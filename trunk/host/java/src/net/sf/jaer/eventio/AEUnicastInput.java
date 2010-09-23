/*
 * AEUnicastDialog.java
 *
 * Created on April 25, 2008, 8:40 AM
 */
package net.sf.jaer.eventio;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.nio.ByteBuffer;
import net.sf.jaer.aemonitor.*;
import java.io.*;
import java.net.*;
import java.nio.ByteOrder;
import java.nio.channels.DatagramChannel;
import java.util.concurrent.Exchanger;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.logging.*;
import java.util.prefs.*;
import net.sf.jaer.graphics.AEViewer;
/** Receives input via datagram (connectionless, UDP) packets from a server.
 * <p>
 * The socket binds to the port which comes initially from the Preferences for AEUnicastInput. The port
 * can be later changed.
 * <p>
Each packet consists of (by default)
 * 
1. a packet sequence integer (32 bits) which can be used to count missed packets
 * 
2. AEs. Each AE is a pair int32 address, int32 timestamp.
Timestamps are assumed to have 1us tick.
 * <p>
 * Options allow different choices for use of sequence number, size of address/timestamp,
 * order of address/timestamp, and swapping byte order to account for big/little endian peers.
 *
 * <p>
 * The datagram socket is not connected to the receiver, i.e., connect() is not called on the socket.
 * 
 * @see #setAddressFirstEnabled
 * @see #setSequenceNumberEnabled
 */
public class AEUnicastInput implements AEUnicastSettings,PropertyChangeListener{
    // TODO If the remote host sends 16 bit timestamps, then a local unwrapping is done to extend the time range
    private static Preferences prefs = Preferences.userNodeForPackage(AEUnicastInput.class);
    private DatagramSocket datagramSocket = null;
    private boolean printedHost = false;
//    private String host=prefs.get("AEUnicastInput.host", "localhost");
    private int port = prefs.getInt("AEUnicastInput.port",AENetworkInterfaceConstants.DATAGRAM_PORT);
    private boolean sequenceNumberEnabled = prefs.getBoolean("AEUnicastInput.sequenceNumberEnabled",true);
    private boolean addressFirstEnabled = prefs.getBoolean("AEUnicastInput.addressFirstEnabled",true);
    private Exchanger<AENetworkRawPacket> exchanger = new Exchanger();
    private AENetworkRawPacket initialEmptyBuffer = new AENetworkRawPacket(); // the buffer to start capturing into
    private AENetworkRawPacket initialFullBuffer = new AENetworkRawPacket();    // the buffer to render/process first
    private AENetworkRawPacket currentFillingBuffer = initialEmptyBuffer; // starting buffer for filling
    private AENetworkRawPacket currentEmptyingBuffer = initialFullBuffer; // starting buffer to empty
    private static final Logger log = Logger.getLogger("AESocketStream");
    private int bufferSize = prefs.getInt("AEUnicastInput.bufferSize",AENetworkInterfaceConstants.DATAGRAM_BUFFER_SIZE_BYTES);
    private boolean swapBytesEnabled = prefs.getBoolean("AEUnicastInput.swapBytesEnabled",false);
    private float timestampMultiplier = prefs.getFloat("AEUnicastInput.timestampMultiplier",DEFAULT_TIMESTAMP_MULTIPLIER);
    private boolean use4ByteAddrTs = prefs.getBoolean("AEUnicastInput.use4ByteAddrTs",DEFAULT_USE_4_BYTE_ADDR_AND_TIMESTAMP);
    private boolean localTimestampsEnabled=prefs.getBoolean("AEUnicastOutput.localTimestampsEnabled", false);
    /** Maximum time interval in ms to exchange EventPacketRaw with consumer */
    static public final long MIN_INTERVAL_MS = 30;
    final int TIMEOUT_MS = 1000; // SO_TIMEOUT for receive in ms
    boolean stopme = false;
    private final boolean debugInput = false; // to print received amount of data
    private DatagramChannel channel;
    private int packetCounter = 0;
    private int packetSequenceNumber = 0;
    private EventRaw eventRaw = new EventRaw();
//    private int wrapCount=0;
    private int timeZero = 0; // used to store initial timestamp for 4 byte timestamp reads to subtract this value
    private boolean readTimeZeroAlready = false;
    // receive buffer, allocated direct for speed
    private ByteBuffer buffer;
    private boolean timestampsEnabled = prefs.getBoolean("AEUnicastInput.timestampsEnabled",DEFAULT_TIMESTAMPS_ENABLED);
    private Semaphore pauseSemaphore = new Semaphore(1);
    private volatile boolean paused = false;
    private Reader readingThread = null;

