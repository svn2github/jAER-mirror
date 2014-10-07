package net.sf.jaer2.util;

public class TripleRO<T, U, V> {
	private final T one;
	private final U two;
	private final V three;

	public TripleRO(final T one, final U two, final V three) {
		this.one = one;
		this.two = two;
		this.three = three;
	}

	public final T getFirst() {
		return one;
	}

	public final U getSecond() {
		return two;
	}

	public final V getThird() {
		return three;
	}

	public static final <T, U, V> TripleRO<T, U, V> of(final T one, final U two, final V three) {
		return new TripleRO<>(one, two, three);
	}

	@Override
	public String toString() {
		return String.format("First = [%s], Second = [%s], Third = [%s]", one.toString(), two.toString(),
			three.toString());
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = (prime * result) + ((one == null) ? 0 : one.hashCode());
		result = (prime * result) + ((three == null) ? 0 : three.hashCode());
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
		if (getClass() != obj.getClass()) {
			return false;
		}

		final TripleRO<?, ?, ?> other = (TripleRO<?, ?, ?>) obj;

		if (one == null) {
			if (other.one != null) {
				return false;
			}
		}
		else if (!one.equals(other.one)) {
			return false;
		}

		if (three == null) {
			if (other.three != null) {
				return false;
			}
		}
		else if (!three.equals(other.three)) {
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
