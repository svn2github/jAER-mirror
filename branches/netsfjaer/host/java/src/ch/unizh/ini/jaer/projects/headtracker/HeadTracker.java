/*
 * HeadTracker.java
 *
 * Created on October 19, 2007, 10:50 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package ch.unizh.ini.jaer.projects.headtracker;

import sf.net.jaer.chip.AEChip;
import sf.net.jaer.event.EventPacket;
import sf.net.jaer.eventprocessing.EventFilter2D;
import sf.net.jaer.eventprocessing.FilterChain;
import sf.net.jaer.eventprocessing.tracking.RectangularClusterTracker;
import sf.net.jaer.graphics.FrameAnnotater;
import java.awt.Graphics2D;
import javax.media.opengl.GLAutoDrawable;

/**
 * Tracks head and applies active appearance models to extract face parameters.
 *<p>
 *
 * @author alex tureczek
 */
public class HeadTracker extends EventFilter2D implements FrameAnnotater{
    
    RectangularClusterTracker rectangularClusterTracker;
    
    private float headSize=getPrefs().getFloat("HeadTracker.headSize",.1f);
    
    /** Creates a new instance of HeadTracker */
    public HeadTracker(AEChip chip) {
        super(chip);
        rectangularClusterTracker=new RectangularClusterTracker(chip);
        rectangularClusterTracker.setClusterSize(headSize);
        FilterChain chain=new FilterChain(chip);
        setEnclosedFilterChain(chain);
        getEnclosedFilterChain().add(rectangularClusterTracker);
    }

    public EventPacket<?> filterPacket(EventPacket<?> in) {
        if(!isFilterEnabled()) return in;
        rectangularClusterTracker.filterPacket(in);
        return in;
    }


    public void resetFilter() {
    }

    public void initFilter() {
    }

    public Object getFilterState() {
        return null;
    }

    public void annotate(float[][][] frame) {
    }

    public void annotate(Graphics2D g) {
    }

    public void annotate(GLAutoDrawable drawable) {
    }

    public float getHeadSize() {
        return headSize;
    }

    public void setHeadSize(float headSize) {
        this.headSize = headSize;
        getPrefs().putFloat("HeadTracker.headSize",headSize);
        rectangularClusterTracker.setClusterSize(headSize);
    }
    
}
