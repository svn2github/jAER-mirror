/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package ch.unizh.ini.jaer.hardware.pantilt.VisualServo;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.DvsMotionOrientationEvent;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;
import ch.unizh.ini.jaer.hardware.pantilt.PanTilt.TrajectoryPoint;
import ch.unizh.ini.jaer.hardware.pantilt.PanTilt;
import java.util.ArrayList;
import javax.media.opengl.GL;
import javax.media.opengl.GL2;
import java.util.Collections;
import java.util.List;
import net.sf.jaer.event.SelfMotionEvent;
import net.sf.jaer.event.MotionOrientationEventInterface;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.eventprocessing.label.AbstractDirectionSelectiveFilter;
import net.sf.jaer.eventprocessing.label.DvsDirectionSelectiveFilter;
import net.sf.jaer.util.Matrix;
import ch.unizh.ini.jaer.hardware.pantilt.PanTiltAimerGUI;

/**
 *
 * @author Bjoern
 */
//TODO: - For some reason the filter does not really work when the actual measured
//        timedifference between panTilt movements is used instead of the set frequency.
//        The measured timeIntervalls vary greatly between .7ms to 24ms with a set
//        frequency of 10ms. However to some extend this can not be correct, as the
//        filter works fine when a fixed intervall of 10ms is used compared to the measured time.
//        This could mean that either the SystemTime is not accurate enough or there is
//        a flaw in the propertychange support.
//      - If the number of points in the pantilt array gets near the MAX_INTEGER value
//        the filter will crash. As the filter relies on the fact that items in the array
//        are NOT shifted arround (otherwise concurrecy would be a problem) this is
//        not trivial to fix and takes a long time to occour
//      - For this filter to work properly the panTilt->Retina transform is artificially 
//        rectified, as the filter is very suscepitble to small deviations in the transformation
public class EfferentFilter extends EventFilter2D implements FrameAnnotater, PropertyChangeListener {
    
    /** ticks per ms of input time */
    public final double NS_PER_US = 1e3;
    public final double NS_PER_MS = 1e6;
    public final double US_PER_S  = 1e6;
    
//    private final PanTiltAimer aimer;
    private final PanTilt pt;
    
    private EventPacket motionPacket = null;
//    private EventPacket dirPacket = null; // the output events, also used for rendering output events
    
    private final AbstractDirectionSelectiveFilter dirFilter;
    private CalibrationTransformation retinaPTCalib;
    private final List<ListPoint> panTiltInducedMotionList = Collections.synchronizedList(new ArrayList<ListPoint>());//need synchronized collection or otherwise we get a lot of access violations and unpredicted behaviour!
    private float   delayThresholdMS            = getFloat("delayThresholdMS",100);
    private float   ppsScale                    = getFloat("ppsScale",.03f);
    private float   alienVelocityThreshold      = getFloat("alienVelocityThreshold",50f);
    private float   angleThreshold              = getFloat("angleThreshold",(float) Math.PI/6);
    private float   lengthThreshold             = getFloat("lengthThreshold",1f);
    private boolean showExpectedMotionEnabled   = getBoolean("showExpectedMotionEnabled",false);
    private boolean showSelfMotionEnabled       = getBoolean("showSelfMotionEnabled",false);
    private boolean showAlienMotionEnabled      = getBoolean("showAlienMotionEnabled",false);
    private boolean showRawInputEnabled         = getBoolean("showRawInputEnabled",true);
    private boolean useFixedTimeIntervalEnabled = getBoolean("useFixedTimeIntervalEnabled",true);
    private boolean outputSelfMotionEnabled     = getBoolean("outputSelfMotionEnabled",true);
    private boolean outputAlienMotionEnabled    = getBoolean("outputAlienMotionEnabled",true);
    private boolean outputPolarityEvents        = getBoolean("outputPolarityEvents",false);
    
    
    int delay;
    byte selfType;
    double curTime, projectionLength;
    float divX,divY,
          ratioX,ratioY;
    Vector2D inducedVelocity    = new Vector2D(0,0), 
             projectionVelocity = new Vector2D(0,0), 
             selfVelocity       = new Vector2D(0,0),
             alienVelocity      = new Vector2D(0,0),
             detectedVelocity   = new Vector2D(0,0);
        
    private class ListPoint {
        Vector2D velocityPPS, ptChange;
        double delay,systemTime;

        public ListPoint(double delay, double systemTime, Vector2D velocity, Vector2D ptChange) {
            this.velocityPPS = velocity;
            this.delay = delay;
            this.systemTime = systemTime;
            this.ptChange = ptChange;
        }
    }
    
