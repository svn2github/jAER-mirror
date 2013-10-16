/*
 * SceneStabilizer.java (formerly MotionCompensator)
 *
 * Created on March 8, 2006, 9:41 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright 2006-2012 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package org.capocaccia.cne.jaer.cne2012.vor;

import ch.unizh.ini.jaer.hardware.pantilt.PanTilt;
import ch.unizh.ini.jaer.projects.poseestimation.DVS128Phidget;
import ch.unizh.ini.jaer.projects.poseestimation.TransformAtTime;
import ch.unizh.ini.jaer.projects.poseestimation.VORSensorForSteadicam;
import com.phidgets.Phidget;
import eu.seebetter.ini.chips.sbret10.IMUSample;
import eu.seebetter.ini.chips.sbret10.SBret10;
import java.awt.geom.Point2D;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Observable;
import java.util.Observer;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.label.DirectionSelectiveFilter;
import net.sf.jaer.eventprocessing.processortype.Application;
import net.sf.jaer.eventprocessing.tracking.OpticalGyro;
import net.sf.jaer.graphics.AEViewer;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.util.filter.HighpassFilter;

/**
 * This "vestibular-ocular Steadicam" tries to compensate global image motion by
 * using vestibular and global motion metrics to redirect output events and
 * (optionally) also a mechanical pantilt unit, shifting them according to
 * motion of input. Three methods can be used 1) the global translational flow
 * computed from DirectionSelectiveFilter, or 2) the optical gyro outputs from
 * OpticalGyro, or 3) (the best method) using a Phidgets gyro unit (the 9-DOF
 * unit).
 *
 * @author tobi
 */
@Description("Compenstates global scene translation and rotation to stabilize scene like a SteadiCam.")
public class Steadicam extends EventFilter2D implements FrameAnnotater, Application, Observer, PropertyChangeListener {

    /**
     * Classes that compute camera rotation estimate based on scene shift and
     * maybe rotation around the center of the scene.
     */
    public enum CameraRotationEstimator {

        OpticalGyro, DirectionSelectiveFilter, VORSensor
    };
    private CameraRotationEstimator cameraRotationEstimator = null; //PositionComputer.valueOf(get("positionComputer", "OpticalGyro"));
    private float gainTranslation = getFloat("gainTranslation", 1f);
    private float gainVelocity = getFloat("gainVelocity", 1);
    private float gainPanTiltServos = getFloat("gainPanTiltServos", 1);
    private DirectionSelectiveFilter dirFilter; // used when using optical flow
    private OpticalGyro opticalGyro; // used when tracking features
    private boolean feedforwardEnabled = getBoolean("feedforwardEnabled", false);
    private boolean panTiltEnabled = getBoolean("panTiltEnabled", false);
    private boolean electronicStabilizationEnabled = getBoolean("electronicStabilizationEnabled", true);
//    private boolean vestibularStabilizationEnabled = getBoolean("vestibularStabilizationEnabled", false);
    private Point2D.Float translation = new Point2D.Float();
    private HighpassFilter filterX = new HighpassFilter(), filterY = new HighpassFilter(), filterRotation = new HighpassFilter();
    private boolean flipContrast = false;
    private final int SHIFT_LIMIT = 30;
    boolean evenMotion = true;
    private FilterChain filterChain;
    private boolean annotateEnclosedEnabled = getBoolean("annotateEnclosedEnabled", true);
    private PanTilt panTilt = null;
    ArrayList<TransformAtTime> transformList = new ArrayList(); // holds list of transforms over update times commputed by enclosed filter update callbacks
    int sx2, sy2;
    TransformAtTime lastTransform = null;
//    private double[] angular, acceleration;
    private float panRate = 0, tiltRate = 0, rollRate = 0; // in deg/sec
    private float panOffset, tiltOffset, rollOffset;
//    private float upAccel = 0, rightAccel = 0, zAccel = 0; // in g in m/s^2
    private float panTranslationDeg = 0;
    private float tiltTranslationDeg = 0;
    private float rollDeg = 0;
    private float panDC = 0, tiltDC = 0, rollDC = 0;
    private float lensFocalLengthMm = getFloat("lensFocalLengthMm", 8.5f);
    HighpassFilter panTranslationFilter = new HighpassFilter();
    HighpassFilter tiltTranslationFilter = new HighpassFilter();
    HighpassFilter rollFilter = new HighpassFilter();
    private float highpassTauMsTranslation = getFloat("highpassTauMsTranslation", 1000);
    private float highpassTauMsRotation = getFloat("highpassTauMsRotation", 1000);
    float radPerPixel;
    private volatile boolean resetCalled = false;
    private int lastImuTimestamp = 0;
    private boolean initialized = false;
    private boolean addTimeStampsResetPropertyChangeListener = false;
    private int transformResetLimitDegrees = getInt("transformResetLimitDegrees", 180);

