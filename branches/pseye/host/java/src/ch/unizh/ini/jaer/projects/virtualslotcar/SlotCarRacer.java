/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.virtualslotcar;

import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.SpikeSound;
import net.sf.jaer.util.StateMachineStates;
import net.sf.jaer.util.TobiLogger;

// clip throttle to hard limit
/**
 * Controls slot car tracked from eye of god view.
 *
 * @author tobi
 *
 * This is part of jAER
<a href="http://jaer.wiki.sourceforge.net">jaer.wiki.sourceforge.net</a>,
licensed under the LGPL (<a href="http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License">http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License</a>.
 */
@Description("Slot car racer project, Telluride 2010")
public class SlotCarRacer extends EventFilter2D implements FrameAnnotater{
    private boolean overrideThrottle = prefs().getBoolean("SlotCarRacer.overrideThrottle", true);
    private float overriddenThrottleSetting = prefs().getFloat("SlotCarRacer.overriddenThrottleSetting", 0);
    private float maxThrottle = prefs().getFloat("SlotCarRacer.maxThrottle", 1);
    private boolean playThrottleSound = prefs().getBoolean("SlotCarRacer.playThrottleSound", true);
    private TobiLogger tobiLogger;
    private SlotCarHardwareInterface hw;
    private TwoCarTracker.TwoCarCluster car = null;
    private FilterChain filterChain;
    private AbstractSlotCarController throttleController;
    private SpikeSound spikeSound;
    private float playSoundThrottleChangeThreshold = 0.01F;
    private float lastSoundThrottleValue = 0;
    private long lastTimeSoundPlayed;
    private ThrottleBrake lastThrottle = new ThrottleBrake();

    private void playThrottleSounds() {
        if(playThrottleSound && lastThrottle.brake){
                 if (spikeSound == null) {
                    spikeSound = new SpikeSound();
                }
                 spikeSound.play(0);
        }
        if (playThrottleSound && Math.abs(lastThrottle.throttle - lastSoundThrottleValue) > playSoundThrottleChangeThreshold) {
            long now;
            if (lastThrottle.throttle > lastSoundThrottleValue && (now = System.currentTimeMillis()) - lastTimeSoundPlayed > 5) {
                if (spikeSound == null) {
                    spikeSound = new SpikeSound();
                }
                spikeSound.play(1);
                lastTimeSoundPlayed = now;
            }
            lastSoundThrottleValue = lastThrottle.throttle;
        }
    }

    public enum ControllerToUse {

        SimpleSpeedController, CurvatureBasedController, LookUpBasedTrottleController, EvolutionaryThrottleController
    };
    private ControllerToUse controllerToUse = ControllerToUse.valueOf(prefs().get("SlotCarRacer.controllerToUse", ControllerToUse.SimpleSpeedController.toString()));

    /** possible states,
     * <ol>
     * <li> STARTING means no car is tracked or tracker has not found a car cluster near the track model,
     * <li> RUNNING is the active state,
     * <li> CRASHED is the state if we were RUNNING and the car tracker has tracked the car
     * sufficiently far away from the track model,
     * <li> STALLED is the state if the car has stopped being tracked but the last tracked position was on the track
     * because it has stalled out and stopped moving. is after there have not been any definite balls for a while and we are waiting for a clear ball directed
     * </ol>
     */
    public enum State {

        OVERRIDDEN, RUNNING
    }

    protected class RacerState extends StateMachineStates {

        State state = State.RUNNING;

        @Override
        public Enum getInitial() {
            return isOverrideThrottle() ? State.OVERRIDDEN : State.RUNNING;
        }
    }
    private RacerState state = new RacerState();

