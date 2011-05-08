/*
 * AEInputStream.java
 *
 * Created on December 26, 2005, 1:03 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */
package net.sf.jaer.eventio;
import java.util.logging.Level;
import net.sf.jaer.aemonitor.*;
import net.sf.jaer.util.EngineeringFormat;
import java.beans.PropertyChangeSupport;
import java.io.*;
import java.nio.*;
import java.nio.channels.*;
import java.util.*;
import java.util.logging.Logger;
/**
 * Class to stream in packets of events from binary input stream from a file recorded by AEViewer.
 *<p>
 *The file format is simple, it consists of an arbitrary number of timestamped AEs:
 *<pre>
 * int32 address
 *int32 timestamp
 *
 * int32 address
 *int32 timestamp
 *</pre>
<p>
(Prior to version 2.0 data files, the address was a 16 bit short value.)
<p>
An optional ASCII header consisting of lines starting with '#' is skipped when opening the file and may be retrieved.
No later comment lines are allowed because the rest ot the file must be pure binary data.
 * <p>
 * The first line of the header specifies the file format (for later versions). Files lacking a header
 * are assumed to be of int16 address form.
 * <p>
 * The first line of the header has a value like  "#!AER-DAT2.0". The 2.0 is the version number.
<p>
 * <strong>PropertyChangeEvents.</strong>
AEFileInputStream has PropertyChangeSupport via getSupport(). PropertyChangeListeners will be informed of
the following events
<ul>
<li> "position" - on any new packet of events, either by time chunk or fixed number of events chunk.
<li> "rewind" - on file rewind.
<li> "eof" - on end of file.
<li> "wrappedTime" - on wrap of time timestamps. This happens every int32 us, which is about 4295 seconds which is 71 minutes. Time is negative, then positive, then negative again.
<li> "init" - on initial read of a file (after creating this with a file input stream). This init event is called on the
initial packet read because listeners can't be added until the object is created.
 * <li> "markset" - on setting mark, old and new mark positions.
 * <li> "markcleared" - on clearing mark, old mark position and zero.
</ul>

 * <strong>Timestamp resets.</strong> AEFileInputStream also supports a special "zero timestamps" operation on reading a file. A  bit mask which is normally
 * zero can be set; if set to a non zero value, then if ORing the bitmask with the raw address results in a nonzero value, then
 * the timestamps are reset to zero at this point. (A timestamp offset is memorized and subtracted from subsequent timestamps read
 * from the file.) This allow synchronization using, e.g. bit 15 of the address space.
 *
 * @author tobi
 * @see net.sf.jaer.eventio.AEDataFile
 */
public class AEFileInputStream extends DataInputStream implements AEFileInputStreamInterface{ // TODO extend AEInputStream
//    public final static long MAX_FILE_SIZE=200000000;

   private static final int NUMBER_LINE_SEPARATORS = 2; // number of line separators which AEFileOutputStream 
                                                       // (writeHeaderLine) is writing to ae data files. 
                                                       // important for calculation of header offset
    
    private PropertyChangeSupport support = new PropertyChangeSupport(this);
    static Logger log = Logger.getLogger("net.sf.jaer.eventio");
    private FileInputStream fileInputStream = null;
    long fileSize = 0; // size of file in bytes
    private File file = null;
    private Class addressType = Short.TYPE; // default address type, unless file header specifies otherwise
    public final int MAX_NONMONOTONIC_TIME_EXCEPTIONS_TO_PRINT = 1000;
    private int numNonMonotonicTimeExceptionsPrinted = 0;
    private int markPosition = 0; // a single MARK position for rewinding to
    private int markOutPosition = 0,  markInPosition = 0; // positions for editing (not yet implemented TODO)
//    private int markInPosition = 0,  markOutPosition = 0; // points to mark IN and OUT positions for editing
    private int eventSizeBytes = AEFileInputStream.EVENT16_SIZE; // size of event in bytes, set finally after reading file header
    private boolean firstReadCompleted = false;
    private long absoluteStartingTimeMs = 0; // parsed from filename if possible
    private boolean enableTimeWrappingExceptionsChecking = true;
    //    private int numEvents,currentEventNumber;
    // mostRecentTimestamp is the last event sucessfully read
    // firstTimestamp, lastTimestamp are the first and last timestamps in the file (at least the memory mapped part of the file)
    private int mostRecentTimestamp,  firstTimestamp,  lastTimestamp;
    // this marks the present read time for packets
    private int currentStartTimestamp;
    FileChannel fileChannel = null;
    public static final int MAX_BUFFER_SIZE_EVENTS = 100000;
    /** With new 32bits addresses, use EVENT32_SIZE, but use EVENT16_SIZE for backward compatibility with 16 bit addresses */
    public static final int EVENT16_SIZE = Short.SIZE / 8 + Integer.SIZE / 8;
    /** (new style) int addr, int timestamp */
    public static final int EVENT32_SIZE = Integer.SIZE / 8 + Integer.SIZE / 8;
    /** the size of the memory mapped part of the input file.
    This window is centered over the file position except at the start and end of the file.
     */
    private int CHUNK_SIZE_EVENTS = 10000000;
    private int chunkSizeBytes = CHUNK_SIZE_EVENTS * EVENT16_SIZE; // size of memory mapped file chunk, depends on event size and number of events to map, initialized as though we didn't have a file header

