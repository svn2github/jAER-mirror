package net.sf.jaer2.devices.config;

public class ConfigBitTristate extends ConfigBase {
	/**
	 * 
	 */
	private static final long serialVersionUID = -554758992623341136L;

	public static enum Tristate {
		LOW(0),
		HIGH(1),
		HIZ(2);

		private final String str;
		private final int bitValue;
		private final String bitValueAsString;

		private Tristate(final int i) {
			str = (i == 0) ? ("LOW") : ((i == 1) ? ("HIGH") : ("HIZ"));
			bitValue = i;
			bitValueAsString = Integer.toBinaryString(i);
		}

		@Override
		public final String toString() {
			return str;
		}

		public final int bitValue() {
			return bitValue;
		}

		public final String bitValueAsString() {
			return bitValueAsString;
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
