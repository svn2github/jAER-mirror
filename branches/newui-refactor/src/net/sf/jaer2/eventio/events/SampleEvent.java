package net.sf.jaer2.eventio.events;

public class SampleEvent extends XYPositionEvent {
	public int sample;

	public SampleEvent(final int ts) {
		super(ts);
	}

	protected final void deepCopyInternal(final SampleEvent evt) {
		super.deepCopyInternal(evt);

		evt.sample = sample;
	}

	@Override
	public SampleEvent deepCopy() {
		final SampleEvent evt = new SampleEvent(timestamp);
		deepCopyInternal(evt);
		return evt;
	}
}
