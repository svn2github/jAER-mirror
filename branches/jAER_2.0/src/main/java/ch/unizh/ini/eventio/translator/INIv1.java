package ch.unizh.ini.eventio.translator;

import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.EarEvent;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.FrameEvent;
import net.sf.jaer2.eventio.events.IMU6Event;
import net.sf.jaer2.eventio.events.IMU9Event;
import net.sf.jaer2.eventio.events.PolarityEvent;
import net.sf.jaer2.eventio.events.SampleEvent;
import net.sf.jaer2.eventio.events.SpecialEvent;
import net.sf.jaer2.eventio.events.raw.RawEvent;
import net.sf.jaer2.eventio.translators.Translator;

import com.google.common.collect.ImmutableList;

public class INIv1 implements Translator {
	/**
	 * The first 4 bits of the address of a RawEvent are reserved for encoding
	 * the type of event, so as to be able to reliably distinguish between them
	 * and reconstruct/interpret events as required.
	 */
	public static final int CODE_MASK = 0xF0_00_00_00;
	public static final int CODE_SHIFT = 28;

	// Event Codes
	public static final int CODE_SPECIAL_EVENT = 0;
	public static final int CODE_POLARITY_EVENT = 1;
	public static final int CODE_SAMPLE_EVENT = 2;
	public static final int CODE_EAR_EVENT = 3;
	public static final int CODE_BLOCK_HEADER = 14;
	public static final int CODE_BLOCK_CONTENT = 15;

	// Special Event Extractor
	public static final int SPECIAL_EVENT_TYPE_MASK = 0x0F_00_00_00;
	public static final int SPECIAL_EVENT_TYPE_SHIFT = 24;
	public static final int SPECIAL_EVENT_Y_MASK = 0x00_FF_F0_00;
	public static final int SPECIAL_EVENT_Y_SHIFT = 12;
	public static final int SPECIAL_EVENT_X_MASK = 0x00_00_0F_FF;
	public static final int SPECIAL_EVENT_X_SHIFT = 0;

	// Special Event Types
	public static final int SPECIAL_EVENT_TYPE_TIMESTAMP_WRAP = 0;
	public static final int SPECIAL_EVENT_TYPE_EXTERNAL_TRIGGER = 1;
	public static final int SPECIAL_EVENT_TYPE_ROW_ONLY = 2;

	// Polarity Event Extractor
	public static final int POLARITY_EVENT_POL_MASK = 0x01_00_00_00;
	public static final int POLARITY_EVENT_POL_SHIFT = 24;
	public static final int POLARITY_EVENT_Y_MASK = 0x00_FF_F0_00;
	public static final int POLARITY_EVENT_Y_SHIFT = 12;
	public static final int POLARITY_EVENT_X_MASK = 0x00_00_0F_FF;
	public static final int POLARITY_EVENT_X_SHIFT = 0;

	// Sample Event Extractor
	public static final int SAMPLE_EVENT_TYPE_MASK = 0x0F_00_00_00;
	public static final int SAMPLE_EVENT_TYPE_SHIFT = 24;
	public static final int SAMPLE_EVENT_SAMPLE_MASK = 0x00_FF_FF_FF;
	public static final int SAMPLE_EVENT_SAMPLE_SHIFT = 0;

	// Ear Event Extractor
	public static final int EAR_EVENT_GANGLION_MASK = 0x00_FF_00_00;
	public static final int EAR_EVENT_GANGLION_SHIFT = 16;
	public static final int EAR_EVENT_EAR_MASK = 0x00_00_C0_00;
	public static final int EAR_EVENT_EAR_SHIFT = 14;
	public static final int EAR_EVENT_FILTER_MASK = 0x00_00_3F_00;
	public static final int EAR_EVENT_FILTER_SHIFT = 8;
	public static final int EAR_EVENT_CHANNEL_MASK = 0x00_00_00_FF;
	public static final int EAR_EVENT_CHANNEL_SHIFT = 0;

	// Block Header Extractor
	public static final int BLOCK_HEADER_TYPE_MASK = 0x0F_C0_00_00;
	public static final int BLOCK_HEADER_TYPE_SHIFT = 22;
	public static final int BLOCK_HEADER_LENGTH_MASK = 0x00_3F_FF_FF;
	public static final int BLOCK_HEADER_LENGTH_SHIFT = 0;

	// Block Types
	public static final int BLOCK_TYPE_FRAME_EVENT = 0;
	public static final int BLOCK_TYPE_IMU6_EVENT = 1;
	public static final int BLOCK_TYPE_IMU9_EVENT = 2;

