
package uk.ac.imperial.pseye;

import java.util.logging.Level;
import uk.ac.imperial.vsbe.Camera;
import uk.ac.imperial.vsbe.CameraControlPanel;
import cl.eye.CLCamera;
import java.util.List;
import java.util.Collections;
import java.util.Observable;
import java.util.logging.Logger;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import javax.swing.JPanel;

/**
 * Wrapper class for camera driver - currently CL 
 * i.e. other classes must never use directly use CL code
 * All underlying variables / methods are overridden
 * Constants and mappings are contained in CLDriverValues interface
 * 
 * Camera defaults to MONO, QVGA, 15FPS, 
 * gain=0, auto_gain=true, exposure=0, auto_exposure=true
 * 
 * @author mlk
 */
public class PSEyeCamera extends Camera implements PSEyeDriverInterface {
    protected final static Logger log = Logger.getLogger("PSEye");
    protected int index; // index of camera to open
    protected int cameraInstance = 0; // local instance of camera
    protected boolean isCreated = false;
    
    public static int GET_FRAME_TIMEOUT = 50;
   
    /* Base Camera hardware parameters - updates require restart */
    protected Mode mode = Mode.COLOUR;
    protected Resolution resolution = Resolution.QVGA;
    protected int frameRate = supportedFrameRate.get(resolution).get(0);
    
    /* store parameters so can be re-set after camera closed() */
    protected int gain = supportedGain.get(resolution).min;
    protected int exposure = supportedExposure.get(resolution).min;
    
    /* channel balance (min value of 0 removes channel) */
    protected int red = 1;
    protected int green = 1;
    protected int blue = 1;
    
    /* automatic settings */
    protected boolean autoGain = false;
    protected boolean autoExposure = false;
    protected boolean autoBalance = false;
    
    /* Constructs instance to open with passed index */
    PSEyeCamera(int index) {
        super();
        // check index valid and make singleton? mlk
        this.index = index;
    }
    
    /*
     * Overriden java.lang.Object
     */
    @Override
    public String toString() {
        return "PSEyeCamera(" + index + ")";
    }    
    
    /*
     * Wrappers for CL Driver functions
     */
    
    /* Returns number of cameras - Does not require a valid camera instance */
    public static int cameraCount() { 
        return CLCamera.CLEyeGetCameraCount(); 
    }

    /* Returns UUID of camera or all 0's if invalid index given - Does not 
     * require a valid camera instance */
    public static String cameraUUID(int index) { 
        return CLCamera.CLEyeGetCameraUUID(index);
    }
    
    /* Create a camera instance */
    synchronized private boolean createCamera() {
        // Check to see if camera already exists, cannot create new
        if (isCreated) return false;
        
        // create camera instance
        cameraInstance = CLCamera.CLEyeCreateCamera(index, mode.getValue(), 
                resolution.getValue(), frameRate);
        if (cameraInstance != 0) {
            // set all parameters to initial values
            initCamera();
            isCreated = true;
            return true;
        }
        return false;
    }
    
    /* Set initial parameter values */
    private void initCamera() {
        // set parameters forcing update - auto also updates underlying parameters
        setAutoGain(autoGain, true);
        setAutoExposure(autoExposure, true);
        setAutoBalance(autoBalance, true);
    }
    
    /* Destroys the camera instance */
    synchronized private boolean destroyCamera() {
        // no camera to destroy or camera running
        if (!isCreated || isStarted) return false;
        
        if (CLCamera.CLEyeDestroyCamera(cameraInstance)) {
            cameraInstance = 0;
            isCreated = false;
            return true;
        }
        return false;
    }
    
    /* Starts the camera. */
    @Override
    synchronized public boolean start() {
        // camera doesn't exist or already started
        if (!isCreated || isStarted) return false;
        
        //  try to start camera
        if (CLCamera.CLEyeCameraStart(cameraInstance)) {
            // start producer thread
            super.start();
            return true;
        }
        return false;
    }

    /* Stops the camera */
    @Override
    synchronized public boolean stop() {
        // camera doesn't exist or is already stopped
        if (!isCreated || !isStarted) return false;

        // try to stop camera
        if (CLCamera.CLEyeCameraStop(cameraInstance)) {
            // stop producer thread
            super.stop();
            
            // Pause needed to give CL Driver Thread time to finish
            try {
                Thread.sleep(50);
            } catch (Exception e) {
                log.warning(e.getMessage());
            }
            return true;
        }
        return false;
    }
    
