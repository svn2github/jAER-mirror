/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package uk.ac.imperial.vsbe;

import net.sf.jaer.biasgen.BiasgenPreferences;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import javax.swing.JPanel;
import java.util.logging.Logger;
/**
 *
 * @author mlk11
 */
public interface CameraChipBiasInterface extends BiasgenPreferences, BiasgenHardwareInterface {
    
    abstract JPanel getChipPanel();
    abstract JPanel getCameraPanel();
    
    abstract void notifyChip();
    abstract Logger getLog();
    
}
