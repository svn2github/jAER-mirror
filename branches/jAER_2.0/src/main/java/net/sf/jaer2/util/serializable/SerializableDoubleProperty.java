package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.DoubleProperty;
import javafx.beans.property.SimpleDoubleProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableDoubleProperty implements Serializable {
	private static final long serialVersionUID = -5026267446590694525L;

	private double variable;

	transient private DoubleProperty observable;

	public SerializableDoubleProperty() {
		variable = 0.0d;
	}

	public SerializableDoubleProperty(final double initial) {
		variable = initial;
	}

	synchronized public DoubleProperty property() {
		if (observable == null) {
			observable = new SimpleDoubleProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<Number>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends Number> val, final Number oldVal,
					final Number newVal) {
					variable = newVal.doubleValue();
				}
			});
		}

		return observable;
	}
}
