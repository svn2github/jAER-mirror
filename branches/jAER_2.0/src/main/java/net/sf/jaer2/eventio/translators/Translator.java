package net.sf.jaer2.eventio.translators;

import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.eventio.events.raw.RawEvent;

import com.google.common.collect.ImmutableList;

public interface Translator {
	public ImmutableList<Class<? extends Event>> getRawEventToEventMappings();

	public Event extractEventFromRawEvent(final RawEvent rawEvent);

	public ImmutableList<Class<? extends Event>> getEventToRawEventMappings();

	public RawEvent[] extractRawEventFromEvent(final Event event);
}
