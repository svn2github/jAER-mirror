package eu.seebetter.ini.chips.sbret10;
/* This class created in Telluride 2013 to encapsulate Invensense IMU MPU-6150 used on SeeBetter cammeras for gyro/accelometer */

import java.nio.ByteBuffer;
import java.util.logging.Logger;

import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.util.filter.LowpassFilter;
import de.thesycon.usbio.UsbIoBuf;
import eu.seebetter.ini.chips.ApsDvsChip;
import static eu.seebetter.ini.chips.sbret10.IMUSampleType.temp;
import net.sf.jaer.event.ApsDvsEvent;

/**
 * Encapsulates data sent from device Invensense Inertial Measurement Unit (IMU) MPU-6150.
 * (acceleration x/y/z, temperature, gyro x/y/z => 7 x 2 bytes =
 * 14 bytes) plus the sample timestamp.
 * 
 */
public class IMUSample extends ApsDvsEvent{

    private final static Logger log=Logger.getLogger("IMUSample");
   /**
     * This byte value as first byte signals an IMU (gyro/accelerometer/compass) sample in the USB byte array sent from device
     */
    static final byte IMU_SAMPLE_CODE = (byte) 0xff;

    /** The 16-bit ADC sample data bits of the IMU data are these bits */
    static final int DATABITMASK = 0x0FFFF000;

    /** Data is shifted left this many bits in final 32-bit address */
    static final int DATABITSHIFT=12;
    
   /** code for this sample is left shifted this many bits plus the DATABITSHIFT shift in the raw 32 bit AE address. 
    * The 4 LS bytes are the data, and the code for the data type is the next 3 bits at this shift */
    static final int CODEBITSHIFT = 16+DATABITSHIFT;

    /** These bits contain the type of the sample, as coded in IMUSampleType.code. 
     * If any of these bits are set then also this AE address is an IMU sample of some type. */
    static final int CODEBITMASK=0x07<<CODEBITSHIFT; 

    /** Size of IMUSample in events written or read from AEPacketRaw */
    public static final int SIZE_EVENTS=7;
 
    /** The IMU data */
    private short[] data=new short[SIZE_EVENTS];

    /** Timestamp of IMUSample in us units using AER time basis  */
    private int timestampUs;
    /* the time in us from since last sample. However note that if multiple threads or objects create IMUSamples, than this deltaTimeUs is meaningless. */
    private int deltaTimeUs;

    /** Used to mark that this event is really an IMUSample and not a (super class) ApsDvsEvent that happens to using this IMUSample as a container */
    public boolean imuSampleEvent=true;

    /** Used to track when last sample came in via EventPacket in us timestamp units */
    private static int lastTimestampUs=0;
    private static boolean firstSampleDone=false;
    
//    /** Used to track when last sample was acquired in host System.nanoTime units */
//    private static long lastSampleTimeSystemNs=System.nanoTime();
     /**
     * values are from datasheet for reset settings
     */
//    final float accelScale = 2f / ((1 << 16)-1), gyroScale = 250f / ((1 << 16)-1), temperatureScale = 1f/340;
    /** IMU sensitivity scaling: The IMU 16-bit values are scaled by this amount to result in either deg/s, g, or deg C */
    public static final float accelScale = 1f/8192, gyroScale = 1f/65.5f, temperatureScale = 1f/340, temperatureOffset=35;

    /** Full scale values */
    public static final float FULL_SCALE_ACCEL_G=4f, FULL_SCALE_GYRO_DEG_PER_SEC=1000f;

    /** Used to track sample rate */
    private static LowpassFilter sampleIntervalFilter=new LowpassFilter(100); // time constant in ms


//    public class IncompleteIMUSampleException extends Exception{
//
//        public IncompleteIMUSampleException(String message) {
//            super(message);
//        }
//    }

    /** Holds incomplete IMUSample and completion status
     * 
     */
    public static class IncompleteIMUSampleException extends Exception {
        IMUSample partialSample;
        int nextCode=0;

