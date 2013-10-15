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
 * Encapsulates data sent from device Invensense Inertial Measurement Unit (IMU) MPU-6150 (acceleration x/y/z, temperature, gyro x/y/z => 7 x 2 bytes =
 * 14 bytes) plus the sample timestamp.
 * 
 */
public class IMUSample extends ApsDvsEvent{

    private final static Logger log=Logger.getLogger("IMUSample");
   /**
     * This byte value as first byte signals an IMU (gyro/accelerometer/compass) sample in the USB byte array sent from device
     */
    private static final byte IMU_SAMPLE_CODE = (byte) 0xff;

    /** The data bits of the IMU data are these bits */
    private static final int DATABITMASK = 0x0FFFF000;

   /** code for this sample is left shifted this many bits in the raw 32 bit AE address. The lsbs are the data, and the code for the data type is at this BITSHIFT */
    private static final int CODEBITSHIFT = 16;

    /** These bits contain the type of the sample. If any of these bits are set then also this AE address is an IMU sample of some type. */
    private static final int CODEBITMASK=0x0f<<CODEBITSHIFT; // 4 bits to code 7 types of samples because we cannot have a zero code, otherwise we could not detect that we have an IMU sample

    /** The IMU data */
    private short[] data=new short[SIZE_EVENTS];

    /** Timestamp of IMUSample in us units using AER time basis  */
    private int timestampUs;
    /* the time in us from System.nanoTime on host since last sample */
    private int deltaTimeUs;

    /** Size of IMUSample in events written or read from AEPacketRaw */
    public static final int SIZE_EVENTS=7;

    /** Used to track when last sample came in via EventPacket in us timestamp units */
    private static int lastTimestampUs=0;
    private static boolean firstSampleDone=false;
    
//    /** Used to track when last sample was acquired in host System.nanoTime units */
//    private static long lastSampleTimeSystemNs=System.nanoTime();
     /**
     * values are from datasheet for reset settings
     */
//    final float accelScale = 2f / ((1 << 16)-1), gyroScale = 250f / ((1 << 16)-1), temperatureScale = 1f/340;
    private static final float accelScale = 1f/16384, gyroScale = 1f/131, temperatureScale = 1f/340, temperatureOffset=35;

    /** Full scale values */
    public static final float FULL_SCALE_ACCEL_G=2f, FULL_SCALE_GYRO_DEG_PER_SEC=250f;

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
        sample.updateStatistics(sample.timestampUs);
        int offset=0;
        for (int code = startingCode; code < IMUSampleType.values().length; code++) {
            if (start + offset >= packet.getNumEvents()) {
                throw new IncompleteIMUSampleException(sample,code);
            }
            int data = packet.addresses[start + offset];
            if ((ApsDvsChip.ADDRESS_TYPE_IMU & data) != ApsDvsChip.ADDRESS_TYPE_IMU) {
                throw new BadIMUDataException("bad data, not an IMU data type, wrong bits are set: " + data);
            }
            final int v = (IMUSample.DATABITMASK & data) >>> 12;
            offset++;

            sample.data[code] = (short) v;
        }
         return sample;
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
        updateStatistics(timestampUs);
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
        return String.format("timestampUs=%-14d deltaTimeUs=%-8d ax=%-8.3f ay=%-8.3f az=%-8.3f gx=%-8.3f gy=%-8.3f gz=%-8.3f temp=%-8.1f ax= %-8d ay= %-8d az= %-8d gx= %-8d gy= %-8d gz= %-8d temp= %-8d",
                getTimestampUs(), deltaTimeUs, getAccelX(), getAccelY(), getAccelZ(), getGyroTiltX(), getGyroYawY(), getGyroRollZ(), getTemperature(),
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
    final public int computeAddress(IMUSampleType imuSampleType) {
        switch (imuSampleType) {
            case ax:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.ax.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.ax.code]) << 12); // shifted just to left of 2-bits of read type for APS data
            case ay:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.ay.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.ay.code]) << 12);
            case az:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.az.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.az.code]) << 12);
            case temp:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.temp.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.temp.code]) << 12);
            case gx:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.gx.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.gx.code]) << 12);
            case gy:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.gy.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.gy.code]) << 12);
            case gz:
                return ApsDvsChip.ADDRESS_TYPE_IMU
                        | (((IMUSampleType.gz.code << IMUSample.CODEBITSHIFT) | data[IMUSampleType.gz.code]) << 12);
            default:
                throw new RuntimeException("no such sample type " + imuSampleType);
        }
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
            packet.addresses[idx] = computeAddress(sampleType);
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
     * Returns the time in us since last sample, using System.nanoTime() on
     * host.
     *
     * @return the deltaTimeUs
     */
    public int getDeltaTimeUs() {
        return deltaTimeUs;
    }

}