    public EfferentFilter(AEChip chip) {
        super(chip);

        pt = PanTilt.getInstance(0); // We initialized the PanTiltAimer to get Instance0, so we want the same instance!
 
        dirFilter = new DvsDirectionSelectiveFilter(chip);
        dirFilter.setAnnotationEnabled(false);
        
        retinaPTCalib = new CalibrationTransformation(chip,"retinaPTCalib");

        setEnclosedFilter(dirFilter);
        
        initFilter();
    }

    @Override public EventPacket<?> filterPacket(EventPacket<?> in) {
        if(in == null) return null;
        if(!filterEnabled) return in;
        
        motionPacket = getEnclosedFilterChain().filterPacket(in); 
        if(outputPolarityEvents) {
            checkOutputPacketEventType(PolarityEvent.class);
        } else {
            checkOutputPacketEventType(SelfMotionEvent.class);
        }
//        if (dirPacket == null) {
//            dirPacket = new EventPacket(SelfMotionEvent.class);
//        }
        
        OutputEventIterator outItr = out.outputIterator();
 
        for(Object eIn:motionPacket) {
            DvsMotionOrientationEvent e = (DvsMotionOrientationEvent) eIn;
            if(!e.isHasDirection()) continue;//writeOutput(outItr,e,false,false,null,null);
            
            delay = e.getDelay();
            detectedVelocity.setLocation(e.getVelocity());
            alienVelocity.setLocation(detectedVelocity);
            selfVelocity.setLocation(0,0);
            curTime = System.nanoTime();

            //There has been no movement of the panTilt. Hence we do nothing.
            if(panTiltInducedMotionList.isEmpty() == true) {
//                System.out.println("No PanTilt motion available");
                if(alienVelocity.length() > alienVelocityThreshold){
                    if(isOutputAlienMotionEnabled()) writeOutput(outItr,e,false,true,null,alienVelocity);  
                } else {
                    continue;
//                    writeOutput(outItr,e,false,false,null,null);    
                }
                continue;
            } 
              
            inducedVelocity.setLocation(delayAdjustedAvgInducedVelociy(panTiltInducedMotionList,delay,curTime));
            if(inducedVelocity.length() == 0) { 
                //If the induced motion either IS zero or if the time between
                // last ptChange and current state is too large we do not have
                // self motion. Hence we do not need to continue.
                if(alienVelocity.length() > alienVelocityThreshold){
                    if(isOutputAlienMotionEnabled()) writeOutput(outItr,e,false,true,null,alienVelocity);    
                } else {
                    continue;
//                    writeOutput(outItr,e,false,false,null,null);    
                }
                continue;
            }
            Vector2D testSelfVelocity = new Vector2D(0,0);
            boolean hasSelfMotion = false;
            boolean hasAlienMotion = true;
            for(MotionOrientationEventInterface.Dir unitDir : MotionOrientationEventInterface.unitDirs) {
                projectionVelocity.setLocation(unitDir.x,unitDir.y);
                projectionVelocity.unify(); // This is needed, as the length of the 'unitDirs' for direction is not always 1.
                projectionLength = inducedVelocity.dotProduct(projectionVelocity);
                if(projectionLength > 0){
                    projectionVelocity.setLength(projectionLength);

                    //Important to note here, that this approach is more general
                    // than would be needed here. Using the angle to differentiate
                    // for similarity makes sense in a general sense, but here we
                    // need to concider, that only quantized directions are used
                    // and we also projected the induced motion onto these quantized
                    // directions. Hence also the angle between detected and induced
                    // velocity is quantized. With the default angle Threshold <PI/4
                    // only the same quantized direction is accepted. This basically
                    // makes the angle-test unnecessary, but I think that in the future
                    // the quantized directions should change at some point and hence
                    // I leave this more general approach.
                    double angle = projectionVelocity.getAngle(detectedVelocity);
                    double lengthDiff = (projectionVelocity.getAbsLengthDiff(detectedVelocity))/detectedVelocity.length();

//                    System.out.println(angle+"///"+lengthDiff);
                    if(angle < angleThreshold && lengthDiff < lengthThreshold) {
                        if(projectionVelocity.length() > testSelfVelocity.length()){
                            testSelfVelocity.setLocation(projectionVelocity);
                            
                            selfVelocity.setLocation(projectionVelocity);
                            alienVelocity.setDifference(detectedVelocity,projectionVelocity);
                            hasSelfMotion = true;
                            hasAlienMotion = true;
                        }
                    } //We dont need to define a 'else' condition, as for the 
                      // case that NO unitvector direction has overlapp with 
                      // the detected motion both boolean flags will still be
                      // zero. If only one of the unitvectors had overlapp we will
                      // have the correct values for self and object motion
                }
            }
            
            
            if(alienVelocity.length() < alienVelocityThreshold){
                hasAlienMotion = false;
                alienVelocity.setLength(0); 
            }
            if(!isOutputAlienMotionEnabled() && selfVelocity.length() > alienVelocity.length()) {
                hasAlienMotion = false;
                alienVelocity.setLength(0);
            } else if(!isOutputAlienMotionEnabled() && selfVelocity.length() < alienVelocity.length()) {
                //We are loosing some information with this method. In fact for all
                // the mixed states that have small self-part (or alien part respectively) we
                // lose the self-part through this continue. However this is necessary 
                // for using this as a filter. If we want to only see motion that is
                // due to objects or due to self, then we need to filter out events
                // completely based on our best guess if it belongs to self or 
                // to object.
                continue;
            }
            
            if(!isOutputSelfMotionEnabled() && selfVelocity.length() < alienVelocity.length()) {
                hasSelfMotion = false;
                selfVelocity.setLength(0);
            } else if(!isOutputSelfMotionEnabled() && selfVelocity.length() > alienVelocity.length()) {
                continue;
            }
            
            if(!isOutputAlienMotionEnabled() && !isOutputSelfMotionEnabled()) {
                continue;
            }
//            System.out.println("Both discovered");
            writeOutput(outItr,e,hasSelfMotion,hasAlienMotion,selfVelocity,alienVelocity);
        }
        return isShowRawInputEnabled() ? in : out; 
    }
    
