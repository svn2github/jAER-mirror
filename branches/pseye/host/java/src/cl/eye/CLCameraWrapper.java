/*
 * Wrapper class for the original CL Laboratory CLCamera Class
 */

package cl.eye;

import java.util.Arrays;
import java.util.Observable;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.prefs.Preferences;
import net.sf.jaer.aemonitor.AEListener;
import net.sf.jaer.aemonitor.AEMonitorInterface;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/** Interface to Code Laboratories driver to Playstation Eye (PS Eye) camera.
 * See <a href="http://codelaboratories.com/research/view/cl-eye-muticamera-api">CodeLaboratories CL Eye Multicam C++ API</a> 
 * for the native API.
 * <p>To install the driver, download the <a href="http://codelaboratories.com/downloads/">CL Eye Platform Driver</a>.
 * 
 * @author jaer wrapper by mlk
 */
public class CLCameraWrapper extends Observable implements HardwareInterface {

    protected final static Logger log = Logger.getLogger("cl.CLEYE");
//    protected static Preferences prefs=Preferences.userNodeForPackage(CLCameraWrapper.class);
    protected final static CLCamera cl = new CLCamera();
    
    private int cameraIndex = 0; // index of camera to open
    private boolean isOpened = false;
    
   /** Observable events; This event is fired when the parameter is changed. */
    public static final String 
            EVENT_GAIN = "gain",
            EVENT_EXPOSURE = "exposure",
            EVENT_AUTOGAIN = "autoGain",
            EVENT_AUTOEXPOSURE = "autoExposure",
            EVENT_CAMERA_MODE = "cameraMode"
            ;
    
    public  final static int numModes = CameraMode.values().length;
    private CameraMode cameraMode = CameraMode.QVGA_COLOR_60; 
    // static methods
    public static final int CLEYE_MAX_GAIN=79;
    public static final int CLEYE_MAX_EXPOSURE=511;
    public static final int CLEYE_MAX_WHITEBALANCE=255;

    /** Possible camera modes */
    public enum CameraMode {
        QVGA_MONO_15(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 15),
        QVGA_MONO_30(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 30),
        QVGA_MONO_60(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 60),
        QVGA_MONO_75(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 75),
        QVGA_MONO_100(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 100),
        QVGA_MONO_125(cl.CLEYE_QVGA, cl.CLEYE_GRAYSCALE, 125),
        QVGA_COLOR_15(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 15),
        QVGA_COLOR_30(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 30),
        QVGA_COLOR_60(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 60),
        QVGA_COLOR_75(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 75),
        QVGA_COLOR_100(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 100),
        QVGA_COLOR_125(cl.CLEYE_QVGA, cl.CLEYE_COLOR, 125);
        
        int resolution;
        int color;
        int frameRateHz;

        CameraMode(int resolution, int color, int frameRateHz) {
            this.resolution = resolution;
            this.color = color;
            this.frameRateHz = frameRateHz;
        }
    }

    public static final int[] CLEYE_FRAME_RATES = {15, 30, 60, 75, 100, 125}; // TODO only QVGA now
    static{Arrays.sort(CLEYE_FRAME_RATES);}

    /**
     * @return the libraryLoaded
     */
    synchronized public static boolean isLibraryLoaded() {
        return cl.IsLibraryLoaded();
    }

    public static int cameraCount() {
        return cl.CLEyeGetCameraCount();
    }

    public static String cameraUUID(int index) {
        return cl.CLEyeGetCameraUUID(index);
    }

    /** Constructs instance for first camera
     * 
     */
    public CLCameraWrapper() {
        // don't use or set prefs here, leave that to use of this interface. Bad idea to split preferences between classes.
        
//        try{
//            cameraMode=CameraMode.valueOf(prefs.get("CLCameraWrapper.cameraMode",CameraMode.QVGA_MONO_60.toString()));
//        } catch(Exception e){
//            cameraMode=CameraMode.QVGA_MONO_60; // default;
//        }
    }

    /** Constructs instance to open the cameraIndex camera
     * 
     * @param cameraIndex 0 based index of cameras.
     */
    CLCameraWrapper(int cameraIndex) {
        this();
        this.cameraIndex = cameraIndex;
    }
    
    CLCameraWrapper(int cameraIndex, CameraMode cameraMode) {
        this();
        this.cameraIndex = cameraIndex;
        try {
            setCameraMode(cameraMode);
        } catch (HardwareInterfaceException ex) {
            log.warning("Setting CameraMode on construction, caught "+ex.toString());
        }
    }

    @Override
    public String toString() {
        return "CLCamera{" + "cameraIndex=" + cameraIndex + ", cameraMode=" + cameraMode + ", cameraStarted=" + cameraStarted + '}';
    }
    
    

    synchronized private boolean createCamera(int cameraIndex, int mode, int resolution, int framerate) {
        cl.cameraInstance = cl.CLEyeCreateCamera(cameraIndex, mode, resolution, framerate);
        return cl.cameraInstance != 0;
    }

