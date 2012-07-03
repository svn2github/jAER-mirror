
package uk.ac.imperial.pseye.seebetter;

import eu.seebetter.ini.chips.seebetter20.PolarityADCSampleEvent;
import eu.seebetter.ini.chips.seebetter20.SeeBetter20.SeeBetter20Renderer;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import java.util.ArrayList;
import java.util.Random;
import java.util.logging.Level;
import net.sf.jaer.Description;
import net.sf.jaer.event.OutputEventIterator;
import javax.swing.JPanel;
import net.sf.jaer.chip.TypedEventExtractor;
import net.sf.jaer.event.BasicEvent;
import uk.ac.imperial.pseye.PSEyeDriverInterface;
import uk.ac.imperial.pseye.PSEyeModelAEChip;
import uk.ac.imperial.vsbe.CameraAEPacketRaw;
import uk.ac.imperial.vsbe.CameraChipBiasgen;

/**
 * @author Mat Katz
 */
@Description("SeeBetter emulator using the PS-Eye Playstation camera")
public class PSEyeModelSeeBetter extends PSEyeModelAEChip implements SeeBetterChipInterface {
    public static final int MAX_EVENTS = 1000000;
    public static final long SEED = 328923423;
    public static final int NLEVELS = 255;
    
    public static final int MAX_ADC = 255;
    
    protected PSEyeSeeBetterPanel chipPanel = null;
    
    ArrayList<Mode> modes = new ArrayList<Mode>() {{
        add(Mode.MONO);
    }};
    
    protected double sigmaOnThreshold = 10;
    protected double sigmaOffThreshold = 10;
    protected double sigmaOnDeviation = 0;
    protected double sigmaOffDeviation = 0;
    
    protected double[] sigmaOnThresholds = null;
    protected double[] sigmaOffThresholds = null;
    
    protected double backgroundEventRatePerPixelHz = 10;
    protected Random bgRandom = new Random();
    protected int bgIntervalUs = Integer.MAX_VALUE;
    // array of last event times for each pixel, for use in emitting background events. We initialize this to a random number 
    // in the frame interval to avoid synchrounous bursts of background events
    protected long[] lastEventTimes = null;
    
    protected boolean isRawData = false;
    protected boolean isGamma = false;
    
    protected boolean isLensCorrection = false;
    protected double[] lensCorrection = null;
    
    protected boolean isLogValue = false;
    protected double[] logValues = null;
    
    protected boolean linearInterpolateTimeStamp;
    protected ArrayList<Integer> discreteEventCount = new ArrayList<Integer>();
    private BasicEvent tempEvent = new BasicEvent();
    
    protected double logTransitionValue = 20;
    protected double expWeight = 2;
    
    protected boolean initialised = false;
    protected boolean sampleADC = false;
    
    protected long currentFrameTimestamp;
    protected long lastFrameTimestamp;
    
    protected boolean useDVSExtrapolation = false;
    protected boolean displayIntensity = true;
    protected boolean displayLogIntensityChangeEvents = true;
    protected int subSampleRate = 30;
    protected int totalFrames = 0;
    
    // counters
    protected int eventCount;
    protected int frameCount;
    protected int timeCount;
    
    //protected ArrayList<Integer> pixelIndices = new ArrayList<Integer>();
    protected int[] pixelValues;
    protected double[] previousValues;
    protected int nPixels;
    
    protected double tempValue;

    @Override
    public JPanel getChipPanel() {
        if (chipPanel == null) 
            chipPanel = new PSEyeSeeBetterPanel(this);
        return chipPanel;
    }

    public int getSubSampleRate() {
        return subSampleRate;
    }

    public void setSubSampleRate(int subSampleRate) {
        this.subSampleRate = subSampleRate;
    }

    @Override
    public int getApsIntensityGain() {
        return 1;
    }

    @Override
    public void setApsIntensityGain(int apsIntensityGain) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public int getApsIntensityOffset() {
        return 0;
    }

    @Override
    public void setApsIntensityOffset(int apsIntensityOffset) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean getAgcEnabled() {
        return false;
    }

    @Override
    public void setAgcEnabled(boolean agcEnabled) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void setAGCTauMs(float tauMs) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public float getTauMs() {
        return 1;
    }

    @Override
    public int getMaxADC() {
        return 255;
    }
    
