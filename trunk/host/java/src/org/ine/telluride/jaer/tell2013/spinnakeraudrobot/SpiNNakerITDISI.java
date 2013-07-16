/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.ine.telluride.jaer.tell2013.spinnakeraudrobot;

import ch.unizh.ini.jaer.projects.cochsoundloc.ISIFilter;
import ch.unizh.ini.jaer.projects.cochsoundloc.ITDFilter;
import java.io.IOException;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.SocketException;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.FilterChain;

/**
 * Combines ITDfilter and ISIFilter to supply heading direction to SpiNNaker using UDP packets to steer robot.
 * @author tobi
 */
@Description("Uses ITDFilter and ISI histograms to supply heading direction to SpiNNaker for Telluride 2013 UNS project")
public class SpiNNakerITDISI extends EventFilter2D{

    private ITDFilter itdFilter=null;
    private ISIFilter isiFilter=null;
    private int bestItdBin=-1;
    
    /* typedef struct // SDP header
        {
        uchar flags; // Flag byte
        uchar tag; // IP Tag byte
        uchar dest_port_cpu; // Destination Port & CPU
        uchar srce_port_cpu // Source Port & CPU
        ushort dest_addr; // Destination P2P Address
        ushort srce_addr; // Source P2P Address
        } sdp_hdr_t;
    */
    // communication to SpiNNaker
    private int spinnakerPort=getInt("spinnakerPort",9000); // TODO
    private String spinnakerHost=getString("spinnakerHost", "localhost");
    private int spinnakerDestCPU=getInt("spinnakerDestCPU",0);
    private int spinnakerDestPort=getInt("spinnakerDestPort",0);
    private int spinnakerSrcePort=getInt("spinnakerSrcePort",0);
    private int spinnakerSrceCPU=getInt("spinnakerSrceCPU",0);
    private int spinnakerDestAddrX=getInt("spinnakerDestAddrX",0);
    private int spinnakerDestAddrY=getInt("spinnakerDestAddrY",0);
    private int spinnakerSrceAddrX=getInt("spinnakerSrceAddrX",0);
    private int spinnakerSrceAddrY=getInt("spinnakerSrceAddrY",0);
    
    private InetSocketAddress client = null;
     private DatagramChannel channel = null;
    private ByteBuffer byteBuffer = ByteBuffer.allocateDirect(32);// the buffer to render/process first
   
    public SpiNNakerITDISI(AEChip chip) {
        super(chip);
        FilterChain filterChain=new FilterChain(chip);
        filterChain.add(itdFilter=new ITDFilter(chip));
        filterChain.add(isiFilter=new ISIFilter(chip));
        setEnclosedFilterChain(filterChain);
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        // check spinnaker UDP socket and construct bound to any available local port if it is null
        if(channel==null || client==null){
             try {
                 channel = DatagramChannel.open();
                 client = new InetSocketAddress(spinnakerHost,spinnakerPort);
            } catch (IOException ex) {
                log.warning(ex.toString());
                return in;
            }
        }
        getEnclosedFilterChain().filterPacket(in);
        int currentBestItdBin=itdFilter.getBestITD();
        if(currentBestItdBin!=bestItdBin){
            bestItdBin=currentBestItdBin;
            byteBuffer.clear();
            // construct SDP header, 8 bytes, according to https://spinnaker.cs.man.ac.uk/tiki-download_wiki_attachment.php?attId=16
            byteBuffer.put((byte)0); // pad
            byteBuffer.put((byte)0); // pad
            byteBuffer.put((byte)0x07); // flags, no reply expected
            byteBuffer.put((byte)0); // tags, not used here since we come from internet
            byteBuffer.put((byte)(0xff&(spinnakerDestPort&0x7)<<5 | (spinnakerDestCPU&0x1f)));
            byteBuffer.put((byte)(0xff&(spinnakerSrcePort&0x7)<<5 | (spinnakerSrceCPU&0x1f)));
            byteBuffer.put((byte)(0xff&spinnakerDestAddrX));
            byteBuffer.put((byte)(0xff&spinnakerDestAddrY));
            byteBuffer.put((byte)(0xff&spinnakerSrceAddrX));
            byteBuffer.put((byte)(0xff&spinnakerSrceAddrY));
            byteBuffer.put((byte)bestItdBin); // TODO supply heading direction
            try {
                channel.send(byteBuffer, client);
            } catch (IOException ex) {
                log.warning(ex.toString());
            }
        }
        
        return in;
    }

    @Override
    public void resetFilter() {
    }

    @Override
    public void initFilter() {
    }

