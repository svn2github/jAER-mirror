/*
 * EyeFilter.java
 *
 * Created on June 16, 2008
 *
 * This filter processes BinocularEvents (generated by the stereoboard chip for example)
 * to let pass event through according to two criteria : Left or Right retina
 * and (added for convenience) ON or OFF events
 */

package net.sf.jaer.stereopsis;

import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import java.util.*;

/**
 * This filter processes BinocularEvents (generated by the stereoboard chip for example)
 * to let pass event through according to two criteria : Left or Right retina
 * and (added for convenience) ON or OFF events
 * (This filter may be slowing down real-time applications)
 * @author rogister
 */
public class EyeFilter extends EventFilter2D implements Observer  {

    public static String getDescription() {
        return "Filters chosen binocolar eye (or polarity) for stereo retinas";
    }
    protected final int RIGHT = 1;
    protected final int LEFT = 0;
    private boolean left = getPrefs().getBoolean("EyeFilter.left", true);
    private boolean right = getPrefs().getBoolean("EyeFilter.right", true);

    // filtering on and off events is added for convenience here but could be removed
    // as it could be another filter and slow down the filter
   protected final int ON = 1;
   protected final int OFF = 0;
   private boolean on = getPrefs().getBoolean("EyeFilter.on", true);
   private boolean off = getPrefs().getBoolean("EyeFilter.off", true);

    
    public EyeFilter(AEChip chip){
        super(chip);
        chip.addObserver(this);
        initFilter();
        resetFilter();
    }
    
   
    /**
     * filters in to out. if filtering is enabled, the number of out may be less
     * than the number put in 
     *@param in input events can be null or empty.
     *@return the processed events, may be fewer in number. filtering may occur in place in the in packet.
     */
    synchronized public EventPacket filterPacket(EventPacket in) {
        if (!filterEnabled) {
            return in;
        }
        if (enclosedFilter != null) {
            in = enclosedFilter.filterPacket(in);
        }
        checkOutputPacketEventType(in);
        OutputEventIterator outItr = out.outputIterator();
        for (Object e : in) {
            if (e instanceof BinocularEvent) {
                BinocularEvent i = (BinocularEvent) e;
                int leftOrRight = i.eye == BinocularEvent.Eye.LEFT ? 0 : 1; //be sure if left is same as here
        
                if((left&&(leftOrRight==LEFT))||(right&&(leftOrRight==RIGHT))){
                    if ((on && (i.type == ON)) || (off && (i.type == OFF))) {

                        BinocularEvent o = (BinocularEvent) outItr.nextOutput();
                        o.copyFrom(i);
                    }
                }
            }



        }

        return out;
    }
    
   
    
 
    
   public Object getFilterState() {
        return null;
   }
    
   
    
    synchronized public void resetFilter() {
        
    }
    
    
    public void update(Observable o, Object arg) {
//        if(!isFilterEnabled()) return;
        initFilter();
    }
    
    public void initFilter() {
        
    }

   

    public void setLeft(boolean left){
        this.left = left;
        
        getPrefs().putBoolean("EyeFilter.left",left);
    }
    public boolean isLeft(){
        return left;
    }
    
     public void setRight(boolean right){
        this.right = right;
        
        getPrefs().putBoolean("EyeFilter.right",right);
    }
    public boolean isRight(){
        return right;
    }
    
      public void setOn(boolean on){
        this.on = on;
        
        getPrefs().putBoolean("EyeFilter.on",on);
    }
    public boolean isOn(){
        return on;
    }
    
      public void setOff(boolean off){
        this.off = off;
        
        getPrefs().putBoolean("EyeFilter.off",off);
    }
    public boolean isOff(){
        return off;
    }
    
}
