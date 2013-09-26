package net.sf.jaer2.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

public final class TypedMap<K> {
	private final Map<PairRO<K, ?>, Object> typedMap = new HashMap<>();

	public <V> void put(final K key, final Class<V> valueType, final V value) {
		typedMap.put(PairRO.of(key, valueType), valueType.cast(value));
	}

	public <V> V get(final K key, final Class<V> valueType) {
		return valueType.cast(typedMap.get(PairRO.of(key, valueType)));
	}

	public Collection<Object> values() {
		return typedMap.values();
	}

	public <V> Collection<V> values(final Class<V> valueType) {
		final Collection<V> valueCollection = new ArrayList<>();

		for (final Object obj : values()) {
			try {
				final V value = valueType.cast(obj);
				valueCollection.add(value);
			}
			catch (final ClassCastException e) {
				// Ignore this one, it's expected.
			}
		}

		return valueCollection;
	}
}
