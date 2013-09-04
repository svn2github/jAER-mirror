package net.sf.jaer2.eventio.events;

public class IMUEvent extends Event {
	private static final long serialVersionUID = 4495287162153651358L;

	public short accelX;
	public short accelY;
	public short accelZ;

	public short gyroX;
	public short gyroY;
	public short gyroZ;

	public IMUEvent(final int ts) {
		super(ts);
	}

	protected final void deepCopyInternal(final IMUEvent evt) {
		super.deepCopyInternal(evt);

		evt.accelX = accelX;
		evt.accelY = accelY;
		evt.accelZ = accelZ;

		evt.gyroX = gyroX;
		evt.gyroY = gyroY;
		evt.gyroZ = gyroZ;
	}

	@Override
	public IMUEvent deepCopy() {
		final IMUEvent evt = new IMUEvent(timestamp);
		deepCopyInternal(evt);
		return evt;
	}
}
