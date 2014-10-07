package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.geometry.Pos;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSNodeListener.NodeEvents;

public class ShiftedSourceBiasCoarseFine extends AddressedIPot {
	public static enum OperatingMode {
		ShiftedSource(0),
		HiZ(1),
		TiedToRail(2);

		private final int bits;
		public static final int mask = 0x0003;

		OperatingMode(final int b) {
			bits = b;
		}

		public final int bits() {
			return bits << Integer.numberOfTrailingZeros(OperatingMode.mask);
		}
	}

	public static enum VoltageLevel {
		SplitGate(0),
		SingleDiode(1),
		DoubleDiode(2);

		private final int bits;
		public static final int mask = 0x000C;

		VoltageLevel(final int b) {
			bits = b;
		}

		public final int bits() {
			return bits << Integer.numberOfTrailingZeros(VoltageLevel.mask);
		}
	}

	private final SSHSAttribute<OperatingMode> operatingMode;

	private final SSHSAttribute<VoltageLevel> voltageLevel;

	// 6 bits for level of shifted source
	/** Bit mask for bias bits */
	private static final int refBiasMask = 0x03F0;

	// 6 bits for bias current for shifted source buffer amplifier
	/** Bit mask for buffer bias bits */
	private static final int regBiasMask = 0xFC00;

	/** Number of bits used for bias value */
	private static final int numRefBiasBits = Integer.bitCount(ShiftedSourceBiasCoarseFine.refBiasMask);

	/**
	 * The number of bits specifying buffer bias current as fraction of master
	 * bias current
	 */
	private static final int numRegBiasBits = Integer.bitCount(ShiftedSourceBiasCoarseFine.regBiasMask);

	/** Max bias bit value */
	private static final int maxRefBitValue = (1 << ShiftedSourceBiasCoarseFine.numRefBiasBits) - 1;

	/** Maximum buffer bias value (all bits on) */
	private static final int maxRegBitValue = (1 << ShiftedSourceBiasCoarseFine.numRegBiasBits) - 1;

	/** The bit value of the buffer bias current */
	private final SSHSAttribute<Byte> refBitValue;