    synchronized private boolean destroyCamera() {
        if (cl.cameraInstance == 0) return true;
        return cl.CLEyeDestroyCamera(cl.cameraInstance);
    }
    
    protected boolean cameraStarted = false;

    /** Starts the camera.
     * 
     * @return true if successful or if already started
     */
    synchronized public boolean startCamera() {
        if (cameraStarted) {
            return true;
        }
        cameraStarted = cl.CLEyeCameraStart(cl.cameraInstance);
        return cameraStarted;
    }

    /** Stops the camera
     * 
     * @return true if successful or if not started
     */
    synchronized public boolean stopCamera() {
        if (!cameraStarted) {
            return true;
        }
        boolean stopped = cl.CLEyeCameraStop(cl.cameraInstance);
        cameraStarted = false;
        return stopped;
    }

    /** Gets frame data
     * 
     * @param imgData
     * @param waitTimeout in ms
     * @throws HardwareInterfaceException if there is an error
     */
    synchronized public void getCameraFrame(int[] imgData, int waitTimeout) throws HardwareInterfaceException {
        if (!cameraStarted || !cl.CLEyeCameraGetFrame(cl.cameraInstance, imgData, waitTimeout)) {
            try {
                // Added to give external thread time to catch up as cannot synchronize directly
                Thread.sleep(500);
            } catch (InterruptedException e) {}
            throw new HardwareInterfaceException("capturing frame");
        }
    }

    /** Sets a camera parameter by parameter key and value.
     * 
     * @param param some parameter code
     * @param val the value
     * @return true if successful
     */
    synchronized public boolean setCameraParam(int param, int val) {
        if (cl.cameraInstance == 0) {
            return false;
        }
        return cl.CLEyeSetCameraParameter(cl.cameraInstance, param, val);
    }

    public int getCameraParam(int param) {
        return cl.CLEyeGetCameraParameter(cl.cameraInstance, param);
    }

    @Override
    public String getTypeName() {
        return "CLEYE PS Eye camera";
    }

    synchronized private void dispose() {
        stopCamera();
        destroyCamera();
    }

    /** Stops the camera.
     * 
     */
    @Override
    synchronized public void close() {
        if(!isOpened) return;
        isOpened = false;
        boolean stopped=stopCamera();
        if(!stopped){
            log.warning("stopCamera returned an error");
        }
        boolean destroyed=destroyCamera();
        if(!destroyed){
            log.warning("destroyCamera returned an error");
        }
        cl.cameraInstance=0;
    }

    /** Opens the cameraIndex camera with some default settings and starts the camera. Set the frameRateHz before calling open().
     * 
     * @throws HardwareInterfaceException 
     */
    @Override
    synchronized public void open() throws HardwareInterfaceException {
        if (isOpened) {
            return;
        }
//        if (cameraInstance == 0) { // only make one instance, don't destroy it on close
            /* removed by mlk as settings included in mode
            boolean gotCam = createCamera(cameraIndex, colorMode.code, cl.CLEYE_QVGA, getFrameRateHz()); // TODO fixed settings now
            */
            boolean gotCam = createCamera(cameraIndex, this.cameraMode.color, this.cameraMode.resolution, 
                    this.cameraMode.frameRateHz);
            if (!gotCam) {
                throw new HardwareInterfaceException("couldn't get camera");
            }
//        }
        if (!startCamera()) {
            throw new HardwareInterfaceException("couldn't start camera");
        }
        isOpened = true;
    }

    @Override
    public boolean isOpen() {
        return isOpened;
    }

    /** Returns the current mode of operation, e.g. QVGA_MONO_100
     * 
     * @return the operation mode
     */
    public CameraMode getCameraMode() {
        return this.cameraMode;
    }
    
    /** Sets the operating mode.
     * 
     * @param cameraMode desired mode.
     * @throws HardwareInterfaceException from the possible re-open attempt.
     */
    synchronized public void setCameraMode(CameraMode cameraMode) throws HardwareInterfaceException {
        if(this.cameraMode!=cameraMode) setChanged();
        this.cameraMode = cameraMode;
//        prefs.put("CLCameraWrapper.cameraMode",cameraMode.toString());   we don't use or set any preferences here
        if(isOpen()){
            close();
            try {
                Thread.sleep(500);
            } catch (InterruptedException ex) {
                log.info("Interrupted");
            }
            open();
        }
        notifyObservers(EVENT_CAMERA_MODE);
    }
    
    /** Sets the operating mode by index into CameraMode enum.
     * After setting this mode, the camera must be closed and re-opened if it was already running.
     * 
     * @param cameraModeIndex desired index
     * @see #close() 
     * @see #open() 
     */
    synchronized public void setCameraMode(int cameraModeIndex) throws HardwareInterfaceException {
        if (cameraModeIndex < 0 || cameraModeIndex >= numModes) {
            log.warning("Invalid Mode index " + cameraModeIndex + " leaving mode unchanged.");
        } else {
            setCameraMode(CameraMode.values()[cameraModeIndex]);
        }
    }
    
    /**
     * @return the frameRateHz
     */
    /* removed by mlk as frameRate incorporated into mode
    public int getFrameRateHz() {
        return frameRateHz;
    }
     * 
     */

