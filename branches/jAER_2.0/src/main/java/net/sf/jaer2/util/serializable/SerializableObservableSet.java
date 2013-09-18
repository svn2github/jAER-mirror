package net.sf.jaer2.util.serializable;

import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

import javafx.collections.FXCollections;
import javafx.collections.ObservableSet;

public class SerializableObservableSet<T> implements Serializable {
	private static final long serialVersionUID = 5629029645890230918L;

	private final Set<T> collection;

	transient private ObservableSet<T> observable;

	public SerializableObservableSet() {
		collection = new HashSet<>();
	}

	synchronized public ObservableSet<T> set() {
		if (observable == null) {
			observable = FXCollections.observableSet(collection);
		}

		return observable;
	}
}