    /**
     * @return the spinnakerPort
     */
    public int getSpinnakerPort() {
        return spinnakerPort;
    }

    /**
     * @param spinnakerPort the spinnakerPort to set
     */
    synchronized public void setSpinnakerPort(int spinnakerPort) {
        if(spinnakerPort!=this.spinnakerPort) client=null;
        this.spinnakerPort = spinnakerPort;
        putInt("spinnakerPort",spinnakerPort);
    }

    /**
     * @return the spinnakerHost
     */
    public String getSpinnakerHost() {
        return spinnakerHost;
    }

    /**
     * @param spinnakerHost the spinnakerHost to set
     */
    synchronized public void setSpinnakerHost(String spinnakerHost) {
         if(spinnakerHost!=this.spinnakerHost) client=null;
       this.spinnakerHost = spinnakerHost;
        putString("spinnakerHost",spinnakerHost);
    }

    /**
     * @return the spinnakerDestCPU
     */
    public int getSpinnakerDestCPU() {
        return spinnakerDestCPU;
    }

    /**
     * @param spinnakerDestCPU the spinnakerDestCPU to set
     */
    public void setSpinnakerDestCPU(int spinnakerDestCPU) {
        this.spinnakerDestCPU = spinnakerDestCPU;
        putInt("spinnakerDestCPU",spinnakerDestCPU);
    }

    /**
     * @return the spinnakerDestPort
     */
    public int getSpinnakerDestPort() {
        return spinnakerDestPort;
    }

    /**
     * @param spinnakerDestPort the spinnakerDestPort to set
     */
    public void setSpinnakerDestPort(int spinnakerDestPort) {
        this.spinnakerDestPort = spinnakerDestPort;
        putInt("spinnakerDestPort",spinnakerDestPort);
    }

    /**
     * @return the spinnakerSrcePort
     */
    public int getSpinnakerSrcePort() {
        return spinnakerSrcePort;
    }

    /**
     * @param spinnakerSrcePort the spinnakerSrcePort to set
     */
    public void setSpinnakerSrcePort(int spinnakerSrcePort) {
        this.spinnakerSrcePort = spinnakerSrcePort;
        putInt("spinnakerSrcePort",spinnakerSrcePort);
    }

    /**
     * @return the spinnakerSrceCPU
     */
    public int getSpinnakerSrceCPU() {
        return spinnakerSrceCPU;
    }

    /**
     * @param spinnakerSrceCPU the spinnakerSrceCPU to set
     */
    public void setSpinnakerSrceCPU(int spinnakerSrceCPU) {
        this.spinnakerSrceCPU = spinnakerSrceCPU;
        putInt("spinnakerSrceCPU",spinnakerSrceCPU);
    }

    /**
     * @return the spinnakerDestAddr
     */
    public int getSpinnakerDestAddrX() {
        return spinnakerDestAddrX;
    }

    /**
     * @param spinnakerDestAddr the spinnakerDestAddr to set
     */
    public void setSpinnakerDestAddrX(int spinnakerDestAddr) {
        this.spinnakerDestAddrX = spinnakerDestAddr;
        putInt("spinnakerDestAddrX",spinnakerDestAddr);
    }

        /**
     * @return the spinnakerDestAddr
     */
    public int getSpinnakerDestAddrY() {
        return spinnakerDestAddrY;
    }

    /**
     * @param spinnakerDestAddr the spinnakerDestAddr to set
     */
    public void setSpinnakerDestAddrY(int spinnakerDestAddr) {
        this.spinnakerDestAddrY = spinnakerDestAddr;
        putInt("spinnakerDestAddrY",spinnakerDestAddr);
    }

    /**
     * @return the spinnakerSrceAddr
     */
    public int getSpinnakerSrceAddrX() {
        return spinnakerSrceAddrX;
    }

    /**
     * @param spinnakerSrceAddr the spinnakerSrceAddr to set
     */
    public void setSpinnakerSrceAddrX(int spinnakerSrceAddr) {
        this.spinnakerSrceAddrX = spinnakerSrceAddr;
        putInt("spinnakerSrceAddrX",spinnakerSrceAddr);
    }
       /**
     * @return the spinnakerSrceAddr
     */
    public int getSpinnakerSrceAddrY() {
        return spinnakerSrceAddrX;
    }

    /**
     * @param spinnakerSrceAddr the spinnakerSrceAddr to set
     */
    public void setSpinnakerSrceAddrY(int spinnakerSrceAddr) {
        this.spinnakerSrceAddrY = spinnakerSrceAddr;
        putInt("spinnakerSrceAddrY",spinnakerSrceAddr);
    }
    
}