    // the packet used for reading events
    private AEPacketRaw packet = new AEPacketRaw(MAX_BUFFER_SIZE_EVENTS);
    EventRaw tmpEvent = new EventRaw();
    MappedByteBuffer byteBuffer = null;
    private int position = 0; // absolute position in file in events, points to next event number, 0 based (1 means 2nd event)
    protected ArrayList<String> header = new ArrayList<String>();
    private int headerOffset = 0; // this is starting position in file for rewind or to add to positioning via slider
    private int chunkNumber = 0; // current memory mapped file chunk, starts with 0 past header
    private long numChunks = 1; // set by parseFileFormatVersion, this is at least 1 and includes the last portion which may be smaller than chunkSizeBytes
    private final String lineSeparator = System.getProperty("line.separator");

    private int timestampResetBitmask=0; // used to memorize timestamp offset.
    private int timestampOffset=0; // set by nonzero bitmask result on address to that events timestamp, subtracted from all timestamps

    /** Creates a new instance of AEInputStream
    @deprecated use the constructor with a File object so that users of this can more easily get file information
     */
    public AEFileInputStream (FileInputStream in) throws IOException{
        super(in);
        init(in);
    }

    /** Creates a new instance of AEInputStream
    @param f the file to open
    @throws FileNotFoundException if file doesn't exist or can't be read
     */
    public AEFileInputStream (File f) throws IOException{
        this(new FileInputStream(f));
        setFile(f);
    }

    public String toString (){
        EngineeringFormat fmt = new EngineeringFormat();
        String s = "AEInputStream with size=" + fmt.format(size()) + " events, firstTimestamp=" + getFirstTimestamp() + " lastTimestamp=" + getLastTimestamp() + " duration=" + fmt.format(getDurationUs() / 1e6f) + " s" + " event rate=" + fmt.format(size() / ( getDurationUs() / 1e6f )) + " eps";
        return s;
    }

    /** fires property change "position".
     * @throws IOException if file is empty or there is some other error.
     */
    private void init (FileInputStream fileInputStream) throws IOException{
        this.fileInputStream = fileInputStream;

//        System.gc();
        readHeader(fileInputStream); // parses header, sets eventSize, chunkSize, throws 0-size IOException

        mostRecentTimestamp = 0;
        currentStartTimestamp = 0; // make sure these are initialized correctly so that an event is always read when file is opened

        setupChunks();




//        long totalMemory=Runtime.getRuntime().totalMemory();
//        long maxMemory=Runtime.getRuntime().maxMemory();
//        long maxSize=3*(maxMemory-totalMemory)/4;
//        EngineeringFormat fmt=new EngineeringFormat();
//        log.info("AEInputStream.init(): trying to open file using memory mapped file of size="+fmt.format(fileSize)+" using memory-limited max size="+fmt.format(maxSize));
//        do{
//            try{
//                fileChannel.position(0);
//                long size=fileChannel.size();
//                if(size>maxSize){
//                    log.warning("opening file using byteBuffer with size="+maxSize+" but file size="+size);
//                    size=maxSize;
//                }
//                byteBuffer=fileChannel.map(FileChannel.MapMode.READ_ONLY,0,size);
//                openok=true;
//            }catch(IOException e){
//                System.gc();
//                long newMaxSize=3*maxSize/4;
//                log.warning("AEInputStream.init(): cannot open file "+fileInputStream+" with maxSize="+maxSize+" trying again with size="+newMaxSize);
//                maxSize=newMaxSize;
//            }
//        }while(openok==false && maxSize>20000000);
//        if(!openok){
//            throw new RuntimeException("cannot open preview, not enough memory");
//        }
        try{
            EventRaw ev = readEventForwards(); // init timestamp
            firstTimestamp = ev.timestamp;
            position((int)( size() - 1 ));
            ev = readEventForwards();
            lastTimestamp = ev.timestamp;
            position(0);
            currentStartTimestamp = firstTimestamp;
            mostRecentTimestamp = firstTimestamp;
        } catch ( IOException e ){
            log.warning("couldn't read first event to set starting timestamp");
        } catch ( NonMonotonicTimeException e2 ){
            log.warning("On AEInputStream.init() caught "+e2.toString());
        }
        log.info("initialized " + this.toString());
    }

    private EventRaw readEventForwards() throws IOException, NonMonotonicTimeException{
        return readEventForwards(Integer.MAX_VALUE);
    }
    
