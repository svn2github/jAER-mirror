
package uk.ac.imperial.pseye;

import cl.eye.CLCamera;
import java.util.EnumMap;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/*
 * Interface to wrap all driver constants and ranges.
 * @author mlk11
 */
public interface PSEyeDriverInterface {
    /* Enums representing possible colour modes */
    public static enum Mode {
        MONO(CLCamera.CLEYE_GRAYSCALE), 
        COLOUR(CLCamera.CLEYE_COLOR);
        
        private final int _v;
        Mode(int _v) { this._v = _v; }
        public int getValue() { return _v; }
    }
    
    /* Enums representing possible resolutions */
    public static enum Resolution {
        VGA(CLCamera.CLEYE_VGA), 
        QVGA(CLCamera.CLEYE_QVGA);

        private final int _v;
        Resolution(int _v) { this._v = _v; }
        public int getValue() { return _v; }
    }
    
    public static final ArrayList<Mode> supportedMode = 
            new ArrayList<Mode>(Arrays.asList(Mode.values()));
    
    public static final ArrayList<Resolution> supportedResolution = 
            new ArrayList<Resolution>(Arrays.asList(Resolution.values()));
    
    /* Supported frame rates for each resolution */
    public static final EnumMap<Resolution, List<Integer>> supportedFrameRate = 
            new EnumMap<Resolution, List<Integer>>(Resolution.class) {{
                put(Resolution.VGA, Arrays.asList(15, 30, 40, 50, 60, 75));
                put(Resolution.QVGA, Arrays.asList(15, 30, 60, 75, 100, 125));
    }};   
    
    /* Helper class for describing parameter ranges */
    public static class Range {
        public int max, min;
        Range(int min, int max) { this.min = min; this.max = max; }
        
        int trimValue(int val) {
            return val > max ? max : (val < min ? min : val);
        }
    }
    
    /* Map of supported exposures for each resolution */
    public static final EnumMap<Resolution, Range> supportedExposure = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 509));
                put(Resolution.QVGA, new Range(0, 277));
    }}; 

    /* Map of supported gain for each resolution */
    public static final EnumMap<Resolution, Range> supportedGain = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 79));
                put(Resolution.QVGA, new Range(0, 79));
    }}; 
    
    /* Map of supported balance for each resolution */
    public static final EnumMap<Resolution, Range> supportedBalance = 
            new EnumMap<Resolution, Range>(Resolution.class) {{
                put(Resolution.VGA, new Range(0, 255));
                put(Resolution.QVGA, new Range(0, 255));
    }}; 
    
    /* Map of data size */
    public static final EnumMap<Mode, Integer> pixelByte = 
            new EnumMap<Mode, Integer>(Mode.class) {{
                put(Mode.MONO, 1);
                put(Mode.COLOUR, 3);
    }};     
    
    /* Map of frame sizes */
    public static final EnumMap<Resolution, Integer> frameSizeMap = 
            new EnumMap<Resolution, Integer>(Resolution.class) {{
                put(Resolution.QVGA, 320 * 240);
                put(Resolution.VGA, 640 * 480);
    }};   

    /* Observable events; This event enum is fired when the parameter is changed. */
    public static enum EVENT { 
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
}


