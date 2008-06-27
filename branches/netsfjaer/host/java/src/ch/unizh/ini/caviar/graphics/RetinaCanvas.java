/*
 * RetinaCanvas.java
 *
 * Created on January 9, 2006, 6:50 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package ch.unizh.ini.caviar.graphics;

//import ch.unizh.ini.caviar.aemonitor.EventXYType;
import ch.unizh.ini.caviar.chip.*;

/**
 * A subclass of ChipCanvas just for retinas. At present this is just a 'marker' class.
 * @author tobi
 */
public class RetinaCanvas extends ChipCanvas {
    
    
    /** Creates a new instance of RetinaCanvas
     * @param chip the chip that we are rendering; everything is available from this object
     */
    public RetinaCanvas(AEChip chip) {
        super(chip);
    }
    
    
}