    /**
     * @param frameRateHz the frameRateHz to set
     */
    /* removed by mlk as frameRate incorporated into mode
    synchronized public void setFrameRateHz(int frameRateHz) throws HardwareInterfaceException {
        int old = this.frameRateHz;

        int closest = closestRateTo(frameRateHz);
        if (closest != frameRateHz) {
            log.warning("returning closest allowed frame rate of " + closest + " from desired rate " + frameRateHz);
            frameRateHz = closest;
        }
        if (old != frameRateHz && isOpen()) {
            log.warning("new frame rate of " + frameRateHz + " will only take effect when camera is next opened");
        }
        this.frameRateHz = frameRateHz;
        prefs.putInt("CLCameraWrapper.frameRateHz", this.frameRateHz);
    }

    private int closestRateTo(int rate) {
        int ind = Arrays.binarySearch(cl.CLEYE_FRAME_RATES, rate);
        if(-ind>=cl.CLEYE_FRAME_RATES.length){
            return cl.CLEYE_FRAME_RATES[cl.CLEYE_FRAME_RATES.length];
        }
        if (ind <0) {
            return cl.CLEYE_FRAME_RATES[-ind-1];
        }
        return cl.CLEYE_FRAME_RATES[ind];
    }
     * 
     */

    // http://codelaboratories.com/research/view/cl-eye-muticamera-api
    /** Thrown for invalid parameters */
    public class InvalidParameterException extends Exception {

        public InvalidParameterException(String message) {
            super(message);
        }
    }

      /** Sets the gain value.
     * 
     * @param gain gain value, range 0-79
     * @throws HardwareInterfaceException if there is a hardware exception signaled by false return from driver
     * @throws cl.eye.CLCameraWrapper.InvalidParameterException if parameter is invalid (outside range)
     */
    synchronized public void setGain(int gain) throws HardwareInterfaceException, InvalidParameterException {
        if(gain!=getGain())setChanged();
        if (gain < 0) {
            throw new InvalidParameterException("tried to set gain<0 (" + gain + ")");
        }
        if (gain > 79) {
            throw new InvalidParameterException("tried to set gain>79 (" + gain + ")");
        }
        if (!setCameraParam(cl.CLEYE_GAIN, gain)) {
            throw new HardwareInterfaceException("setting gain to " + gain);
        }
        notifyObservers(EVENT_GAIN);
    }

    /** Asks the driver for the gain value.
     * 
     * @return gain value 
     */
    public int getGain() {
        int gain = getCameraParam(cl.CLEYE_GAIN);
        return gain;
    }

    /** Sets the exposure value.
     * 
     * @param exp exposure value, range 0-511
     * @throws HardwareInterfaceException if there is a hardware exception signaled by false return from driver
     * @throws cl.eye.CLCameraWrapper.InvalidParameterException if parameter is invalid (outside range)
     */
    synchronized public void setExposure(int exp) throws HardwareInterfaceException, InvalidParameterException {
        if(exp!=getExposure()) setChanged();
        if (exp < 0) {
            throw new InvalidParameterException("tried to set exposure<0 (" + exp + ")");
        }
        if (exp > CLEYE_MAX_EXPOSURE) {
            throw new InvalidParameterException("tried to set exposure>511 (" + exp + ")");
        }
        if (!setCameraParam(cl.CLEYE_EXPOSURE, exp)) {
            throw new HardwareInterfaceException("setting exposure to " + exp);
        }
        notifyObservers(EVENT_EXPOSURE);
    }

   /** Asks the driver for the exposure value.
     * 
     * @return exposure value 
     */
    public int getExposure() {
        int gain = getCameraParam(cl.CLEYE_EXPOSURE);
        return gain;
    }

    /** Enables auto gain
     * 
     * @param yes
     * @throws HardwareInterfaceException 
     */
    synchronized public void setAutoGain(boolean yes) throws HardwareInterfaceException {
       if(yes!=isAutoGain()) setChanged();
        if (!setCameraParam(cl.CLEYE_AUTO_GAIN, yes ? 1 : 0)) {
            throw new HardwareInterfaceException("setting auto gain=" + yes);
        }
        notifyObservers(EVENT_AUTOGAIN);
    }

    public boolean isAutoGain() {
        return getCameraParam(cl.CLEYE_AUTO_GAIN) != 0;
    }

    /** Enables auto exposure
     * 
     * @param yes
     * @throws HardwareInterfaceException 
     */
    synchronized public void setAutoExposure(boolean yes) throws HardwareInterfaceException {
        if(yes!=isAutoExposure()) setChanged();
        if (!setCameraParam(cl.CLEYE_AUTO_EXPOSURE, yes ? 1 : 0)) {
            throw new HardwareInterfaceException("setting auto exposure=" + yes);
        }
        notifyObservers(EVENT_AUTOEXPOSURE);
    }

    public boolean isAutoExposure() {
        return getCameraParam(cl.CLEYE_AUTO_EXPOSURE) != 0;
    }
}
