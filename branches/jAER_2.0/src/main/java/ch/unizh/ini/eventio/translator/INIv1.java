package ch.unizh.ini.eventio.translator;

import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacketContainer;
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
	public ImmutableList<Class<? extends Event>> getRawEventToEventMappings() {
		return ImmutableList.<Class<? extends Event>> of(SpecialEvent.class, PolarityEvent.class, SampleEvent.class,
			EarEvent.class, FrameEvent.class, IMU6Event.class, IMU9Event.class);
	}

	@Override
	public void extractEventFromRawEvent(final RawEvent rawEventIn, final EventPacketContainer eventPacketContainerOut) {
		switch ((rawEventIn.getAddress() & INIv1.CODE_MASK) >>> INIv1.CODE_SHIFT) {
			case CODE_SPECIAL_EVENT:
				final SpecialEvent special = new SpecialEvent(rawEventIn.getTimestamp());

				switch ((rawEventIn.getAddress() & INIv1.SPECIAL_EVENT_TYPE_MASK) >>> INIv1.SPECIAL_EVENT_TYPE_SHIFT) {
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

				special
					.setY((short) ((rawEventIn.getAddress() & INIv1.SPECIAL_EVENT_Y_MASK) >>> INIv1.SPECIAL_EVENT_Y_SHIFT));
				special
					.setX((short) ((rawEventIn.getAddress() & INIv1.SPECIAL_EVENT_X_MASK) >>> INIv1.SPECIAL_EVENT_X_SHIFT));

				eventPacketContainerOut.getPacket(SpecialEvent.class, eventPacketContainerOut.getSourceId()).append(
					special);
				break;

			case CODE_POLARITY_EVENT:
				final PolarityEvent polarity = new PolarityEvent(rawEventIn.getTimestamp());

				if (((rawEventIn.getAddress() & INIv1.POLARITY_EVENT_POL_MASK) >>> INIv1.POLARITY_EVENT_POL_SHIFT) == 0) {
					polarity.setPolarity(PolarityEvent.Polarity.OFF);
				}
				else {
					polarity.setPolarity(PolarityEvent.Polarity.ON);
				}

				polarity
					.setY((short) ((rawEventIn.getAddress() & INIv1.POLARITY_EVENT_Y_MASK) >>> INIv1.POLARITY_EVENT_Y_SHIFT));
				polarity
					.setX((short) ((rawEventIn.getAddress() & INIv1.POLARITY_EVENT_X_MASK) >>> INIv1.POLARITY_EVENT_X_SHIFT));

				eventPacketContainerOut.getPacket(PolarityEvent.class, eventPacketContainerOut.getSourceId()).append(
					polarity);
				break;

			case CODE_SAMPLE_EVENT:
				final SampleEvent sample = new SampleEvent(rawEventIn.getTimestamp());

				sample
					.setType((byte) ((rawEventIn.getAddress() & INIv1.SAMPLE_EVENT_TYPE_MASK) >>> INIv1.SAMPLE_EVENT_TYPE_SHIFT));
				sample
					.setSample((rawEventIn.getAddress() & INIv1.SAMPLE_EVENT_SAMPLE_MASK) >>> INIv1.SAMPLE_EVENT_SAMPLE_SHIFT);

				eventPacketContainerOut.getPacket(SampleEvent.class, eventPacketContainerOut.getSourceId()).append(
					sample);
				break;

			case CODE_EAR_EVENT:
				final EarEvent ear = new EarEvent(rawEventIn.getTimestamp());

				switch ((rawEventIn.getAddress() & INIv1.EAR_EVENT_EAR_MASK) >>> INIv1.EAR_EVENT_EAR_SHIFT) {
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

				ear.setFilter((byte) ((rawEventIn.getAddress() & INIv1.EAR_EVENT_FILTER_MASK) >>> INIv1.EAR_EVENT_FILTER_SHIFT));
				ear.setGanglion((short) ((rawEventIn.getAddress() & INIv1.EAR_EVENT_GANGLION_MASK) >>> INIv1.EAR_EVENT_GANGLION_SHIFT));
				ear.setChannel((short) ((rawEventIn.getAddress() & INIv1.EAR_EVENT_CHANNEL_MASK) >>> INIv1.EAR_EVENT_CHANNEL_SHIFT));

				eventPacketContainerOut.getPacket(EarEvent.class, eventPacketContainerOut.getSourceId()).append(ear);
				break;

			case CODE_BLOCK_HEADER:

				break;

			case CODE_BLOCK_CONTENT:

				break;

			default:
				break;
		}
	}

	@Override
	public ImmutableList<Class<? extends Event>> getEventToRawEventMappings() {
		return ImmutableList.<Class<? extends Event>> of(SpecialEvent.class, PolarityEvent.class, SampleEvent.class,
			EarEvent.class, FrameEvent.class, IMU6Event.class, IMU9Event.class);
	}

	@Override
	public void extractRawEventFromEvent(Event eventIn, RawEventPacketContainer rawEventPacketContainerOut) {
		int address = 0;

		if (event instanceof SpecialEvent) {
			final SpecialEvent special = (SpecialEvent) event;

			address = (INIv1.CODE_SPECIAL_EVENT << INIv1.CODE_SHIFT);

			switch (special.getType()) {
				case TIMESTAMP_WRAP:
					address |= (INIv1.SPECIAL_EVENT_TYPE_TIMESTAMP_WRAP << INIv1.SPECIAL_EVENT_TYPE_SHIFT);
					break;

				case EXTERNAL_TRIGGER:
					address |= (INIv1.SPECIAL_EVENT_TYPE_EXTERNAL_TRIGGER << INIv1.SPECIAL_EVENT_TYPE_SHIFT);
					break;

				case ROW_ONLY:
					address |= (INIv1.SPECIAL_EVENT_TYPE_ROW_ONLY << INIv1.SPECIAL_EVENT_TYPE_SHIFT);
					break;

				default:
					break;
			}

			address |= ((special.getY() << INIv1.SPECIAL_EVENT_Y_SHIFT) & INIv1.SPECIAL_EVENT_Y_MASK);
			address |= ((special.getX() << INIv1.SPECIAL_EVENT_X_SHIFT) & INIv1.SPECIAL_EVENT_X_MASK);
		}
		else if (event instanceof PolarityEvent) {
			final PolarityEvent polarity = (PolarityEvent) event;

			address = (INIv1.CODE_POLARITY_EVENT << INIv1.CODE_SHIFT);

			if (polarity.getPolarity() == PolarityEvent.Polarity.ON) {
				address |= (1 << INIv1.POLARITY_EVENT_POL_SHIFT);
			}
			// OFF polarity doesn't need any assignment, since the default
			// value for address is already zero.

			address |= ((polarity.getY() << INIv1.POLARITY_EVENT_Y_SHIFT) & INIv1.POLARITY_EVENT_Y_MASK);
			address |= ((polarity.getX() << INIv1.POLARITY_EVENT_X_SHIFT) & INIv1.POLARITY_EVENT_X_MASK);
		}
		else if (event instanceof SampleEvent) {
			final SampleEvent sample = (SampleEvent) event;

			address = (INIv1.CODE_SAMPLE_EVENT << INIv1.CODE_SHIFT);

			address |= ((sample.getType() << INIv1.SAMPLE_EVENT_TYPE_SHIFT) & INIv1.SAMPLE_EVENT_TYPE_MASK);
			address |= ((sample.getSample() << INIv1.SAMPLE_EVENT_SAMPLE_SHIFT) & INIv1.SAMPLE_EVENT_SAMPLE_MASK);
		}
		else if (event instanceof EarEvent) {
			final EarEvent ear = (EarEvent) event;

			address = (INIv1.CODE_EAR_EVENT << INIv1.CODE_SHIFT);

			switch (ear.getEar()) {
				case LEFT_FRONT:
					address |= (0 << INIv1.EAR_EVENT_EAR_SHIFT);
					break;

				case RIGHT_FRONT:
					address |= (1 << INIv1.EAR_EVENT_EAR_SHIFT);
					break;

				case LEFT_BACK:
					address |= (2 << INIv1.EAR_EVENT_EAR_SHIFT);
					break;

				case RIGHT_BACK:
					address |= (3 << INIv1.EAR_EVENT_EAR_SHIFT);
					break;

				default:
					break;
			}

			address |= ((ear.getFilter() << INIv1.EAR_EVENT_FILTER_SHIFT) & INIv1.EAR_EVENT_FILTER_MASK);
			address |= ((ear.getGanglion() << INIv1.EAR_EVENT_GANGLION_SHIFT) & INIv1.EAR_EVENT_GANGLION_MASK);
			address |= ((ear.getChannel() << INIv1.EAR_EVENT_CHANNEL_SHIFT) & INIv1.EAR_EVENT_CHANNEL_MASK);
		}
		else if (event instanceof FrameEvent) {
			final FrameEvent frame = (FrameEvent) event;

			final int compressedFrameSize = (((frame.getSizeY() * frame.getSizeX() * frame.getDepthADC()) + (60 - 1)) / 60);
			final int numberOfBlockContents = 6 + compressedFrameSize;
			final RawEvent[] rawEvents = new RawEvent[1 + numberOfBlockContents];

			// First one is the Block Header, with the main time-stamp.
			address = (INIv1.CODE_BLOCK_HEADER << INIv1.CODE_SHIFT);
			address |= (INIv1.BLOCK_TYPE_FRAME_EVENT << INIv1.BLOCK_HEADER_TYPE_SHIFT);
			address |= ((numberOfBlockContents << INIv1.BLOCK_HEADER_LENGTH_SHIFT) & INIv1.BLOCK_HEADER_LENGTH_MASK);

			rawEvents[0] = new RawEvent(address, event.getTimestamp());

			// The following six Block Contents contain the six time-stamps
			// (SOE, EOE, SORR, EORR, SOSR, EOSR), as well as the Y, X and
			// ADCDepth dimensions in the first three address parts.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= frame.getSizeY();

			rawEvents[1] = new RawEvent(address, frame.getTsStartOfExposure());

			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= frame.getSizeX();

			rawEvents[2] = new RawEvent(address, frame.getTsEndOfExposure());

			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= frame.getDepthADC();

			rawEvents[3] = new RawEvent(address, frame.getTsStartOfResetRead());

			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);

			rawEvents[4] = new RawEvent(address, frame.getTsEndOfResetRead());

			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);

			rawEvents[5] = new RawEvent(address, frame.getTsStartOfSignalRead());

			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);

			rawEvents[6] = new RawEvent(address, frame.getTsEndOfSignalRead());

			return rawEvents;
		}
		else if (event instanceof IMU6Event) {
			final IMU6Event imu6 = (IMU6Event) event;

			final int numberOfBlockContents = 3; // accel, gyro and temp.
			final RawEvent[] rawEvents = new RawEvent[1 + numberOfBlockContents];

			// First one is the Block Header, with the main time-stamp.
			address = (INIv1.CODE_BLOCK_HEADER << INIv1.CODE_SHIFT);
			address |= (INIv1.BLOCK_TYPE_IMU6_EVENT << INIv1.BLOCK_HEADER_TYPE_SHIFT);
			address |= ((numberOfBlockContents << INIv1.BLOCK_HEADER_LENGTH_SHIFT) & INIv1.BLOCK_HEADER_LENGTH_MASK);

			rawEvents[0] = new RawEvent(address, event.getTimestamp());

			// Then the three Accelerometer axes.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= imu6.getAccelX();

			rawEvents[1] = new RawEvent(address, ((imu6.getAccelY() << 16) | imu6.getAccelZ()));

			// Then the three Gyroscope axes.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= imu6.getGyroX();

			rawEvents[2] = new RawEvent(address, ((imu6.getGyroY() << 16) | imu6.getGyroZ()));

			// And finally the Temperature measurement.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);

			rawEvents[3] = new RawEvent(address, (imu6.getTemp() & 0x00_00_FF_FF));

			return rawEvents;
		}
		else if (event instanceof IMU9Event) {
			final IMU9Event imu9 = (IMU9Event) event;

			final int numberOfBlockContents = 4; // accel, gyro, compass and
													// temp.
			final RawEvent[] rawEvents = new RawEvent[1 + numberOfBlockContents];

			// First one is the Block Header, with the main time-stamp.
			address = (INIv1.CODE_BLOCK_HEADER << INIv1.CODE_SHIFT);
			address |= (INIv1.BLOCK_TYPE_IMU9_EVENT << INIv1.BLOCK_HEADER_TYPE_SHIFT);
			address |= ((numberOfBlockContents << INIv1.BLOCK_HEADER_LENGTH_SHIFT) & INIv1.BLOCK_HEADER_LENGTH_MASK);

			rawEvents[0] = new RawEvent(address, event.getTimestamp());

			// Then the three Accelerometer axes.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= imu9.getAccelX();

			rawEvents[1] = new RawEvent(address, ((imu9.getAccelY() << 16) | imu9.getAccelZ()));

			// Then the three Gyroscope axes.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= imu9.getGyroX();

			rawEvents[2] = new RawEvent(address, ((imu9.getGyroY() << 16) | imu9.getGyroZ()));

			// Then the three Compass axes.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);
			address |= imu9.getCompX();

			rawEvents[3] = new RawEvent(address, ((imu9.getCompY() << 16) | imu9.getCompZ()));

			// And finally the Temperature measurement.
			address = (INIv1.CODE_BLOCK_CONTENT << INIv1.CODE_SHIFT);

			rawEvents[4] = new RawEvent(address, (imu9.getTemp() & 0x00_00_FF_FF));

			return rawEvents;
		}

		// Return one RawEvent (default case). If more than one are generated,
		// they will return a bigger array above inside their transform code.
		return new RawEvent[] { new RawEvent(address, event.getTimestamp()) };
	}
}