    enum EVENT_MODEL { 
        GAMMA,
        LENS_CORRECTION,
        LOG_VALUE,
        RAW_DATA,
        SIGMA_OFF,
        SIGMA_ON,        
        LOG_TRANSISTION,
        EXP_WEIGHT,
        SIGMA_ON_STD,
        SIGMA_OFF_STD,
        INTERPOLATE,
        BACKGROUND_RATE
    }
    
    public PSEyeModelSeeBetter () {
        super();
        loadPreferences();
        
        setBiasgen(new CameraChipBiasgen<PSEyeModelSeeBetter>(this));
        camera.addObserver(this);
        init();
        setEventExtractor(new SeeBetterExtractor(this));
        setRenderer((renderer = new SeeBetterRenderer<PSEyeModelSeeBetter>(this)));
    }
    
    @Override 
    public ArrayList<Mode> getModes() { 
        return modes;
    }
    
    protected void init() {
        setSizeX(camera.getFrameX());
        setSizeY(camera.getFrameY());
        nPixels = camera.getFrameX() * camera.getFrameY();  
        fillSigmaThresholds();
        lastEventTimes = new long[nPixels];
        for (int i = 0; i < nPixels; i++) {
            lastEventTimes[i] = bgRandom.nextInt(16000); // initialize to random time in 16ms
        }
        fillLensCorrection();
        initialised = false;
    }
    
    @Override
    public void storePreferences() {
        getPrefs().putInt("subSampleRate", subSampleRate);
        
        getPrefs().putDouble("sigmaOnThreshold", sigmaOnThreshold);
        getPrefs().putDouble("sigmaOffThreshold", sigmaOffThreshold);
        getPrefs().putDouble("sigmaOnDeviation", sigmaOnDeviation);
        getPrefs().putDouble("sigmaOffDeviation", sigmaOffDeviation);
        
        getPrefs().putDouble("backgroundEventRatePerPixelHz",  backgroundEventRatePerPixelHz);
        
        getPrefs().putBoolean("isRawData", isRawData);
        getPrefs().putBoolean("isGamma", isGamma);
        getPrefs().putBoolean("isLensCorrection", isLensCorrection);        
        getPrefs().putBoolean("linearInterpolateTimeStamp", linearInterpolateTimeStamp);

        getPrefs().putBoolean("isLogValue", isLogValue);
        getPrefs().putDouble("logTransitionValue", logTransitionValue);
        getPrefs().putDouble("expWeight", expWeight);
        
        super.storePreferences();
    }
    
    @Override
    public void loadPreferences() {
        subSampleRate = getPrefs().getInt("subSampleRate", subSampleRate);
        
        sigmaOnThreshold = getPrefs().getDouble("sigmaOnThreshold", sigmaOnThreshold);
        sigmaOffThreshold = getPrefs().getDouble("sigmaOffThreshold", sigmaOffThreshold);
        sigmaOnDeviation = getPrefs().getDouble("sigmaOnDeviation", sigmaOnDeviation);
        sigmaOffDeviation = getPrefs().getDouble("sigmaOffDeviation", sigmaOffDeviation);
        
        backgroundEventRatePerPixelHz = getPrefs().getDouble("backgroundEventRatePerPixelHz",  backgroundEventRatePerPixelHz);

        isRawData = getPrefs().getBoolean("isRawData", isRawData);
        isGamma = getPrefs().getBoolean("isGamma", isGamma);
        isLensCorrection = getPrefs().getBoolean("isLensCorrection", isLensCorrection);        
        linearInterpolateTimeStamp = getPrefs().getBoolean("linearInterpolateTimeStamp", linearInterpolateTimeStamp);

        isLogValue = getPrefs().getBoolean("isLogValue", isLogValue);
        logTransitionValue = getPrefs().getDouble("logTransitionValue", logTransitionValue);
        expWeight = getPrefs().getDouble("expWeight", expWeight);
        
        super.loadPreferences();
    }

    @Override
    public String getName() {
        return "PSEyeModelDVS";
    }

    public boolean getDisplayIntensity() {
        return displayIntensity;
    }

    public void setDisplayIntensity(boolean displayIntensity) {
        this.displayIntensity = displayIntensity;
    }