        /** Constructs new IncompleteIMUSampleException
         * 
         * @param partialSample the partially completed sample.
         * @param nextCode the next sample type to be filled in.
         */
        public IncompleteIMUSampleException(IMUSample partialSample, int nextCode) {
            this.partialSample=partialSample;
            this.nextCode=nextCode;
        }
        
        public String toString(){
            return String.format("IncompleteIMUSampleException holding %s completed up to sampleType.code=%d",partialSample,nextCode);
        }
    }
    
    public static class BadIMUDataException extends Exception {

        public BadIMUDataException(String message) {
            super(message);
        }
        
    }

    /**
     * The protected constructor for an empty IMUSample
     *
     */
    protected IMUSample() {
        super();
        special=true;
        imuSampleEvent=true;
        adcSample=-1; // mark it as NOT ADC sample or it won't get passed out to event filters!
    }
    
    /**
     * Constructs a new IMUSample from the AEPacketRaw. This factory method deals with situation that packet does not contain an entire IMUSample.
     *
     * @param packet the packet.
     * @param start the starting index where the sample starts.
     * @param previousException null ordinarily, or a previous exception if the sample was not completed.
     * @return the sample, or null if the sample is bad because bogus data was detected in it.
     * @throws IncompleteIMUSampleException if the packet is too short to contain the entire sample. 
    The returned exception contains the partially
     * completed sample and the completion status and can be passed into a new
     * call to constructFromAEPacketRaw to complete the sample.
     */
    public static IMUSample constructFromAEPacketRaw(AEPacketRaw packet, int start, IncompleteIMUSampleException previousException)
            throws IncompleteIMUSampleException, BadIMUDataException {
        IMUSample sample;
        int startingCode = 0;
        if (previousException != null) {
            sample = previousException.partialSample;
            startingCode = previousException.nextCode;
        } else {
            sample = new IMUSample();
        }
        sample.timestampUs = packet.timestamps[start]; // assume all have same timestamp
        int offset=0;
        for (int code = startingCode; code < IMUSampleType.values().length; code++) {
            if (start + offset >= packet.getNumEvents()) {
                throw new IncompleteIMUSampleException(sample,code);
            }
            int data = packet.addresses[start + offset];
            if ((ApsDvsChip.ADDRESS_TYPE_IMU & data) != ApsDvsChip.ADDRESS_TYPE_IMU) {
                throw new BadIMUDataException("bad data, not an IMU data type, wrong bits are set: " + data);
            }
            int actualCode;
            if((actualCode=extractSampleTypeCode(data))!=code){
                  throw new BadIMUDataException("bad data, data=" + data+" should contain code="+code+" but actual code="+actualCode);
            }
            final int v = (IMUSample.DATABITMASK & data) >>> DATABITSHIFT;
            sample.data[code] = (short) v;
            offset++;
        }
        sample.updateStatistics(sample.timestampUs);
         return sample;
    }

    /** Extracts the sample type code from the 32-bit address data
     * 
     * @param addr the 32-bit raw address in AEPacketRaw
     * @return the code for the sample type
     * @see IMUSampleType
     */
     public static int extractSampleTypeCode(int addr){
        int code=((addr&CODEBITMASK)>>>CODEBITSHIFT);
        return code;
    }
        
    /** Creates a new IMUSample collection from the byte buffer sent from device.
     *
     * @param buf the buffer sent on the endpoint from the device
     */
    public IMUSample(UsbIoBuf buf) {
        this();
        setFromUsbIoBuf(buf);
    }

