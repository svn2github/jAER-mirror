package ch.unizh.ini.devices.components.aer;

import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.devices.config.muxes.Mux;
import net.sf.jaer2.devices.config.pots.AddressedIPotCoarseFine;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.ShiftedSourceBiasCoarseFine;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.FrameEvent;
import net.sf.jaer2.eventio.events.PolarityEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.translators.DeviceTranslator;
import net.sf.jaer2.util.SSHSNode;

import com.google.common.collect.ImmutableList;

public class SBRet10 extends AERChip {
	public SBRet10(final SSHSNode componentConfigNode) {
		this("SBRet10", componentConfigNode);
	}

	public SBRet10(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);

		// Masterbias needs to be added first!
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.",
			componentConfigNode);

		// Estimated from tox=42A, mu_n=670 cm^2/Vs.
		masterbias.setKPrimeNFet(55e-3f);
		// =45 correct for DVS320.
		masterbias.setMultiplier(4);
		// Masterbias has nfet with w/l=2 at output.
		masterbias.setWOverL(4.8f / 2.4f);

		addSetting(masterbias);

		addSetting(new AddressedIPotCoarseFine("DiffBn", ".", componentConfigNode, 0, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("OnBn", ".", componentConfigNode, 1, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("OffBn", ".", componentConfigNode, 2, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("ApsCasEpc", ".", componentConfigNode, 3, masterbias, Pot.Type.CASCODE,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("DiffCasBnc", ".", componentConfigNode, 4, masterbias, Pot.Type.CASCODE,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("ApsROSFBn", ".", componentConfigNode, 5, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("LocalBufBn", ".", componentConfigNode, 6, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PixInvBn", ".", componentConfigNode, 7, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PrBp", ".", componentConfigNode, 8, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("PrSFBp", ".", componentConfigNode, 9, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("RefrBp", ".", componentConfigNode, 10, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("AEPdBn", ".", componentConfigNode, 11, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", componentConfigNode, 12, masterbias,
			Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("AEPuXBp", ".", componentConfigNode, 13, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("AEPuYBp", ".", componentConfigNode, 14, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new AddressedIPotCoarseFine("IFThrBn", ".", componentConfigNode, 15, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("IFRefrBn", ".", componentConfigNode, 16, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("PadFollBn", ".", componentConfigNode, 17, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("apsOverflowLevel", ".", componentConfigNode, 18, masterbias,
			Pot.Type.NORMAL, Pot.Sex.N));
		addSetting(new AddressedIPotCoarseFine("biasBuffer", ".", componentConfigNode, 19, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));

		addSetting(new ShiftedSourceBiasCoarseFine("SSP", ".", componentConfigNode, 20, masterbias, Pot.Type.NORMAL,
			Pot.Sex.P));
		addSetting(new ShiftedSourceBiasCoarseFine("SSN", ".", componentConfigNode, 21, masterbias, Pot.Type.NORMAL,
			Pot.Sex.N));

		final ShiftRegisterContainer chipSR = new ShiftRegisterContainer("ChipSR",
			"ShiftRegister for on-chip configuration (muxes, settings).", componentConfigNode, 56);

		final Mux digMux3 = new Mux("DigMux3", ".", chipSR.getConfigNode(), 4);

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

		final Mux digMux2 = new Mux("DigMux2", ".", chipSR.getConfigNode(), 4);

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

		final Mux digMux1 = new Mux("DigMux1", ".", chipSR.getConfigNode(), 4);

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

		final Mux digMux0 = new Mux("DigMux0", ".", chipSR.getConfigNode(), 4);

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
			"ShiftRegister for on-chip configuration.", chipSR.getConfigNode(), 24);

		chipConfigSR.addSetting(new ShiftRegisterContainer.PlaceholderBits("Placeholder", 17));
		chipConfigSR.addSetting(new ConfigBit("globalShutter", ".", chipConfigSR.getConfigNode(), false));
		chipConfigSR.addSetting(new ConfigBit("useAout", ".", chipConfigSR.getConfigNode(), true));
		chipConfigSR.addSetting(new ConfigBit("nArow", ".", chipConfigSR.getConfigNode(), false));
		chipConfigSR.addSetting(new ConfigBit("hotPixelSuppression", ".", chipConfigSR.getConfigNode(), false));
		chipConfigSR.addSetting(new ConfigBit("resetTestpixel", ".", chipConfigSR.getConfigNode(), true));
		chipConfigSR.addSetting(new ConfigBit("typeNCalib", ".", chipConfigSR.getConfigNode(), false));
		chipConfigSR.addSetting(new ConfigBit("resetCalib", ".", chipConfigSR.getConfigNode(), true));

		chipSR.addSetting(chipConfigSR);

		final Mux anaMux2 = new Mux("AnaMux2", ".", chipSR.getConfigNode(), 4);

		anaMux2.put(0, "on", 1);
		anaMux2.put(1, "off", 3);
		anaMux2.put(2, "vdiff", 5);
		anaMux2.put(3, "nResetPixel", 7);
		anaMux2.put(4, "pr", 9);
		anaMux2.put(5, "pd", 11);
		anaMux2.put(6, "calibNeuron", 13);
		anaMux2.put(7, "nTimeout_AI", 15);

		chipSR.addSetting(anaMux2);

		final Mux anaMux1 = new Mux("AnaMux1", ".", chipSR.getConfigNode(), 4);

		anaMux1.put(0, "on", 1);
		anaMux1.put(1, "off", 3);
		anaMux1.put(2, "vdiff", 5);
		anaMux1.put(3, "nResetPixel", 7);
		anaMux1.put(4, "pr", 9);
		anaMux1.put(5, "pd", 11);
		anaMux1.put(6, "apsgate", 13);
		anaMux1.put(7, "apsout", 15);

		chipSR.addSetting(anaMux1);

		final Mux anaMux0 = new Mux("AnaMux0", ".", chipSR.getConfigNode(), 4);

		anaMux0.put(0, "on", 1);
		anaMux0.put(1, "off", 3);
		anaMux0.put(2, "vdiff", 5);
		anaMux0.put(3, "nResetPixel", 7);
		anaMux0.put(4, "pr", 9);
		anaMux0.put(5, "pd", 11);
		anaMux0.put(6, "apsgate", 13);
		anaMux0.put(7, "apsout", 15);

		chipSR.addSetting(anaMux0);

		final Mux biasOutMux = new Mux("BiasOutMux", ".", chipSR.getConfigNode(), 4);

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

	public static final class Translator implements DeviceTranslator {
		@Override
		public ImmutableList<Class<? extends Event>> getEventTypes() {
			return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, FrameEvent.class, SpecialEvent.class);
		}

		@Override
		public void extractRawEventPacket(ByteBuffer buffer, RawEventPacket rawEventPacket) {
			// TODO Auto-generated method stub
		}
	}
}
