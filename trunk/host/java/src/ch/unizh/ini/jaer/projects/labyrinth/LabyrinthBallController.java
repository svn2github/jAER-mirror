/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.labyrinth;

import java.awt.Point;
import java.awt.event.MouseEvent;
import java.awt.geom.*;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.util.LinkedList;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.glu.GLU;
import net.sf.jaer.aemonitor.AEConstants;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2DMouseAdaptor;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.tracking.RectangularClusterTracker.Cluster;
import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.util.HexString;

/**
 * This filter enables controlling the tracked labyrinth ball.
 * 
 * @author Tobi Delbruck
 */
public class LabyrinthBallController extends EventFilter2DMouseAdaptor implements PropertyChangeListener, Observer {

    public static float MAX_INTEGRAL_CONTROL_RAD = 5 * (float) Math.PI / 180;
    private long JIGGLE_TIME_MS = 2000;

    public static final String getDescription() {
        return "Low level ball controller for Labyrinth game";
    }
    private float xTiltRad = 0;
    private float yTiltRad = 0; // TODO limit in deg 
    volatile private Point2D.Float tiltsRad = new Point2D.Float(xTiltRad, yTiltRad);
    // control
    private float proportionalGain = getFloat("proportionalGain", 1);
    private float derivativeGain = getFloat("derivativeGain", 1);
    private float integralGain = getFloat("integralGain", 1);
    // error signals
    // errors
    Point2D.Float pErr =  new Point2D.Float(0, 0);
    Point2D.Float iErr = new Point2D.Float(0, 0);
    Point2D.Float dErr=new Point2D.Float(0,0);
    int lastErrorUpdateTime = 0;
    boolean controllerInitialized = false;
    
    // The ball acceleration will be g (grav constant) * sin(angle) which is approx g*angle with angle in radians =g*angleRadPerServoUnit*(servo-0.5f).
    final float metersPerPixel = 0.22f / 128;  // TODO estimated pixels of 128 retina per meter, assumes table fills retina vertically
    final float gravConstantMperS2 = 9.8f; // meters per second^2
    final float gravConstantPixPerSec2 = gravConstantMperS2 / metersPerPixel; // g in pixel units
    // fields
    LabyrinthHardware labyrinthHardware;
    LabyrinthBallTracker tracker = null;
    // filter chain
    FilterChain filterChain;

    // state stuff
    Point2D.Float desiredPosition = null, target = null; // manually selected ball position and actual target location (maybe from path following)
    // history
    Trajectory trajectory = new Trajectory();
    private LabyrinthTableTiltControllerGUI gui;
    boolean navigateMaze = getBoolean("navigateMaze", true);
    private boolean controllerEnabled = getBoolean("controllerEnabled", true);

    /** Constructs instance of the new 'filter' CalibratedPanTilt. The only time events are actually used
     * is during calibration. The PanTilt hardware interface is also constructed.
     * @param chip
     */
    public LabyrinthBallController(AEChip chip) {
        super(chip);

        tracker = new LabyrinthBallTracker(chip);
        tracker.addObserver(this);
        labyrinthHardware = new LabyrinthHardware(chip);
        labyrinthHardware.getSupport().addPropertyChangeListener(this);

        filterChain = new FilterChain(chip);

        filterChain.add(labyrinthHardware);
        filterChain.add(tracker);

        setEnclosedFilterChain(filterChain);

//        String control = "Control";
        setPropertyTooltip("disableServos", "disables servos, e.g. to turn off annoying servo hum");
        setPropertyTooltip("center", "centers pan and tilt controls");
        setPropertyTooltip("integralGain", "integral error gain: tilt(rad)=error(pixels)*integralGain(1/(pixels*sec))");
        setPropertyTooltip("proportionalGain", "proportional error gain: tilt(rad)=error(pixels)*proportionalGain(1/pixels)");
        setPropertyTooltip("derivativeGain", "-derivative gain: damps overshoot. tilt(rad)=-vel(pix/sec)*derivativeGain(sec/pixel)");
        setPropertyTooltip("navigateMaze", "follow the path in the maze");
        setPropertyTooltip("tiltLimitRad", "limit of tilt of table in radians; 1 rad=57 deg");
        setPropertyTooltip("jiggleTable", "jiggle the table for " + JIGGLE_TIME_MS + " ms according to the jitter settings for the LabyrinthHardware");
        computePoles();
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        out = getEnclosedFilterChain().filterPacket(in);
        if (controllerEnabled) {
            control(in, in.getLastTimestamp());
        }

        return out;
    }

