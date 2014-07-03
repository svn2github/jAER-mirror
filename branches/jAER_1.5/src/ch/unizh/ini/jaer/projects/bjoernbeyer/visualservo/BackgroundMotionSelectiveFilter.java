
package ch.unizh.ini.jaer.projects.bjoernbeyer.visualservo;

import net.sf.jaer.util.Vector2D;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Level;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OpticalFlowEvent;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.label.SmoothOpticalFlowLabeler;
import net.sf.jaer.graphics.FrameAnnotater;
import javax.media.opengl.GL2;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.util.DrawGL;

/**
 *
 * @author Bjoern
 */
public class BackgroundMotionSelectiveFilter extends EventFilter2D implements Observer, FrameAnnotater {
    
    /** ticks per ms of input time */
    public final int TICK_PER_MS = 1000;
    private final int MINX = 0, MINY = 0;
    
    private int maxX, maxY;
    
    private final SmoothOpticalFlowLabeler motionFilter;
    
    private EventPacket motionPacket = null;
     
    //with outerRadius=30 and innerRadius=20 we have 1576 pixels in the inhibitory
    // range. Hence roughly 10% of the overall 16'384 pixels.
    private int inhibitionOuterRadiusPX       = getInt("inhibitionOuterRadius",30); //The outer radius of inhibition in pixel from the current position.
    private int inhibitionInnerRadiusPX       = getInt("inhibitionInnerRadius",28); //The inner radius of inhibition (meaning pixel closer to current than this will not inhibit) in pixel.
    //with excitationRadius=5 we average over 80 pixels around the center pixel
    private int excitationOuterRadiusPX       = getInt("excitationOuterRadius",6); //The excitation radius in pixel from current position. By default the current cell does not self excite.
    private int excitationInnerRadiusPX       = getInt("excitationOuterRadius",1); //The excitation radius in pixel from current position. By default the current cell does not self excite.
    private int circleCoarseness              = getInt("circleCoarseness",2);      
    private float maxDtMs                     = getFloat("maxDtMs",50f); //The maximum temporal distance in milliseconds between the current event and the last event in an inhibiting or exciting location that is taken into acount for the averge inhibition/excitation vector. Events with a dt larger than this will be ignored. Events with half the dt than this will contribute with 50% of their length.
    private float exciteInhibitRatioThreshold = getFloat("exciteInhibitRatioThreshold",-.3f);
    private boolean showRawInputEnabled       = getBoolean("showRawInputEnabled",false);
    private boolean drawInhibitExcitePoints   = getBoolean("drawInhibitExcitePoints",false);
    private boolean drawCenterCell            = getBoolean("drawCenterCell",false); 
    private boolean showInhibitedEvents       = getBoolean("showInhibitedEvents", true);
    private boolean outputPolarityEvents      = getBoolean("outputPolarityEvents", false);
    
    //Filter Variables
    private byte hasGlobalMotion;
    private final Vector2D avgExcitatoryDir = new Vector2D();
    private final Vector2D avgInhibitoryDir = new Vector2D();
    private double exciteInhibitRatio = 0;
    // End filter Variables
    
    private int[][] inhibitionCirc,excitationCirc;
    private Vector2D[][] lastDirMap;
    private int[][] lastTimesMap;
    
    private int x,y;
    
    private CalibratedStimulusGUI StimGUI;
    
    //TODO: make sure that everytime a raidus changes we calculate the new circle.
    //TODO: Das wird jetzt alles nicht funktionieren wenn man subsampled im anderen Filter oder?
    public BackgroundMotionSelectiveFilter(AEChip chip) {
        super(chip);
        chip.addObserver(this);
        resetFilter();
        
        motionFilter = new SmoothOpticalFlowLabeler(chip);
        motionFilter.setAnnotationEnabled(false);
        setEnclosedFilter(motionFilter);
    }