    public boolean getDisplayLogIntensityChangeEvents() {
        return displayLogIntensityChangeEvents;
    }

    public void setDisplayLogIntensityChangeEvents(boolean displayLogIntensityChangeEvents) {
        this.displayLogIntensityChangeEvents = displayLogIntensityChangeEvents;
    }

    public boolean getUseDVSExtrapolation() {
        return useDVSExtrapolation;
    }

    public void setUseDVSExtrapolation(boolean useDVSExtrapolation) {
        this.useDVSExtrapolation = useDVSExtrapolation;
    }

    
    
    public boolean getIsGamma() {
        return isGamma;
    }

    public void setIsGamma(boolean isGamma) {
        if(isGamma != getIsGamma()) {
            this.isGamma = isGamma;
            setChanged();
            notifyObservers(EVENT_MODEL.GAMMA);
        }
    }

    public boolean getIsLensCorrection() {
        return isLensCorrection;
    }

    public void setIsLensCorrection(boolean isLensCorrection) {
        if (isLensCorrection != getIsLensCorrection()) {
            this.isLensCorrection = isLensCorrection;
            setChanged();
            notifyObservers(EVENT_MODEL.LENS_CORRECTION);
        }
    }

    public boolean getIsLogValue() {
        return isLogValue;
    }

    public void setIsLogValue(boolean isLogValue) {
        if (isLogValue != getIsLogValue()) {
            this.isLogValue = isLogValue;
            setChanged();
            notifyObservers(EVENT_MODEL.LOG_VALUE);
        }
    }

    public boolean getIsRawData() {
        return isRawData;
    }

    public void setIsRawData(boolean isRawData) {
        if (isRawData != getIsRawData()) {
            this.isRawData = isRawData;
            setChanged();
            notifyObservers(EVENT_MODEL.RAW_DATA);
        }
    }

    public double getLogTransitionValue() {
        return logTransitionValue;
    }

    public void setLogTransitionValue(double logTransitionValue) {
        if (logTransitionValue != getLogTransitionValue()) {
            this.logTransitionValue = logTransitionValue;
            setChanged();
            notifyObservers(EVENT_MODEL.LOG_TRANSISTION);
        }
    }

    public double getExpWeight() {
        return expWeight;
    }

    public void setExpWeight(double expWeight) {
        if (expWeight != getExpWeight()) {
            this.expWeight = expWeight;
            setChanged();
            notifyObservers(EVENT_MODEL.EXP_WEIGHT);
        }        
    }

    public double getSigmaOffThreshold() {
        return sigmaOffThreshold;
    }

    synchronized public void setSigmaOffThreshold(double sigmaOffThreshold) {
        if (sigmaOffThreshold > NLEVELS) {
            log.log(Level.WARNING, "Sigma Off Threshold {0} above maximum, setting to max {1}", 
                    new Object[] {sigmaOffThreshold, NLEVELS});
            sigmaOffThreshold = NLEVELS;
        }
        
        if (sigmaOffThreshold < 0) {
            log.log(Level.WARNING, "Sigma Off Threshold {0} below minimum, setting to min {1}", 
                    new Object[] {sigmaOffThreshold, 0});
            sigmaOffThreshold = 0;            
        }  
        
        if(sigmaOffThreshold != getSigmaOffThreshold()) {
            this.sigmaOffThreshold = sigmaOffThreshold;
            fillSigmaThresholds();
            setChanged();
            notifyObservers(EVENT_MODEL.SIGMA_OFF);
        }
    }

    public double getSigmaOffDeviation() {
        return sigmaOffDeviation;
    }

    public void setSigmaOffDeviation(double sigmaOffDeviation) {
        if (sigmaOffDeviation != getSigmaOffDeviation()) {
            this.sigmaOffDeviation = sigmaOffDeviation;
            fillSigmaThresholds();
            setChanged();
            notifyObservers(EVENT_MODEL.SIGMA_OFF_STD);
        } 
    }
    
    public double getSigmaOnThreshold() {
        return sigmaOnThreshold;
    }

