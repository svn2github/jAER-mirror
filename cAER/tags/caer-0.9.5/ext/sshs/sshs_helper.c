#include "sshs_internal.h"

static void sshsHelperAllocSprintf(char **strp, const char *format, ...) __attribute__ ((format (printf, 2, 3)));

// Put NULL in *strp on failure (memory allocation failure).
static void sshsHelperAllocSprintf(char **strp, const char *format, ...) {
	va_list argptr;

	va_start(argptr, format);
	size_t printLength = (size_t) vsnprintf(NULL, 0, format, argptr);
	va_end(argptr);

	*strp = malloc(printLength + 1);
	if (*strp == NULL) {
		return;
	}

	va_start(argptr, format);
	vsnprintf(*strp, printLength + 1, format, argptr);
	va_end(argptr);
}

// Return NULL on unknown type. Do not free returned strings!
const char *sshsHelperTypeToStringConverter(enum sshs_node_attr_value_type type) {
	// Convert the value and its type into a string for XML output.
	switch (type) {
		case BOOL:
			return ("bool");

		case BYTE:
			return ("byte");

		case SHORT:
			return ("short");

		case INT:
			return ("int");

		case LONG:
			return ("long");

		case FLOAT:
			return ("float");

		case DOUBLE:
			return ("double");

		case STRING:
			return ("string");

		default:
			return (NULL); // UNKNOWN TYPE.
	}
}

// Return -1 on unknown type.
enum sshs_node_attr_value_type sshsHelperStringToTypeConverter(const char *typeString) {
	if (typeString == NULL) {
		return (-1); // NULL STRING.
	}

	// Convert the value string back into the internal type representation.
	if (strcmp(typeString, "bool") == 0) {
		return (BOOL);
	}
	else if (strcmp(typeString, "byte") == 0) {
		return (BYTE);
	}
	else if (strcmp(typeString, "short") == 0) {
		return (SHORT);
	}
	else if (strcmp(typeString, "int") == 0) {
		return (INT);
	}
	else if (strcmp(typeString, "long") == 0) {
		return (LONG);
	}
	else if (strcmp(typeString, "float") == 0) {
		return (FLOAT);
	}
	else if (strcmp(typeString, "double") == 0) {
		return (DOUBLE);
	}
	else if (strcmp(typeString, "string") == 0) {
		return (STRING);
	}

	return (-1); // UNKNOWN TYPE.
}

// Return NULL on failure (either memory allocation or unknown type / faulty conversion).
// Strings returned by this function need to be free()'d after use!
char *sshsHelperValueToStringConverter(enum sshs_node_attr_value_type type, union sshs_node_attr_value value) {
	// Convert the value and its type into a string for XML output.
	char *valueString;

	switch (type) {
		case BOOL:
			// Manually generate true or false.
			if (value.boolean) {
				valueString = strdup("true");
			}
			else {
				valueString = strdup("false");
			}

			break;

		case BYTE:
			sshsHelperAllocSprintf(&valueString, "%" PRIu8, value.ubyte);
			break;

		case SHORT:
			sshsHelperAllocSprintf(&valueString, "%" PRIu16, value.ushort);
			break;

		case INT:
			sshsHelperAllocSprintf(&valueString, "%" PRIu32, value.uint);
			break;

		case LONG:
			sshsHelperAllocSprintf(&valueString, "%" PRIu64, value.ulong);
			break;

		case FLOAT:
			sshsHelperAllocSprintf(&valueString, "%g", value.ffloat);
			break;

		case DOUBLE:
			sshsHelperAllocSprintf(&valueString, "%lg", value.ddouble);
			break;

		case STRING:
			valueString = strdup(value.string);
			break;

		default:
			valueString = NULL; // UNKNOWN TYPE.
			break;
	}

	return (valueString);
}

// Return false on failure (unknown type / faulty conversion), the content of
// value is undefined. For the STRING type, the returned value.string is a copy
// of the input string. Remember to free() it after use!
bool sshsHelperStringToValueConverter(enum sshs_node_attr_value_type type, const char *valueString,
	union sshs_node_attr_value *value) {
	if (valueString == NULL || value == NULL) {
		return (false); // NULL STRING.
	}

	switch (type) {
		case BOOL:
			// Boolean uses custom true/false strings.
			if (strcmp(valueString, "true") == 0) {
				value->boolean = true;
			}
			else {
				value->boolean = false;
			}

			break;

		case BYTE:
			if (sscanf(valueString, "%" SCNu8, &value->ubyte) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case SHORT:
			if (sscanf(valueString, "%" SCNu16, &value->ushort) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case INT:
			if (sscanf(valueString, "%" SCNu32, &value->uint) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case LONG:
			if (sscanf(valueString, "%" SCNu64, &value->ulong) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case FLOAT:
			if (sscanf(valueString, "%g", &value->ffloat) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case DOUBLE:
			if (sscanf(valueString, "%lg", &value->ddouble) != 1) {
				return (false); // CONVERSION FAILURE.
			}

			break;

		case STRING:
			value->string = strdup(valueString);
			if (value->string == NULL) {
				return (false); // MALLOC FAILURE.
			}

			break;

		default:
			return (false); // UNKNOWN TYPE.
	}

	return (true);
}