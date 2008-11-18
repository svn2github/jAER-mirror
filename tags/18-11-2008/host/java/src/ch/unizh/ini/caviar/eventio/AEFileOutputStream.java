/*
 * AEOutputStream.java
 *
 * Created on December 26, 2005, 1:03 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package ch.unizh.ini.caviar.eventio;

import ch.unizh.ini.caviar.aemonitor.*;
import java.io.*;
import java.util.*;
import java.util.logging.*;

/**
 * Class to stream out packets of events in binary. The file format (as of version 2.0) is
 <br>
 int32 address
 <br>
 int32 timestamp
 <br>
 repeated for the number of events in the file.
 <p>
 Prior to version 2.0 files, each address was an int16 address.
 The timestamp tick is 1us.
 
 * @author tobi
 */
public class AEFileOutputStream extends DataOutputStream {
    
    private static Logger log=Logger.getLogger("AEOutputStream");
    
    private boolean writeHeader=true;
    private boolean wrotePacket=false;
    
//    ByteArrayOutputStream bos=new ByteArrayOutputStream();
    
    /** 
     Creates a new instance of AEOutputStream.
     *
     @param os an output stream, e.g. from <code>new BufferedOutputStream(new FileOutputStream(File f)</code>.
     */
    public AEFileOutputStream(OutputStream os) {
        super(os);
        if(writeHeader){
            try{
                writeHeaderLine(AEDataFile.DATA_FILE_FORMAT_HEADER+AEDataFile.DATA_FILE_VERSION_NUMBER);
                writeHeaderLine(" This is a raw AE data file - do not edit");
                writeHeaderLine(" Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event");
                writeHeaderLine(" Timestamps tick is "+AEConstants.TICK_DEFAULT_US+" us");
                writeHeaderLine(" created "+new Date());
            }catch(IOException e){
                e.printStackTrace();
            }
        }
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
     Writes a comment header line. Writes the string with prepended '#' and appended '\r\n'
     @param s the string
     */
    public void writeHeaderLine(String s) throws IOException {
        if(wrotePacket){
            log.warning("already wrote a packet, not writing the header");
            return;
        }
        writeByte('#');
        writeBytes(s);
        writeByte('\r');
        writeByte('\n');
    }
    
}