    public SlotCarRacer(AEChip chip) {
        super(chip);
        hw = new SlotCarHardwareInterface();


        filterChain = new FilterChain(chip);

        setControllerToUse(controllerToUse);

        setEnclosedFilterChain(filterChain);

        tobiLogger = new TobiLogger("SlotCarRacer", "racer data " + throttleController.logContents());

        // tooltips for properties
        final String con = "Controller", dis = "Display", ov = "Override", vir = "Virtual car", lg = "Logging";
        setPropertyTooltip(con, "desiredSpeed", "Desired speed from speed controller");
        setPropertyTooltip(ov, "overrideThrottle", "Select to override the controller throttle setting");
        setPropertyTooltip(con, "maxThrottle", "Absolute limit on throttle for safety");
        setPropertyTooltip(ov, "overriddenThrottleSetting", "Manual overidden throttle setting");
//        setPropertyTooltip(vir, "virtualCarEnabled", "Enable display of virtual car on virtual track");
        setPropertyTooltip(lg, "logRacerDataEnabled", "enables logging of racer data");
        setPropertyTooltip(con, "controllerToUse", "Which controller to use to control car throttle");
        setPropertyTooltip("playThrottleSound", "plays a spike when throttle is increased to indicate controller active");
        setPropertyTooltip("playSoundThrottleChangeThreshold", "threshold change in throttle to play sound");

    }

 

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        out = getEnclosedFilterChain().filterPacket(in);
        
        lastThrottle.copyFrom(throttleController.getThrottle()); // copy from profile for example
        // clip and apply override
        lastThrottle.throttle = lastThrottle.throttle > maxThrottle ? maxThrottle : lastThrottle.throttle;
        if(isOverrideThrottle()){
            lastThrottle.throttle=getOverriddenThrottleSetting();
            lastThrottle.brake=false;
        }

        // send to hardware
        hw.setThrottle(lastThrottle);

        if (isLogRacerDataEnabled()) {
            logRacerData(throttleController.logControllerState());
        }

