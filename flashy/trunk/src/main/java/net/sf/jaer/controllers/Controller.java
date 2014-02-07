package net.sf.jaer.controllers;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import javafx.scene.layout.VBox;
import net.sf.jaer.UsbDevice;

public abstract class Controller {
	protected UsbDevice usbDevice;

	public Controller(final UsbDevice device) {
		usbDevice = device;
	}

	public abstract VBox generateGUI();

	public static <T, E> T newInstanceForClassWithArgument(final Class<T> clazz, final Class<E> argumentType,
		final E argumentValue) {
		Constructor<T> constr = null;

		// Try to find a compatible constructor for the given concrete type.
		try {
			constr = clazz.getConstructor(argumentType);
		}
		catch (NoSuchMethodException | SecurityException e) {
			return null;
		}

		if (constr == null) {
			throw new NullPointerException("constructor is null");
		}

		T newClass = null;

		// Try to create a new instance of the given concrete type, using the
		// constructor found above.
		try {
			newClass = constr.newInstance(argumentValue);
		}
		catch (InstantiationException | IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
			return null;
		}

		if (newClass == null) {
			throw new NullPointerException("new instance is null");
		}

		return newClass;
	}
}
