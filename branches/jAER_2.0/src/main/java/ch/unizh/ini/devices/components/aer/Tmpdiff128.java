package ch.unizh.ini.devices.components.aer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.eventpackets.EventPacket;
import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.PolarityEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.events.SpecialEvent.Type;
import net.sf.jaer2.eventio.events.raw.RawEvent;
import net.sf.jaer2.eventio.translators.Translator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableList;

public class Tmpdiff128 extends AERChip implements Translator {
	private static final long serialVersionUID = -7614038645899184474L;

	/** Local logger for log messages. */
	private final static Logger logger = LoggerFactory.getLogger(Tmpdiff128.class);

	public Tmpdiff128() {
		this("Tmpdiff128");
	}

	public Tmpdiff128(final String componentName) {
		super(componentName);

		// Masterbias needs to be added first!
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.");
		addSetting(masterbias);

		final ShiftRegisterContainer chipSR = new ShiftRegisterContainer("ChipSR",
			"ShiftRegister for on-chip bias generator configuration.", 288);

		chipSR.addSetting(new IPot("cas", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		chipSR.addSetting(new IPot("injGnd", ".", masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		chipSR.addSetting(new IPot("reqPd", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("puX", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("diffOff", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("req", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("refr", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("puY", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("diffOn", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("diff", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("foll", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("pr", ".", masterbias, Pot.Type.NORMAL, Pot.Sex.P));

		addSetting(chipSR);
	}

	@Override
	public int getSizeX() {
		return 128;
	}

	@Override
	public int getSizeY() {
		return 128;
	}

	@Override
	public int getNumCellTypes() {
		return 2;
	}

	@Override
	public ImmutableList<Class<? extends Event>> getEventTypes() {
		return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, SpecialEvent.class);
	}

	@Override
	public void extractEventPacketContainer(final RawEventPacket rawEventPacket,
		final EventPacketContainer eventPacketContainer) {
		/*
		 * setTypemask((short) 1);
		 * setTypeshift((byte) 0);
		 * setFlipx(true);
		 * setFlipy(false);
		 * setFliptype(true);
		 */
		final short XMASK = 0x00FE, XSHIFT = 1, YMASK = 0x7F00, YSHIFT = 8;
		final int SYNC_EVENT_BITMASK = 0x8000, SPECIAL_EVENT_BIT_MASK = 0x80000000;

		int printedSyncBitWarningCount = 3;
		final int sxm = getSizeX() - 1;

		final EventPacket<PolarityEvent> eventPacketPolarity = eventPacketContainer.createPacket(PolarityEvent.class,
			eventPacketContainer.getSourceId());
		final EventPacket<SpecialEvent> eventPacketSpecial = eventPacketContainer.createPacket(SpecialEvent.class,
			eventPacketContainer.getSourceId());

		for (final RawEvent rawEvent : rawEventPacket) {
			final int addr = rawEvent.getAddress();

			if ((addr & (SYNC_EVENT_BITMASK | SPECIAL_EVENT_BIT_MASK)) != 0) {
				// Special Event (MSB is set)
				final SpecialEvent specEvent = new SpecialEvent(rawEvent.getTimestamp());

				specEvent.setX((short) -1);
				specEvent.setY((short) -1);

				specEvent.setType(Type.SYNC);

				eventPacketSpecial.append(specEvent);

				if (printedSyncBitWarningCount > 0) {
					Tmpdiff128.logger
						.warn("Raw address {} is >32767 (0xEFFF), either sync or stereo bit is set!", addr);
					printedSyncBitWarningCount--;

					if (printedSyncBitWarningCount == 0) {
						Tmpdiff128.logger.warn("Suppressing futher warnings about MSB of raw address.");
					}
				}
			}
			else {
				final PolarityEvent polEvent = new PolarityEvent(rawEvent.getTimestamp());

				polEvent.setX((short) (sxm - ((short) ((addr & XMASK) >>> XSHIFT))));
				polEvent.setY((short) ((addr & YMASK) >>> YSHIFT));

				polEvent.setPolarity((((byte) ((1 - addr) & 1)) == 0) ? (PolarityEvent.Polarity.OFF)
					: (PolarityEvent.Polarity.ON));

				eventPacketPolarity.append(polEvent);
			}
		}
	}

	@Override
	public void reconstructRawEventPacket(final EventPacketContainer eventPacketContainer,
		final RawEventPacket rawEventPacket) {
		// TODO Auto-generated method stub
	}
}
