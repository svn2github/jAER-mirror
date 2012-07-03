/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package uk.ac.imperial.pseye.seebetter;

import eu.seebetter.ini.chips.seebetter20.PolarityADCSampleEvent;
import java.awt.geom.Point2D;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutput;
import java.io.ObjectOutputStream;
import java.nio.FloatBuffer;
import java.util.Arrays;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.graphics.RetinaRenderer;
import net.sf.jaer.util.filter.LowpassFilter2d;

/**
 * Renders complex data from PSEyeModelRetina chip.
 *
 * @author mlk
 */
public class SeeBetterRenderer<C extends AEChip & SeeBetterChipInterface> extends RetinaRenderer {

    protected C seeBetterChip = null;
    protected final float[] brighter = {1, 0, 0}, darker = {0, 1, 0};
    protected int sizeX = 1;
    protected int sizeY = 1;
    protected LowpassFilter2d agcFilter = new LowpassFilter2d();  // 2 lp values are min and max log intensities from each frame
    protected IntensityFrameData frameData = null;
    /** PropertyChange */
    public static final String AGC_VALUES = "AGCValuesChanged";
    /** PropertyChange when value is changed */
    public static final String APS_INTENSITY_GAIN = "apsIntensityGain", APS_INTENSITY_OFFSET = "apsIntensityOffset";
    /** Control scaling and offset of display of log intensity values. */



    public SeeBetterRenderer(C chip) {
        super(chip);
        seeBetterChip = chip;
        agcFilter.setTauMs(seeBetterChip.getTauMs());
        sizeX = chip.getSizeX();
        sizeY = chip.getSizeY();
        frameData = new IntensityFrameData();
    }

    /** Overridden to make gray buffer special for bDVS array */
    @Override
    protected void resetPixmapGrayLevel(float value) {
        checkPixmapAllocation();
        final int n = 3 * chip.getNumPixels();
        boolean madebuffer = false;
        if (grayBuffer == null || grayBuffer.capacity() != n) {
            grayBuffer = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
            madebuffer = true;
        }
        if (madebuffer || value != grayValue) {
            grayBuffer.rewind();
            for (int y = 0; y < sizeY; y++) {
                for (int x = 0; x < sizeX; x++) {
                    if(isDisplayLogIntensityChangeEvents()){
                        grayBuffer.put(0);
                        grayBuffer.put(0);
                        grayBuffer.put(0);
                    } else {
                        grayBuffer.put(grayValue);
                        grayBuffer.put(grayValue);
                        grayBuffer.put(grayValue);
                    }
                }
            }
            grayBuffer.rewind();
        }
        System.arraycopy(grayBuffer.array(), 0, pixmap.array(), 0, n);
        pixmap.rewind();
        pixmap.limit(n);
//        pixmapGrayValue = grayValue;
    }