    @Override public EventPacket<?> filterPacket(EventPacket<?> in) {
        if(in==null) return null;
        if(!filterEnabled) return in;

        motionPacket = motionFilter.filterPacket(in); 
        if (motionPacket.getEventClass() != OpticalFlowEvent.class) {
            log.log(Level.WARNING, "input events are {0}, but they need to be OpticalFlowEvent's", motionPacket.getEventClass());
            return in;
        }  
        if(outputPolarityEvents) {
            checkOutputPacketEventType(PolarityEvent.class);
        } else {
            checkOutputPacketEventType(BackgroundMotionInhibitedEvent.class);
        }
        
        checkMaps();
        OutputEventIterator outItr = out.outputIterator();
       
        for(Object eIn:motionPacket) {
            OpticalFlowEvent e = (OpticalFlowEvent) eIn;
            
            //It is important that this filter is getting all events from the
            // directionSelective and orientationFilters. This means that the 
            // current event could be an event that has no orientation or no
            // direction of motion. However we can still inhibit this event, if
            // it is in the vicinity of detected global motion. So we do our
            // center/surround computation for every event and block it, if the
            // motion in the center is similar to the motion in the surround.
            // It is important that we inhibit ANY event, not just those that
            // have motion attached to them.
            
            x = e.x;
            y = e.y;

            lastDirMap[x][y].setLocation(e.optFlowVelPPS);
            lastTimesMap[x][y] = e.timestamp;
            
            avgExcitatoryDir.setLocation(getAvgDir(x,y,excitationCirc));
            avgInhibitoryDir.setLocation(getAvgDir(x,y,inhibitionCirc));
            //System.out.println("excecDir:"+avgExcitatoryDir + " inhibitDir:"+avgInhibitoryDir);

            if(avgExcitatoryDir.length() != 0) avgExcitatoryDir.unify(); 
            if(avgInhibitoryDir.length() != 0) avgInhibitoryDir.unify();
            exciteInhibitRatio = avgInhibitoryDir.dotProduct(avgExcitatoryDir);
            if(avgInhibitoryDir.length()==0 && avgExcitatoryDir.length() != 0) exciteInhibitRatio = -1; //Only ExcitatoryMotion detected
            if(avgInhibitoryDir.length()!=0 && avgExcitatoryDir.length() == 0) exciteInhibitRatio = 1; //Only InhibitoryMotion detected
            //As we are calculating the dot product of unified vectors, we are
            // sure that the ratio will be between -1 and 1.
            
            if( exciteInhibitRatio >= exciteInhibitRatioThreshold){// INHIBITION
                hasGlobalMotion = 1;
                if(!showInhibitedEvents) continue;
            } else {// EXCITATION
                hasGlobalMotion=0;
            }
            
            writeEvent(outItr,e);
            //System.out.println("type:"+hasGlobalMotion+" outLength:"+outDir.length()+" inLength:"+centerDir.length()+" ratio:"+saveRatio);
        }
        return showRawInputEnabled ? in : out;
    }

    @Override
    public final void resetFilter() {
        checkMaps();
        
        maxX=chip.getSizeX();
        maxY=chip.getSizeY();
        
        inhibitionCirc = PixelCircle(inhibitionOuterRadiusPX,inhibitionInnerRadiusPX,circleCoarseness);
        excitationCirc = PixelCircle(excitationOuterRadiusPX,excitationInnerRadiusPX,circleCoarseness);//inner Radius 1 means that the cell does not excite itself.
    }

    private void writeEvent(OutputEventIterator outItr, OpticalFlowEvent e) { 
        if(outputPolarityEvents) {
            PolarityEvent oe = (PolarityEvent) outItr.nextOutput();
            oe.copyFrom(e);
        } else {
            BackgroundMotionInhibitedEvent oe = (BackgroundMotionInhibitedEvent) outItr.nextOutput();
            oe.copyFrom(e);
            oe.avgExcitationVel.setLocation(avgExcitatoryDir);
            oe.avgInhibitionVel.setLocation(avgInhibitoryDir);
            oe.exciteInhibitionRatio = exciteInhibitRatio;
            oe.hasGlobalMotion = hasGlobalMotion;
        }   
    }
    
    @Override public void initFilter() { resetFilter(); }

    @Override public void update(Observable o, Object arg) {
        if (o instanceof AEChip) {
            if (arg == AEChip.EVENT_SIZEX || arg == AEChip.EVENT_SIZEY) {
                resetFilter();
            }
        }
    }
    
