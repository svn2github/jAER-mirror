package net.sf.jaer2.util;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

public class PairRO<T, U> {
	private final T one;
	private final U two;

	public PairRO(final T one, final U two) {
		this.one = one;
		this.two = two;
	}

	public T getFirst() {
		return one;
	}

	public U getSecond() {
		return two;
	}

	@Override
	public int hashCode() {
		return new HashCodeBuilder().append(one).append(two).toHashCode();
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

		final PairRO<?, ?> other = (PairRO<?, ?>) obj;

		return new EqualsBuilder().append(one, other.one).append(two, other.two).isEquals();
	}

	@Override
	public String toString() {
		return String.format("First = [%s], Second = [%s]", one.toString(), two.toString());
	}

	public static <T, U> PairRO<T, U> of(final T one, final U two) {
		return new PairRO<>(one, two);
	}
}
