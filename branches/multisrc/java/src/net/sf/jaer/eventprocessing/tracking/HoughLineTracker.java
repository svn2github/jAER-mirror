/*
 * LineTracker.java
 *
 * Created on December 26, 2006, 9:24 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright December 26, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package net.sf.jaer.eventprocessing.tracking;

import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.filter.AngularLowpassFilter;
import net.sf.jaer.util.filter.LowpassFilter;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.util.*;
import javax.media.opengl.*;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.glu.GLU;
import javax.swing.*;
import net.sf.jaer.Description;

/**
 * Tracks a single line as used for line-following navigation or for lane tracking.
<p>
Origin of the line is center of image.
Angle of line is 0 when vertical and positive for clockwise line rotation.
<p>
The line is tracked using an incremental Hough transform method. See
http://rkb.home.cern.ch/rkb/AN16pp/node122.html for a concise explanation of basic idea of Hough's.
Or http://en.wikipedia.org/wiki/Hough_transform.
Or http://www.cs.tu-bs.de/rob/lehre/bv/HNF.html for a good interactive java applet demo.
<p>
Each point is splatted in its p, theta form into an accumulator array;
the array maximum value is computed for each
packet and the resulting p,theta values are lowpass filtered to form the output.
 * @author tobi
@see LineDetector
 */
@Description("Tracks a single line as used for line-following navigation or for lane tracking")
public class HoughLineTracker extends EventFilter2D implements FrameAnnotater, LineDetector, Observer {

    //    static Preferences prefs=Preferences.userNodeForPackage(HoughLineTracker.class);
//    Line line=new Line();
    private float angleMixingFactor = getPrefs().getFloat("LineTracker.angleMixingFactor", 0.005f);
    

    {
        setPropertyTooltip("angleMixingFactor", "how much angle gets turned per packet");
    }
    private float positionMixingFactor = getPrefs().getFloat("LineTracker.positionMixingFactor", 0.005f);
    

    {
        setPropertyTooltip("positionMixingFactor", "how much line position gets moved per packet");
    }
//    private boolean favorVertical=getPrefs().getBoolean("LineTracker.favorVertical",true);
//    {setPropertyTooltip("favorVertical","favors vertical lines by weighting them more in accumulator");}
    private float favorVerticalAngleRangeDeg = getPrefs().getFloat("LineTracker.favorVerticalAngleRangeDeg", 90);
    

    {
        setPropertyTooltip("favorVerticalAngleRangeDeg", "range of angle on each side of vertical that is allowed for line");
    }
    private int allowedThetaNumber = getAllowedThetaNumber(favorVerticalAngleRangeDeg);
//    private int updateThresholdEvents=getPrefs().getInt("LineTracker.updateThresholdEvents",2);
//    {setPropertyTooltip("updateThresholdEvents","the line estimate will not be updated unless you getString at least this many events per packet in the biggest accumulator cell");}
    private float houghDecayFactor = getPrefs().getFloat("LineTracker.houghDecayFactor", 0.6f);
    

    {
        setPropertyTooltip("houghDecayFactor", "hough accumulator cells are multiplied by this factor before each frame, 0=no memory, 1=infinite memory");
    }//    private float lineWidth=prefs.getFloat("LineTracker.lineWidth",10f);
    private float thetaResDeg = getPrefs().getFloat("LineTracker.thetaResDeg", 10);
    

    {
        setPropertyTooltip("thetaResDeg", "quantization in degrees of hough transform map");
    }
    private float rhoResPixels = getPrefs().getFloat("LineTracker.rhoResPixels", 6);
    

    {
        setPropertyTooltip("rhoResPixels", "quantization in pixels of hough transform map");
    }
    private boolean showHoughWindow = false;
    

    {
        setPropertyTooltip("showHoughWindow", "shows the hough transform integrator array");
    }
    private float rhoLimit;
    private float[][] accumArray;
    private int nTheta,  nRho;
    private float tauMs = getPrefs().getFloat("LineTracker.tauMs", 10);
    

