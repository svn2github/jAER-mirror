package net.sf.jaer2.util;

public final class Numbers {
	public static enum NumberFormat {
		BINARY(2),
		BINARY_UNSIGNED(2),
		OCTAL(8),
		OCTAL_UNSIGNED(8),
		DECIMAL(10),
		DECIMAL_UNSIGNED(10),
		HEXADECIMAL(16),
		HEXADECIMAL_UNSIGNED(16);

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

		Integer result;

		switch (fmt) {
			case BINARY:
			case OCTAL:
			case DECIMAL:
			case HEXADECIMAL:
				result = Integer.parseInt(str, fmt.base());
				break;

			default:
				result = Integer.parseUnsignedInt(str, fmt.base());
				break;
		}

		return result;
	}

	public static String integerToString(final Integer i, final NumberFormat fmt) {
		if ((i == null) || (i == 0)) {
			return "0";
		}

		String result;

		switch (fmt) {
			case BINARY:
			case OCTAL:
			case DECIMAL:
			case HEXADECIMAL:
				result = Integer.toString(i, fmt.base());
				break;

			default:
				result = Integer.toUnsignedString(i, fmt.base());
				break;
		}

		return result;
	}
}
