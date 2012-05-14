
package uk.ac.imperial.pseye.dvs;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import java.util.ArrayList;
import java.util.Arrays;
import net.sf.jaer.Description;
import net.sf.jaer.event.OutputEventIterator;
import java.util.prefs.Preferences;
import net.sf.jaer.chip.TypedEventExtractor;
import uk.ac.imperial.pseye.PSEyeDriverInterface;
import uk.ac.imperial.pseye.PSEyeModelAEChip;
import uk.ac.imperial.vsbe.CameraAEPacketRaw;

/**
 * @author Mat Katz
 */
@Description("DVS emulator using the PS-Eye Playstation camera")
public class PSEyeModelDVS extends PSEyeModelAEChip {
    public static final int MAX_EVENTS = 1000000;
    
    ArrayList<Mode> modes = new ArrayList<Mode>() {{
        add(Mode.COLOUR);
    }};
    
    protected double sigmaOnThreshold = 10;
    protected double sigmaOffThreshold = -10;
    protected double sigmaOnDeviation = 0.02;
    protected double sigmaOffDeviation = 0.02;
    
    protected double logTransitionValue = 20;
    protected double expWeight = 2;
    
    protected boolean initialised = false;
    protected int currentFrameTimestamp;
    protected int lastFrameTimestamp;
    
    // counters
    protected int eventCount;
    protected int frameCount;
    protected int timeCount;
    
    //protected ArrayList<Integer> pixelIndices = new ArrayList<Integer>();
    protected int[] pixelValues;
    protected double[] previousValues;
    protected int nPixels;
    
    public PSEyeModelDVS () {
        super();
        setSizeX(camera.getFrameX());
        setSizeY(camera.getFrameY());
        setEventExtractor(new DVSExtractor(this));
    }
    
    @Override 
    public ArrayList<Mode> getModes() { 
        return modes;
    }
    
    protected void storePreferences(Preferences prefs) {
        prefs.putDouble("sigmaOnThreshold", sigmaOnThreshold);
        prefs.putDouble("sigmaOffThreshold", sigmaOffThreshold);
        prefs.putDouble("sigmaOnDeviation", sigmaOnDeviation);
        prefs.putDouble("sigmaOffDeviation", sigmaOffDeviation);
        
        //prefs.putBoolean("linearInterpolateTimeStamp", linearInterpolateTimeStamp);
        //prefs.putBoolean("logIntensityMode", logIntensityMode);
        //prefs.putInt("linLogTransitionValue", linLogTransitionValue);
    }
    
