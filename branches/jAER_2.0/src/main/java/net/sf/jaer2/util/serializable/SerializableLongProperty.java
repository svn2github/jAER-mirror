package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.LongProperty;
import javafx.beans.property.SimpleLongProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableLongProperty implements Serializable {
	private static final long serialVersionUID = 5755816141792146214L;

	private long variable;

	transient private LongProperty observable;

	public SerializableLongProperty() {
		variable = 0;
	}

	public SerializableLongProperty(final long initial) {
		variable = initial;
	}

	synchronized public LongProperty property() {
		if (observable == null) {
			observable = new SimpleLongProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<Number>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends Number> val, final Number oldVal,
					final Number newVal) {
					variable = newVal.longValue();
				}
			});
		}

		return observable;
	}
}
