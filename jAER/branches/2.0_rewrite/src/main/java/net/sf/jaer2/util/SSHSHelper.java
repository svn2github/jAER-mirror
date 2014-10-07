package net.sf.jaer2.util;

public class SSHSHelper {
	// Return NULL on unknown type. Do not free returned strings!
	public static String typeToStringConverter(final Class<?> type) {
		// Convert the value and its type into a string for XML output.
		if (type == Boolean.class) {
			return ("bool");
		}
		else if (type == Byte.class) {
			return ("byte");
		}
		else if (type == Short.class) {
			return ("short");
		}
		else if (type == Integer.class) {
			return ("int");
		}
		else if (type == Long.class) {
			return ("long");
		}
		else if (type == Float.class) {
			return ("float");
		}
		else if (type == Double.class) {
			return ("double");
		}
		else if (type == String.class) {
			return ("string");
		}
		else {
			return null; // UNKNOWN TYPE.
		}
	}

	// Return -1 on unknown type.
	public static Class<?> stringToTypeConverter(final String typeString) {
		if (typeString == null) {
			return null; // NULL STRING.
		}

		// Convert the value string back into the internal type representation.
		switch (typeString) {
			case "bool":
				return Boolean.class;
			case "byte":
				return Byte.class;
			case "short":
				return Short.class;
			case "int":
				return Integer.class;
			case "long":
				return Long.class;
			case "float":
				return Float.class;
			case "double":
				return Double.class;
			case "string":
				return String.class;
			default:
				return null; // UNKNOWN TYPE.
		}
	}

	// Return NULL on failure (either memory allocation or unknown type / faulty
	// conversion).
	// Strings returned by this function need to be free()'d after use!
	public static String valueToStringConverter(final Class<?> type, final Object value) {
		// Convert the value and its type into a string for XML output.
		if (type == Boolean.class) {
			// Manually generate true or false.
			if ((Boolean) value) {
				return "true";
			}

			return "false";
		}
		else if ((type == Byte.class) || (type == Short.class) || (type == Integer.class) || (type == Long.class)) {
			return value.toString();
		}
		else if ((type == Float.class) || (type == Double.class)) {
			return String.format("%g", value);
		}
		else if (type == String.class) {
			return (String) value;
		}
		else {
			return null; // UNKNOWN TYPE.
		}
	}

	// Return false on failure (unknown type / faulty conversion), the content
	// of
	// value is undefined. For the STRING type, the returned value.string is a
	// copy
	// of the input string. Remember to free() it after use!
	public static <V> V stringToValueConverter(final Class<V> type, final String valueString) {
		if (valueString == null) {
			return null; // NULL STRING.
		}

		if (type == Boolean.class) {
			// Boolean uses custom true/false strings.
			if (valueString.equals("true")) {
				return type.cast(Boolean.TRUE);
			}

			return type.cast(Boolean.FALSE);
		}
		else if (type == Byte.class) {
			return type.cast(Byte.parseByte(valueString));
		}
		else if (type == Short.class) {
			return type.cast(Short.parseShort(valueString));
		}
		else if (type == Integer.class) {
			return type.cast(Integer.parseInt(valueString));
		}
		else if (type == Long.class) {
			return type.cast(Long.parseLong(valueString));
		}
		else if (type == Float.class) {
			return type.cast(Float.parseFloat(valueString));
		}
		else if (type == Double.class) {
			return type.cast(Double.parseDouble(valueString));
		}
		else if (type == String.class) {
			return type.cast(valueString);
		}
		else {
			return null; // UNKNOWN TYPE.
		}
	}
}
