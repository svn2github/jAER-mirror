package net.sf.jaer2.util;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

public final class TripleRO<T, U, V> {
	private final T one;
	private final U two;
	private final V three;

	public TripleRO(final T one, final U two, final V three) {
		this.one = one;
		this.two = two;
		this.three = three;
	}

	public T getFirst() {
		return one;
	}

	public U getSecond() {
		return two;
	}

	public V getThird() {
		return three;
	}

	@Override
	public int hashCode() {
		return new HashCodeBuilder().append(one).append(two).append(three).toHashCode();
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj) {
			return true;
		}
		if (obj == null) {
			return false;
		}
		if (this.getClass() != obj.getClass()) {
			return false;
		}

		final TripleRO<?, ?, ?> other = (TripleRO<?, ?, ?>) obj;

		return new EqualsBuilder().append(one, other.one).append(two, other.two).append(three, other.three).isEquals();
	}

	@Override
	public String toString() {
		return String.format("First = [%s], Second = [%s], Third = [%s]", one.toString(), two.toString(),
			three.toString());
	}
}