    /** Constructs an instance of AEUnicastInput and binds it to the default port.
     * The port preference value may have been modified from the Preferences
     * default by a previous setPort() call which
     * stored the preference value.
     * <p>
     * This Thread subclass must be started in order to receive event packets.
     * @see AENetworkInterfaceConstants
     * 
     */
    public AEUnicastInput (){ // TODO basic problem here is that if port is unavailable, then we cannot construct and set port
        allocateBuffers();
    }

    /** Constructs a new AEUnicastInput using the given port number.
     *
     * @param port the UDP port number.
     * @see AEUnicastInput#AEUnicastInput()
     */
    public AEUnicastInput (int port){
        this();
        setPort(port);
    }

    private int eventSize (){
        if ( use4ByteAddrTs ){
            if ( timestampsEnabled ){
                return AENetworkInterfaceConstants.EVENT_SIZE_BYTES;
            } else{
                return 4;
            }
        } else{
            if ( timestampsEnabled ){
                return 4;
            } else{
                return 2;
            }
        }
    }

    /** Returns the latest buffer of events. If a timeout occurs occurs a null packet is returned.
     * @return the events collected since the last call to readPacket(), or null on a timeout or interrupt.
     */
    public AENetworkRawPacket readPacket (){
//        readingThread=Thread.currentThread();
        try{
            currentEmptyingBuffer = exchanger.exchange(currentEmptyingBuffer,1,TimeUnit.SECONDS);
            readingThread.maxSizeExceeded=false;
            // changed to remove timeout to explore effect on speed
            //currentEmptyingBuffer = exchanger.exchange(currentEmptyingBuffer, TIMEOUT_MS, TimeUnit.MILLISECONDS);
            if ( debugInput && currentEmptyingBuffer.getNumEvents() > 0 ){
                log.info("exchanged and returning readPacket=" + currentEmptyingBuffer);
            }
            return currentEmptyingBuffer;
        } catch ( InterruptedException e ){
            log.info("Interrupted exchange of buffers in AEUnicastInput: " + e.toString());
            return null;
        }
        catch (TimeoutException toe) {
            return null;
        }
    }

    synchronized private void allocateBuffers (){
        buffer = ByteBuffer.allocateDirect(bufferSize);
        buffer.order(swapBytesEnabled ? ByteOrder.LITTLE_ENDIAN : ByteOrder.BIG_ENDIAN);
    }

    private void checkSequenceNumber (){
        if ( sequenceNumberEnabled ){
            packetSequenceNumber = buffer.getInt(); // swab(buffer.getInt());
//                log.info("recieved packet with sequence number "+packetSequenceNumber);
            if ( packetSequenceNumber != packetCounter ){
                log.warning(String.format("Dropped %d packets. (Incoming packet sequence number (%d) doesn't match expected packetCounter (%d), resetting packetCounter to match present incoming sequence number)",packetSequenceNumber - packetCounter,packetSequenceNumber,packetCounter));
                packetCounter = packetSequenceNumber;
            }
        }
    }

    /** Receives a buffer from the UDP socket. Data is stored in internal buffer.
     *
     * @param packet used only to set number of events to 0 if there is an error.
     * @return client if successful, null if there is an IOException.
     */
    private SocketAddress receiveBuffer (AENetworkRawPacket packet){
        SocketAddress client = null;
        try{
            client = channel.receive(buffer); // fill buffer with data from datagram, blocks here until packet received
            if ( !printedHost ){
                printedHost = true;
                log.info("received first packet from " + client + " of length " + buffer.position() + " bytes"); // , connecting channel
                // do not connect so that multiple clients can send us data on the same port
                //                channel.connect(client); // TODO connect the channel to avoid security check overhead. TODO check if handles reconnects correctly.
            }
            if(client instanceof InetSocketAddress)  {
                packet.addClientAddress((InetSocketAddress)client, packet.getNumEvents());
            }else{
                if(client == null){
                    paused = true;
                    log.warning("Device not connected or wrong configured. Datagrams have to be sent to port: "+port+" .Input stream paused.");
                } else {
                    log.warning("unknown type of client address - should be InetSocketAddress: "+client);
                }
            }
        } catch ( SocketTimeoutException to ){
            // just didn't fill the buffer in time, ignore
            log.warning(to.toString());
            return null;
        } catch ( IOException e ){
            log.warning(e.toString());
            packet.clear();
            return null;
        } catch ( IllegalArgumentException eArg ){
            log.warning(eArg.toString());
            return null;
        }
        return client;
    }

