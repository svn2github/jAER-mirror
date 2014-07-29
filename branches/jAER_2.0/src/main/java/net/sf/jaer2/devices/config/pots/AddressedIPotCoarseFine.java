package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.geometry.Pos;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSNodeListener.NodeEvents;

public class AddressedIPotCoarseFine extends AddressedIPot {
	/**
	 * The nominal ratio of coarse current between each coarse bias step change.
	 */
	private static final float RATIO_COARSE_CURRENT_STEP = 8f;

	/**
	 * Estimation of the master bias with 100kOhm external resistor (designed
	 * value); 389nA
	 */
	private static final double fixMasterBias = 0.000000389;

	/**
	 * Operating current level, defines whether to use shifted-source current
	 * mirrors for small currents.
	 */
	public static enum CurrentLevel {
		Normal("Normal"),
		Low("Low");

		private final String str;

		private CurrentLevel(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	/**
	 * This enum determines whether low-current mode is enabled. In low-current
	 * mode, the bias uses
	 * shifted n or p source regulated voltages.
	 */
	private final SSHSAttribute<CurrentLevel> currentLevel;

	/**
	 * If enabled=true the bias operates normally, if enabled=false,
	 * then the bias is disabled by being weakly tied to the appropriate rail
	 * (depending on bias sex, N or P).
	 */
	private final SSHSAttribute<Boolean> biasEnabled;

	/**
	 * Bit mask for flag bias enabled (normal operation) or disabled (tied
	 * weakly to rail)
	 */
	private static final int enabledMask = 0b0001;

	/** Bit mask for flag for bias sex (N or P) */
	private static final int sexMask = 0b0010;

	/** Bit mask for flag for bias type (normal or cascode) */
	private static final int typeMask = 0b0100;

	/** Bit mask for flag low current mode enabled */
	private static final int lowCurrentModeMask = 0b1000;

	/** Bit mask for fine bias current value bits */
	private static final int bitFineMask = 0x0FF0; // 8 bits

	/** Bit mask for coarse bias current value bits */
	private static final int bitCoarseMask = 0x7000; // 3 bits

	/** Number of bits used for fine bias value */
	private static final int numFineBits = Integer.bitCount(AddressedIPotCoarseFine.bitFineMask);

	/** Number of bits used for coarse bias value */
	private static final int numCoarseBits = Integer.bitCount(AddressedIPotCoarseFine.bitCoarseMask);

	/** Max fine bias bit value */
	private static final int maxFineBitValue = (1 << AddressedIPotCoarseFine.numFineBits) - 1;

	/** Max bias bit value */
	private static final int maxCoarseBitValue = (1 << AddressedIPotCoarseFine.numCoarseBits) - 1;

	/**
	 * the current fine value of the ipot in bits loaded into the shift register
	 */
	private final SSHSAttribute<Short> fineBitValue;

	/**
	 * the current coarse value of the ipot in bits loaded into the shift
	 * register
	 */
	private final SSHSAttribute<Byte> coarseBitValue;

	public AddressedIPotCoarseFine(final String name, final String description, final SSHSNode configNode,
		final int address, final Masterbias masterbias, final Type type, final Sex sex) {
		this(name, description, configNode, address, masterbias, type, sex,
			AddressedIPotCoarseFine.maxCoarseBitValue / 2, AddressedIPotCoarseFine.maxFineBitValue,
			CurrentLevel.Normal, true);
	}

	public AddressedIPotCoarseFine(final String name, final String description, final SSHSNode configNode,
		final int address, final Masterbias masterbias, final Type type, final Sex sex, final int defaultCoarseValue,
		final int defaultFineValue, final CurrentLevel currLevel, final boolean biasEnabled) {
		super(name, description, configNode, address, masterbias, type, sex, 0, AddressedIPotCoarseFine.numCoarseBits
			+ AddressedIPotCoarseFine.numFineBits + 4);
		// Add four bits for: currentLevel, type, sex and biasEnabled.

		coarseBitValue = this.configNode.getAttribute("coarseValue", Byte.class);
		setCoarseBitValue(defaultCoarseValue);

		fineBitValue = this.configNode.getAttribute("fineValue", Short.class);
		setFineBitValue(defaultFineValue);

		setBitValueUpdateListeners();

		// Developer check: the calculation should always be correct.
		assert getBitValue() == ((defaultCoarseValue << AddressedIPotCoarseFine.numFineBits) + defaultFineValue);

		currentLevel = this.configNode.getAttribute("currentLevel", CurrentLevel.class);
		setCurrentLevel(currLevel);

		this.biasEnabled = this.configNode.getAttribute("enabled", Boolean.class);
		setBiasEnabled(biasEnabled);
	}

	private void setBitValueUpdateListeners() {
		// Add listeners that mediate updates between the bitValue and its
		// coarse and fine parts automatically.
		coarseBitValue
			.addListener(
				(node, userData, event, oldValue, newValue) -> setBitValue((newValue.intValue() << AddressedIPotCoarseFine.numFineBits)
					+ getFineBitValue()), null);

		fineBitValue
			.addListener(
				(node, userData, event, oldValue, newValue) -> setBitValue((getCoarseBitValue() << AddressedIPotCoarseFine.numFineBits)
					+ newValue.intValue()), null);

		bitValue.addListener((node, userData, event, oldValue, newValue) -> {
			setCoarseBitValue(newValue.intValue() >>> AddressedIPotCoarseFine.numFineBits);
			setFineBitValue(newValue.intValue() & AddressedIPotCoarseFine.maxFineBitValue);
		}, null);

		// Set the bitValue once manually to ensure previous settings of the
		// coarse/fine values are respected and propagated.
		setBitValue((getCoarseBitValue() << AddressedIPotCoarseFine.numFineBits) + getFineBitValue());
	}

	public int getFineBitValue() {
		return fineBitValue.getValue() & 0xFFFF;
	}

	/**
	 * Set the fine bias bit value.
	 */
	public void setFineBitValue(final int fine) {
		fineBitValue.setValue((short) AddressedIPotCoarseFine.clipFine(fine));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	private static int clipFine(final int in) {
		int out = in;

		if (in < 0) {
			out = 0;
		}
		if (in > AddressedIPotCoarseFine.maxFineBitValue) {
			out = AddressedIPotCoarseFine.maxFineBitValue;
		}

		return out;
	}

	public int getCoarseBitValue() {
		return coarseBitValue.getValue() & 0xFF;
	}

	/**
	 * Set the coarse bias bit value.
	 */
	public void setCoarseBitValue(final int coarse) {
		coarseBitValue.setValue((byte) AddressedIPotCoarseFine.clipCoarse(coarse));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	private static int clipCoarse(final int in) {
		int out = in;

		if (in < 0) {
			out = 0;
		}
		if (in > AddressedIPotCoarseFine.maxCoarseBitValue) {
			out = AddressedIPotCoarseFine.maxCoarseBitValue;
		}

		return out;
	}

	public static int getMaxCoarseBitValue() {
		return AddressedIPotCoarseFine.maxCoarseBitValue;
	}

	public static int getMinCoarseBitValue() {
		return 0;
	}

	public static int getMaxFineBitValue() {
		return AddressedIPotCoarseFine.maxFineBitValue;
	}

	public static int getMinFineBitValue() {
		return 0;
	}

	@Override
	public int getBitValueBits() {
		return AddressedIPotCoarseFine.numCoarseBits + AddressedIPotCoarseFine.numFineBits;
	}

	public boolean isBiasEnabled() {
		return biasEnabled.getValue();
	}

	public void setBiasEnabled(final boolean biasEnabled) {
		this.biasEnabled.setValue(biasEnabled);
	}

	public CurrentLevel getCurrentLevel() {
		return currentLevel.getValue();
	}

	public void setCurrentLevel(final CurrentLevel currentLevel) {
		this.currentLevel.setValue(currentLevel);
	}

	public boolean isLowCurrentModeEnabled() {
		return getCurrentLevel() == CurrentLevel.Low;
	}

	/**
	 * Sets the enum currentLevel according to the flag lowCurrentModeEnabled.
	 *
	 * @param lowCurrentModeEnabled
	 *            true to set CurrentLevel.Low
	 */
	public void setLowCurrentModeEnabled(final boolean lowCurrentModeEnabled) {
		setCurrentLevel(lowCurrentModeEnabled ? CurrentLevel.Low : CurrentLevel.Normal);
	}

	/**
	 * Returns estimated coarse current based on master bias current and coarse
	 * bit setting
	 *
	 * @return current in amperes
	 */
	public float getCoarseCurrent() {
		// TODO: implement real MasterBias.
		final double im = AddressedIPotCoarseFine.fixMasterBias;
		final float i = (float) (im * Math.pow(AddressedIPotCoarseFine.RATIO_COARSE_CURRENT_STEP, getCoarseBitValue()));
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
	public float setCoarseCurrent(final float current) {
		// TODO: implement real MasterBias.
		final double im = AddressedIPotCoarseFine.fixMasterBias;
		setCoarseBitValue((int) Math.round(Math.log(current / im)
			/ Math.log(AddressedIPotCoarseFine.RATIO_COARSE_CURRENT_STEP)));
		return getCoarseCurrent();
	}

	public float getFineCurrent() {
		final float im = getCoarseCurrent();
		final float i = (im * getFineBitValue()) / (AddressedIPotCoarseFine.getMaxFineBitValue() + 1);
		return i;
	}

	public float setFineCurrent(final float current) {
		final float im = getCoarseCurrent();
		final float r = current / im;
		setFineBitValue(Math.round(r * (AddressedIPotCoarseFine.getMaxFineBitValue() + 1)));
		return getFineCurrent();
	}

	/**
	 * Computes the actual bit pattern to be sent to chip based on configuration
	 * values
	 */
	@Override
	protected long computeBinaryRepresentation() {
		int ret = 0;

		if (isBiasEnabled()) {
			ret |= AddressedIPotCoarseFine.enabledMask;
		}
		if (getSex() == Pot.Sex.N) {
			ret |= AddressedIPotCoarseFine.sexMask;
		}
		if (getType() == Pot.Type.NORMAL) {
			ret |= AddressedIPotCoarseFine.typeMask;
		}
		if (!isLowCurrentModeEnabled()) {
			ret |= AddressedIPotCoarseFine.lowCurrentModeMask;
		}

		ret |= getFineBitValue() << Integer.numberOfTrailingZeros(AddressedIPotCoarseFine.bitFineMask);

		ret |= getCoarseBitValue() << Integer.numberOfTrailingZeros(AddressedIPotCoarseFine.bitCoarseMask);

		return ret;
	}

	@Override
	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, getName(), getDescription(), null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);

		final CheckBox enableBox = GUISupport.addCheckBox(rootConfigLayout, "Enabled", isBiasEnabled());

		enableBox.selectedProperty().addListener((valueRef, oldValue, newValue) -> setBiasEnabled(newValue));

		biasEnabled.addListener(
			(node, userData, event, oldValue, newValue) -> enableBox.selectedProperty().setValue(newValue), null);

		final ComboBox<CurrentLevel> currentBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(CurrentLevel.class), getCurrentLevel().ordinal());

		currentBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setCurrentLevel(newValue));

		currentLevel.addListener(
			(node, userData, event, oldValue, newValue) -> currentBox.valueProperty().setValue(newValue), null);

		final ComboBox<Type> typeBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Type.class), getType()
			.ordinal());

		typeBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setType(newValue));

		type.addListener((node, userData, event, oldValue, newValue) -> typeBox.valueProperty().setValue(newValue),
			null);

		final ComboBox<Sex> sexBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Sex.class), getSex()
			.ordinal());

		sexBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setSex(newValue));

		sex.addListener((node, userData, event, oldValue, newValue) -> sexBox.valueProperty().setValue(newValue), null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, 10, (int) getMinBitValue(), (int) getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, bitValue, getBitValueBits(), (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);

		final Slider coarseSlider = GUISupport.addSlider(rootConfigLayout,
			AddressedIPotCoarseFine.getMinCoarseBitValue(), AddressedIPotCoarseFine.getMaxCoarseBitValue(),
			getCoarseBitValue(), 10);

		coarseSlider.valueProperty().addListener(
			(valueRef, oldValue, newValue) -> setCoarseBitValue(newValue.intValue()));

		coarseBitValue.addListener(
			(node, userData, event, oldValue, newValue) -> coarseSlider.setValue(newValue.doubleValue()), null);

		final Slider fineSlider = GUISupport.addSlider(rootConfigLayout, AddressedIPotCoarseFine.getMinFineBitValue(),
			AddressedIPotCoarseFine.getMaxFineBitValue(), getFineBitValue(), 10);
		HBox.setHgrow(fineSlider, Priority.ALWAYS);

		fineSlider.valueProperty().addListener((valueRef, oldValue, newValue) -> setFineBitValue(newValue.intValue()));

		fineBitValue.addListener(
			(node, userData, event, oldValue, newValue) -> fineSlider.setValue(newValue.doubleValue()), null);

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
		return String.format("%s, enabled=%b, lowCurrentMode=%b, coarseBitValue=%d, fineBitValue=%d", super.toString(),
			isBiasEnabled(), isLowCurrentModeEnabled(), getCoarseBitValue(), getFineBitValue());
	}
}