    /* Set a parameter on the camera */
    private boolean setCameraParam(int param, int val) {
        return CLCamera.CLEyeSetCameraParameter(cameraInstance, param, val);
    }
    
    /* Get a parameter on the camera */
    private int getCameraParam(int param) {
        return CLCamera.CLEyeGetCameraParameter(cameraInstance, param);
    }
    
    /*
     * Overriden vsbe.FrameStreamable methods
     */
    @Override
    public int getFrameX() {
        switch(resolution) {
            case QVGA: return 320;
            case VGA: return 640;
            default: return 0;
        }
    }
    
    @Override
    public int getFrameY() {
        switch(resolution) {
            case QVGA: return 240;
            case VGA: return 480;
            default: return 0;
        }    
    }
    
    @Override
    public int getPixelSize() {
        switch(mode) {
            case MONO: return 1;
            case COLOUR: return 1;
            default: return 0;
        }        
    }
    
    @Override
    public boolean readFrameStream(int[] imgData, int offset) {
        // check camera created and started and that passed array big enough to store data
        if (!isCreated || !isStarted || frameSizeMap.get(resolution) > imgData.length) return false;
        return CLCamera.CLEyeCameraGetFrame(cameraInstance, imgData, GET_FRAME_TIMEOUT);        
    }
    
    
    @Override
    public JPanel getControlPanel() {
        return new CameraControlPanel(this, new PSEyeSettingPanel(this));
    }
    
     /*
     * Overriden net.sf.jaer.hardwareinterface.HardwareInterface
     */
    @Override
    public String getTypeName() {
        return toString();
    }

    /* Closes the camera. */
    @Override
    synchronized public void close() {
        if(!stop()) {
            log.warning("Unable to stop camera.");
        }
        
        else if (!destroyCamera()) {
            log.warning("Unable to destroy camera.");
        }
    }

    /* Opens the cameraIndex camera with some default settings and starts the camera. Set the frameRateHz before calling open(). */
    @Override
    synchronized public void open() throws HardwareInterfaceException {
        if (!createCamera()) {
            throw new HardwareInterfaceException("couldn't create camera");
        }
        if (!start()) {
            throw new HardwareInterfaceException("couldn't start camera");
        }
    }

    @Override
    synchronized public boolean isOpen() {
        return isStarted;
    }
    
    private void reload() throws HardwareInterfaceException {
        // used when re-loading camera
        boolean wasStarted = isStarted;
        boolean wasCreated = isCreated;
        
        if (isStarted && !stop()) {
            throw new HardwareInterfaceException("couldn't stop camera");
        }
        
        if (isCreated && !destroyCamera()) {
            throw new HardwareInterfaceException("couldn't destroy camera");
        }        
        
        if (wasCreated && !createCamera()) {
            throw new HardwareInterfaceException("couldn't create camera");
        }
        
        if (wasStarted && !start()) {
            throw new HardwareInterfaceException("couldn't start camera");
        }
    }

    @Override
    public Mode getMode() {
        // cannot query camera as only set during creation
        return mode;
    }
    
    @Override
    synchronized public Mode setMode(Mode cameraMode) throws HardwareInterfaceException {
        return setMode(cameraMode, true);
    }
    
    private Mode setMode(Mode cameraMode, boolean reset) throws HardwareInterfaceException {
        if(getMode() != cameraMode) {
            mode = cameraMode;
            if (reset) reload();
            setChanged();
            notifyObservers(EVENT.MODE);
        }
        
        return mode;
    }

    @Override
    public Resolution getResolution() {
        // cannot query camera as only set during creation
        return resolution;
    }    
    
    @Override
    synchronized public Resolution setResolution(Resolution cameraResolution) throws HardwareInterfaceException {
        return setResolution(cameraResolution, true);
    }
    
    private Resolution setResolution(Resolution cameraResolution, boolean reset) throws HardwareInterfaceException {
        if(getResolution() != cameraResolution) {
            resolution = cameraResolution;
            // alter resolution dependent framerate            
            setFrameRate(frameRate, false);
            if (reset) reload();
            setChanged();            
            notifyObservers(EVENT.RESOLUTION);
        }
        
        return resolution;
    }
    
