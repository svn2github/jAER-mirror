package net.sf.jaer2.eventio.events;

import java.util.Arrays;

public class FrameEvent extends Event {
	private static final long serialVersionUID = 615761097757470341L;

	private short sizeX;
	private short sizeY;
	private int[] frame;

	public FrameEvent(final int ts) {
		super(ts);
	}

	public short getSizeX() {
		return sizeX;
	}

	public void setSizeX(short sizeX) {
		this.sizeX = sizeX;
	}

	public short getSizeY() {
		return sizeY;
	}

	public void setSizeY(short sizeY) {
		this.sizeY = sizeY;
	}

	public int[] getFrame() {
		return frame;
	}

	public void setFrame(int[] frame) {
		this.frame = frame;
	}

	protected final void deepCopyInternal(final FrameEvent evt) {
		super.deepCopyInternal(evt);

		evt.sizeX = sizeX;
		evt.sizeY = sizeY;

		evt.frame = Arrays.copyOf(frame, frame.length);
	}

	@Override
	public FrameEvent deepCopy() {
		final FrameEvent evt = new FrameEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