    /**
     * Creates a new instance of SceneStabilizer
     */
    public Steadicam(AEChip chip) {
        super(chip);
        filterChain = new FilterChain(chip);

        // if dirFilter is used to compute lastTransform, opticalGyro is still used to lastTransform the events
        dirFilter = new DirectionSelectiveFilter(chip);
        dirFilter.setAnnotationEnabled(false);
        dirFilter.addObserver(this);
        filterChain.add(dirFilter);

        opticalGyro = new OpticalGyro(chip);
        opticalGyro.setAnnotationEnabled(false); // annotation of cluster drawn in unshifted space and hard to see, clutters view.
        opticalGyro.addObserver(this);
        filterChain.add(opticalGyro);

        setEnclosedFilterChain(filterChain);

        addObserver(this); // we add ourselves as observer so that our update() can be called during packet iteration periodically according to global FilterFrame update interval settting

        try {
            cameraRotationEstimator = CameraRotationEstimator.valueOf(getString("positionComputer", "OpticalGyro"));
        } catch (IllegalArgumentException e) {
            log.warning("bad preference " + getString("positionComputer", "OpticalGyro") + " for preferred PositionComputer, choosing default OpticalGyro");
            cameraRotationEstimator = CameraRotationEstimator.OpticalGyro;
            putString("positionComputer", "OpticalGyro");
        }

        setCameraRotationEstimator(cameraRotationEstimator); // init filter enabled states
        initFilter(); // init filters for motion compensation
        setPropertyTooltip("cameraRotationEstimator", "specifies which method is used to measure camera rotation");
        setPropertyTooltip("gainTranslation", "gain applied to measured scene translation to affect electronic or mechanical output");
        setPropertyTooltip("gainVelocity", "gain applied to measured scene velocity times the weighted-average cluster aqe to affect electronic or mechanical output");
        setPropertyTooltip("gainPanTiltServos", "gain applied to translation for pan/tilt servo values");
        setPropertyTooltip("feedforwardEnabled", "enables motion computation on stabilized output of filter rather than input (only during use of DirectionSelectiveFilter)");
        setPropertyTooltip("panTiltEnabled", "enables use of pan/tilt servos for camera");
        setPropertyTooltip("electronicStabilizationEnabled", "stabilize by shifting events according to the PositionComputer");
        setPropertyTooltip("flipContrast", "flips contrast of output events depending on x*y sign of motion - should maintain colors of edges");
//        setPropertyTooltip("cornerFreqHz", "sets highpass corner frequency in Hz for stabilization - frequencies smaller than this will not be stabilized and transform will return to zero on this time scale");
        setPropertyTooltip("annotateEnclosedEnabled", "showing tracking or motion filter output annotation of output, for setting up parameters of enclosed filters");
        setPropertyTooltip("opticalGyroTauLowpassMs", "lowpass filter time constant in ms for optical gyro camera rotation measure");
        setPropertyTooltip("opticalGyroRotationEnabled", "enables rotation in transform");
        setPropertyTooltip("vestibularStabilizationEnabled", "use the gyro/accelometer to provide transform");
        setPropertyTooltip("zeroGyro", "zeros the gyro output. Sensor should be stationary for period of 1-2 seconds during zeroing");
        setPropertyTooltip("eraseGyroZero", "Erases the gyro zero values");

        setPropertyTooltip("sampleIntervalMs", "sensor sample interval in ms, min 4ms, powers of two, e.g. 4,8,16,32...");
        setPropertyTooltip("highpassTauMsTranslation", "highpass filter time constant in ms to relax transform back to zero for translation (pan, tilt) components");
        setPropertyTooltip("highpassTauMsRotation", "highpass filter time constant in ms to relax transform back to zero for rotation (roll) component");
        setPropertyTooltip("lensFocalLengthMm", "sets lens focal length in mm to adjust the scaling from camera rotation to pixel space");
        setPropertyTooltip("zeroGyro", "zeros the gyro output. Sensor should be stationary for period of 1-2 seconds during zeroing");
        setPropertyTooltip("eraseGyroZero", "Erases the gyro zero values");
        setPropertyTooltip("transformResetLimitDegrees", "If transform translations exceed this limit in degrees the transform is automatically reset to 0");
        rollFilter.setTauMs(highpassTauMsRotation);
        panTranslationFilter.setTauMs(highpassTauMsTranslation);
        tiltTranslationFilter.setTauMs(highpassTauMsTranslation);
    }

