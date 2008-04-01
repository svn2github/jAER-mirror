/*
 * CypressFX2MonitorSequencerFactory.java
 *
 * Created on 29 de noviembre de 2005, 9:47
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */

package ch.unizh.ini.caviar.hardwareinterface.usb;

import ch.unizh.ini.caviar.util.HexString;
import de.thesycon.usbio.PnPNotifyInterface;
import de.thesycon.usbio.*;
import de.thesycon.usbio.structs.*;
import java.util.*;
import ch.unizh.ini.caviar.hardwareinterface.*;
import java.util.logging.*;

/**
 * Manufactures CypressFX2-based objects. This class is used in
 HardwareInterfaceFactory or it can be directly accessed.
 *
 * @author tobi/raphael
 *@see ch.unizh.ini.caviar.hardwareinterface.HardwareInterfaceFactory
 */
public class CypressFX2Factory implements UsbIoErrorCodes, PnPNotifyInterface, HardwareInterfaceFactoryInterface {
    
    static Logger log=Logger.getLogger("CypressFX2Factory");
    int status;
    
    PnPNotify pnp=null;
    
    //static instance, by which this class can be accessed
    private static CypressFX2Factory instance=new CypressFX2Factory();
    
    CypressFX2Factory(){
        if(UsbIoUtilities.usbIoIsAvailable){
            pnp=new PnPNotify(this);
            pnp.enablePnPNotification(GUID);
            buildUsbIoList();
        }
    }
    
    /** @return singleton instance */
    public static HardwareInterfaceFactoryInterface instance(){
        return instance;
    }
    
    public void onAdd() {
        log.info("CypressFX2Factory.onAdd(): device added");
        buildUsbIoList();
    }
    
    public void onRemove() {
        log.info("CypressFX2Factory.onRemove(): device removed");
        buildUsbIoList();
    }
    
    /** driver guid (Globally unique ID, for this USB driver instance */
    public final static    String GUID = CypressFX2.GUID; // see guid.txt at root of CypressFX2USB2
    
    /** the UsbIo interface to the device. This is assigned when this particular instance is opened, after enumerating all devices */
    private UsbIo gUsbIo=null;
    
    private int gDevList; // 'handle' (an integer) to an internal device list static to UsbIo
    
    private ArrayList<UsbIo> usbioList=null;
    
    void buildUsbIoList(){
        usbioList=new ArrayList<UsbIo>();
        if(!UsbIoUtilities.usbIoIsAvailable) return;
         /* from USBIO reference manual for C++ method Open
                       Comments
            There are two options:
            (A) DeviceList != NULL
            The device list provided in DeviceList must have been built using
            CUsbIo::CreateDeviceList. The GUID that identifies the device interface must be
            provided in InterfaceGuid. DeviceNumber is used to iterate through the device list. It
            should start with zero and should be incremented after each call to Open. If no more
            instances of the interface are available then the status code
            USBIO_ERR_NO_SUCH_DEVICE_INSTANCE is returned.
            Note: This is the recommended way of implementing a device enumeration.
          */
        final int MAXDEVS=8;
        
        UsbIo dev;
        gDevList=UsbIo.createDeviceList(GUID);
        for(int i=0;i<MAXDEVS;i++){
            dev=new UsbIo();
            int status=dev.open(i, gDevList, GUID);
            
            if(status==USBIO_ERR_NO_SUCH_DEVICE_INSTANCE) {
                break;
            }else{
                //        System.out.println("CypressFX2.openUsbIo(): UsbIo opened the device");
                // get device descriptor (possibly before firmware download, when still bare cypress device or running off EEPROM firmware)
                USB_DEVICE_DESCRIPTOR deviceDescriptor=new USB_DEVICE_DESCRIPTOR();
                status = dev.getDeviceDescriptor(deviceDescriptor);
                if (status != USBIO_ERR_SUCCESS) {
                    UsbIo.destroyDeviceList(gDevList);
                    log.warning(UsbIo.errorText(status));
                } else {
                    usbioList.add(dev);
                }
                dev.close();
            }
        }
        UsbIo.destroyDeviceList(gDevList); // we got number of devices, done with list
    }
    
