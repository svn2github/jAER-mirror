package net.sf.jaer2.devices.config.pots;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.BooleanProperty;
import javafx.beans.property.IntegerProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
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
import net.sf.jaer2.util.serializable.SerializableBooleanProperty;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;
import net.sf.jaer2.util.serializable.SerializableObjectProperty;

public class AddressedIPotCoarseFine extends AddressedIPot {
	private static final long serialVersionUID = -8998488876441985890L;

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
	private final SerializableObjectProperty<CurrentLevel> currentLevel = new SerializableObjectProperty<>();

	/**
	 * If enabled=true the bias operates normally, if enabled=false,
	 * then the bias is disabled by being weakly tied to the appropriate rail
	 * (depending on bias sex, N or P).
	 */
	private final SerializableBooleanProperty biasEnabled = new SerializableBooleanProperty();

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
	private final SerializableIntegerProperty fineBitValue = new SerializableIntegerProperty();

	/**
	 * the current coarse value of the ipot in bits loaded into the shift
	 * register
	 */
	private final SerializableIntegerProperty coarseBitValue = new SerializableIntegerProperty();

	public AddressedIPotCoarseFine(final String name, final String description, final int address,
		final Masterbias masterbias, final Type type, final Sex sex) {
		this(name, description, address, masterbias, type, sex, AddressedIPotCoarseFine.maxCoarseBitValue / 2,
			AddressedIPotCoarseFine.maxFineBitValue, CurrentLevel.Normal, true);
	}

	public AddressedIPotCoarseFine(final String name, final String description, final int address,
		final Masterbias masterbias, final Type type, final Sex sex, final int defaultCoarseValue,
		final int defaultFineValue, final CurrentLevel currLevel, final boolean biasEnabled) {
		super(name, description, address, masterbias, type, sex, 0, AddressedIPotCoarseFine.numCoarseBits
			+ AddressedIPotCoarseFine.numFineBits + 4);
		// Add four bits for: currentLevel, type, sex and biasEnabled.

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
		getCoarseBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((newVal.intValue() << AddressedIPotCoarseFine.numFineBits) + getFineBitValue());
			}
		});

		getFineBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((getCoarseBitValue() << AddressedIPotCoarseFine.numFineBits) + newVal.intValue());
			}
		});

		getBitValueProperty().addListener(new ChangeListener<Number>() {
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

	public IntegerProperty getFineBitValueProperty() {
		return fineBitValue.property();
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

	public IntegerProperty getCoarseBitValueProperty() {
		return coarseBitValue.property();
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param o
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
		return biasEnabled.property().get();
	}

	public void setBiasEnabled(final boolean biasEnabled) {
		this.biasEnabled.property().set(biasEnabled);
	}

	public BooleanProperty getBiasEnabledProperty() {
		return biasEnabled.property();
	}

	public CurrentLevel getCurrentLevel() {
		return currentLevel.property().get();
	}

	public void setCurrentLevel(final CurrentLevel currentLevel) {
		this.currentLevel.property().set(currentLevel);
	}

	public ObjectProperty<CurrentLevel> getCurrentLevelProperty() {
		return currentLevel.property();
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
		// TODO: implement real MasterBias.
		final double im = AddressedIPotCoarseFine.fixMasterBias;
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
		// TODO: implement real MasterBias.
		final double im = AddressedIPotCoarseFine.fixMasterBias;
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

	@Override
	protected void buildChangeBinding() {
		changeBinding = new LongBinding() {
			{
				super.bind(getCoarseBitValueProperty(), getFineBitValueProperty(), getTypeProperty(), getSexProperty(),
					getBiasEnabledProperty(), getCurrentLevelProperty());
			}

			@Override
			protected long computeValue() {
				return System.currentTimeMillis();
			}
		};
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
		return Integer.reverse(value) >>> (Integer.SIZE - length);
	}

	@Override
	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, getName(), getDescription(), null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);

		final CheckBox enableBox = GUISupport.addCheckBox(rootConfigLayout, "Enabled", isBiasEnabled());
		enableBox.selectedProperty().bindBidirectional(getBiasEnabledProperty());

		final ComboBox<CurrentLevel> currentBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(CurrentLevel.class), getCurrentLevel().ordinal());
		currentBox.valueProperty().bindBidirectional(getCurrentLevelProperty());

		final ComboBox<Type> typeBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Type.class), getType()
			.ordinal());
		typeBox.valueProperty().bindBidirectional(getTypeProperty());

		final ComboBox<Sex> sexBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Sex.class), getSex()
			.ordinal());
		sexBox.valueProperty().bindBidirectional(getSexProperty());

		GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(), 10, (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(), getBitValueBits(),
			(int) getMinBitValue(), (int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);

		final Slider coarseSlider = GUISupport.addSlider(rootConfigLayout,
			AddressedIPotCoarseFine.getMinCoarseBitValue(), AddressedIPotCoarseFine.getMaxCoarseBitValue(), 0, 10);

		coarseSlider.valueProperty().bindBidirectional(getCoarseBitValueProperty());

		final Slider fineSlider = GUISupport.addSlider(rootConfigLayout, AddressedIPotCoarseFine.getMinFineBitValue(),
			AddressedIPotCoarseFine.getMaxFineBitValue(), 0, 10);
		HBox.setHgrow(fineSlider, Priority.ALWAYS);

		fineSlider.valueProperty().bindBidirectional(getFineBitValueProperty());

		final Label binaryRep = GUISupport.addLabel(rootConfigLayout, getBinaryRepresentationAsString(),
			"Binary data to be sent to the device.", null, null);

		getChangeBinding().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				binaryRep.setText(getBinaryRepresentationAsString());
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, enabled=%b, lowCurrentMode=%b, coarseBitValue=%d, fineBitValue=%d", super.toString(),
			isBiasEnabled(), isLowCurrentModeEnabled(), getCoarseBitValue(), getFineBitValue());
	}
}
