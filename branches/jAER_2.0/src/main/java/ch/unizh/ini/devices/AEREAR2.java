package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigBitTristate;
import net.sf.jaer2.devices.config.ConfigBitTristate.Tristate;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.eventio.translators.Translator;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class AEREAR2 extends USBDevice {
	public AEREAR2() {
		super("AER EAR 2", "USB cochlea using the CochleaAMS1c chip.", VID_THESYCON, (short) 0x8406);

		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("runAERComm", true), FX2.Ports.PA3);
		fx2.addSetting(new ConfigBit("hostResetTimestamps", false), FX2.Ports.PA7);
		fx2.addSetting(new ConfigBit("runAdc", true), FX2.Ports.PC0);
		fx2.addSetting(new ConfigBit("vCtrlKill", true), FX2.Ports.PD6);
		fx2.addSetting(new ConfigBit("aerKillBit", false), FX2.Ports.PD7);
		fx2.addSetting(new ConfigBit("cochleaBitLatch", true), FX2.Ports.PE1);
		fx2.addSetting(new ConfigBit("powerDown", false), FX2.Ports.PE2);
		fx2.addSetting(new ConfigBit("cochleaReset", false), FX2.Ports.PE3);

		final I2C eeprom = new EEPROM_I2C(32, 0x51); // Size in KB and I2C address.
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);

		latticeMachX0.addSetting(new ConfigBit("yBit", false), 0);
		latticeMachX0.addSetting(new ConfigInt("onchipPreampGain", 3), 1, 2);
		latticeMachX0.addSetting(new ConfigBit("selAER", true), 3);
		latticeMachX0.addSetting(new ConfigBit("selIn", false), 4);
		latticeMachX0.addSetting(new ConfigBitTristate("preampAttackRelease", Tristate.LOW), 5, 6);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Left", Tristate.HIZ), 7, 8);
		latticeMachX0.addSetting(new ConfigBitTristate("preampGain.Right", Tristate.HIZ), 9, 10);
		latticeMachX0.addSetting(new ConfigInt("adcConfig", 4), 11, 22);
		latticeMachX0.addSetting(new ConfigInt("adcTrackTime", 0), 23, 38);
		latticeMachX0.addSetting(new ConfigInt("adcIdleTime", 0), 39, 54);
		latticeMachX0.addSetting(new ConfigInt("scanChannel", 0), 55, 61);
		latticeMachX0.addSetting(new ConfigBit("scanSel", false), 62);
		latticeMachX0.addSetting(new ConfigBit("scanContinuouslyEnabled", true), 63);

		// ADC adcAD7933 = new AD7933();
		// Not actively configurable.

		final AER cochlea = new AEREAR2();
		cochlea.setBiasProgrammer(fx2);

		// BufferBias BufferIPot ???

		cochlea.addBias(new IPot("VAGC", 0, NORMAL, N, 0));
		cochlea.addBias(new IPot("Curstartbpf", 1, NORMAL, P, 0));
		cochlea.addBias(new IPot("DacBufferNb", 2, NORMAL, N, 0));
		cochlea.addBias(new IPot("Vbp", 3, NORMAL, P, 0));
		cochlea.addBias(new IPot("Ibias20OpAmp", 4, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vioff", 5, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vsetio", 6, CASCODE, P, 0));
		cochlea.addBias(new IPot("Vdc1", 7, NORMAL, P, 0));
		cochlea.addBias(new IPot("NeuronRp", 8, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vclbtgate", 9, NORMAL, P, 0));
		cochlea.addBias(new IPot("N.C.", 10, NORMAL, N, 0));
		cochlea.addBias(new IPot("Vbias2", 11, NORMAL, P, 0));
		cochlea.addBias(new IPot("Ibias10OpAmp", 12, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vthbpf2", 13, CASCODE, P, 0));
		cochlea.addBias(new IPot("Follbias", 14, NORMAL, N, 0));
		cochlea.addBias(new IPot("pdbiasTX", 15, NORMAL, N, 0));
		cochlea.addBias(new IPot("Vrefract", 16, NORMAL, N, 0));
		cochlea.addBias(new IPot("VbampP", 17, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vcascode", 18, CASCODE, N, 0));
		cochlea.addBias(new IPot("Vbpf2", 19, NORMAL, P, 0));
		cochlea.addBias(new IPot("Ibias10OTA", 20, NORMAL, N, 0));
		cochlea.addBias(new IPot("Vthbpf1", 21, CASCODE, P, 0));
		cochlea.addBias(new IPot("Curstart", 22, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vbias1", 23, NORMAL, P, 0));
		cochlea.addBias(new IPot("NeuronVleak", 24, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vioffbpfn", 25, NORMAL, N, 0));
		cochlea.addBias(new IPot("Vcasbpf", 26, CASCODE, P, 0));
		cochlea.addBias(new IPot("Vdc2", 27, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vterm", 28, CASCODE, N, 0));
		cochlea.addBias(new IPot("Vclbtcasc", 29, CASCODE, P, 0));
		cochlea.addBias(new IPot("reqpuTX", 30, NORMAL, P, 0));
		cochlea.addBias(new IPot("Vbpf1", 31, NORMAL, P, 0));

		final DAC dacAD5391 = new AD5391_32chan();

		dacAD5391.addBias(new VPot("Vterm", 0, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vrefhres", 1, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("VthAGC", 2, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vrefreadout", 3, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("BiasDACBufferNBias", 4, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vrefract", 5, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("PreampAGCThreshold", 6, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vrefpreamp", 7, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("NeuronRp", 8, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vthbpf1x", 9, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vioffbpfn", 10, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("NeuronVleak", 11, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("DCOutputLevel", 12, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vthbpf2x", 13, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("DACSpOut2", 14, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("DACSpOut1", 15, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vth4", 16, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vcas2x", 17, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vrefo", 18, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vrefn2", 19, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vq", 20, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vpf", 21, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vgain", 22, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vrefn", 23, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("VAI0", 24, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vdd1", 25, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vth1", 26, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vref", 27, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("Vtau", 28, NORMAL, P, 0));
		dacAD5391.addBias(new VPot("VcondVt", 29, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vpm", 30, NORMAL, N, 0));
		dacAD5391.addBias(new VPot("Vhm", 31, NORMAL, N, 0));
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
