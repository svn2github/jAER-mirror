package net.sf.jaer2.eventio.events;

import java.util.Arrays;

public class FrameEvent extends Event {
	// Timestamps
	private int tsStartOfExposure;
	private int tsEndOfExposure;
	private int tsStartOfResetRead;
	private int tsEndOfResetRead;
	private int tsStartOfSignalRead;
	private int tsEndOfSignalRead;

	// Frame information
	private short sizeX;
	private short sizeY;
	private short depthADC;

	// Frame content
	private short[] frame;
	private short[] frameReset; // Can be null
	private short[] frameSignal; // Can be null

	public FrameEvent(final int ts, final short x, final short y) {
		super(ts);

		sizeX = x;
		sizeY = y;

		frame = new short[sizeX * sizeY];
	}

	public int getTsStartOfExposure() {
		return tsStartOfExposure;
	}

	public void setTsStartOfExposure(final int tsStartOfExposure) {
		this.tsStartOfExposure = tsStartOfExposure;
	}

	public int getTsEndOfExposure() {
		return tsEndOfExposure;
	}

	public void setTsEndOfExposure(final int tsEndOfExposure) {
		this.tsEndOfExposure = tsEndOfExposure;
	}

	public int getTsStartOfResetRead() {
		return tsStartOfResetRead;
	}

	public void setTsStartOfResetRead(final int tsStartOfResetRead) {
		this.tsStartOfResetRead = tsStartOfResetRead;
	}

	public int getTsEndOfResetRead() {
		return tsEndOfResetRead;
	}

	public void setTsEndOfResetRead(final int tsEndOfResetRead) {
		this.tsEndOfResetRead = tsEndOfResetRead;
	}

	public int getTsStartOfSignalRead() {
		return tsStartOfSignalRead;
	}

	public void setTsStartOfSignalRead(final int tsStartOfSignalRead) {
		this.tsStartOfSignalRead = tsStartOfSignalRead;
	}

	public int getTsEndOfSignalRead() {
		return tsEndOfSignalRead;
	}

	public void setTsEndOfSignalRead(final int tsEndOfSignalRead) {
		this.tsEndOfSignalRead = tsEndOfSignalRead;
	}

	public short getSizeX() {
		return sizeX;
	}

	public void setSizeX(final short sizeX) {
		this.sizeX = sizeX;
	}

	public short getSizeY() {
		return sizeY;
	}

	public void setSizeY(final short sizeY) {
		this.sizeY = sizeY;
	}

	public short getDepthADC() {
		return depthADC;
	}

	public void setDepthADC(final short depthADC) {
		this.depthADC = depthADC;
	}

	public short[] getFrame() {
		return frame;
	}

	public void setFrame(final short[] frame) {
		this.frame = frame;
	}

	public short[] getFrameReset() {
		return frameReset;
	}

	public void setFrameReset(final short[] frameReset) {
		this.frameReset = frameReset;
	}

	public short[] getFrameSignal() {
		return frameSignal;
	}

	public void setFrameSignal(final short[] frameSignal) {
		this.frameSignal = frameSignal;
	}

	protected final void deepCopyInternal(final FrameEvent evt) {
		super.deepCopyInternal(evt);

		evt.tsStartOfExposure = tsStartOfExposure;
		evt.tsEndOfExposure = tsEndOfExposure;
		evt.tsStartOfResetRead = tsStartOfResetRead;
		evt.tsEndOfResetRead = tsEndOfResetRead;
		evt.tsStartOfSignalRead = tsStartOfSignalRead;
		evt.tsEndOfSignalRead = tsEndOfSignalRead;

		evt.depthADC = depthADC;

		System.arraycopy(frame, 0, evt.frame, 0, frame.length);
		if (frameReset != null) {
			evt.frameReset = Arrays.copyOf(frameReset, frameReset.length);
		}
		if (frameSignal != null) {
			evt.frameSignal = Arrays.copyOf(frameSignal, frameSignal.length);
		}
	}

	@Override
	public FrameEvent deepCopy() {
		final FrameEvent evt = new FrameEvent(getTimestamp(), sizeX, sizeY);
		deepCopyInternal(evt);
		return evt;
	}
}
