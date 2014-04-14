package net.sf.jaer2.util;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import net.sf.jaer2.util.SSHSAttribute.SSHSAttrListener.AttributeEvents;

public class SSHSAttribute<V> {
	public interface SSHSAttrListener<V> {
		public static enum AttributeEvents {
			ATTRIBUTE_MODIFIED;
		}

		public void attributeChanged(SSHSNode node, Object userData, AttributeEvents event, V oldValue, V newValue);
	}

	private final String key;
	private V value;

	private final SSHSNode parentNode;
	private final List<PairRO<SSHSAttrListener<V>, Object>> listeners;
	private final ReadWriteLock lock;

	SSHSAttribute(final String keyName, final SSHSNode parent) {
		key = keyName;
		value = null;

		parentNode = parent;
		listeners = new ArrayList<>();
		lock = new ReentrantReadWriteLock();
	}

	public String getKey() {
		return key;
	}

	public V getValue() {
		lock.readLock().lock();

		final V returnValue = value;

		lock.readLock().unlock();

		return returnValue;
	}

	public void setValue(final V val) {
		lock.writeLock().lock();

		// Update value and call listeners only if there really was a change.
		if (!value.equals(val)) {
			for (final PairRO<SSHSAttrListener<V>, Object> listener : listeners) {
				listener.getFirst().attributeChanged(parentNode, listener.getSecond(),
					AttributeEvents.ATTRIBUTE_MODIFIED, value, val);
			}

			value = val;
		}

		lock.writeLock().unlock();
	}

	public void addListener(final SSHSAttrListener<V> l, final Object userData) {
		lock.writeLock().lock();

		// Avoid duplicates by disallowing the addition of them.
		if (!listeners.contains(PairRO.of(l, userData))) {
			listeners.add(PairRO.of(l, userData));
		}

		lock.writeLock().unlock();
	}

	public void removeListener(final SSHSAttrListener<V> l, final Object userData) {
		lock.writeLock().lock();

		listeners.remove(PairRO.of(l, userData));

		lock.writeLock().unlock();
	}
}
