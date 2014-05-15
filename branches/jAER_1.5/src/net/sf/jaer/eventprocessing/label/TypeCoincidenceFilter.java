/*
 * TypeCoincidenceFilter.java
 *
 * Created on 27.1.2006 Tobi
 *
 */

package net.sf.jaer.eventprocessing.label;

import java.util.Observable;
import java.util.Observer;

import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OrientationEvent;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.eventprocessing.EventFilter2D;

/**
 * Computes coincidences betweeen different types of events at the same location in its input. Intended for e.g., a corner detector that works by
 *simulatanous vertical and horizontal edges.
 *
 * @author tobi
 */
@Description("Only lets through events spatio-temporally correlated complementary types (e.g. corners)")
public class TypeCoincidenceFilter extends EventFilter2D implements Observer {
   
   public boolean isGeneratingFilter(){ return true;}
    
    /** events must occur within this time along orientation in us to generate an event */
//    protected int maxDtThreshold=prefs.getInt("DvsOrientationFilter.maxDtThreshold",Integer.MAX_VALUE);
    private int minDtThreshold=getPrefs().getInt("TypeCoincidenceFilter.minDtThreshold",10000);
    {setPropertyTooltip("minDtThreshold","events must be this close in us to result in output");}
    
    private int subSampleBy=getPrefs().getInt("TypeCoincidenceFilter.subSampleBy", 0);
    {setPropertyTooltip("subSampleBy","subsample by this many bits before looking for type coincidence");}
    
    static final int MAX_DIST=5;
    private int dist=getPrefs().getInt("TypeCoincidenceFilter.dist",0);
    {setPropertyTooltip("dist","distance in pixels to search for coincident events");}
    
    static final int NUM_INPUT_CELL_TYPES=4;
    int[][][] lastTimesMap;
    
    /** the number of cell output types */
    public final int NUM_TYPES=4; // we make it big so rendering is in color
    
    /** Creates a new instance of TypeCoincidenceFilter */
    public TypeCoincidenceFilter(AEChip chip) {
        super(chip);
        chip.addObserver(this);
        resetFilter();
    }
    
    public Object getFilterState() {
        return lastTimesMap;
    }
    
    DvsOrientationFilter oriFilter;
    
    synchronized public void resetFilter() {
        allocateMap();
        if(oriFilter==null) oriFilter=new DvsOrientationFilter(chip);
        setEnclosedFilter(oriFilter);
    }
    
    static final int PADDING=MAX_DIST*2, P=MAX_DIST;
    
    void checkMap(){
        if(lastTimesMap==null) allocateMap();
    }
    
    private void allocateMap() {
        if(!isFilterEnabled()) return;
        lastTimesMap=new int[chip.getSizeX()+PADDING][chip.getSizeY()+PADDING][NUM_INPUT_CELL_TYPES];
    }
    
    int[][] dts=new int[4][2]; // delta times to neighbors in each direction
    int[] maxdts=new int[4]; // max times to neighbors in each dir
    
    public int getMinDtThreshold() {
        return this.minDtThreshold;
    }
    
    public void setMinDtThreshold(final int minDtThreshold) {
        this.minDtThreshold = minDtThreshold;
        getPrefs().putInt("TypeCoincidenceFilter.minDtThreshold", minDtThreshold);
    }
    
    public void initFilter() {
        resetFilter();
    }
    
    public void update(Observable o, Object arg) {
        initFilter();
    }
    
    EventPacket<ApsDvsOrientationEvent> oriPacket;
    
    synchronized public EventPacket filterPacket(EventPacket in) {
        if(in==null) return null;
        if(!filterEnabled) return in;
        if(in.getEventClass()!=PolarityEvent.class){
            log.warning("wrong input cell type "+in+", disabling filter");
            setFilterEnabled(false);
            return in;
        }
        oriPacket=(EventPacket<ApsDvsOrientationEvent>)(enclosedFilter.filterPacket(in));
        checkMap();
        checkOutputPacketEventType(in);
        int n=in.getSize();
        
        // for each orientation event that has been output from the orifilter
        // write out a PolarityEvent event from the orievent
        // iff there has been an orievent of 90 angle to this one in immediate neighborhood within past minDtThreshold
        OutputEventIterator outItr=out.outputIterator();
        for(Object o:oriPacket){
            ApsDvsOrientationEvent e=(ApsDvsOrientationEvent)o;  // the orievent
            // save time of event in lastTimesMap, subsampled by some number of bits in x and y
            int ex=e.x>>>subSampleBy, ey=e.y>>>subSampleBy;
            lastTimesMap[ex+P][ey+P][e.orientation]=e.timestamp;
            
            // compute orthogonal orientation
            int orthOri=(e.orientation+2)%4;
            breakOut:
            for(int x=-dist;x<=dist;x++){
                for(int y=-dist;y<=dist;y++){
                    // in neighborhood, compute dt between this event and prior events at orthog orientation
                    int dt=e.timestamp-lastTimesMap[ex+x+P][ey+y+P][orthOri];
                    // now write output cell if previous event within minDtThreshold
                    if( dt<minDtThreshold ){
                        PolarityEvent oe=(PolarityEvent)outItr.nextOutput();
                        oe.copyFrom((PolarityEvent)e);
                        break breakOut;
                    }
                }
            }
        }
        return out;
    }

    public int getDist() {
        return dist;
    }

    /** sets neighborhood distance */
    public void setDist(int dist) {
        if(dist>MAX_DIST) dist=MAX_DIST; else if(dist<0) dist=0;
        this.dist = dist;
        getPrefs().putInt("TypeCoincidenceFilter.dist",dist);
    }

    public int getSubSampleBy() {
        return subSampleBy;
    }

    public void setSubSampleBy(int subSampleBy) {
        this.subSampleBy = subSampleBy;
        getPrefs().putInt("TypeCoincidenceFilter.subSampleBy", subSampleBy);
    }
    
}
