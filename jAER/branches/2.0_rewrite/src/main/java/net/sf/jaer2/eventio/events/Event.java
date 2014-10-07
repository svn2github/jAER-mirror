package net.sf.jaer2.eventio.events;


public abstract class Event implements Comparable<Event> {
	private short sourceID = 0;
	private boolean valid = true;

	private final int timestamp;

	public Event(final int ts) {
		timestamp = ts;
	}

	public final Class<? extends Event> getEventType() {
		return getClass();
	}

	public final int getTimestamp() {
		return timestamp;
	}

	public final short getSourceID() {
		return sourceID;
	}

	public final void setSourceID(final short sourceID) {
		this.sourceID = sourceID;
	}

	public final boolean isValid() {
		return valid;
	}

	public final void setValid(final boolean valid) {
		this.valid = valid;
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
	public final int compareTo(final Event o) {
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
