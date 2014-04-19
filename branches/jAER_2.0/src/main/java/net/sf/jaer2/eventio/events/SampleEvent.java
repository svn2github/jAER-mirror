package net.sf.jaer2.eventio.events;

public class SampleEvent extends Event {
	private byte type;
	private int sample;

	public SampleEvent(final int ts) {
		super(ts);
	}

	public byte getType() {
		return type;
	}

	public void setType(final byte type) {
		this.type = type;
	}

	public int getSample() {
		return sample;
	}

	public void setSample(final int sample) {
		this.sample = sample;
	}

	protected final void deepCopyInternal(final SampleEvent evt) {
		super.deepCopyInternal(evt);

		evt.sample = sample;
	}

	@Override
	public SampleEvent deepCopy() {
		final SampleEvent evt = new SampleEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
