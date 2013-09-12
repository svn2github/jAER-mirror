package ch.unizh.ini.devices.components.aer;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.muxes.AnalogMux;
import net.sf.jaer2.devices.config.muxes.BiasMux;
import net.sf.jaer2.devices.config.muxes.DigitalMux;
import net.sf.jaer2.devices.config.pots.AddressedIPotCoarseFine;
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
	public SBRet10() {
		addSetting(new AddressedIPotCoarseFine("DiffBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 0);
		addSetting(new AddressedIPotCoarseFine("OnBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 1);
		addSetting(new AddressedIPotCoarseFine("OffBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 2);
		addSetting(new AddressedIPotCoarseFine("ApsCasEpc", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 3);
		addSetting(new AddressedIPotCoarseFine("DiffCasBnc", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 4);
		addSetting(new AddressedIPotCoarseFine("ApsROSFBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 5);
		addSetting(new AddressedIPotCoarseFine("LocalBufBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 6);
		addSetting(new AddressedIPotCoarseFine("PixInvBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 7);
		addSetting(new AddressedIPotCoarseFine("PrBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		addSetting(new AddressedIPotCoarseFine("PrSFBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 9);
		addSetting(new AddressedIPotCoarseFine("RefrBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 10);
		addSetting(new AddressedIPotCoarseFine("AEPdBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 11);
		addSetting(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 12);
		addSetting(new AddressedIPotCoarseFine("AEPuXBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 13);
		addSetting(new AddressedIPotCoarseFine("AEPuYBp", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 14);
		addSetting(new AddressedIPotCoarseFine("IFThrBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 15);
		addSetting(new AddressedIPotCoarseFine("IFRefrBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 16);
		addSetting(new AddressedIPotCoarseFine("PadFollBn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 17);
		addSetting(new AddressedIPotCoarseFine("apsOverflowLevel", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 18);
		addSetting(new AddressedIPotCoarseFine("biasBuffer", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 19);

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
	public int getNumCells() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int getNumPixels() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public boolean compatibleWith(final AERChip chip) {
		// TODO Auto-generated method stub
		return false;
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

	@Override
	public String toString() {
		return getClass().getSimpleName();
	}

	@Override
	public String getName() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Pane getConfigGUI() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void setProgrammer(final Controller programmer) {
		// TODO Auto-generated method stub
	}

	@Override
	public void addSetting(final ConfigBase setting, final int address) {
		// TODO Auto-generated method stub
	}
}
