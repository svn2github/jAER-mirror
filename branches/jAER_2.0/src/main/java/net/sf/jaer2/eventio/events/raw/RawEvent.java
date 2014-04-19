package net.sf.jaer2.eventio.events.raw;


/**
 * A read-only raw event, having an int (32 bit) address and int (32 bit)
 * time-stamp, with custom encodings of various data types.
 *
 * @author llongi
 */
public final class RawEvent {
	// 32 bit address and time-stamp
	private final int address;
	private final int timestamp;

	/**
	 * Creates a new instance of RawEvent, initialized with the given values.
	 *
	 * @param addr
	 *            the address.
	 * @param ts
	 *            the time-stamp.
	 */
	public RawEvent(final int addr, final int ts) {
		address = addr;
		timestamp = ts;
	}

	public int getAddress() {
		return address;
	}

	public int getTimestamp() {
		return timestamp;
	}

	@Override
	public String toString() {
		return String.format("RawEvent with address %d and time-stamp %d", getAddress(), getTimestamp());
	}
}
