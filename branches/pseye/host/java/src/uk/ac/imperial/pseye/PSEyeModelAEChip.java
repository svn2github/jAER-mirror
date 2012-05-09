
package uk.ac.imperial.pseye;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Observable;
import java.util.logging.Logger;
import java.util.prefs.InvalidPreferencesFormatException;
import javax.swing.JPanel;
import net.sf.jaer.biasgen.Biasgen;
import uk.ac.imperial.vsbe.CameraChipBiasgen;
import uk.ac.imperial.vsbe.CameraAEHardwareInterface;
import uk.ac.imperial.vsbe.CameraChipInterface;
import net.sf.jaer.chip.AEChip;
import java.util.prefs.PreferenceChangeEvent;
import java.util.prefs.PreferenceChangeListener;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import java.io.File;
import java.io.IOException;
import net.sf.jaer.eventio.AEFileInputStream;

/**
 * A private base class for the behavioural model of several AE retina models 
 * using the PS3-Eye camera.
 * Unlike the rest of jAER all hardware control should be done through
 * the chip's control panels as this handles setting validation and preferences (for 
 * camera and chip).
 * 
 * @author Tobi Delbruck and Mat Katz
 */
public class PSEyeModelAEChip extends AEChip implements PreferenceChangeListener, 
        PSEyeDriverInterface, CameraChipInterface {
    PSEyeModelRenderer renderer = null;
    PSEyeCameraHardware camera = null;
    
    @Override
    public void preferenceChange(PreferenceChangeEvent evt) {
        getBiasgen().loadPreferences();
    }

    public PSEyeModelAEChip() {
        setEventExtractor(createEventExtractor());
        loadPreferences();
        
        setBiasgen(new CameraChipBiasgen<PSEyeModelAEChip>(this));
        setRenderer((renderer = new PSEyeModelRenderer(this)));
        
        getPrefs().addPreferenceChangeListener(this);
        //camera = new PSEyeDriverChipComponent<PSEyeModelAEChip>(this);
    }

    /* needed to ensure listener deregistered on construction of
     * an equivalent instance and so prevent a memory leak 
     */
    @Override
    public void cleanup() {
        super.cleanup();
        getPrefs().removePreferenceChangeListener(this);
    }
    
    @Override
    public void loadPreferences() {
        try {
            camera.loadPreferences();    
        } catch (Exception ex) {
            log.warning(ex.toString());
        }
        
        if (getEventExtractor() != null && (getEventExtractor() instanceof PSEyeEventExtractor))
            ((PSEyeEventExtractor) getEventExtractor()).loadPreferences(getPrefs());
    }

    @Override
    public void storePreferences() {
        // use getter functions to store parameters
        camera.storePreferences();
        if (getEventExtractor() != null && (getEventExtractor() instanceof PSEyeEventExtractor))
            ((PSEyeEventExtractor) getEventExtractor()).storePreferences(getPrefs());
    }

    /* load all hardware parameters from chip 
     * cannot use chip setters due to notify and setChange
     * which should not fire unless chip changed, camera
     * notifiers will fire though - used by raw panel.
     * Assumes hardware interface not already open (otherwise get multiple resets).
     */
    @Override
    public void setHardwareInterface(HardwareInterface hardwareInterface) {
        if (hardwareInterface != null && (hardwareInterface instanceof CameraAEHardwareInterface)) { 
            super.setHardwareInterface(hardwareInterface);
            PSEyeCameraHardware pseye = (PSEyeCameraHardware) getHardwareInterface();
            try {
                camera.setCamera(pseye);
            } catch (Exception ex) {
                log.warning(ex.toString());
            }
        }
        else if (hardwareInterface == null) {
            camera.setCamera(null);
            super.setHardwareInterface(null);
        }
        else
            log.warning("tried to set HardwareInterface to not a PSEyeHardwareInterface: " + hardwareInterface);
    }

   // abstract protected PSEyeEventExtractor createEventExtractor();
    @Override
    public AEFileInputStream constuctFileInputStream(File file) throws IOException {
        return new PSEyeCameraFileInputStream(file);
    }

    @Override public Mode setMode(Mode mode) throws HardwareInterfaceException { return camera.setMode(mode); }
    @Override public Mode getMode() { return camera.getMode(); }
    @Override public Resolution setResolution(Resolution resolution) throws HardwareInterfaceException { return camera.setResolution(resolution); }
    @Override public Resolution getResolution() { return camera.getResolution(); }
    @Override public int setFrameRate(int frameRate) throws HardwareInterfaceException { return camera.setFrameRate(frameRate); }
    @Override public int getFrameRate() { return camera.getFrameRate(); }
    @Override public int setGain(int gain) { return camera.setGain(gain); }
    @Override public int getGain() { return camera.getGain(); }
    @Override public int setExposure(int exposure) { return camera.setExposure(exposure); }
    @Override public int getExposure() { return camera.getExposure(); }
    @Override public int setRedBalance(int red) { return camera.setRedBalance(red); }
    @Override public int getRedBalance() { return camera.getRedBalance(); }
    @Override public int setGreenBalance(int green) { return camera.setGreenBalance(green); }
    @Override public int getGreenBalance() { return camera.getGreenBalance(); }
    @Override public int setBlueBalance(int blue) { return camera.setBlueBalance(blue); }
    @Override public int getBlueBalance() { return camera.getBlueBalance(); }
    @Override public boolean setAutoGain(boolean yes) { return camera.setAutoGain(yes); }
    @Override public boolean getAutoGain() { return camera.getAutoGain(); }
    @Override public boolean setAutoExposure(boolean yes) { return camera.setAutoExposure(yes); }
    @Override public boolean getAutoExposure() { return camera.getAutoExposure(); }
    @Override public boolean setAutoBalance(boolean yes) { return camera.setAutoBalance(yes); }
    @Override public boolean getAutoBalance() { return camera.getAutoBalance(); }

    @Override public Observable getObservable() { return this; }
    @Override public void notifyChip() { setChanged(); }
    @Override public Logger getLog() { return log; }

    @Override
    public JPanel getChipPanel() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public JPanel getCameraPanel() {
        throw new UnsupportedOperationException("Not supported yet.");
    }



    @Override
    public void exportPreferences(OutputStream os) throws IOException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void importPreferences(InputStream is) throws IOException, InvalidPreferencesFormatException, HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setPowerDown(boolean powerDown) throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void sendConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void flashConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public byte[] formatConfigurationBytes(Biasgen biasgen) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String getTypeName() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void close() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void open() throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean isOpen() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public ArrayList<Mode> getModes() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public ArrayList<Resolution> getResolutions() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public ArrayList<Integer> getFrameRates() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMaxExposure() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMinExposure() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMaxGain() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMinGain() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMaxBalance() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getMinBalance() {
        throw new UnsupportedOperationException("Not supported yet.");
    }
}
