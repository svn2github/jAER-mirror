package net.sf.jaer2.eventio.events;

public class IMU9Event extends IMU6Event {
	private short compX;
	private short compY;
	private short compZ;

	public IMU9Event(final int ts) {
		super(ts);
	}

	public short getCompX() {
		return compX;
	}

	public void setCompX(final short compX) {
		this.compX = compX;
	}

	public short getCompY() {
		return compY;
	}

	public void setCompY(final short compY) {
		this.compY = compY;
	}

	public short getCompZ() {
		return compZ;
	}

	public void setCompZ(final short compZ) {
		this.compZ = compZ;
	}

	protected final void deepCopyInternal(final IMU9Event evt) {
		super.deepCopyInternal(evt);

		evt.compX = compX;
		evt.compY = compY;
		evt.compZ = compZ;
	}

	@Override
	public IMU9Event deepCopy() {
		final IMU9Event evt = new IMU9Event(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
