package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.FloatProperty;
import javafx.beans.property.SimpleFloatProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableFloatProperty implements Serializable {
	private static final long serialVersionUID = -8421832701689179511L;

	private float variable;

	transient private FloatProperty observable;

	public SerializableFloatProperty() {
		variable = 0.0f;
	}

	public SerializableFloatProperty(final float initial) {
		variable = initial;
	}

	synchronized public FloatProperty property() {
		if (observable == null) {
			observable = new SimpleFloatProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<Number>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends Number> val, final Number oldVal,
					final Number newVal) {
					variable = newVal.floatValue();
				}
			});
		}

		return observable;
	}
}