    @Override
    public EventPacket filterPacket(EventPacket in) { // TODO completely rework this code because IMUSamples are part of the packet now!
        if (!addTimeStampsResetPropertyChangeListener) {
            chip.getAeViewer().addPropertyChangeListener(AEViewer.EVENT_TIMESTAMPS_RESET, this);
            addTimeStampsResetPropertyChangeListener = true;
        }
        sx2 = chip.getSizeX() / 2;
        sy2 = chip.getSizeY() / 2;
        int sizex = chip.getSizeX() - 1;
        int sizey = chip.getSizeY() - 1;
        checkOutputPacketEventType(in);
        transformList.clear(); // empty list of transforms to be applied
        // The call to enclosed filters issues callbacks to us periodically via updates that fills transform list, in case of enclosed filters. 
        // this is not the case when using integrated IMU which generates IMUSamples in the event stream.
        getEnclosedFilterChain().filterPacket(in);
//        System.out.println("new steadicam input packet "+in);
        if (isElectronicStabilizationEnabled()) { // here we stabilize by using the measured camera rotation to counter-transform the events
            checkOutputPacketEventType(in);
            OutputEventIterator outItr = getOutputPacket().outputIterator();// the transformed events output packet
            // TODO compute evenMotion boolean from opticalGyro
            Iterator<TransformAtTime> transformItr = transformList.iterator(); // this list is filled by the enclosed filters
//            int i=-1;
            for (Object o : in) {
                if (o == null) {
                    log.warning("null event passed in, returning input packet");
                    return in;
                }
//                i++;
                PolarityEvent ev = (PolarityEvent) o;
                switch (cameraRotationEstimator) {
                    case VORSensor:
                        if (ev instanceof IMUSample) {
                            // TODO hack, we mark IMUSamples in EventExtractor that are actually ApsDvsEvent as non-special so we can detect them here
//                            System.out.println("at position "+i+" got "+ev); 
                            IMUSample s = (IMUSample) ev;
                            if (s.imuSampleEvent) {
                                lastTransform = updateTransform(s);
                                continue; // next event
                            }
                        }
                        break;
                    default:
                        lastTransform = transformItr.next();
                }

                if (lastTransform != null) {
                    transformEvent(ev, lastTransform);
                }

                if (ev.x > sizex || ev.x < 0 || ev.y > sizey || ev.y < 0) {
                    continue; // discard events outside chip limits for now, because we can't render them presently, although they are valid events
                }
                // deal with flipping contrast of output event depending on direction of motion, to make things appear the same regardless of camera rotation
                if (!flipContrast) {
                    outItr.nextOutput().copyFrom(ev);
                } else {
                    if (evenMotion) {
                        ev.type = (byte) (1 - ev.type); // don't let contrast flip when direction changes, try to stabilze contrast  by flipping it as well
                        ev.polarity = ev.polarity == PolarityEvent.Polarity.On ? PolarityEvent.Polarity.Off : PolarityEvent.Polarity.On;
                    }
                    outItr.nextOutput().copyFrom(ev);
                }
            }
        }

        if (isPanTiltEnabled()) { // mechanical pantilt
            try {
                // mechanical pantilt
                // assume that pan of 1 takes us 180 degrees and that the sensor has 45 deg FOV,
                // then 1 pixel will require only 45/180/size pan
                final float factor = (float) (chip.getPixelWidthUm() / 1000 / lensFocalLengthMm / Math.PI);
                panTilt.setPanTiltValues(.5f - translation.x * getGainPanTiltServos() * factor, .5f + translation.y * getGainPanTiltServos() * factor);
            } catch (HardwareInterfaceException ex) {
                log.warning("setting pantilt: " + ex);
                panTilt.close();
            }
        }

        if (isElectronicStabilizationEnabled()) {
            return getOutputPacket();
        } else {
            return in;
        }
    }

