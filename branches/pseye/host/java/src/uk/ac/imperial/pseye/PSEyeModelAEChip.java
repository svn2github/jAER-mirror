
package uk.ac.imperial.pseye;

import uk.ac.imperial.vsbe.FrameStreamable;
import uk.ac.imperial.vsbe.FrameInputStream;
import net.sf.jaer.chip.AEChip;
import java.util.prefs.PreferenceChangeEvent;
import java.util.prefs.PreferenceChangeListener;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import java.io.File;
import java.io.IOException;
import java.util.Observable;
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
abstract class PSEyeModelAEChip extends AEChip implements PreferenceChangeListener, 
        PSEyeDriverInterface {
    // camera values being used by chip
    public Mode mode;
    public Resolution resolution;
    public int frameRate;
    
    /* store parameters so can be re-set after camera closed() */
    private int gain;
    private int exposure;
    
    /* channel balance (min value of 0 removes channel) */
    private int red;
    private int green;
    private int blue;
    
    /* automatic settings */
    private boolean autoGain;
    private boolean autoExposure;
    private boolean autoBalance;
    
    PSEyeCamera pseye = null;
    PSEyeModelRenderer renderer = null;
    
    @Override
    public void preferenceChange(PreferenceChangeEvent evt) {
        getBiasgen().loadPreferences();
    }

    public PSEyeModelAEChip() {
        setEventExtractor(createEventExtractor());
        loadPreferences();
        
        setBiasgen(new PSEyeBiasgen(this));
        setRenderer((renderer = new PSEyeModelRenderer(this)));
        
        getPrefs().addPreferenceChangeListener(this);
    }

    /* needed to ensure listener deregistered on construction of
     * an equivalent instance and so prevent a memory leak 
     */
    @Override
    public void cleanup() {
        super.cleanup();
        getPrefs().removePreferenceChangeListener(this);
    }
    
    protected void loadPreferences() {
        try {
            // set mode, resolution, framerate
            setMode(Mode.valueOf(getPrefs().get("mode", "MONO")));
            setResolution(Resolution.valueOf(getPrefs().get("resolution", "QVGA")));
            setFrameRate(getPrefs().getInt("frameRate", 60));
                
            // set exposure, gain, and auto gain/exposure settings
            setGain(getPrefs().getInt("gain", 30));
            setExposure(getPrefs().getInt("exposure", 0));
            
            setRedBalance(getPrefs().getInt("red", 1));
            setGreenBalance(getPrefs().getInt("green", 1));
            setBlueBalance(getPrefs().getInt("blue", 1));
            
            setAutoGain(getPrefs().getBoolean("autoGain", true));
            setAutoExposure(getPrefs().getBoolean("autoExposure", true));      
            setAutoBalance(getPrefs().getBoolean("autoBalance", true));      
            
        } catch (Exception ex) {
            log.warning(ex.toString());
        }
        
        if (getEventExtractor() != null && (getEventExtractor() instanceof PSEyeEventExtractor))
            ((PSEyeEventExtractor) getEventExtractor()).loadPreferences(getPrefs());
    }

    protected void storePreferences() {
        // use getter functions to store parameters
        getPrefs().put("mode", getMode().name());
        getPrefs().put("resolution", getResolution().name());
        getPrefs().putInt("frameRate", getFrameRate());
        
        getPrefs().putInt("gain", getGain());
        getPrefs().putInt("exposure", getExposure());
        
        getPrefs().putInt("red", getRedBalance());
        getPrefs().putInt("green", getGreenBalance());
        getPrefs().putInt("blue", getBlueBalance());
        
        getPrefs().putBoolean("autoGain", getAutoGain());
        getPrefs().putBoolean("autoExposure", getAutoExposure());
        getPrefs().putBoolean("autoBalance", getAutoBalance());
        
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
        if (hardwareInterface != null && (hardwareInterface instanceof PSEyeHardwareAEInterface)) {
            super.setHardwareInterface(hardwareInterface);
            pseye = (PSEyeCamera) getHardwareInterface();
            try {
                // set mode, resolution, framerate
                mode = pseye.setMode(mode);
                resolution = pseye.setResolution(resolution);
                frameRate = pseye.setFrameRate(frameRate);
                
                // set exposure, gain, and auto gain/exposure settings
                gain = pseye.setGain(gain);
                exposure = pseye.setExposure(exposure);
                
                red = pseye.setRedBalance(red);
                green = pseye.setGreenBalance(green);
                blue = pseye.setBlueBalance(blue);
                
                autoGain = pseye.setAutoGain(autoGain);
                autoExposure = pseye.setAutoExposure(autoExposure);      
                autoBalance = pseye.setAutoBalance(autoBalance);      
                
            } catch (Exception ex) {
                log.warning(ex.toString());
            }
        }
        else if (hardwareInterface == null) {
            if (checkHardware()) {
                pseye.close();
                pseye = null;
            }
            super.setHardwareInterface(null);
        }
        else
            log.warning("tried to set HardwareInterface to not a PSEyeHardwareInterface: " + hardwareInterface);
    }

    // should this iinclude mode, resolution and frame rate?
    public void sendConfiguration() {
        if (checkHardware()) {
            setGain(gain);
            setExposure(exposure);
            setAutoExposure(autoExposure);
            setAutoGain(autoGain);
        }
    }
    
    public boolean checkHardware() {
        return pseye != null;
    }

    abstract protected PSEyeEventExtractor createEventExtractor();
    
    @Override
    public Mode setMode(Mode mode) throws HardwareInterfaceException {
        if (mode != getMode()) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.mode = pseye.setMode(mode);
            else this.mode = mode; 
            
            setChanged();            
            notifyObservers(EVENT.MODE);
        }   
        return this.mode;
    }
    
    @Override
    public Mode getMode() {
        if (checkHardware()) mode = pseye.getMode();
        return mode;
    }
    
    @Override
    public Resolution setResolution(Resolution resolution) throws HardwareInterfaceException {
        if (resolution != getResolution()) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.resolution = pseye.setResolution(resolution);
            else this.resolution = resolution; 
            
            setChanged();            
            notifyObservers(EVENT.RESOLUTION);
        }   
        return this.resolution;
    }
    
    @Override
    public Resolution getResolution() {
        if (checkHardware()) resolution = pseye.getResolution();
        return resolution;
    }
    
    @Override
    public int setFrameRate(int frameRate) throws HardwareInterfaceException {
        if (frameRate != getFrameRate()) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.frameRate = pseye.setFrameRate(frameRate);
            else this.frameRate = frameRate; 
            
            setChanged();            
            notifyObservers(EVENT.FRAMERATE);
        }   
        return this.frameRate;        
    }
    
    @Override
    public int getFrameRate() {
        if (checkHardware()) frameRate = pseye.getFrameRate();
        return frameRate;
    }
    
    /* Set the value of gain */
    @Override
    synchronized public int setGain(int gain) {
        if (gain != this.gain) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.gain = pseye.setGain(gain);
            else this.gain = gain;

            setChanged();
            notifyObservers(EVENT.GAIN);
        }
        return this.gain;
    }
    
    /* Get the value of gain */
    @Override
    public int getGain() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) gain = pseye.getGain();
        return gain;
    }
    
    /* Set the value of exposure */
    @Override
    synchronized public int setExposure(int exposure) {
        if (exposure != this.exposure) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.exposure = pseye.setExposure(exposure);
            else this.exposure = exposure;

            setChanged();
            notifyObservers(EVENT.EXPOSURE);
        }
        return this.exposure;
    }
    
    /* Get the value of exposure */
    @Override
    public int getExposure() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) exposure = pseye.getExposure();
        return exposure;
    }
    
    @Override
    public int setRedBalance(int red) {
        if (red != this.red) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.red = pseye.setRedBalance(red);
            else this.red = red;

            setChanged();
            notifyObservers(EVENT.RED_BALANCE);
        }
        return this.red;      
    }
    
    @Override
    public int getRedBalance() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) red = pseye.getRedBalance();
        return red;        
    }
  
    @Override
    public int setGreenBalance(int green) {
        if (green != this.green) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.green = pseye.setGreenBalance(green);
            else this.green = green;

            setChanged();
            notifyObservers(EVENT.GREEN_BALANCE);
        }
        return this.green;      
    }
        
    @Override
    public int getGreenBalance() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) green = pseye.getGreenBalance();
        return green;        
    }

    @Override
    public int setBlueBalance(int blue) {
        if (blue != this.blue) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.blue = pseye.setBlueBalance(blue);
            else this.blue = blue;

            setChanged();
            notifyObservers(EVENT.BLUE_BALANCE);
        }
        return this.blue;      
    }
    
    @Override
    public int getBlueBalance() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) blue = pseye.getBlueBalance();
        return blue;        
    }

    @Override
    public boolean setAutoGain(boolean yes) {
        if (yes != this.autoGain) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.autoGain = pseye.setAutoGain(yes);
            else this.autoGain = yes;

            setChanged();
            notifyObservers(EVENT.AUTO_GAIN);
        }
        return this.autoGain;        
    }
    
    @Override
    public boolean getAutoGain() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) autoGain = pseye.getAutoGain();
        return autoGain;         
    }

    @Override
    public boolean setAutoExposure(boolean yes) {
        if (yes != this.autoExposure) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.autoExposure = pseye.setAutoExposure(yes);
            else this.autoExposure = yes;

            setChanged();
            notifyObservers(EVENT.AUTO_EXPOSURE);
        }
        return this.autoExposure;        
    }    
    
    @Override
    public boolean getAutoExposure() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) autoExposure = pseye.getAutoExposure();
        return autoExposure;         
    }
    
    @Override
    public boolean getAutoBalance() {
        // check hardware interface exists and is PSEye camera
        if (checkHardware()) autoBalance = pseye.getAutoBalance();
        return autoBalance;         
    }    
    
    @Override
    public boolean setAutoBalance(boolean yes) {
        if (yes != this.autoBalance) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.autoBalance = pseye.setAutoBalance(yes);
            else this.autoBalance = yes;

            setChanged();
            notifyObservers(EVENT.AUTO_BALANCE);
        }
        return this.autoBalance;        
    }    

    @Override
    public Observable getObservable() {
        return this;
    }
    
    @Override
    public AEFileInputStream constuctFileInputStream(File file) throws IOException {
        return new PSEyeCameraFileInputStream(file);
    }    
}
