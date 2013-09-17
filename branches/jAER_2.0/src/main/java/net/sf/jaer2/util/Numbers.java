package net.sf.jaer2.util;

public final class Numbers {
	public static enum NumberFormat {
		BINARY(2),
		OCTAL(8),
		DECIMAL(10),
		HEXADECIMAL(16);

		private final int base;

		private NumberFormat(final int i) {
			base = i;
		}

		public int base() {
			return base;
		}

		@Override
		public final String toString() {
			return String.format("%d", base);
		}
	}

	public static Integer stringToInteger(final String str, final NumberFormat fmt) {
		if ((str == null) || str.isEmpty()) {
			return 0;
		}

		return Integer.parseUnsignedInt(str, fmt.base());
	}

	public static String integerToString(final Integer i, final NumberFormat fmt) {
		if ((i == null) || (i < 0)) {
			return "0";
		}

		return Integer.toUnsignedString(i, fmt.base());
	}
}