    /** returns the first interface in the list
     *@return refernence to the first interface in the list
     */
    public USBInterface getFirstAvailableInterface() {
        return getInterface(0);
    }
    
    /** returns the n-th interface in the list, either Tmpdiff128Retina, USBAERmini2 or USB2AERmapper, TCVS320, or MonitorSequencer depending on PID
     *@param n the number to instance (0 based)
     */
    public  USBInterface getInterface(int n){
        int numAvailable=getNumInterfacesAvailable();
        if(n>numAvailable-1){
            log.warning("Only "+numAvailable+" interfaces available but you asked for number "+n);
            return null;
        }
        
        UsbIo dev=new UsbIo();
        
        gDevList=UsbIo.createDeviceList(GUID);
        
        int status=dev.open(n, gDevList, GUID);
        
        if (status!=this.USBIO_ERR_SUCCESS) {
            log.warning(UsbIo.errorText(status));
            dev.close();
            UsbIo.destroyDeviceList(gDevList);
            return null;
        }
        
        USB_DEVICE_DESCRIPTOR deviceDescriptor=new USB_DEVICE_DESCRIPTOR();
        status = dev.getDeviceDescriptor(deviceDescriptor);
        if (status != USBIO_ERR_SUCCESS) {
            UsbIo.destroyDeviceList(gDevList);
            log.warning(UsbIo.errorText(status));
            dev.close();
            return null;
        }
        
        dev.close();
        UsbIo.destroyDeviceList(gDevList);
        short pid=(short)(0xffff&deviceDescriptor.idProduct); // for some reason returns 0xffff8613 from blank cypress fx2
        
        switch(pid){
            case CypressFX2.PID_USB2AERmapper:
                return new CypressFX2Mapper(n);
            case CypressFX2.PID_TMPDIFF128_RETINA:
            case CypressFX2.PID_TMPDIFF128_FX2_SMALL_BOARD:
                return new CypressFX2TmpdiffRetina(n);
            case CypressFX2.PID_TCVS320_RETINA:
                return new CypressFX2TCVS320Retina(n);
            case CypressFX2.PID_USBAERmini2:
                return new CypressFX2MonitorSequencer(n);
            default:
                log.warning("PID="+HexString.toString(pid)+" doesn't match any device, returning CypressFX2MonitorSequencer");
                return new CypressFX2MonitorSequencer(n);
        }
    }
    
    /** @return the number of compatible monitor/sequencer attached to the driver
     */
    public int getNumInterfacesAvailable() {
        buildUsbIoList();
//        System.out.println(instance.usbioList.size()+" CypressFX2 interfaces available ");
        return instance.usbioList.size();
    }
    
    /** display all available CypressFX2 devices controlled by USBIO driver
     */
    public void listDevices() {
        buildUsbIoList();
        
        int numberOfDevices=instance.usbioList.size();
        
        System.out.println(numberOfDevices +" CypressFX2 interfaces available ");
        
        CypressFX2 dev;
        int[] VIDPID;
        String[] strings;
        gDevList=UsbIo.createDeviceList(GUID);
        for(int i=0;i<numberOfDevices;i++){
            dev=new CypressFX2(i);
            
            try {
                // printing the device information not necessary, gets printed in dev.open()
                System.out.println("----------------------------");
                System.out.println("  Device number: " + i);
                System.out.println("----------------------------");
                dev.open();
                /*VIDPID = dev.getVIDPID();
                System.out.println(", VID: "+ VIDPID[0] +", PID: "+ VIDPID[1]);
                 
                strings=dev.getStringDescriptors();
                 
                System.out.println("Manufacturer: " + strings[0] + ", device type: " + strings[1]);
                 
                if (dev.getNumberOfStringDescriptors()==3)
                {
                    System.out.println("Device name: " + strings[2]);
                }*/
                System.out.println("----------------------------");
                System.out.println("");
                dev.close();
            } catch (HardwareInterfaceException e) {
                System.out.println("Error handling device " + i + ": " + e);
            }
        }
        UsbIo.destroyDeviceList(gDevList);
    }
}