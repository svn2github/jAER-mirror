/*
 * USBInterface.java
 *
 * Created on September 20, 2005, 10:45 PM
 */

package net.sf.jaer.hardwareinterface.usb;

import net.sf.jaer.hardwareinterface.*;


/**
 * Interface to a USB device. Includes constants such as assigned VID and PID range for jAER devices.
 *
 * @author tobi
 */
public interface USBInterface extends HardwareInterface {
    
    // new VID/PID assigned from Thesycon 16.6.2008 (stored in jAER/docs/USBIO_VID_PID_Assignments_Neuroinformatik.pdf
    // are as follows
    // VID = 0x152A (thesycon)
    // PID =0x8400 to 0x841f (32 PIDs)
    
    /** The vendor ID that goes with VID/PIDs bought from Thesycon */
    static public final short VID_THESYCON=0x152a;
    /** The starting PID that goes with VID_THESYCON */
    static public final short PID_THESYCON_START=(short)0x8400;
    /** The ending PID that goes with VID_THESYCON */
    static public final short PID_THESYCON_END=(short)0x841f;

     
   /** return the string USB descriptors for the device. By USB convention, the first string is the manufactuer, the second is product, and the last is the unique serial number.
    * The serial number may not be implemented, in which case a null string may be the third string or the length of the returned array may only be 2.
     *@return String[] of USB descriptors
     */
    public String[] getStringDescriptors();
    
    /** return the USB VID/PID of the interface
     *@return int[] of length 2 containing the Vendor ID (VID) and Product ID (PID) of the device. First element is VID, second element is PID.
     *@deprecated use getVID and getPID instead
     */
    public int[] getVIDPID();
    
    /**@return PID (vendor ID) */
    public short getVID();
    
    /**@return PID (product ID) */
    public short getPID();
    
    /**@return DID (device ID). This is the firmware version number, not the serial number. A device may not set the firmware version number in it's descriptors. Returns 0 then. DVS128 
     and the USBAERmini2 do have it.
     */
    public short getDID();
    
     
}