    public void doAim() {
        PanTiltAimerGUI aimerGui = new PanTiltAimerGUI(PanTilt.getInstance(0));
        aimerGui.setVisible(true);
    }
    //This might look as if we would have possible concurency problems witht the list
    // as code could add items to the list after we determined size. However
    // this is not a problem as long as we do not delete from the list, as new
    // add methods only append to the end of the list. In this regard this method
    // relies on the fact that the order of elements in the list stays the same.
    // this is of course ugly and unsafe but fixing it would include a private locking mechanism in the list which sounds complicated
    private Vector2D delayAdjustedAvgInducedVelociy(List<ListPoint> panTiltInducedMotionList, int delay, double curTime){
        int size = panTiltInducedMotionList.size();
        int n = 0;
        double ptDelay = 0;
        Vector2D ptVelocity = new Vector2D(0,0);
        
        ListPoint currentPanTiltMotionItem = panTiltInducedMotionList.get(size-1);
        if((curTime - currentPanTiltMotionItem.systemTime) > getDelayThresholdMS()*NS_PER_MS){
//            System.out.println("Time difference since last pantilt too large  -->"+(curTime - currentPanTiltMotionItem.systemTime)+">"+(getDelayThresholdMS()*NS_PER_MS));
            return ptVelocity; //We want to return a 0-vector, but at this point ptVelocity is always 0
        }
        
        do {
            if(size <= n) {
                System.out.println("size smaller than needed!");
                break;
            }
            n++;
            currentPanTiltMotionItem = panTiltInducedMotionList.get(size-n);
            
            ptDelay     += currentPanTiltMotionItem.delay;
            ptVelocity.add(currentPanTiltMotionItem.velocityPPS);
        } while (ptDelay <= delay);
        
        ptVelocity.div(n);
        
        return ptVelocity;        
    }
    
    private void writeOutput(OutputEventIterator outItr, DvsMotionOrientationEvent e,boolean hasSelfMotion,boolean hasAlienMotion,Vector2D selfMotion, Vector2D alienMotion) {
        if(outputPolarityEvents) {
            PolarityEvent oe = (PolarityEvent) outItr.nextOutput();
            oe.copyFrom(e);
        } else {
            SelfMotionEvent oe = (SelfMotionEvent) outItr.nextOutput();
            oe.copyFrom(e);
            oe.hasSelfMotion = hasSelfMotion;
            oe.hasAlienMotion = hasAlienMotion;
            if(!hasSelfMotion){
                oe.selfMotion.setLocation(0,0);
            } else {
                oe.selfMotion.setLocation(selfMotion);
            }
            if(!hasAlienMotion) {
                oe.alienMotion.setLocation(0,0);
            } else {
                oe.alienMotion.setLocation(alienMotion);
            }
        }
    }

