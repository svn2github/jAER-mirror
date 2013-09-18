package net.sf.jaer2.util.serializable;

import java.io.Serializable;

import javafx.beans.property.ObjectProperty;
import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;

public class SerializableObjectProperty<T> implements Serializable {
	private static final long serialVersionUID = -8996068654104249419L;

	private T variable;

	transient private ObjectProperty<T> observable;

	public SerializableObjectProperty() {
		variable = null;
	}

	public SerializableObjectProperty(final T initial) {
		variable = initial;
	}

	synchronized public ObjectProperty<T> property() {
		if (observable == null) {
			observable = new SimpleObjectProperty<>();
			observable.set(variable);

			observable.addListener(new ChangeListener<T>() {
				@SuppressWarnings("unused")
				@Override
				public void changed(final ObservableValue<? extends T> val, final T oldVal, final T newVal) {
					variable = newVal;
				}
			});
		}

		return observable;
	}
}
