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
import net.sf.jaer2.eventio.translators.Translator;

import com.google.common.collect.ImmutableList;

public class INIv1 implements Translator {
	/**
	 * The first 4 bits of the address are reserved for encoding the type of
	 * event, so as to be able to reliably distinguish between them and
	 * reconstruct/interpret events as needed.
	 */
	// private static final int CODE_MASK = 0xF0000000;
	// private static final int CODE_BITS = Integer.bitCount(CODE_MASK);
	// private static final int CODE_SHIFT =
	// Integer.numberOfTrailingZeros(CODE_MASK);

	// private static final int ADDR_MASK = 0x0FFFFFFF;
	// private static final int ADDR_BITS = Integer.bitCount(ADDR_MASK);
	// private static final int ADDR_SHIFT =
	// Integer.numberOfTrailingZeros(ADDR_MASK);

	@Override
	public ImmutableList<Class<? extends Event>> getEventTypes() {
		return ImmutableList.<Class<? extends Event>> of(PolarityEvent.class, FrameEvent.class, IMU6Event.class,
			IMU9Event.class, SampleEvent.class, EarEvent.class, SpecialEvent.class);
	}

	@Override
	public void extractEventPacketContainer(RawEventPacket rawEventPacket, EventPacketContainer eventPacketContainer) {
		// if ((code >= (1 << CODE_BITS)) || (addr >= (1 << ADDR_BITS))) {
		// throw new
		// IllegalArgumentException("Code (4 bits) or Address (28 bits) out of range!");
		// }

		// address = ((code << CODE_SHIFT) & CODE_MASK) | ((addr << ADDR_SHIFT)
		// & ADDR_MASK);
	}

	@Override
	public void reconstructRawEventPacket(final EventPacketContainer eventPacketContainer,
		final RawEventPacket rawEventPacket) {
		// TODO Auto-generated method stub
	}
}
