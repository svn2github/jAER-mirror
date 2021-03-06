package net.sf.jaer2.eventio.eventpackets;

import java.security.InvalidParameterException;
import java.util.AbstractCollection;
import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;
import java.util.NoSuchElementException;

import net.sf.jaer2.eventio.events.Event;
import net.sf.jaer2.util.PredicateIterator;

public final class EventPacket<E extends Event> extends AbstractCollection<E> {
	private static final int DEFAULT_EVENT_CAPACITY = 2048;

	// RawEvents array and index into it for adding new elements.
	private E[] events;
	private int lastEvent;
	private int validEvents;

	private final Class<E> eventType;
	private short eventSource;
	private EventPacketContainer parentContainer;

	private boolean timeOrdered;
	private boolean timeOrderingEnforced;

	public EventPacket(final Class<E> type, final short source) {
		this(type, source, false);
	}

	public EventPacket(final Class<E> type, final short source, final boolean timeOrder) {
		this(type, source, EventPacket.DEFAULT_EVENT_CAPACITY, timeOrder);
	}

	public EventPacket(final Class<E> type, final short source, final int capacity) {
		this(type, source, capacity, false);
	}

	public EventPacket(final Class<E> type, final short source, final int capacity, final boolean timeOrder) {
		super();

		// Check passed parameters before assigning.
		if (type == null) {
			throw new InvalidParameterException("type cannot be null!");
		}
		if (source <= 0) {
			throw new InvalidParameterException("source cannot be zero or smaller, must be defined clearly!");
		}
		if (capacity <= 0) {
			throw new InvalidParameterException("capacity cannot be zero or smaller!");
		}

		eventType = type;
		eventSource = source;
		timeOrderingEnforced = timeOrder;

		// Use user-supplied capacity.
		events = net.sf.jaer2.util.Arrays.newArrayFromType(type, capacity);
	}

	public Class<E> getEventType() {
		return eventType;
	}

	public short getEventSource() {
		return eventSource;
	}

	public void setEventSource(final short source) {
		eventSource = source;

		// Update all events accordingly!
		for (int i = 0; i < lastEvent; i++) {
			events[i].setSourceID(source);
		}
	}

	public EventPacketContainer getParentContainer() {
		return parentContainer;
	}

	void setParentContainer(final EventPacketContainer container) {
		if (parentContainer == container) {
			// Return right away if setting to previous value (no change).
			return;
		}

		parentContainer = container;

		if ((parentContainer != null) && parentContainer.isTimeOrderingEnforced()) {
			setTimeOrderingEnforced(true);
		}
	}

	private void rebuildGlobalTimeOrder() {
		// Rebuild global time-order list.
		if ((parentContainer != null) && parentContainer.isTimeOrderingEnforced()) {
			parentContainer.rebuildGlobalTimeOrder();
		}
	}

	@Override
	public void clear() {
		if (clearInternal()) {
			rebuildGlobalTimeOrder();
		}
	}

	boolean clearInternal() {
		if (lastEvent == 0) {
			// Nothing to clear if lastEvent was never increased.
			return false;
		}

		// Ensure freeing by GC.
		for (int i = 0; i < lastEvent; i++) {
			events[i] = null;
		}

		lastEvent = 0;
		validEvents = 0;

		return true;
	}

	public int capacity() {
		return events.length;
	}

	public int sizeFull() {
		return lastEvent;
	}

	@Override
	public int size() {
		return validEvents;
	}

	public boolean isEmptyFull() {
		return (lastEvent == 0);
	}

	@Override
	public boolean isEmpty() {
		return (validEvents == 0);
	}

	/**
	 * Double array capacity until there is enough place for the supplied amount
	 * of elements to be added and then copy over old elements to new array.
	 *
	 * @param number
	 *            number of additional elements to ensure available space for
	 */
	private void increaseCapacity(final int number) {
		int arrayLength = events.length;
		int currentCapacity = arrayLength - lastEvent;

		// Keep doubling array capacity until it's enough.
		while (currentCapacity < number) {
			arrayLength *= 2;
			currentCapacity = arrayLength - lastEvent;
		}

		final E[] eventsNew = net.sf.jaer2.util.Arrays.newArrayFromType(eventType, arrayLength);

		System.arraycopy(events, 0, eventsNew, 0, events.length);

		events = eventsNew;
	}

	public void ensureCapacity(final int number) {
		// First check if there's enough capacity in the still empty part of the
		// events array.
		int currentCapacity = events.length - lastEvent;

		if (currentCapacity >= number) {
			return;
		}

		// Then check if by compacting we can gain enough capacity on the
		// current events array.
		currentCapacity += compactGain();
		compact();

		if (currentCapacity >= number) {
			return;
		}

		// As a last resort, increase the capacity, so that there is enough
		// place for sure available.
		increaseCapacity(number);
	}

	/**
	 * Calculate how much events can be freed by compacting the EventPacket.
	 *
	 * @return number of freeable events
	 */
	public int compactGain() {
		return (lastEvent - validEvents);
	}