    {
        setPropertyTooltip("tauMs", "time constant in ms of line lowpass");
    }
    float[] cos = null, sin = null;
    int rhoMaxIndex, thetaMaxIndex;
    float accumMax;
    int[][] accumUpdateTime;
    float sx2, sy2; // half chip size
    private float rhoPixelsFiltered = 0;
    private float thetaDegFiltered = 0;
    LowpassFilter rhoFilter;
//    LowpassFilter thetaFilter;  // this lowpass filter handles periodicity of angle
    AngularLowpassFilter thetaFilter;  // this lowpass filter handles periodicity of angle
//    private int maxNumLines=getPrefs().getInt("LineTracker.maxNumLines",2);
//    private List<Line> lines=new ArrayList<Line>(maxNumLines);
//    Peak[] peaks=null;

    /** Creates a new instance of LineTracker
    @param chip the chip to track for
     */
    public HoughLineTracker(AEChip chip) {
        super(chip);
        initFilter();
        chip.addObserver(this);
    }

    /** returns the Hough line radius of the last packet's estimate -
    the closest distance from the middle of the chip image.
    @return the distance in pixels. If the chip size is sx by sy, can
    range over +-Math.sqrt( (sx/2)^2 + (sy/2)^2).
    This number is positive if the line is above the origin (center of chip)
     */
    synchronized public float getRhoPixels() {
        return (rhoMaxIndex - nRho / 2) * rhoResPixels;
    }

    /** returns the angle of the last packet's Hough line.
    @return angle in degrees. Ranges from 0 to 180 degrees,
    where 0 and 180 represent a vertical line and 90 is a horizontal line
     */
    synchronized public float getThetaDeg() {
        return (thetaMaxIndex) * thetaResDeg;
    }

    /** returns the angle of the last packet's Hough line.
    @return angle in radians. Ranges from 0 to Pi radians,
    where 0 and Pi represent a vertical line and Pi/2 is a horizontal line
     */
    public float getThetaRad() {
        return getThetaDeg() / 180 * 3.141592f;
    }

