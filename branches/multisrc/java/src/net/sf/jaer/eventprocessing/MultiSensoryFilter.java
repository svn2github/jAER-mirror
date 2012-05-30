/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.PriorityQueue;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;

/**
 *
 * @author Peter
 */
public abstract class MultiSensoryFilter extends EventFilter2D {
    
    public MultiSensoryFilter(AEChip chip) // Why is "chip" so tightly bound with viewing options??
    {   super(chip);        
    }
    
    abstract public void filterPacket(ArrayList<EventPacket> packets,int[] order);
    
    abstract public String[] getInputLabels();
    
    public void filterPacket(ArrayList<EventPacket> packets)
    {   filterPacket(packets,orderEvents(packets));
    }
    
    /**
     * Order Events by timestamp.  This returns an array of indeces which show 
     * the order in which packets should be sorted.
     * @param packets
     * @return 
     */
    public static int[] orderEvents(ArrayList<EventPacket> packets) {   // Quick and dirty, inefficient solution

        // A better solution would use a Priority queue and maybe some kind of sourced event
        // Right now this contains a quick and dirty solution to work with 1 or 2 inputs

        if (packets.size() == 1) {
            
            return new int[packets.get(0).getSize()];
            
        } else if (packets.size() == 2) {
            int[] arr = new int[packets.get(0).getSize() + packets.get(1).getSize()];

            int j = 0, k = 0;
            EventPacket p0 = packets.get(0);
            EventPacket p1 = packets.get(1);
            int p1size = p1.getSize();

            for (int i = 0; i < arr.length; i++) {
                if (k > p1size || p0.getEvent(j).timestamp < p1.getEvent(k).timestamp) {
                    arr[i] = j++;
                } else {
                    arr[i] = k++;
                }
            }
            return arr;
        } else {
            throw new UnsupportedOperationException("YOU GAVE US " +packets.size()+", BUT WE ONLY CURRENTLY HANDLE 1 or 2!!");
            //return new int[0];
        }


    }
    
    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        throw new UnsupportedOperationException("This filter type does not filter single packets.  Subclass off EventFilter2D instead if you want to do that.");
    }
}
