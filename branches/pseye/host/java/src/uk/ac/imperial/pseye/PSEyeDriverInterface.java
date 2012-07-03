
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

    double[] gamma = {0.1251, 0.5002, 0.7504, 1.0005, 1.2506, 1.5007, 
        1.7509, 2.1260, 2.5012, 2.7513, 3.0015, 3.2516, 3.5017, 3.7518, 
        4.1270, 4.5022, 4.7523, 5.1275, 5.5027, 5.7528, 6.1280, 6.5032, 
        6.7533, 7.1285, 7.5037, 7.7538, 8.1290, 8.5042, 8.8794, 9.2545, 
        9.5047, 9.8798, 10.2550, 10.6302, 11.0054, 11.2555, 11.6307, 
        12.0059, 12.3811, 12.7563, 13.0064, 13.3816, 13.7567, 14.1319, 
        14.5071, 14.7572, 15.1324, 15.5076, 15.7577, 16.1329, 16.6332, 
        17.0083, 17.3835, 17.7587, 18.1339, 18.5091, 18.8843, 19.3845, 
        19.7597, 20.1349, 20.5101, 20.8852, 21.2604, 21.6356, 22.0108, 
        22.3860, 22.8862, 23.2614, 23.6366, 24.0118, 24.3870, 24.7621, 
        25.1373, 25.6376, 26.0128, 26.3879, 26.7631, 27.1383, 27.5135, 
        27.8887, 28.2639, 28.6390, 29.1393, 29.5145, 29.8897, 30.2648, 
        30.6400, 31.0152, 31.3904, 31.7656, 32.2658, 32.8911, 33.3914, 
        33.8916, 34.3919, 34.8921, 35.3923, 36.0177, 36.6430, 37.1432, 
        37.6435, 38.1437, 38.6439, 39.1442, 39.6444, 40.2697, 41.0201, 
        41.6454, 42.2707, 43.0211, 43.6464, 44.2717, 45.0221, 45.6474, 
        46.2727, 47.0231, 47.6484, 48.3987, 49.3992, 50.2746, 51.1501, 
        52.0255, 52.9009, 53.7764, 54.6518, 55.5272, 56.4026, 57.2781, 
        58.0284, 58.7788, 59.5292, 60.4046, 61.2800, 62.0304, 62.7808, 
        63.5311, 64.5316, 65.7822, 66.9078, 68.0333, 69.1589, 70.2845, 
        71.4100, 72.5356, 73.7862, 74.9117, 76.0373, 77.1628, 78.2884, 
        79.4139, 80.5395, 81.7901, 83.0407, 84.2913, 85.5419, 86.7925, 
        88.0432, 89.2938, 90.5444, 91.7950, 93.0456, 94.2962, 95.4218, 
        96.6724, 98.0481, 99.2987, 100.6744, 102.0500, 103.3006, 104.6763, 
        106.0520, 107.3026, 108.6783, 110.0539, 111.3046, 112.8053, 
        114.4311, 115.9318, 117.4326, 118.9333, 120.4340, 121.9348, 
        123.4355, 124.9362, 126.4370, 128.0628, 129.6886, 131.1893, 
        132.6900, 134.1908, 135.6915, 137.1923, 138.6930, 140.1937, 
        141.6945, 143.1952, 144.8210, 146.5718, 148.3227, 149.9485, 
        151.5743, 153.3252, 155.0760, 156.7018, 158.3276, 160.0785, 
        161.8293, 163.4551, 165.0809, 166.8318, 168.5826, 170.2084, 
        171.8342, 173.5851, 175.2109, 176.9617, 178.9627, 180.8386, 
        182.7146, 184.5905, 186.4664, 188.3423, 190.2182, 192.0942, 
        193.9701, 195.8460, 197.7219, 199.5978, 201.4738, 203.3497, 
        205.2256, 207.1015, 208.9774, 210.9784, 212.9794, 214.9804, 
        216.9814, 218.9823, 220.9833, 222.9843, 224.9853, 226.9863, 
        228.9872, 230.9882, 232.9892, 234.9902, 236.9912, 238.9922, 
        240.9931, 242.9941, 244.9951, 246.9961, 248.9971, 250.9980, 
        252.9990, 255.0000};
        /*
        {0.5,2,3,4,5,6,7,8.5,10,11,12,13,14,15,16.5,18,19,20.5, 
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
        */
    
    /* Observable events; This event enum is fired when the parameter is changed. */
    enum EVENT_CAMERA { 
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


