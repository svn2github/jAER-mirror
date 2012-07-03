
package uk.ac.imperial.vsbe;

import net.sf.jaer.chip.Chip;
import net.sf.jaer.biasgen.Biasgen;
import net.sf.jaer.biasgen.PotArray;
import net.sf.jaer.biasgen.Pot;
import net.sf.jaer.biasgen.IPotGroup;
import net.sf.jaer.biasgen.Masterbias;
import java.util.Observable;
import java.util.ArrayList;
import java.util.prefs.InvalidPreferencesFormatException;
import javax.swing.JPanel;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import net.sf.jaer.graphics.AEViewer;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/**
 * Generic Biasgen Class for Cameras
 * Incorporates BiasgenPreferences to load and save
 * 
 * BiasgenFrame uses:
 *  isOpen, open, close, sendConfiguration, importPreferences, exportPreferences,
 *  suspend, resume, flashConfiguration, loadPreferences, storePreferences,
 *  buildControlPanel
 * 
 * @author mlk
 */
public class CameraChipBiasgen<C extends Chip & CameraChipBiasInterface> extends Biasgen {
    // constructor used to ensure only PSEye chip used
    public CameraChipBiasgen(C chip) {
        super(chip);
        // remove master bias as not used - HACK
        masterbias.deleteObserver(this);
        masterbias = null;
    }
    
    // ensure chip being set is a PSEyeModelAEChip
    @Override
    public void setChip(Chip chip) {
        if (chip instanceof CameraChipBiasInterface) 
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
        
        panel = new CameraChipBiasgenPanel(this);
        
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
        //getChip().loadPreferences();
        try {
            endBatchEdit();
        } catch (HardwareInterfaceException e) {
            log.warning(e.toString());
        }
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
    public void suspend() {
        return;
    }

    @Override
    public void resume() {
        return;
    }
    
    @Override
    public void flashConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        getChip().storePreferences();
        sendConfiguration(biasgen);
    }
    
    /*
     * Biasgen methods used but forwarded to super for safety
     */
    
    @Override
    public void exportPreferences(java.io.OutputStream os) throws java.io.IOException {
        super.exportPreferences(os);
    }
    
    @Override
    public void importPreferences(java.io.InputStream is) throws java.io.IOException, InvalidPreferencesFormatException, HardwareInterfaceException {
        super.importPreferences(is);
    }
    
    @Override
    public void setMasterbias(final Masterbias masterbias) {
        super.setMasterbias(masterbias);
    }
    
    @Override
    public void startBatchEdit() {
        super.startBatchEdit();
    }

    @Override
    public void endBatchEdit() throws HardwareInterfaceException {
        super.endBatchEdit();
    }
    
    @Override
    public boolean isOpen() {
        return super.isOpen();
    }  

    @Override
    public void open() throws HardwareInterfaceException {
        super.open();
    }
    
    @Override
    public void close() {
        super.close();
    }
    
    @Override
    public void setHardwareInterface(final BiasgenHardwareInterface hardwareInterface) {
        super.setHardwareInterface(hardwareInterface);
    }
    
    @Override
    public void setBatchEditOccurring(boolean batchEditOccurring) {
        super.setBatchEditOccurring(batchEditOccurring);
    }
    
    @Override
    public boolean isBatchEditOccurring() {
        return super.isBatchEditOccurring();
    }
    
    /*
     * Biasgen methods not used, overriden for safety
     */
    @Override 
    public JPanel getControlPanel() {
        throw new UnsupportedOperationException("Not supported yet.");
    }


    @Override
    public void setControlPanel(JPanel panel) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public PotArray getPotArray() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setPotArray(final PotArray PotArray) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Masterbias getMasterbias() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String getName() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setName(final String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void putPref(String key, String value) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void putPref(String key, boolean value) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void putPref(String key, int value) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void putPref(String key, float value) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void putPref(String key, double value) {
      throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String toString() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void update(Observable observable, Object object) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Pot getPotByName(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Pot getPotByNumber(int number) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public BiasgenHardwareInterface getHardwareInterface() {
       throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getNumPots() {
        throw new UnsupportedOperationException("Not supported yet.");
    }
    
    @Override
    public byte[] formatConfigurationBytes(Biasgen biasgen) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setPowerDown(boolean powerDown) throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String getTypeName() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public ArrayList<IPotGroup> getIPotGroups() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setIPotGroups(ArrayList<IPotGroup> iPotGroups) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean isInitialized() {
        throw new UnsupportedOperationException("Not supported yet.");
    }
   
    @Override
    public void showUnitializedBiasesWarningDialog(final AEViewer container) {
        throw new UnsupportedOperationException("Not supported yet.");
    }    
}