    synchronized public void resetFilter() {
        sx2 = chip.getSizeX() / 2;
        sy2 = chip.getSizeY() / 2;
        nTheta = (int) (180 / thetaResDeg); // theta spans only 0 to Pi
        rhoLimit = (float) Math.ceil(Math.sqrt(sx2 * sx2 + sy2 * sy2));
        // rho can span this +/- limit after hough transform of event
        // coordinate which shifted so that middle of chip is zero
        nRho = (int) (2 * rhoLimit / rhoResPixels);
        accumArray = new float[nTheta][nRho];
//        accumUpdateTime=new int[nTheta][nRho];
        accumMax = Float.NEGATIVE_INFINITY;
        // precompute sin/cos for accumulator array updates for quantized angle values
        cos = new float[nTheta];
        sin = new float[nTheta];
        for (int i = 0; i < cos.length; i++) {
            cos[i] = (float) Math.cos(thetaResDeg * (i) / 180 * Math.PI);
            // cos[i] is the cos of the i'th angle, runs from approx 0 to 2 Pi rad
            sin[i] = (float) Math.sin(thetaResDeg * (i) / 180 * Math.PI);
        }
        rhoFilter = new LowpassFilter();
//        thetaFilter=new LowpassFilter(); // periodic filter with period 180 degrees
        thetaFilter = new AngularLowpassFilter(180); // periodic filter with period 180 degrees
        rhoFilter.setTauMs(tauMs);
        thetaFilter.setTauMs(tauMs);
        allowedThetaNumber = getAllowedThetaNumber(favorVerticalAngleRangeDeg);
    }

    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        if (!isFilterEnabled()) {
            return in;
        }
        if (getEnclosedFilter() != null) {
            in = getEnclosedFilter().filterPacket(in);
        }
        if (getEnclosedFilterChain() != null) {
            in = getEnclosedFilterChain().filterPacket(in);
        }
        for (BasicEvent e : in) {
            addEvent(e);
        }
        decayAccumArray();
        thetaDegFiltered = thetaFilter.filter(getThetaDeg(), in.getLastTimestamp());
        rhoPixelsFiltered = rhoFilter.filter(getRhoPixels(), in.getLastTimestamp());
        if (showHoughWindow) {
            checkAccumFrame();
            accumCanvas.repaint();
        }
        return in;
    }
    // http://rkb.home.cern.ch/rkb/AN16pp/node122.html
    private void addEvent(BasicEvent e) {
        float x = e.x - sx2;
        float y = e.y - sy2; // x,y relative to center of chip
        // iterate over all angles included in allowedThetaNumber angles
        for (int thetaNumber = 0; thetaNumber < allowedThetaNumber; thetaNumber++) {
            // only iterate up to allowed angle, 0 is vertical line,
            // iterate over theta, computing  rho, quantizing it, and integrating it into the Hough array
            float rho = ((x * cos[thetaNumber] + y * sin[thetaNumber]));
            int rhoNumber = (int) ((rho + rhoLimit) / rhoResPixels);
            if (rhoNumber < 0 || rhoNumber >= nRho) {
//                log.warning(String.format("e.x=%d, e.y=%d, x=%f, y=%f, rho=%f, rhoNumber=%d",e.x,e.y,x,y,rho,rhoNumber));
                continue;
            }
            updateHoughAccumulator(thetaNumber, rhoNumber);
        }
        // iterate over all angles included in allowedThetaNumber angles, handle the angles from Pi-allowedThetaNumber to Pi
        for (int thetaNumber = nTheta - allowedThetaNumber + 1; thetaNumber < nTheta; thetaNumber++) {
            // only iterate up to allowed angle, 0 is vertical line,
            // iterate over theta, computing  rho, quantizing it, and integrating it into the Hough array
            float rho = ((x * cos[thetaNumber] + y * sin[thetaNumber]));
            int rhoNumber = (int) ((rho + rhoLimit) / rhoResPixels);
            if (rhoNumber < 0 || rhoNumber >= nRho) {
//                log.warning(String.format("e.x=%d, e.y=%d, x=%f, y=%f, rho=%f, rhoNumber=%d",e.x,e.y,x,y,rho,rhoNumber));
                continue;
            }
            updateHoughAccumulator(thetaNumber, rhoNumber);
        }
    }

    /** Uses a reset array and just counts events in
    each bin to determine the peak locations of the lines
    @param thetaNumber the index of the theta of the line.
    thetaNumber=0 means theta=0 which is a horizontal line, theta=nTheta/2 is a vertical line. ???? must be wrong, rotate 90 deg
    @param rhoNumber the rho (radius) number. rho is spaced by rhoResPixels.
     */
    private void updateHoughAccumulator(int thetaNumber, int rhoNumber) {
        float f = accumArray[thetaNumber][rhoNumber];
        f++;
        accumArray[thetaNumber][rhoNumber] = f; // update the accumulator
    }

    public void annotate(GLAutoDrawable drawable) {
        if (!isFilterEnabled()) {
            return;
        }
        final float LINE_WIDTH = 5f; // in pixels
        GL gl = drawable.getGL(); // when we getString this we are already set up with scale 1=1 pixel, at LL corner
        gl.glLineWidth(LINE_WIDTH);
        double thetaRad = getThetaRad();
        double cosTheta = Math.cos(thetaRad);
        double sinTheta = Math.sin(thetaRad);
        gl.glColor3f(0, 0, 1);
        gl.glBegin(GL.GL_LINES);
        if (thetaRad > Math.PI / 4 && thetaRad < 3 * Math.PI / 4) {
            gl.glVertex2d(0, yFromX(0, cosTheta, sinTheta));
            gl.glVertex2d(sx2 * 2, yFromX(sx2 * 2, cosTheta, sinTheta));
        } else {
            gl.glVertex2d(xFromY(0, cosTheta, sinTheta), 0);
            gl.glVertex2d(xFromY(sy2 * 2, cosTheta, sinTheta), sy2 * 2);
        }
        gl.glEnd();
    }
    // returns chip y from chip x using present fit
    private double yFromX(float x, double cosTheta, double sinTheta) {
        double xx = x - sx2;
        double yy = (rhoPixelsFiltered - xx * cosTheta) / sinTheta;
        double y = yy + sy2;
//        if(y>sy2*2) y=sy2*100; else if(y<0) y=-sy2*100;
        return y;
    }
    // returns chip x from chip y using present fit
    private double xFromY(float y, double cosTheta, double sinTheta) {
        double yy = y - sy2;
        double xx = (rhoPixelsFiltered - yy * sinTheta) / cosTheta;
        double x = xx + sx2;
        return x;
    }

    void checkAccumFrame() {
        if (showHoughWindow && (accumFrame == null || (accumFrame != null && !accumFrame.isVisible()))) {
            createAccumFrame();
        }
    }
    JFrame accumFrame = null;
    GLCanvas accumCanvas = null;
    GLU glu = null;
