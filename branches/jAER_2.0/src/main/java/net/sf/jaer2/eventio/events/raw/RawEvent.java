package net.sf.jaer2.eventio.events.raw;

import java.io.Serializable;

/**
 * A read-only raw event, having an int (32 bit) address and int (32 bit)
 * time-stamp, with custom encodings of various data types.
 * The first 4 bits of the address are reserved for encoding the type of
 * event, so as to be able to reliably distinguish between them and
 * reconstruct/interpret envents as needed.
 *
 * @author llongi
 */
public final class RawEvent implements Serializable {
	private static final long serialVersionUID = 808179108331580491L;

	private static final int CODE_MASK = 0xF0000000;
	private static final int CODE_BITS = Integer.bitCount(CODE_MASK);
	private static final int CODE_SHIFT = Integer.numberOfTrailingZeros(CODE_MASK);

	private static final int ADDR_MASK = 0x0FFFFFFF;
	private static final int ADDR_BITS = Integer.bitCount(ADDR_MASK);
	private static final int ADDR_SHIFT = Integer.numberOfTrailingZeros(ADDR_MASK);

	// 32 bit address and time-stamp
	private final int address;
	private final int timestamp;

	/**
	 * Creates a new instance of RawEvent, initialized with the given values.
	 *
	 * @param code
	 *            the event code.
	 * @param addr
	 *            the address.
	 * @param ts
	 *            the time-stamp.
	 */
	public RawEvent(final int code, final int addr, final int ts) {
		if ((code >= (1 << CODE_BITS)) || (addr >= (1 << ADDR_BITS))) {
			throw new IllegalArgumentException("Code (4 bits) or Address (28 bits) out of range!");
		}

		address = ((code << CODE_SHIFT) & CODE_MASK) | ((addr << ADDR_SHIFT) & ADDR_MASK);
		timestamp = ts;
	}

	public int getCode() {
		return ((address & CODE_MASK) >>> CODE_SHIFT);
	}

	public int getAddress() {
		return ((address & ADDR_MASK) >>> ADDR_SHIFT);
	}

	public int getTimestamp() {
		return timestamp;
	}

	@Override
	public String toString() {
		return String.format("RawEvent with code %d, address %d and time-stamp %d", getCode(), getAddress(),
			getTimestamp());
	}
}