    /**
     * Called back here during packet iteration to update transform
     *
     * @param o
     * @param arg
     */
    @Override
    public void update(Observable o, Object arg) { // called by enclosed filter to update event stream on the fly, using intermediate data
        if (arg instanceof UpdateMessage) {
            computeTransform((UpdateMessage) arg); // gets the lastTransform from the enclosed filter
        }
    }

    /**
     * Computes transform using current gyro outputs based on timestamp supplied
     * and returns a TransformAtTime object. Should be called by update in
     * enclosing processor.
     *
     * @param timestamp the timestamp in us.
     * @return the transform object representing the camera rotation
     */
    synchronized public TransformAtTime updateTransform(IMUSample imuSample) {

        if (resetCalled) {
            log.info("reset called, panDC" + panDC + " panTranslationFilter=" + panTranslationFilter);
            resetCalled = false;
        }
        if (imuSample == null) {
            return null;
        }
//        System.out.println(imuSample.toString());
        int timestamp = imuSample.getTimestampUs();
        float dtS = (timestamp - lastImuTimestamp) * 1e-6f;
        lastImuTimestamp = timestamp;
        if (!initialized) {
            initialized = true;
            return null;
        }
        panRate = imuSample.getGyroYawY();
        tiltRate = imuSample.getGyroTiltX();
        rollRate = imuSample.getGyroRollZ();
//        zAccel = imuSample.getAccelZ();
//        upAccel = imuSample.getAccelY();
//        rightAccel = imuSample.getAccelX();

        panDC += getPanRate() * dtS;
        tiltDC += getTiltRate() * dtS;
        rollDC += getRollRate() * dtS;

        panTranslationDeg = panTranslationFilter.filter(panDC, timestamp);
        tiltTranslationDeg = tiltTranslationFilter.filter(tiltDC, timestamp);
        rollDeg = rollFilter.filter(rollDC, timestamp);

        // check limits
        if (Math.abs(panTranslationDeg) > transformResetLimitDegrees || Math.abs(tiltTranslationDeg) > transformResetLimitDegrees || Math.abs(rollDeg) > transformResetLimitDegrees) {
            panDC = 0;
            tiltDC = 0;
            rollDC = 0;

            panTranslationDeg = 0;
            tiltTranslationDeg = 0;
            rollDeg = 0;
            panTranslationFilter.reset();
            tiltTranslationFilter.reset();
            rollFilter.reset();
        }

        // computute transform in TransformAtTime units here.
        // Use the lens focal length and camera resolution.

        TransformAtTime tr = new TransformAtTime(timestamp,
                new Point2D.Float(
                (float) (Math.PI / 180 * panTranslationDeg) / radPerPixel,
                (float) (Math.PI / 180 * tiltTranslationDeg) / radPerPixel),
                -rollDeg * (float) Math.PI / 180);
        return tr;
    }

