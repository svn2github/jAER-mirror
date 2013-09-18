package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.BooleanProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableBooleanProperty implements Serializable {
	private static final long serialVersionUID = 2089896307012866067L;

	private boolean variable;

	transient private BooleanProperty observable;

	public SerializableBooleanProperty() {
		variable = false;
	}

	public SerializableBooleanProperty(final boolean initial) {
		variable = initial;
	}

	synchronized public BooleanProperty property() {
		if (observable == null) {
			observable = new SimpleBooleanProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<Boolean>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends Boolean> val, final Boolean oldVal,
					final Boolean newVal) {
					variable = newVal.booleanValue();
				}
			});
		}

		return observable;
	}
}
