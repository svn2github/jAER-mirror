package net.sf.jaer2.eventio.events;

public class IMUEvent extends Event {
	private static final long serialVersionUID = 4495287162153651358L;

	private short accelX;
	private short accelY;
	private short accelZ;

	private short gyroX;
	private short gyroY;
	private short gyroZ;

	private short temp;

	public IMUEvent(final int ts) {
		super(ts);
	}

	public short getAccelX() {
		return accelX;
	}

	public void setAccelX(final short accelX) {
		this.accelX = accelX;
	}

	public short getAccelY() {
		return accelY;
	}

	public void setAccelY(final short accelY) {
		this.accelY = accelY;
	}

	public short getAccelZ() {
		return accelZ;
	}

	public void setAccelZ(final short accelZ) {
		this.accelZ = accelZ;
	}

	public short getGyroX() {
		return gyroX;
	}

	public void setGyroX(final short gyroX) {
		this.gyroX = gyroX;
	}

	public short getGyroY() {
		return gyroY;
	}

	public void setGyroY(final short gyroY) {
		this.gyroY = gyroY;
	}

	public short getGyroZ() {
		return gyroZ;
	}

	public void setGyroZ(final short gyroZ) {
		this.gyroZ = gyroZ;
	}

	public short getTemp() {
		return temp;
	}

	public void setTemp(short temp) {
		this.temp = temp;
	}

	protected final void deepCopyInternal(final IMUEvent evt) {
		super.deepCopyInternal(evt);

		evt.accelX = accelX;
		evt.accelY = accelY;
		evt.accelZ = accelZ;

		evt.gyroX = gyroX;
		evt.gyroY = gyroY;
		evt.gyroZ = gyroZ;

		evt.temp = temp;
	}

	@Override
	public IMUEvent deepCopy() {
		final IMUEvent evt = new IMUEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
