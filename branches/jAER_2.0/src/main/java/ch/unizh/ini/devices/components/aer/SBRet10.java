package ch.unizh.ini.devices.components.aer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.devices.config.muxes.AnalogMux;
import net.sf.jaer2.devices.config.muxes.DigitalMux;
import net.sf.jaer2.devices.config.muxes.Mux;
import net.sf.jaer2.devices.config.pots.AddressedIPotCoarseFine;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.ShiftedSourceBiasCoarseFine;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.PolarityEvent;
import net.sf.jaer2.eventio.events.SampleEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.translators.Translator;

import com.google.common.collect.ImmutableList;

public class SBRet10 extends AERChip implements Translator {
	private static final long serialVersionUID = -4741673273319613810L;

	public SBRet10() {
		this("SBRet10");
	}

	public SBRet10(final String componentName) {
		super(componentName);

		// Masterbias needs to be added first!
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.");

		// Estimated from tox=42A, mu_n=670 cm^2/Vs.
		masterbias.setKPrimeNFet(55e-3f);
		// =45 correct for DVS320.
		masterbias.setMultiplier(4);
		// Masterbias has nfet with w/l=2 at output.
		masterbias.setWOverL(4.8f / 2.4f);

		addSetting(masterbias);

		addSetting(new AddressedIPotCoarseFine("DiffBn", ".", 0, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("OnBn", ".", 1, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("OffBn", ".", 2, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("ApsCasEpc", ".", 3, Pot.Type.CASCODE, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("DiffCasBnc", ".", 4, Pot.Type.CASCODE, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("ApsROSFBn", ".", 5, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("LocalBufBn", ".", 6, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PixInvBn", ".", 7, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PrBp", ".", 8, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("PrSFBp", ".", 9, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("RefrBp", ".", 10, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("AEPdBn", ".", 11, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", 12, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("AEPuXBp", ".", 13, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("AEPuYBp", ".", 14, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("IFThrBn", ".", 15, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("IFRefrBn", ".", 16, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PadFollBn", ".", 17, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("apsOverflowLevel", ".", 18, Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("biasBuffer", ".", 19, Pot.Type.NORMAL, Pot.Sex.N));

		addSetting(new ShiftedSourceBiasCoarseFine("SSP", ".", 20, Pot.Type.NORMAL, Pot.Sex.P));
		addSetting(new ShiftedSourceBiasCoarseFine("SSN", ".", 21, Pot.Type.NORMAL, Pot.Sex.N));

		final ShiftRegisterContainer chipSR = new ShiftRegisterContainer("ChipSR",
			"ShiftRegister for on-chip configuration (muxes, settings).", 56);

		final Mux digMux3 = new DigitalMux("DigMux3", ".");

		digMux3.put(0, "AY179right");
		digMux3.put(1, "Acol");
		digMux3.put(2, "ColArbTopA");
		digMux3.put(3, "ColArbTopR");
		digMux3.put(4, "FF1");
		digMux3.put(5, "FF2");
		digMux3.put(6, "Rcarb");
		digMux3.put(7, "Rcol");
		digMux3.put(8, "Rrow");
		digMux3.put(9, "RxarbE");
		digMux3.put(10, "nAX0");
		digMux3.put(11, "nArowBottom");
		digMux3.put(12, "nArowTop");
		digMux3.put(13, "nRxOn");
		digMux3.put(14, "nResetRxCol");
		digMux3.put(15, "nRYtestpixel");

		chipSR.addSetting(digMux3);

		final Mux digMux2 = new DigitalMux("DigMux2", ".");

		digMux2.put(0, "AY179right");
		digMux2.put(1, "Acol");
		digMux2.put(2, "ColArbTopA");
		digMux2.put(3, "ColArbTopR");
		digMux2.put(4, "FF1");
		digMux2.put(5, "FF2");
		digMux2.put(6, "Rcarb");
		digMux2.put(7, "Rcol");
		digMux2.put(8, "Rrow");
		digMux2.put(9, "RxarbE");
		digMux2.put(10, "nAX0");
		digMux2.put(11, "nArowBottom");
		digMux2.put(12, "nArowTop");
		digMux2.put(13, "nRxOn");
		digMux2.put(14, "biasCalibSpike");
		digMux2.put(15, "nRY179right");

		chipSR.addSetting(digMux2);

		final Mux digMux1 = new DigitalMux("DigMux1", ".");

		digMux1.put(0, "AY179right");
		digMux1.put(1, "Acol");
		digMux1.put(2, "ColArbTopA");
		digMux1.put(3, "ColArbTopR");
		digMux1.put(4, "FF1");
		digMux1.put(5, "FF2");
		digMux1.put(6, "Rcarb");
		digMux1.put(7, "Rcol");
		digMux1.put(8, "Rrow");
		digMux1.put(9, "RxarbE");
		digMux1.put(10, "nAX0");
		digMux1.put(11, "nArowBottom");
		digMux1.put(12, "nArowTop");
		digMux1.put(13, "nRxOn");
		digMux1.put(14, "AY179");
		digMux1.put(15, "RY179");

		chipSR.addSetting(digMux1);

		final Mux digMux0 = new DigitalMux("DigMux0", ".");

		digMux0.put(0, "AY179right");
		digMux0.put(1, "Acol");
		digMux0.put(2, "ColArbTopA");
		digMux0.put(3, "ColArbTopR");
		digMux0.put(4, "FF1");
		digMux0.put(5, "FF2");
		digMux0.put(6, "Rcarb");
		digMux0.put(7, "Rcol");
		digMux0.put(8, "Rrow");
		digMux0.put(9, "RxarbE");
		digMux0.put(10, "nAX0");
		digMux0.put(11, "nArowBottom");
		digMux0.put(12, "nArowTop");
		digMux0.put(13, "nRxOn");
		digMux0.put(14, "AY179");
		digMux0.put(15, "RY179");

		chipSR.addSetting(digMux0);

		final ShiftRegisterContainer chipConfigSR = new ShiftRegisterContainer("chipConfigSR",
			"ShiftRegister for on-chip configuration.", 24);

		chipConfigSR.addSetting(new ShiftRegisterContainer.PlaceholderBits("Placeholder", 17));
		chipConfigSR.addSetting(new ConfigBit("globalShutter", ".", false));
		chipConfigSR.addSetting(new ConfigBit("useAout", ".", true));
		chipConfigSR.addSetting(new ConfigBit("nArow", ".", false));
		chipConfigSR.addSetting(new ConfigBit("hotPixelSuppression", ".", false));
		chipConfigSR.addSetting(new ConfigBit("resetTestpixel", ".", true));
		chipConfigSR.addSetting(new ConfigBit("typeNCalib", ".", false));
		chipConfigSR.addSetting(new ConfigBit("resetCalib", ".", true));

		chipSR.addSetting(chipConfigSR);

		final Mux anaMux2 = new AnalogMux("AnaMux2", ".");

		anaMux2.put(0, "on");
		anaMux2.put(1, "off");
		anaMux2.put(2, "vdiff");
		anaMux2.put(3, "nResetPixel");
		anaMux2.put(4, "pr");
		anaMux2.put(5, "pd");
		anaMux2.put(6, "calibNeuron");
		anaMux2.put(7, "nTimeout_AI");

		chipSR.addSetting(anaMux2);

		final Mux anaMux1 = new AnalogMux("AnaMux1", ".");

		anaMux1.put(0, "on");
		anaMux1.put(1, "off");
		anaMux1.put(2, "vdiff");
		anaMux1.put(3, "nResetPixel");
		anaMux1.put(4, "pr");
		anaMux1.put(5, "pd");
		anaMux1.put(6, "apsgate");
		anaMux1.put(7, "apsout");

		chipSR.addSetting(anaMux1);

		final Mux anaMux0 = new AnalogMux("AnaMux0", ".");

		anaMux0.put(0, "on");
		anaMux0.put(1, "off");
		anaMux0.put(2, "vdiff");
		anaMux0.put(3, "nResetPixel");
		anaMux0.put(4, "pr");
		anaMux0.put(5, "pd");
		anaMux0.put(6, "apsgate");
		anaMux0.put(7, "apsout");

		chipSR.addSetting(anaMux0);

		final Mux biasOutMux = new DigitalMux("BiasOutMux", ".");

		biasOutMux.put(0, "IFThrBn");
		biasOutMux.put(1, "AEPuYBp");
		biasOutMux.put(2, "AEPuXBp");
		biasOutMux.put(3, "LColTimeout");
		biasOutMux.put(4, "AEPdBn");
		biasOutMux.put(5, "RefrBp");
		biasOutMux.put(6, "PrSFBp");
		biasOutMux.put(7, "PrBp");
		biasOutMux.put(8, "PixInvBn");
		biasOutMux.put(9, "LocalBufBn");
		biasOutMux.put(10, "ApsROSFBn");
		biasOutMux.put(11, "DiffCasBnc");
		biasOutMux.put(12, "ApsCasBpc");
		biasOutMux.put(13, "OffBn");
		biasOutMux.put(14, "OnBn");
		biasOutMux.put(15, "DiffBn");

		chipSR.addSetting(biasOutMux);

		addSetting(chipSR);
	}

	@Override
	public int getSizeX() {
		return 240;
	}

	@Override
	public int getSizeY() {
		return 180;
	}

	@Override
	public int getNumCellTypes() {
		return 3;
	}

	@Override
	public ImmutableList<Class<? extends Event>> getEventTypes() {
		return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, SampleEvent.class, SpecialEvent.class);
	}

	@Override
	public void extractEventPacketContainer(final RawEventPacket rawEventPacket,
		final EventPacketContainer eventPacketContainer) {
		// TODO Auto-generated method stub
	}

	@Override
	public void reconstructRawEventPacket(final EventPacketContainer eventPacketContainer,
		final RawEventPacket rawEventPacket) {
		// TODO Auto-generated method stub
	}
}