    /** reads the next event forward, sets mostRecentTimestamp, returns null if the next timestamp is later than maxTimestamp.
     * @param maxTimestamp the latest timestamp that should be read.
    @throws EOFException at end of file
     * @throws NonMonotonicTimeException
     * @throws WrappedTimeException
     */
    private EventRaw readEventForwards (int maxTimestamp) throws IOException,NonMonotonicTimeException{
        int ts = -1;
        int addr = 0;
        int lastTs=mostRecentTimestamp;
        try{
//            eventByteBuffer.rewind();
//            fileChannel.read(eventByteBuffer);
//            eventByteBuffer.rewind();
//            addr=eventByteBuffer.getShort();
//            ts=eventByteBuffer.getInt();
            if ( addressType == Integer.TYPE ){
                addr = byteBuffer.getInt();
            } else{
                addr = (byteBuffer.getShort()&0xffff); // TODO reads addr as negative number if msb is set
            }
            ts = byteBuffer.getInt();
//            log.info("position="+position+" ts="+ts) ;
//            if(ts==0){
//                System.out.println("zero timestamp");
//            }
             // for marking sync in a recording using the result of bitmask with input
            if ( ( addr & timestampResetBitmask ) != 0 ){
                log.log(Level.INFO,"found timestamp reset event addr={0} position={1} timstamp={2}",new Object[ ]{ addr,position,ts });
                timestampOffset=ts;
            }
            ts-=timestampOffset; 
//            // TODO fix extra event no matter what dt
//            if (ts > maxTimestamp) {
//                // push back event
//                byteBuffer.position(position()-eventSizeBytes); // we haven't updated our position field yet
//                ts=lastTs; // this is the one last read successfully 
//                mostRecentTimestamp=ts;
//                return null;
//            }
            // check for non-monotonic increasing timestamps, if we get one, reset our notion of the starting time
            if ( isWrappedTime(ts,mostRecentTimestamp,1) ){
                throw new WrappedTimeException(ts,mostRecentTimestamp,position);
            }
            if ( enableTimeWrappingExceptionsChecking && ts < mostRecentTimestamp ){
//                log.warning("AEInputStream.readEventForwards returned ts="+ts+" which goes backwards in time (mostRecentTimestamp="+mostRecentTimestamp+")");
                throw new NonMonotonicTimeException(ts,mostRecentTimestamp,position);
            }
 
            tmpEvent.address = addr;
            tmpEvent.timestamp = ts;
            position++;
 
            return tmpEvent;
        } catch ( BufferUnderflowException e ){
            try{
                mapNextChunk();
                return readEventForwards(maxTimestamp);
            } catch ( IOException eof ){
                byteBuffer = null;
                System.gc(); // all the byteBuffers have referred to mapped files and use up all memory, now free them since we're at end of file anyhow
                getSupport().firePropertyChange(AEInputStream.EVENT_EOF,position(),position());
                throw new EOFException("reached end of file");
            }
        } catch ( NullPointerException npe ){
            rewind();
            return readEventForwards(maxTimestamp);
        } finally{
            mostRecentTimestamp = ts;
        }
    }

    /** Reads the next event backwards and leaves the position and byte buffer pointing to event one earlier
    than the one we just read. I.e., we back up, read the event, then back up again to leave us in state to
    either read forwards the event we just read, or to repeat backing up and reading if we read backwards
     */
    private EventRaw readEventBackwards () throws IOException,NonMonotonicTimeException{
        // we enter this with position pointing to next event *to read forwards* and byteBuffer also in this state.
        // therefore we need to decrement the byteBuffer pointer and the position, and read the event.

        // update the position first to leave us afterwards pointing one before current position
        int newPos = position - 1; // this is new absolute position
        if ( newPos < 0 ){
            // reached start of file
            newPos = 0;
//            System.out.println("readEventBackwards: reached start");
            throw new EOFException("reached start of file");
        }

        // normally we just update the postiion to be one less, then move the byteBuffer pointer back by
        // one event and read that new event. But if we have reached start of byte buffer, we
        // need to load a new chunk and set the buffer pointer to point to one event before the end
        int newBufPos;
        newBufPos = byteBuffer.position() - eventSizeBytes;

        if ( newBufPos < 0 ){
            // check if we need to map a new earlier chunk of the file
            int newChunkNumber = getChunkNumber(newPos);
            if ( newChunkNumber != chunkNumber ){
                mapPreviousChunk(); // will throw EOFException when reaches start of file
                newBufPos = ( eventSizeBytes * newPos ) % chunkSizeBytes;

                byteBuffer.position(newBufPos); // put the buffer pointer at the end of the buffer
            }
        } else{
            // this is usual situation
            byteBuffer.position(newBufPos);
        }
        // short addr=byteBuffer.getShort();
        int addr;
        // with new 32bits adressses, use getInt, but use getShort for backward compatibility with 16bits

        if ( addressType == Integer.TYPE ){
            addr = byteBuffer.getInt();
        } else{
            addr = (byteBuffer.getShort()&0xffff); // TODO reads addr as negative number if msb is set if we don't AND with 0xFFFF
        }

        int ts = byteBuffer.getInt()-timestampOffset; 
        byteBuffer.position(newBufPos);
        tmpEvent.address = addr;
        tmpEvent.timestamp = ts;
        mostRecentTimestamp = ts;
        position--; // decrement position before exception to make sure we skip over a bad timestamp
        if ( enableTimeWrappingExceptionsChecking && isWrappedTime(ts,mostRecentTimestamp,-1) ){
            throw new WrappedTimeException(ts,mostRecentTimestamp,position);
        }
        if ( enableTimeWrappingExceptionsChecking && ts > mostRecentTimestamp ){
            throw new NonMonotonicTimeException(ts,mostRecentTimestamp,position);
        }
        return tmpEvent;
    }

