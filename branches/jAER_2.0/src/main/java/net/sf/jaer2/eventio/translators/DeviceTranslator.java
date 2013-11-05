package net.sf.jaer2.eventio.translators;

import java.nio.ByteBuffer;

import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacket;
import net.sf.jaer2.eventio.events.Event;

import com.google.common.collect.ImmutableList;

public interface DeviceTranslator {
	public abstract ImmutableList<Class<? extends Event>> getEventTypes();

	public void extractRawEventPacket(final ByteBuffer buffer, final RawEventPacket rawEventPacket);
}