    @Override
    public synchronized void render(EventPacket packet) {

        checkPixmapAllocation();
        resetSelectedPixelEventCount(); // TODO fix locating pixel with xsel ysel
        // rendering is a hack to use the standard pixmap to duplicate pixels on left side (where 32x32 cDVS array lives) with superimposed Brighter, Darker, Redder, Bluer, and log intensity values,
        // and to show DVS test pixel events on right side (where the 64x64 total consisting of 4x 32x32 types of pixels live)

        if (packet == null) {
            return;
        }
        this.packet = packet;
        if (packet.getEventClass() != PolarityADCSampleEvent.class) {
            log.warning("wrong input event class, got " + packet.getEventClass() + " but we need to have " + PolarityADCSampleEvent.class);
            return;
        }
        float[] pm = getPixmapArray();
        sizeX = chip.getSizeX();
        //log.info("pm : "+pm.length+", sizeX : "+sizeX);
        if (!accumulateEnabled) {
            resetFrame(.5f);
        }
        //String eventData = "NULL";
        boolean putADCData=isDisplayIntensity() && !chip.getAeViewer().isPaused(); // don't keep reputting the ADC data into buffer when paused and rendering packet over and over again
        String event = "";
        try {
            step = 1f / (colorScale);
            int adccount = 0;
            for (Object obj : packet) {
                PolarityADCSampleEvent e = (PolarityADCSampleEvent) obj;
                //eventData = "address:"+Integer.toBinaryString(e.address)+"( x: "+Integer.toString(e.x)+", y: "+Integer.toString(e.y)+"), data "+Integer.toBinaryString(e.adcSample)+" ("+Integer.toString(e.adcSample)+")";
                //System.out.println("Event: "+eventData);
                if (putADCData && e.isAdcSample()) { // hack to detect ADC sample events
                    // ADC 'event'
                    adccount++;
                    frameData.putEvent(e);
                    //log.info("put "+e.toString());
                } else if (!e.isAdcSample()) {   
                    // real AER event                        
                    int type = e.getType();
                    if(frameData.useDVSExtrapolation){
                        frameData.updateDVScalib(e.x, e.y, type==0);
                    }
                    if(isDisplayLogIntensityChangeEvents()){
                        if (xsel >= 0 && ysel >= 0) { // find correct mouse pixel interpretation to make sounds for large pixels
                            int xs = xsel, ys = ysel;
                            xs >>= 1;
                            ys >>= 1;

                            if (e.x == xs && e.y == ys) {
                                playSpike(type);
                            }
                        }
                        int x = e.x, y = e.y;
                        switch (e.polarity) {
                            case On:
                                changeCDVSPixel(x, y, pm, brighter, step);
                                break;
                            case Off:
                                changeCDVSPixel(x, y, pm, darker, step);
                                break;
                        }
                    }
                }
            }
            adccount = 0;
            if (isDisplayIntensity()) {
                int minADC = Integer.MAX_VALUE;
                int maxADC = Integer.MIN_VALUE;
                for (int y = 0; y < sizeY; y++) {
                    for (int x = 0; x < sizeX; x++) {
                        //event = "ADC x "+x+", y "+y;
                        int count = frameData.get(x, y);
                        if (isAgcEnabled()) {
                            if (count < minADC) {
                                minADC = count;
                            } else if (count > maxADC) {
                                maxADC = count;
                            }
                        }
                        float v = adc01normalized(count);
                        float[] vv = {v, v, v};
                        changeCDVSPixel(x, y, pm, vv, 1);
                    }
                }
                if (isAgcEnabled() && (minADC > 0 && maxADC > 0)) { // don't adapt to first frame which is all zeros
                    Point2D.Float filter2d = agcFilter.filter2d(minADC, maxADC, frameData.getTimestamp());
//                        System.out.println("agc minmax=" + filter2d + " minADC=" + minADC + " maxADC=" + maxADC);
                    getSupport().firePropertyChange(AGC_VALUES, null, filter2d); // inform listeners (GUI) of new AGC min/max filterd log intensity values
                }

            }
            autoScaleFrame(pm);
        } catch (IndexOutOfBoundsException e) {
            log.warning(e.toString() + ": ChipRenderer.render(), some event out of bounds for this chip type? Event: "+event);//log.warning(e.toString() + ": ChipRenderer.render(), some event out of bounds for this chip type? Event: "+eventData);
        }
        pixmap.rewind();
    }

    /** Changes scanned pixel value according to scan-out order
     * 
     * @param ind the pixel to change, which marches from LL corner to right, then to next row up and so on. Physically on chip this is actually from UL corner.
     * @param f the pixmap RGB array
     * @param c the colors
     * @param step the step size which multiplies each color component
     */
    private void changeCDVSPixel(int ind, float[] f, float[] c, float step) {
        float r = c[0] * step, g = c[1] * step, b = c[2] * step;
        f[ind] += r;
        f[ind + 1] += g;
        f[ind + 2] += b;
    }

    /** Changes all 4 pixmap locations for each large pixel affected by this event. 
     * x,y refer to space of large pixels each of which is 2x2 block of pixmap pixels
     * 
     */
    private void changeCDVSPixel(int x, int y, float[] f, float[] c, float step) {
        int ind = 3 * (x + y * sizeX);
        changeCDVSPixel(ind, f, c, step);
    }

    public void setDisplayLogIntensityChangeEvents(boolean displayIntensityChangeEvents) {
        seeBetterChip.setDisplayLogIntensityChangeEvents(displayIntensityChangeEvents);
    }

    public void setDisplayIntensity(boolean displayIntensity) {
        seeBetterChip.setDisplayIntensity(displayIntensity);
    }

    public boolean isDisplayLogIntensityChangeEvents() {
        return seeBetterChip.getDisplayLogIntensityChangeEvents();
    }

    public boolean isDisplayIntensity() {
        return seeBetterChip.getDisplayIntensity();
    }
    
    public float getAGCTauMs() {
        return agcFilter.getTauMs();
    }

    public void setAGCTauMs(float tauMs) {
        if (tauMs < 10) {
            tauMs = 10;
        }
        agcFilter.setTauMs(tauMs);
        seeBetterChip.setAGCTauMs(tauMs);
    }