    protected void loadPreferences(Preferences prefs) {
        sigmaOnThreshold = prefs.getDouble("sigmaOnThreshold", 10);
        sigmaOffThreshold = prefs.getDouble("sigmaOffThreshold", -10);
        sigmaOnDeviation = prefs.getDouble("sigmaOnDeviation", 0.02);
        sigmaOffDeviation = prefs.getDouble("sigmaOffDeviation", 0.02);
        
        //linearInterpolateTimeStamp = prefs.getBoolean("linearInterpolateTimeStamp", false);
        //logIntensityMode = prefs.getBoolean("logIntensityMode", true);
        //linLogTransitionValue = prefs.getInt("linLogTransitionValue", 15);
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
    
    protected double lensCorrection(int x, int y) {
        double a = -1.011;
        double b = 3.359;
        double c = -8.333;
        double z1 = 0.4949;
        double z2 = 0.4676;
        double o = 1.052;
        int ext = getSizeX();
        return (a * Math.pow(x / ext - z1, 2) + 
                b * Math.pow(x / ext - z1, 4) +
                c * Math.pow(x / ext - z1, 6) + o) * 
               (a * Math.pow(y / ext - z2, 2) + 
                b * Math.pow(y / ext - z2, 4) + 
                c * Math.pow(y / ext - z2, 6) + o);
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
    
    protected double transformValue(int x, int y, int value) {
        double v;
        if (value> 10){
            value = value * 2;
        }
        value = getRawData(x, y, value);

        //v = PSEyeDriverInterface.gamma[value];
        //v = v * lensCorrection(x, y);
        return value & 0xff;//logValue(value);
    }
    
    class DVSExtractor extends TypedEventExtractor<PolarityEvent> {
        private double valueDelta;
        private int number;
        private int x;
        private int y;
    
        public DVSExtractor(PSEyeModelDVS aechip) {
            super(aechip);
        }

        
        protected void createEvents(int pixelIndex, OutputEventIterator itr) {
                            x = pixelIndex % chip.getSizeX();
            y = (int) Math.floor(pixelIndex / chip.getSizeX()); 
            valueDelta = (transformValue(x, y, pixelValues[pixelIndex])) - previousValues[pixelIndex]; 
            // brightness change 
            if (valueDelta > sigmaOnThreshold) { // if our gray level is sufficiently higher than the stored gray level
                            x = pixelIndex % chip.getSizeX();
            y = (int) Math.floor(pixelIndex / chip.getSizeX()); 
                number = (int) Math.floor(valueDelta / sigmaOnThreshold);
                outputEvents(PolarityEvent.Polarity.On, number, itr, x, y);
                previousValues[pixelIndex] += sigmaOnThreshold * number; // update stored gray level by events // TODO include mismatch
            } 
            else if (valueDelta < sigmaOffThreshold) { // if our gray level is sufficiently higher than the stored gray level
                            x = pixelIndex % chip.getSizeX();
            y = (int) Math.floor(pixelIndex / chip.getSizeX()); 
                number = (int) Math.floor(valueDelta / sigmaOffThreshold);
                outputEvents(PolarityEvent.Polarity.Off, number, itr, x, y);
                previousValues[pixelIndex] += sigmaOffThreshold * number; // update stored gray level by events // TODO include mismatch
            } 
        }
        
        protected void initValues(int pixelIndex) {
            previousValues[pixelIndex] = pixelValues[pixelIndex] & 0xff;
        }
        
        protected void outputEvents(PolarityEvent.Polarity type, int number, OutputEventIterator itr, int x, int y) {
            for (int j = 0; j < number; j++) { // use down iterator as ensures latest timestamp as last event
                if (eventCount >= MAX_EVENTS) break;
                PolarityEvent e = (PolarityEvent) itr.nextOutput();
                e.x = (short) x;
                e.y = (short) (chip.getSizeY() - y); // flip y according to jAER with 0,0 at LL
                
                e.polarity = type;
                //if (linearInterpolateTimeStamp) {
                //    e.timestamp = currentFrameTimestamp - j * (currentFrameTimestamp - lastFrameTimestamp) / number;
                //} else {
                    e.timestamp = currentFrameTimestamp;
                //}
                eventCount++;
            }

        }
        
        @Override
        public synchronized void extractPacket(AEPacketRaw in, EventPacket out) {
            //if (!isHardwareInterfaceEnabled())
            //    return;
        
            // check to see that framepacket has correct number of pixel
            if (!(in instanceof CameraAEPacketRaw))
                return;
        
            CameraAEPacketRaw framePacket = (CameraAEPacketRaw) in;
            nPixels = framePacket.getFrameSize();
        
            int nFrames = framePacket.getNumFrames();
        
            pixelValues = in.getAddresses(); // pixel RGB values stored here by hardware interface
            //out.allocate();
            OutputEventIterator itr = out.outputIterator();
        
            //OutputEventIterator itr = out.outputIterator();
            //if (linearInterpolateTimeStamp) {
            //    discreteEventCount.clear();
            //}

            if (out.getEventClass() != PolarityEvent.class) {
                out.setEventClass(PolarityEvent.class); // set the proper output event class to include color change events
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
                    currentFrameTimestamp = 0;
                    previousValues = new double[nPixels];
                    for (int i = 0; i < nPixels; i++) {
                        x = i % chip.getSizeX();
                        y = (int) Math.floor(i / chip.getSizeX()); 
                        previousValues[i] = transformValue(x, y, pixelValues[i]);
                    } 
                    initialised = true;
                }

                timeCount += currentFrameTimestamp - lastFrameTimestamp;
                lastFrameTimestamp = currentFrameTimestamp;
                frameCount++;    
            
                if (frameCount >= (3 * getFrameRate())) {
                    log.warning("Frame Rate: " + frameCount * 1000000.0f / timeCount);
                    frameCount = 0;
                    timeCount = 0;
                }
            }
        }
        
    }
}

