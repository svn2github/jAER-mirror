
package uk.ac.imperial.pseye;

import java.util.ArrayList;
import java.util.Observable;
import java.util.logging.Level;
import uk.ac.imperial.vsbe.AbstractCamera;
import cl.eye.CLCamera;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.nio.channels.FileChannel;
import java.util.List;
import java.util.Collections;
import java.util.logging.Logger;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import javax.swing.JPanel;
import uk.ac.imperial.vsbe.Frame;

/**
 * Wrapper class for camera driver - currently CL 
 * i.e. other classes must never use directly use CL code
 * All underlying variables / methods are overridden
 * Constants and mappings are contained in CLDriverValues interface
 * 
 * AbstractCamera defaults to MONO, QVGA, 15FPS, 
 * gain=0, auto_gain=true, exposure=0, auto_exposure=true
 * 
 * @author mlk
 */
public class PSEyeCameraHardware extends AbstractCamera implements PSEyeDriverInterface {
    protected final static Logger log = Logger.getLogger("PSEye");
    protected int index; // index of camera to open
    protected int cameraInstance = 0; // local instance of camera
    protected boolean isCreated = false;
    
    public static int GET_FRAME_TIMEOUT = 50;
   
    /* Base AbstractCamera hardware parameters - updates require restart */
    protected Mode mode = Mode.COLOUR;
    protected Resolution resolution = Resolution.QVGA;
    protected int frameRate = supportedFrameRates.get(resolution).get(0);
    
    /* store parameters so can be re-set after camera closed() */
    protected int gain = supportedGains.get(resolution).min;
    protected int exposure = supportedExposures.get(resolution).min;
    
    /* channel balance (min value of 0 removes channel) */
    protected int red = 1;
    protected int green = 1;
    protected int blue = 1;
    
    /* automatic settings */
    protected boolean autoGain = false;
    protected boolean autoExposure = false;
    protected boolean autoBalance = false;
    
    /* Constructs instance to open with passed index */
    PSEyeCameraHardware() {
        super();
    }
    