    private void control(EventPacket in, int timestamp) {
        if (tracker.getBall() != null) {
            Cluster ball = tracker.getBall();
            Point2D.Float pos = ball.getLocation();
//            trajectory.add(ball.getLastEventTimestamp(), pos.x, pos.y);
            Point2D.Float vel = ball.getVelocityPPS();
            if (desiredPosition != null) {
                target = desiredPosition;
            } else {
                target = tracker.findNextPathPoint();
            }

            if (target != null) {
                pErr.setLocation(target.x - pos.x, target.y - pos.y);
                dErr.setLocation(-vel.x,-vel.y);
                if (!controllerInitialized) {
                    lastErrorUpdateTime = timestamp; // initialize to avoid giant dt, will be zero on first pass
                    controllerInitialized = true;
                }
                int dtUs = timestamp - lastErrorUpdateTime;
                float dtSec=dtUs  * 1e-6f * AEConstants.TICK_DEFAULT_US;
                iErr.x += dtSec * pErr.x ;
                iErr.y += dtSec * pErr.y ;
                lastErrorUpdateTime = timestamp;
                // anti windup control
                iErr.x = windupLimit(iErr.x);
                iErr.y = windupLimit(iErr.y);
//                System.out.println("ierr= "+iErr);

                float xtilt = pErr.x * proportionalGain + dErr.x * derivativeGain *tau + iErr.x * integralGain/tau;
                float ytilt = pErr.y * proportionalGain + dErr.y * derivativeGain *tau + iErr.y * integralGain/tau;
                try {
                    setTilts(xtilt, ytilt);
                } catch (HardwareInterfaceException ex) {
                    // TODO ignore for now - need to handle hardware errors in any case in servo class better
                }
            }
        } else {
            resetControllerState();
        }
    }

    float windupLimit(float intErr) {
        if (Math.abs(intErr * integralGain) > MAX_INTEGRAL_CONTROL_RAD) {
            intErr = Math.signum(intErr) * MAX_INTEGRAL_CONTROL_RAD / integralGain;
        }
        return intErr;
    }

    @Override
    public void resetFilter() {
        resetControllerState();
        filterChain.reset();
    }

    @Override
    public void initFilter() {
        resetFilter();
    }

    /** Sets the pan and tilt servo values, clipped to limits, and sets internal values.
    @param xtiltRad in radians, positive to tilt to right towards positive x
    @param ytiltRad in radians, positive to tilt up towards positive y
     */
    public void setTilts(float xtiltRad, float ytiltRad) throws HardwareInterfaceException {
        this.xTiltRad = clipPanTilts(xtiltRad);
        this.yTiltRad = clipPanTilts(ytiltRad);
        tiltsRad.setLocation(this.xTiltRad, this.yTiltRad);
        getPanTiltHardware().setPanTiltValues(this.xTiltRad, this.yTiltRad);
    }

