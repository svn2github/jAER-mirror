package net.sf.jaer2.devices.config;

import java.io.Serializable;
import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class ConfigBase implements Serializable {
	private static final long serialVersionUID = -4814139458067416419L;

	public static interface Address {
		int address();

		@Override
		String toString();
	}

	/** Local logger for log messages. */
	protected static final Logger logger = LoggerFactory.getLogger(ConfigBase.class);

	private final String name;
	private final String description;

	/**
	 * The number of bits of resolution for this setting. This number is used to
	 * compute the limits of the value (min and max) and also for computing the
	 * number of bits or bytes to send to a device.
	 */
	private final int numBits;

	transient protected LongBinding changeBinding;

	transient protected HBox rootConfigLayout;

	public ConfigBase(final String name, final String description, final int numBits) {
		this.name = name;
		this.description = description;
		this.numBits = numBits;
	}

	public final String getName() {
		return name;
	}

	public final String getDescription() {
		return description;
	}

	/**
	 * Return an additional address, where this setting needs to be sent to.
	 * This throws an UnsupportedOperationException by default, and is only
	 * implemented for certain setting types, where it makes sense for them to
	 * have an address.
	 *
	 * @return setting address on device.
	 */
	@SuppressWarnings("static-method")
	public int getAddress() {
		throw new UnsupportedOperationException("Addressed mode not supported.");
	}

	public final int getNumBits() {
		return numBits;
	}

	public final int getNumBytes() {
		return (getNumBits() / Byte.SIZE) + (((getNumBits() % Byte.SIZE) == 0) ? (0) : (1));
	}

	/**
	 * Return the maximum value representing all stages of current splitter
	 * enabled.
	 */
	public long getMaxBitValue() {
		return ((1L << (getNumBits())) - 1);
	}

	/** Return the minimum value, no current: zero. */
	@SuppressWarnings("static-method")
	public long getMinBitValue() {
		return 0;
	}

	synchronized public final LongBinding getChangeBinding() {
		if (changeBinding == null) {
			buildChangeBinding();
		}

		return changeBinding;
	}

	protected abstract void buildChangeBinding();

	protected abstract long computeBinaryRepresentation();

	/**
	 * Computes and returns a new array of bytes representing the bias to be
	 * sent over the hardware interface to the device.
	 *
	 * @return array of bytes to be sent, by convention values are ordered in
	 *         big-endian format so that byte 0 is the most significant byte and
	 *         is sent first to the hardware.
	 */
	public byte[] getBinaryRepresentation() {
		final byte[] bytes = new byte[getNumBytes()];

		// Get the binary representation (can be up to 64 bits).
		// Mask off whatever's not in the lowest getNumBits() bits, to make sure
		// we only get the values we're interested in. This also guarantees
		// left-padding with zeros with no additional work needed.
		final long safetyMask = 0xFFFFFFFFFFFFFFFFL >>> (Long.SIZE - getNumBits());
		final long val = computeBinaryRepresentation() & safetyMask;

		int k = 0;
		for (int i = bytes.length - 1; i >= 0; i--) {
			bytes[k++] = (byte) (0xFF & (val >>> (i * Byte.SIZE)));
		}

		return bytes;
	}

	public final String getBinaryRepresentationAsString() {
		final byte[] binRep = getBinaryRepresentation();

		final StringBuilder s = new StringBuilder(binRep.length * Byte.SIZE);

		for (final byte element : binRep) {
			s.append(Numbers.integerToString((int) element, NumberFormat.BINARY,
				EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING)).substring(
				Integer.SIZE - Byte.SIZE, Integer.SIZE));
		}

		return s.toString();
	}

	synchronized public final Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new HBox(10);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, getName(), getDescription(), null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);
	}

	@Override
	public String toString() {
		return String.format("%s [type=%s,len=%d]", getName(), getClass().getSimpleName(), getNumBits());
	}
}