    final void setFromUsbIoBuf(UsbIoBuf buf) {
        if (buf.BytesTransferred != 19) {
            log.warning("wrong number of bytes transferred, got " + buf.BytesTransferred);
            return;
        }
        byte[] b = buf.BufferMem;
        if (b[0] != IMU_SAMPLE_CODE) {
            log.warning("got IMU_Sample message with wrong first byte code. Should be " + IMU_SAMPLE_CODE + " but got " + b[0]);
            return;
        }
        int[] tsBuf=new int[1];
        ByteBuffer.wrap(b, 1, 4).asIntBuffer().get(tsBuf, 0, 1); // interpret the data in buffer bytes 1-4 as timestamp 
        timestampUs=tsBuf[0]; // timestamp on device increments every 100us
//        System.out.println(String.format("timestamp=\t%12d",timestampUs));
        ByteBuffer.wrap(b, 5, 14).asShortBuffer().get(data, 0, 7); // from http://stackoverflow.com/questions/5625573/byte-array-to-short-array-and-back-again-in-java
        // see page 7 of RM-MPU-6100A.pdf (register map for MPU6150 IMU)
        // data is sent big-endian (MSB first for each sample).
        // data is scaled according to product specification datasheet PS-MPU-6100A.pdf
//        data[IMUSampleType.ax.code] = extractS16(b, 1);
//        data[IMUSampleType.ay.code] = extractS16(b, 3);
//        data[IMUSampleType.az.code] = extractS16(b, 5);
//        data[IMUSampleType.temp.code] = extractS16(b, 7);
//        data[IMUSampleType.gx.code] = extractS16(b, 9);
//        data[IMUSampleType.gy.code] = extractS16(b, 11);
//        data[IMUSampleType.gz.code] = extractS16(b, 13); // TODO remove temperature
//        this.timestampUs = ts;
//        long nowNs=System.nanoTime();
//        deltaTimeUs=(int)((nowNs-lastSampleTimeSystemNs)>>10);
//        sampleIntervalFilter.filter(deltaTimeUs, ts);
//        lastSampleTimeSystemNs=nowNs;
//        System.out.println("on reception: "+this.toString()); // debug
//        updateStatistics(timestampUs);
    }
    
    /** Computes deltaTimeUs and average sample rate
     * 
     * @param timestampUs 
     */
    private void updateStatistics(int timestampUs) {
        deltaTimeUs = timestampUs - lastTimestampUs;
        sampleIntervalFilter.filter(firstSampleDone?deltaTimeUs:0, timestampUs);
        firstSampleDone=true;
        lastTimestampUs = timestampUs;
    }

    @Override
    public String toString() {
        return String.format("imuSample=%s timestampUs=%d deltaTimeUs=%d (ax,ay,az)=(%.2f,%.2f,%.2f) g (gx,gy,gz)=(%.2f,%.2f,%.2f) deg/sec temp=%.2fC Samples: (ax,ay,az)=(%d,%d,%d) (gx,gy,gz)=(%d,%d,%d) temp=%d",
                imuSampleEvent,getTimestampUs(), deltaTimeUs, getAccelX(), getAccelY(), getAccelZ(), getGyroTiltX(), getGyroYawY(), getGyroRollZ(), getTemperature(),
                getSensorRaw(IMUSampleType.ax), getSensorRaw(IMUSampleType.ay), getSensorRaw(IMUSampleType.az),
                getSensorRaw(IMUSampleType.gx), getSensorRaw(IMUSampleType.gy), getSensorRaw(IMUSampleType.gz),
                getSensorRaw(IMUSampleType.temp));
    }

    public short getSensorRaw(IMUSampleType type){
        return data[type.ordinal()];
    }
    /**
     * Returns acceleration in g's.
     * Positive is camera right.
     *
     * @return the acceleration along x axis
     */
    final public float getAccelX() {
        return -data[IMUSampleType.ax.code] * accelScale;
    }

    /**
     * Returns acceleration in g's in vertical direction.
     * Positive is camera up.  with camera in normal orientation will provide approx -1g gravitational acceleration.
     *
     * @return the accelY
     */
    final public float getAccelY() {
        return (data[IMUSampleType.ay.code] * accelScale);
    }

    /**
     * Returns acceleration in g's towards scene.
     * Positive is towards scene.
     *
     * @return the accelZ
     */
    final public float getAccelZ() {
        return data[IMUSampleType.az.code] * accelScale;  // TODO sign not checked
    }

