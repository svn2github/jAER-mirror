package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
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
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.VPot;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.CochleaAMS1c;
import ch.unizh.ini.devices.components.misc.AD5391_32chan;

public class AEREAR2 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x8406;

	public AEREAR2(final Device usbDevice) {
		super("AER EAR 2", "USB cochlea using the CochleaAMS1c chip.", USBDevice.VID, AEREAR2.PID, USBDevice.DID,
			usbDevice);

		final Controller fx2 = new FX2();
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

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);

		latticeMachX0.addSetting(new ConfigBit("yBit", ".", false), 0);
		latticeMachX0.addSetting(new ConfigInt("onchipPreampGain", ".", 3), 1, 2);
		latticeMachX0.addSetting(new ConfigBit("selAER", ".", true), 3);
		latticeMachX0.addSetting(new ConfigBit("selIn", ".", false), 4);
		latticeMachX0.addSetting(new ConfigBitTristate("preampAttackRelease", ".", Tristate.LOW), 5, 6);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Left", ".", Tristate.HIZ), 7, 8);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Right", ".", Tristate.HIZ), 9, 10);
		latticeMachX0.addSetting(new ConfigInt("adcConfig", ".", 4), 11, 22);
		latticeMachX0.addSetting(new ConfigInt("adcTrackTime", ".", 0), 23, 38);
		latticeMachX0.addSetting(new ConfigInt("adcIdleTime", ".", 0), 39, 54);
		latticeMachX0.addSetting(new ConfigInt("scanChannel", ".", 0), 55, 61);
		latticeMachX0.addSetting(new ConfigBit("scanSel", ".", false), 62);
		latticeMachX0.addSetting(new ConfigBit("scanContinuouslyEnabled", ".", true), 63);

		// ADC adcAD7933 = new AD7933();
		// Not actively configurable.

		final AERChip cochlea = new CochleaAMS1c();
		cochlea.setProgrammer(fx2);

		// BufferBias BufferIPot ???

		cochlea.addBias(new IPot("VAGC", ".", 0, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Curstartbpf", ".", 1, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("DacBufferNb", ".", 2, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vbp", ".", 3, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Ibias20OpAmp", ".", 4, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vioff", ".", 5, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vsetio", ".", 6, Pot.Type.CASCODE, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vdc1", ".", 7, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("NeuronRp", ".", 8, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vclbtgate", ".", 9, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("N.C.", ".", 10, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vbias2", ".", 11, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Ibias10OpAmp", ".", 12, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vthbpf2", ".", 13, Pot.Type.CASCODE, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Follbias", ".", 14, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("pdbiasTX", ".", 15, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vrefract", ".", 16, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("VbampP", ".", 17, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vcascode", ".", 18, Pot.Type.CASCODE, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vbpf2", ".", 19, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Ibias10OTA", ".", 20, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vthbpf1", ".", 21, Pot.Type.CASCODE, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Curstart", ".", 22, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vbias1", ".", 23, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("NeuronVleak", ".", 24, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vioffbpfn", ".", 25, Pot.Type.NORMAL, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vcasbpf", ".", 26, Pot.Type.CASCODE, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vdc2", ".", 27, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vterm", ".", 28, Pot.Type.CASCODE, Pot.Sex.N, 0));
		cochlea.addBias(new IPot("Vclbtcasc", ".", 29, Pot.Type.CASCODE, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("reqpuTX", ".", 30, Pot.Type.NORMAL, Pot.Sex.P, 0));
		cochlea.addBias(new IPot("Vbpf1", ".", 31, Pot.Type.NORMAL, Pot.Sex.P, 0));

		final DAC dacAD5391 = new AD5391_32chan();

		dacAD5391.addBias(new VPot("Vterm", ".", 0, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vrefhres", ".", 1, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("VthAGC", ".", 2, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vrefreadout", ".", 3, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("BiasDACBufferNBias", ".", 4, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vrefract", ".", 5, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("PreampAGCThreshold", ".", 6, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vrefpreamp", ".", 7, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("NeuronRp", ".", 8, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vthbpf1x", ".", 9, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vioffbpfn", ".", 10, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("NeuronVleak", ".", 11, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("DCOutputLevel", ".", 12, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vthbpf2x", ".", 13, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("DACSpOut2", ".", 14, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("DACSpOut1", ".", 15, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vth4", ".", 16, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vcas2x", ".", 17, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vrefo", ".", 18, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vrefn2", ".", 19, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vq", ".", 20, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vpf", ".", 21, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vgain", ".", 22, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vrefn", ".", 23, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("VAI0", ".", 24, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vdd1", ".", 25, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vth1", ".", 26, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vref", ".", 27, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("Vtau", ".", 28, Pot.Type.NORMAL, Pot.Sex.P, 0));
		dacAD5391.addBias(new VPot("VcondVt", ".", 29, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vpm", ".", 30, Pot.Type.NORMAL, Pot.Sex.N, 0));
		dacAD5391.addBias(new VPot("Vhm", ".", 31, Pot.Type.NORMAL, Pot.Sex.N, 0));
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
