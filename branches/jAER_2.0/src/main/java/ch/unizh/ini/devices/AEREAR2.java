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
import net.sf.jaer2.devices.config.ConfigByte;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.ConfigShort;
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

		final FX2 fx2 = new FX2();
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
		latticeMachX0.addSetting(new ConfigByte("onchipPreampGain", ".", (byte) 3), 1, 2);
		latticeMachX0.addSetting(new ConfigBit("selAER", ".", true), 3);
		latticeMachX0.addSetting(new ConfigBit("selIn", ".", false), 4);
		latticeMachX0.addSetting(new ConfigBitTristate("preampAttackRelease", ".", Tristate.LOW), 5, 2);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Left", ".", Tristate.HIZ), 7, 2);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Right", ".", Tristate.HIZ), 9, 2);
		latticeMachX0.addSetting(new ConfigShort("adcConfig", ".", (short) 4), 11, 12);
		latticeMachX0.addSetting(new ConfigInt("adcTrackTime", ".", 0), 23, 16);
		latticeMachX0.addSetting(new ConfigInt("adcIdleTime", ".", 0), 39, 16);
		latticeMachX0.addSetting(new ConfigByte("scanChannel", ".", (byte) 0), 55, 7);
		latticeMachX0.addSetting(new ConfigBit("scanSel", ".", false), 62);
		latticeMachX0.addSetting(new ConfigBit("scanContinuouslyEnabled", ".", true), 63);

		// ADC adcAD7933 = new AD7933();
		// Not actively configurable.

		final AERChip cochlea = new CochleaAMS1c();
		cochlea.setProgrammer(fx2);

		// BufferBias BufferIPot ???

		cochlea.addSetting(new IPot("VAGC", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 0);
		cochlea.addSetting(new IPot("Curstartbpf", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 1);
		cochlea.addSetting(new IPot("DacBufferNb", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 2);
		cochlea.addSetting(new IPot("Vbp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 3);
		cochlea.addSetting(new IPot("Ibias20OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 4);
		cochlea.addSetting(new IPot("Vioff", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 5);
		cochlea.addSetting(new IPot("Vsetio", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 6);
		cochlea.addSetting(new IPot("Vdc1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 7);
		cochlea.addSetting(new IPot("NeuronRp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		cochlea.addSetting(new IPot("Vclbtgate", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 9);
		cochlea.addSetting(new IPot("N.C.", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 10);
		cochlea.addSetting(new IPot("Vbias2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 11);
		cochlea.addSetting(new IPot("Ibias10OpAmp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 12);
		cochlea.addSetting(new IPot("Vthbpf2", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 13);
		cochlea.addSetting(new IPot("Follbias", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 14);
		cochlea.addSetting(new IPot("pdbiasTX", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 15);
		cochlea.addSetting(new IPot("Vrefract", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 16);
		cochlea.addSetting(new IPot("VbampP", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 17);
		cochlea.addSetting(new IPot("Vcascode", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 18);
		cochlea.addSetting(new IPot("Vbpf2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 19);
		cochlea.addSetting(new IPot("Ibias10OTA", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 20);
		cochlea.addSetting(new IPot("Vthbpf1", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 21);
		cochlea.addSetting(new IPot("Curstart", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 22);
		cochlea.addSetting(new IPot("Vbias1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 23);
		cochlea.addSetting(new IPot("NeuronVleak", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 24);
		cochlea.addSetting(new IPot("Vioffbpfn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 25);
		cochlea.addSetting(new IPot("Vcasbpf", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 26);
		cochlea.addSetting(new IPot("Vdc2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 27);
		cochlea.addSetting(new IPot("Vterm", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 28);
		cochlea.addSetting(new IPot("Vclbtcasc", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 29);
		cochlea.addSetting(new IPot("reqpuTX", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 30);
		cochlea.addSetting(new IPot("Vbpf1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 31);

		final DAC dacAD5391 = new AD5391_32chan();

		dacAD5391.addSetting(new VPot("Vterm", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 0);
		dacAD5391.addSetting(new VPot("Vrefhres", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 1);
		dacAD5391.addSetting(new VPot("VthAGC", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 2);
		dacAD5391.addSetting(new VPot("Vrefreadout", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 3);
		dacAD5391.addSetting(new VPot("BiasDACBufferNBias", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 4);
		dacAD5391.addSetting(new VPot("Vrefract", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 5);
		dacAD5391.addSetting(new VPot("PreampAGCThreshold", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 6);
		dacAD5391.addSetting(new VPot("Vrefpreamp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 7);
		dacAD5391.addSetting(new VPot("NeuronRp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		dacAD5391.addSetting(new VPot("Vthbpf1x", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 9);
		dacAD5391.addSetting(new VPot("Vioffbpfn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 10);
		dacAD5391.addSetting(new VPot("NeuronVleak", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 11);
		dacAD5391.addSetting(new VPot("DCOutputLevel", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 12);
		dacAD5391.addSetting(new VPot("Vthbpf2x", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 13);
		dacAD5391.addSetting(new VPot("DACSpOut2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 14);
		dacAD5391.addSetting(new VPot("DACSpOut1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 15);
		dacAD5391.addSetting(new VPot("Vth4", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 16);
		dacAD5391.addSetting(new VPot("Vcas2x", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 17);
		dacAD5391.addSetting(new VPot("Vrefo", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 18);
		dacAD5391.addSetting(new VPot("Vrefn2", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 19);
		dacAD5391.addSetting(new VPot("Vq", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 20);
		dacAD5391.addSetting(new VPot("Vpf", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 21);
		dacAD5391.addSetting(new VPot("Vgain", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 22);
		dacAD5391.addSetting(new VPot("Vrefn", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 23);
		dacAD5391.addSetting(new VPot("VAI0", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 24);
		dacAD5391.addSetting(new VPot("Vdd1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 25);
		dacAD5391.addSetting(new VPot("Vth1", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 26);
		dacAD5391.addSetting(new VPot("Vref", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 27);
		dacAD5391.addSetting(new VPot("Vtau", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 28);
		dacAD5391.addSetting(new VPot("VcondVt", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 29);
		dacAD5391.addSetting(new VPot("Vpm", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 30);
		dacAD5391.addSetting(new VPot("Vhm", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 31);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
