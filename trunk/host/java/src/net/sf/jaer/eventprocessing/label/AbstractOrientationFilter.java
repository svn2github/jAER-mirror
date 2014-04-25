/*
 * DvsOrientationFilter.java
 *
 * Created on November 2, 2005, 8:24 PM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */
package net.sf.jaer.eventprocessing.label;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.VectorHistogram;
import java.awt.geom.Point2D;
import java.util.*;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;


/**Computes simple-type orientation-tuned cells.
 *A switch allows WTA mode (only max 1 event generated) or many event (any orientation that passes coincidence threshold.
 *Another switch allows contour enhancement by using previous output orientation events to make it easier to make events along the same orientation.
 *Another switch decides whether to use max delay or average delay as the coincidence measure.
 * <p>
 * Orientation type output takes values 0-3; 0 is a horizontal edge (0 deg),  1 is an edge tilted up and to right (rotated CCW 45 deg),
 * 2 is a vertical edge (rotated 90 deg), 3 is tilted up and to left (rotated 135 deg from horizontal edge).
 *
 * The filter takes either PolarityEvents or BinocularEvents to create ApsDvsOrientationEvents or BinocularApsDvsOrientationEvents.
 * @author tobi/phess */
@Description("Abstract superclass for labelers that detect local orientation by spatio-temporal correlation")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
abstract public class AbstractOrientationFilter extends EventFilter2D implements Observer , FrameAnnotater{

    public boolean isGeneratingFilter (){
        return true;
    }
    protected boolean showGlobalEnabled = getPrefs().getBoolean("showGlobalEnabled",false);
    /** events must occur within this time along orientation in us to generate an event */
    protected int minDtThreshold = getInt("minDtThreshold",100000);
    /** We reject delta times that are larger than minDtThreshold by this factor, to rule out very old events */
    protected int dtRejectMultiplier = getInt("dtRejectMultiplier",16);
    protected int dtRejectThreshold = minDtThreshold * dtRejectMultiplier;
    protected boolean multiOriOutputEnabled = getBoolean("multiOriOutputEnabled",false);
    /** set true to use min of average time to neighbors. Set false to use max time to neighbors (reduces # events) */
    protected boolean useAverageDtEnabled = getBoolean("useAverageDtEnabled",true);
    protected boolean contouringEnabled = getBoolean("contouringEnabled",false);
    protected boolean passAllEvents = getBoolean("passAllEvents",false);
    protected int subSampleShift = getInt("subSampleShift",0);
    protected final int SUBSAMPLING_SHIFT = 1;
    protected int length = getInt("searchDistance",3);
    protected int width = getInt("width",0);
    protected boolean oriHistoryEnabled = getBoolean("oriHistoryEnabled",false);
    protected boolean showVectorsEnabled = getBoolean("showVectorsEnabled",false);
    protected boolean showRawInputEnabled = getBoolean("showRawInputEnabled",false);
    protected float oriHistoryMixingFactor = getFloat("oriHistoryMixingFactor",0.1f);
    protected float oriDiffThreshold = getFloat("oriDiffThreshold",0.5f);
    protected boolean jitterVectorLocations=getBoolean("jitterVectorLocations", true);
    protected float jitterAmountPixels=getFloat("jitterAmountPixels",.5f);
    
    public static final int MAX_LENGTH = 6;
    /** the number of cell output types */
    public final int NUM_TYPES = 4;
    
    /** Times of most recent input events: [x][y][polarity] */
    protected int[][][] lastTimesMap; // x,y,polarity
    /** Scalar map of past orientation values: [x][y] */
    protected float[][] oriHistoryMap;  // scalar orientation value x,y
//    /** holds the times of the last output orientation events that have been generated */
//    int[][][][] lastOutputTimesMap;
    
    protected int rfSize;
    
    /** Historical orientation values. */
    protected VectorHistogram oriHist = new VectorHistogram(NUM_TYPES);
    /** Delta times to neighbors in each direction. */
    protected int[][] dts = null; // new int[NUM_TYPES][length*2+1]; // delta times to neighbors in each direction
    /** Max times to neighbors in each dir. */
    protected int[] maxdts = new int[ NUM_TYPES ]; // max times to neighbors in each dir
    // takes about 350ns/event on tobi's t43p laptop at max performance (2.1GHz Pentium M, 1GB RAM)
    /** A vector direction object used for iterating over neighborhood. */
    protected final class Dir{
        int x, y;

