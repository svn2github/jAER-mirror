package net.sf.jaer2.eventio.events.raw;

import java.io.Serializable;

/**
 * A read-only raw AER event, having an int (32 bit) time-stamp and int (32 bit)
 * raw address.
 *
 * @author llongi
 */
public final class RawEvent implements Serializable, Comparable<RawEvent> {
	private static final long serialVersionUID = 808179108331580491L;

	// 32 bit time-stamp and address
	private final int timestamp;
	private final int address;

	/**
	 * Creates a new instance of RawEvent, initialized with the given values.
	 *
	 * @param ts
	 *            the time-stamp.
	 * @param addr
	 *            the address.
	 */
	public RawEvent(final int ts, final int addr) {
		timestamp = ts;
		address = addr;
	}

	public int getTimestamp() {
		return timestamp;
	}

	public int getAddress() {
		return address;
	}

	@Override
	public String toString() {
		return String.format("RawEvent with time-stamp %d and address %d", timestamp, address);
	}

	/**
	 * Note: this class has a natural ordering that is inconsistent with equals.
	 */
	@Override
	public int compareTo(final RawEvent o) {
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