    synchronized public void setSigmaOnThreshold(double sigmaOnThreshold) {
        if (sigmaOnThreshold > NLEVELS) {
            log.log(Level.WARNING, "Sigma On Threshold {0} above maximum, setting to max {1}", 
                    new Object[] {sigmaOnThreshold, NLEVELS});
            sigmaOnThreshold = NLEVELS;
        }
        
        if (sigmaOnThreshold < 0) {
            log.log(Level.WARNING, "Sigma On Threshold {0} below minimum, setting to min {1}", 
                    new Object[] {sigmaOnThreshold, 0});
            sigmaOnThreshold = 0;            
        }  
        
        if(sigmaOnThreshold != getSigmaOnThreshold()) {
            this.sigmaOnThreshold = sigmaOnThreshold;
            fillSigmaThresholds();
            setChanged();
            notifyObservers(EVENT_MODEL.SIGMA_ON);
        }
    }

    public double getSigmaOnDeviation() {
        return sigmaOnDeviation;
    }

    public void setSigmaOnDeviation(double sigmaOnDeviation) {
        if (sigmaOnDeviation != getSigmaOnDeviation()) {
            this.sigmaOnDeviation = sigmaOnDeviation;
            fillSigmaThresholds();
            setChanged();
            notifyObservers(EVENT_MODEL.SIGMA_ON_STD);
        }    
    }
    
    public boolean getLinearInterpolateTimeStamp() {
        return linearInterpolateTimeStamp;
    }

    public void setLinearInterpolateTimeStamp(boolean linearInterpolateTimeStamp) {
        if (this.linearInterpolateTimeStamp != linearInterpolateTimeStamp) {
            setChanged();
            this.linearInterpolateTimeStamp = linearInterpolateTimeStamp;
            notifyObservers(EVENT_MODEL.INTERPOLATE);
        }
    }
    
    public double getBackgroundEventRatePerPixelHz() {
        return backgroundEventRatePerPixelHz;
    }

    public void setBackgroundEventRatePerPixelHz(double backgroundEventRatePerPixelHz) {
        if (backgroundEventRatePerPixelHz < 0) {
            backgroundEventRatePerPixelHz = 0;
        }
        if (this.backgroundEventRatePerPixelHz != backgroundEventRatePerPixelHz) {
            this.backgroundEventRatePerPixelHz = backgroundEventRatePerPixelHz;
            bgIntervalUs = (int) (1e6f / backgroundEventRatePerPixelHz);
            for (int i = 0; i < nPixels; i++) {
                lastEventTimes[i] = currentFrameTimestamp + (long) ((bgRandom.nextDouble() + 0.5) * bgIntervalUs);
            }
            setChanged();
            notifyObservers(EVENT_MODEL.BACKGROUND_RATE);
        }
    }
    
    protected double logValue(double value) {
        if (value >= logTransitionValue) {
            return Math.log(value);
        }
        else {
            return value * Math.log(logTransitionValue) /  logTransitionValue *
                Math.exp(value * expWeight / logTransitionValue) / Math.exp(expWeight);
        }
    }
    
    protected double calculateLensCorrection(int pixelIndex) {
        int ext = getSizeX();
        int x = pixelIndex % ext + 1;
        int y = (int) Math.floor(pixelIndex / ext) + 1;
        double a = -1.011;
        double b = 3.359;
        double c = -8.333;
        double z1 = 0.4949;
        double z2 = 0.4676;
        double o = 1.052;
        double n = 1.1067;
        
        return (a * Math.pow(x / ext - z1, 2) + 
                b * Math.pow(x / ext - z1, 4) +
                c * Math.pow(x / ext - z1, 6) + o) * 
               (a * Math.pow(y / ext - z2, 2) + 
                b * Math.pow(y / ext - z2, 4) + 
                c * Math.pow(y / ext - z2, 6) + o) / n;
    }

    protected void fillLensCorrection() {
        lensCorrection = new double[nPixels];
        for (int i = 0; i < nPixels; i++) {
            lensCorrection[i] = calculateLensCorrection(i);
        } 
    }
    
    protected int getRawData(int x, int y, int value) {
        if (x % 2 == 0) {
            if (y % 2 == 0) return (value & 0xff00) >> 8;
            else return (value & 0xff0000) >> 16;
        }
        else {
            if (y % 2 == 0) return value & 0xff;
            else return (value & 0xff00) >> 8;
        }       
    }
    