    /**
     * @param seeBetterChip.getAgcEnabled() the seeBetterChip.getAgcEnabled() to set
     */
    public boolean isAgcEnabled() {
        return seeBetterChip.getAgcEnabled();
    }
    
    public void setAgcEnabled(boolean agcEnabled) {
        seeBetterChip.setAgcEnabled(agcEnabled);
    }
    
    public int getMaxADC() {
        return seeBetterChip.getMaxADC();
    }
    
    private float adc01normalized(int count) {
        float v;
        if (!isAgcEnabled()) {
            v = (float) (getApsIntensityGain()*count+getApsIntensityOffset()) / (float) getMaxADC();
        } else {
            Point2D.Float filter2d = agcFilter.getValue2d();
            float offset = filter2d.x;
            float range = (filter2d.y - filter2d.x);
            v = ((count - offset)) / range;
//                System.out.println("offset="+offset+" range="+range+" count="+count+" v="+v);
        }
        if (v < 0) {
            v = 0;
        } else if (v > 1) {
            v = 1;
        }
        return v;
    }

    void applyAGCValues() {
        Point2D.Float f = agcFilter.getValue2d();
        setApsIntensityOffset(agcOffset());
        setApsIntensityGain(agcGain());
    }

    private int agcOffset() {
        return (int) agcFilter.getValue2d().x;
    }

    private int agcGain() {
        Point2D.Float f = agcFilter.getValue2d();
        float diff = f.y - f.x;
        if (diff < 1) {
            return 1;
        }
        int gain = (int) (getMaxADC() / (f.y - f.x));
        return gain;
    }

    public int getApsIntensityGain() {
        return seeBetterChip.getApsIntensityGain();
    }
    
    /**
     * Value from 1 to getMaxADC(). Gain of 1, offset of 0 turns full scale ADC to 1.
     * Gain of getMaxADC() makes a single count go full scale.
     * @param apsIntensityGain the apsIntensityGain to set
     */
    public void setApsIntensityGain(int apsIntensityGain) {
        int old = getApsIntensityGain();
        if (apsIntensityGain < 1) {
            apsIntensityGain = 1;
        } else if (apsIntensityGain > getMaxADC()) {
            apsIntensityGain = getMaxADC();
        }
        seeBetterChip.setApsIntensityGain(apsIntensityGain);
        chip.getPrefs().putInt("seeBetterChip.getApsIntensityGain()", getApsIntensityGain());
        if (chip.getAeViewer() != null) {
            chip.getAeViewer().interruptViewloop();
        }
        getSupport().firePropertyChange(APS_INTENSITY_GAIN, old, getApsIntensityGain());
    }

    public int getApsIntensityOffset() {
        return seeBetterChip.getApsIntensityOffset();
    }

    /**
     * Sets value subtracted from ADC count before gain multiplication. Clamped between 0 to getMaxADC().
     * @param apsIntensityOffset the apsIntensityOffset to set
     */
    public void setApsIntensityOffset(int apsIntensityOffset) {
        int old = getApsIntensityOffset();
        if (apsIntensityOffset < 0) {
            apsIntensityOffset = 0;
        } else if (apsIntensityOffset > getMaxADC()) {
            apsIntensityOffset = getMaxADC();
        }
        seeBetterChip.setApsIntensityOffset(apsIntensityOffset);
        chip.getPrefs().putInt("seeBetterChip.getApsIntensityOffset()", getApsIntensityOffset());
        if (chip.getAeViewer() != null) {
            chip.getAeViewer().interruptViewloop();
        }
        getSupport().firePropertyChange(APS_INTENSITY_OFFSET, old, getApsIntensityOffset());
    }

    /**
     * 
     * Holds the frame of log intensity values to be display for a chip with log intensity readout.
     * Applies calibration values to get() the values and supplies put() and resetWriteCounter() to put the values.
     * 
     * @author Tobi
     */
    public static enum Read{A, B, C, DIFF_B, DIFF_C, HDR, LOG_HDR};
    
