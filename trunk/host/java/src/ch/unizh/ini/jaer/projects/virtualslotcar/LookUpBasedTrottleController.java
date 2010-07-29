/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.virtualslotcar;

import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;
import java.awt.geom.Point2D;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.tracking.ClusterInterface;
import net.sf.jaer.graphics.FrameAnnotater;

/**
 * Learns the throttle at different part of the track.
 * @author Juston, Tobi
 */
public class LookUpBasedTrottleController extends AbstractSlotCarController implements SlotCarControllerInterface, FrameAnnotater {
    private float fractionOfTrackToPunish  =prefs().getFloat("LookUpBasedTrottleController.fractionOfTrackToPunish",0.06f);

    private float throttle = 0; // last output throttle setting
    private float defaultThrottle = prefs().getFloat("CurvatureBasedController.defaultThrottle", .1f); // default throttle setting if no car is detected
    private float measuredSpeedPPS; // the last measured speed
    private Point2D.Float measuredLocation;
    private float throttleDelayMs = prefs().getFloat("CurvatureBasedController.throttleDelayMs", 200);
    private SimpleSpeedController speedController;
    private float maxDistanceFromTrackPoint = prefs().getFloat("CurvatureBasedController.maxDistanceFromTrackPoint", 30); // pixels - need to set in track model
    private SlotcarTrack track;
    private int currentTrackPos; // position in spline parameter of track
    private int lastTrackPos; // last position in spline parameter of track
    private int[] trackPos; // used to store points to punish
    private int nbsection;
    private int nbPreviewsStep =0;
    private ThrottleSection[] lookUpTable;
    private boolean learning = false;
    private boolean crash;
    private float throttleChange = prefs().getFloat("LookUpBasedTrottleController.throttleChange", 0.01f);
    boolean didPunishment=false;
    private float punishmentFactorIncrease=prefs().getFloat("LookUpBasedTrottleController.punishmentFactorIncrease",5);
    private int cte=0;

//eligibility trace
    public LookUpBasedTrottleController(AEChip chip) {
        super(chip);
        setPropertyTooltip("defaultThrottle", "default throttle setting if no car is detected");
        setPropertyTooltip("throttleDelayMs", "delay time constant of throttle change on speed; same as look-ahead time for estimation of track curvature");
        setPropertyTooltip("maxDistanceFromTrackPoint", "Maximum allowed distance in pixels from track spline point to find nearest spline point; if currentTrackPos=-1 increase maxDistanceFromTrackPoint");
        setPropertyTooltip("fractionOfTrackToPunish", "fraction of track to reduce throttle and mark for no reward");
    }

    /** Computes throttle using tracker output and upcoming curvature, using methods from SlotcarTrack.
     *
     * @param tracker
     * @param track
     * @return the throttle from 0-1.
     */
    @Override
    synchronized public float computeControl(CarTracker tracker, SlotcarTrack track) {
        // find the csar, pass it to the track if there is one to get it's location, the use the UpcomingCurvature to compute the curvature coming up,
        // then compute the throttle to get our speed at the limit of traction.
        ClusterInterface car = tracker.findCarCluster();
         {
            if (track == null) {
                log.warning("null track model - can't compute control");
                return getThrottle();
            }
            this.track = track; // set track for logging
            track.setPointTolerance(maxDistanceFromTrackPoint);
            
            measuredSpeedPPS = car==null? Float.NaN: (float) car.getSpeedPPS();
            measuredLocation = car==null? null: car.getLocation();


            nbsection = track.getNumPoints();//load the number of section
            if (lookUpTable == null || lookUpTable.length != track.getNumPoints()) {
                lookUpTable = new ThrottleSection[nbsection];

            }
              if (trackPos==null || nbPreviewsStep != (int) (nbsection * fractionOfTrackToPunish)){
                  nbPreviewsStep = (int) (nbsection * fractionOfTrackToPunish);
                  trackPos = new int[nbPreviewsStep];
              }
            SlotcarState carState = track.updateSlotcarState(measuredLocation, measuredSpeedPPS);
            setCrash(!carState.onTrack);
            if (!crash) {
                didPunishment=false;
                currentTrackPos = carState.segmentIdx;
                if (lookUpTable[currentTrackPos] == null) {
                    lookUpTable[currentTrackPos] = new ThrottleSection(currentTrackPos);
                }
                if (currentTrackPos != lastTrackPos) { // update table of positions to later credit with crash
                    for (int i = nbPreviewsStep-1; i > 0; i--) {
                        trackPos[i] = trackPos[i - 1];
                    }
                    trackPos[0] = currentTrackPos;
                    lastTrackPos = currentTrackPos;
                
                    if (learning && lookUpTable[currentTrackPos].definethrottle < 1) {
                        lookUpTable[currentTrackPos].maybeReward(currentTrackPos);
                    }
                }
            }else if(!didPunishment){
                didPunishment=true;
                for (int i = 1; i < nbPreviewsStep; i++) {
                    if (trackPos[1]-i+1<0){
                        cte=nbsection;
                    }else{
                        cte=0;
                    }
                    if (lookUpTable[trackPos[1]-i+1+cte]!=null){
                        lookUpTable[trackPos[1]-i+1+cte].punish(i);
                    }

                }
                //learning=false;
            }


            throttle = lookUpTable[currentTrackPos]==null ? defaultThrottle : lookUpTable[currentTrackPos].definethrottle;
            return throttle;
        }
    }

