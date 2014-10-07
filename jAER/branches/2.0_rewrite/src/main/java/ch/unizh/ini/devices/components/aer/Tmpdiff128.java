package ch.unizh.ini.devices.components.aer;

import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Masterbias;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.PolarityEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.events.raw.RawEvent;
import net.sf.jaer2.eventio.translators.DeviceTranslator;
import net.sf.jaer2.util.SSHSNode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableList;

public class Tmpdiff128 extends AERChip {
	/** Local logger for log messages. */
	private final static Logger logger = LoggerFactory.getLogger(Tmpdiff128.class);

	public Tmpdiff128(final SSHSNode componentConfigNode) {
		this("Tmpdiff128", componentConfigNode);
	}

	public Tmpdiff128(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);

		// Masterbias needs to be added first!
		final Masterbias masterbias = new Masterbias("Masterbias", "Masterbias for on-chip bias generator.",
			componentConfigNode);
		addSetting(masterbias);

		final ShiftRegisterContainer chipSR = new ShiftRegisterContainer("ChipSR",
			"ShiftRegister for on-chip bias generator configuration.", componentConfigNode, 288);

		chipSR.addSetting(new IPot("cas", ".", chipSR.getConfigNode(), masterbias, Pot.Type.CASCODE, Pot.Sex.N));
		chipSR.addSetting(new IPot("injGnd", ".", chipSR.getConfigNode(), masterbias, Pot.Type.CASCODE, Pot.Sex.P));
		chipSR.addSetting(new IPot("reqPd", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("puX", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("diffOff", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("req", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("refr", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("puY", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("diffOn", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("diff", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.N));
		chipSR.addSetting(new IPot("foll", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.P));
		chipSR.addSetting(new IPot("pr", ".", chipSR.getConfigNode(), masterbias, Pot.Type.NORMAL, Pot.Sex.P));

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

	public static final class Translator implements DeviceTranslator {
		@Override
		public ImmutableList<Class<? extends Event>> getEventTypes() {
			return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, SpecialEvent.class);
		}

		/**
		 * SYNC events are detected when this bit mask is detected in the input
		 * event stream.
		 */
		private static final int SYNC_EVENT_BITMASK = 0x8000;

		private int printedSyncEventWarningCount = 0;
		private int wrapAdd = 0;

		@Override
		public void extractRawEventPacket(final ByteBuffer buffer, final RawEventPacket rawEventPacket) {
			int address = 0, timestamp = 0, lastTimestamp = 0;
			int bytesSent = buffer.limit();

			if ((bytesSent % 4) != 0) {
				Tmpdiff128.logger.warn("{} bytes sent, which is not a multiple of 4.", bytesSent);

				// truncate off any extra part-event
				bytesSent = (bytesSent / 4) * 4;
			}

			for (int i = 0; i < bytesSent; i += 4) {
				if ((buffer.get(i + 3) & 0x80) == 0x80) {
					// timestamp bit 15 is one -> wrap: now we need to increment
					// the wrapAdd, uses only 14 bit timestamps
					wrapAdd += 0x4000;
				}
				else if ((buffer.get(i + 3) & 0x40) == 0x40) {
					// timestamp bit 14 is one -> wrapAdd reset: this firmware
					// version uses reset events to reset timestamps
					wrapAdd = 0;
					lastTimestamp = 0;
				}
				else if (i >= rawEventPacket.capacity()) {
					// just do nothing, throw away events
					continue;
				}
				else {
					// address is LSB MSB
					address = (buffer.get(i) & 0xFF) | ((buffer.get(i + 1) & 0xFF) << 8);

					// same for timestamp, LSB MSB
					// 15 bit value of timestamp in TICK_US tick
					timestamp = (((buffer.get(i + 2) & 0xFF) | ((buffer.get(i + 3) & 0xFF) << 8)) + wrapAdd);

					// and convert to 1us tick
					if (timestamp < lastTimestamp) {
						Tmpdiff128.logger.info("non-monotonic timestamp: lastTimestamp={}, timestamp={}",
							lastTimestamp, timestamp);
					}

					lastTimestamp = timestamp;

					// this is USB2AERmini2 or StereoRetina board which have 1us
					// timestamp tick
					if ((address & Translator.SYNC_EVENT_BITMASK) != 0) {
						if (printedSyncEventWarningCount < 10) {
							if (printedSyncEventWarningCount < 10) {
								Tmpdiff128.logger.info("sync event at timestamp={}", timestamp);
							}
							else {
								Tmpdiff128.logger.warn("disabling further printing of sync events");
							}

							printedSyncEventWarningCount++;
						}
					}

					rawEventPacket.addRawEvent(new RawEvent(address, timestamp));
				}
			}
		}
	}
}