    @Override public void resetFilter() {
        panTiltInducedMotionList.clear();
    }

    @Override public final void initFilter() {
        pt.addPropertyChangeListener(this);
        resetFilter();
    }

    @Override public void annotate(GLAutoDrawable drawable) {
        if (!isFilterEnabled()) return;

        GL2 gl = drawable.getGL().getGL2();
        if (gl == null) return;
        
        if(showExpectedMotionEnabled) {
            // <editor-fold defaultstate="collapsed" desc="ExpectedMotionAnnotation">
            int size = panTiltInducedMotionList.size();
            if(size > 1){
                gl.glPushMatrix();
                gl.glLineWidth(4f);
                gl.glBegin(GL.GL_LINES);

                Vector2D ptChange = panTiltInducedMotionList.get(size-1).ptChange;
                gl.glColor3f(1, 0, 0);
                
                Vector2D testUnitDir = new Vector2D(0,0),testVector = new Vector2D(0,0);
                double projectionLength;
                for(MotionOrientationEventInterface.Dir unitDir : MotionOrientationEventInterface.unitDirs) {
                    testUnitDir.setLocation(unitDir.x,unitDir.y);
                    testUnitDir.unify();
                    projectionLength = panTiltInducedMotionList.get(size-1).velocityPPS.dotProduct(testUnitDir);
                    
                    if(projectionLength > 0){
                        testVector.setLocation(testUnitDir);
                        testVector.setLength(projectionLength);
                        testVector.drawVector(gl, -10, 64, 1, ppsScale);
                    }
                }
                
                gl.glColor3f(0, 1, 0);
                ptChange.drawVector(gl, -10, 64, 2, 3000);
                
                gl.glEnd();
                gl.glPopMatrix();
            }
            // </editor-fold>
        }
        
        if((isShowSelfMotionEnabled() || isShowAlienMotionEnabled()) && !outputPolarityEvents){
            // <editor-fold defaultstate="collapsed" desc="Alien- and/or SelfMotionAnnotation">
            gl.glPushMatrix();
            float[][] c;
            gl.glLineWidth(2f);
            gl.glBegin(GL.GL_LINES);
            for(Object o:out){
                SelfMotionEvent e=(SelfMotionEvent)o;
                c=chip.getRenderer().makeTypeColors(8);
                if(e.hasSelfMotion && isShowSelfMotionEnabled()) {
                    gl.glColor3fv(c[e.getDirection()],0);
                    e.selfMotion.drawVector(gl, e.x, e.y, 1,ppsScale);
    //                System.out.println("||||"+e.selfMotion.toString());
                }
                if(e.hasAlienMotion && isShowAlienMotionEnabled()) {
                    gl.glColor3fv(c[e.getDirection()],0);
                    e.alienMotion.drawVector(gl, e.x, e.y, 1, ppsScale);
    //                System.out.println("||||"+e.alienMotion.toString());
                }
            }
            gl.glEnd();
            gl.glPopMatrix();
            // </editor-fold>
        }
    }
    
    @Override public void propertyChange(PropertyChangeEvent evt) {
        if(evt.getPropertyName().equals("PanTiltValues") && pt.getPanTiltTrajectory().size() > 1) {
            TrajectoryPoint currentVal = pt.getPanTiltTrajectory().get(pt.getPanTiltTrajectory().size()-1);
            TrajectoryPoint pastVal    = pt.getPanTiltTrajectory().get(pt.getPanTiltTrajectory().size()-2);

            //The tilt needs to be inverted
            float[] ptChange   = {currentVal.getPan() - pastVal.getPan(),-(currentVal.getTilt() - pastVal.getTilt()),1};
            float[] retChange  = retinaPTCalib.makeInverseTransform(ptChange);
            double timeChangeUS;
            if(useFixedTimeIntervalEnabled){
                timeChangeUS = US_PER_S/pt.getMoveUpdateFreqHz();
            } else {
                timeChangeUS = currentVal.getTime()/NS_PER_US;//the time saved in panTiltAimer allready is the timedifference in nanoseconds since the last update
            }
//                System.out.println("timechange:"+timeChangeUS+" // "+(currentVal.getTime()/NS_PER_US));
            Vector2D velocityPPS = new Vector2D((float) (retChange[0]/(timeChangeUS/US_PER_S)),(float) (retChange[1]/(timeChangeUS/US_PER_S)));
            panTiltInducedMotionList.add(new ListPoint(timeChangeUS,System.nanoTime(),velocityPPS, new Vector2D(ptChange[0],ptChange[1])));
//                System.out.println("ptx:"+ptChange[0]+" - pty:"+ptChange[1] + "  --  retx:"+retChange[0]+" /-/ rety:"+retChange[1]+"  --  vx:"+velocityPPS.x + " |--| vy:" + velocityPPS.y);
        }
    }
    