    protected double transformValue(int pixelIndex, int value) {
        //if (isRawData) {
        //    value = getRawData(x, y, value);
        //}
        //else value = value & 0xff;
        value = value & 0xff;
        
        if (isGamma) {
            tempValue = PSEyeDriverInterface.gamma[value];
        }
        else tempValue = (double) value;
        
        if (isLensCorrection) tempValue = tempValue * lensCorrection[pixelIndex];
        if (isLogValue) {
            tempValue = logValue(tempValue) * 46.0184; // 255 / log(255)
        }
                
        return tempValue;
    }
    
    private void fillSigmaThresholds() {
        Random r = new Random(SEED);
        if (sigmaOnThresholds == null || sigmaOnThresholds.length != nPixels) {
            sigmaOnThresholds = new double[nPixels];
        }
        if (sigmaOffThresholds == null || sigmaOffThresholds.length != nPixels) {
            sigmaOffThresholds = new double[nPixels];
        }
        for (int i = 0; i < nPixels; i++) {
            sigmaOnThresholds[i] = sigmaOnThreshold * (1 + sigmaOnDeviation * r.nextGaussian());
            sigmaOffThresholds[i] = -(sigmaOffThreshold * (1 + sigmaOffDeviation * r.nextGaussian()));
        }
    }
    
    class SeeBetterExtractor extends TypedEventExtractor<PolarityADCSampleEvent> {
        private double valueDelta;
        private int number;
        private int x;
        private int y;
    
        public SeeBetterExtractor(PSEyeModelSeeBetter aechip) {
            super(aechip);
        }

        
        protected void createEvents(int pixelIndex, OutputEventIterator itr) {
            x = pixelIndex % chip.getSizeX();
            y = (int) Math.floor(pixelIndex / chip.getSizeX()); 
            valueDelta = transformValue(pixelIndex, pixelValues[pixelIndex]);
            if ((totalFrames % subSampleRate) == 0) {
                outputADCEvents(itr, x, y, valueDelta);
                totalFrames = 0;
            }
            valueDelta = valueDelta - previousValues[pixelIndex];
            
            // brightness change 
            if (valueDelta > sigmaOnThresholds[pixelIndex]) { // if our gray level is sufficiently higher than the stored gray level
                number = (int) Math.floor(valueDelta / sigmaOnThresholds[pixelIndex]);
                outputDVSEvents(PolarityEvent.Polarity.On, number, itr, x, y);
                previousValues[pixelIndex] += sigmaOnThresholds[pixelIndex] * number; // update stored gray level by events // TODO include mismatch
                lastEventTimes[pixelIndex] = currentFrameTimestamp + (long) (bgRandom.nextDouble() * 2 * bgIntervalUs);
            } 
            else if (valueDelta < sigmaOffThresholds[pixelIndex]) { // if our gray level is sufficiently higher than the stored gray level
                number = (int) Math.floor(valueDelta / sigmaOffThresholds[pixelIndex]);
                outputDVSEvents(PolarityEvent.Polarity.Off, number, itr, x, y);
                previousValues[pixelIndex] += sigmaOffThresholds[pixelIndex] * number; // update stored gray level by events // TODO include mismatch
                lastEventTimes[pixelIndex] = currentFrameTimestamp + (long) (bgRandom.nextDouble() * 2 * bgIntervalUs);
            } 
            // emit background event possibly
            else if (backgroundEventRatePerPixelHz > 0 && (currentFrameTimestamp - lastEventTimes[pixelIndex]) > bgIntervalUs) {
                // randomly emit either Brighter or Redder event TODO check Redder/Bluer
                PolarityEvent.Polarity bgType = bgRandom.nextBoolean() ? PolarityEvent.Polarity.On : PolarityEvent.Polarity.Off;
                outputDVSEvents(bgType, 1, itr, x, y);
                lastEventTimes[pixelIndex] = currentFrameTimestamp + (long) (bgRandom.nextDouble() * 2 * bgIntervalUs);
            }
        }
        
        protected void outputADCEvents(OutputEventIterator itr, int x, int y, double value) {
            PolarityADCSampleEvent e = (PolarityADCSampleEvent) itr.nextOutput();
            e.x = (short) x;
            e.y = (short) (chip.getSizeY() - y - 1); // flip y according to jAER with 0,0 at LL
            if (e.x == 120 && e.y == 100) {
                value = value;
            }
            e.setAdcSample((int) Math.floor(value));
            e.timestamp = (int) currentFrameTimestamp;
                               
            e.setReadoutType(PolarityADCSampleEvent.Type.A);
        }
        