    /** Adds to the packet supplied as argument by receiving
     * a single datagram and processing the data in it.
    @param packet the packet to add to.
     */
    synchronized private void receiveDatagramAndAddToCurrentEventPacket (AENetworkRawPacket packet) throws NullPointerException{
        if ( datagramSocket == null ){
            throw new NullPointerException("datagram socket became null for " + AEUnicastInput.this);
        }
        if ( receiveBuffer(packet)==null ){
            return;
        }
//        log.info("received buffer="+buffer);
        buffer.flip();
        if ( buffer.limit() < Integer.SIZE / 8 ){
            log.warning(String.format("DatagramPacket only has %d bytes, and thus doesn't even have sequence number, returning empty packet",buffer.limit()));
            packet.clear();
            buffer.clear();
            return;
        }
        packetCounter++;

        // debug
        if ( debugInput ){
            int nevents = buffer.remaining() / 8;
            int nstars = nevents;
            if ( nstars > 80 ){
                nstars = 80;
            }
            char[] ast = new char[ nstars ];
            for ( int i = 0 ; i < nstars ; i++ ){
                ast[i] = '*';
            }
            String asts = new String(ast);
            System.out.println(String.format("got packet %10d with %10d events:%s ",packetCounter,nevents,asts));
        }

        checkSequenceNumber();
        extractEvents(packet);
        buffer.clear();
    }

    /** Extracts data from internal buffer and adds to packet, according to all the option flags.
     *
     * @param packet to add events to.
     */
    private void extractEvents (AENetworkRawPacket packet){
        // extract the ae data and add events to the packet we are presently filling
        int seqNumLength = sequenceNumberEnabled ? Integer.SIZE / 8 : 0;
        int eventSize = eventSize();
        int nEventsInPacket = ( buffer.limit() - seqNumLength ) / eventSize;
        int ts = !timestampsEnabled || localTimestampsEnabled ? (int)( System.nanoTime() / 1000 ) : 0; // if no timestamps coming, add system clock for all.

        final int startingIndex = packet.getNumEvents();
        final int newPacketLength = startingIndex + nEventsInPacket;
        packet.ensureCapacity(newPacketLength);
        final int[] addresses = packet.getAddresses();
        final int[] timestamps = packet.getTimestamps();

        for ( int i = 0 ; i < nEventsInPacket ; i++ ){
            if ( addressFirstEnabled ){
                if ( use4ByteAddrTs ){
                    eventRaw.address = buffer.getInt(); // swab(buffer.getInt()); // swapInt is switched to handle big endian event sources (like ARC camera)
//                    int v=buffer.getInt();
                    if ( !localTimestampsEnabled && timestampsEnabled ){
                        int rawTime = buffer.getInt(); //swab(v);
//            if(rawTime<lastts) {
//                System.out.println("backwards timestamp at event "+i+"of "+nEventsInPacket);
//            }else if(rawTime!=lastts){
//                System.out.println("time jump at event "+i+"of "+nEventsInPacket);
//            }
//            lastts=rawTime;
                        int zeroedRawTime;
                        if ( readTimeZeroAlready ){
                            // TODO TDS sends 32 bit timestamp which overflows after multiplication
                            // by timestampMultiplier and cast to int jaer timestamp
                            zeroedRawTime = rawTime - timeZero;
                        } else{
                            readTimeZeroAlready = true;
                            timeZero = rawTime;
                            zeroedRawTime = 0;
                        }
//                        int v3 = 0xffff & v2; // TODO hack for TDS sensor which uses all 32 bits causing overflow after multiplication by multiplier and int cast
                        float floatFinalTime = timestampMultiplier * zeroedRawTime;
                        int finalTime;
                        if ( floatFinalTime >= Integer.MAX_VALUE || floatFinalTime<=Integer.MIN_VALUE ){
                            timeZero = rawTime; // after overflow reset timezero
                            finalTime = Integer.MIN_VALUE+(int)(floatFinalTime-Integer.MAX_VALUE); // Change to -2k seconds now - was: wrap around at 2k seconds, back to 0 seconds. TODO different than hardware which wraps back to -2k seconds
                        } else{
                            finalTime = (int)floatFinalTime;
                        }
                        eventRaw.timestamp = finalTime;
                    } else{
                        eventRaw.timestamp = ts;
                    }
                } else{
                    eventRaw.address = buffer.getShort()&0xffff; // swab(buffer.getShort()); // swapInt is switched to handle big endian event sources (like ARC camera)
//                    eventRaw.timestamp=(int) (timestampMultiplier*(int) swab(buffer.getShort()));
                    if ( !localTimestampsEnabled && timestampsEnabled ){
                        eventRaw.timestamp = (int)( timestampMultiplier * (int)buffer.getShort() );
                    } else{
                        eventRaw.timestamp = ts;
                    }
                }
            } else{
                if ( use4ByteAddrTs ){
//                    eventRaw.timestamp=(int) (swab(buffer.getInt()));
//                    eventRaw.address=swab(buffer.getInt());
                    if ( !localTimestampsEnabled && timestampsEnabled ){
                        eventRaw.timestamp = (int)( ( buffer.getInt() ) );
                    } else{
                        eventRaw.timestamp = ts;
                    }
                    eventRaw.address = ( buffer.getInt() );
                } else{
//                    eventRaw.timestamp=(int) (swab(buffer.getShort()));
//                    eventRaw.address=(int) (timestampMultiplier*(int) swab(buffer.getShort()));
                    if ( !localTimestampsEnabled && timestampsEnabled ){
                        eventRaw.timestamp = (int)( ( buffer.getShort() ) );  // TODO check if need AND with 0xffff to avoid negative timestamps
                    } else{
                        eventRaw.timestamp = ts;
                    }
                    eventRaw.address = (int)( timestampMultiplier * ( buffer.getShort()&0xffff ) );
                }
            }

            // alternative is to directly add to arrays of packet for speed, to bypass the capacity checking
//            packet.addEvent(eventRaw);
            addresses[startingIndex + i] = eventRaw.address;
            timestamps[startingIndex + i] = eventRaw.timestamp;

        }
        packet.setNumEvents(newPacketLength);

    }

