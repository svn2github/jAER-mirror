package net.sf.jaer2.util.serializable;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;

public class SerializableObservableList<T> implements Serializable {
	private static final long serialVersionUID = -8004632931769510697L;

	private final List<T> collection;

	transient private ObservableList<T> observable;

	public SerializableObservableList() {
		collection = new ArrayList<>();
	}

	synchronized public ObservableList<T> list() {
		if (observable == null) {
			observable = FXCollections.observableList(collection);
		}

		return observable;
	}
}