    public class IntensityFrameData {
        private int timestamp = 0; // timestamp of starting sample
        private float[] data = null;
        private float[] bDiffData = null;
        private float[] cDiffData = null;
        private float[] hdrData = null;
        private float[] oldData = null;
        private float[] displayData = null;
        private float[] onCalib = null;
        private float[] offCalib = null;
        private float onGain = 1f;
        private float offGain = 1f;
        private int[] onCount = null;
        private int[] offCount = null;
        private int[] aData, bData, cData;
        private float minC, maxC, maxB;
        /** Readers should access the current reading buffer. */
        private int writeCounterA = 0;
        private int writeCounterB = 0;
        private boolean useDVSExtrapolation = chip.getPrefs().getBoolean("useDVSExtrapolation", true);
        private boolean invertADCvalues = chip.getPrefs().getBoolean("invertADCvalues", false); // true by default for log output which goes down with increasing intensity
        private int lasttimestamp=-1;
        private Read displayRead = Read.A;
        
        public IntensityFrameData() {
            init();
        }
        
        public void init() {
            int size = sizeX * sizeY;
            data = new float[size];
            bDiffData = new float[size];
            cDiffData = new float[size];
            hdrData = new float[size];
            oldData = new float[size];
            displayData = new float[size];
            onCalib = new float[size];
            offCalib = new float[size];
            onCount = new int[size];
            offCount = new int[size];
            minC = Integer.MAX_VALUE;
            maxB = 0;
            maxC = 0;
            aData = new int[size];
            bData = new int[size];
            cData = new int[size];
            Arrays.fill(aData, 0);
            Arrays.fill(bData, 0);
            Arrays.fill(cData, 0);
            Arrays.fill(hdrData, 0);
            Arrays.fill(bDiffData, 0);
            Arrays.fill(cDiffData, 0);
            Arrays.fill(onCalib, 0);
            Arrays.fill(offCalib, 0);
            Arrays.fill(onCount, 0);
            Arrays.fill(offCount, 0);
            Arrays.fill(data, 0);
            Arrays.fill(displayData, 0);
            Arrays.fill(oldData, 0);            
        }
        
        private int index(int x, int y){
            final int idx = y + sizeY * x; 
            return idx;
        }

        /** Gets the sample at a given pixel address (not scanner address) 
         * 
         * @param x pixel x from left side of array
         * @param y pixel y from top of array on chip
         * @return  value from ADC
         */
        private int outputData;
        
        public int get(int x, int y) {
            final int idx = index(x,y); // values are written by row for each column (row parallel readout in this chip, with columns addressed one by one)
            switch (displayRead) {
                case A:
                    outputData = aData[idx];
                    break;
                case B:
                    outputData = bData[idx];
                    break;
                case C:
                    outputData = cData[idx];
                    break;
                case DIFF_B:
                default:
                    if(useDVSExtrapolation){
                        outputData = (int)displayData[idx];
                    }else{
                        outputData = (int)bDiffData[idx];
                    }
                    break;
                case DIFF_C:
                    if(useDVSExtrapolation){
                        outputData = (int)displayData[idx];
                    }else{
                        outputData = (int)cDiffData[idx];
                    }
                    break;
                case HDR:
                case LOG_HDR:
                    if(useDVSExtrapolation){
                        outputData = (int)displayData[idx];
                    }else{
                        outputData = (int)hdrData[idx];
                    }
                    break;
            }
            if (invertADCvalues) {
                return getMaxADC() - outputData;
            } else {
                return outputData;
            }
        }

        private void putEvent(PolarityADCSampleEvent e) {
            if(!e.isAdcSample()) return;
            //|| e.timestamp==lasttimestamp) return;
            if(e.isStartOfFrame()) {
                resetWriteCounter();
                setTimestamp(e.timestamp);
            }
            putNextSampleValue(e.getAdcSample(), e.getReadoutType(), index(e.x, e.y));
            lasttimestamp=e.timestamp; // so we don't put the same sample over and over again
        }
        
        private void putNextSampleValue(int val, PolarityADCSampleEvent.Type type, int index) {
            float value = 0;
            float valueB = 0;
            switch(type){
                case C: 
                    break;
                case B: 
                    break;
                case A:
                default:
                    if (index >= aData.length) {
        //            log.info("buffer overflowed - missing start frame bit?");
                        return;
                    }
                    if (val != 0) {
                        val = val;
                    }
                    aData[index] = val;
                    break;
            }
        }
        
        private void updateDVSintensities(){
            float difference = 1;
            for(int i = 0; i < sizeX*sizeY; i++){
                difference = data[i]-oldData[i];
                if(difference != 0){
                    if(onCount[i] > 0 && oldData[i] > 0){
                        onGain = (float)(99*onGain+((difference-Math.log(oldData[i])*offGain*offCount[i])/onCount[i]))/100;
                    } else if(offCount[i] > 0 && oldData[i] > 0){
                        offGain = (float)(99*offGain+((difference+Math.log(oldData[i])*onGain*onCount[i])/offCount[i]))/100;
                    }
                }
            }
            System.arraycopy(data, 0, displayData, 0, sizeX*sizeY);
            System.arraycopy(data, 0, oldData, 0, sizeX*sizeY);
            Arrays.fill(onCount, 0);
            Arrays.fill(offCount, 0);
        }
        
