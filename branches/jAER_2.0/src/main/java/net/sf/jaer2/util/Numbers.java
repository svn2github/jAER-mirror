package net.sf.jaer2.util;

import java.util.EnumSet;

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

	public static enum NumberOptions {
		UNSIGNED,
		ZERO_PADDING,
		LEFT_PADDING,
		RIGHT_PADDING;
	}

	public static Integer stringToInteger(final String str, final NumberFormat fmt, final NumberOptions opt) {
		return Numbers.stringToInteger(str, fmt, EnumSet.of(opt));
	}

	public static Integer stringToInteger(final String str, final NumberFormat fmt, final EnumSet<NumberOptions> opts) {
		if ((str == null) || str.isEmpty()) {
			return 0;
		}

		if (opts.contains(NumberOptions.UNSIGNED)) {
			return Integer.parseUnsignedInt(str, fmt.base());
		}

		return Integer.parseInt(str, fmt.base());
	}

	public static String integerToString(final Integer i, final NumberFormat fmt, final NumberOptions opt) {
		return Numbers.integerToString(i, fmt, EnumSet.of(opt));
	}

	public static String integerToString(final Integer i, final NumberFormat fmt, final EnumSet<NumberOptions> opts) {
		final StringBuilder s = new StringBuilder();

		if ((i == null) || (i == 0)) {
			s.append('0');
		}
		else if (opts.contains(NumberOptions.UNSIGNED)) {
			s.append(Integer.toUnsignedString(i, fmt.base()));
		}
		else {
			s.append(Integer.toString(i, fmt.base()));
		}

		// Determine the character to use for padding.
		char padChar = ' ';

		if (opts.contains(NumberOptions.ZERO_PADDING)) {
			padChar = '0';
		}

		// Pad if needed to 32 characters.
		if (opts.contains(NumberOptions.LEFT_PADDING)) {
			int pads = 32 - s.length();

			while (pads-- > 0) {
				s.insert(0, padChar);
			}
		}
		else if (opts.contains(NumberOptions.RIGHT_PADDING)) {
			int pads = 32 - s.length();

			while (pads-- > 0) {
				s.append(padChar);
			}
		}

		return s.toString();
	}
}
