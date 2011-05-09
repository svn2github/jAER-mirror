/*
 * SubSampler.java
 *
 * Created on March 4, 2006, 7:24 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright March 4, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */

package net.sf.jaer.eventprocessing.filter;

import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.*;
import net.sf.jaer.eventprocessing.EventFilter2D;

/**
 * Subsmaples input AE packets to produce output at some binary subsampling.
 *
 * @author tobi
 */
@Description("Subsamples x and y addresses")
@DevelopmentStatus(DevelopmentStatus.Status.Stable)
public class SubSampler extends EventFilter2D {
    
    private int bits;
    short shiftx, shifty;
        
    /** Creates a new instance of SubSampler */
    public SubSampler(AEChip chip) {
        super(chip);
        setBits(getPrefs().getInt("SubSampler.bits",1));
        computeShifts();
        setPropertyTooltip("bits","Subsample by this many bits, by masking these off X and Y addreses");
    }
    
    public Object getFilterState() {
        return null;
    }
    
    public void resetFilter() {
    }
    
    public void initFilter() {
    }
    
    public int getBits() {
        return bits;
    }
    
    @Override public void setFilterEnabled(boolean yes){
        super.setFilterEnabled(yes);
        computeShifts();
    }
    
    /** Sets the subsampler subsampling shift.
     @param bits the number of bits to subsample by, e.g. bits=1 divides by two
     */
    synchronized public void setBits(int bits) {
        if(bits<0) bits=0; else if(bits>8) bits=8;
        this.bits = bits;
        getPrefs().putInt("SubSampler.bits",bits);
        computeShifts();
    }
    
    private void computeShifts() {
        if(bits==0){
            shiftx=0; shifty=0; return;
        }
        int s1=chip.getSizeX();
        int s2=s1>>>bits;
        shiftx=(short)((s1-s2)/2);
        s1=chip.getSizeY();
        s2=s1>>>bits;
        shifty=(short)((s1-s2)/2);
    }
    
    synchronized public EventPacket filterPacket(EventPacket in) {
        if(in==null) return null;
        if(!filterEnabled) return in;
        if(enclosedFilter!=null) in=enclosedFilter.filterPacket(in);
        checkOutputPacketEventType(in);
        OutputEventIterator oi=out.outputIterator();
        for(Object obj:in){
            TypedEvent e=(TypedEvent)obj;
            TypedEvent o=(TypedEvent)oi.nextOutput();
            o.copyFrom(e);
            o.setX((short) ((e.x >>> bits) + shiftx));
            o.setY((short) ((e.y >>> bits) + shifty));
        }
        return out;
    }
    
}