	@Override
	public ImmutableList<Class<? extends Event>> getEventTypes() {
		return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, FrameEvent.class, IMU6Event.class,
			IMU9Event.class, SampleEvent.class, EarEvent.class, SpecialEvent.class);
	}

	@Override
	public void extractEventPacketContainer(RawEventPacket rawEventPacket, EventPacketContainer eventPacketContainer) {
		for (final RawEvent rawEvent : rawEventPacket) {
			switch ((rawEvent.getAddress() & CODE_MASK) >>> CODE_SHIFT) {
				case CODE_SPECIAL_EVENT:
					SpecialEvent special = new SpecialEvent(rawEvent.getTimestamp());

					switch ((rawEvent.getAddress() & SPECIAL_EVENT_TYPE_MASK) >>> SPECIAL_EVENT_TYPE_SHIFT) {
						case SPECIAL_EVENT_TYPE_TIMESTAMP_WRAP:
							special.setType(SpecialEvent.Type.TIMESTAMP_WRAP);
							break;

						case SPECIAL_EVENT_TYPE_EXTERNAL_TRIGGER:
							special.setType(SpecialEvent.Type.EXTERNAL_TRIGGER);
							break;

						case SPECIAL_EVENT_TYPE_ROW_ONLY:
							special.setType(SpecialEvent.Type.ROW_ONLY);
							break;

						default:
							break;
					}

					special.setY((short) ((rawEvent.getAddress() & SPECIAL_EVENT_Y_MASK) >>> SPECIAL_EVENT_Y_SHIFT));
					special.setX((short) ((rawEvent.getAddress() & SPECIAL_EVENT_X_MASK) >>> SPECIAL_EVENT_X_SHIFT));

					break;

				case CODE_POLARITY_EVENT:
					PolarityEvent polarity = new PolarityEvent(rawEvent.getTimestamp());

					if (((rawEvent.getAddress() & POLARITY_EVENT_POL_MASK) >>> POLARITY_EVENT_POL_SHIFT) == 0) {
						polarity.setPolarity(PolarityEvent.Polarity.OFF);
					}
					else {
						polarity.setPolarity(PolarityEvent.Polarity.ON);
					}

					polarity.setY((short) ((rawEvent.getAddress() & POLARITY_EVENT_Y_MASK) >>> POLARITY_EVENT_Y_SHIFT));
					polarity.setX((short) ((rawEvent.getAddress() & POLARITY_EVENT_X_MASK) >>> POLARITY_EVENT_X_SHIFT));

					break;

				case CODE_SAMPLE_EVENT:
					SampleEvent sample = new SampleEvent(rawEvent.getTimestamp());

					sample
						.setType((byte) ((rawEvent.getAddress() & SAMPLE_EVENT_TYPE_MASK) >>> SAMPLE_EVENT_TYPE_SHIFT));
					sample.setSample((rawEvent.getAddress() & SAMPLE_EVENT_SAMPLE_MASK) >>> SAMPLE_EVENT_SAMPLE_SHIFT);

					break;

				case CODE_EAR_EVENT:
					EarEvent ear = new EarEvent(rawEvent.getTimestamp());

					switch ((rawEvent.getAddress() & EAR_EVENT_EAR_MASK) >>> EAR_EVENT_EAR_SHIFT) {
						case 0:
							ear.setEar(EarEvent.Ear.LEFT_FRONT);
							break;

						case 1:
							ear.setEar(EarEvent.Ear.RIGHT_FRONT);
							break;

						case 2:
							ear.setEar(EarEvent.Ear.LEFT_BACK);
							break;

						case 3:
							ear.setEar(EarEvent.Ear.RIGHT_BACK);
							break;

						default:
							break;
					}

					ear.setFilter((byte) ((rawEvent.getAddress() & EAR_EVENT_FILTER_MASK) >>> EAR_EVENT_FILTER_SHIFT));
					ear.setGanglion((short) ((rawEvent.getAddress() & EAR_EVENT_GANGLION_MASK) >>> EAR_EVENT_GANGLION_SHIFT));
					ear.setChannel((short) ((rawEvent.getAddress() & EAR_EVENT_CHANNEL_MASK) >>> EAR_EVENT_CHANNEL_SHIFT));

					break;

				case CODE_BLOCK_HEADER:

					break;

				case CODE_BLOCK_CONTENT:

					break;

				default:
					break;
			}
		}
	}

	@Override
	public void reconstructRawEventPacket(final EventPacketContainer eventPacketContainer,
		final RawEventPacket rawEventPacket) {
		// TODO Auto-generated method stub
	}
}
