/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing;

import java.util.ArrayList;
import net.sf.jaer.event.EventPacket;

/**
 * This is an equivalent to the filter-chain that can include multi-input filters.
 * 
 * @author Peter
 */
public class FilterNetwork {
    
    int[] executionOrder;
    Node[] nodes;
    
    class Node
    {   EventFilter2D filt;
        boolean isMultiInput=false;
        ArrayList<Node> sources;
        EventPacket outputPacket;
        
        void process() {
            if (isMultiInput) {
                ArrayList<EventPacket> inputs=new ArrayList();
                for (Node n :sources)
                    inputs.add(n.outputPacket);                
            } else {
                outputPacket=filt.filterPacket(sources.get(0).outputPacket);
            }

        }
        
    }
    
    /** 
     * Get the order in which to execute the filters such that all dependent 
     * filters have been run before the filter which requires them.
     */
    int[] defineExecutionOrder()
    {
        return new int[0];
    }
    
    /**
     * Filter packets, returning an array containing the output packet for each filter
     * @param packets
     * @return 
     */
    public ArrayList<EventPacket> filterPackets(ArrayList<EventPacket> packets)
    {
        for (int i:executionOrder)
            nodes[i].process();
        
        ArrayList<EventPacket> outputs=new ArrayList();
        for (Node n:nodes)
            outputs.add(n.outputPacket);
        
        return outputs;
        
    }
    
    
    
}
