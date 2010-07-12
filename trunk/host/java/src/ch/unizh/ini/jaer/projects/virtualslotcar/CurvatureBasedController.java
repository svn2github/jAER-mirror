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
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.tracking.ClusterInterface;
import net.sf.jaer.graphics.FrameAnnotater;
/**
 * Controls speed of car based on upcoming curvature of track, using measured speed of car and track model.
 * @author tobi
 *
 * This is part of jAER
<a href="http://jaer.wiki.sourceforge.net">jaer.wiki.sourceforge.net</a>,
licensed under the LGPL (<a href="http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License">http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License</a>.
 */
public class CurvatureBasedController extends AbstractSlotCarController implements SlotCarControllerInterface, FrameAnnotater {

    private float throttle=0; // last output throttle setting
    private float defaultThrottle=prefs().getFloat("CurvatureBasedController.defaultThrottle",.3f); // default throttle setting if no car is detected
    private float measuredSpeedPPS; // the last measured speed
    private Point2D.Float measuredLocation;
    private float throttleDelayMs=prefs().getFloat("CurvatureBasedController.throttleDelayMs", 30);
    private int numUpcomingCurvaturePoints=prefs().getInt("CurvatureBasedController.numUpcomingCurvaturePoints",3);
    private float desiredSpeedPPS=0;
    private SimpleSpeedController speedController;
 

    private float maxDistanceFromTrackPoint=prefs().getFloat("CurvatureBasedController.maxDistanceFromTrackPoint",15);
//    private float curvatureDeltaTimeMs=prefs().getFloat("CurvatureBasedController.curvatureDeltaTimeMs",1);
    private float lateralAccelerationLimitPPS2=prefs().getFloat("CurvatureBasedController.lateralAccelerationLimitPPS2", 4000);// 400pps change in 0.1s is about 4000pps2
    private float upcomingCurvature=0;
    private SlotcarTrack track;

    public CurvatureBasedController(AEChip chip) {
        super(chip);
        setPropertyTooltip("defaultThrottle", "default throttle setting if no car is detected");
        setPropertyTooltip("gain", "gain of proportional controller");
        setPropertyTooltip("throttleDelayMs", "delay time constant of throttle change on speed; same as look-ahead time for estimation of track curvature");
        setPropertyTooltip("lateralAccelerationLimitPPS2","Maximum allowed lateral acceleration in pixels per second squared; 400pps change in 0.1s is about 4000pps2");
//        setPropertyTooltip("", "");
        speedController=new SimpleSpeedController(chip);
        setEnclosedFilterChain(new FilterChain(chip));
        getEnclosedFilterChain().add(speedController);
        speedController.setEnclosed(true, this); // to get GUI to show up properly
    }

    /** Computes throttle using tracker output and upcoming curvature, using methods from SlotcarTrack.
     *
     * @param tracker
     * @param track
     * @return the throttle from 0-1.
     */
    @Override
    public float computeControl (CarTracker tracker,SlotcarTrack track){
        // find the csar, pass it to the track if there is one to get it's location, the use the UpcomingCurvature to compute the curvature coming up,
        // then compute the throttle to get our speed at the limit of traction.
        ClusterInterface car=tracker.getCarCluster();
        if(car==null){
            // lost car tracking or just starting out
            return getThrottle();  // return last throttle
        }else{
            if(track==null){
                log.warning("null track model - can't compute control");
                return getThrottle();
            }
            this.track=track; // set track for logging
            /*
             * during the normal running of the car, the steps would be as follows (which are computed in the controller, given the CarTracker and SlotcarTrack)

   1. Get the car position from the tracker.
   2. Ask the track model for the nearest spline point which is an int indexing into the list of track points.
   3. Update the car state SlotcarState of the track model - not clear how this should be done from the CarTracker data.
   4. Ask the track model for the list of upcoming curvatures.
   5. From the parameter throttleDelayMs, find the curvature at this time in the future.
   6. Compute the throttle needed to get us to a speed at this future time that puts us at the limit of traction.


This still requires us to have an estimated relation between throttle and resulting speed. We don't have any such model yet.
             */
             measuredSpeedPPS=(float)car.getSpeedPPS();
             measuredLocation=car.getLocation();
            int trackPos= track.findClosest(measuredLocation, getMaxDistanceFromTrackPoint());
            track.getCarState().pos=trackPos;
            track.getCarState().XYpos=measuredLocation; // update car state
            track.getCarState().speed=measuredSpeedPPS;
// TODO nothing below is correct!!!!
            // compute the curvature at throttleDelayMs in the future, given our measured speed
            UpcomingCurvature curvature=track.getCurvature(1, 1, measuredSpeedPPS/10);

            // compute desiredSpeedPPS given limit on lateral acceleration 'g', curvature 'c', and speed 'v'
            // v^2*c<g, so
            // v<sqrt(g/c)
            float c=Math.abs(curvature.getCurvature(0));
            float g=getLateralAccelerationLimitPPS2();
            float v=(float)Math.sqrt(g/c);
            desiredSpeedPPS=v;
            upcomingCurvature=c;
            speedController.setDesiredSpeedPPS(v);
            throttle=speedController.computeControl(tracker, track);
            return throttle;
        }
    }

    @Override
    public float getThrottle (){
        return throttle;
    }

 
    @Override
    public String logControllerState() {
        return String.format("%f\t%f\t%f\t%s",desiredSpeedPPS, measuredSpeedPPS, throttle, track==null? null:track.getCarState());
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
        prefs().putFloat("CurvatureBasedController.defaultThrottle",defaultThrottle);
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        String s=String.format("CurvatureBasedController\nDesired speed: %8.1f\nMeasured speed %8.1f\nCurvature: %8.1f\nThrottle: %8.1f",desiredSpeedPPS, measuredSpeedPPS, upcomingCurvature, throttle);
        MultilineAnnotationTextRenderer.renderMultilineString(s);
    }

    /**
     * @return the lateralAccelerationLimitPPS2
     */
    public float getLateralAccelerationLimitPPS2() {
        return lateralAccelerationLimitPPS2;
    }

    /**
     * @param lateralAccelerationLimitPPS2 the lateralAccelerationLimitPPS2 to set
     */
    public void setLateralAccelerationLimitPPS2(float lateralAccelerationLimitPPS2) {
        this.lateralAccelerationLimitPPS2 = lateralAccelerationLimitPPS2;
        prefs().putFloat("CurvatureBasedController.lateralAccelerationLimitPPS2",lateralAccelerationLimitPPS2);
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
        prefs().putFloat("CurvatureBasedController.maxDistanceFromTrackPoint",maxDistanceFromTrackPoint);
    }

    /**
     * @return the throttleDelayMs
     */
    public float getThrottleDelayMs() {
        return throttleDelayMs;
    }

    /**
     * @param throttleDelayMs the throttleDelayMs to set
     */
    public void setThrottleDelayMs(float throttleDelayMs) {
        this.throttleDelayMs = throttleDelayMs;
        prefs().putFloat("CurvatureBasedController.throttleDelayMs",throttleDelayMs);
    }
    

}
