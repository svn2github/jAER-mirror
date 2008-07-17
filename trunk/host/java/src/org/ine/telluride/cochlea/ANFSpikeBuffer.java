/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package org.ine.telluride.cochlea;
import ch.unizh.ini.caviar.chip.AEChip;
import ch.unizh.ini.caviar.event.EventPacket;
import ch.unizh.ini.caviar.event.TypedEvent;
import ch.unizh.ini.caviar.eventprocessing.EventFilter2D;
/**
 * Extracts pitch from AE cochlea spike output.
 * 
 * @author ahs (Andrew Schwartz, MIT)
 */
public class ANFSpikeBuffer extends EventFilter2D{
    private static final int NUM_CHANS = 32;
    private int bufferSize=getPrefs().getInt("MSO.bufferSize",25);
    {setPropertyTooltip("bufferSize","Number of spikes held per channel/cochlea in ANF spike buffer");}
    
    private int[][][] spikeBuffer = null;
    private int[][] bufferIndex = null;
    private boolean[][] bufferFull = null;
        
    int chan, id, ii, jj;
    
    @Override
    public String getDescription() {
        return "Keep a buffer of spikes on each channel/cochlea";
    }
    
    public ANFSpikeBuffer(AEChip chip) {
        super(chip);

        resetFilter();
    }

    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        if(!isFilterEnabled()) return in;
        if(in==null) return in;

        for(Object o:in){
            TypedEvent e=(TypedEvent)o;
            chan = e.x & 31;
            id = ((e.x & 32)>0)?1:0;
            spikeBuffer[id][chan][bufferIndex[chan][id]] = e.timestamp;
            bufferIndex[id][chan]++;
            if (bufferIndex[id][chan]>bufferSize) {
                bufferIndex[id][chan]=0;
                if (!bufferFull[id][chan]) bufferFull[id][chan]=true;
                //would it be quicker to just write without checking?
            }
                    
        }
        //e.x, e.timestamp
        return in;
    }

    
    public int[][][] getBuffer() {
        return spikeBuffer;
    }
    
   
    public boolean[][] getBufferFull() {
        return bufferFull;
    }
    
    
    @Override
    public Object getFilterState() {
        return null;
    }

    @Override
    public void resetFilter() {
        //allcoate spike buffers
        spikeBuffer = new int[NUM_CHANS][2][bufferSize];
        bufferIndex = new int[NUM_CHANS][2];
        bufferFull = new boolean[NUM_CHANS][2];
        
        //initialize per-channel buffer values
        for (chan=0; chan<NUM_CHANS; chan++) {
            for (id=0;id<2;id++){
                for (ii=0;ii<bufferSize;ii++){
                    spikeBuffer[id][chan][ii] = 0;
                }
                bufferIndex[id][chan]=0;
                bufferFull[id][chan]=false;
            }
        }
        
   
    }

    @Override
    public void initFilter() {
    }

    public int getBufferSize() {
        return bufferSize;
    }

    public void setBufferSize(int bufferSize) {
        this.bufferSize = bufferSize;
        getPrefs().putInt("MSO.bufferSize",bufferSize);
    }
   
}
