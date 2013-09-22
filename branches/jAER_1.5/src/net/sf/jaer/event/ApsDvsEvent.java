package net.sf.jaer.event;



/** This event class is used in the extractor to hold data from the sensor 
 * so that it can be logged to files and played back here. It adds the ADC sample value.
 * This event has the usual timestamp in us.
 */
public class ApsDvsEvent extends PolarityEvent {

    /** The readout type of the multiple readouts: ResetRead is the readout of reset level, SignalRead is the readout of first sample, C, is the readout of 2nd sample, etc.
     * Normally only ResetRead and SignalRead are used and the CDS is done in digital domain by subtracting ResetRead-SignalRead readings.
     */
    public enum ReadoutType {ResetRead,SignalRead,EOF};
    
    /** The ADC sample value. Has value -1 by convention for non-sample events. */
    public int adcSample = 0;
    
    /** Set if this event is a start bit event, e.g. start of frame sample. */
    public boolean startOfFrame=false;
    
    /** This bit determines whether it is the first read (ResetRead) or the second read (SignalRead) of a pixel */
    public ReadoutType readoutType = ReadoutType.ResetRead;

    public ApsDvsEvent() {
    }

    @Override
    public String toString() {
        return super.toString()+" adcSample="+adcSample+" startOfFrame="+startOfFrame+" readoutType="+readoutType.toString(); 
    }
    
    

    /**
     * The ADC sample value.
     * @return the adcSample
     */
    public int getAdcSample() {
        return adcSample;
    }

    /**
     * Sets the ADC sample value.
     * 
     * @param adcSample the adcSample to set
     */
    public void setAdcSample(int adcSample) {
        this.adcSample = adcSample;
    }
    
    /**
     * The readout type (ResetRead,SignalRead,C)
     * @return the readoutType
     */
    public ReadoutType getReadoutType() {
        return readoutType;
    }

    /**
     * Sets the readout type (ResetRead,SignalRead,C)
     * 
     * @param readoutType the readoutType to set
     */
    public void setReadoutType(ReadoutType readoutType) {
        this.readoutType = readoutType;
    }

    /**
     * Flags if this sample is from the start of the frame.
     * @return the startOfFrame
     */
    public boolean isStartOfFrame() {
        return startOfFrame;
    }

    /**
     * Flags if this sample is from the start of the frame.
    * 
     * @param startOfFrame the startOfFrame to set
     */
    public void setStartOfFrame(boolean startOfFrame) {
        this.startOfFrame = startOfFrame;
    }

    @Override
    public void copyFrom(BasicEvent src) {
        ApsDvsEvent e = (ApsDvsEvent) src;
        super.copyFrom(src);
        adcSample = e.getAdcSample();
        readoutType = e.getReadoutType();
        setStartOfFrame(e.isStartOfFrame());
    }

    /** Returns true if sample is non-negative.
     * 
     * @return true if this is an ADC sample
     */
    public boolean isAdcSample() {
        return adcSample>=0;
    }
    
    public boolean isResetRead(){
        return readoutType == ReadoutType.ResetRead;
    }
    
    public boolean isSignalRead(){
        return readoutType == ReadoutType.SignalRead;
    }
    
    public boolean isEndOfFrame(){
        return readoutType == ReadoutType.EOF;
    }
}