        playThrottleSounds();
        return out;
    }


    @Override
    public void resetFilter() {
        if (hw.isOpen()) {
            lastThrottle.throttle=0;
            lastThrottle.brake=false;
            hw.setThrottle(lastThrottle);
            hw.close();
        }
        filterChain.reset();
    }

    @Override
    public void initFilter() {
    }

    @Override
    public synchronized void annotate(GLAutoDrawable drawable) { // TODO may not want to synchronize here since this will block filtering durring annotation
        MultilineAnnotationTextRenderer.resetToYPositionPixels(chip.getSizeY());

        String s = "SlotCarRacer\nstate: " + state.toString() + "\nthrottle: " + lastThrottle ;
        MultilineAnnotationTextRenderer.renderMultilineString(s);
    }

    /**
     * @return the overrideThrottle
     */
    public boolean isOverrideThrottle() {
        return overrideThrottle;
    }

    /**
     * Overrides any controller action to manually control the throttle.
     *
     * @param overrideThrottle the overrideThrottle to copyFrom
     */
    public void setOverrideThrottle(boolean overrideThrottle) {
        this.overrideThrottle = overrideThrottle;
        prefs().putBoolean("SlotCarRacer.overrideThrottle", overrideThrottle);
        if (overrideThrottle) {
            state.set(State.OVERRIDDEN);
        } else {
            state.set(State.RUNNING);
        }
    }

    /**
     * @return the overriddenThrottleSetting
     */
    public float getOverriddenThrottleSetting() {
        return overriddenThrottleSetting;
    }

    /**
     * Sets the value of the throttle override throttle.
     *
     * @param overriddenThrottleSetting the overriddenThrottleSetting to copyFrom
     */
    public void setOverriddenThrottleSetting(float overriddenThrottleSetting) {
        this.overriddenThrottleSetting = overriddenThrottleSetting;
        prefs().putFloat("SlotCarRacer.overriddenThrottleSetting", overriddenThrottleSetting);
    }

    // for GUI slider
    public float getMaxOverriddenThrottleSetting() {
        return 1;
    }

    public float getMinOverriddenThrottleSetting() {
        return 0;
    }

    public synchronized void setLogRacerDataEnabled(boolean logDataEnabled) {
        tobiLogger.setEnabled(logDataEnabled);
        throttleController.setLoggingEnabled(logDataEnabled);
    }

    public synchronized void logRacerData(String s) {
        tobiLogger.log(lastThrottle+" "+s);
    }

    public boolean isLogRacerDataEnabled() {
        if (tobiLogger == null) {
            return false;
        }
        return tobiLogger.isEnabled();
    }

    /**
     * @return the maxThrottle
     */
    public float getMaxThrottle() {
        return maxThrottle;
    }

    /**
     *  Sets the failsafe maximum throttle that overrides any controller action.
     * @param maxThrottle the maxThrottle to copyFrom
     */
    public void setMaxThrottle(float maxThrottle) {
        if (maxThrottle > 1) {
            maxThrottle = 1;
        } else if (maxThrottle < 0) {
            maxThrottle = 0;
        }
        this.maxThrottle = maxThrottle;
        prefs().putFloat("SlotCarRacer.maxThrottle", maxThrottle);
    }

    public float getMaxMaxThrottle() {
        return 1;
    }

    public float getMinMaxThrottle() {
        return 0;
    }

    /**
     * @return the controllerToUse
     */
    public ControllerToUse getControllerToUse() {
        return controllerToUse;
    }

    /**
     * Swaps in the chosen controller and rebuilds the GUI and filterChain.
     *
     * @param controllerToUse the controllerToUse to copyFrom
     */
    synchronized final public void setControllerToUse(ControllerToUse controllerToUse) {
        this.controllerToUse = controllerToUse;
        try {
            switch (controllerToUse) {
                case SimpleSpeedController:
                    if (throttleController == null || !(throttleController instanceof SimpleSpeedController)) {
                        filterChain.remove(throttleController);
                        throttleController = new SimpleSpeedController(chip);
                    }
                    break;
                case CurvatureBasedController:
                    if (throttleController == null || !(throttleController instanceof CurvatureBasedController)) {
                        filterChain.remove(throttleController);
                        throttleController = new CurvatureBasedController(chip);
                    }
                    break;
                case LookUpBasedTrottleController:
                    if (throttleController == null || !(throttleController instanceof LookUpBasedTrottleController)) {
                        filterChain.remove(throttleController);
                        throttleController = new LookUpBasedTrottleController(chip);
                    }
                    break;
                case EvolutionaryThrottleController:
                    if (throttleController == null || !(throttleController instanceof EvolutionaryThrottleController)) {
                        filterChain.remove(throttleController);
                        throttleController = new EvolutionaryThrottleController(chip);
                    }
                    break;
                default:
                    throw new RuntimeException("Unknown controller " + controllerToUse);
            }
            throttleController.setFilterEnabled(true);
            filterChain.add(throttleController);
            throttleController.setEnclosed(true, this);
            if (chip.getAeViewer() != null && chip.getAeViewer().getFilterFrame() != null) {
                chip.getAeViewer().getFilterFrame().rebuildContents();
            }
            prefs().put("SlotCarRacer.controllerToUse", controllerToUse.toString());
            log.info("set throttleController to instance of " + throttleController.getClass());
        } catch (Exception e) {
            log.warning(e.toString());
        }
    }

    /**
     * @return the playThrottleSound
     */
    public boolean isPlayThrottleSound() {
        return playThrottleSound;
    }

    /**
     * @param playThrottleSound the playThrottleSound to copyFrom
     */
    public void setPlayThrottleSound(boolean playThrottleSound) {
        this.playThrottleSound = playThrottleSound;
        prefs().putBoolean("SlotCarRacer.playThrottleSound", playThrottleSound);
    }

    /**
     * @return the playSoundThrottleChangeThreshold
     */
    public float getPlaySoundThrottleChangeThreshold() {
        return playSoundThrottleChangeThreshold;
    }

    /**
     * @param playSoundThrottleChangeThreshold the playSoundThrottleChangeThreshold to copyFrom
     */
    public void setPlaySoundThrottleChangeThreshold(float playSoundThrottleChangeThreshold) {
        this.playSoundThrottleChangeThreshold = playSoundThrottleChangeThreshold;
    }

}
