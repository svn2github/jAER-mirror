package ch.unizh.ini.devices.components.aer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.muxes.AnalogMux;
import net.sf.jaer2.devices.config.muxes.BiasMux;
import net.sf.jaer2.devices.config.muxes.DigitalMux;
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
		final Masterbias masterbias = new Masterbias("Masterbias", ".");
		addSetting(masterbias, AERChip.MASTERBIAS_ADDRESS);

		// Estimated from tox=42A, mu_n=670 cm^2/Vs.
		masterbias.setKPrimeNFet(55e-3f);
		// =45 correct for DVS320.
		masterbias.setMultiplier(4);
		// Masterbias has nfet with w/l=2 at output.
		masterbias.setWOverL(4.8f / 2.4f);

		addSetting(new AddressedIPotCoarseFine("DiffBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 0);
		addSetting(new AddressedIPotCoarseFine("OnBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 1);
		addSetting(new AddressedIPotCoarseFine("OffBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 2);
		addSetting(new AddressedIPotCoarseFine("ApsCasEpc", ".", Pot.Type.CASCODE, Pot.Sex.P), 3);
		addSetting(new AddressedIPotCoarseFine("DiffCasBnc", ".", Pot.Type.CASCODE, Pot.Sex.N), 4);
		addSetting(new AddressedIPotCoarseFine("ApsROSFBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 5);
		addSetting(new AddressedIPotCoarseFine("LocalBufBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 6);
		addSetting(new AddressedIPotCoarseFine("PixInvBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 7);
		addSetting(new AddressedIPotCoarseFine("PrBp", ".", Pot.Type.NORMAL, Pot.Sex.P), 8);
		addSetting(new AddressedIPotCoarseFine("PrSFBp", ".", Pot.Type.NORMAL, Pot.Sex.P), 9);
		addSetting(new AddressedIPotCoarseFine("RefrBp", ".", Pot.Type.NORMAL, Pot.Sex.P), 10);
		addSetting(new AddressedIPotCoarseFine("AEPdBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 11);
		addSetting(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 12);
		addSetting(new AddressedIPotCoarseFine("AEPuXBp", ".", Pot.Type.NORMAL, Pot.Sex.P), 13);
		addSetting(new AddressedIPotCoarseFine("AEPuYBp", ".", Pot.Type.NORMAL, Pot.Sex.P), 14);
		addSetting(new AddressedIPotCoarseFine("IFThrBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 15);
		addSetting(new AddressedIPotCoarseFine("IFRefrBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 16);
		addSetting(new AddressedIPotCoarseFine("PadFollBn", ".", Pot.Type.NORMAL, Pot.Sex.N), 17);
		addSetting(new AddressedIPotCoarseFine("apsOverflowLevel", ".", Pot.Type.NORMAL, Pot.Sex.N), 18);
		addSetting(new AddressedIPotCoarseFine("biasBuffer", ".", Pot.Type.NORMAL, Pot.Sex.N), 19);

		addSetting(new ShiftedSourceBiasCoarseFine("SSP", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 20);
		addSetting(new ShiftedSourceBiasCoarseFine("SSN", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 21);

		addSetting(new ConfigBit("resetCalib", ".", true), 0);
		addSetting(new ConfigBit("typeNCalib", ".", false), 1);
		addSetting(new ConfigBit("resetTestpixel", ".", true), 2);
		addSetting(new ConfigBit("hotPixelSuppression", ".", false), 3);
		addSetting(new ConfigBit("nArow", ".", false), 4);
		addSetting(new ConfigBit("useAout", ".", true), 5);
		addSetting(new ConfigBit("globalShutter", ".", false), 6);

		addSetting(new AnalogMux("AnaMux2", "."), 1);
		addSetting(new AnalogMux("AnaMux1", "."), 2);
		addSetting(new AnalogMux("AnaMux0", "."), 3);

		addSetting(new DigitalMux("DigMux3", "."), 1);
		addSetting(new DigitalMux("DigMux2", "."), 2);
		addSetting(new DigitalMux("DigMux1", "."), 3);
		addSetting(new DigitalMux("DigMux0", "."), 4);

		addSetting(new BiasMux("BiasOutMux", "."), 0);
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