    /* Constructs instance to open with passed index */
    PSEyeCameraHardware(int index) {
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
            isCreated = true;
            // set all parameters to initial values
            initCamera();
            
            return true;
        }
        return false;
    }
    
    public PSEyeCameraHardware copySettings(PSEyeCameraHardware pseye)  throws HardwareInterfaceException {    
        try {
            setMode(pseye.getMode(), false);
            setResolution(pseye.getResolution(), false);
            setFrameRate(pseye.getFrameRate(), true);
        } catch (Exception e) {
            throw new HardwareInterfaceException("couldn't create camera");
        }
            
        setGain(pseye.getGain());
        setExposure(pseye.getExposure());
    
        setRedBalance(pseye.getRedBalance());
        setGreenBalance(pseye.getGreenBalance());
        setBlueBalance(pseye.getBlueBalance());
    
        setAutoGain(pseye.getAutoGain());
        setAutoExposure(pseye.getAutoExposure());
        setAutoBalance(pseye.getAutoBalance());
            
        return this;
    }
    
    /* Set initial parameter values */
    private void initCamera() {
        // set parameters forcing update
        setAutoGain(autoGain, true);
        setGain(gain, true);
        
        setAutoExposure(autoExposure, true);
        setExposure(exposure, true);
        
        setAutoBalance(autoBalance, true);
        setRedBalance(red, true);
        setGreenBalance(green, true);
        setBlueBalance(blue, true);
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
        return frameSizeX.get(resolution);
    }
    
    @Override
    public int getFrameY() {
        return frameSizeY.get(resolution);  
    }
    
    @Override
    public int getPixelSize() {
        return pixelSize.get(mode);   
    }
    
    @Override
    public boolean read(Frame frame) {
        // check camera created and started and that passed array big enough to store data
        if (!isCreated || !isStarted ) return false;
        if (frame.getSize() != (getFrameX() * getFrameY() * getPixelSize())) return false;
        return CLCamera.CLEyeCameraGetFrame(cameraInstance, frame.getData().array(), GET_FRAME_TIMEOUT);        
    }
    
    @Override
    public boolean peek(Frame frame) {
        return false;      
    }
    
    
    @Override
    public JPanel getControlPanel() {
        return new PSEyeControlPanel(this);
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
            notifyObservers(EVENT_CAMERA.MODE);
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
            // try re-setting parameters as dependent on resolution
            setGain(gain);
            setExposure(exposure);
            setRedBalance(red);
            setRedBalance(green);
            setRedBalance(blue);
        
            setChanged();            
            notifyObservers(EVENT_CAMERA.RESOLUTION);
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
            notifyObservers(EVENT_CAMERA.FRAMERATE);
        }
        
        return cameraFrameRate;
    }
    
    /* Get the nearest supported frame rate above that passed */
    private int getClosestFrameRate(int frameRate) {
        List<Integer> frs = supportedFrameRates.get(resolution);
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
        if (gain > getMaxGain()) {
            log.log(Level.WARNING, "Gain {0} above maximum, setting to max {1}", 
                    new Object[] {gain, getMaxGain()});
            gain = getMaxGain();
        }
        
        if (gain < getMinGain()) {
            log.log(Level.WARNING, "Gain {0} below minimum, setting to min {1}", 
                    new Object[] {gain, getMinGain()});
            gain = getMinGain();            
        }   
        
        if(force || getGain() != gain) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_GAIN, gain))
                    this.gain = getCameraParam(CLCamera.CLEYE_GAIN);
                else return this.gain;
            }
            else this.gain = gain;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT_CAMERA.GAIN);
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
        if (exposure > getMaxExposure()) {
            log.log(Level.WARNING, "Exposure {0} above maximum, setting to max {1}", 
                    new Object[] {exposure, getMaxExposure()});
            exposure = getMaxExposure();
        }
        
        if (exposure < getMinExposure()) {
            log.log(Level.WARNING, "Exposure {0} below minimum, setting to min {1}", 
                    new Object[] {exposure, getMinExposure()});
            exposure = getMinExposure();            
        }   
        
        if(force || exp != getExposure()) {
            if(isCreated) {
                if (setCameraParam(CLCamera.CLEYE_EXPOSURE, exp))
                    exposure = getCameraParam(CLCamera.CLEYE_EXPOSURE);
                else return exposure;
            }
            else exposure = exp;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT_CAMERA.EXPOSURE);
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
        if (red > getMaxBalance()) {
            log.log(Level.WARNING, "Red balance {0} above maximum, setting to max {1}", 
                    new Object[] {red, getMaxBalance()});
            red = getMaxBalance();
        }
        
        if (red < getMinBalance()) {
            log.log(Level.WARNING, "Red balance {0} below minimum, setting to min {1}", 
                    new Object[] {red, getMinBalance()});
            red = getMinBalance();            
        }  
        
        if(force || getRedBalance() != red) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_RED, red))
                    this.red = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_RED);
                else return this.red;
            }
            else this.red = red;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT_CAMERA.RED_BALANCE);
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
        if (green > getMaxBalance()) {
            log.log(Level.WARNING, "Green balance {0} above maximum, setting to max {1}", 
                    new Object[] {green, getMaxBalance()});
            green = getMaxBalance();
        }
        
        if (green < getMinBalance()) {
            log.log(Level.WARNING, "Green balance {0} below minimum, setting to min {1}", 
                    new Object[] {green, getMinBalance()});
            green = getMinBalance();            
        }  
        
        if(force || getGreenBalance() != green) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_GREEN, green))
                    this.green = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_GREEN);
                else return this.green;
            }
            else this.green = green;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT_CAMERA.GREEN_BALANCE);
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
        if (blue > getMaxBalance()) {
            log.log(Level.WARNING, "Blue balance {0} above maximum, setting to max {1}", 
                    new Object[] {blue, getMaxBalance()});
            blue = getMaxBalance();
        }
        
        if (blue < getMinBalance()) {
            log.log(Level.WARNING, "Blue balance {0} below minimum, setting to min {1}", 
                    new Object[] {blue, getMinBalance()});
            blue = getMinBalance();            
        }  
        
        if(force || getBlueBalance() != blue) {
            if (isCreated) {
                if (setCameraParam(CLCamera.CLEYE_WHITEBALANCE_BLUE, blue))
                    this.blue = getCameraParam(CLCamera.CLEYE_WHITEBALANCE_BLUE);
                else return this.blue;
            }
            else this.blue = blue;
            // parameter changed so set flag and notify
            setChanged();
            notifyObservers(EVENT_CAMERA.BLUE_BALANCE);
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
                    if (!yes) setGain(gain, true);
                }
                else return autoGain;
            }
            else autoGain = yes;
            setChanged();
            notifyObservers(EVENT_CAMERA.AUTO_GAIN);
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
                    if (!yes) setExposure(exposure, true);
                }
                else return autoExposure;
            }
            else autoExposure = yes;
            setChanged();
            notifyObservers(EVENT_CAMERA.AUTO_EXPOSURE);
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
                    if (!yes) {
                        setRedBalance(red, true);
                        setGreenBalance(green, true);
                        setBlueBalance(blue, true);
                    }
                }
                else return autoBalance;
            }
            else autoBalance = yes;
            setChanged();
            notifyObservers(EVENT_CAMERA.AUTO_BALANCE);
        }
        return autoBalance;
    }
    
    @Override
    public ArrayList<Mode> getModes() {
        return supportedModes;
    }

    @Override
    public ArrayList<Resolution> getResolutions() {
        return supportedResolutions;
    }

    @Override
    public ArrayList<Integer> getFrameRates() {
        return supportedFrameRates.get(resolution);
    }

    @Override
    public int getMaxExposure() {
        return supportedExposures.get(resolution).max;
    }

    @Override
    public int getMinExposure() {
        return supportedExposures.get(resolution).min;
    }

    @Override
    public int getMaxGain() {
        return supportedGains.get(resolution).max;
    }

    @Override
    public int getMinGain() {
        return supportedGains.get(resolution).min;
    }

    @Override
    public int getMaxBalance() {
        return supportedBalances.get(resolution).max;
    }

    @Override
    public int getMinBalance() {
        return supportedBalances.get(resolution).min;
    }
    
    @Override
    public Logger getLog() {
        return log;
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
        int i = 0;
        int cameraInstance = CLCamera.CLEyeCreateCamera(0, CLCamera.CLEYE_COLOR, 
                CLCamera.CLEYE_QVGA, 125);
        log.log(Level.INFO, "{0}", cameraInstance);
        log.log(Level.INFO, "{0}", CLCamera.CLEyeSetCameraParameter(cameraInstance, CLCamera.CLEYE_EXPOSURE, 200));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeSetCameraParameter(cameraInstance, CLCamera.CLEYE_GAIN, 0));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeSetCameraParameter(cameraInstance, CLCamera.CLEYE_WHITEBALANCE_RED, 0));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeSetCameraParameter(cameraInstance, CLCamera.CLEYE_WHITEBALANCE_GREEN, 0));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeSetCameraParameter(cameraInstance, CLCamera.CLEYE_WHITEBALANCE_BLUE, 255));
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStart(cameraInstance));
        
        
        ByteBuffer temp = ByteBuffer.allocate(320 * 240);
        IntBuffer temp2 = IntBuffer.allocate(320*240);
        log.log(Level.INFO, "{0}", temp2.hasArray());
        for (i=0; i < 300; i++) {
            CLCamera.CLEyeCameraGetFrame(cameraInstance, temp2.array(), 50);
        }
        log.log(Level.INFO, "{0}", CLCamera.CLEyeCameraStop(cameraInstance));
        
        for (i=0; i<temp2.capacity(); i++) {
            temp.put((byte)(temp2.get() & 0xff));
        }
        
        FileChannel fc = null;
        temp.rewind();
        try {
            fc = new FileOutputStream(new File("D:\\test.txt")).getChannel();
            fc.write(temp);
            fc.close();
        } catch (Exception e) { log.log(Level.INFO, "{0}", e.getMessage());}            

        /*
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
        */
    }
}