        Dir (int x,int y){
            this.x = x;
            this.y = y;
        }

        @Override
        public String toString (){
            return String.format("%d,%d",x,y);
        }
    }
    /** 
     * Offsets from a pixel to pixels forming the receptive field (RF) for an orientation response.
     * They are computed whenever the RF size changes.
     * First index is orientation 0-NUM_TYPES, second is index over offsets. */
    protected Dir[][] offsets = null;
    /** The basic offsets for each orientation.
     * You getString the perpendicular orientation to i by indexing (i+2)%NUM_TYPES. */
    protected final Dir[] baseOffsets = {
        new Dir(1,0), // right
        new Dir(1,1), // 45 up right
        new Dir(0,1), // up
        new Dir(-1,1), // up left
    };

    /** Creates a new instance of SimpleOrientationFilter */
    public AbstractOrientationFilter (AEChip chip){
        super(chip);
        chip.addObserver(this);
        // properties, tips and groups
        final String size = "Size", tim = "Timing", disp = "Display";

        setPropertyTooltip(disp,"showGlobalEnabled","shows line of average orientation");
        setPropertyTooltip(disp,"showVectorsEnabled","shows local orientation segments");
        setPropertyTooltip(disp,"jitterAmountPixels","how much to jitter vector origins by in pixels");
        setPropertyTooltip(disp,"jitterVectorLocations","whether to jitter vector location to see overlapping vectors more easily");
        setPropertyTooltip(disp,"passAllEvents","Passes all events, even those that do not get labled with orientation");
        setPropertyTooltip(disp,"showRawInputEnabled","shows the input events, instead of the direction types");
        setPropertyTooltip(size,"subSampleShift","Shift subsampled timestamp map stores by this many bits");
        setPropertyTooltip(size,"width","width of RF, total is 2*width+1");
        setPropertyTooltip(size,"length","length of half of RF, total length is length*2+1");
        setPropertyTooltip(tim,"minDtThreshold","Coincidence time, events that pass this coincidence test are considerd for orientation output");
        setPropertyTooltip(tim,"dtRejectMultiplier","<html>reject delta times more than this factor times <em>minDtThreshold</em> to reduce noise");
        setPropertyTooltip(tim,"dtRejectThreshold","reject delta times more than this time in us to reduce effect of very old events");
        setPropertyTooltip(tim,"useAverageDtEnabled","Use averarge delta time instead of minimum");
        setPropertyTooltip(tim,"oriHistoryEnabled","enable use of prior orientation values to filter out events not consistent with history");
        setPropertyTooltip(tim,"oriHistoryMixingFactor","mixing factor for history of local orientation, increase to learn new orientations more quickly");
        setPropertyTooltip(tim,"oriDiffThreshold","orientation must be within this value of historical value to pass");
        setPropertyTooltip("multiOriOutputEnabled","Enables multiple event output for all events that pass test");
    }
     
    public Object getFilterState (){
        return lastTimesMap;
    }

    @Override
    synchronized public void resetFilter (){
        if ( !isFilterEnabled() ){
            return;
        }
//        allocateMaps(); // will allocate even if filter is enclosed and enclosing is not enabled
        oriHist.reset();
        if ( lastTimesMap != null ){
            for ( int i = 0 ; i < lastTimesMap.length ; i++ ){
                for ( int j = 0 ; j < lastTimesMap[i].length ; j++ ){
                    Arrays.fill(lastTimesMap[i][j],0);
                }
            }
        }
        if ( oriHistoryMap != null ){
            for ( int i = 0 ; i < oriHistoryMap.length ; i++ ){
                Arrays.fill(oriHistoryMap[i],0f);
            }
        }
    }

    /** overrides super method to allocate or free local memory */
    @Override
    synchronized public void setFilterEnabled (boolean yes){
        super.setFilterEnabled(yes);
        if ( yes ){
            resetFilter();
        } else{
            lastTimesMap = null;
            oriHistoryMap=null;
//            lastOutputTimesMap=null;
        }
    }

    protected void checkMaps (EventPacket packet){
        if ( lastTimesMap == null || lastTimesMap.length != chip.getSizeX() || lastTimesMap[0].length != chip.getSizeY() || lastTimesMap[0][0].length != 2 ){ // changed to 2 for PolarityEvents
            allocateMaps();
        }
    }

