
package uk.ac.imperial.pseye;

import cl.eye.CLCamera;
import java.util.EnumMap;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Observable;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/*
 * Interface to wrap all driver constants and ranges.
 * @author mlk11
 */
public interface PSEyeDriverInterface {
    /* Enums representing possible colour modes */
    enum Mode {
        MONO(CLCamera.CLEYE_GRAYSCALE), 
        COLOUR(CLCamera.CLEYE_COLOR);
        
        private final int _v;
        Mode(int _v) { this._v = _v; }
        public int getValue() { return _v; }
    }
    
    /* Enums representing possible resolutions */
    enum Resolution {
        VGA(CLCamera.CLEYE_VGA), 
        QVGA(CLCamera.CLEYE_QVGA);

        private final int _v;
        Resolution(int _v) { this._v = _v; }
        public int getValue() { return _v; }
    }
    
    ArrayList<Mode> supportedModes = 
            new ArrayList<Mode>(Arrays.asList(Mode.values()));
    
    ArrayList<Resolution> supportedResolutions = 
            new ArrayList<Resolution>(Arrays.asList(Resolution.values()));
    
    /* Supported frame rates for each resolution */
    EnumMap<Resolution, ArrayList<Integer>> supportedFrameRates = 
            new EnumMap<Resolution, ArrayList<Integer>>(Resolution.class) {{
                put(Resolution.VGA, new ArrayList<Integer>(Arrays.asList(15, 30, 40, 50, 60, 75)));
                put(Resolution.QVGA, new ArrayList<Integer>(Arrays.asList(15, 30, 60, 75, 100, 125)));
    }};   
    
    /* Helper class for describing parameter ranges */
    class Range {
        public int max, min;
        Range(int min, int max) { this.min = min; this.max = max; }
    }
    
    /* Map of supported exposures for each resolution */
    EnumMap<Resolution, Range> supportedExposures = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 509));
                put(Resolution.QVGA, new Range(0, 277));
    }}; 

    /* Map of supported gain for each resolution */
    EnumMap<Resolution, Range> supportedGains = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 79));
                put(Resolution.QVGA, new Range(0, 79));
    }}; 
    
    /* Map of supported balance for each resolution */
    EnumMap<Resolution, Range> supportedBalances = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 255));
                put(Resolution.QVGA, new Range(0, 255));
    }}; 
    
    /* Map of data size */
    EnumMap<Mode, Integer> pixelSize = 
            new EnumMap<Mode, Integer>(Mode.class) {{
                put(Mode.MONO, 1);
                put(Mode.COLOUR, 1);
    }};     
    
    /* Map of frame sizes */
    EnumMap<Resolution, Integer> frameSizeX = 
            new EnumMap<Resolution, Integer>(Resolution.class) {{
                put(Resolution.QVGA, 320);
                put(Resolution.VGA, 640);
    }};
    
    /* Map of frame sizes */
    EnumMap<Resolution, Integer> frameSizeY = 
            new EnumMap<Resolution, Integer>(Resolution.class) {{
                put(Resolution.QVGA, 240);
                put(Resolution.VGA, 480);
    }};  

    double[] gamma = {0.5,2,3,4,5,6,7,8.5,10,11,12,13,14,15,16.5,18,19,20.5, 
        22,23,24.5,26,27,28.5,30,31,32.5,34,35.5,37,38,39.5,41,
        42.5,44,45,46.5,48,49.5,51,52,53.5,55,56.5,58,59,60.5,62, 
        63,64.5,66.5,68,69.5,71,72.5,74,75.5,77.5,79,80.5,82,83.5, 
        85,86.5,88,89.5,91.5,93,94.5,96,97.5,99,100.5,102.5,104, 
        105.5,107,108.5,110,111.5,113,114.5,116.5,118,119.5,121, 
        122.5,124,125.5,127,129,131.5,133.5,135.5,137.5,139.5, 
        141.5,144,146.5,148.5,150.5,152.5,154.5,156.5,158.5,161, 
        164,166.5,169,172,174.5,177,180,182.5,185,188,190.5,193.5, 
        197.5,201,204.5,208,211.5,215,218.5,222,225.5,229,232,235, 
        238,241.5,245,248,251,254,258,263,267.5,272,276.5,281,285.5, 
        290,295,299.5,304,308.5,313,317.5,322,327,332,337,342,347, 
        352,357,362,367,372,377,381.5,386.5,392,397,402.5,408,413, 
        418.5,424,429,434.5,440,445,451,457.5,463.5,469.5,475.5, 
        481.5,487.5,493.5,499.5,505.5,512,518.5,524.5,530.5,536.5, 
        542.5,548.5,554.5,560.5,566.5,572.5,579,586,593,599.5,606, 
        613,620,626.5,633,640,647,653.5,660,667,674,680.5,687,694, 
        700.5,707.5,715.5,723,730.5,738,745.5,753,760.5,768,775.5, 
        783,790.5,798,805.5,813,820.5,828,835.5,843.5,851.5,859.5, 
        867.5,875.5,883.5,891.5,899.5,907.5,915.5,923.5,931.5,939.5, 
        947.5,955.5,963.5,971.5,979.5,987.5,995.5,1003.5,1011.5,1019.5};
    
    /* Observable events; This event enum is fired when the parameter is changed. */
    enum EVENT { 
        MODE,
        RESOLUTION,
        FRAMERATE,
        GAIN,
        EXPOSURE,
        RED_BALANCE,
        GREEN_BALANCE,
        BLUE_BALANCE,
        AUTO_GAIN,
        AUTO_EXPOSURE,
        AUTO_BALANCE;
    }
    
    public Mode setMode(Mode mode) throws HardwareInterfaceException;
    public Mode getMode();
    
    public Resolution setResolution(Resolution resolution) throws HardwareInterfaceException;
    public Resolution getResolution();
    
    public int setFrameRate(int frameRate) throws HardwareInterfaceException;
    public int getFrameRate();
    
    public int setGain(int gain);
    public int getGain();
    
    public int setExposure(int exposure);
    public int getExposure();
    
    public int setRedBalance(int red);
    public int getRedBalance();
    
    public int setGreenBalance(int green);
    public int getGreenBalance();
    
    public int setBlueBalance(int blue);
    public int getBlueBalance();
    
    public boolean setAutoGain(boolean yes);
    public boolean getAutoGain();
    
    public boolean setAutoExposure(boolean yes);
    public boolean getAutoExposure();
    
    public boolean setAutoBalance(boolean yes);
    public boolean getAutoBalance();
    
    public ArrayList<Mode> getModes();
    public ArrayList<Resolution> getResolutions();
    public ArrayList<Integer> getFrameRates();
    
    public int getMaxExposure();
    public int getMinExposure();
    public int getMaxGain();
    public int getMinGain();
    public int getMaxBalance();
    public int getMinBalance();
    
    public Observable getObservable();
}


