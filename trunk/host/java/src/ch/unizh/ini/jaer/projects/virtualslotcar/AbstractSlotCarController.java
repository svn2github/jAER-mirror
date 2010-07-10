/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package ch.unizh.ini.jaer.projects.virtualslotcar;

import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;

/**
 * Base class for slot car controllers where all methods are Unsupported.
 *
 * @author tobi
 */
abstract public class AbstractSlotCarController extends EventFilter2D implements FrameAnnotater{

    public AbstractSlotCarController(AEChip chip) {
        super(chip);
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

    public void annotate(GLAutoDrawable drawable) {
    }

      /** Computes the control signal given the car tracker and the track model.
     *
     * @param tracker
     * @param track
     * @return the throttle setting ranging from 0 to 1.
     */
    abstract public float computeControl(CarTracker tracker, SlotcarTrack track);

   /** Returns the last computed throttle setting.
     *
     * @return the throttle setting.
     */
    abstract public  float getThrottle();

     /** Implement this method to return a string logging the state of the controller, e.g. throttle, measured speed, and curvature.
     *
     * @return string to log, by default the empty string.
     */
    public String logControllerState() {
        return "";
    }

     /** Returns a string that says what are the contents of the log, e.g. throttle, desired speed, measured speed.
     *
     * @return the string description of the log contents - by default empty
     */
    public String getLogContentsHeader(){
        return "";
    }

}
