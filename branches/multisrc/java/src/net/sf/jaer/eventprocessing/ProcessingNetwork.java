/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing;

import java.util.ArrayList;
import java.util.concurrent.Semaphore;
import net.sf.jaer.event.EventPacket;

/**
 * This is an equivalent to the filter-chain that can include multi-input filters.
 * 
 * 
 * @author Peter
 */
public class ProcessingNetwork {
    
    int[] executionOrder;
    
    ArrayList<PacketStream> inputStreams=new ArrayList();
    
    ArrayList<Node> nodes=new ArrayList();
    
    
    /** Mainly for back-compatibility.  Build the processing network out of a 
     * filter-chain.
     * @param ch 
     */
    public void buildFromFilterChain(FilterChain ch)
    {
        nodes.clear();
        
        for (int i=0; i<ch.size(); i++)
        {   EventFilter2D philly=ch.get(i);
            nodes.add(new Node(philly,i));
        }
    }
    
    /** Set the list of input streams */
    public void setInputStreams(ArrayList<PacketStream> ins)
    {
        inputStreams=ins;
    }
    
    
    class Node implements PacketStream
    {   
        int nodeID;
        EventFilter2D filt;
        boolean isMultiInput=false;
        ArrayList<PacketStream> sources;
        EventPacket outputPacket;
        
        public Node(EventFilter2D philt,int id)
        {
            filt=philt;
            
            nodeID=id;
            // This is a sinful use of instanceof, but it's all in the name of 
            // backwards-compatibility
            isMultiInput=philt instanceof MultiSensoryFilter;
            
        }
        
        /** Return a list of possible input sources */
        public ArrayList<PacketStream> getSourceOptions()
        {   
            ArrayList<PacketStream> arr=new ArrayList();
            
            for (PacketStream p:inputStreams)
                arr.add(p);
            
            
            // TODO: modify list to prevent circular dependencies
            for (PacketStream p:nodes)
                if (p!=this)
                    arr.add(p);
            
            return arr;
        }
        
        
        /** Do the processing for this node */
        void process() {
            if (isMultiInput) {
                ArrayList<EventPacket> inputs=new ArrayList();
                for (PacketStream n :sources)
                    inputs.add(n.getPacket());       
                
                outputPacket=((MultiSensoryFilter)filt).filterPackets(inputs);
                
            } else {
                outputPacket=filt.filterPacket(sources.get(0).getPacket());
            }

        }

        @Override
        public EventPacket getPacket() {
            throw new UnsupportedOperationException("Not supported yet.");
        }

        @Override
        public void setSemaphore(Semaphore semi) {
        }

        @Override
        public String getName() {
            String name= filt.getClass().getName();
            return nodeID+": "+name.substring(name.lastIndexOf('.') + 1);
        }
        
        public int nInputs()
        {
            if (filt instanceof MultiSensoryFilter)
            {   return ((MultiSensoryFilter)filt).nInputs();
            }
            else
            {   return 1;
            }
        }
        
        /** Get the names of the inputs */
        public String[] getInputNames()
        {
            if (filt instanceof MultiSensoryFilter)
            {   return ((MultiSensoryFilter)filt).getInputNames();
            }
            else
            {   return new String[] {"input"};
            }
            
        }
        
    }
    
    /** 
     * Get the order in which to execute the filters such that all dependent 
     * filters have been run before the filter which requires them.
     * @TODO: implement
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
            nodes.get(i).process();
        
        ArrayList<EventPacket> outputs=new ArrayList();
        for (Node n:nodes)
            outputs.add(n.outputPacket);
        
        return outputs;
        
    }
    
    
    
}