    @Override
    public int getFrameRate() {
        // cannot query camera as only set during creation
        return frameRate;
    }
    
    @Override
    synchronized public int setFrameRate(int cameraFrameRate) throws HardwareInterfaceException {
        return setFrameRate(cameraFrameRate, true);
    }
    
    private int setFrameRate(int cameraFrameRate, boolean reset) throws HardwareInterfaceException {
        // get a supported frame rate
        cameraFrameRate = getClosestFrameRate(cameraFrameRate);
        if(getFrameRate() != cameraFrameRate) {
            frameRate = cameraFrameRate;
            if(reset) reload();
            setChanged();
            notifyObservers(EVENT.FRAMERATE);
        }
        
        return cameraFrameRate;
    }
    
    /* Get the nearest supported frame rate above that passed */
    private int getClosestFrameRate(int frameRate) {
        List<Integer> frs = supportedFrameRate.get(resolution);
        Collections.sort(frs);
        int pos = Collections.binarySearch(frs, frameRate);
        if (pos >= 0) {
            return frs.get(pos);
        }
        else {
            pos = -(pos + 1);
            return pos < frs.size() ? frs.get(pos) : frs.get(pos - 1);
        } 
    }    
    
    @Override
    public int getGain() {
        return gain;
    }    

    @Override
    synchronized public int setGain(int gain) {
        return setGain(gain, false);
    }
    