    private float clipPanTilts(float tilt) {
        if (tilt > getTiltLimitRad()) {
            return getTiltLimitRad();
        } else if (tilt < -getTiltLimitRad()) {
            return -getTiltLimitRad();
        }
        return tilt;
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {

        super.annotate(drawable);
        GL gl = drawable.getGL();
        if (target != null) {
            // draw desired position disk
            gl.glColor4f(0, .25f, 0, .3f);
            gl.glPushMatrix();
            gl.glTranslatef(target.x, target.y, 0);
            if (quad == null) {
                quad = glu.gluNewQuadric();
            }
            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
            glu.gluDisk(quad, 0, 3, 32, 1);
            gl.glPopMatrix();
            // draw error vector if ball is tracked also
            if (tracker.getBall() != null) {
                gl.glLineWidth(2f);
                gl.glColor4f(.25f, .25f, 0, .3f);
                gl.glBegin(GL.GL_LINES);
                gl.glVertex2f(tracker.getBall().getLocation().x, tracker.getBall().getLocation().y);
                gl.glVertex2f(target.x, target.y);
                gl.glEnd();
            }
        }
        // draw table tilt values
        final float size = .1f;
        float sx = chip.getSizeX(), sy = chip.getSizeY();
        chip.getCanvas().checkGLError(gl, glu, "before controller annotations");
        {
            gl.glPushMatrix();

            gl.glTranslatef(-sx * size * 1.1f, 0, 0); // move outside chip array to lower left
            gl.glScalef(sx * size, sx * size, sx * size); // scale everything so that when we draw 1 unit we cover this size*sx pixels

            chip.getCanvas().checkGLError(gl, glu, "in control box  controller annotations");
            gl.glLineWidth(3f);
            gl.glColor3f(1, 1, 1);

            {
                gl.glBegin(GL.GL_LINE_LOOP);
                gl.glVertex2f(0, 0);
                gl.glVertex2f(1, 0);
                gl.glVertex2f(1, 1);
                gl.glVertex2f(0, 1);
                gl.glEnd();
            }
            gl.glPointSize(4f);
            {
                gl.glBegin(GL.GL_POINTS);
                gl.glVertex2f(.5f, .5f);
                gl.glEnd();
            }
            chip.getCanvas().checkGLError(gl, glu, "drawing tilt box");
            // draw tilt vector
            float lim=getTiltLimitRad()/2;
            float xlen = xTiltRad / lim;
            float ylen = yTiltRad / lim;
            gl.glLineWidth(4f);
            if (Math.abs(xlen) < .5f && Math.abs(ylen) < .5f) {
                gl.glColor4f(0, 1, 0, 1);
            } else {
                gl.glColor4f(1, 0, 0, 1);
            }
            gl.glPointSize(4f);
            {
                gl.glTranslatef(.5f, .5f, 0);
                gl.glBegin(GL.GL_POINTS);
                gl.glVertex2f(0, 0);
                gl.glEnd();
            }
            gl.glLineWidth(4);
            {
                gl.glBegin(GL.GL_LINES);
                gl.glVertex2f(0, 0);
                gl.glVertex2f(xlen, ylen);
                gl.glEnd();
            }
            chip.getCanvas().checkGLError(gl, glu, "drawing tilt box");
            gl.glPopMatrix();
        }

        // print some stuff
        MultilineAnnotationTextRenderer.renderMultilineString("Left-Click to hint ball location\nMiddle-Click/drag to set desired ball position\nCtl-click outside chip frame to clear desired ball posiition");
        String s = String.format("Controller dynamics:\ntau=%.1fms\nQ=%.2f", tau * 1000, Q);
        MultilineAnnotationTextRenderer.renderMultilineString(s);
        chip.getCanvas().checkGLError(gl, glu, "after controller annotations");
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        getSupport().firePropertyChange(evt);
    }

    /**
     * @return the proportionalGain
     */
    public float getProportionalGain() {
        return proportionalGain;
    }

    /**
     * @param proportionalGain the proportionalGain to set
     */
    public void setProportionalGain(float proportionalGain) {
        this.proportionalGain = proportionalGain;
        putFloat("proportionalGain", proportionalGain);
        computePoles();
    }

    /**
     * @return the derivativeGain
     */
    public float getDerivativeGain() {
        return derivativeGain;
    }

    /**
     * @param derivativeGain the derivativeGain to set
     */
    public void setDerivativeGain(float derivativeGain) {
        this.derivativeGain = derivativeGain;
        putFloat("derivativeGain", derivativeGain);
        computePoles();
    }

    /**
     * @return the integralGain
     */
    public float getIntegralGain() {
        return integralGain;
    }

    /**
     * @param integralGain the integralGain to set
     */
    public void setIntegralGain(float integralGain) {
        this.integralGain = integralGain;
        putFloat("integralGain", integralGain);
        computePoles();
    }

    /** Handles control for updates from the tracker.
     * 
     * @param o the calling filter
     * @param arg the UpdateMessage (or other message).
     */
    @Override
    public void update(Observable o, Object arg) {
        if (arg instanceof UpdateMessage) {
            UpdateMessage m = (UpdateMessage) arg;
            if (controllerEnabled) {
                control(m.packet, m.timestamp);
            }
        }
    }

    /**
     * @return the desiredPosition
     */
    private Point2D.Float getDesiredPosition() {
        return desiredPosition;
    }

    /**
     * @param desiredPosition the desiredPosition to set
     */
    private void setDesiredPosition(Point2D.Float desiredPosition) {
        this.desiredPosition = desiredPosition;
        resetControllerState();
    }
    private float tau, Q;

    private void computePoles() {
        // compute the pole locations and resulting tau and Q given PID parameters
        // TODO doesn't include integral term yet
        tau = (float) Math.sqrt(1 / (gravConstantPixPerSec2 * proportionalGain));
        Q =  proportionalGain / derivativeGain;
    }

    /**
     * @return the xTiltRad
     */
    public float getxTiltRad() {
        return xTiltRad;
    }

    /**
     * @return the yTiltRad
     */
    public float getyTiltRad() {
        return yTiltRad;
    }

    /**
     * @return the tilts
     */
    public Point2D.Float getTiltsRad() {
        return tiltsRad;
    }

    /**
     * @return the tiltLimitRad
     */
    public float getTiltLimitRad() {
        return labyrinthHardware.getPanTiltLimitRad();
    }

    /**
     * @param tiltLimitRad the tiltLimitRad to set
     */
    public void setTiltLimitRad(float tiltLimitRad) {
        if (tiltLimitRad < 0.001f) {
            tiltLimitRad = 0.001f; // prevent / by 0
        }
        labyrinthHardware.setPanTiltLimitRad(tiltLimitRad);
    }

    private void resetControllerState() {
        controllerInitialized = false;
        iErr.setLocation(0, 0);
    }

    public enum Message {

        AbortRecording,
        ClearRecording,
        SetRecordingEnabled
    }

    synchronized private void setBallLocationFromMouseEvent(MouseEvent e) {
        Point p = getMousePixel(e);
        if (p == null) {
            return;
        }
        Point2D.Float pf = new Point2D.Float(p.x, p.y);
        tracker.setBallLocation(pf);
    }

    synchronized private void setDesiredPositionFromMouseEvent(MouseEvent e) {
        Point p = getMousePixel(e);
        if (p == null) {
            desiredPosition = null;
            resetControllerState();
            return;
        }
        if (desiredPosition == null) {
            desiredPosition = new Point2D.Float(p.x, p.y);
        } else {
            desiredPosition.x = p.x;
            desiredPosition.y = p.y;
        }
        resetControllerState();
//        log.info("desired position from mouse=" + desiredPosition);
    }

    void processMouseEvent(MouseEvent e) {
        int left=MouseEvent.BUTTON1_DOWN_MASK;
        int middle=MouseEvent.BUTTON2_DOWN_MASK;
        int right=MouseEvent.BUTTON3_DOWN_MASK;
//        log.info("e.getModifiersEx()="+HexString.toString(e.getModifiersEx()));
        if ((e.getModifiersEx()&(middle|right))!=0) {
            setDesiredPositionFromMouseEvent(e);
        } else if((e.getModifiersEx()&left)==left){
            setBallLocationFromMouseEvent(e);
        }
    }

    @Override
    public void mouseClicked(MouseEvent e) {
        processMouseEvent(e);
    }
    
    @Override
    public void mousePressed(MouseEvent e) {
        processMouseEvent(e);
    }

    @Override
    public void mouseDragged(MouseEvent e) {
        processMouseEvent(e);
    }

    class Trajectory extends LinkedList<TrajectoryPoint> {

        final int MAX_POINTS = 1000;

        public void add(long millis, float pan, float tilt) {
            if (size() > MAX_POINTS) {
                removeFirst();
            }
            add(new TrajectoryPoint(millis, pan, tilt));
        }
    }

    class TrajectoryPoint {

        long timeMillis;
        float pan, tilt;

        public TrajectoryPoint(long timeMillis, float pan, float tilt) {
            this.timeMillis = timeMillis;
            this.pan = pan;
            this.tilt = tilt;
        }
    }

    public void centerTilts() {
        try {
            setTilts(0, 0);
        } catch (HardwareInterfaceException ex) {
            log.warning(ex.toString());
        }
    }

    public void disableServos() {
        if (labyrinthHardware != null && labyrinthHardware.getServoInterface() != null) {
            try {
                labyrinthHardware.stopJitter();
                labyrinthHardware.getServoInterface().disableAllServos();
            } catch (HardwareInterfaceException ex) {
                log.warning(ex.toString());
            }
        }
    }

    public LabyrinthHardware getPanTiltHardware() {
        return labyrinthHardware;
    }

    public void controlTilts() {
        if (gui == null || !gui.isDisplayable()) {
            gui = new LabyrinthTableTiltControllerGUI(this);
            gui.addPropertyChangeListener(this);
            gui.setPanTiltLimit(getTiltLimitRad());
        }
        gui.setVisible(true);
    }

    public void loadMap() {
        tracker.doLoadMap();
    }

    public synchronized void clearMap() {
        tracker.doClearMap();
    }

    public void doJiggleTable() {
        Runnable r = new Runnable() {

            public void run() {
                boolean en=isControllerEnabled();
                setControllerEnabled(false);
                tracker.resetFilter();
                centerTilts();
                labyrinthHardware.startJitter();
                try {
                    Thread.sleep(JIGGLE_TIME_MS);
                } catch (InterruptedException ex) {
                }
                labyrinthHardware.stopJitter();
                try {
                    Thread.sleep(100);
                } catch (InterruptedException ex) {
                }
                centerTilts();
                setControllerEnabled(en);

            }
        };
        Thread T = new Thread(r);
        T.setName("TableJiggler");
        T.start();
    }

    public boolean isLostTracking() {
        return tracker.isLostTracking();
    }

    public boolean isAtMazeStart() {
        return tracker.isAtMazeStart();
    }

    public boolean isAtMazeEnd() {
        return tracker.isAtMazeEnd();
    }

    public boolean isPathNotFound() {
        return tracker.isPathNotFound();
    }

    /**
     * @return the controllerEnabled
     */
    public boolean isControllerEnabled() {
        return controllerEnabled;
    }

    /**
     * @param controllerEnabled the controllerEnabled to set
     */
    public void setControllerEnabled(boolean controllerEnabled) {
        this.controllerEnabled = controllerEnabled;
        putBoolean("controllerEnabled", controllerEnabled);
    }
}
