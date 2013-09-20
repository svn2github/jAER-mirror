package net.sf.jaer2.devices.config.pots;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.EnumSet;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.geometry.Pos;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableBooleanProperty;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;
import net.sf.jaer2.util.serializable.SerializableObjectProperty;

public class AddressedIPotCoarseFine extends AddressedIPot {
	private static final long serialVersionUID = -8998488876441985890L;

	/** The nominal (designed for) external resistor on the master bias */
	public static final float RX = 100e3f;

	/**
	 * The nominal ratio of coarse current between each coarse bias step change.
	 */
	public static final float RATIO_COARSE_CURRENT_STEP = 8f;

	/**
	 * Estimation of the master bias with 100kOhm external resistor (designed
	 * value); 389nA
	 */
	private final double fixMasterBias = 0.000000389;

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
	protected final SerializableObjectProperty<CurrentLevel> currentLevel = new SerializableObjectProperty<>();

	/**
	 * If enabled=true the bias operates normally, if enabled=false,
	 * then the bias is disabled by being weakly tied to the appropriate rail
	 * (depending on bias sex, N or P).
	 */
	protected final SerializableBooleanProperty biasEnabled = new SerializableBooleanProperty();

	/**
	 * Bit mask for flag bias enabled (normal operation) or disabled (tied
	 * weakly to rail)
	 */
	protected static final int enabledMask = 0b0001;

	/** Bit mask for flag for bias sex (N or P) */
	protected static final int sexMask = 0b0010;

	/** Bit mask for flag for bias type (normal or cascode) */
	protected static final int typeMask = 0b0100;

	/** Bit mask for flag low current mode enabled */
	protected static final int lowCurrentModeMask = 0b1000;

	/** Bit mask for fine bias current value bits */
	protected static final int bitFineMask = 0x0FF0; // 8 bits

	/** Bit mask for coarse bias current value bits */
	protected static final int bitCoarseMask = 0x7000; // 3 bits

	/** Number of bits used for fine bias value */
	protected static final int numFineBits = Integer.bitCount(AddressedIPotCoarseFine.bitFineMask);

	/** Number of bits used for coarse bias value */
	protected static final int numCoarseBits = Integer.bitCount(AddressedIPotCoarseFine.bitCoarseMask);

	/** Max fine bias bit value */
	protected static final int maxFineBitValue = (1 << AddressedIPotCoarseFine.numFineBits) - 1;

	/** Max bias bit value */
	protected static final int maxCoarseBitValue = (1 << AddressedIPotCoarseFine.numCoarseBits) - 1;

	/**
	 * the current fine value of the ipot in bits loaded into the shift register
	 */
	protected final SerializableIntegerProperty fineBitValue = new SerializableIntegerProperty();

	/**
	 * the current coarse value of the ipot in bits loaded into the shift
	 * register
	 */
	protected final SerializableIntegerProperty coarseBitValue = new SerializableIntegerProperty();

	public AddressedIPotCoarseFine(final String name, final String description, final Type type, final Sex sex) {
		this(name, description, type, sex, AddressedIPotCoarseFine.maxCoarseBitValue / 2,
			AddressedIPotCoarseFine.maxFineBitValue, CurrentLevel.Normal, true);
	}

	public AddressedIPotCoarseFine(final String name, final String description, final Type type, final Sex sex,
		final int defaultCoarseValue, final int defaultFineValue, final CurrentLevel currLevel,
		final boolean biasEnabled) {
		super(name, description, type, sex, 0);

		setNumBits(AddressedIPotCoarseFine.numFineBits + AddressedIPotCoarseFine.numCoarseBits);

		setBitValueUpdateListeners();

		setCoarseBitValue(defaultCoarseValue);
		setFineBitValue(defaultFineValue);

		// Developer check: the calculation should always be correct.
		assert getBitValue() == ((defaultCoarseValue << AddressedIPotCoarseFine.numFineBits) + defaultFineValue);

		setCurrentLevel(currLevel);
		setBiasEnabled(biasEnabled);
	}

