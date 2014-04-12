package net.sf.jaer2.util;

import java.util.concurrent.atomic.AtomicReferenceArray;

import sun.misc.Contended;

public final class RingBuffer<E> {
	@Contended
	private int putPos;
	@Contended
	private int getPos;
	private final AtomicReferenceArray<E> elements;

	public RingBuffer() {
		this(32);
	}

	public RingBuffer(final int size) {
		// Force multiple of two size for performance.
		if ((size <= 0) || ((size & (size - 1)) != 0)) {
			throw new IllegalArgumentException("Size must be a positive power of two.");
		}

		elements = new AtomicReferenceArray<>(size);
	}

	public boolean put(final E elem) {
		if (elem == null) {
			// NULL elements are disallowed (used as place-holders).
			// Critical error, should never happen -> throw exception!
			throw new IllegalArgumentException("Element cannot be null.");
		}

		final E curr = elements.get(putPos);

		// If the place where we want to put the new element is NULL, it's still
		// free and we can use it.
		if (curr == null) {
			elements.set(putPos, elem);

			// Increase local put pointer.
			putPos = ((putPos + 1) & (elements.length() - 1));

			return (true);
		}

		// Else, buffer is full.
		return (false);
	}

	public E get() {
		final E curr = elements.get(getPos);

		// If the place where we want to get an element from is not NULL, there
		// is valid content there, which we return, and reset the place to NULL.
		if (curr != null) {
			elements.set(getPos, null);

			// Increase local get pointer.
			getPos = ((getPos + 1) & (elements.length() - 1));

			return (curr);
		}

		// Else, buffer is empty.
		return (null);
	}

	public E look() {
		final E curr = elements.get(getPos);

		// If the place where we want to get an element from is not NULL, there
		// is valid content there, which we return, without removing it from the
		// ring buffer.
		if (curr != null) {
			return (curr);
		}

		// Else, buffer is empty.
		return (null);
	}
}