    /** Uesd to read fixed size packets either forwards or backwards. 
     * Behavior in case of non-monotonic timestamps depends on setting of tim wrapping exception checking.
     * If exception checking is enabled, then the read will terminate on the first non-monotonic timestamp.
    @param n the number of events to read
    @return a raw packet of events of a specfied number of events
    fires a property change "position" on every call, and a property change "wrappedTime" if time wraps around.
     */
    synchronized public AEPacketRaw readPacketByNumber (int n) throws IOException{
        if ( !firstReadCompleted ){
            fireInitPropertyChange();
        }
        int an = (int)Math.abs(n);
        if ( an > MAX_BUFFER_SIZE_EVENTS ){
            an = MAX_BUFFER_SIZE_EVENTS;
            if ( n > 0 ){
                n = MAX_BUFFER_SIZE_EVENTS;
            } else{
                n = -MAX_BUFFER_SIZE_EVENTS;
            }
        }
        int[] addr = packet.getAddresses();
        int[] ts = packet.getTimestamps();
        int oldPosition = position();
        EventRaw ev;
        int count = 0;
        try{
            if ( n > 0 ){
                for ( int i = 0 ; i < n ; i++ ){
                    ev = readEventForwards();
                    count++;
                    addr[i] = ev.address;
                    ts[i] = ev.timestamp;
                }
            } else{ // backwards
                n = -n;
                for ( int i = 0 ; i < n ; i++ ){
                    ev = readEventBackwards();
                    count++;
                    addr[i] = ev.address;
                    ts[i] = ev.timestamp;
                }
            }
        } catch ( WrappedTimeException e ){
            log.warning(e.toString());
            getSupport().firePropertyChange(AEInputStream.EVENT_WRAPPED_TIME,e.getPreviousTimestamp(),e.getCurrentTimestamp());
        } catch ( NonMonotonicTimeException e ){
           getSupport().firePropertyChange(AEInputStream.EVENT_NON_MONOTONIC_TIMESTAMP,e.getPreviousTimestamp(),e.getCurrentTimestamp());
 //            log.info(e.getMessage());
        }
        packet.setNumEvents(count);
        getSupport().firePropertyChange(AEInputStream.EVENT_POSITION,oldPosition,position());
        return packet;
//        return new AEPacketRaw(addr,ts);
    }

    /** returns an AEPacketRaw at least dt long up to the max size of the buffer or until end-of-file.
     *Events are read as long as the timestamp until (and including) the event whose timestamp is greater (for dt>0) than
     * startTimestamp+dt, where startTimestamp is the currentStartTimestamp. currentStartTimestamp is incremented after the call by dt.
     *Fires a property change "position" on each call.
    Fires property change "wrappedTime" when time wraps from positive to negative or vice versa (when playing backwards).
     * <p>
     *Non-monotonic timestamps cause warning messages to be printed (up to MAX_NONMONOTONIC_TIME_EXCEPTIONS_TO_PRINT) and packet
     * reading is aborted when the non-monotonic timestamp is encountered. Normally this does not cause problems except that the packet
     * is shorter in duration that called for. But when synchronized playback is enabled it causes the different threads to desynchronize.
     * Therefore the data files should not contain non-monotonic timestamps when synchronized playback is desired.
     * 
     *@param dt the timestamp different in units of the timestamp (usually us)
     *@see #MAX_BUFFER_SIZE_EVENTS
     */
    synchronized public AEPacketRaw readPacketByTime (int dt) throws IOException{
        if ( !firstReadCompleted ){
            fireInitPropertyChange();
        }
        int endTimestamp = currentStartTimestamp + dt;
        // check to see if this read will wrap the int32 timestamp around e.g. from >0 to <0 for dt>0
        boolean bigWrap = isWrappedTime(endTimestamp,currentStartTimestamp,dt);
//        if( (dt>0 && mostRecentTimestamp>endTimestamp ) || (dt<0 && mostRecentTimestamp<endTimestamp)){
//            boolean lt1=endTimestamp<0, lt2=mostRecentTimestamp<0;
//            boolean changedSign= ( (lt1 && !lt2) || (!lt1 && lt2) );
//            if( !changedSign ){
//                currentStartTimestamp=endTimestamp;
//                log.info(this+" returning empty packet because mostRecentTimestamp="+mostRecentTimestamp+" is already later than endTimestamp="+endTimestamp);
//                return new AEPacketRaw(0);
//            }
//        }
        int startTimestamp = mostRecentTimestamp;
        int[] addr = packet.getAddresses();
        int[] ts = packet.getTimestamps();
        int oldPosition = position();
        EventRaw ae;
        int i = 0;
//        System.out.println("endTimestamp-startTimestamp="+(endTimestamp-startTimestamp)+"   mostRecentTimestamp="+mostRecentTimestamp+" startTimestamp="+startTimestamp);
        try{
            if ( dt > 0 ){ // read forwards
                if ( !bigWrap ){ // normal situation
                    do{
                        ae = readEventForwards(endTimestamp);// TODO always reads an event even if it occurs after time slice
                        if (ae == null) {
                            break;
                        }
                        addr[i] = ae.address;
                        ts[i] = ae.timestamp;
                        i++;
                    } while ( mostRecentTimestamp < endTimestamp && i < addr.length  && mostRecentTimestamp >= startTimestamp ); // if time jumps backwards (e.g. timestamp reset during recording) then will read a huge number of events.
                } else{ // read should wrap around
//                    System.out.println("bigwrap started");
                    do{
                        ae = readEventForwards(endTimestamp);
                        if(ae==null) break;
                        addr[i] = ae.address;
                        ts[i] = ae.timestamp;
                        i++;
                    } while ( mostRecentTimestamp > 0 && i < addr.length ); // read to where bigwrap occurs, then terminate - but wrapped time exception will happen first
                    // never gets here because of wrap exception
//                    System.out.println("reading one more event after bigwrap");
//                    ae = readEventForwards();
//                    addr[i] = ae.address;
//                    ts[i] = ae.timestamp;
//                    i++;
                }
            } else{ // read backwards
                if ( !bigWrap ){
                    do{
                        ae = readEventBackwards();
                        addr[i] = ae.address;
                        ts[i] = ae.timestamp;
                        i++;
                    } while ( mostRecentTimestamp > endTimestamp && i < addr.length && mostRecentTimestamp <= startTimestamp );
                } else{
                    do{
                        ae = readEventBackwards();
                        addr[i] = ae.address;
                        ts[i] = ae.timestamp;
                        i++;
                    } while ( mostRecentTimestamp < 0 && i < addr.length - 1 );

                    ae = readEventBackwards();
                    addr[i] = ae.address;
                    ts[i] = ae.timestamp;
                    i++;
                }
            }
        } catch ( WrappedTimeException w ){
            log.warning(w.toString());
            currentStartTimestamp = w.getCurrentTimestamp();
            mostRecentTimestamp = w.getCurrentTimestamp();
            getSupport().firePropertyChange(AEInputStream.EVENT_WRAPPED_TIME,w.getPreviousTimestamp(),w.getCurrentTimestamp());
        } catch ( NonMonotonicTimeException e ){
//            e.printStackTrace();
            if ( numNonMonotonicTimeExceptionsPrinted++ < MAX_NONMONOTONIC_TIME_EXCEPTIONS_TO_PRINT ){
                log.log(Level.INFO,"{0} resetting currentStartTimestamp from {1} to {2} and setting mostRecentTimestamp to same value",new Object[ ]{ e,currentStartTimestamp,e.getCurrentTimestamp() });
                if ( numNonMonotonicTimeExceptionsPrinted == MAX_NONMONOTONIC_TIME_EXCEPTIONS_TO_PRINT ){
                    log.warning("suppressing further warnings about NonMonotonicTimeException");
                }
            }
            currentStartTimestamp = e.getCurrentTimestamp();
            mostRecentTimestamp = e.getCurrentTimestamp();
            getSupport().firePropertyChange(AEInputStream.EVENT_NON_MONOTONIC_TIMESTAMP,lastTimestamp, mostRecentTimestamp);
       } finally{
            currentStartTimestamp = mostRecentTimestamp;
        }
        packet.setNumEvents(i);
//        if(i<1){
//            log.info(packet.toString());
//        }
        getSupport().firePropertyChange(AEInputStream.EVENT_POSITION,oldPosition,position());
//        System.out.println("bigwrap="+bigWrap+" read "+packet.getNumEvents()+" mostRecentTimestamp="+mostRecentTimestamp+" currentStartTimestamp="+currentStartTimestamp);
        return packet;
    }