    synchronized protected void allocateMaps (){
        if ( !isFilterEnabled() ){
            return;
        }
        if ( chip != null ){
            lastTimesMap = new int[ chip.getSizeX() ][ chip.getSizeY() ][ 2 ]; // fixed to 2 for PolarityEvents
            oriHistoryMap = new float[ chip.getSizeX() ][ chip.getSizeY() ];
            //lastOutputTimesMap=new int[chip.getSizeX()][chip.getSizeY()][NUM_TYPES][2];
            log.info(String.format("allocated int[%d][%d][%d] array for last event times and float[%d][%d] array for orientation history",chip.getSizeX(),chip.getSizeY(),2,chip.getSizeX(),chip.getSizeY()));

        }
        computeRFOffsets();
    }

    /** @return the average orientation vector based on counts. A unit vector pointing along each orientation
     * is multiplied by the count of local orientation events of that orientation. The vector sum of these weighted unit
     * vectors is returned.
     * The angle theta increases CCW and starts along x axis: 0 degrees is along x axis, 90 deg is up along y axis.
     * This resulting vector can be rendered by duplicating it pointing in the opposite direction to show a "global" orientation.
     * The total length then represents the number and dominance of a particular type of orientation event. */
    Point2D.Float computeGlobalOriVector (){
        final float scale = .1f;
        java.awt.geom.Point2D.Float p = new Point2D.Float();
        int[] counts = oriHist.getCounts();
        for ( int i = 0 ; i < NUM_TYPES ; i++ ){
            double theta = ( Math.PI * (double)i / NUM_TYPES ); // theta starts vertical up, type 0 is for vertical ori -Math.PI/2
            float wx = (float)Math.cos(theta);
            float wy = (float)Math.sin(theta);
            p.x += counts[i] * wx; // multiply unit vector by count of ori events
            p.y += counts[i] * wy;
        }
        p.x *= scale;
        p.y *= scale;
        return p;
    }

    /** precomputes offsets for iterating over neighborhoods */
    protected void computeRFOffsets (){
        // compute array of Dir for each orientation
        rfSize = 2 * length * ( 2 * width + 1 );
        offsets = new Dir[ NUM_TYPES ][ rfSize ];
        for ( int ori = 0 ; ori < NUM_TYPES ; ori++ ){
            Dir d = baseOffsets[ori];
            int ind = 0;
            for ( int s = -length ; s <= length ; s++ ){
                if ( s == 0 ){
                    continue;
                }
                Dir pd = baseOffsets[( ori + 2 ) % NUM_TYPES]; // this is offset in perpindicular direction
                for ( int w = -width ; w <= width ; w++ ){
                    // for each line of RF
                    offsets[ori][ind++] = new Dir(s * d.x + w * pd.x,s * d.y + w * pd.y);
                }
            }
        }
        dts = new int[ NUM_TYPES ][ rfSize ]; // delta times to neighbors in each direction
    }

    @Override
    public void initFilter (){
        resetFilter();
    }

    @Override
    public void update (Observable o,Object arg){
        initFilter();
    }

    public int getLength (){
        return length;
    }

    /** @param searchDistance the length of the RF, actual length is twice this because we search on each side of pixel by length*/
    synchronized public void setLength (int searchDistance){
        if ( searchDistance > MAX_LENGTH ){
            searchDistance = MAX_LENGTH;
        } else if ( searchDistance < 1 ){
            searchDistance = 1; // limit size
        }
        this.length = searchDistance;
        allocateMaps();
        putInt("searchDistance",searchDistance);
    }

    public int getWidth (){
        return width;
    }

    /** @param width the width of the RF, 0 for a single line of pixels, 1 for 3 lines, etc */
    synchronized public void setWidth (int width){
        if ( width < 0 ){
            width = 0;
        }
        if ( width > length - 1 ){
            width = length - 1;
        }
        this.width = width;
        allocateMaps();
        putInt("width",width);
    }

