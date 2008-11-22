/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package ch.unizh.ini.jaer.chip.cochlea;

import net.sf.jaer.biasgen.Biasgen;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import java.util.Observable;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.CypressFX2;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.CypressFX2MonitorSequencer;

/**
 * The hardware interface to CochleaAMS1b.
 * 
 * @author tobi
 */
public class CochleaAMS1bHardwareInterface extends CypressFX2MonitorSequencer implements BiasgenHardwareInterface{

    final byte VR_CONFIG=CypressFX2.VENDOR_REQUEST_SEND_BIAS_BYTES;
    
    /** The USB PID */
    public static final short PID=(short)0x8405;
    
    public CochleaAMS1bHardwareInterface(int n){
        super(n);
    }

    public void setPowerDown(boolean powerDown) throws HardwareInterfaceException {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public void sendConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        if(!(biasgen instanceof CochleaAMS1b.Biasgen)){
            log.warning("biasgen is not instanceof CochleaAMS1b.Biasgen");
            return;
        }
        ((CochleaAMS1b.Biasgen)biasgen).sendConfiguration();
    }

    public void flashConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
        throw new HardwareInterfaceException("Flashing configuration not supported yet.");
    }

    public byte[] formatConfigurationBytes(Biasgen biasgen) {
        if(!(biasgen instanceof CochleaAMS1b.Biasgen)){
            log.warning(biasgen+" is not instanceof CochleaAMS1b.Biasgen, returning null array");
            return null;
        }
        CochleaAMS1b.Biasgen b=(CochleaAMS1b.Biasgen) biasgen;
        return new byte[0];
    }
    
    public void update(Observable obs, Object obj){
        log.info("got update from "+obs+" of "+obj);
    }
}