    /** rewind to the start, or to the marked position, if it has been set. 
    Fires a property change "position" followed by "rewind". */
    synchronized public void rewind () throws IOException{
        int oldPosition = position();
        position(markPosition);
        try{
            if ( markPosition == 0 ){
                mostRecentTimestamp = firstTimestamp;
//                skipHeader();
            } else{
                readEventForwards(); // to set the mostRecentTimestamp
            }
        } catch ( NonMonotonicTimeException e ){
            log.log(Level.INFO,"rewind from timestamp={0} to timestamp={1}",new Object[ ]{ e.getPreviousTimestamp(),e.getCurrentTimestamp() });
        }
        currentStartTimestamp = mostRecentTimestamp;
//        System.out.println("AEInputStream.rewind(): set position="+byteBuffer.position()+" mostRecentTimestamp="+mostRecentTimestamp);
        getSupport().firePropertyChange(AEInputStream.EVENT_POSITION,oldPosition,position());
        getSupport().firePropertyChange(AEInputStream.EVENT_REWIND,oldPosition,position());
    }

    /** gets the size of the stream in events
    @return size in events
     */
    public long size (){
        return ( fileSize - headerOffset ) / eventSizeBytes;
    }

    /** set position in events from start of file
    @param event the number of the event, starting with 0
     */
    synchronized public void position (int event){
//        if(event==size()) event=event-1;
        int newChunkNumber;
        try{
            if ( ( newChunkNumber = getChunkNumber(event) ) != chunkNumber ){
                mapChunk(newChunkNumber);
            }
            byteBuffer.position(( event * eventSizeBytes ) % chunkSizeBytes);
            position = event;
        } catch ( IOException e ){
            log.log(Level.WARNING,"caught {0}",e);
            e.printStackTrace();
        } catch ( IllegalArgumentException e2 ){
            log.warning("caught " + e2);
            e2.printStackTrace();
        }
    }

    /** gets the current position (in events) for reading forwards, i.e., readEventForwards will read this event number.
    @return position in events.
     */
    synchronized public int position (){
        return this.position;
    }

    /**Returns the position as a fraction of the total number of events
    @return fractional position in total events*/
    synchronized public float getFractionalPosition (){
        return (float)position() / size();
    }