	private void readObject(final ObjectInputStream in) throws IOException, ClassNotFoundException {
		in.defaultReadObject();

		setBitValueUpdateListeners();
	}

	private void setBitValueUpdateListeners() {
		// Add listeners that mediate updates between the bitValue and its
		// coarse and fine parts automatically.
		coarseBitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((newVal.intValue() << AddressedIPotCoarseFine.numFineBits) + getFineBitValue());
			}
		});

		fineBitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((getCoarseBitValue() << AddressedIPotCoarseFine.numFineBits) + newVal.intValue());
			}
		});

		bitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setCoarseBitValue(newVal.intValue() >>> AddressedIPotCoarseFine.numFineBits);
				setFineBitValue(newVal.intValue() & AddressedIPotCoarseFine.maxFineBitValue);
			}
		});
	}

	public int getFineBitValue() {
		return fineBitValue.property().get();
	}

	/**
	 * Set the buffer bias bit value
	 *
	 * @param bufferBitValue
	 *            the value which has maxBuffeBitValue as maximum and specifies
	 *            fraction of master bias
	 */
	public void setFineBitValue(final int fine) {
		fineBitValue.property().set(AddressedIPotCoarseFine.clipFine(fine));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	protected static int clipFine(final int in) {
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
		return coarseBitValue.property().get();
	}

	/**
	 * Set the course bias bit value. Note that because of an initial design
	 * error, the value of coarse current *decreases* as the bit value
	 * increases.
	 * The current is nominally the master current for a bit value of 2.
	 *
	 * @param bufferBitValue
	 *            the value which has maxBuffeBitValue as maximum and specifies
	 *            fraction of master bias
	 */
	public void setCoarseBitValue(final int coarse) {
		coarseBitValue.property().set(AddressedIPotCoarseFine.clipCoarse(coarse));
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param o
	 *            candidate new value.
	 * @return allowed value.
	 */
	protected static int clipCoarse(final int in) {
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

	public boolean isBiasEnabled() {
		return biasEnabled.property().get();
	}

	public void setBiasEnabled(final boolean biasEnabled) {
		this.biasEnabled.property().set(biasEnabled);
	}

	public CurrentLevel getCurrentLevel() {
		return currentLevel.property().get();
	}

	public void setCurrentLevel(final CurrentLevel currentLevel) {
		this.currentLevel.property().set(currentLevel);
	}

	public boolean isLowCurrentModeEnabled() {
		return getCurrentLevel() == CurrentLevel.Low;
	}

	/**
	 * Sets the enum currentLevel according to the flag lowCurrentModeEnabled.
	 *
	 * @param lowCurrentModeEnabled
	 *            true to set CurrentMode.LowCurrent
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
		final double im = fixMasterBias; // TODO: implement real MasterBias.
		final float i = (float) (im * Math.pow(AddressedIPotCoarseFine.RATIO_COARSE_CURRENT_STEP,
			2 - getCoarseBitValue()));
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
		final double im = fixMasterBias; // TODO: implement real MasterBias.
		setCoarseBitValue(7 - (int) Math.round((Math.log(current / im) / Math.log(8)) + 5));
		return getCoarseCurrent();
	}

	/**
	 * Increments coarse current
	 *
	 * @return true if change was possible, false if coarse current is already
	 *         maximum value
	 */
	public boolean incrementCoarseCurrent() {
		if (getCoarseBitValue() == AddressedIPotCoarseFine.getMaxCoarseBitValue()) {
			return false;
		}

		setCoarseBitValue(getCoarseBitValue() - 1);
		return true;
	}

	/**
	 * Decrements coarse current
	 *
	 * @return true if change was possible, false if coarse current is already
	 *         minimum value
	 */
	public boolean decrementCoarseCurrent() {
		if (getCoarseBitValue() == AddressedIPotCoarseFine.getMinCoarseBitValue()) {
			return false;
		}

		setCoarseBitValue(getCoarseBitValue() + 1);
		return true;
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
	protected int computeBinaryRepresentation() {
		int ret = 0;

		if (isBiasEnabled()) {
			ret |= AddressedIPotCoarseFine.enabledMask;
		}
		if (getType() == Pot.Type.NORMAL) {
			ret |= AddressedIPotCoarseFine.typeMask;
		}
		if (getSex() == Pot.Sex.N) {
			ret |= AddressedIPotCoarseFine.sexMask;
		}
		if (!isLowCurrentModeEnabled()) {
			ret |= AddressedIPotCoarseFine.lowCurrentModeMask;
		}

		ret |= getFineBitValue() << Integer.numberOfTrailingZeros(AddressedIPotCoarseFine.bitFineMask);

		// The coarse bits are reversed (this was a mistake) so we need to
		// mirror them here before we send them.
		final int coarseBitValueReversed = AddressedIPotCoarseFine.computeBinaryInverse(getCoarseBitValue(),
			AddressedIPotCoarseFine.numCoarseBits);
		ret |= coarseBitValueReversed << Integer.numberOfTrailingZeros(AddressedIPotCoarseFine.bitCoarseMask);

		return ret;
	}

	/**
	 * The coarse bits are reversed (this was a mistake) so we need to mirror
	 * them here before we sent them.
	 *
	 * @param value
	 *            the bits in
	 * @param lenth
	 *            the number of bits
	 * @return the bits mirrored
	 */
	private static int computeBinaryInverse(final int value, final int length) {
		return Integer.reverse(value) >>> (32 - length);
	}

	@Override
	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, name, description, null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);

		final CheckBox enableBox = GUISupport.addCheckBox(rootConfigLayout, "Enabled", isBiasEnabled());
		enableBox.selectedProperty().bindBidirectional(biasEnabled.property());

		final ComboBox<CurrentLevel> currentBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(CurrentLevel.class), getCurrentLevel().ordinal());
		currentBox.valueProperty().bindBidirectional(currentLevel.property());

		final ComboBox<Type> typeBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Type.class), getType()
			.ordinal());
		typeBox.valueProperty().bindBidirectional(type.property());

		final ComboBox<Sex> sexBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Sex.class), getSex()
			.ordinal());
		sexBox.valueProperty().bindBidirectional(sex.property());

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, bitValue.property(),
			Pot.getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(bitValue.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.BINARY, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(32 - getNumBits(), 32);
			}
		});

		final TextField valueInt = GUISupport.addTextNumberField(rootConfigLayout, bitValue.property(),
			Pot.getMinBitValue(), getMaxBitValue(), null);
		valueInt.setPrefColumnCount(10);

		valueInt.textProperty().bindBidirectional(bitValue.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final Slider coarseSlider = GUISupport.addSlider(rootConfigLayout,
			AddressedIPotCoarseFine.getMinCoarseBitValue(), AddressedIPotCoarseFine.getMaxCoarseBitValue(), 0, 10);

		coarseSlider.valueProperty().bindBidirectional(coarseBitValue.property());

		final Slider fineSlider = GUISupport.addSlider(rootConfigLayout, AddressedIPotCoarseFine.getMinFineBitValue(),
			AddressedIPotCoarseFine.getMaxFineBitValue(), 0, 10);
		HBox.setHgrow(fineSlider, Priority.ALWAYS);

		fineSlider.valueProperty().bindBidirectional(fineBitValue.property());
	}

	@Override
	public String toString() {
		return String.format("%s, Sex=%s, Type=%s, enabled=%d, lowCurrentMode=%d, coarseBitValue=%d, fineBitValue=%d",
			super.toString(), getSex(), getType(), isBiasEnabled(), isLowCurrentModeEnabled(), getCoarseBitValue(),
			getFineBitValue());
	}
}
