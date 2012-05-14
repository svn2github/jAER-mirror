/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package uk.ac.imperial.vsbe;

import de.thesycon.usbio.PnPNotifyInterface;
import java.util.logging.Logger;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.hardwareinterface.HardwareInterfaceFactoryInterface;
import net.sf.jaer.hardwareinterface.usb.UsbIoUtilities;

/**
 * Constructs CLEye hardware interfaces.
 * 
 * @author tobi
 */
abstract public class CameraHardwareInterfaceFactory implements HardwareInterfaceFactoryInterface, PnPNotifyInterface {
    /** The GUID associated with jAERs Code Labs driver installation for the PS Eye camera.*/
    protected HardwareInterface[] interfaces;
    
    protected CameraHardwareInterfaceFactory() { // TODO doesn't support PnP, only finds cameras plugged in on construction at JVM startup.
       buildList();
       UsbIoUtilities.enablePnPNotification(this, getGUID()); // TODO doesn't do anything since we are not using UsbIo driver for the PS Eye. Doesn't hurt however so will leave in in case we can get equivalent functionality.
    }

    abstract protected void buildList();
    abstract public Logger getLog();
    /** @return singleton instance used to construct PSEyeCameras. */
    //public static HardwareInterfaceFactoryInterface instance() {
    //    return instance;
    //}
    
    @Override
    public int getNumInterfacesAvailable() {
        if(interfaces==null) return 0;
        return this.interfaces.length;
    }

    /** Returns the first camera
     * 
     * @return first camera, or null if none available.
     * @throws HardwareInterfaceException 
     */
    @Override
    public HardwareInterface getFirstAvailableInterface() throws HardwareInterfaceException {
        return getInterface(0);
    }

    /** Returns the n'th camera (0 based) 
     * 
     * @param n
     * @return the camera
     * @throws HardwareInterfaceException 
     */
    @Override
    public HardwareInterface getInterface(int n) throws HardwareInterfaceException {
        if(getNumInterfacesAvailable() == 0 || getNumInterfacesAvailable() < n + 1) return null;
        return this.interfaces[n];
    }
    
    @Override
    public void onAdd() {
        getLog().info("camera added, rebuilding list of cameras");
        buildList();
    }

    @Override
    public void onRemove() {
        getLog().info("camera removed, rebuilding list of cameras");
        buildList();
    }
}
