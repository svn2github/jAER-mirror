package net.sf.jaer2.eventio.events;

import java.io.Serializable;

public abstract class Event implements Serializable, Comparable<Event> {
	private static final long serialVersionUID = 6776816266258337111L;

	transient private short sourceID = 0;
	private boolean valid = true;

	public final int timestamp;

	public Event(final int ts) {
		timestamp = ts;
	}

	public final Class<? extends Event> getEventType() {
		return getClass();
	}

	public final short getEventSource() {
		return sourceID;
	}

	public final void setEventSource(final short source) {
		sourceID = source;
	}

	public final boolean isValid() {
		return valid;
	}

	public final void setValid(final boolean validEvent) {
		valid = validEvent;
	}

	public final void invalidate() {
		valid = false;
	}

	protected final void deepCopyInternal(final Event evt) {
		evt.sourceID = sourceID;
		evt.valid = valid;
	}

	public abstract Event deepCopy();

	/**
	 * Note: this class has a natural ordering that is inconsistent with equals.
	 */
	@Override
	public int compareTo(final Event o) {
		// RawEvents and Events have a default total ordering dependent on
		// their time-stamps only, bigger is newer.
		if (timestamp < o.timestamp) {
			return -1;
		}

		if (timestamp > o.timestamp) {
			return 1;
		}

		return 0;
	}
}