    public void transformEvent(BasicEvent e, TransformAtTime transform) {
        if (transform == null) {
            return;
        }
        e.x -= sx2;
        e.y -= sy2;
        short newx = (short) Math.round((transform.cosAngle * e.x - transform.sinAngle * e.y + transform.translation.x));
        short newy = (short) Math.round((transform.sinAngle * e.x + transform.cosAngle * e.y + transform.translation.y));
        e.x = (short) (newx + sx2);
        e.y = (short) (newy + sy2);
        e.address = chip.getEventExtractor().getAddressFromCell(e.x, e.y, e.getType()); // so event is logged properly to disk
    }

    public void doEraseGyroZero() {
        panOffset = 0;
        tiltOffset = 0;
        rollOffset = 0;
    }

    public void doZeroGyro() {
        panOffset = panRate; // TODO offsets should really be some average over some samples
        tiltOffset = tiltRate;
        rollOffset = rollRate;
    }

    /**
     * Called by update on enclosed filter updates. <p> Using
     * DirectionSelectiveFilter, the lastTransform is computed by pure
     * integration of the motion signal followed by a high-pass filter to remove
     * long term DC offsets. <p> Using OpticalGyro, the lastTransform is
     * computed by the optical gyro which tracks clusters and measures scene
     * translation (and possibly rotation) from a consensus of the tracked
     * clusters. <p> Using PhidgetsVORSensor, lastTransform is computed by
     * PhidgetsVORSensor using rate gyro sensors.
     *
     *
     * @param in the input event packet.
     */
    private void computeTransform(UpdateMessage msg) {
        float shiftx = 0, shifty = 0;
        float rot = 0;
        Point2D.Float trans = new Point2D.Float();
        switch (cameraRotationEstimator) {
            case DirectionSelectiveFilter:
                Point2D.Float f = dirFilter.getTranslationVector(); // this is 'instantaneous' motion vector in PPS units (as filtered by DirectionSelectiveFilter)
                int t = msg.timestamp;
                int dtUs = (t - msg.packet.getFirstTimestamp()); // duration of this slice
                if (Math.abs(f.x) > Math.abs(f.y)) {
                    evenMotion = f.x > 0; // used to flip contrast 
                } else {
                    evenMotion = f.y > 0;
                }
                shiftx += -(float) (gainTranslation * f.x * dtUs * 1e-6f); // this is integrated shift
                shifty += -(float) (gainTranslation * f.y * dtUs * 1e-6f);
                trans.x = (filterX.filter(shiftx, t)); // these are highpass filtered shifts
                trans.y = (filterY.filter(shifty, t));
                transformList.add(new TransformAtTime(msg.timestamp, trans, rot)); // this list is applied during output lastTransform of the event stream
                break;
            case OpticalGyro:
//                Point2D.Float trans=opticalGyro.getOpticalGyroTranslation();
//                Point2D.Float velPPS=opticalGyro.getOpticalGyro().getVelocityPPT();
//                int deltaTime=opticalGyro.getOpticalGyro().getAverageClusterAge();
//                translation.x=filterX.filter(-trans.x,in.getLastTimestamp())+gainVelocity*velPPS.x*deltaTime/1e6f/AEConstants.TICK_DEFAULT_US;
//                translation.y = filterY.filter(-trans.y,in.getLastTimestamp()) + gainVelocity * velPPS.y * deltaTime / 1e6f / AEConstants.TICK_DEFAULT_US; // shift is negative of gyro value.
                trans.setLocation(opticalGyro.getOpticalGyroTranslation());
                rot = opticalGyro.getOpticalGyroRotation();
                Point2D.Float v = opticalGyro.getVelocityPPt();
                if (Math.abs(v.x) > Math.abs(v.y)) {
                    evenMotion = v.x > 0; // used to flip contrast 
                } else {
                    evenMotion = v.y > 0;
                }
                transformList.add(new TransformAtTime(msg.timestamp, trans, rot)); // this list is applied during output lastTransform of the event stream
                break;
        }
    }

