package net.sf.jaer2.devices.config;

import java.io.Serializable;
import java.util.EnumSet;

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

	transient protected HBox rootConfigLayout;

	public ConfigBase(final String name, final String description, final int numBits) {
		this.name = name;
		this.description = description;
		this.numBits = numBits;
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}

	public int getNumBits() {
		return numBits;
	}

	public int getNumBytes() {
		return (getNumBits() / 8) + (((getNumBits() % 8) == 0) ? (0) : (1));
	}

	/**
	 * Return the maximum value representing all stages of current splitter
	 * enabled.
	 */
	public long getMaxBitValue() {
		return ((1L << (getNumBits())) - 1);
	}

	/** Return the minimum value, no current: zero. */
	public static long getMinBitValue() {
		return 0;
	}

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

		final long val = computeBinaryRepresentation();

		int k = 0;
		for (int i = bytes.length - 1; i >= 0; i--) {
			bytes[k++] = (byte) (0xFF & (val >>> (i * 8)));
		}

		return bytes;
	}

	public String getBinaryRepresentationAsString() {
		final byte[] binRep = getBinaryRepresentation();

		final StringBuilder s = new StringBuilder(binRep.length * 8);

		for (final byte element : binRep) {
			s.append(Numbers.integerToString((int) element, NumberFormat.BINARY,
				EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING)).substring(
				24, 32));
		}

		return s.toString();
	}

	synchronized public Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new HBox(10);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, name, description, null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);
	}

	@Override
	public String toString() {
		return String.format("%s - %s", name, description);
	}
}