    //debug
//    int lastts=0;
    @Override
    public String toString (){
        return "AEUnicastInput at PORT=" + getPort();
    }

    /** Interrupts the thread which is acquiring data and closes the underlying DatagramSocket.
     * 
     */
    public void close (){
        if ( channel != null && channel.isOpen() ){
            try{
                stopme = true;
                channel.close();
                datagramSocket.close();
            } catch ( IOException ex ){
                log.warning("on closing DatagramChannel caught " + ex);
            }
        }
//        if(datagramSocket!=null){
//            datagramSocket.close();
//        }
        // interrupt(); // TODO this interrupts the thread reading from the socket, but not the one that is blocked on the exchange
//        if(readingThread!=null) readingThread.interrupt();
    }

    /**@return "localhost". */
    public String getHost (){
        return "localhost";
    }

    private void cleanup (){
        try{
            datagramSocket.close();
        } catch ( Exception e ){
            log.warning("on closing caught " + e);
        }
    }

    /** resolves host, builds socket, returns true if it succeeds */
    private boolean checkSocket (){
        if ( channel != null && channel.isOpen() ){ //if(datagramSocket!=null && datagramSocket.isBound()) {
            return true;
        }
        try{
            channel = DatagramChannel.open();
            datagramSocket = channel.socket();
            datagramSocket.setReuseAddress(true);
            // disable timeout so that receive just waits for data forever (until interrupted)
//            datagramSocket.setSoTimeout(TIMEOUT_MS);
//            if (datagramSocket.getSoTimeout() != TIMEOUT_MS) {
//                log.warning("datagram socket read timeout value read=" + datagramSocket.getSoTimeout() + " which is different than timeout value of " + TIMEOUT_MS + " that we tried to set - perhaps timeout is not supported?");
//            }
            SocketAddress address = new InetSocketAddress(getPort());
            datagramSocket.bind(address);
            log.info("bound " + this);
            datagramSocket.setSoTimeout(0); // infinite timeout
            return true;
        } catch ( IOException e ){
            log.warning("caught " + e + ", datagramSocket will be constructed later");
            return false;
        }
    }

    /** Opens the input. Binds the port and starts the background receiver thread.
     * 
     * @throws java.io.IOException
     */
    public void open () throws IOException{  // TODO cannot really throw exception because socket is opened in Reader
        close();
        readingThread = new Reader();
        readingThread.start();
    }