    @Override public void annotate(GLAutoDrawable drawable) {
        if(!outputPolarityEvents){
            GL2 gl = drawable.getGL().getGL2();
            // draw individual motion vectors
            if(drawInhibitExcitePoints) {
                gl.glPushMatrix();
                gl.glColor3f(1, 1, 1);
                gl.glLineWidth(3f);
                gl.glPointSize(2);
                for (Object o : out) {
                    BackgroundMotionInhibitedEvent e = (BackgroundMotionInhibitedEvent) o;
                    float[][] c=chip.getRenderer().makeTypeColors(2);
                    gl.glColor3fv(c[e.hasGlobalMotion],0);
                    gl.glBegin(GL2.GL_POINTS);
                        gl.glVertex2d(e.x, e.y);
                    gl.glEnd();
                }
                gl.glPopMatrix();
            }

            if(drawCenterCell) {
                gl.glPushMatrix();

                gl.glPointSize(2);
                gl.glLineWidth(4f);

                //Draw regions of average
                gl.glBegin(GL2.GL_POINTS);
                    gl.glColor3f(1, 1, 0);
                    for (int[] circ1 : inhibitionCirc) {
                        gl.glVertex2d(circ1[0]+maxX/2, circ1[1]+maxY/2);
                    }
                    gl.glColor3f(0, 1, 1);
                    for (int[] circ1 : excitationCirc) {
                        gl.glVertex2d(circ1[0]+maxX/2, circ1[1]+maxY/2);
                    }
                gl.glEnd();
                gl.glPopMatrix();
                
                int xOffset = maxX/2,yOffset = maxY/2;
                int scale=20;
                for(Object o : out) {
                    BackgroundMotionInhibitedEvent e = (BackgroundMotionInhibitedEvent) o;
                    if(e.x == maxX/2 && e.y == maxY/2){
                        gl.glPushMatrix();
                        gl.glColor3f(0, 1, 0);
                        e.avgExcitationVel.drawVector(gl, xOffset+20, yOffset, 1, scale);
                        gl.glPopMatrix();
                        
                        gl.glPushMatrix();
                        gl.glColor3f(1, 0, 0);
                        e.avgInhibitionVel.drawVector(gl, xOffset-20, yOffset, 1, scale);
                        gl.glPopMatrix();

                        gl.glColor3f(1, 1, 1);
                        gl.glRectf(-10, 0, -5,  100*(float)e.exciteInhibitionRatio);
                        gl.glRectf(-10.5f, 0, -10, 100);
                    }
                }
            }
        }
    }
    
    private void checkMaps(){
        if(lastTimesMap==null || lastTimesMap.length!=maxX || lastTimesMap[0].length!=maxY){
            allocateTimesMap();
        }
        if(lastDirMap==null ||  lastDirMap.length!=maxX || lastDirMap[0].length!=maxY){
            allocateLastDirMap();
        }
    }
    
    private void allocateTimesMap() {
        if(!isFilterEnabled()) return;
        lastTimesMap=new int[maxX][maxY];
        log.log(Level.INFO,"allocated int[{0}][{1}] array for last event times", new Object[]{maxX,maxY});
    }
    private void allocateLastDirMap() {
        if(!isFilterEnabled()) return;
        lastDirMap=new Vector2D[maxX][maxY];
        //Need to deep-initialize this, such that we can assign to each element directly
        // this is done only once and hence shouldnt be too expensive.
        for(int i=0;i<maxX;i++) {
            for(int j=0;j<maxY;j++) {
                lastDirMap[i][j] = new Vector2D();
            }
        }
        log.log(Level.INFO,"allocated int[{0}][{1}] array for last optic flow velocities", new Object[]{maxX,maxY});
    }
    
    /** Computes the average optical flow vector from all positions given in a 
     * position list and with an (x,y) offset.
     * 
     * Each vector to be averaged is weighted by the temporal distance to the 
     * current event, effectively highpass filtering the Vectors before averaging.
     * Events with a dt > maxDtMs are ignored and not taken into account in the average.
     * 
     * @param x the offset of the pixel list in the x direction
     * @param ythe offset of the pixel list in the y direction
     * @param xyPixelList A [n][2] list where the first dimension is a list of 
     *  points that are defined in the second dimension. [n][0] is the x-component
     *  [n][1] is the y component of the point to be averaged.
     * @return the averaged vector. If no Event in the Testregion passed the 
     * significanceTest a (0,0) vector is returned.*/
    private Vector2D getAvgDir(int x, int y, int[][] xyPixelList) {
        Vector2D res = new Vector2D(0,0);
        int n = 0,dt = 0,xLoc,yLoc;
        float fac;

        for (int[] xyItem : xyPixelList) {
            xLoc = xyItem[0] + x;
            yLoc = xyItem[1] + y;
            if(xLoc < MINX || xLoc >= maxX || yLoc < MINY || yLoc >= maxY) {
                //We are 'out of bounds' of the sensor. Nothing we can do here.
                // This DOES mean that we get some boundary effects, where the
                // average is not as meaningful as in the middle of the sensor,
                // but if the radii of excitation and inhibition are sufficiently
                // large it should not be a problem.
                continue;
            }
            
            dt = lastTimesMap[x][y]-lastTimesMap[xLoc][yLoc];
            fac = 1-(dt/(maxDtMs*TICK_PER_MS));
            
            if(fac <= 0){
                continue; 
                //This means that dt >= maxDtMs
                //No need to add zero and also dont increment n as nothing was added.
            }
            res.addFraction(lastDirMap[xLoc][yLoc],fac);
            n++;
        }
        
        if(n!=0) res.div(n);
        return res;
    }
    
