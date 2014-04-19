package ch.unizh.ini.devices;

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
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.VPot;
import net.sf.jaer2.eventio.translators.Translator;

import org.usb4java.Device;

import ch.unizh.ini.devices.components.aer.CochleaAMS1c;
import ch.unizh.ini.devices.components.misc.AD5391_32chan;

public class AEREAR2 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x8406;

	public AEREAR2(final Device usbDevice) {
		super("AER EAR 2", "Cochlea using the CochleaAMS1c chip, USB 2.0.", USBDevice.VID, AEREAR2.PID, USBDevice.DID,
			usbDevice);

		final FX2 fx2 = new FX2(getConfigNode());
		addComponent(fx2);

		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("runAERComm", ".", getConfigNode(), FX2.Ports.PA3, true));
		fx2.addSetting(new ConfigBit("hostResetTimestamps", ".", getConfigNode(), FX2.Ports.PA7, false));
		fx2.addSetting(new ConfigBit("runAdc", ".", getConfigNode(), FX2.Ports.PC0, true));
		fx2.addSetting(new ConfigBit("vCtrlKill", ".", getConfigNode(), FX2.Ports.PD6, true));
		fx2.addSetting(new ConfigBit("aerKillBit", ".", getConfigNode(), FX2.Ports.PD7, false));
		fx2.addSetting(new ConfigBit("cochleaBitLatch", ".", getConfigNode(), FX2.Ports.PE1, true));
		fx2.addSetting(new ConfigBit("powerDown", ".", getConfigNode(), FX2.Ports.PE2, false));
		fx2.addSetting(new ConfigBit("cochleaReset", ".", getConfigNode(), FX2.Ports.PE3, false));

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(getConfigNode(), 32, 0x51);
		eeprom.setProgrammer(fx2);
		addComponent(eeprom);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0(getConfigNode());
		latticeMachX0.setProgrammer(fx2);
		addComponent(latticeMachX0);

		final ShiftRegisterContainer cpldSR = new ShiftRegisterContainer("cpldSR",
			"ShiftRegister for on-CPLD configuration.", getConfigNode(), 80);

		cpldSR.addSetting(new ConfigBit("yBit", ".", cpldSR.getConfigNode(), false));
		cpldSR.addSetting(new ConfigInt("onchipPreampGain", ".", cpldSR.getConfigNode(), (byte) 3, 2));
		cpldSR.addSetting(new ConfigBit("selAER", ".", cpldSR.getConfigNode(), true));
		cpldSR.addSetting(new ConfigBit("selIn", ".", cpldSR.getConfigNode(), false));
		cpldSR.addSetting(new ConfigBitTristate("preampAttackRelease", ".", cpldSR.getConfigNode(), Tristate.LOW));
		cpldSR.addSetting(new ConfigBitTristate("preampGain.Left", ".", cpldSR.getConfigNode(), Tristate.HIZ));
		cpldSR.addSetting(new ConfigBitTristate("preampGain.Right", ".", cpldSR.getConfigNode(), Tristate.HIZ));
		cpldSR.addSetting(new ConfigInt("adcConfig", ".", cpldSR.getConfigNode(), (short) 4, 12));
		cpldSR.addSetting(new ConfigInt("adcTrackTime", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("adcIdleTime", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("scanChannel", ".", cpldSR.getConfigNode(), (byte) 0, 7));
		cpldSR.addSetting(new ConfigBit("scanSel", ".", cpldSR.getConfigNode(), false));
		cpldSR.addSetting(new ConfigBit("scanContinuouslyEnabled", ".", cpldSR.getConfigNode(), true));

		latticeMachX0.addSetting(cpldSR);

		// ADC adcAD7933 = new AD7933();
		// Not actively configurable.

		final AERChip cochlea = new CochleaAMS1c(getConfigNode());
		cochlea.setProgrammer(fx2);
		addComponent(cochlea);

		final DAC dacAD5391 = new AD5391_32chan(getConfigNode());
		dacAD5391.setProgrammer(latticeMachX0);
		addComponent(dacAD5391);

		dacAD5391.addSetting(new VPot("Vterm", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391
			.addSetting(new VPot("Vrefhres", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("VthAGC", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vrefreadout", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.N));
		dacAD5391.addSetting(new VPot("BiasDACBufferNBias", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.N));
		dacAD5391
			.addSetting(new VPot("Vrefract", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("PreampAGCThreshold", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vrefpreamp", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391
			.addSetting(new VPot("NeuronRp", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391
			.addSetting(new VPot("Vthbpf1x", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vioffbpfn", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.N));
		dacAD5391.addSetting(new VPot("NeuronVleak", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391.addSetting(new VPot("DCOutputLevel", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391
			.addSetting(new VPot("Vthbpf2x", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("DACSpOut2", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391.addSetting(new VPot("DACSpOut1", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL,
			Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vth4", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vcas2x", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("Vrefo", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vrefn2", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vq", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vpf", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("Vgain", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vrefn", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("VAI0", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vdd1", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vth1", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vref", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391.addSetting(new VPot("Vtau", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.P));
		dacAD5391
			.addSetting(new VPot("VcondVt", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("Vpm", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
		dacAD5391.addSetting(new VPot("Vhm", ".", dacAD5391.getConfigNode(), dacAD5391, Pot.Type.NORMAL, Pot.Sex.N));
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return null;
	}
}
