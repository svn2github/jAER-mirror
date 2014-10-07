package net.sf.jaer2.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

public final class TypedMap<K> {
	private final Map<PairRO<K, Class<?>>, Object> typedMap = new HashMap<>();

	public boolean isEmpty() {
		return typedMap.isEmpty();
	}

	public int size() {
		return typedMap.size();
	}

	public void clear() {
		typedMap.clear();
	}

	public boolean contains(final K key, final Class<?> valueType) {
		return typedMap.containsKey(PairRO.of(key, valueType));
	}

	public <V> V put(final K key, final Class<V> valueType, final V value) {
		return valueType.cast(typedMap.put(PairRO.of(key, valueType), valueType.cast(value)));
	}

	public <V> V putIfAbsent(final K key, final Class<V> valueType, final V value) {
		return valueType.cast(typedMap.putIfAbsent(PairRO.of(key, valueType), valueType.cast(value)));
	}

	public <V> V get(final K key, final Class<V> valueType) {
		return valueType.cast(typedMap.get(PairRO.of(key, valueType)));
	}

	public Set<Entry<PairRO<K, Class<?>>, Object>> entrySet() {
		return typedMap.entrySet();
	}

	public Set<PairRO<K, Class<?>>> keySet() {
		return typedMap.keySet();
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
				// Ignore this one, it's expected for the values that are not
				// the ones corresponding to valueType's type.
			}
		}

		return valueCollection;
	}
}
