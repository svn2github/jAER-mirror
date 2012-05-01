
package uk.ac.imperial.vsbe;

import net.sf.jaer.chip.Chip;
import net.sf.jaer.biasgen.Biasgen;
import net.sf.jaer.biasgen.BiasgenPreferences;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import javax.swing.JPanel;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/**
 * Generic Biasgen Class for Cameras
 * Incorporates BiasgenPreferences to load and save
 * @author mlk
 */
public class CameraBiasgen<C extends Chip & BiasgenPreferences & 
        BiasgenHardwareInterface> extends Biasgen {
    // constructor used to ensure only PSEye chip used
    public CameraBiasgen(C chip) {
        super(chip);
        // remove master bias as not used - HACK
        setMasterbias(null);
    }
    
    // ensure chip being set is a PSEyeModelAEChip
    @Override
    public void setChip(Chip chip) {
        if (chip instanceof BiasgenPreferences && 
                chip instanceof BiasgenHardwareInterface) 
            super.setChip(chip);
        else
            super.setChip(null);
    }
    
    /* Returns PSEyeModelAEChip associated with this biasgen.
     */
    @Override
    public C getChip() {
        return (C) super.getChip();
    }

    /* 
     * Almost verbatim copy from base class due
     * to need to override "new BiagenPanel"
     */
    @Override
    public JPanel buildControlPanel() {
        startBatchEdit();
        JPanel panel = null;
        
        panel = new CameraBiasgenPanel(this);
        try {
            endBatchEdit();
        } catch (HardwareInterfaceException e) {
            log.warning(e.toString());
        }
        return panel;
    }
    
    /* Loads preferences (preferred values) for the chip
     */
    @Override
    public void loadPreferences() {
        startBatchEdit();
        getChip().loadPreferences();
        try {
            endBatchEdit();
        } catch (HardwareInterfaceException e) {
            log.warning(e.toString());
        }
    }
    
    @Override
    public boolean isOpen() {
        if (getChip().getHardwareInterface() == null) {
            return false;
        }
        return getChip().getHardwareInterface().isOpen();
    }    
    
    @Override
    public void sendConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        if (!isBatchEditOccurring()) {
            getChip().sendConfiguration(biasgen);
        }
    }    
    
    @Override
    public void storePreferences() {
        log.info("storing preferences to preferences tree");
        getChip().storePreferences();
    }    
    
    @Override
    public void suspend() {}

    @Override
    public void resume() {}
    
    @Override
    public void flashConfiguration(Biasgen biasgen) throws HardwareInterfaceException {}
}