    /** 
    @param host the hostname
     * @deprecated doesn't do anything here because we only set local port
     */
    public void setHost (String host){ // TODO all wrong, doesn't need host since receiver
        log.log(Level.WARNING, "setHost({0}) ignored for AEUnicastInput", host);
        // TODO should make new socket here too since we may have changed the host since we connected the socket
//        this.host=host;
//        prefs.put("AEUnicastInput.host", host);
    }

    public int getPort (){
        return port;
    }

    /** Set the local port number for receiving events.
     * 
     * @param port
     */
    public void setPort (int port){ // TODO all wrong
        this.port = port;
        prefs.putInt("AEUnicastInput.port",port);
        if ( port == this.port ){
            log.info("port " + port + " is already the bound port for " + this);
            return;
        }
        readTimeZeroAlready = false;
    }

    public boolean isSequenceNumberEnabled (){
        return sequenceNumberEnabled;
    }

    /** If set true (default), then an int32 sequence number is the first word of the packet. Otherwise the
     * first int32 is part of the first AE. 
     * 
     * @param sequenceNumberEnabled default true
     */
    public void setSequenceNumberEnabled (boolean sequenceNumberEnabled){
        this.sequenceNumberEnabled = sequenceNumberEnabled;
        prefs.putBoolean("AEUnicastInput.sequenceNumberEnabled",sequenceNumberEnabled);
    }

    /** @see #setAddressFirstEnabled */
    public boolean isAddressFirstEnabled (){
        return addressFirstEnabled;
    }

    /** If set true, the first int32 of each AE is the address, and the second is the timestamp. If false,
     * the first int32 is the timestamp, and the second is the address.
     * This parameter is stored as a preference.
     * @param addressFirstEnabled default true. 
     */
    public void setAddressFirstEnabled (boolean addressFirstEnabled){
        this.addressFirstEnabled = addressFirstEnabled;
        prefs.putBoolean("AEUnicastInput.addressFirstEnabled",addressFirstEnabled);
    }

    /** Java is big endian but intel native is little endian. If setSwapBytesEnabled(true), then
     * the bytes are swapped.  Use false for java to java transfers, or for java/native transfers
     * where the native side does not swap the data.
     * @param yes true to swap big/little endian address and timestamp data.
     */
    public void setSwapBytesEnabled (boolean yes){
        swapBytesEnabled = yes;
        prefs.putBoolean("AEUnicastInput.swapBytesEnabled",swapBytesEnabled);
        if ( buffer != null ){
            buffer.order(swapBytesEnabled ? ByteOrder.LITTLE_ENDIAN : ByteOrder.BIG_ENDIAN);
        }
    }

    public boolean isSwapBytesEnabled (){
        return swapBytesEnabled;
    }

    public float getTimestampMultiplier (){
        return timestampMultiplier;
    }

    /** Timestamps from the remote host are multiplied by this value to become jAER timestamps.
     * If the remote host uses 1 ms timestamps, set timestamp multiplier to 1000.
     * @param timestampMultiplier
     */
    public void setTimestampMultiplier (float timestampMultiplier){
        this.timestampMultiplier = timestampMultiplier;
        prefs.putFloat("AEUnicastInput.timestampMultiplier",timestampMultiplier);
    }

    // TODO javadoc
    public void set4ByteAddrTimestampEnabled (boolean yes){
        use4ByteAddrTs = yes;
        prefs.putBoolean("AEUnicastInput.use4ByteAddrTs",yes);
    }

    public boolean is4ByteAddrTimestampEnabled (){
        return use4ByteAddrTs;
    }

   public void setLocalTimestampEnabled(boolean yes) {
        localTimestampsEnabled=yes;
        prefs.putBoolean("AEUnicastOutput.localTimestampsEnabled",localTimestampsEnabled);
    }

    public boolean isLocalTimestampEnabled() {
        return localTimestampsEnabled;
    }

    /**
     * Returns the desired buffer size for datagrams in bytes.
     * @return the bufferSize in bytes.
     */
    public int getBufferSize (){
        return bufferSize;
    }

    /**
     * Sets the maximum datagram size that can be received in bytes. It is much faster to use small (e.g. 8k) packets than large
     * ones to minimize CPU usage.
     * @param bufferSize the bufferSize to set in bytes.
     */
    synchronized public void setBufferSize (int bufferSize){
        this.bufferSize = bufferSize;
        prefs.putInt("AEUnicastInput.bufferSize",bufferSize);
        allocateBuffers();
    }

    public boolean isTimestampsEnabled (){
        return timestampsEnabled;
    }

