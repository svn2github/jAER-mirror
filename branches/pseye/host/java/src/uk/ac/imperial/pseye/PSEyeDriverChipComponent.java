
package uk.ac.imperial.pseye;

import java.util.Observable;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.chip.Chip;
import uk.ac.imperial.vsbe.CameraChipBiasInterface;
import java.util.logging.Logger;

/**
 * A private base class for the behavioural model of several AE retina models 
 * using the PS3-Eye camera.
 * Unlike the rest of jAER all hardware control should be done through
 * the chip's control panels as this handles setting validation and preferences (for 
 * camera and chip).
 * 
 * @author Tobi Delbruck and Mat Katz
 */
public class PSEyeDriverChipComponent<C extends Chip & CameraChipBiasInterface> implements PSEyeDriverInterface {
    protected Logger log;
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
    
    PSEyeCameraHardware pseye = null;
    C chip;

    public PSEyeDriverChipComponent(C modelChip) {
        chip = modelChip;
        log = chip.getLog();
        loadPreferences();
    }

    public void loadPreferences() {
        try {
            // set mode, resolution, framerate
            setMode(Mode.valueOf(chip.getPrefs().get("mode", "MONO")));
            setResolution(Resolution.valueOf(chip.getPrefs().get("resolution", "QVGA")));
            setFrameRate(chip.getPrefs().getInt("frameRate", 60));
                
            // set exposure, gain, and auto gain/exposure settings
            setGain(chip.getPrefs().getInt("gain", 30));
            setExposure(chip.getPrefs().getInt("exposure", 0));
            
            setRedBalance(chip.getPrefs().getInt("red", 1));
            setGreenBalance(chip.getPrefs().getInt("green", 1));
            setBlueBalance(chip.getPrefs().getInt("blue", 1));
            
            setAutoGain(chip.getPrefs().getBoolean("autoGain", true));
            setAutoExposure(chip.getPrefs().getBoolean("autoExposure", true));      
            setAutoBalance(chip.getPrefs().getBoolean("autoBalance", true));      
            
        } catch (Exception ex) {
            log.warning(ex.toString());
        }
    }

    public void storePreferences() {
        // use getter functions to store parameters
        chip.getPrefs().put("mode", getMode().name());
        chip.getPrefs().put("resolution", getResolution().name());
        chip.getPrefs().putInt("frameRate", getFrameRate());
        
        chip.getPrefs().putInt("gain", getGain());
        chip.getPrefs().putInt("exposure", getExposure());
        
        chip.getPrefs().putInt("red", getRedBalance());
        chip.getPrefs().putInt("green", getGreenBalance());
        chip.getPrefs().putInt("blue", getBlueBalance());
        
        chip.getPrefs().putBoolean("autoGain", getAutoGain());
        chip.getPrefs().putBoolean("autoExposure", getAutoExposure());
        chip.getPrefs().putBoolean("autoBalance", getAutoBalance());
    }

    public void setCamera(PSEyeCameraHardware camera) {
        if (camera != null) {
            pseye = camera;
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
        else {
            if (checkHardware()) {
                pseye.close();
                pseye = null;
            }
        }    
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
    
    @Override
    public Mode setMode(Mode mode) throws HardwareInterfaceException {
        if (mode != getMode()) {
            // check hardware interface exists and is PSEye camera
            if (checkHardware()) this.mode = pseye.setMode(mode);
            else this.mode = mode; 
            
            chip.notifyChip();
            chip.notifyObservers(EVENT.MODE);
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
            
            chip.notifyChip();            
            chip.notifyObservers(EVENT.RESOLUTION);
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
            
            chip.notifyChip();            
            chip.notifyObservers(EVENT.FRAMERATE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.GAIN);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.EXPOSURE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.RED_BALANCE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.GREEN_BALANCE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.BLUE_BALANCE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.AUTO_GAIN);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.AUTO_EXPOSURE);
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

            chip.notifyChip();
            chip.notifyObservers(EVENT.AUTO_BALANCE);
        }
        return this.autoBalance;        
    }

    @Override
    public Observable getObservable() {
        return chip;
    }
}