//    GLUT glut=null;
    void createAccumFrame() {
        accumFrame = new JFrame("Hough accumulator");
        accumFrame.setPreferredSize(new Dimension(200, 200));
        accumCanvas = new GLCanvas();
        accumCanvas.addGLEventListener(new GLEventListener() {

            public void init(GLAutoDrawable drawable) {
            }

            synchronized public void display(GLAutoDrawable drawable) {
                if (accumArray == null) {
                    return;
                }
                GL gl = drawable.getGL();
                gl.glLoadIdentity();
                gl.glScalef(drawable.getWidth() / nTheta, drawable.getHeight() / nRho, 1);
                gl.glClearColor(0, 0, 0, 0);
                gl.glClear(GL.GL_COLOR_BUFFER_BIT);
                for (int i = 0; i < nTheta; i++) {
                    for (int j = 0; j < nRho; j++) {
                        float f = accumArray[i][j] / accumMax;
                        gl.glColor3f(f, f, f);
                        gl.glRectf(i, j, i + 1, j + 1);
                    }
                }
                gl.glPointSize(6);
                gl.glColor3f(1, 0, 0);
                gl.glBegin(GL.GL_POINTS);
                gl.glVertex2f(thetaMaxIndex, rhoMaxIndex);
                gl.glEnd();
//                if(glut==null) glut=new GLUT();
                int error = gl.glGetError();
                if (error != GL.GL_NO_ERROR) {
                    if (glu == null) {
                        glu = new GLU();
                    }
                    log.warning("GL error number " + error + " " + glu.gluErrorString(error));
                }
            }

            synchronized public void reshape(GLAutoDrawable drawable, int x, int y, int width, int height) {
                GL gl = drawable.getGL();
                final int B = 10;
                gl.glMatrixMode(GL.GL_PROJECTION);
                gl.glLoadIdentity(); // very important to load identity matrix here so this works after first resize!!!
                gl.glOrtho(-B, drawable.getWidth() + B, -B, drawable.getHeight() + B, 10000, -10000);
                gl.glMatrixMode(GL.GL_MODELVIEW);
                gl.glViewport(0, 0, width, height);
            }

            public void displayChanged(GLAutoDrawable drawable, boolean modeChanged, boolean deviceChanged) {
            }
        });
        accumFrame.getContentPane().add(accumCanvas);
        accumFrame.pack();
        accumFrame.setVisible(true);
    }

    public Object getFilterState() {
        return null;
    }

    public void initFilter() {
        resetFilter();
    }

    public void annotate(float[][][] frame) {
    }

    public void annotate(Graphics2D g) {
    }

    public float getThetaResDeg() {
        return thetaResDeg;
    }

    synchronized public void setThetaResDeg(float thetaResDeg) {
        this.thetaResDeg = thetaResDeg;
        getPrefs().putFloat("LineTracker.thetaResDeg", thetaResDeg);
        resetFilter();
    }

    public float getRhoResPixels() {
        return rhoResPixels;
    }

    synchronized public void setRhoResPixels(float rhoResPixels) {
        this.rhoResPixels = rhoResPixels;
        getPrefs().putFloat("LineTracker.rhoResPixels", rhoResPixels);
        resetFilter();
    }

    public float getTauMs() {
        return tauMs;
    }

    synchronized public void setTauMs(float tauMs) {
        this.tauMs = tauMs;
        getPrefs().putFloat("LineTracker.tauMs", tauMs);
        rhoFilter.setTauMs(tauMs);
        thetaFilter.setTauMs(tauMs);
    }
    // doesn't actually reset, but decays accumulator array according to houghDecayFactor
    // also determines maximum accumulator value and sets line estimate according to this
    private void decayAccumArray() {
        accumMax = 0;
        for (int theta = 0; theta < nTheta; theta++) {
            float[] f = accumArray[theta];
            for (int rho = 0; rho < f.length; rho++) {
                float fval = f[rho];
                fval *= houghDecayFactor;
                if (fval > accumMax) {
                    accumMax = fval;
                    thetaMaxIndex = theta;
                    rhoMaxIndex = rho;
                }
                f[rho] = fval;
            }
        }
    }

    public boolean isShowHoughWindow() {
        return showHoughWindow;
    }

    synchronized public void setShowHoughWindow(boolean showHoughWindow) {
        this.showHoughWindow = showHoughWindow;
    }

    private void findPeaks() {
    }

    /** returns the filtered Hough line radius estimate - the closest distance from the middle of the chip image.
    @return the distance in pixels. If the chip size is sx by sy, can range over +-Math.sqrt( (sx/2)^2 + (sy/2)^2).
    This number is positive if the line is above the origin (center of chip)
     */
    public float getRhoPixelsFiltered() {
        return rhoPixelsFiltered;
    }

    /**
    returns the filtered angle of the line.
    @return angle in degrees. Ranges from 0 to 180 degrees, where 0 and 180 represent a vertical line and 90 is a horizontal line
     */
    public float getThetaDegFiltered() {
        return thetaDegFiltered;
    }

    public void update(Observable o, Object arg) {
        // chip may have changed, update ourselves
        resetFilter();
    }
