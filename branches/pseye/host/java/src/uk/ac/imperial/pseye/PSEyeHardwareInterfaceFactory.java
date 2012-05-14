/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package uk.ac.imperial.pseye;

import java.util.logging.Logger;
import uk.ac.imperial.vsbe.CameraHardwareInterfaceFactory;
import uk.ac.imperial.vsbe.CameraAEHardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceFactoryInterface;

/**
 * Constructs CLEye hardware interfaces.
 * 
 * @author tobi
 */
public class PSEyeHardwareInterfaceFactory extends CameraHardwareInterfaceFactory {
    /** The GUID associated with jAERs Code Labs driver installation for the PS Eye camera.*/
    public static final String GUID = "{4b4803fb-ff80-41bd-ae22-1d40defb0d01}";
    final static Logger log = Logger.getLogger("PSEye");
    private static PSEyeHardwareInterfaceFactory instance = new PSEyeHardwareInterfaceFactory(); // singleton
    
    private PSEyeHardwareInterfaceFactory() {}

    @Override
    protected void buildList() {
        this.interfaces = new HardwareInterface[PSEyeCameraHardware.cameraCount()];
        for ( int i = 0; i < this.interfaces.length; i++ ) {
            this.interfaces[i] = new CameraAEHardwareInterface<PSEyeCameraHardware>(new PSEyeCameraHardware(i));
        }
    }

    @Override
    public Logger getLog() { return log; }
    
    @Override
    public String getGUID() { return GUID; }

    public static HardwareInterfaceFactoryInterface instance() {
        return instance;
    }
}