    /* Sets the gain value. */
    private int setGain(int gain, boolean force) {
        gain = supportedGain.get(resolution).trimValue(gain);
        if(force || getGain() != gain) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_GAIN, gain))
                    this.gain = getCameraParam(CLCamera.CLEYE_GAIN);
                else return this.gain;
            }
            else this.gain = gain;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT.GAIN);
        }
        return this.gain;
    }
    
    @Override
    public int getExposure() {
        return exposure;
    }
        
    @Override
    synchronized public int setExposure(int exp) {
        return setExposure(exp, false);
    }
    
    /* Sets the exposure value. */
    private int setExposure(int exp, boolean force) {
        exp = supportedExposure.get(resolution).trimValue(exp);
        if(force || exp != getExposure()) {
            if(isCreated) {
                if (setCameraParam(CLCamera.CLEYE_EXPOSURE, exp))
                    exposure = getCameraParam(CLCamera.CLEYE_EXPOSURE);
                else return exposure;
            }
            else exposure = exp;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT.EXPOSURE);
        }
        return exposure;
    }

    @Override
    public int getRedBalance() {
        return red;
    }    

    @Override
    synchronized public int setRedBalance(int red) {
        return setRedBalance(red, false);
    }
    
    /* Sets the red value. */
    private int setRedBalance(int red, boolean force) {
        red = supportedBalance.get(resolution).trimValue(red);
        if(force || getRedBalance() != red) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_RED, red))
                    this.red = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_RED);
                else return this.red;
            }
            else this.red = red;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT.RED_BALANCE);
        }
        return this.red;
    }
    
    @Override
    public int getGreenBalance() {
        return green;
    }    

    @Override
    synchronized public int setGreenBalance(int green) {
        return setGreenBalance(green, false);
    }
    
    /* Sets the green value. */
    private int setGreenBalance(int green, boolean force) {
        green = supportedBalance.get(resolution).trimValue(green);
        if(force || getGreenBalance() != green) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_GREEN, green))
                    this.green = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_GREEN);
                else return this.green;
            }
            else this.green = green;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT.GREEN_BALANCE);
        }
        return this.green;
    }
    
    @Override
    public int getBlueBalance() {
        return blue;
    }    

    @Override
    synchronized public int setBlueBalance(int blue) {
        return setBlueBalance(blue, false);
    }
    
    /* Sets the blue value. */
    private int setBlueBalance(int blue, boolean force) {
        blue = supportedBalance.get(resolution).trimValue(blue);
        if(force || getBlueBalance() != blue) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_BLUE, blue))
                    this.blue = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_BLUE);
                else return this.blue;
            }
            else this.blue = blue;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT.BLUE_BALANCE);
        }
        return this.blue;
    }
    
    @Override
    public boolean getAutoGain() {
        return autoGain;
    } 
    
    @Override
    synchronized public boolean setAutoGain(boolean yes) {
        return setAutoGain(yes, false);
    }
    
    /* Enables auto gain */
    private boolean setAutoGain(boolean yes, boolean force) {
        if(force || yes != getAutoGain()) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_AUTO_GAIN, yes ? 1 : 0)) {
                    autoGain = getCameraParam(CLCamera.CLEYE_AUTO_GAIN) == 1;
                    setGain(gain, true);
                }
                else return autoGain;
            }
            else autoGain = yes;
            setChanged();
            notifyObservers(EVENT.AUTO_GAIN);
        }
        return autoGain;
    }

    @Override
    public boolean getAutoExposure() {
        return autoExposure;
    } 
    
    @Override
    synchronized public boolean setAutoExposure(boolean yes) {
        return setAutoExposure(yes, false);
    }
    
    /* Enables auto gain */
    private boolean setAutoExposure(boolean yes, boolean force) {
        if(force || yes != getAutoExposure()) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_AUTO_EXPOSURE, yes ? 1 : 0)) {
                    autoExposure = getCameraParam(CLCamera.CLEYE_AUTO_EXPOSURE) == 1;
                    setExposure(exposure, true);
                }
                else return autoExposure;
            }
            else autoExposure = yes;
            setChanged();
            notifyObservers(EVENT.AUTO_EXPOSURE);
        }
        return autoExposure;
    }
    
    @Override
    public boolean getAutoBalance() {
        return autoBalance;
    } 
    
    @Override
    synchronized public boolean setAutoBalance(boolean yes) {
        return setAutoBalance(yes, false);
    }
    
    /* Enables auto gain */
    private boolean setAutoBalance(boolean yes, boolean force) {
        if(force || yes != getAutoBalance()) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_AUTO_WHITEBALANCE, yes ? 1 : 0)) {
                    autoBalance = getCameraParam(CLCamera.CLEYE_AUTO_WHITEBALANCE) == 1;
                    setRedBalance(red, true);
                    setRedBalance(green, true);
                    setRedBalance(blue, true);
                }
                else return autoBalance;
            }
            else autoBalance = yes;
            setChanged();
            notifyObservers(EVENT.AUTO_BALANCE);
        }
        return autoBalance;
    }
    
    @Override
    public Observable getObservable() {
        return this;
    }
    
    /* Helper functions */
    
    /* Convert the gain parameter passed to the CL Driver into a real gain */
    public static double realGain(int gp) {
        return Math.pow(2, gp >> 4) * ((gp % 16) / 16 + 1);
    }
    
    /* unit test of driver functions */
    public static void main (String arg[]) {
        log.log(Level.INFO, "{0}", cameraCount());
        log.log(Level.INFO, "{0}", cameraUUID(0));
        int cameraInstance = CLCamera.CLEyeCreateCamera(0, CLCamera.CLEYE_GRAYSCALE, 
                CLCamera.CLEYE_VGA, 15);
        log.log(Level.INFO, "{0}", cameraInstance);
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStart(cameraInstance));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeGetCameraParameter(cameraInstance, CLCamera.CLEYE_EXPOSURE));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStop(cameraInstance));
        cameraInstance = CLCamera.CLEyeCreateCamera(0, CLCamera.CLEYE_GRAYSCALE, 
                CLCamera.CLEYE_VGA, 15);                    
        try {
            Thread.sleep(50);
        } catch (Exception e) {}
        log.log(Level.INFO, "{0}", CLCamera.CLEyeDestroyCamera(cameraInstance));
        cameraInstance = CLCamera.CLEyeCreateCamera(0, CLCamera.CLEYE_GRAYSCALE, 
                CLCamera.CLEYE_VGA, 15);
        log.log(Level.INFO, "{0}", cameraInstance);
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStart(cameraInstance));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeGetCameraParameter(cameraInstance, CLCamera.CLEYE_EXPOSURE));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStop(cameraInstance));
        try {
            Thread.sleep(50);
        } catch (Exception e) {}
        log.log(Level.INFO, "{0}", CLCamera.CLEyeDestroyCamera(cameraInstance));
        //log.info("" + CLCamera.CLEyeGetCameraParameter(cameraInstance, CLCamera.CLEYE_EXPOSURE));
        
    }
}
