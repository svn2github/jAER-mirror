package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHS;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSNodeListener.NodeEvents;

public abstract class Pot extends ConfigBase {
	/** Type of bias, NORMAL, CASCODE or REFERENCE. */
	public static enum Type {
		NORMAL("Normal"),
		CASCODE("Cascode"),
		REFERENCE("Reference");

		private final String str;

		private Type(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	/** Transistor type for bias, N, P or not available (na). */
	public static enum Sex {
		N("N"),
		P("P"),
		na("N/A");

		private final String str;

		private Sex(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	protected final SSHSAttribute<Type> type;
	protected final SSHSAttribute<Sex> sex;

	/** The current value of the bias in bits. */
	protected final SSHSAttribute<Integer> bitValue;

	public Pot(final String name, final String description, final SSHSNode configNode, final Type type, final Sex sex) {
		this(name, description, configNode, type, sex, 0, 24);
	}

	public Pot(final String name, final String description, final SSHSNode configNode, final Type type, final Sex sex,
		final int defaultValue, final int numBits) {
		super(name, description, configNode, numBits);

		// Reset config node to be one level deeper that what is passed in, so
		// that each bias appears isolated inside their own node.
		this.configNode = SSHS.getRelativeNode(this.configNode, name + "/");

		this.type = this.configNode.getAttribute("type", Type.class);
		setType(type);

		this.sex = this.configNode.getAttribute("sex", Sex.class);
		setSex(sex);

		bitValue = this.configNode.getAttribute("bitValue", Integer.class);
		setBitValue(defaultValue);
	}

	public Type getType() {
		return type.getValue();
	}

	public void setType(final Type t) {
		type.setValue(t);
	}

	public Sex getSex() {
		return sex.getValue();
	}

	public void setSex(final Sex s) {
		sex.setValue(s);
	}

	public int getBitValue() {
		return bitValue.getValue();
	}

	public void setBitValue(final int bitVal) {
		bitValue.setValue(clip(bitVal));
	}

	private int clip(final int in) {
		int out = in;

		if (in < getMinBitValue()) {
			out = (int) getMinBitValue();
		}
		if (in > getMaxBitValue()) {
			out = (int) getMaxBitValue();
		}

		return out;
	}

	public int getBitValueBits() {
		return getNumBits();
	}

	@Override
	public long getMaxBitValue() {
		return ((1L << getBitValueBits()) - 1);
	}

	/** Increment bias value by one count. */
	public boolean incrementBitValue() {
		if (getBitValue() == getMaxBitValue()) {
			return false;
		}

		setBitValue(getBitValue() + 1);
		return true;
	}

	/** Decrement bias value by one count. */
	public boolean decrementBitValue() {
		if (getBitValue() == getMinBitValue()) {
			return false;
		}

		setBitValue(getBitValue() - 1);
		return true;
	}

	public String getBitValueAsString() {
		return Numbers.integerToString(getBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING)).substring(
			Integer.SIZE - getBitValueBits(), Integer.SIZE);
	}

	/**
	 * Returns the physical value of the bias, e.g. for current Amps or for
	 * voltage Volts.
	 *
	 * @return physical value.
	 */
	abstract public float getPhysicalValue();

	/**
	 * Sets the physical value of the bias.
	 *
	 * @param value
	 *            the physical value, e.g. in Amps or Volts.
	 */
	abstract public void setPhysicalValue(float value);

	/** Return the unit (e.g. A, mV) of the physical value for this bias. */
	abstract public String getPhysicalValueUnits();

	@Override
	protected long computeBinaryRepresentation() {
		return getBitValue();
	}

	protected Slider mainSlider;

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		GUISupport.addLabel(rootConfigLayout, getType().toString(), null, null, null);

		GUISupport.addLabel(rootConfigLayout, getSex().toString(), null, null, null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, 10, (int) getMinBitValue(), (int) getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, getBitValueBits(), (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);

		final long minBitValueSlider = getMinBitValue();
		final long maxBitValueSlider = (getMaxBitValue() < 4095) ? (getMaxBitValue()) : (4095);

		mainSlider = GUISupport.addSlider(rootConfigLayout, minBitValueSlider, maxBitValueSlider,
			Math.round(((double) getBitValue() / getMaxBitValue()) * maxBitValueSlider), 10);
		HBox.setHgrow(mainSlider, Priority.ALWAYS);

		final Label binaryRep = GUISupport.addLabel(rootConfigLayout, getBinaryRepresentationAsString(),
			"Binary data to be sent to the device.", null, null);

		// Add listener directly to the node, so that any change to a
		// subordinate setting results in the update of the shift register
		// display value.
		configNode.addNodeListener((node, userData, event, key) -> {
			if (event == NodeEvents.ATTRIBUTE_MODIFIED) {
				// On any subordinate attribute update, refresh the
				// displayed value.
			binaryRep.setText(getBinaryRepresentationAsString());
		}
	}, null);
	}

	@Override
	public String toString() {
		return String.format("%s, Type=%s, Sex=%s, bitValue=%d", super.toString(), getType().toString(), getSex()
			.toString(), getBitValue());
	}
}