        public void updateDVScalib(int x, int y, boolean isOn){
            final int idx = index(x,y);
            if(isOn){
                onCount[idx]++;
                //System.out.println("On event - data: "+displayData[idx]+" + calib: "+onGain+" => "+onGain*Math.log(displayData[idx]));
                displayData[idx] = (float)(displayData[idx]+onGain*Math.log(displayData[idx]));
                //System.out.println("displayData: "+displayData[idx]);
            } else {
                offCount[idx]++;
                //System.out.println("Off event - data: "+displayData[idx]+" + calib: "+offGain+" => "+onGain*Math.log(displayData[idx]));
                displayData[idx] = (float)(displayData[idx]+offGain*Math.log(displayData[idx]));
                //System.out.println("displayData: "+displayData[idx]);
            }
        }

        /**
         * @return the timestamp
         */
        public int getTimestamp() {
            return timestamp;
        }

        /**
         * Sets the buffer timestamp. 
         * @param timestamp the timestamp to set
         */
        public void setTimestamp(int timestamp) {
            this.timestamp = timestamp;
        }

        /**
         * @return the useDVSExtrapolation
         */
        public boolean isUseDVSExtrapolation() {
            return useDVSExtrapolation;
        }

        /**
         * @param useDVSExtrapolation the useOffChipCalibration to set
         */
        public void setUseDVSExtrapolation(boolean useDVSExtrapolation) {
            this.useDVSExtrapolation = useDVSExtrapolation;
            chip.getPrefs().putBoolean("useDVSExtrapolation", useDVSExtrapolation);
        }

        private int getMean(int[] dataIn) {
            int mean = 0;
            for (int i = 0; i < dataIn.length; i++) {
                mean += dataIn[i];
            }
            mean = mean / dataIn.length;
            return mean;
        }

        private void subtractMean(int[] dataIn, int[] dataOut) {
            int mean = getMean(dataIn);

            for (int i = 0; i < dataOut.length; i++) {
                dataOut[i] = dataIn[i] - mean;
            }
        }
        
        public void setDisplayRead(Read displayRead){
            this.displayRead = displayRead;
        }
        
        public Read getDisplayRead(){
            return displayRead;
        }

        /**
         * @return the invertADCvalues
         */
        public boolean isInvertADCvalues() {
            return invertADCvalues;
        }

        /**
         * @param invertADCvalues the invertADCvalues to set
         */
        public void setInvertADCvalues(boolean invertADCvalues) {
            this.invertADCvalues = invertADCvalues;
            chip.getPrefs().putBoolean("invertADCvalues", invertADCvalues);
        }

        public boolean isNewData() {
            return true; // dataWrittenSinceLastSwap; // TODO not working yet
        }

        @Override
        public String toString() {
            return "IntensityFrameData{" + "WIDTH=" + sizeX + ", HEIGHT=" + sizeY + ", sizeX*sizeY=" + sizeX*sizeY + ", timestamp=" + timestamp + ", writeCounter=" + writeCounterA + '}';
        }

        public void resetWriteCounter() {
            minC = Integer.MAX_VALUE;
            maxC = 0;
            maxB = 0;
            writeCounterA = 0;
            writeCounterB = 0;
        }
        final String CALIB1_KEY = "IntensityFrameData.calibData1", CALIB2_KEY = "IntensityFrameData.calibData2";

        private void putArray(int[] array, String key) {
            if (array == null || key == null) {
                log.warning("null array or key");
                return;
            }
            try {
                // Serialize to a byte array
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                ObjectOutput out = new ObjectOutputStream(bos);
                out.writeObject(array);
                out.close();

                // Get the bytes of the serialized object
                byte[] buf = bos.toByteArray();
                chip.getPrefs().putByteArray(key, buf);
            } catch (Exception e) {
                log.warning(e.toString());
            }

        }

        private int[] getArray(String key) {
            int[] ret = null;
            try {
                byte[] bytes = chip.getPrefs().getByteArray(key, null);
                if (bytes != null) {
                    ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bytes));
                    ret = (int[]) in.readObject();
                    in.close();
                }
            } catch (Exception e) {
                log.warning(e.toString());
            }
            return ret;
        }

    }
}