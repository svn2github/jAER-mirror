/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.seebetter.ini.retinamodel;

import java.util.Iterator;
import java.util.Observable;
import java.util.Observer;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.event.PolarityEvent.Polarity;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.filter.SubSampler;
import net.sf.jaer.graphics.FrameAnnotater;

/**
 * Models a single approach cell discovered by Botond Roska group in Basel.
 * This cell responds to approaching (expanding, but not translating) dark objects, such
 * as perhaps a hungry bird diving on the mouse.
 * 
 * From Botond: The important point is NO delay.

        Small subunits, that make OFF excitation and ON inhibition input to the approach cell.
        * 
        Importantly both subunits have an expansive nonlinearity such that the ON subunit does not respond when there 
       is a darkening input signal and its response increases nonlinearly with contrast. 
        (you can implement as nonlinearity that has two segments, zero up to a positive number and then 
       linear or below zero it is zero and above zero some exponential.
       * Same nonlinearity for OFF subunits.

        Ganglion cell is much larger than the subunits and sums them together.

        This way when there is lateral motion the ON inhibition and OFF excitation 
        sums together to zero response (because of the lack of delay) but when 
        there is approach motion  of a black object then there is only excitation.

        The importance of the nonlinearity is that this way the system will 
        respond when there is an approaching object. 
* 
 * @author tobi
 */
@Description("Models approach cell discovered by Botond Roska group")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class ApproachCell extends EventFilter2D implements FrameAnnotater, Observer{

    private boolean showSubunits=getBoolean("showSubunits", true);
    private boolean showApproachCell=getBoolean("showApproachCell", true);
    private int subunitSubsamplingBits=getInt("subunitSubsamplingBits",4);
    
    private SubSampler subSampler=new SubSampler(chip);
    
    private Subunits onSubunits, offSubunits;
    
    public ApproachCell(AEChip chip) {
        super(chip);
        chip.addObserver(this);
        setPropertyTooltip("showSubunits", "Enables showing subunit activity annotation over retina output");
        setPropertyTooltip("showApproachCell", "Enables showing approach cell activity annotation over retina output");
        setPropertyTooltip("subunitSubsamplingBits", "Each subunit integrates events from 2^n by 2^n pixels, where n=subunitSubsamplingBits.");
        
    }

    
    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        if(!(in.getEventPrototype() instanceof PolarityEvent)) return in;
        for(Object o:in){
            PolarityEvent e=(PolarityEvent)o;
            offSubunits.update(e);
            onSubunits.update(e);
        }
        return in;
    }

    @Override
    public void resetFilter() {
    }

    @Override
    public void initFilter() {
        onSubunits=new Subunits(SubunitType.On);
        offSubunits=new Subunits(SubunitType.Off);
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
    }

    @Override
    public void update(Observable o, Object arg) {
        if (arg != null && (arg == AEChip.EVENT_SIZEX || arg == AEChip.EVENT_SIZEY) && chip.getNumPixels()>0) {
            initFilter();
        }
    }

     private  enum SubunitType {Off, On};
       
     private class Subunits {

        float[][] activity;
        SubunitType type;
        int[][] lastUpdateTimestamp;
        
        public Subunits(SubunitType type) {
            this.type=type;
            activity=new float[(chip.getSizeX()>>subunitSubsamplingBits)+1][(chip.getSizeY()>>subunitSubsamplingBits)+1];
           lastUpdateTimestamp=new int[(chip.getSizeX()>>subunitSubsamplingBits)+1][(chip.getSizeY()>>subunitSubsamplingBits)+1];
        }
        
        public void update(PolarityEvent e){
            // subsample retina address to clump retina input pixel blocks.
            int x=e.x>>subunitSubsamplingBits, y=e.y>>subunitSubsamplingBits;
            // excite with 
            activity[x][y]=activity[x][y]+(e.polarity==Polarity.Off?-1:+1);
        }
    }
    
}
