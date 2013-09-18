package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableStringProperty implements Serializable {
	private static final long serialVersionUID = -91638838470708140L;

	private String variable;

	transient private StringProperty observable;

	public SerializableStringProperty() {
		variable = null;
	}

	public SerializableStringProperty(final String initial) {
		variable = initial;
	}

	synchronized public StringProperty property() {
		if (observable == null) {
			observable = new SimpleStringProperty();
			observable.set(variable);

			observable.addListener(new ChangeListener<String>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends String> val, final String oldVal,
					final String newVal) {
					variable = newVal;
				}
			});
		}

		return observable;
	}
}
