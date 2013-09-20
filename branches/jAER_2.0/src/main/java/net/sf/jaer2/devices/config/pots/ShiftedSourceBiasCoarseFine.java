package net.sf.jaer2.devices.config.pots;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.util.EnumSet;

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

		public int bits() {
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

		public int bits() {
			return bits << Integer.numberOfTrailingZeros(VoltageLevel.mask);
		}
	}

	protected final SerializableObjectProperty<OperatingMode> operatingMode = new SerializableObjectProperty<>();

	protected final SerializableObjectProperty<VoltageLevel> voltageLevel = new SerializableObjectProperty<>();

	protected static final int refBiasMask = 0x03F0; // 6 bits for level of
														// shifted source
	/** Bit mask for buffer bias bits */
	protected static final int regBiasMask = 0xFC00; // 6 bits for bias current
														// for shifted source
														// buffer amplifier
	/** Number of bits used for bias value */
	protected static final int numRefBiasBits = Integer.bitCount(ShiftedSourceBiasCoarseFine.refBiasMask);

	/**
	 * The number of bits specifying buffer bias current as fraction of master
	 * bias current
	 */
	protected static final int numRegBiasBits = Integer.bitCount(ShiftedSourceBiasCoarseFine.regBiasMask);

	/** Max bias bit value */
	protected static final int maxRefBitValue = (1 << ShiftedSourceBiasCoarseFine.numRefBiasBits) - 1;

	/** Maximum buffer bias value (all bits on) */
	protected static final int maxRegBitValue = (1 << ShiftedSourceBiasCoarseFine.numRegBiasBits) - 1;

	/** The bit value of the buffer bias current */
	protected final SerializableIntegerProperty refBitValue = new SerializableIntegerProperty();

	/** The bit value of the buffer bias current */
	protected final SerializableIntegerProperty regBitValue = new SerializableIntegerProperty();

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final Type type, final Sex sex) {
		this(name, description, type, sex, ShiftedSourceBiasCoarseFine.maxRefBitValue,
			ShiftedSourceBiasCoarseFine.maxRegBitValue, OperatingMode.ShiftedSource, VoltageLevel.SplitGate);
	}

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final Type type, final Sex sex,
		final int defaultRefBitValue, final int defaultRegBitValue, final OperatingMode opMode,
		final VoltageLevel vLevel) {
		super(name, description, type, sex, 0);

		setNumBits(ShiftedSourceBiasCoarseFine.numRefBiasBits + ShiftedSourceBiasCoarseFine.numRegBiasBits);

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
		refBitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((getRegBitValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits) + newVal.intValue());
			}
		});

		regBitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((newVal.intValue() << ShiftedSourceBiasCoarseFine.numRefBiasBits) + getRefBitValue());
			}
		});

		bitValue.property().addListener(new ChangeListener<Number>() {
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

	public OperatingMode getOperatingMode() {
		return operatingMode.property().get();
	}

	public void setOperatingMode(final OperatingMode opMode) {
		operatingMode.property().set(opMode);
	}

	public VoltageLevel getVoltageLevel() {
		return voltageLevel.property().get();
	}

	public void setVoltageLevel(final VoltageLevel vLevel) {
		voltageLevel.property().set(vLevel);
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
	protected int computeBinaryRepresentation() {
		int ret = 0;

		ret |= getOperatingMode().bits();

		ret |= getVoltageLevel().bits();

		ret |= getRefBitValue() << Integer.numberOfTrailingZeros(ShiftedSourceBiasCoarseFine.refBiasMask);

		ret |= getRegBitValue() << Integer.numberOfTrailingZeros(ShiftedSourceBiasCoarseFine.regBiasMask);

		return ret;
	}

	/**
	 * Computes the actual bit pattern to be sent to chip based on configuration
	 * values
	 */
	@Override
	public byte[] getBinaryRepresentation() {
		final byte[] bytes = new byte[getNumBytes()];

		final int val = computeBinaryRepresentation();

		int k = 0;
		for (int i = bytes.length - 1; i >= 0; i--) {
			bytes[k++] = (byte) (0xFF & (val >>> (i * 8)));
		}

		return bytes;
	}

	@Override
	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		final Label l = GUISupport.addLabel(rootConfigLayout, name, description, null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);

		final ComboBox<OperatingMode> opModeBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(OperatingMode.class), getOperatingMode().ordinal());
		opModeBox.valueProperty().bindBidirectional(operatingMode.property());

		final ComboBox<VoltageLevel> vLevelBox = GUISupport.addComboBox(rootConfigLayout,
			EnumSet.allOf(VoltageLevel.class), getVoltageLevel().ordinal());
		vLevelBox.valueProperty().bindBidirectional(voltageLevel.property());

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

		final Slider refSlider = GUISupport
			.addSlider(rootConfigLayout, getMinRefBitValue(), getMaxRefBitValue(), 0, 10);

		refSlider.valueProperty().bindBidirectional(refBitValue.property());

		final Slider regSlider = GUISupport
			.addSlider(rootConfigLayout, getMinRegBitValue(), getMaxRegBitValue(), 0, 10);

		regSlider.valueProperty().bindBidirectional(regBitValue.property());
	}

	@Override
	public String toString() {
		return String.format("%s, Sex=%s, Type=%s, OperatingMode=%s, VoltageLevel=%s, refBitValue=%d, regBitValue=%d",
			super.toString(), getSex(), getType(), getOperatingMode(), getVoltageLevel(), getRefBitValue(),
			getRegBitValue());
	}
}
