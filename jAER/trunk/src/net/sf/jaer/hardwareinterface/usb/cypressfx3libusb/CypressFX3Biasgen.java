package net.sf.jaer.hardwareinterface.usb.cypressfx3libusb;

import javax.swing.JOptionPane;

import net.sf.jaer.biasgen.AddressedIPot;
import net.sf.jaer.biasgen.Biasgen;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import net.sf.jaer.biasgen.Pot;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

import org.usb4java.Device;

import eu.seebetter.ini.chips.davis.DavisConfig;

/**
 * Adds biasgen functionality to base interface via Cypress FX2.
 *
 * @author tobi
 */
public class CypressFX3Biasgen extends CypressFX3 implements BiasgenHardwareInterface {

	/**
	 * max number of bytes used for each bias. For 24-bit biasgen, only 3 bytes are used, but we oversize considerably
	 * for the future.
	 */
	public static final int MAX_BYTES_PER_BIAS = 8;

	/**
	 * Creates a new instance of CypressFX3Biasgen. Note that it is possible to construct several instances
	 * and use each of them to open and read from the same device.
	 *
	 * @param devNumber
	 *            the desired device number, in range returned by CypressFX3Factory.getNumInterfacesAvailable
	 * @see CypressFX3TmpdiffRetinaFactory
	 */
	protected CypressFX3Biasgen(final Device device) {
		super(device);
	}

	/*
	 * sets the powerdown input pin to the biasgenerator.
	 * Chip may have been plugged in without being
	 * powered up. To ensure the biasgen is powered up, a negative transition is necessary. This transistion is
	 * necessary to ensure the startup circuit starts up the masterbias again.
	 *
	 * if this method is called from a GUI is may be desireable to actually toggle the powerdown pin high and then low
	 * to ensure the chip is powered up.
	 * otherwise it doesn't make sense to always toggle this pin because it will perturb the chip operation
	 * significantly.
	 * For instance, it should not be called very time new bias values are sent.
	 *
	 * @param powerDown true to power OFF the biasgen, false to power on
	 */
	@Override
	synchronized public void setPowerDown(final boolean powerDown) throws HardwareInterfaceException {
		// DO NOTHING.
	}

	/**
	 * sends the ipot values.
	 *
	 * @param biasgen
	 *            the biasgen which has the values to send
	 */
	@Override
	synchronized public void sendConfiguration(final net.sf.jaer.biasgen.Biasgen biasgen)
		throws HardwareInterfaceException {
		if (deviceHandle == null) {
			try {
				open();
			}
			catch (final HardwareInterfaceException e) {
				CypressFX3.log.warning(e.getMessage());
				return; // may not have been constructed yet.
			}
		}

		DavisConfig davisConf = null; 
                try {
                    davisConf = ((DavisConfig) biasgen);
                } catch (ClassCastException cce) {
                    throw new HardwareInterfaceException(cce.getLocalizedMessage(),cce); //propagate as HIEx
                }
                
                davisConf.sendConfiguration(biasgen);

		if (biasgen.getPotArray() != null) {
			// Send all biases.
			for (Pot b : biasgen.getPotArray().getPots()) {
				davisConf.sendAIPot((AddressedIPot) b);
			}
		}
	}


	@Override
	synchronized public void flashConfiguration(final Biasgen biasgen) throws HardwareInterfaceException {
		JOptionPane.showMessageDialog(null, "Flashing biases not yet supported on CypressFX3");
	}

	/**
	 * This implementation delegates the job of getting the bytes to send to the Biasgen object.
	 * Depending on the hardware interface, however, it may be that a particular subclass of this
	 * should override formatConfigurationBytes to return a different set of data.
	 *
	 * @param biasgen
	 *            the source of configuration information.
	 * @return the bytes to send
	 */
	@Override
	public byte[] formatConfigurationBytes(final Biasgen biasgen) {
		final byte[] b = biasgen.formatConfigurationBytes(biasgen);
		return b;
	}
}