    private int[][] PixelCircle(int outerRadius, int innerRadius, int coarseness){
        //savely oversizing the array, we return only the first n elements anyway
        // The integer sequence A000328 of pixels in a circle is expansive to compute
        // All upper bounds involve square roots and potentiation.
        int[][] pixCirc = new int[(1+4*outerRadius*outerRadius)-(4*innerRadius*innerRadius)][2]; 
        int n = 0;
        if(coarseness<1)coarseness=1;
        
        for(int xCirc = -outerRadius; xCirc<=outerRadius; xCirc+=coarseness) {
            for(int yCirc = -outerRadius; yCirc<=outerRadius; yCirc+=coarseness) {
                if(((xCirc*xCirc)+(yCirc*yCirc) <= (outerRadius*outerRadius)) && ((xCirc*xCirc)+(yCirc*yCirc) >= (innerRadius*innerRadius))){
                    pixCirc[n][0] = xCirc;
                    pixCirc[n][1] = yCirc;
                    n++;    
                }
            }
        }
        int[][] res = new int[n][2];
        for(int p=0;p<n;p++) {
            res[p][0] = pixCirc[p][0];
            res[p][1] = pixCirc[p][1];
        }
        return res;
    }

    public float getExciteInhibitRatioThreshold() {
        return exciteInhibitRatioThreshold;
    }

    public void setExciteInhibitRatioThreshold(float exciteInhibitRatioThreshold) {
        float setValue = exciteInhibitRatioThreshold;
        if(setValue > 1) setValue = 1;
        if(setValue < -1)setValue = -1;
        this.exciteInhibitRatioThreshold = setValue;
    }

    public boolean isOutputPolarityEvents() {
        return outputPolarityEvents;
    }

    public void setOutputPolarityEvents(boolean outputPolarityEvents) {
        this.outputPolarityEvents = outputPolarityEvents;
    }
    
    public int getInhibitionOuterRadius() {
        return inhibitionOuterRadiusPX;
    }

    public void setInhibitionOuterRadius(final int inhibitionOuterRadius) {
        this.inhibitionOuterRadiusPX = inhibitionOuterRadius;
        resetFilter(); //need to recalculate the circles
    }

    public int getInhibitionInnerRadius() {
        return inhibitionInnerRadiusPX;
    }

    public void setInhibitionInnerRadius(final int inhibitionInnerRadius) {
        this.inhibitionInnerRadiusPX = inhibitionInnerRadius;
        resetFilter(); //need to recalculate the circles
    }

    public int getExcitationOuterRadius() {
        return excitationOuterRadiusPX;
    }

    public void setExcitationOuterRadius(final int excitationRadius) {
        this.excitationOuterRadiusPX = excitationRadius;
        resetFilter(); //need to recalculate the circles
    }
    
    public int getExcitationInnerRadius() {
        return excitationInnerRadiusPX;
    }

    public void setExcitationInnerRadius(final int excitationRadius) {
        int setValue = excitationRadius;
        if(excitationRadius <= 1) setValue = 1;
        this.excitationInnerRadiusPX = setValue;
        resetFilter(); //need to recalculate the circles
    }

    public boolean isShowRawInputEnabled() {
        return showRawInputEnabled;
    }

    public void setShowRawInputEnabled(final boolean showRawInputEnabled) {
        this.showRawInputEnabled = showRawInputEnabled;
    }
    
    public float getMaxDtMs() {
      return maxDtMs;
    }

    public void setMaxDtMs(float maxDtMs) {
      this.maxDtMs = maxDtMs;
    }

    public boolean isDrawInhibitExcitePoints() {
        return drawInhibitExcitePoints;
    }

    public void setDrawInhibitExcitePoints(boolean drawMotionVectors) {
        this.drawInhibitExcitePoints = drawMotionVectors;
    }
    
    public boolean isDrawCenterCell() {
        return drawCenterCell;
    }

    public void setDrawCenterCell(boolean drawCenterCell) {
        this.drawCenterCell = drawCenterCell;
    }
    
    public boolean isShowInhibitedEvents() {
        return showInhibitedEvents;
    }

    public void setShowInhibitedEvents(boolean showTotalInhibitedEvents) {
        this.showInhibitedEvents = showTotalInhibitedEvents;
    }

    public int getCircleCoarseness() {
        return circleCoarseness;
    }

    public void setCircleCoarseness(int circleCoarseness) {
        this.circleCoarseness = circleCoarseness;
        resetFilter(); //need to recalculate the circles
    }

    
}
