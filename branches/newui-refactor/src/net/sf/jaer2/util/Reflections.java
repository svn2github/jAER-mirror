package net.sf.jaer2.util;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Modifier;
import java.util.Iterator;
import java.util.Set;

import net.sf.jaer2.chips.Chip;
import net.sf.jaer2.eventio.processors.EventProcessor;
import net.sf.jaer2.eventio.sinks.Sink;
import net.sf.jaer2.eventio.sources.Source;

import org.reflections.util.ClasspathHelper;
import org.reflections.util.ConfigurationBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Reflections {
	/** Local logger for log messages. */
	private static final Logger logger = LoggerFactory.getLogger(Reflections.class);

	private static final ConfigurationBuilder config = new ConfigurationBuilder();
	static {
		Reflections.config.addUrls(ClasspathHelper.forPackage("net.sf.jaer2"));
		Reflections.config.addUrls(ClasspathHelper.forPackage("ch.unizh.ini.jaer2"));
	}

	private static final org.reflections.Reflections reflections = new org.reflections.Reflections(Reflections.config);

	public static <T> Set<Class<? extends T>> getSubClasses(final Class<T> clazz) {
		final Set<Class<? extends T>> classes = Reflections.reflections.getSubTypesOf(clazz);

		for (final Iterator<Class<? extends T>> iter = classes.iterator(); iter.hasNext();) {
			// Only consider non-abstract sub-classes, that can be instantiated.
			if (Modifier.isAbstract(iter.next().getModifiers())) {
				iter.remove();
			}
		}

		return classes;
	}

	/** List of classes extending EventProcessor. */
	public static final Set<Class<? extends EventProcessor>> eventProcessorTypes = Reflections
		.getSubClasses(EventProcessor.class);

	/** List of classes extending Sink. */
	public static final Set<Class<? extends Source>> sourceTypes = Reflections.getSubClasses(Source.class);

	/** List of classes extending Chip. */
	public static final Set<Class<? extends Chip>> chipTypes = Reflections.getSubClasses(Chip.class);

	/** List of classes extending Sink. */
	public static final Set<Class<? extends Sink>> sinkTypes = Reflections.getSubClasses(Sink.class);

	public static <T> T newInstanceForClass(final Class<T> clazz) throws NoSuchMethodException, SecurityException,
		InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException,
		NullPointerException {
		Constructor<T> constr = null;

		constr = clazz.getConstructor();

		if (constr == null) {
			throw new NullPointerException("constructor is null");
		}

		T newClass = null;

		newClass = constr.newInstance();

		if (newClass == null) {
			throw new NullPointerException("newly created class is null");
		}

		return newClass;
	}

	public static <T, E> T newInstanceForClassWithArgument(final Class<T> clazz, final Class<E> argumentType,
		final E argumentValue) throws NoSuchMethodException, SecurityException, InstantiationException,
		IllegalAccessException, IllegalArgumentException, InvocationTargetException, NullPointerException {
		Constructor<T> constr = null;

		// Try to find a compatible constructor for the given concrete type.
		constr = clazz.getConstructor(argumentType);

		if (constr == null) {
			throw new NullPointerException("constructor is null");
		}

		T newClass = null;

		// Try to create a new instance of the given concrete type, using the
		// constructor found above.
		newClass = constr.newInstance(argumentValue);

		if (newClass == null) {
			throw new NullPointerException("newly created class is null");
		}

		return newClass;
	}

	/**
	 * DO NOT EVER USE THIS OUTSIDE OF A CONSTRUCTOR OR READRESOLVE() METHOD!
	 * SERIOUSLY, NEVER, EVER!
	 */
	public static <T> void setFinalField(final T instance, final String field, final Object value) {
		try {
			if ((instance == null) || (field == null) || (value == null)) {
				throw new NullPointerException();
			}

			final Field f = instance.getClass().getDeclaredField(field);
			f.setAccessible(true);
			f.set(instance, value);
		}
		catch (NullPointerException | NoSuchFieldException | SecurityException | IllegalArgumentException
			| IllegalAccessException e) {
			Reflections.logger.error("CRITICAL: Exception while setting final field!", e);
		}
	}
}