	/**
	 * Compact EventPacket by removing all invalid events.
	 */
	public void compact() {
		if (compactInternal()) {
			rebuildGlobalTimeOrder();
		}
	}

	boolean compactInternal() {
		// Compact only if there actually is anything to compact.
		if (compactGain() == 0) {
			return false;
		}

		int copyOffset = 0;
		int position = 0;

		for (; position < lastEvent; position++) {
			if (events[position].isValid()) {
				if (copyOffset == 0) {
					continue;
				}

				events[(position - copyOffset)] = events[position];
			}
			else {
				copyOffset++;
			}
		}

		// Reset array length.
		lastEvent -= copyOffset;

		// Ensure freeing by GC.
		for (int i = lastEvent; i < position; i++) {
			events[i] = null;
		}

		return true;
	}

	/**
	 * Append one event to the EventPacket, after all other events.
	 * If needed, take care to manually ensure time ordering, either by adding
	 * the packets in such an order that you know follows time ordering and then
	 * calling setTimeOrdered(true) yourself, or by calling
	 * setTimeOrdered(false), which will take the correct actions to ensure
	 * compliance with time ordering policy as needed.
	 *
	 * @param evt
	 *            event to add to the end of the EventPacket
	 *
	 * @throws NullPointerException
	 *             evt cannot be null
	 * @throws InvalidParameterException
	 *             evt has an incompatible source ID
	 */
	public void append(final E evt) {
		// Disallow adding NULL events.
		if (evt == null) {
			throw new NullPointerException();
		}

		// Disallow adding events from other sources.
		// <= 0 are accepted and converted to this source implicitly.
		final int source = evt.getSourceID();

		if (source != eventSource) {
			if (source > 0) {
				throw new InvalidParameterException("Event from incompatible source!");
			}

			evt.setSourceID(eventSource);
		}

		ensureCapacity(1);

		@SuppressWarnings("unchecked")
		final E newEvt = (E) evt.deepCopy();

		// Add event.
		events[lastEvent++] = newEvt;

		if (newEvt.isValid()) {
			validEvents++;
		}

		// Not able to guarantee time ordering after appending!
		timeOrdered = false;
	}

	/**
	 * Add one event to the EventPacket, ensuring time ordering as needed by the
	 * time ordering policy.
	 *
	 * @param evt
	 *            event to add to the EventPacket
	 */
	@Override
	public boolean add(final E evt) {
		append(evt);

		// Make sure time ordering is still present, if requested.
		if (timeOrderingEnforced) {
			timeOrder();
		}

		return true;
	}

	/**
	 * Add multiple events to the EventPacket, ensuring time ordering as needed
	 * by the time ordering policy.
	 *
	 * @param evts
	 *            events to add to the EventPacket
	 */
	public boolean addAll(final E[] evts) {
		// Efficiently convert array to array-list, so that the Iterable-based
		// method can be used.
		return addAll(Arrays.asList(evts));
	}

	/**
	 * Add multiple events to the EventPacket, ensuring time ordering as needed
	 * by the time ordering policy.
	 *
	 * @param evts
	 *            events to add to the EventPacket
	 */
	@Override
	public boolean addAll(final Collection<? extends E> evts) {
		ensureCapacity(evts.size());

		// Copy all events over.
		for (final E evt : evts) {
			append(evt);
		}

		// Make sure time ordering is still present, if requested.
		if (timeOrderingEnforced) {
			timeOrder();
		}

		return true;
	}

	public void appendPacket(final EventPacket<E> evtPacket) {
		// Disallow adding NULL EventPackets (fail!).
		if (evtPacket == null) {
			throw new NullPointerException();
		}

		// Disallow adding EventPackets from other sources.
		if (evtPacket.getEventSource() != eventSource) {
			throw new InvalidParameterException("EventPacket from incompatible source!");
		}

		ensureCapacity(evtPacket.sizeFull());

		for (final Iterator<E> iter = evtPacket.iteratorFull(); iter.hasNext();) {
			append(iter.next());
		}
	}

	public boolean addPacket(final EventPacket<E> evtPacket) {
		appendPacket(evtPacket);

		// Make sure time ordering is still present, if requested.
		if (timeOrderingEnforced) {
			timeOrder();
		}

		return true;
	}

	public boolean addAllPackets(final EventPacket<E>[] evtPackets) {
		return addAllPackets(Arrays.asList(evtPackets));
	}

	public boolean addAllPackets(final Iterable<EventPacket<E>> evtPackets) {
		// Add all EventPackets.
		for (final EventPacket<E> evtPacket : evtPackets) {
			appendPacket(evtPacket);
		}

		// Make sure time ordering is still present, if requested.
		if (timeOrderingEnforced) {
			timeOrder();
		}

		return true;
	}

	public boolean isTimeOrdered() {
		return timeOrdered;
	}