        protected void outputDVSEvents(PolarityADCSampleEvent.Polarity type, int number, OutputEventIterator itr, int x, int y) {
            for (int j = 0; j < number; j++) { // use down iterator as ensures latest timestamp as last event
                if (eventCount >= MAX_EVENTS) break;
                PolarityADCSampleEvent e = (PolarityADCSampleEvent) itr.nextOutput();
                e.x = (short) x;
                e.y = (short) (chip.getSizeY() - y - 1); // flip y according to jAER with 0,0 at LL
                e.setAdcSample(-1);
                               
                e.polarity = type;
                if (linearInterpolateTimeStamp) {
                    e.timestamp = (int) (currentFrameTimestamp - j * (currentFrameTimestamp - lastFrameTimestamp) / number);
                    orderedLastSwap(out, j);
                } else {
                    e.timestamp = (int) currentFrameTimestamp;
                }
                eventCount++;
            }

        }
        
        @Override
        public void extractPacket(AEPacketRaw in, EventPacket out) {
            // check to see that framepacket has correct number of pixel
            if (!(in instanceof CameraAEPacketRaw))
                return;
        
            CameraAEPacketRaw framePacket = (CameraAEPacketRaw) in;
            if (nPixels != framePacket.getFrameSize())
                init();
        
            int nFrames = framePacket.getNumFrames();
        
            pixelValues = in.getAddresses(); // pixel RGB values stored here by hardware interface
            OutputEventIterator itr = out.outputIterator();
        
            //OutputEventIterator itr = out.outputIterator();
            if (linearInterpolateTimeStamp) {
                discreteEventCount.clear();
            }

            if (out.getEventClass() != PolarityADCSampleEvent.class) {
                out.setEventClass(PolarityADCSampleEvent.class); // set the proper output event class to include color change events
            }

            currentFrameTimestamp = 0;
            eventCount = 0;
            for (int fr = 0; fr < nFrames; fr++) {
                // get timestamp for events in this frame
                if (initialised) {
                    currentFrameTimestamp = in.getTimestamp(fr * nPixels); // timestamps stored here, currently only first timestamp meaningful TODO multiple frames stored here
             
                    for (int i = 0; i < nPixels; i++) {
                        createEvents(i, itr);
                        if (eventCount >= MAX_EVENTS) {
                            log.warning("Maximum events (" + MAX_EVENTS +") exceeded ignoring further output");
                            break;
                        }
                    }
                }
                else {
                    currentFrameTimestamp = in.getTimestamp(0);
                    previousValues = new double[nPixels];
                    for (int i = 0; i < nPixels; i++) {
                        previousValues[i] = transformValue(i, pixelValues[i]);
                        lastEventTimes[i] = currentFrameTimestamp;
                    } 
                    initialised = true;
                }

                timeCount += currentFrameTimestamp - lastFrameTimestamp;
                lastFrameTimestamp = currentFrameTimestamp;
                frameCount++;    
                totalFrames++;
            
                if (frameCount >= (3 * getFrameRate())) {
                    log.warning("Frame Rate: " + frameCount * 1000000.0f / timeCount);
                    frameCount = 0;
                    timeCount = 0;
                }
            }
        }
        
        /*
        * Used to reorder event packet using interpolated time step.
        * Much faster then using Arrays.sort on event packet
        */
        private void orderedLastSwap(EventPacket out, int timeStep) {
            while (discreteEventCount.size() <= timeStep) {
                discreteEventCount.add(0);
            }
            discreteEventCount.set(timeStep, discreteEventCount.get(timeStep) + 1);
            if (timeStep > 0) {
                int previousStepCount = 0;
                for (int i = 0; i < timeStep; i++) {
                    previousStepCount += (int) discreteEventCount.get(i);
                }
                int size = out.getSize() - 1;
                swap(out, size, size - previousStepCount);
            }
        }

        /*
        * Exchange positions of two events in packet
        */
        private void swap(EventPacket out, int index1, int index2) {
            BasicEvent[] elementData = out.getElementData();
            tempEvent = elementData[index1];
            elementData[index1] = elementData[index2];
            elementData[index2] = tempEvent;
        }
    }
}

