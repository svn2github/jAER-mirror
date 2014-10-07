package net.sf.jaer2.eventio.translators;

import net.sf.jaer2.eventio.eventpackets.EventPacketContainer;
import net.sf.jaer2.eventio.eventpackets.raw.RawEventPacketContainer;
import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.raw.RawEvent;

import com.google.common.collect.ImmutableList;

public interface Translator {
	public ImmutableList<Class<? extends Event>> getRawEventToEventMappings();

	public void extractEventFromRawEvent(final RawEvent rawEventIn, final EventPacketContainer eventPacketContainerOut);

	public ImmutableList<Class<? extends Event>> getEventToRawEventMappings();

	public void extractRawEventFromEvent(final Event eventIn, final RawEventPacketContainer rawEventPacketContainerOut);
}