	/** The bit value of the buffer bias current */
	private final SSHSAttribute<Byte> regBitValue;

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final SSHSNode configNode,
		final int address, final Masterbias masterbias, final Type type, final Sex sex) {
		this(name, description, configNode, address, masterbias, type, sex, ShiftedSourceBiasCoarseFine.maxRefBitValue,
			ShiftedSourceBiasCoarseFine.maxRegBitValue, OperatingMode.ShiftedSource, VoltageLevel.SplitGate);
	}

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final SSHSNode configNode,
		final int address, final Masterbias masterbias, final Type type, final Sex sex, final int defaultRefBitValue,
		final int defaultRegBitValue, final OperatingMode opMode, final VoltageLevel vLevel) {
		super(name, description, configNode, address, masterbias, type, sex, 0,
			ShiftedSourceBiasCoarseFine.numRefBiasBits + ShiftedSourceBiasCoarseFine.numRegBiasBits + 4);
		// Add four bits for: operatingMode (2) and voltageLevel (2).

		refBitValue = this.configNode.getAttribute("refValue", Byte.class);
		setRefBitValue(defaultRefBitValue);

		regBitValue = this.configNode.getAttribute("regValue", Byte.class);
		setRegBitValue(defaultRegBitValue);

		setBitValueUpdateListeners();

		// Developer check: the calculation should always be correct.
		assert getBitValue() == ((defaultRegBitValue << ShiftedSourceBiasCoarseFine.numRefBiasBits) + defaultRefBitValue);

		operatingMode = this.configNode.getAttribute("operatingMode", OperatingMode.class);
		setOperatingMode(opMode);

		voltageLevel = this.configNode.getAttribute("voltageLevel", VoltageLevel.class);
		setVoltageLevel(vLevel);
	}

	private void setBitValueUpdateListeners() {
		// Add listeners that mediate updates between the bitValue and its
		// ref and reg parts automatically.
		refBitValue
			.addListener(
				(node, userData, event, oldValue, newValue) -> setBitValue((getRegBitValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits)
					+ newValue.intValue()), null);

		regBitValue
			.addListener(
				(node, userData, event, oldValue, newValue) -> setBitValue((newValue.intValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits)
					+ getRefBitValue()), null);

		bitValue.addListener((node, userData, event, oldValue, newValue) -> {
			setRefBitValue(newValue.intValue() & ShiftedSourceBiasCoarseFine.maxRefBitValue);
			setRegBitValue(newValue.intValue() >>> ShiftedSourceBiasCoarseFine.numRefBiasBits);
		}, null);

		// Set the bitValue once manually to ensure previous settings of the
		// ref/reg values are respected and propagated.
		setBitValue((getRegBitValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits) + getRefBitValue());
	}

	public int getRefBitValue() {
		return refBitValue.getValue() & 0xFF;
	}

	public void setRefBitValue(final int ref) {
		refBitValue.setValue((byte) ShiftedSourceBiasCoarseFine.clipRef(ref));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	private static int clipRef(final int in) {
		int out = in;

		if (in < 0) {
			out = 0;
		}
		if (in > ShiftedSourceBiasCoarseFine.maxRefBitValue) {
			out = ShiftedSourceBiasCoarseFine.maxRefBitValue;
		}

		return out;
	}

	public int getRegBitValue() {
		return regBitValue.getValue() & 0xFF;
	}

	public void setRegBitValue(final int reg) {
		regBitValue.setValue((byte) ShiftedSourceBiasCoarseFine.clipReg(reg));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	private static int clipReg(final int in) {
		int out = in;

		if (in < 0) {
			out = 0;
		}
		if (in > ShiftedSourceBiasCoarseFine.maxRegBitValue) {
			out = ShiftedSourceBiasCoarseFine.maxRegBitValue;
		}

		return out;
	}

	public static int getMaxRefBitValue() {
		return ShiftedSourceBiasCoarseFine.maxRefBitValue;
	}

	public static int getMinRefBitValue() {
		return 0;
	}

	public static int getMaxRegBitValue() {
		return ShiftedSourceBiasCoarseFine.maxRegBitValue;
	}

	public static int getMinRegBitValue() {
		return 0;
	}

	@Override
	public int getBitValueBits() {
		return ShiftedSourceBiasCoarseFine.numRefBiasBits + ShiftedSourceBiasCoarseFine.numRegBiasBits;
	}

	public OperatingMode getOperatingMode() {
		return operatingMode.getValue();
	}

	public void setOperatingMode(final OperatingMode opMode) {
		operatingMode.setValue(opMode);
	}

	public VoltageLevel getVoltageLevel() {
		return voltageLevel.getValue();
	}

	public void setVoltageLevel(final VoltageLevel vLevel) {
		voltageLevel.setValue(vLevel);
	}

	/**
	 * sets the bit value based on desired current and {@link #masterbias}
	 * current.
	 * Observers are notified if value changes.
	 *
	 * @param current
	 *            in amps
	 * @return actual float value of current after resolution clipping.
	 */
	public float setRegCurrent(final float current) {
		final float im = getMasterbias().getCurrent();
		final float r = current / im;
		setRegBitValue(Math.round(r * ShiftedSourceBiasCoarseFine.getMaxRegBitValue()));
		return getRegCurrent();
	}

	/**
	 * Computes the estimated current based on the bit value for the current
	 * splitter and the {@link #masterbias}
	 *
	 * @return current in amps
	 */
	public float getRegCurrent() {
		final float im = getMasterbias().getCurrent();
		final float i = (im * getRegBitValue()) / ShiftedSourceBiasCoarseFine.getMaxRegBitValue();
		return i;
	}

	/**
	 * sets the bit value based on desired current and {@link #masterbias}
	 * current.
	 * Observers are notified if value changes.
	 *
	 * @param current
	 *            in amps
	 * @return actual float value of current after resolution clipping.
	 */
	public float setRefCurrent(final float current) {
		final float im = getMasterbias().getCurrent();
		final float r = current / im;
		setRefBitValue(Math.round(r * ShiftedSourceBiasCoarseFine.getMaxRefBitValue()));
		return getRefCurrent();
	}

	/**
	 * Computes the estimated current based on the bit value for the current
	 * splitter and the {@link #masterbias}
	 *
	 * @return current in amps
	 */
	public float getRefCurrent() {
		final float im = getMasterbias().getCurrent();
		final float i = (im * getRefBitValue()) / ShiftedSourceBiasCoarseFine.getMaxRefBitValue();
		return i;
	}

	/**
	 * Computes the actual bit pattern to be sent to chip based on configuration
	 * values.
	 * The order of the bits from the input end of the shift register is
	 * operating mode config bits, buffer bias current code bits, voltage level
	 * config bits, voltage level code bits.
	 */
	@Override
	protected long computeBinaryRepresentation() {
		int ret = 0;

		ret |= getOperatingMode().bits();

		ret |= getVoltageLevel().bits();

		ret |= getRefBitValue() << Integer.numberOfTrailingZeros(ShiftedSourceBiasCoarseFine.refBiasMask);

		ret |= getRegBitValue() << Integer.numberOfTrailingZeros(ShiftedSourceBiasCoarseFine.regBiasMask);

		return ret;
	}

	@Override
	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, getName(), getDescription(), null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);

		final ComboBox<OperatingMode> opModeBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(OperatingMode.class), getOperatingMode().ordinal());

		opModeBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setOperatingMode(newValue));

		operatingMode.addListener(
			(node, userData, event, oldValue, newValue) -> opModeBox.valueProperty().setValue(newValue), null);

		final ComboBox<VoltageLevel> vLevelBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(VoltageLevel.class), getVoltageLevel().ordinal());

		vLevelBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setVoltageLevel(newValue));

		voltageLevel.addListener(
			(node, userData, event, oldValue, newValue) -> vLevelBox.valueProperty().setValue(newValue), null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, 10, (int) getMinBitValue(), (int) getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, getBitValueBits(), (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);

		final Slider refSlider = GUISupport.addSlider(rootConfigLayout,
			ShiftedSourceBiasCoarseFine.getMinRefBitValue(), ShiftedSourceBiasCoarseFine.getMaxRefBitValue(),
			getRefBitValue(), 10);

		refSlider.valueProperty().addListener((valueRef, oldValue, newValue) -> setRefBitValue(newValue.intValue()));

		refBitValue.addListener(
			(node, userData, event, oldValue, newValue) -> refSlider.setValue(newValue.doubleValue()), null);

		final Slider regSlider = GUISupport.addSlider(rootConfigLayout,
			ShiftedSourceBiasCoarseFine.getMinRegBitValue(), ShiftedSourceBiasCoarseFine.getMaxRegBitValue(),
			getRegBitValue(), 10);

		regSlider.valueProperty().addListener((valueRef, oldValue, newValue) -> setRegBitValue(newValue.intValue()));

		regBitValue.addListener(
			(node, userData, event, oldValue, newValue) -> regSlider.setValue(newValue.doubleValue()), null);

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
		return String.format("%s, OperatingMode=%s, VoltageLevel=%s, refBitValue=%d, regBitValue=%d", super.toString(),
			getOperatingMode().toString(), getVoltageLevel().toString(), getRefBitValue(), getRegBitValue());
	}
}