	public void setTimeOrdered(final boolean timeOrder) {
		timeOrdered = timeOrder;

		if (!timeOrdered && !timeOrderingEnforced) {
			// In the case explicit time ordering is not wanted, nor required,
			// simply return without doing anything.
			return;
		}

		// In all other cases, enforce either the requirement or the will of the
		// user. Only sort locally if needed, but always update the global
		// time-ordered list if the container needs it.
		timeOrderInternal();
		rebuildGlobalTimeOrder();
	}

	public boolean isTimeOrderingEnforced() {
		return timeOrderingEnforced;
	}

	/**
	 * @param timeOrderEnforced
	 *            enable or disable time-order enforcing
	 *
	 * @throws IllegalStateException
	 *             if trying to disable time-order enforcing while the parent
	 *             container still requires it
	 */
	public void setTimeOrderingEnforced(final boolean timeOrderEnforced) {
		if (timeOrderingEnforced == timeOrderEnforced) {
			// Return right away if setting to previous value (no change).
			return;
		}

		timeOrderingEnforced = timeOrderEnforced;

		// Reset time order enforcing back to enabled if a parent container
		// exists and requires it.
		if ((timeOrderingEnforced == false) && (parentContainer != null) && parentContainer.isTimeOrderingEnforced()) {
			throw new IllegalStateException();
		}

		// If time ordering enforced, but not yet time ordered, do so.
		if (timeOrderingEnforced && !timeOrdered) {
			timeOrderInternal();
		}
	}

	public void timeOrder() {
		if (timeOrderInternal()) {
			rebuildGlobalTimeOrder();
		}
	}

	boolean timeOrderInternal() {
		// Nothing to do if already timeOrdered.
		if (timeOrdered) {
			return false;
		}

		timeOrdered = true;

		// Sort by timestamp.
		Arrays.sort(events, 0, lastEvent);

		return true;
	}

	@Override
	public Iterator<E> iterator() {
		return new PredicateIterator<E>(iteratorFull()) {
			@Override
			public boolean verifyPredicate(final E element) {
				return element.isValid();
			}
		};
	}

	public Iterator<E> iteratorFull() {
		return new EventPacketIteratorFull();
	}

	private final class EventPacketIteratorFull implements Iterator<E> {
		private int position = 0;
		private boolean nextCalled = false;

		@Override
		public boolean hasNext() {
			if (position < lastEvent) {
				return true;
			}

			return false;
		}

		@Override
		public E next() {
			if (!hasNext()) {
				throw new NoSuchElementException();
			}

			// Support remove() correctly.
			nextCalled = true;

			return events[position++];
		}

		@Override
		public void remove() {
			if (!nextCalled) {
				throw new IllegalStateException();
			}

			nextCalled = false;

			// Remove by invalidating the current element (-1 because next()
			// always does +1 internally), but only if it was valid originally.
			if (events[(position - 1)].isValid()) {
				events[(position - 1)].invalidate();
				validEvents--;
			}
		}
	}

	public Iterator<E> iteratorTimeOrder() {
		if (!timeOrdered) {
			throw new UnsupportedOperationException("EventPacket doesn't support time-ordering (not time-ordered).");
		}

		return iterator();
	}

	public Iterator<E> iteratorTimeOrderFull() {
		if (!timeOrdered) {
			throw new UnsupportedOperationException("EventPacket doesn't support time-ordering (not time-ordered).");
		}

		return iteratorFull();
	}

	@Override
	public boolean contains(final Object obj) {
		if (obj == null) {
			throw new NullPointerException();
		}

		if (!(obj instanceof Event)) {
			throw new ClassCastException();
		}

		return super.contains(obj);
	}

	@Override
	public boolean containsAll(final Collection<?> coll) {
		if (coll == null) {
			throw new NullPointerException();
		}

		for (final Object obj : coll) {
			if (obj == null) {
				throw new NullPointerException();
			}

			if (!(obj instanceof Event)) {
				throw new ClassCastException();
			}
		}

		return super.containsAll(coll);
	}

	@Override
	public boolean remove(final Object obj) {
		if (obj == null) {
			throw new NullPointerException();
		}

		if (!(obj instanceof Event)) {
			throw new ClassCastException();
		}

		return super.remove(obj);
	}

	@Override
	public boolean removeAll(final Collection<?> coll) {
		if (coll == null) {
			throw new NullPointerException();
		}

		for (final Object obj : coll) {
			if (obj == null) {
				throw new NullPointerException();
			}

			if (!(obj instanceof Event)) {
				throw new ClassCastException();
			}
		}

		return super.removeAll(coll);
	}

	@Override
	public boolean retainAll(final Collection<?> coll) {
		if (coll == null) {
			throw new NullPointerException();
		}

		for (final Object obj : coll) {
			if (obj == null) {
				throw new NullPointerException();
			}

			if (!(obj instanceof Event)) {
				throw new ClassCastException();
			}
		}

		return super.retainAll(coll);
	}
}