    /** Sets fractional position in events
     * @param frac 0-1 float range, 0 at start, 1 at end
     */
    synchronized public void setFractionalPosition (float frac){
        position((int)( frac * size() ));
        try{
            readEventForwards();
        } catch ( Exception e ){
//            e.printStackTrace();
        }
    }

    /** AEFileInputStream has PropertyChangeSupport. This support fires events on certain events such as "rewind".
     */
    public PropertyChangeSupport getSupport (){
        return support;
    }

    /** mark the current position.
     * @throws IOException if there is some error in reading the data
     */
    synchronized public void mark () throws IOException{
        int old=markPosition;
        markPosition = position();
        markPosition = ( markPosition / eventSizeBytes ) * eventSizeBytes; // to avoid marking inside an event
        getSupport().firePropertyChange(AEInputStream.EVENT_MARKSET,old,markPosition);

//        System.out.println("AEInputStream.mark() marked position "+markPosition);
    }

    /** mark the current position as the IN point for editing.
     * @throws IOException if there is some error in reading the data
     */
    synchronized public void markIn () throws IOException{
        markInPosition = position();
        markInPosition = ( markPosition / eventSizeBytes ) * eventSizeBytes; // to avoid marking inside an event
    }

    /** mark the current position as the OUT position for editing.
     * @throws IOException if there is some error in reading the data
     */
    synchronized public void markOut () throws IOException{
        markOutPosition = position();
        markOutPosition = ( markPosition / eventSizeBytes ) * eventSizeBytes; // to avoid marking inside an event
    }

    /** clear any marked position */
    synchronized public void unmark (){
       int old=markPosition;
         markPosition = 0;
       getSupport().firePropertyChange(AEInputStream.EVENT_MARKCLEARED,old,markPosition);
    }

    /** Returns true if mark has been set to nonzero position.
     *
     * @return true if set.
     */
    public boolean isMarkSet(){
        return markPosition!=0;
    }

    @Override
    public void close () throws IOException{
        super.close();
        fileChannel.close();
        System.gc();
        System.runFinalization(); // try to free memory mapped file buffers so file can be deleted....
    }

    /** returns the first timestamp in the stream
    @return the timestamp
     */
    public int getFirstTimestamp (){
        return firstTimestamp;
    }

    /** @return last timestamp in file */
    public int getLastTimestamp (){
        return lastTimestamp;
    }

    /** @return the duration of the file in us. <p>
     * Assumes data file is timestamped in us. This method fails to provide a sensible value if the timestamp wwaps.
     */
    public int getDurationUs (){
        return lastTimestamp - firstTimestamp;
    }

    /** @return the present value of the startTimestamp for reading data */
    synchronized public int getCurrentStartTimestamp (){
        return currentStartTimestamp;
    }

    public void setCurrentStartTimestamp (int currentStartTimestamp){
        this.currentStartTimestamp = currentStartTimestamp;
    }

    /** @return returns the most recent timestamp
     */
    public int getMostRecentTimestamp (){
        return mostRecentTimestamp;
    }

    public void setMostRecentTimestamp (int mostRecentTimestamp){
        this.mostRecentTimestamp = mostRecentTimestamp;
    }
    /** class used to signal a backwards read from input stream */
    public class NonMonotonicTimeException extends Exception{
        protected int timestamp,  lastTimestamp,  position;

        public NonMonotonicTimeException (){
            super();
        }

        public NonMonotonicTimeException (String s){
            super(s);
        }

        public NonMonotonicTimeException (int ts){
            this.timestamp = ts;
        }

        /** Constructs a new NonMonotonicTimeException
         *
         * @param readTs the timestamp just read
         * @param lastTs the previous timestamp
         */
        public NonMonotonicTimeException (int readTs,int lastTs){
            this.timestamp = readTs;
            this.lastTimestamp = lastTs;
        }

        /** Constructs a new NonMonotonicTimeException
         *
         * @param readTs the timestamp just read
         * @param lastTs the previous timestamp
         * @param position the current position in the stream
         */
        public NonMonotonicTimeException (int readTs,int lastTs,int position){
            this.timestamp = readTs;
            this.lastTimestamp = lastTs;
            this.position = position;
        }

        public int getCurrentTimestamp (){
            return timestamp;
        }

        public int getPreviousTimestamp (){
            return lastTimestamp;
        }

        public String toString (){
            return "NonMonotonicTimeException: position=" + position + " timestamp=" + timestamp + " lastTimestamp=" + lastTimestamp + " jumps backwards by " + ( timestamp - lastTimestamp );
        }
    }
    /** Indicates that timestamp has wrapped around from most positive to most negative signed value.
    The de-facto timestamp tick is us and timestamps are represented as int32 in jAER. Therefore the largest possible positive timestamp
    is 2^31-1 ticks which equals 2147.4836 seconds (35.7914 minutes). This wraps to -2147 seconds. The actual total time
    can be computed taking account of these "big wraps" if
    the time is increased by 4294.9673 seconds on each WrappedTimeException (when reading file forwards).
     * @param readTs the current (just read) timestamp
     * @param lastTs the previous timestamp
     */
    public class WrappedTimeException extends NonMonotonicTimeException{
        public WrappedTimeException (int readTs,int lastTs){
            super(readTs,lastTs);
        }

