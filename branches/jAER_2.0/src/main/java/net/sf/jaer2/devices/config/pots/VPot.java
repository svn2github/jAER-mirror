package net.sf.jaer2.devices.config.pots;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import net.sf.jaer2.devices.components.misc.DAC;

public class VPot extends Pot {
	private static final long serialVersionUID = 5367992495461216L;

	/** the delta voltage to change by in increment and decrement methods */
	private static final float VOLTAGE_CHANGE_VALUE_VOLTS = 0.005f;

	private final DAC dac;

	public VPot(final String name, final String description, final DAC dac, final Type type, final Sex sex) {
		this(name, description, dac, type, sex, 0, 24);
	}

	public VPot(final String name, final String description, final DAC dac, final Type type, final Sex sex,
		final int defaultValue, final int numBits) {
		super(name, description, type, sex, defaultValue, numBits);

		this.dac = dac;
	}

	public DAC getDac() {
		return dac;
	}

	/**
	 * gets the voltage output by this VPot according the bit value times the
	 * difference between ref min and ref max, clipped
	 * to the DAC's vdd.
	 *
	 * @return voltage in volts.
	 */
	public float getVoltage() {
		final float vdd = getDac().getVdd();
		float v = getMinVoltage() + (getVoltageResolution() * getBitValue());
		if (v > vdd) {
			v = vdd;
		}

		return v;
	}

	/**
	 * sets the bit value based on desired voltage, clipped the DAC's vdd.
	 * Observers are notified if value changes.
	 *
	 * @param voltage
	 *            in volts
	 * @return actual float value of voltage after resolution rounding and vdd
	 *         clipping.
	 */
	public float setVoltage(final float voltage) {
		final float vdd = getDac().getVdd();
		final float v = (voltage > vdd) ? (vdd) : (voltage);

		setBitValue(Math.round(v * getMaxBitValue()));

		return getVoltage();
	}

	/** @return max possible voltage */
	public float getMaxVoltage() {
		return getDac().getRefMaxVolts();
	}

	/** @return min possible voltage. */
	public float getMinVoltage() {
		return getDac().getRefMinVolts();
	}

	/**
	 * return resolution of pot in voltage.
	 *
	 * @return smallest possible voltage change -- in principle.
	 */
	public float getVoltageResolution() {
		return (getDac().getRefMaxVolts() - getDac().getRefMinVolts()) / getMaxBitValue();
	}

	/** increment pot value */
	public boolean incrementVoltage() {
		if (getBitValue() == getMaxBitValue()) {
			return false;
		}

		setVoltage(getVoltage() + VPot.VOLTAGE_CHANGE_VALUE_VOLTS);
		return true;
	}

	/** decrement pot value */
	public boolean decrementVoltage() {
		if (getBitValue() == getMinBitValue()) {
			return false;
		}

		setVoltage(getVoltage() - VPot.VOLTAGE_CHANGE_VALUE_VOLTS);
		return true;
	}

	/**
	 * changes VPot value by a fraction of full scale, e.g. -0.05f for a -5%
	 * decrease of full-scale value
	 *
	 * @param fraction
	 *            of full scale value
	 */
	public void changeByFractionOfFullScale(final float fraction) {
		final int change = (int) (getMaxBitValue() * fraction);

		setBitValue(getBitValue() + change);
	}

	@Override
	public float getPhysicalValue() {
		return getVoltage();
	}

	@Override
	public String getPhysicalValueUnits() {
		return "V";
	}

	@Override
	public void setPhysicalValue(final float value) {
		setVoltage(value);
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		mainSlider.valueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				setBitValue((int) Math.round((newVal.doubleValue() / mainSlider.getMax()) * getMaxBitValue()));
			}
		});

		getBitValueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				mainSlider.setValue((int) Math.round((newVal.doubleValue() / getMaxBitValue()) * mainSlider.getMax()));
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, voltage=%f", super.toString(), getVoltage());
	}
}