package net.sf.jaer2.eventio.events;

public class XYPositionEvent extends Event {
	private static final long serialVersionUID = 5576838970200124104L;

	private short x;
	private short y;

	public XYPositionEvent(final int ts) {
		super(ts);
	}

	public short getX() {
		return x;
	}

	public void setX(final short x) {
		this.x = x;
	}

	public short getY() {
		return y;
	}

	public void setY(final short y) {
		this.y = y;
	}

	protected final void deepCopyInternal(final XYPositionEvent evt) {
		super.deepCopyInternal(evt);

		evt.x = x;
		evt.y = y;
	}

	@Override
	public XYPositionEvent deepCopy() {
		final XYPositionEvent evt = new XYPositionEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
