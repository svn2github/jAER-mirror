package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.controllers.logic.LatticeMachX0;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.DAC;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigBitTristate;
import net.sf.jaer2.devices.config.ConfigBitTristate.Tristate;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.VPot;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.CochleaAMS1c;
import ch.unizh.ini.devices.components.misc.AD5391_32chan;

public class AEREAR2 extends USBDevice {
	private static final long serialVersionUID = 4796720824881098486L;

	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x8406;

	public AEREAR2(final Device usbDevice) {
		super("AER EAR 2", "USB cochlea using the CochleaAMS1c chip.", USBDevice.VID, AEREAR2.PID, USBDevice.DID,
			usbDevice);

		final FX2 fx2 = new FX2();
		addComponent(fx2);

		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("runAERComm", ".", true), FX2.Ports.PA3);
		fx2.addSetting(new ConfigBit("hostResetTimestamps", ".", false), FX2.Ports.PA7);
		fx2.addSetting(new ConfigBit("runAdc", ".", true), FX2.Ports.PC0);
		fx2.addSetting(new ConfigBit("vCtrlKill", ".", true), FX2.Ports.PD6);
		fx2.addSetting(new ConfigBit("aerKillBit", ".", false), FX2.Ports.PD7);
		fx2.addSetting(new ConfigBit("cochleaBitLatch", ".", true), FX2.Ports.PE1);
		fx2.addSetting(new ConfigBit("powerDown", ".", false), FX2.Ports.PE2);
		fx2.addSetting(new ConfigBit("cochleaReset", ".", false), FX2.Ports.PE3);

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);
		addComponent(eeprom);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);
		addComponent(latticeMachX0);

		latticeMachX0.addSetting(new ConfigBit("yBit", ".", false), 0);
		latticeMachX0.addSetting(new ConfigInt("onchipPreampGain", ".", (byte) 3), 1, 2);
		latticeMachX0.addSetting(new ConfigBit("selAER", ".", true), 3);
		latticeMachX0.addSetting(new ConfigBit("selIn", ".", false), 4);
		latticeMachX0.addSetting(new ConfigBitTristate("preampAttackRelease", ".", Tristate.LOW), 5, 2);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Left", ".", Tristate.HIZ), 7, 2);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Right", ".", Tristate.HIZ), 9, 2);
		latticeMachX0.addSetting(new ConfigInt("adcConfig", ".", (short) 4), 11, 12);
		latticeMachX0.addSetting(new ConfigInt("adcTrackTime", ".", 0), 23, 16);
		latticeMachX0.addSetting(new ConfigInt("adcIdleTime", ".", 0), 39, 16);
		latticeMachX0.addSetting(new ConfigInt("scanChannel", ".", (byte) 0), 55, 7);
		latticeMachX0.addSetting(new ConfigBit("scanSel", ".", false), 62);
		latticeMachX0.addSetting(new ConfigBit("scanContinuouslyEnabled", ".", true), 63);

		// ADC adcAD7933 = new AD7933();
		// Not actively configurable.

		final AERChip cochlea = new CochleaAMS1c();
		cochlea.setProgrammer(fx2);
		addComponent(cochlea);

		final DAC dacAD5391 = new AD5391_32chan();
		dacAD5391.setProgrammer(latticeMachX0);
		addComponent(dacAD5391);

		dacAD5391.addSetting(new VPot("Vterm", ".", Pot.Type.NORMAL, Pot.Sex.N), 0);
		dacAD5391.addSetting(new VPot("Vrefhres", ".", Pot.Type.NORMAL, Pot.Sex.N), 1);
		dacAD5391.addSetting(new VPot("VthAGC", ".", Pot.Type.NORMAL, Pot.Sex.P), 2);
		dacAD5391.addSetting(new VPot("Vrefreadout", ".", Pot.Type.NORMAL, Pot.Sex.N), 3);
		dacAD5391.addSetting(new VPot("BiasDACBufferNBias", ".", Pot.Type.NORMAL, Pot.Sex.N), 4);
		dacAD5391.addSetting(new VPot("Vrefract", ".", Pot.Type.NORMAL, Pot.Sex.N), 5);
		dacAD5391.addSetting(new VPot("PreampAGCThreshold", ".", Pot.Type.NORMAL, Pot.Sex.P), 6);
		dacAD5391.addSetting(new VPot("Vrefpreamp", ".", Pot.Type.NORMAL, Pot.Sex.P), 7);
		dacAD5391.addSetting(new VPot("NeuronRp", ".", Pot.Type.NORMAL, Pot.Sex.P), 8);
		dacAD5391.addSetting(new VPot("Vthbpf1x", ".", Pot.Type.NORMAL, Pot.Sex.P), 9);
		dacAD5391.addSetting(new VPot("Vioffbpfn", ".", Pot.Type.NORMAL, Pot.Sex.N), 10);
		dacAD5391.addSetting(new VPot("NeuronVleak", ".", Pot.Type.NORMAL, Pot.Sex.P), 11);
		dacAD5391.addSetting(new VPot("DCOutputLevel", ".", Pot.Type.NORMAL, Pot.Sex.P), 12);
		dacAD5391.addSetting(new VPot("Vthbpf2x", ".", Pot.Type.NORMAL, Pot.Sex.P), 13);
		dacAD5391.addSetting(new VPot("DACSpOut2", ".", Pot.Type.NORMAL, Pot.Sex.P), 14);
		dacAD5391.addSetting(new VPot("DACSpOut1", ".", Pot.Type.NORMAL, Pot.Sex.P), 15);
		dacAD5391.addSetting(new VPot("Vth4", ".", Pot.Type.NORMAL, Pot.Sex.P), 16);
		dacAD5391.addSetting(new VPot("Vcas2x", ".", Pot.Type.NORMAL, Pot.Sex.N), 17);
		dacAD5391.addSetting(new VPot("Vrefo", ".", Pot.Type.NORMAL, Pot.Sex.P), 18);
		dacAD5391.addSetting(new VPot("Vrefn2", ".", Pot.Type.NORMAL, Pot.Sex.P), 19);
		dacAD5391.addSetting(new VPot("Vq", ".", Pot.Type.NORMAL, Pot.Sex.P), 20);
		dacAD5391.addSetting(new VPot("Vpf", ".", Pot.Type.NORMAL, Pot.Sex.N), 21);
		dacAD5391.addSetting(new VPot("Vgain", ".", Pot.Type.NORMAL, Pot.Sex.P), 22);
		dacAD5391.addSetting(new VPot("Vrefn", ".", Pot.Type.NORMAL, Pot.Sex.P), 23);
		dacAD5391.addSetting(new VPot("VAI0", ".", Pot.Type.NORMAL, Pot.Sex.P), 24);
		dacAD5391.addSetting(new VPot("Vdd1", ".", Pot.Type.NORMAL, Pot.Sex.P), 25);
		dacAD5391.addSetting(new VPot("Vth1", ".", Pot.Type.NORMAL, Pot.Sex.P), 26);
		dacAD5391.addSetting(new VPot("Vref", ".", Pot.Type.NORMAL, Pot.Sex.P), 27);
		dacAD5391.addSetting(new VPot("Vtau", ".", Pot.Type.NORMAL, Pot.Sex.P), 28);
		dacAD5391.addSetting(new VPot("VcondVt", ".", Pot.Type.NORMAL, Pot.Sex.N), 29);
		dacAD5391.addSetting(new VPot("Vpm", ".", Pot.Type.NORMAL, Pot.Sex.N), 30);
		dacAD5391.addSetting(new VPot("Vhm", ".", Pot.Type.NORMAL, Pot.Sex.N), 31);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return CochleaAMS1c.class;
	}
}