    @Override
    public void annotate (GLAutoDrawable drawable){
        if ( !isAnnotationEnabled() ){
            return;
        }
        GL gl = drawable.getGL();

        if ( isShowGlobalEnabled() ){
            if ( gl == null ){
                return;
            }
            gl.glPushMatrix();
            gl.glTranslatef(chip.getSizeX() / 2,chip.getSizeY() / 2,0);
            gl.glLineWidth(6f);
            Point2D.Float p = computeGlobalOriVector();
            gl.glBegin(GL.GL_LINES);
            gl.glColor3f(1,1,1);
            gl.glVertex2f(-p.x,-p.y);
            gl.glVertex2f(p.x,p.y);
            gl.glEnd();
            gl.glPopMatrix();
        }
        if ( isShowVectorsEnabled() && getOutputPacket()!=null ){
            // draw individual orientation vectors
            gl.glPushMatrix();
             EventPacket outputPacket=getOutputPacket();
             for ( Object o:outputPacket ){
                OrientationEventInterface e = (OrientationEventInterface)o;
                drawOrientationVector(gl,e);
            }
             gl.glPopMatrix();
        }
    }
    protected Random r=new Random();
    
    // plots a single motion vector which is the number of pixels per second times scaling
    protected void drawOrientationVector (GL gl,OrientationEventInterface e){
        if ( !e.isHasOrientation() ){
            return;
        }
        byte ori=e.getOrientation();
        OrientationEvent.UnitVector d = OrientationEvent.unitVectors[ori];
        float jx=0, jy=0;
        if(jitterVectorLocations){
            jx=(r.nextFloat()-.5f)*jitterAmountPixels;
            jy=(r.nextFloat()-.5f)*jitterAmountPixels;
        }
            gl.glLineWidth(3f);
            float[] c=chip.getRenderer().makeTypeColors(e.getNumCellTypes())[ori];
            gl.glColor3fv(c,0);
//        switch (ori) {
//            case 0:
//                gl.glColor3fv(c,0);
//                break;
//            case 1:
//                gl.glColor3f(1, 1, 0);
//                break;
//            case 2:
//                gl.glColor3f(0, 1, 0);
//                break;
//            case 3:
//                gl.glColor3f(0, 1, 1);
//        }
          gl.glBegin(GL.GL_LINES);
          BasicEvent be=(BasicEvent)e;
        gl.glVertex2f(be.x - d.x * length + jx, be.y - d.y * length + jy);
        gl.glVertex2f(be.x + d.x * length + jx, be.y + d.y * length+jy);
           gl.glEnd();
    }

    /**Abstract method that filters in to out packet. 
     * If filtering is enabled, the number of getOutputPacket() may be less
     * than the number in
     * @param in input events can be null or empty.
     * @return the processed events, may be fewer in number. */
    @Override
    abstract  public EventPacket<?> filterPacket (EventPacket<?> in);
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --MinDtThreshold--">
    public int getMinDtThreshold (){
        return this.minDtThreshold;
    }