        public WrappedTimeException (int readTs,int lastTs,int position){
            super(readTs,lastTs,position);
        }

        public String toString (){
            return "WrappedTimeException: timestamp=" + timestamp + " lastTimestamp=" + lastTimestamp + " jumps backwards by " + ( timestamp - lastTimestamp );
        }
    }

    // checks for wrap (if reading forwards, this timestamp <0 and previous timestamp >0)
    private final boolean isWrappedTime (int read,int prevRead,int dt){
        if ( dt > 0 && read <= 0 && prevRead > 0 ){
            return true;
        }
        if ( dt < 0 && read >= 0 && prevRead < 0 ){
            return true;
        }
        return false;
    }

    /** cuts out the part of the stream from IN to OUT and returns it as a new AEInputStream
    @return the new stream
     */
    public AEFileInputStream cut (){
        AEFileInputStream out = null;
        return out;
    }

    /** copies out the part of the stream from IN to OUT markers and returns it as a new AEInputStream
    @return the new stream
     */
    public AEFileInputStream copy (){
        AEFileInputStream out = null;
        return out;
    }

    /** pastes the in stream at the IN marker into this stream
    @param in the stream to paste
     */
    public void paste (AEFileInputStream in){
    }

    /** returns the chunk number which starts with 0. For position<CHUNK32_SIZE_BYTES returns 0
     */
    private int getChunkNumber (int position){
        int chunk;
        chunk = (int)( ( position * eventSizeBytes ) / chunkSizeBytes );
        return chunk;
    }

    private int positionFromChunk (int chunkNumber){
        int pos = chunkNumber * chunkSizeBytes / eventSizeBytes;
        return pos;
    }

    private void mapNextChunk () throws IOException{
        chunkNumber++; // increment the chunk number
        if ( chunkNumber >= numChunks ){
            // if we try now to map a chunk past the last one then throw an EOF
            throw new EOFException("end of file; tried to map chunkNumber=" + chunkNumber + " but file only has numChunks=" + numChunks);
        }
        int start = getChunkStartPosition(chunkNumber);
        if ( start >= fileSize || start < 0 ){
            chunkNumber = 0; // overflow will wrap<0
        }
        mapChunk(chunkNumber);
    }

    private void mapPreviousChunk () throws IOException{
        chunkNumber--;
        if ( chunkNumber < 0 ){
            chunkNumber = 0;
        }
        int start = getChunkStartPosition(chunkNumber);
        if ( start >= fileSize || start < 0 ){
            chunkNumber = 0; // overflow will wrap<0
        }
        mapChunk(chunkNumber);
    }