    public void doShowTransform() {
        Matrix.print(retinaPTCalib.getInverseTransformation(),10);
        Matrix.print(retinaPTCalib.getTransformation(),10);
    }

    public boolean isShowExpectedMotionEnabled() {
        return showExpectedMotionEnabled;
    }

    public void setShowExpectedMotionEnabled(boolean showExpectedMotionEnabled) {
        putBoolean("showExpectedMotionEnabled",showExpectedMotionEnabled);
        this.showExpectedMotionEnabled = showExpectedMotionEnabled;
    }

    public boolean isShowSelfMotionEnabled() {
        return showSelfMotionEnabled;
    }

    public void setShowSelfMotionEnabled(boolean showFilteredOnlyEnabled) {
        putBoolean("showSelfMotionEnabled",showSelfMotionEnabled);
        this.showSelfMotionEnabled = showFilteredOnlyEnabled;
    }

    public boolean isShowAlienMotionEnabled() {
        return showAlienMotionEnabled;
    }

    public void setShowAlienMotionEnabled(boolean showAlienMotionEnabled) {
        putBoolean("showAlienMotionEnabled",showAlienMotionEnabled);
        this.showAlienMotionEnabled = showAlienMotionEnabled;
    }

    public float getPpsScale() {
        return ppsScale;
    }

    public void setPpsScale(float ppsScale) {
        putFloat("ppsScale",ppsScale);
        this.ppsScale = ppsScale;
    }

    public boolean isShowRawInputEnabled() {
        return showRawInputEnabled;
    }

    public void setShowRawInputEnabled(boolean showRawInputEnabled) {
        putBoolean("showRawInputEnabled",showRawInputEnabled);
        this.showRawInputEnabled = showRawInputEnabled;
    }

    public boolean isUseFixedTimeIntervalEnabled() {
        return useFixedTimeIntervalEnabled;
    }

    public void setUseFixedTimeIntervalEnabled(boolean useFixedTimeIntervalEnabled) {
        putBoolean("useFixedTimeIntervalEnabled",useFixedTimeIntervalEnabled);
        this.useFixedTimeIntervalEnabled = useFixedTimeIntervalEnabled;
    }

    public boolean isOutputSelfMotionEnabled() {
        return outputSelfMotionEnabled;
    }

    public void setOutputSelfMotionEnabled(boolean outputSelfMotionEnabled) {
        putBoolean("outputSelfMotionEnabled",outputSelfMotionEnabled);
        this.outputSelfMotionEnabled = outputSelfMotionEnabled;
    }

    public boolean isOutputAlienMotionEnabled() {
        return outputAlienMotionEnabled;
    }

    public void setOutputAlienMotionEnabled(boolean outputAlienMotionEnabled) {
        putBoolean("outputAlienMotionEnabled",outputAlienMotionEnabled);
        this.outputAlienMotionEnabled = outputAlienMotionEnabled;
    }

    public boolean isOutputPolarityEvents() {
        return outputPolarityEvents;
    }

    public void setOutputPolarityEvents(boolean outputPolarityEvents) {
        putBoolean("outputPolarityEvents",outputPolarityEvents);
        this.outputPolarityEvents = outputPolarityEvents;
    }

    public float getAlienVelocityThreshold() {
        return alienVelocityThreshold;
    }

    public void setAlienVelocityThreshold(float alienVelocityThreshold) {
        putFloat("alienVelocityThreshold",alienVelocityThreshold);
        this.alienVelocityThreshold = alienVelocityThreshold;
    }

    public float getAngleThreshold() {
        return angleThreshold;
    }

    public void setAngleThreshold(float angleThreshold) {
        putFloat("angleThreshold",angleThreshold);
        this.angleThreshold = angleThreshold;
    }

    public float getLengthThreshold() {
        return lengthThreshold;
    }

    public void setLengthThreshold(float lengthThreshold) {
        putFloat("lengthThreshold",lengthThreshold);
        this.lengthThreshold = lengthThreshold;
    }

    public float getDelayThresholdMS() {
        return delayThresholdMS;
    }

    public void setDelayThresholdMS(float delayThresholdMS) {
        putFloat("delayThresholdMS",delayThresholdMS);
        this.delayThresholdMS = delayThresholdMS;
    }
    
}
