package net.sf.jaer2.util;

public class PairRO<T, U> {
	private final T one;
	private final U two;

	public PairRO(final T one, final U two) {
		this.one = one;
		this.two = two;
	}

	public final T getFirst() {
		return one;
	}

	public final U getSecond() {
		return two;
	}

	public static final <T, U> PairRO<T, U> of(final T one, final U two) {
		return new PairRO<>(one, two);
	}

	@Override
	public String toString() {
		return String.format("First = [%s], Second = [%s]", one.toString(), two.toString());
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = (prime * result) + ((one == null) ? 0 : one.hashCode());
		result = (prime * result) + ((two == null) ? 0 : two.hashCode());
		return result;
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

		if (one == null) {
			if (other.one != null) {
				return false;
			}
		}
		else if (!one.equals(other.one)) {
			return false;
		}

		if (two == null) {
			if (other.two != null) {
				return false;
			}
		}
		else if (!two.equals(other.two)) {
			return false;
		}

		return true;
	}
}
