/* Copyright Albert Cardona 2007 
 *
 * Telluride 2007
 *
 */
#include <Python.h>
#include <stdlib.h>
#include <math.h>


/* Gets a list of integers that represent an image, and scales them to max 128 in width and height, preserving aspect ratio.
 * Uses crude nearest point.
 */
PyObject* scaleImage(PyObject* self, PyObject* args) {
	PyObject* pix_ob;
	PyObject* width_ob;
	int width;
	int length;
	int height;
	int w, h;
	int length2;
	double sx;
	double sy;
	int i;
	PyObject* list;
	PyObject* pix_ob2;
	int x1, y1;
	width = (int) PyInt_AsLong(width_ob);
	height = length / width;
	length = PyList_GET_SIZE(pix_ob);
	if (!PyArg_ParseTuple(args, "O!O!",
				&PyList_Type, &pix_ob,
				&PyInt_Type, &width_ob)) {
		printf("\nscaleImage arguments are not proper.\n");
		Py_INCREF(Py_None);
		return Py_None;
	}
	if (width > 128) {
		w = 128;
		h = (int)((128.0 / width) * height);
		if (h > 128) {
			h = 128;
			w = (int)((128.0 / height) * 128);
		}
	} else if (height > 128) {
		h = 128;
		w = (int)((128.0 / height) * width);
	} else {
		// untouched
		return pix_ob;
	}
	//printf("New dimensions: %i , %i", w, h);
	// new array, using crude nearest-point
	length2 = w * h;
	pix_ob2 = PyList_New(length2);
	sx = ((double)w) / width;
	sy = ((double)h) / height;
	
	for (i=0; i<length2; i++) {
		x1 = (int)((i % w) / sx);
		y1 = (int)((i / w) / sy);
		PyList_SET_ITEM(pix_ob2, i, PyInt_FromLong(PyInt_AsLong(PyList_GET_ITEM(pix_ob, y1 * width + x1)))); // duplicating the number wrapper
		//PyList_SET_ITEM(pix_ob2, i, PyList_GET_ITEM(pix_ob, y1 * width + x1)); // SEG FAULT! without duplicating the number wrapper
	}
	list = PyList_New(2);
	PyList_SET_ITEM(list, 0, pix_ob2);
	PyList_SET_ITEM(list, 1, PyInt_FromLong(w));
	// return both the new image and the new width
	return list;
}

/* Takes to byte arrays and the width, and creates the events as x,y,log(pixdiff) 
 * Returns a list of integers, each with a packed event (will need to be casted to 16-bit before sending to the jAER)
 */
PyObject* createEvents(PyObject* self, PyObject* args) {
	int i;
	// obtain arguments
	PyObject* matrix_ob;
	PyObject* pix_ob;
	PyObject* width_ob;
	PyObject* threshold_ob;
	int width, length;
	int a, b;
	double val;
	double threshold;
		int* event;
		int count;
		PyObject* list;
	if (!PyArg_ParseTuple(args, "O!O!O!O!",
				&PyList_Type, &matrix_ob,
				&PyList_Type, &pix_ob,
				&PyInt_Type, &width_ob,
				&PyFloat_Type, &threshold_ob)) {
		printf("\ncreateEvents arguments are not proper.\n");
		Py_INCREF(Py_None);
		return Py_None;
	}
	// generate events from pixels that have changed
  length = PyList_GET_SIZE(pix_ob); // both matrix and pix have the same size
	width = (int) PyInt_AsLong(width_ob);
	//const int height = length / width;
	threshold = PyFloat_AsDouble(threshold_ob);
	event = malloc(sizeof(int) * length);
	count = 0;
	for (i=0; i<length; i++) {
		a = (int) PyInt_AsLong(PyList_GET_ITEM(matrix_ob, i));
		b = (int) PyInt_AsLong(PyList_GET_ITEM(pix_ob, i));
		/*if (i < 10) {
			printf("a, b: %i , %i\n", a , b);
		}*/
		if (a == b) continue;
		val = log(a) - log(b);
		// if any changes:
		if (fabs(val) > threshold) {
			// generate event: jAER event is a 16 bit, with first bit zero, 7 bits for y, 7 bits for x and final bit for positive/negative change. The code below will NOT work as expected if the X and Y 's meaningful part is larger than 7-bit
			event[count] =  /* X */ ((width - (i % width))<<1) /* X needs to be shifted */
				      + /* Y */ ((i / width)<<8)
				      + /* SIGN */ (val > 0 ? 1 : 0);
			//printf("width=%i x=%i y=%i val=%i\n", width, (i % width), (i / width), (val > 0 ? 1 : 0));
			count++;
			// update event matrix pixel values for those that have changed
			PyList_SET_ITEM(matrix_ob, i, PyInt_FromLong(b));
		}
	}
	// pack events in a list
	list = PyList_New(count);
	for (i=0; i<count; i++) {
		PyList_SET_ITEM(list, i, PyInt_FromLong(event[i]));
	}
	free(event);
	//if (0 != count) printf("Generated %i events\n", count);
	return list;
}

static char documentation[] = "Call method createEvents with two lists of equal length and the int width.";
static char createEvents__doc__[] = "Call with two lists of equal length and the int width.";
static char scaleImage__doc__[] = "Call with a list of int pixels and the int width; returns a list with the new image and the new width.";
static struct PyMethodDef methods[] = {
	{"createEvents", (PyCFunction)createEvents, 1, createEvents__doc__},
	{"scaleImage", (PyCFunction)scaleImage, 1, scaleImage__doc__},
	{NULL, NULL, 0, NULL}
};

PyMODINIT_FUNC
initEventGenerator(void)
{
	PyObject* m;
	m = Py_InitModule4("EventGenerator", methods, documentation, (PyObject*)NULL, PYTHON_API_VERSION);
	if (PyErr_Occurred()) {
		PyErr_Print();
		Py_FatalError("\nEventGenerator initEventGenerator: Can't initialize module EventGenerator");
	}
	printf("Module initialized correctly.");
}