    synchronized public void doResetAllThrottleValues() {
        lookUpTable = null;
    }

    private float clipThrottle(float t) {
        if (t > 1) {
            t = 1;
        } else if (t < defaultThrottle) {
            t = defaultThrottle;
        }
        return t;
    }

    @Override
    public float getThrottle() {
        return throttle;
    }

    @Override
    public String logControllerState() {
        return String.format("%f\t%f\t%s", measuredSpeedPPS, throttle, track == null ? null : track.getCarState());
    }

    @Override
    public String getLogContentsHeader() {
        return "upcomingCurvature, lateralAccelerationLimitPPS2, desiredSpeedPPS, measuredSpeedPPS, throttle, slotCarState";
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        return in;
    }

    @Override
    public void resetFilter() {
    }

    @Override
    public void initFilter() {
    }

    /**
     * @return the defaultThrottle
     */
    public float getDefaultThrottle() {
        return defaultThrottle;
    }

    /**
     * @param defaultThrottle the defaultThrottle to set
     */
    public void setDefaultThrottle(float defaultThrottle) {
        this.defaultThrottle = defaultThrottle;
        prefs().putFloat("CurvatureBasedController.defaultThrottle", defaultThrottle);
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        String s = String.format("LookUpBasedTrottleController\ncurrentTrackPos: %d\nThrottle: %8.3f", currentTrackPos, throttle);
        MultilineAnnotationTextRenderer.renderMultilineString(s);
    }

    /**
     * @return the maxDistanceFromTrackPoint
     */
    public float getMaxDistanceFromTrackPoint() {
        return maxDistanceFromTrackPoint;
    }

    /**
     * @param maxDistanceFromTrackPoint the maxDistanceFromTrackPoint to set
     */
    public void setMaxDistanceFromTrackPoint(float maxDistanceFromTrackPoint) {
        this.maxDistanceFromTrackPoint = maxDistanceFromTrackPoint;
        prefs().putFloat("CurvatureBasedController.maxDistanceFromTrackPoint", maxDistanceFromTrackPoint);
        // Define tolerance for track model
        track.setPointTolerance(maxDistanceFromTrackPoint);
    }

    /**
     * @return the learning
     */
    public boolean isLearning() {
        return learning;
    }

    /**
     * @param learning the learning to set
     */
    public void setLearning(boolean learning) {
        this.learning = learning;
    }

    /**
     * @return the crash
     */
    public boolean isCrash() {
        return crash;
    }

    /**
     * @param crash the crash to set
     */
    public void setCrash(boolean crash) {
        this.crash = crash;
        if(crash){
            System.out.println("crash");
        }
    }

    /**
     * @return the throttlePunishment
     */
    public float getThrottleChange() {
        return throttleChange;
    }

    /**
     * @param throttlePunishment the throttlePunishment to set
     */
    public void setThrottleChange(float throttlePunishment) {
        this.throttleChange = throttlePunishment;
        prefs().putFloat("LookUpBasedTrottleController.throttleChange", throttleChange);
    }

    /**
     * @return the fractionOfTrackToPunish
     */
    public float getFractionOfTrackToPunish() {
        return fractionOfTrackToPunish;
    }

    /**
     * @param fractionOfTrackToPunish the fractionOfTrackToPunish to set
     */
    synchronized public void setFractionOfTrackToPunish(float fractionOfTrackToPunish) {
        this.fractionOfTrackToPunish = fractionOfTrackToPunish;
        prefs().putFloat("LookUpBasedTrottleController.fractionOfTrackToPunish",fractionOfTrackToPunish);
        trackPos=null;
    }

    /**
     * @return the punishmentFactorIncrease
     */
    public float getPunishmentFactorIncrease() {
        return punishmentFactorIncrease;
    }


    /**
     * @param punishmentFactorIncrease the punishmentFactorIncrease to set
     */
    public void setPunishmentFactorIncrease(float punishmentFactorIncrease) {
        this.punishmentFactorIncrease = punishmentFactorIncrease;
        prefs().putFloat("LookUpBasedTrottleController.punishmentFactorIncrease",punishmentFactorIncrease);
    }

    private class ThrottleSection {

        float definethrottle = getDefaultThrottle();
        int nbcrash = 0;
        int trackPoint;

        public ThrottleSection(int trackPoint) {
            this.trackPoint = trackPoint;
        }



        void punish(int i) {

            if(!learning) return;

            System.out.println(trackPoint+ ": punishing "+i+" with nbcrash="+nbcrash+", definethrottle="+definethrottle+" now");
            definethrottle = clipThrottle(definethrottle - (getPunishmentFactorIncrease()*getThrottleChange())*(2/(float)(nbsection)*(float)(Math.exp((float)(-((i-nbsection)^2))/(float)((nbsection^2/2))))));
            nbcrash++;
            System.out.println(trackPoint+ ": punishing "+i+" with nbcrash="+nbcrash+", definethrottle="+definethrottle+" now");
        }


        void maybeReward(int i) {
             if(!learning) return;
            if (nbcrash == 0) {
                definethrottle = clipThrottle(definethrottle + getThrottleChange());
                System.out.println(trackPoint+ ": rewarding "+i+" with nbcrash="+nbcrash);
            }
        }
    }
}
