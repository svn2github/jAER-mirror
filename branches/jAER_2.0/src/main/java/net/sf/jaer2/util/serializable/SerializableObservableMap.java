package net.sf.jaer2.util.serializable;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import javafx.collections.FXCollections;
import javafx.collections.ObservableMap;

public class SerializableObservableMap<K, V> implements Serializable {
	private static final long serialVersionUID = 3267876866451374384L;

	private final Map<K, V> collection;

	transient private ObservableMap<K, V> observable;

	public SerializableObservableMap() {
		collection = new HashMap<>();
	}

	synchronized public ObservableMap<K, V> map() {
		if (observable == null) {
			observable = FXCollections.observableMap(collection);
		}

		return observable;
	}
}
