package net.sf.jaer2.eventio.events;

public abstract class XYZPositionEvent extends XYPositionEvent {
	private static final long serialVersionUID = -7413859531742503973L;

	private short z;

	public XYZPositionEvent(final int ts) {
		super(ts);
	}

	public short getZ() {
		return z;
	}

	public void setZ(final short z) {
		this.z = z;
	}

	protected final void deepCopyInternal(final XYZPositionEvent evt) {
		super.deepCopyInternal(evt);

		evt.z = z;
	}
}
