/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventio;

import java.io.DataOutputStream;
import java.io.OutputStream;
import net.sf.jaer.aemonitor.AEPacketRaw;
import java.io.IOException;
import java.util.logging.Logger;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;

/**
 * Class to stream out packets of events in binary to a generic OutputStream. The stream format (as of version 2.0) is
 <br>
 int32 address
 <br>
 int32 timestamp
 <br>
 repeated for the number of events in the file.
 <p>
 Prior to version 2.0 streams, each address was an int16 address.
 The timestamp tick is 1us.

 * @author tobi
 * @see AEFileOutputStream
 */
public class AEOutputStream extends DataOutputStream {

    protected static Logger log=Logger.getLogger("AEOutputStream");

    /** Used to protect binary content from additional headers. */
    protected boolean wrotePacket=false;

    /**
     Creates a new instance of AEOutputStream.
     *
     @param os an output stream, e.g. from <code>new BufferedOutputStream(new FileOutputStream(File f)</code>.
     */
    public AEOutputStream(OutputStream os) {
        super(os);
    }

    /**
     * Writes the packet out as sequence of address/timestamp's, just as they came as input from the device. The notion of a packet is discarded
     *to simplify later reading an input stream from the output stream result.
     *@param ae a raw addresse-event packet
     */
    public void writePacket(AEPacketRaw ae) throws IOException {
        int n=ae.getNumEvents();
        int[] addr=ae.getAddresses();
        int[] ts=ae.getTimestamps();
//        writeInt(n);
        for(int i=0;i<n;i++){
            writeInt(addr[i]);  // changed from writeShort with change to int raw addressses in v2.0 format
            writeInt(ts[i]);
        }
        wrotePacket=true;
    }

    /**
     *  Writes a packet of events to the stream, using the events contained address and timestamp.
     * 
     * @param packet
     * @throws IOException
     * @since May 2010
     */
    public void writePacket(EventPacket<? extends BasicEvent> packet) throws IOException{
        for(BasicEvent e:packet){
            writeInt(e.address);
            writeInt(e.timestamp);
        }

    }

}
