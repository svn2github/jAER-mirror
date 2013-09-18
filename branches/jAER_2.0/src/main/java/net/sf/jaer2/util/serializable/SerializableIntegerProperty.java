package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.IntegerProperty;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableIntegerProperty implements Serializable {
	private static final long serialVersionUID = -46097877165484177L;

	private int variable;

	transient private IntegerProperty observable;

	public SerializableIntegerProperty() {
		variable = 0;
	}

	public SerializableIntegerProperty(final int initial) {
		variable = initial;
	}

	synchronized public IntegerProperty property() {
		if (observable == null) {
			observable = new SimpleIntegerProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<Number>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends Number> val, final Number oldVal,
					final Number newVal) {
					variable = newVal.intValue();
				}
			});
		}

		return observable;
	}
}