    /** memory-maps a chunk of the input file.
    @param chunkNumber the number of the chunk, starting with 0
     */
    private void mapChunk (int chunkNumber) throws IOException{
        this.chunkNumber = chunkNumber;
        int start = getChunkStartPosition(chunkNumber);
        if ( start >= fileSize ){
            throw new EOFException("start of chunk=" + start + " but file has fileSize=" + fileSize);
        }
        int numBytesToMap = chunkSizeBytes;
        if ( start + numBytesToMap >= fileSize ){
            numBytesToMap = (int)( fileSize - start );
        }
        byteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY,start,numBytesToMap);
        this.position = positionFromChunk(chunkNumber);
//        log.info("mapped chunk # "+chunkNumber+" of "+numChunks);
    }

    /** @return start of chunk in bytes
    @param chunk the chunk number
     */
    private int getChunkStartPosition (int chunk){
        if ( chunk <= 0 ){
            return headerOffset;
        }
        return ( chunk * chunkSizeBytes ) + headerOffset;

    }

    private int getChunkEndPosition (int chunk){
        return headerOffset + ( chunk + 1 ) * chunkSizeBytes;
    }

    /** skips the header lines (if any) */
    protected void skipHeader () throws IOException{
        position(headerOffset);
    }

    /** reads the header comment lines. Must have eventSize and chunkSizeBytes set for backwards compatiblity for files without headers to short address sizes.
     */
    protected void readHeader (FileInputStream fileInputStream) throws IOException{


        if ( fileInputStream == null ){
            throw new IOException("null fileInputStream");
        }
        if ( in.available() == 0 ){
            throw new IOException("empty file (0 bytes available)");
        }

        BufferedReader bufferedHeaderReader = new BufferedReader(new InputStreamReader(fileInputStream));
        headerOffset = 0; // start from 0
        if ( !bufferedHeaderReader.markSupported() ){
            throw new IOException("no mark supported while reading file header, is this a normal file?");
        }
        String s;
//        System.out.println("File header:");
        while ( ( s = readHeaderLine(bufferedHeaderReader) ) != null ){
            header.add(s);
            parseFileFormatVersion(s);
        }
        // we don't map yet until we know eventSize
        StringBuffer sb = new StringBuffer();
        sb.append("File header:");
        for ( String str:header ){
            sb.append(str);
            sb.append(lineSeparator); // "\n");
        }
        log.info(sb.toString());
        bufferedHeaderReader = null; // mark for GC
    }

    /** parses the file format version given a string with the header comment character stripped off.
    @see net.sf.jaer.eventio.AEDataFile
     */
    protected void parseFileFormatVersion (String s){
        float version = 1f;
        if ( s.startsWith(AEDataFile.DATA_FILE_FORMAT_HEADER) ){ // # stripped off by readHeaderLine
            try{
                version = Float.parseFloat(s.substring(AEDataFile.DATA_FILE_FORMAT_HEADER.length()));
            } catch ( NumberFormatException numberFormatException ){
                log.warning("While parsing header line " + s + " got " + numberFormatException.toString());
            }
            if ( version < 2 ){
                addressType = Short.TYPE;
                eventSizeBytes = Integer.SIZE / 8 + Short.SIZE / 8;
            } else if ( version >= 2 ){ // this is hack to avoid parsing the AEDataFile. format number string...
                addressType = Integer.TYPE;
                eventSizeBytes = Integer.SIZE / 8 + Integer.SIZE / 8;
            }
            log.info("Data file version=" + version + " and has addressType=" + addressType);
        }
    }

    void setupChunks () throws IOException{
        fileChannel = fileInputStream.getChannel();
        fileSize = fileChannel.size();
        chunkSizeBytes = eventSizeBytes * CHUNK_SIZE_EVENTS;
        numChunks = ( fileSize / chunkSizeBytes ) + 1; // used to limit chunkNumber to prevent overflow of position and for EOF
        log.info("fileSize=" + fileSize + " chunkSizeBytes=" + chunkSizeBytes + " numChunks=" + numChunks);
        mapChunk(0);
    }

    /** assumes we are positioned at start of line and that we may either
     * read a comment char '#' or something else
    leaves us after the line at start of next line or of raw data.
     * Assumes header lines are written using the AEOutputStream.writeHeaderLine().
    @return header line
     */
    private String readHeaderLine (BufferedReader reader) throws IOException{
//        StringBuffer s = new StringBuffer();
        // read header lines from fileInputStream, not byteBuffer, since we have not mapped file yet
//        reader.mark(1);  // max header line length in chars
        int c = reader.read();  // read single char
        if ( c != AEDataFile.COMMENT_CHAR ){ // if it's not a comment char
            return null;  // return a null header line
        }
//        reader.reset(); // reset to start of header/comment line
        // we don't push back comment char because we want to parse the file format sans this
        String s = reader.readLine();
        for ( byte b:s.getBytes() ){
            if ( b < 32 || b > 126 ){
                log.warning("Non printable character (byte value=" + b + ") which is (<32 || >126) detected in header line, aborting header read and resetting to start of file because this file may not have a real header");
                return null;
            }
        }
        headerOffset += s.length() + NUMBER_LINE_SEPARATORS + 1; // adds comment char and trailing CRLF newline, assumes CRLF EOL // TODO fix this assumption
        return s;
    }

    /** Gets the header strings from the file
    @return list of strings, one per line
     */
    public ArrayList<String> getHeader (){
        return header;
    }

    private void fireInitPropertyChange (){
        getSupport().firePropertyChange(AEInputStream.EVENT_INIT,0,0);
        firstReadCompleted = true;
    }

    /** Returns the File that is being read, or null if the instance is constructed from a FileInputStream */
    public File getFile (){
        return file;
    }

    /** Sets the File reference but doesn't open the file */
    public void setFile (File f){
        this.file = f;
        absoluteStartingTimeMs = getAbsoluteStartingTimeMsFromFile(getFile());
    }

    /** When the file is opened, the filename is parsed to try to extract the date and time the file was created from the filename.
    @return the time logging was started in ms since 1970
     */
    public long getAbsoluteStartingTimeMs (){
        return absoluteStartingTimeMs;
    }

    public void setAbsoluteStartingTimeMs (long absoluteStartingTimeMs){
        this.absoluteStartingTimeMs = absoluteStartingTimeMs;
    }

    /**Parses the filename to extract the file logging date from the name of the file.
     *  
     * @return start of logging time in ms, i.e., in "java" time, since 1970 
     */
    private long getAbsoluteStartingTimeMsFromFile (File f){
        if ( f == null ){
            return 0;
        }
        try{
            String fn = f.getName();
            String dateStr = fn.substring(fn.indexOf('-') + 1); // guess that datestamp is right after first - which follows Chip classname
            Date date = AEDataFile.DATE_FORMAT.parse(dateStr);
            return date.getTime();
        } catch ( Exception e ){
            log.warning(e.toString());
            return 0;
        }
    }

    public boolean isNonMonotonicTimeExceptionsChecked (){
        return enableTimeWrappingExceptionsChecking;
    }

    public void setNonMonotonicTimeExceptionsChecked (boolean yes){
        enableTimeWrappingExceptionsChecking = yes;
    }

    /**
     *    * Returns the bitmask that is OR'ed with raw addresses; if result is nonzero then a new timestamp offset is memorized and subtracted from

     * @return the timestampResetBitmask
     */
    public int getTimestampResetBitmask (){
        return timestampResetBitmask;
    }

    /**
     * Sets the bitmask that is OR'ed with raw addresses; if result is nonzero then a new timestamp offset is memorized and subtracted from
     * all subsequent timestamps.
     *
     * @param timestampResetBitmask the timestampResetBitmask to set
     */
    public void setTimestampResetBitmask (int timestampResetBitmask){
        this.timestampResetBitmask = timestampResetBitmask;
    }

}
