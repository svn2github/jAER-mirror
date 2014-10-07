package net.sf.jaer2.eventio.events;

public class SpecialEvent extends XYPositionEvent {
	public static enum Type {
		TIMESTAMP_WRAP,
		TIMESTAMP_RESET,
		EXTERNAL_TRIGGER,
		ROW_ONLY,
	}

	private Type type;

	public SpecialEvent(final int ts) {
		super(ts);
	}

	public Type getType() {
		return type;
	}

	public void setType(final Type type) {
		this.type = type;
	}

	protected final void deepCopyInternal(final SpecialEvent evt) {
		super.deepCopyInternal(evt);

		evt.type = type;
	}

	@Override
	public SpecialEvent deepCopy() {
		final SpecialEvent evt = new SpecialEvent(getTimestamp());
		deepCopyInternal(evt);
		return evt;
	}
}
