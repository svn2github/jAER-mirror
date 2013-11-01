package net.sf.jaer2.eventio.events;

public class EarEvent extends Event {
	private static final long serialVersionUID = 3374862098656713211L;

	public static enum Ear {
		LEFT_FRONT,
		RIGHT_FRONT,
		LEFT_BACK,
		RIGHT_BACK,
	}

	private Ear ear;
	private byte ganglion;
	private byte filter;
	private short channel;

	public EarEvent(final int ts) {
		super(ts);
	}

	protected final void deepCopyInternal(final EarEvent evt) {
		super.deepCopyInternal(evt);

		evt.ear = ear;
		evt.ganglion = ganglion;
		evt.filter = filter;
		evt.channel = channel;
	}

	@Override
	public EarEvent deepCopy() {
		final EarEvent evt = new EarEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