//    public boolean isFavorVertical() {
//        return favorVertical;
//    }
//
//    public void setFavorVertical(boolean favorVertical) {
//        this.favorVertical = favorVertical;
//        getPrefs().putBoolean("LineTracker.favorVertical",favorVertical);
//    }
    // returns range around 0 (vertical) that are allowed angles of line
    private int getAllowedThetaNumber(float favorVerticalAngleRangeDeg) {
        return (int) Math.round(favorVerticalAngleRangeDeg / 180 * nTheta);
    }

    public float getFavorVerticalAngleRangeDeg() {
        return favorVerticalAngleRangeDeg;
    }

    public void setFavorVerticalAngleRangeDeg(float favorVerticalAngleRangeDeg) {
        if (favorVerticalAngleRangeDeg < 5) {
            favorVerticalAngleRangeDeg = 5;
        } else if (favorVerticalAngleRangeDeg > 90) {
            favorVerticalAngleRangeDeg = 90;
        }
        this.favorVerticalAngleRangeDeg = favorVerticalAngleRangeDeg;
        allowedThetaNumber = getAllowedThetaNumber(favorVerticalAngleRangeDeg);
        getPrefs().putFloat("LineTracker.favorVerticalAngleRangeDeg", favorVerticalAngleRangeDeg);
    }
//    public int getUpdateThresholdEvents() {
//        return updateThresholdEvents;
//    }
//    
//    public void setUpdateThresholdEvents(int updateThresholdEvents) {
//        if(updateThresholdEvents<0)updateThresholdEvents=0; else if(updateThresholdEvents>100) updateThresholdEvents=100;
//        this.updateThresholdEvents = updateThresholdEvents;
//        getPrefs().putInt("LineTracker.updateThresholdEvents",updateThresholdEvents);
//    }
    public float getHoughDecayFactor() {
        return houghDecayFactor;
    }

    public void setHoughDecayFactor(float houghDecayFactor) {
        if (houghDecayFactor < 0) {
            houghDecayFactor = 0;
        } else if (houghDecayFactor > 1) {
            houghDecayFactor = 1;
        }
        this.houghDecayFactor = houghDecayFactor;
        getPrefs().putFloat("LineTracker.houghDecayFactor", houghDecayFactor);
    }
}


