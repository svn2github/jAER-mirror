package net.sf.jaer2.devices.config.pots;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.IntegerProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.geometry.Pos;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;
import net.sf.jaer2.util.serializable.SerializableObjectProperty;

public class ShiftedSourceBiasCoarseFine extends AddressedIPot {
	private static final long serialVersionUID = -4838678921924901764L;

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

	private final SerializableObjectProperty<OperatingMode> operatingMode = new SerializableObjectProperty<>();

	private final SerializableObjectProperty<VoltageLevel> voltageLevel = new SerializableObjectProperty<>();

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
	private final SerializableIntegerProperty refBitValue = new SerializableIntegerProperty();

	/** The bit value of the buffer bias current */
	private final SerializableIntegerProperty regBitValue = new SerializableIntegerProperty();

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final int address,
		final Masterbias masterbias, final Type type, final Sex sex) {
		this(name, description, address, masterbias, type, sex, ShiftedSourceBiasCoarseFine.maxRefBitValue,
			ShiftedSourceBiasCoarseFine.maxRegBitValue, OperatingMode.ShiftedSource, VoltageLevel.SplitGate);
	}

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final int address,
		final Masterbias masterbias, final Type type, final Sex sex, final int defaultRefBitValue,
		final int defaultRegBitValue, final OperatingMode opMode, final VoltageLevel vLevel) {
		super(name, description, address, masterbias, type, sex, 0, ShiftedSourceBiasCoarseFine.numRefBiasBits
			+ ShiftedSourceBiasCoarseFine.numRegBiasBits + 4);
		// Add four bits for: operatingMode (2) and voltageLevel (2).

		setBitValueUpdateListeners();

		setRefBitValue(defaultRefBitValue);
		setRegBitValue(defaultRegBitValue);

		// Developer check: the calculation should always be correct.
		assert getBitValue() == ((defaultRegBitValue << ShiftedSourceBiasCoarseFine.numRefBiasBits) + defaultRefBitValue);

		setOperatingMode(opMode);
		setVoltageLevel(vLevel);
	}

	private void readObject(final ObjectInputStream in) throws IOException, ClassNotFoundException {
		in.defaultReadObject();

		setBitValueUpdateListeners();
	}

	private void setBitValueUpdateListeners() {
		// Add listeners that mediate updates between the bitValue and its
		// ref and reg parts automatically.
		getRefBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((getRegBitValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits) + newVal.intValue());
			}
		});

		getRegBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((newVal.intValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits) + getRefBitValue());
			}
		});

		getBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setRefBitValue(newVal.intValue() & ShiftedSourceBiasCoarseFine.maxRefBitValue);
				setRegBitValue(newVal.intValue() >>> ShiftedSourceBiasCoarseFine.numRefBiasBits);
			}
		});
	}

	public int getRefBitValue() {
		return refBitValue.property().get();
	}

	public void setRefBitValue(final int ref) {
		refBitValue.property().set(ShiftedSourceBiasCoarseFine.clipRef(ref));
	}

	public IntegerProperty getRefBitValueProperty() {
		return refBitValue.property();
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	protected static int clipRef(final int in) {
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
		return regBitValue.property().get();
	}

	public void setRegBitValue(final int reg) {
		regBitValue.property().set(ShiftedSourceBiasCoarseFine.clipReg(reg));
	}

	public IntegerProperty getRegBitValueProperty() {
		return regBitValue.property();
	}

	/**
	 * returns clipped value of potential new value for buffer bit value,
	 * constrained by limits of hardware.
	 *
	 * @param in
	 *            candidate new value.
	 * @return allowed value.
	 */
	protected static int clipReg(final int in) {
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
		return operatingMode.property().get();
	}

	public void setOperatingMode(final OperatingMode opMode) {
		operatingMode.property().set(opMode);
	}

	public ObjectProperty<OperatingMode> getOperatingModeProperty() {
		return operatingMode.property();
	}

	public VoltageLevel getVoltageLevel() {
		return voltageLevel.property().get();
	}

	public void setVoltageLevel(final VoltageLevel vLevel) {
		voltageLevel.property().set(vLevel);
	}

	public ObjectProperty<VoltageLevel> getVoltageLevelProperty() {
		return voltageLevel.property();
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

	@Override
	protected void buildChangeBinding() {
		changeBinding = new LongBinding() {
			{
				super.bind(getBitValueProperty(), getTypeProperty(), getSexProperty(), getOperatingModeProperty(),
					getVoltageLevelProperty());
			}

			@Override
			protected long computeValue() {
				return System.currentTimeMillis();
			}
		};
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
		opModeBox.valueProperty().bindBidirectional(getOperatingModeProperty());

		final ComboBox<VoltageLevel> vLevelBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(VoltageLevel.class), getVoltageLevel().ordinal());
		vLevelBox.valueProperty().bindBidirectional(getVoltageLevelProperty());

		final TextField valueInt = GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueInt.setPrefColumnCount(10);

		valueInt.textProperty().bindBidirectional(getBitValueProperty().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getBitValueBits());

		valueBits.textProperty().bindBidirectional(getBitValueProperty().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.BINARY, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(Integer.SIZE - getBitValueBits(), Integer.SIZE);
			}
		});

		final Slider refSlider = GUISupport.addSlider(rootConfigLayout,
			ShiftedSourceBiasCoarseFine.getMinRefBitValue(), ShiftedSourceBiasCoarseFine.getMaxRefBitValue(), 0, 10);

		refSlider.valueProperty().bindBidirectional(getRefBitValueProperty());

		final Slider regSlider = GUISupport.addSlider(rootConfigLayout,
			ShiftedSourceBiasCoarseFine.getMinRegBitValue(), ShiftedSourceBiasCoarseFine.getMaxRegBitValue(), 0, 10);

		regSlider.valueProperty().bindBidirectional(getRegBitValueProperty());

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
		return String.format("%s, OperatingMode=%s, VoltageLevel=%s, refBitValue=%d, regBitValue=%d", super.toString(),
			getOperatingMode().toString(), getVoltageLevel().toString(), getRefBitValue(), getRegBitValue());
	}
}
