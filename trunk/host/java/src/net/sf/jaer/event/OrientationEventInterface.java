/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package net.sf.jaer.event;

/**
 * Common interface for all events signaling an orientation
 * @author tobi
 */
public interface OrientationEventInterface extends PolarityEventInterface{
    
    
    public byte getOrientation();
    public void setOrientation(byte orientation);
    public boolean isHasOrientation();
    public void setHasOrientation(boolean yes);
    
        /** represents a unit orientation.
     The x and y fields represent relative offsets in the x and y directions by these amounts. */
    public static final class UnitVector{
        public float x, y;
        UnitVector(float x, float y){
            float l=(float)Math.sqrt(x*x+y*y);
            x=x/l;
            y=y/l;
            this.x=x;
            this.y=y;
        }
    }
    
    /**
     *     An array of 4 nearest-neighbor unit vectors going CCW from horizontal.
     *     <p>
     *    these unitDirs are indexed by inputType, then by (inputType+4)%4 (opposite direction)
     *    when input type is orientation, then input type 0 is 0 deg horiz edge, so first index could be to down, second to up
     *    so list should start with down
     */
    public static final UnitVector[] unitVectors={
        new UnitVector(1,0), 
        new UnitVector(1,1), 
        new UnitVector(0,1), 
        new UnitVector(-1,1), 
    };
    
}