    /**
     * @return the panRate
     */
    public float getPanRate() {
        return panRate - panOffset;
    }

    /**
     * @return the tiltRate
     */
    public float getTiltRate() {
        return tiltRate - tiltOffset;
    }

    /**
     * @return the rollRate
     */
    public float getRollRate() {
        return rollRate - rollOffset;
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        GL gl = drawable.getGL();
        if (gl == null) {
            return;
        }

        if (lastTransform != null && isElectronicStabilizationEnabled()) { // draw translation frame
            // draw transform
            gl.glPushMatrix();

            // draw xhairs on frame to help show locations of objects and if they have moved.
            gl.glLineWidth(2f);
            gl.glColor3f(1, 0, 0);
            gl.glBegin(GL.GL_LINES);
            gl.glVertex2f(sx2, 0);
            gl.glVertex2f(sx2, sy2 << 1);
            gl.glVertex2f(0, sy2);
            gl.glVertex2f(sx2 << 1, sy2);
            gl.glEnd();

            // rectangle around transform
            gl.glTranslatef(lastTransform.translation.x + sx2, lastTransform.translation.y + sy2, 0);
            gl.glRotatef((float) (lastTransform.rotation * 180 / Math.PI), 0, 0, 1);
            gl.glBegin(GL.GL_LINE_LOOP);
            gl.glVertex2f(-sx2, -sy2);
            gl.glVertex2f(sx2, -sy2);
            gl.glVertex2f(sx2, sy2);
            gl.glVertex2f(-sx2, sy2);
            gl.glEnd();
            gl.glPopMatrix();

        }
    }

//    public float getGainTranslation() {
//        return gainTranslation;
//    }
//
//    public void setGainTranslation(float gain) {
//        if (gain < 0) {
//            gain = 0;
//        } else if (gain > 100) {
//            gain = 100;
//        }
//        this.gainTranslation = gain;
//        putFloat("gainTranslation", gain);
//    }
//    /**
//     * @return the gainVelocity
//     */
//    public float getGainVelocity() {
//        return gainVelocity;
//    }
//
//    /**
//     * @param gainVelocity the gainVelocity to set
//     */
//    public void setGainVelocity(float gainVelocity) {
//        this.gainVelocity = gainVelocity;
//        putFloat("gainVelocity", gainVelocity);
//    }
//    public void setCornerFreqHz(float freq) {
//        cornerFreqHz = freq;
//        filterX.set3dBFreqHz(freq);
//        filterY.set3dBFreqHz(freq);
//        filterRotation.set3dBFreqHz(freq);
//        putFloat("cornerFreqHz", freq);
//    }
//
//    public float getCornerFreqHz() {
//        return cornerFreqHz;
//    }
    @Override
    synchronized public void resetFilter() {
        resetCalled = true;
        panRate = 0;
        tiltRate = 0;
        rollRate = 0;
        panDC = 0;
        tiltDC = 0;
        rollDC = 0;
        rollDeg = 0;
        panTranslationFilter.reset();
        tiltTranslationFilter.reset();
        rollFilter.reset();
        radPerPixel = (float) Math.atan(getChip().getPixelWidthUm() * 1e-3f / lensFocalLengthMm);
        dirFilter.resetFilter();
        opticalGyro.resetFilter();
        filterX.setInternalValue(0);
        filterY.setInternalValue(0);
        filterRotation.setInternalValue(0);
        translation.x = 0;
        translation.y = 0;
        lastTransform = null;
        if (isPanTiltEnabled()) {
            try {
                panTilt.setPanTiltValues(.5f, .5f);
            } catch (HardwareInterfaceException ex) {
                log.warning(ex.toString());
                panTilt.close();
            }
        }
        initialized = false;
    }