    /** If timestamps are enabled, then they are parsed from the input stream. If disabled, timestamps are added
     * using the System.nanoTime()/1000 system clock for all events in the packet.
     * @param yes true to enable parsing of timestamps.
     */
    public void setTimestampsEnabled (boolean yes){
        timestampsEnabled = yes;
        prefs.putBoolean("AEUnicastInput.timestampsEnabled",yes);
    }

    public void setPaused (boolean yes){
        paused = yes;
        readingThread.interrupt();
        // following deadlocks with exchanger
//        if ( yes ){
//            try{
//                pauseSemaphore.acquire();
//            } catch ( InterruptedException ex ){
//                log.info(ex.toString());
//            }
//        } else{
//            pauseSemaphore.release();
//        }
    }

    public boolean isPaused (){
        return paused;
//        return pauseSemaphore.availablePermits() == 0;
    }

    public void propertyChange (PropertyChangeEvent evt){
//        log.info(evt.toString());
//        if ( evt.getPropertyName().equals("paused") ){
//            setPaused((Boolean)evt.getNewValue());
//        }
    }
    //    private int swab(int v) {
//        return v;
//        // TODO now handled by ByteBuffer.order
////        if(swapBytesEnabled) {
////            return ByteSwapper.swap(v);
////        } else {
////            return v;
////        }
//    }
//
//    private short swab(short v) {
//        return v;
//
////        if(swapBytesEnabled) {
////            return ByteSwapper.swap(v);
////        } else {
////            return v;
////        }
//    }
    private class Reader extends Thread{
        volatile boolean maxSizeExceeded=false;

        /** Bumps priority and names thread */
        public Reader (){
            super("AEUnicastInput.Reader");
            setPriority(Thread.NORM_PRIORITY + 1);
        }

        /** This run method loops forever, filling the current filling buffer so that readPacket can return data
         * that may be processed while the other buffer is being filled.
         */
        @Override
        public void run (){
            while ( !stopme ){
//                try{
//                    pauseSemaphore.acquire();
//                } catch ( InterruptedException ex ){
//                    log.info(ex.toString());
//                }
                if ( !checkSocket() ){
                    // if port cannot be bound, just try again in a bit
                    try{
                        Thread.sleep(1000);
                    } catch ( Exception e ){
                        log.warning("tried to bind " + this + " but got " + e);
                    }
                    continue;
                }
                if(currentFillingBuffer.getNumEvents()>=AEPacket.MAX_PACKET_SIZE_EVENTS){
                    if(!maxSizeExceeded){
                        log.warning("currentFillingBuffer "+currentFillingBuffer+" has more than "+AEPacket.MAX_PACKET_SIZE_EVENTS+" disabling filling until packet is read");
                        maxSizeExceeded=true;
                    }
                }
                // try to receive a datagram packet and add it to the currentFillingBuffer - but this call will timeout after some ms
                if ( !maxSizeExceeded && !paused ){ // if paused, don't overrun memory
                    try{
                        receiveDatagramAndAddToCurrentEventPacket(currentFillingBuffer);
                    } catch ( NullPointerException e ){
                        log.warning(e.toString());
                        break;
                    }
                }
//            long t = System.currentTimeMillis();
//            if (currentFillingBuffer.getNumEvents() >= MAX_EVENT_BUFFER_SIZE || (t - lastExchangeTime > MIN_INTERVAL_MS)) {
////                    System.out.println("swapping buffer to rendering: " + currentFillingBuffer);
//                lastExchangeTime = t;
                // TODO if the rendering thread does not ask for a buffer, we just sit here - in the meantime incoming packets are lost
                // because we are not calling receive on them.
                // currentBuffer starts as initialEmptyBuffer that we initially captured to, after exchanger,
                // current buffer is initialFullBuffer
                try{
                    currentFillingBuffer = exchanger.exchange(currentFillingBuffer,0,TimeUnit.MILLISECONDS); // get buffer to write to from consumer thread
                    // timeout set to zero so that we time out immediately if rendering isn't asking for data now, in which case we try again to read a datagram with addToBuffer
                    currentFillingBuffer.clear(); // reset event counter
                } catch ( InterruptedException ex ){
                    log.info("interrupted");
                    stopme = true;
                    break;
                } catch ( TimeoutException ex ){
                    // didn't exchange within timeout, just add more events since we didn't get exchange request from the consumer this time
                } finally{
//                    pauseSemaphore.release();
                }
            }
            log.info("closing datagramSocket");
            cleanup();
        }
    };
}
