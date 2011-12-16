/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.gesture.proximity;

import java.util.Observable;
import java.util.Observer;
import java.util.Timer;
import java.util.TimerTask;
import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.filter.EventRateEstimator;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.HasLEDControl;

/**
 * Detects proximity of hand or object by looking for events generated by response of sensor to flashing LED which illuminates the nearby scene.
 * 
 * @author tobi
 */
@Description("Proximity detection using flashing LED that illuminates nearby scene")
public class ProximityLEDDetector extends EventFilter2D implements Observer {
    
    private HasLEDControl ledControl=null;
    private boolean proximityDetected=false;
    /** Event that is fired on change of proximity */
    public static final String PROXIMITY="proximity";
    private Timer ledTimer=null;
    private long periodMs=20;
    private int timewindowMs=3;
    private long lastLedChangeTimeNs;
    private EventRateEstimator rateEstimator=null;
    
    
    public ProximityLEDDetector(AEChip chip) {
        super(chip);
        rateEstimator=new EventRateEstimator(chip);
        setEnclosedFilterChain(new FilterChain(chip));
        getEnclosedFilterChain().add(rateEstimator);
        chip.addObserver(this);
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        rateEstimator.filterPacket(in);
        return in;
        
    }
    
    private class LEDSetterTask extends TimerTask{

        @Override
        public void run() {
            if(ledControl!=null){
                switch(ledControl.getLEDState(0)){
                    case ON:
                        ledControl.setLEDState(0, HasLEDControl.LEDState.OFF);
                        break;
                    case OFF:
                    case UNKNOWN:
                    case FLASHING:
                         ledControl.setLEDState(0, HasLEDControl.LEDState.ON);
                }
            }
        }
    }
    
    public boolean isProximityDetected(){
        return proximityDetected;
    }
    
    public void setProximityDetected(boolean yes){
        boolean old=this.proximityDetected;
        this.proximityDetected=yes;
        getSupport().firePropertyChange(PROXIMITY, old, proximityDetected); // updates GUI among others
    }

    @Override
    public void resetFilter() {
        getEnclosedFilterChain().reset();
    }

    @Override
    public void initFilter() {
    }

    @Override
    public synchronized void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        if(yes){
            ledTimer=new Timer("LED Flasher");
            ledTimer.schedule(new LEDSetterTask(), 0, periodMs);
        }else{
            if(ledTimer!=null) ledTimer.cancel();
            if(ledControl!=null) ledControl.setLEDState(0, HasLEDControl.LEDState.OFF);
        }
    }
    
    

    @Override
    public void update(Observable o, Object arg) {
        if(arg instanceof HasLEDControl){
            ledControl=(HasLEDControl)arg;
            ledControl.setLEDState(0, HasLEDControl.LEDState.OFF);
        }
    }
    
}