    @Override
    public void initFilter() {
        panTilt = new PanTilt();
        resetFilter();
    }

    public boolean isFlipContrast() {
        return flipContrast;
    }

    public void setFlipContrast(boolean flipContrast) {
        this.flipContrast = flipContrast;
    }

    @Override
    synchronized public void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        setCameraRotationEstimator(cameraRotationEstimator); // reflag enabled/disabled state of motion computation
        getEnclosedFilterChain().reset();
        if (!yes) {
            setPanTiltEnabled(false); // turn off servos, close interface
        }
    }

    public boolean isFeedforwardEnabled() {
        return feedforwardEnabled;
    }

    /**
     * true to apply current shift values to input packet events. This does a
     * kind of feedback compensation
     */
    public void setFeedforwardEnabled(boolean feedforwardEnabled) {
        this.feedforwardEnabled = feedforwardEnabled;
        putBoolean("feedforwardEnabled", feedforwardEnabled);
    }

//    public boolean isRotationEnabled(){
//        return rotationEnabled;
//    }
//
//    public void setRotationEnabled(boolean rotationEnabled){
//        this.rotationEnabled=rotationEnabled;
//        putBoolean("rotationEnabled",rotationEnabled);
//    }
    /**
     * Method used to compute shift.
     *
     * @return the positionComputer
     */
    public CameraRotationEstimator getCameraRotationEstimator() {
        return cameraRotationEstimator;
    }

    /**
     * Chooses how the current position of the scene is computed.
     *
     * @param positionComputer the positionComputer to set
     */
    synchronized public void setCameraRotationEstimator(CameraRotationEstimator positionComputer) {
        this.cameraRotationEstimator = positionComputer;
        putString("positionComputer", positionComputer.toString());
        switch (positionComputer) {
            case DirectionSelectiveFilter:
                dirFilter.setFilterEnabled(true);
                opticalGyro.setFilterEnabled(false);
                break;
            case OpticalGyro:
                opticalGyro.setFilterEnabled(true);
                dirFilter.setFilterEnabled(false);
                break;
            case VORSensor:
                opticalGyro.setFilterEnabled(false);
                dirFilter.setFilterEnabled(false);
        }
    }

    /**
     * The global translational shift applied to output, computed by enclosed
     * FilterChain.
     *
     * @return the x,y shift
     */
    public Point2D.Float getShift() {
        return translation;
    }

    /**
     * @param shift the shift to set
     */
    public void setShift(Point2D.Float shift) {
        this.translation = shift;
    }

    /**
     * @return the annotateEnclosedEnabled
     */
    public boolean isAnnotateEnclosedEnabled() {
        return annotateEnclosedEnabled;
    }

    /**
     * @param annotateEnclosedEnabled the annotateEnclosedEnabled to set
     */
    public void setAnnotateEnclosedEnabled(boolean annotateEnclosedEnabled) {
        this.annotateEnclosedEnabled = annotateEnclosedEnabled;
        putBoolean("annotateEnclosedEnabled", annotateEnclosedEnabled);
    }

    /**
     * @return the panTiltEnabled
     */
    public boolean isPanTiltEnabled() {
        return panTiltEnabled;
    }

    /**
     * Enables use of pan/tilt servo controller for camera for mechanical
     * stabilization.
     *
     * @param panTiltEnabled the panTiltEnabled to set
     */
    public void setPanTiltEnabled(boolean panTiltEnabled) {
        this.panTiltEnabled = panTiltEnabled;
        putBoolean("panTiltEnabled", panTiltEnabled);
        if (!panTiltEnabled) {
            try {
                if (panTilt != null && panTilt.getServoInterface() != null && panTilt.getServoInterface().isOpen()) {
                    panTilt.getServoInterface().disableAllServos();
                    panTilt.close();
                }
            } catch (HardwareInterfaceException ex) {
                log.warning(ex.toString());
                panTilt.close();
            }
        }
    }

    /**
     * @return the electronicStabilizationEnabled
     */
    public boolean isElectronicStabilizationEnabled() {
        return electronicStabilizationEnabled;
    }

    /**
     * @param electronicStabilizationEnabled the electronicStabilizationEnabled
     * to set
     */
    public void setElectronicStabilizationEnabled(boolean electronicStabilizationEnabled) {
        this.electronicStabilizationEnabled = electronicStabilizationEnabled;
        putBoolean("electronicStabilizationEnabled", electronicStabilizationEnabled);
    }

    /**
     * @return the gainPanTiltServos
     */
    public float getGainPanTiltServos() {
        return gainPanTiltServos;
    }

    /**
     * @param gainPanTiltServos the gainPanTiltServos to set
     */
    public void setGainPanTiltServos(float gainPanTiltServos) {
        this.gainPanTiltServos = gainPanTiltServos;
        putFloat("gainPanTiltServos", gainPanTiltServos);
    }

    public void setOpticalGyroRotationEnabled(boolean opticalGyroRotationEnabled) {
        opticalGyro.setOpticalGyroRotationEnabled(opticalGyroRotationEnabled);
    }

    public boolean isOpticalGyroRotationEnabled() {
        return opticalGyro.isOpticalGyroRotationEnabled();
    }

    public void setOpticalGyroTauLowpassMs(float opticalGyroTauLowpassMs) {
        opticalGyro.setOpticalGyroTauLowpassMs(opticalGyroTauLowpassMs);
    }

    public float getOpticalGyroTauLowpassMs() {
        return opticalGyro.getOpticalGyroTauLowpassMs();
    }

    /**
     * @return the highpassTauMs
     */
    public float getHighpassTauMsTranslation() {
        return highpassTauMsTranslation;
    }

    /**
     * @param highpassTauMs the highpassTauMs to set
     */
    public void setHighpassTauMsTranslation(float highpassTauMs) {
        this.highpassTauMsTranslation = highpassTauMs;
        putFloat("highpassTauMsTranslation", highpassTauMs);
        panTranslationFilter.setTauMs(highpassTauMs);
        tiltTranslationFilter.setTauMs(highpassTauMs);
    }

    /**
     * @return the highpassTauMs
     */
    public float getHighpassTauMsRotation() {
        return highpassTauMsRotation;
    }

    /**
     * @param highpassTauMs the highpassTauMs to set
     */
    public void setHighpassTauMsRotation(float highpassTauMs) {
        this.highpassTauMsRotation = highpassTauMs;
        putFloat("highpassTauMsRotation", highpassTauMs);
        rollFilter.setTauMs(highpassTauMs);
    }

    private float clip(float f, float lim) {
        if (f > lim) {
            f = lim;
        } else if (f < -lim) {
            f = -lim;
        }
        return f;
    }

    /**
     * @return the lensFocalLengthMm
     */
    public float getLensFocalLengthMm() {
        return lensFocalLengthMm;
    }

    /**
     * @param lensFocalLengthMm the lensFocalLengthMm to set
     */
    public void setLensFocalLengthMm(float lensFocalLengthMm) {
        this.lensFocalLengthMm = lensFocalLengthMm;
        putFloat("lensFocalLengthMm", lensFocalLengthMm);
        radPerPixel = (float) Math.asin(getChip().getPixelWidthUm() * 1e-3f / lensFocalLengthMm);
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if (evt.getPropertyName() == AEViewer.EVENT_TIMESTAMPS_RESET) {
            resetFilter();
        }
    }

    /**
     * @return the transformResetLimitDegrees
     */
    public int getTransformResetLimitDegrees() {
        return transformResetLimitDegrees;
    }

    /**
     * @param transformResetLimitDegrees the transformResetLimitDegrees to set
     */
    public void setTransformResetLimitDegrees(int transformResetLimitDegrees) {
        this.transformResetLimitDegrees = transformResetLimitDegrees;
        putInt("transformResetLimitDegrees", transformResetLimitDegrees);
    }
}
