/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing;

import java.util.concurrent.Semaphore;
import net.sf.jaer.event.EventPacket;

/**
 * This interface pretty much just returns eventPackets.  Its function is to 
 * provide a common interface between AEviewers and Event Filters for grabbing packets.
 * 
 * @author Peter
 */
public interface PacketStream {
    
    EventPacket getPacket();
    
    /**
     * Sets the semaphore for a packet stream.  This only needs to be properly 
     * implemented for subclasses of Thread - otherwise, just leave this method 
     * empty and you'll be fine.
     */
    void setSemaphore(Semaphore semi);
    
    String getName();
    
    
}
