package net.sf.jaer2.devices;

public class ConfigBitTristate extends ConfigBase {
	public static enum Tristate {
		LOW(0),
		HIGH(1),
		HIZ(2);

		private final String str;

		private Tristate(final int i) {
			str = Integer.toString(i);
		}

		@Override
		public final String toString() {
			return str;
		}

		public final boolean isLow() {
			return (this == Tristate.LOW);
		}

		public final boolean isHigh() {
			return (this == Tristate.HIGH);
		}

		public final boolean isHiZ() {
			return (this == Tristate.HIZ);
		}
	}

	private Tristate value;

	public ConfigBitTristate(final String name, final String description, final Tristate defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public Tristate getValue() {
		return value;
	}

	public void setValue(final Tristate value) {
		this.value = value;
	}
}
