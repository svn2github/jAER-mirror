package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX3;
import net.sf.jaer2.devices.components.controllers.logic.LatticeECP3;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.devices.components.misc.memory.Flash_SPI;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigByte;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.muxes.AnalogMux;
import net.sf.jaer2.devices.config.muxes.BiasMux;
import net.sf.jaer2.devices.config.muxes.DigitalMux;
import net.sf.jaer2.devices.config.pots.AddressedIPotCoarseFine;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.ShiftedSourceBiasCoarseFine;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.SBRet10;

public class ApsDvs10FX3 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x841A;

	public ApsDvs10FX3(final Device usbDevice) {
		super("ApsDVS 10 FX3", "USB 3.0 vision sensor with active and dynamic pixels, using the SBRet10 chip.",
			USBDevice.VID, ApsDvs10FX3.PID, USBDevice.DID, usbDevice);

		final FX3 fx3 = new FX3();
		fx3.firmwareToRam(false);

		fx3.addSetting(new ConfigByte("LOG_LEVEL",
			"Set the logging level, to restrict which error messages will be sent over the Status EP1.", (byte) 6),
			FX3.VendorRequests.VR_LOG_LEVEL);
		fx3.addSetting(new ConfigBit("FX3_RESET", "Hard-reset the FX3 microcontroller", false),
			FX3.VendorRequests.VR_FX3_RESET);

		fx3.addSetting(new ConfigBit("extTrigger", "External trigger.", false), FX3.Ports.GPIO40);
		fx3.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", true), FX3.Ports.GPIO41);
		fx3.addSetting(new ConfigBit("runAdc", "Enable the ADC.", true), FX3.Ports.GPIO35);
		fx3.addSetting(new ConfigBit("powerDown", "Power down the chip.", false), FX3.Ports.GPIO42);
		fx3.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", true), FX3.Ports.GPIO43);

		// Size in KB and SPI address.
		final Memory flash = new Flash_SPI(512, 0);
		flash.setProgrammer(fx3);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);

		final Logic latticeECP3 = new LatticeECP3();
		latticeECP3.setProgrammer(fx3);
		latticeECP3.firmwareToRam(true);

		// Support flashing LatticeECP3 firmware.
		latticeECP3.firmwareToFlash(flash);

		latticeECP3.addSetting(new ConfigInt("exposure", ".", 0), 0, 16);
		latticeECP3.addSetting(new ConfigInt("colSettle", ".", 0), 16, 16);
		latticeECP3.addSetting(new ConfigInt("rowSettle", ".", 0), 32, 16);
		latticeECP3.addSetting(new ConfigInt("resSettle", ".", 0), 48, 16);
		latticeECP3.addSetting(new ConfigInt("frameDelay", ".", 0), 64, 16);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10();
		sbret10.setProgrammer(fx3);

		sbret10.addSetting(new AddressedIPotCoarseFine("DiffBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 0);
		sbret10.addSetting(new AddressedIPotCoarseFine("OnBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 1);
		sbret10.addSetting(new AddressedIPotCoarseFine("OffBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 2);
		sbret10.addSetting(new AddressedIPotCoarseFine("ApsCasEpc", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 3);
		sbret10.addSetting(new AddressedIPotCoarseFine("DiffCasBnc", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 4);
		sbret10.addSetting(new AddressedIPotCoarseFine("ApsROSFBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 5);
		sbret10.addSetting(new AddressedIPotCoarseFine("LocalBufBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 6);
		sbret10.addSetting(new AddressedIPotCoarseFine("PixInvBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 7);
		sbret10.addSetting(new AddressedIPotCoarseFine("PrBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		sbret10.addSetting(new AddressedIPotCoarseFine("PrSFBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 9);
		sbret10.addSetting(new AddressedIPotCoarseFine("RefrBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 10);
		sbret10.addSetting(new AddressedIPotCoarseFine("AEPdBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 11);
		sbret10.addSetting(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 12);
		sbret10.addSetting(new AddressedIPotCoarseFine("AEPuXBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 13);
		sbret10.addSetting(new AddressedIPotCoarseFine("AEPuYBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 14);
		sbret10.addSetting(new AddressedIPotCoarseFine("IFThrBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 15);
		sbret10.addSetting(new AddressedIPotCoarseFine("IFRefrBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 16);
		sbret10.addSetting(new AddressedIPotCoarseFine("PadFollBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 17);
		sbret10.addSetting(new AddressedIPotCoarseFine("apsOverflowLevel", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 18);
		sbret10.addSetting(new AddressedIPotCoarseFine("biasBuffer", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 19);

		sbret10.addSetting(new ShiftedSourceBiasCoarseFine("SSP", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 20);
		sbret10.addSetting(new ShiftedSourceBiasCoarseFine("SSN", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 21);

		sbret10.addSetting(new ConfigBit("resetCalib", ".", true), 0);
		sbret10.addSetting(new ConfigBit("typeNCalib", ".", false), 1);
		sbret10.addSetting(new ConfigBit("resetTestpixel", ".", true), 2);
		sbret10.addSetting(new ConfigBit("hotPixelSuppression", ".", false), 3);
		sbret10.addSetting(new ConfigBit("nArow", ".", false), 4);
		sbret10.addSetting(new ConfigBit("useAout", ".", true), 5);
		sbret10.addSetting(new ConfigBit("globalShutter", ".", false), 6);

		sbret10.addSetting(new AnalogMux("AnaMux2", "."), 1);
		sbret10.addSetting(new AnalogMux("AnaMux1", "."), 2);
		sbret10.addSetting(new AnalogMux("AnaMux0", "."), 3);

		sbret10.addSetting(new DigitalMux("DigMux3", "."), 1);
		sbret10.addSetting(new DigitalMux("DigMux2", "."), 2);
		sbret10.addSetting(new DigitalMux("DigMux1", "."), 3);
		sbret10.addSetting(new DigitalMux("DigMux0", "."), 4);

		sbret10.addSetting(new BiasMux("BiasOutMux", "."), 0);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(fx3);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
