package net.sf.jaer2.devices.config.pots;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.Slider;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import net.sf.jaer2.devices.components.misc.DAC;
import net.sf.jaer2.util.GUISupport;

public class VPot extends Pot {
	private static final long serialVersionUID = 5367992495461216L;

	/** the delta voltage to change by in increment and decrement methods */
	public static final float VOLTAGE_CHANGE_VALUE_VOLTS = 0.005f;

	private DAC dac;

	public VPot(final String name, final String description, final Type type, final Sex sex, final int defaultValue) {
		super(name, description, type, sex, defaultValue);
	}

	public DAC getDac() {
		return dac;
	}

	public void setDac(final DAC dac) {
		this.dac = dac;
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
		return (getDac().getRefMaxVolts() - getDac().getRefMinVolts()) / ((1 << getNumBits()) - 1);
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

		final Slider slider = GUISupport.addSlider(rootConfigLayout, 0, 4095, 0, 10);
		HBox.setHgrow(slider, Priority.ALWAYS);

		slider.valueProperty().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				bitValue.property().setValue(
					(int) Math.round((newVal.doubleValue() / slider.getMax()) * getMaxBitValue()));
			}
		});

		bitValue.property().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				slider.setValue((int) Math.round((newVal.doubleValue() / getMaxBitValue()) * slider.getMax()));
			}
		});
	}

	@Override
	public String toString() {
		return String.format("VPot %s with bitValue=%d, voltage=%f", getName(), getBitValue(), getVoltage());
	}
}