    public void setMinDtThreshold (final int minDtThreshold){
        this.minDtThreshold = minDtThreshold;
        putInt("minDtThreshold",minDtThreshold);
        dtRejectThreshold = minDtThreshold * dtRejectMultiplier;
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --UseAverageDtEnabled--">
    public boolean isUseAverageDtEnabled (){
        return useAverageDtEnabled;
    }

    public void setUseAverageDtEnabled (boolean useAverageDtEnabled){
        this.useAverageDtEnabled = useAverageDtEnabled;
        putBoolean("useAverageDtEnabled",useAverageDtEnabled);
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --MultiOriOutputEnabled--">
    synchronized public boolean isMultiOriOutputEnabled (){
        return multiOriOutputEnabled;
    }

    synchronized public void setMultiOriOutputEnabled (boolean multiOriOutputEnabled){
        this.multiOriOutputEnabled = multiOriOutputEnabled;
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --PassAllEvents--">
    public boolean isPassAllEvents (){
        return passAllEvents;
    }

    /** Set this to true to pass all events even if they don't satisfy the 
     * orientation test. These passed events have no orientation set.
     * @param passAllEvents true to pass all events, false to pass only events 
     * that pass coincidence test. */
    public void setPassAllEvents (boolean passAllEvents){
        this.passAllEvents = passAllEvents;
        putBoolean("passAllEvents",passAllEvents);
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --SubSampleShift--">
    public int getSubSampleShift (){
        return subSampleShift;
    }

    /** Sets the number of spatial bits to subsample events times by. 
     * Setting this equal to 1, for example, subsamples into an event time map 
     * with halved spatial resolution, aggregating over more space at coarser 
     * resolution but increasing the search range by a factor of two at no additional cost.
     * @param subSampleShift the number of bits, 0 means no subsampling */
    public void setSubSampleShift (int subSampleShift){
        if ( subSampleShift < 0 ){
            subSampleShift = 0;
        } else if ( subSampleShift > 4 ){
            subSampleShift = 4;
        }
        this.subSampleShift = subSampleShift;
        putInt("subSampleShift",subSampleShift);
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --DtRejectMultiplier--">
    public int getDtRejectMultiplier (){
        return dtRejectMultiplier;
    }

    public void setDtRejectMultiplier (int dtRejectMultiplier){
        if ( dtRejectMultiplier < 2 ){
            dtRejectMultiplier = 2;
        } else if ( dtRejectMultiplier > 128 ){
            dtRejectMultiplier = 128;
        }
        this.dtRejectMultiplier = dtRejectMultiplier;
        dtRejectThreshold = minDtThreshold * dtRejectMultiplier;
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --OriHist--">
    public VectorHistogram getOriHist (){
        return oriHist;
    }

    public void setOriHist (VectorHistogram oriHist){
        this.oriHist = oriHist;
    }
    // </editor-fold>
 
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --OriHistoryMixingFactor--">
    public float getOriHistoryMixingFactor (){
        return oriHistoryMixingFactor;
    }

    public void setOriHistoryMixingFactor (float oriHistoryMixingFactor){
        if ( oriHistoryMixingFactor > 1 ){
            oriHistoryMixingFactor = 1;
        } else if ( oriHistoryMixingFactor < 0 ){
            oriHistoryMixingFactor = 0;
        }
        this.oriHistoryMixingFactor = oriHistoryMixingFactor;
        putFloat("oriHistoryMixingFactor",oriHistoryMixingFactor);
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --OriHistoryEnabled--">
    public boolean isOriHistoryEnabled (){
        return oriHistoryEnabled;
    }

    public void setOriHistoryEnabled (boolean oriHistoryEnabled){
        this.oriHistoryEnabled = oriHistoryEnabled;
        putBoolean("oriHistoryEnabled",oriHistoryEnabled);
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --OriDiffThreshold--">
    public float getOriDiffThreshold (){
        return oriDiffThreshold;
    }

    public void setOriDiffThreshold (float oriDiffThreshold){
        if ( oriDiffThreshold > NUM_TYPES ){
            oriDiffThreshold = NUM_TYPES;
        }
        this.oriDiffThreshold = oriDiffThreshold;
        putFloat("oriDiffThreshold",oriDiffThreshold);
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --JitterVectorLocations--">
    /**
     * @return the jitterVectorLocations
     */
    public boolean isJitterVectorLocations() {
        return jitterVectorLocations;
    }

    /**
     * @param jitterVectorLocations the jitterVectorLocations to set
     */
    public void setJitterVectorLocations(boolean jitterVectorLocations) {
        this.jitterVectorLocations = jitterVectorLocations;
        putBoolean("jitterVectorLocations", jitterVectorLocations);
        getChip().getAeViewer().interruptViewloop();
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --JitterAmountPixels--">
    /**
     * @return the jitterAmountPixels
     */
    public float getJitterAmountPixels() {
        return jitterAmountPixels;
    }

    /**
     * @param jitterAmountPixels the jitterAmountPixels to set
     */
    public void setJitterAmountPixels(float jitterAmountPixels) {
        this.jitterAmountPixels = jitterAmountPixels;
        putFloat("jitterAmountPixels",jitterAmountPixels);
        getChip().getAeViewer().interruptViewloop();
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --ShowRawInputEnable--">
    public boolean isShowRawInputEnabled() {
        return showRawInputEnabled;
    }
    
    public void setShowRawInputEnabled(boolean showRawInputEnabled) {
        this.showRawInputEnabled = showRawInputEnabled;
        putBoolean("showRawInputEnabled",showRawInputEnabled);
    }
    // </editor-fold>
    
    // <editor-fold defaultstate="collapsed" desc="getter/setter for --ShowVectorsEnabled--">
    public boolean isShowVectorsEnabled (){
        return showVectorsEnabled;
    }

    public void setShowVectorsEnabled (boolean showVectorsEnabled){
        this.showVectorsEnabled = showVectorsEnabled;
        putBoolean("showVectorsEnabled",showVectorsEnabled);
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="getter/setter for --ShowGlobalEnabled--">
    public boolean isShowGlobalEnabled (){
        return showGlobalEnabled;
    }

    public void setShowGlobalEnabled (boolean showGlobalEnabled){
        this.showGlobalEnabled = showGlobalEnabled;
        putBoolean("showGlobalEnabled",showGlobalEnabled);
    }
    // </editor-fold>
}