    /**
     * Returns rotation in deg/sec. Positive is rotating clockwise.
     *
     * @return the rotational velocity in deg/s
     */
    final public float getGyroRollZ() {
        return -data[IMUSampleType.gz.code] * gyroScale;
    }

    /**
     * Returns rotation in deg/sec. Positive is tilt up.
     *
     * @return the rotational velocity in deg/s
     */
    final public float getGyroTiltX() {
        return -data[IMUSampleType.gx.code] * gyroScale;
    }

    /**
     * Returns rotation in deg/sec. Positive is yaw right.
     *
     * @return the rotational velocity in deg/s
     */
    final public float getGyroYawY() {
        return data[IMUSampleType.gy.code] * gyroScale;
    }

    /**
     * Returns temperature in degrees Celsius
     *
     * @return the temperature
     */
    final public float getTemperature() {
        return (data[IMUSampleType.temp.code] * temperatureScale)+temperatureOffset;
    }

    /**
     * Returns timestamp of sample, which should be on same time base as AEs from sensor.
     * Units are microseconds.
     *
     * @return the timestamp in us.
     */
    final public int getTimestampUs() {
        return timestampUs;
    }

    /**
     * @param timestamp the timestamp to set, in microseconds
     */
    public void setTimestampUs(int timestamp) {
        this.timestampUs = timestamp;
    }

    /**
     * Returns raw AE address corresponding to a particular IMU sample type from
     * this IMUSample object that has all sensor values. This method is used to
     * encode the sensor values as raw addresses.
     *
     * @param imuSampletype the type of sensor value event address we want
     */
    final static public int computeAddress(IMUSample sample, IMUSampleType imuSampleType) {
        short data= sample.data[imuSampleType.code];
        int addr=imuSampleType.codeBits|(DATABITMASK &(data<<DATABITSHIFT));
        return addr;
    }

    /** Writes the IMUSample to the packet starting at start location. The number of events written to packet is returned and
     * can be used to update the eventCouner in the translateEvents method.
     * @param packet to write to
     * @param start starting event location to write to in the packet
     * @return the number of events written
     */
    public int writeToPacket(AEPacketRaw packet, int start) {
        final int cap=packet.getCapacity();
        if ((start + SIZE_EVENTS) >= cap) {
            packet.ensureCapacity(cap + SIZE_EVENTS);
        }
        for (IMUSampleType sampleType : IMUSampleType.values()) {
            final int idx=start + sampleType.code;
            packet.addresses[idx] = IMUSample.computeAddress(this,sampleType);
            packet.timestamps[idx] = timestampUs;
        }
        packet.setNumEvents(packet.getNumEvents()+SIZE_EVENTS);
        return SIZE_EVENTS;
    }

//     private int fillCounter=0;

//     /** Fills in this IMUSample from the event packet, assuming that all samples are in order.
//     * If the packet ends before this can be filled then the method returns false, but an internal counter is set
//     * that allow completing the fill from the next call.
//     * @param packet
//     * @param start
//     * @return true if sample is filled in, false if read is not completed before packet ends
//     */
//    public boolean readFromPacket(AEPacketRaw packet, int start){
//         for (IMUSampleType sampleType : IMUSampleType.values()) {
//            data[sampleType.code]=DATABITMASK&packet.addresses[start + sampleType.code];
//            packet.timestamps[start + sampleType.code] = timestamp;
//        }
//        return true;
//    }

     /** Returns the global average sample interval in us for IMU samples
      * 
      * @return time average sample interval in us
      */
     static public float getAverageSampleIntervalUs(){
         return sampleIntervalFilter.getValue();
     }
     
    /**
     * Returns the time in us since last sample. Note that only a single thread/class can access IMUSample class
     * for this number to have a meaning, because it is a static class measure.
     *
     * @return the deltaTimeUs
     */
    public int getDeltaTimeUs() {
        return deltaTimeUs;
    }

}