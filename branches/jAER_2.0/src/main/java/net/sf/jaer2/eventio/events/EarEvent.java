package net.sf.jaer2.eventio.events;

public class EarEvent extends Event {
	public static enum Ear {
		LEFT_FRONT,
		RIGHT_FRONT,
		LEFT_BACK,
		RIGHT_BACK,
	}

	private Ear ear;
	private byte filter;
	private short ganglion;
	private short channel;

	public EarEvent(final int ts) {
		super(ts);
	}

	public Ear getEar() {
		return ear;
	}

	public void setEar(final Ear ear) {
		this.ear = ear;
	}

	public byte getFilter() {
		return filter;
	}

	public void setFilter(final byte filter) {
		this.filter = filter;
	}

	public short getGanglion() {
		return ganglion;
	}

	public void setGanglion(final short ganglion) {
		this.ganglion = ganglion;
	}

	public short getChannel() {
		return channel;
	}

	public void setChannel(final short channel) {
		this.channel = channel;
	}

	protected final void deepCopyInternal(final EarEvent evt) {
		super.deepCopyInternal(evt);

		evt.ear = ear;
		evt.filter = filter;
		evt.ganglion = ganglion;
		evt.channel = channel;
	}

	@Override
	public EarEvent deepCopy() {
		final EarEvent evt = new EarEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
