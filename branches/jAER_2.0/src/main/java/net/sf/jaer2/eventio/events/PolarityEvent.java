package net.sf.jaer2.eventio.events;

public class PolarityEvent extends XYPositionEvent {
	public static enum Polarity {
		ON,
		OFF,
	}

	private Polarity polarity;

	public PolarityEvent(final int ts) {
		super(ts);
	}

	public Polarity getPolarity() {
		return polarity;
	}

	public void setPolarity(final Polarity polarity) {
		this.polarity = polarity;
	}

	protected final void deepCopyInternal(final PolarityEvent evt) {
		super.deepCopyInternal(evt);

		evt.polarity = polarity;
	}

	@Override
	public PolarityEvent deepCopy() {
		final PolarityEvent evt = new PolarityEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
