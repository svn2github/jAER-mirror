package net.sf.jaer2.util;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.Comparator;
import java.util.Iterator;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;

import net.sf.jaer2.eventio.processors.EventProcessor;
import net.sf.jaer2.eventio.sinks.Sink;
import net.sf.jaer2.eventio.sources.Source;
import net.sf.jaer2.eventio.translators.Translator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Reflections {
	/** Local logger for log messages. */
	private static final Logger logger = LoggerFactory.getLogger(Reflections.class);

	private static final org.reflections.Reflections reflections = new org.reflections.Reflections("");

	public static <T> SortedSet<Class<? extends T>> getSubClasses(final Class<T> clazz) {
		final Set<Class<? extends T>> classes = Reflections.reflections.getSubTypesOf(clazz);

		for (final Iterator<Class<? extends T>> iter = classes.iterator(); iter.hasNext();) {
			// Only consider non-abstract sub-classes, that can be instantiated.
			if (Modifier.isAbstract(iter.next().getModifiers())) {
				iter.remove();
			}
		}

		// Return a sorted set, to give predictable order.
		final SortedSet<Class<? extends T>> sortedClasses = new TreeSet<>(new ClassComparator<>());

		sortedClasses.addAll(classes);

		return sortedClasses;
	}

	private static final class ClassComparator<T> implements Comparator<Class<? extends T>> {
		@Override
		public int compare(final Class<? extends T> cl1, final Class<? extends T> cl2) {
			return cl1.getCanonicalName().compareTo(cl2.getCanonicalName());
		}
	}

	/** List of classes extending EventProcessor. */
	public static final SortedSet<Class<? extends EventProcessor>> eventProcessorTypes = Reflections
		.getSubClasses(EventProcessor.class);

	/** List of classes extending Source. */
	public static final SortedSet<Class<? extends Source>> sourceTypes = Reflections.getSubClasses(Source.class);

	/** List of classes extending Translator. */
	public static final SortedSet<Class<? extends Translator>> translatorTypes = Reflections
		.getSubClasses(Translator.class);

	/** List of classes extending Sink. */
	public static final SortedSet<Class<? extends Sink>> sinkTypes = Reflections.getSubClasses(Sink.class);

	public static <T> T newInstanceForClass(final Class<T> clazz) {
		Constructor<T> constr = null;

		try {
			constr = clazz.getConstructor();
		}
		catch (NoSuchMethodException | SecurityException e) {
			Reflections.logger.error("Exception while getting constructor.", e);
			return null;
		}

		if (constr == null) {
			throw new NullPointerException("constructor is null");
		}

		T newClass = null;

		try {
			newClass = constr.newInstance();
		}
		catch (InstantiationException | IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
			Reflections.logger.error("Exception while creating new instance.", e);
			return null;
		}

		if (newClass == null) {
			throw new NullPointerException("new instance is null");
		}

		return newClass;
	}

	public static <T, E> T newInstanceForClassWithArgument(final Class<T> clazz, final Class<E> argumentType,
		final E argumentValue) {
		Constructor<T> constr = null;

		// Try to find a compatible constructor for the given concrete type.
		try {
			constr = clazz.getConstructor(argumentType);
		}
		catch (NoSuchMethodException | SecurityException e) {
			Reflections.logger.error("Exception while getting constructor.", e);
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
			Reflections.logger.error("Exception while creating new instance.", e);
			return null;
		}

		if (newClass == null) {
			throw new NullPointerException("new instance is null");
		}

		return newClass;
	}

	public static <T, R> R callStaticMethodForClass(final Class<T> clazz, final String methodName,
		final Class<R> returnType) {
		Method m = null;

		try {
			m = clazz.getMethod(methodName);
		}
		catch (NoSuchMethodException | SecurityException e) {
			Reflections.logger.error("Exception while getting method.", e);
			return null;
		}

		if (m == null) {
			throw new NullPointerException("method is null");
		}

		R result = null;

		try {
			result = returnType.cast(m.invoke(null));
		}
		catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
			Reflections.logger.error("Exception while calling method.", e);
			return null;
		}

		return result;
	}

	public static <T, R, E> R callStaticMethodForClassWithArgument(final Class<T> clazz, final String methodName,
		final Class<R> returnType, final Class<E> argumentType, final E argumentValue) {
		Method m = null;

		try {
			m = clazz.getMethod(methodName, argumentType);
		}
		catch (NoSuchMethodException | SecurityException e) {
			Reflections.logger.error("Exception while getting method.", e);
			return null;
		}

		if (m == null) {
			throw new NullPointerException("method is null");
		}

		R result = null;

		try {
			result = returnType.cast(m.invoke(null, argumentValue));
		}
		catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
			Reflections.logger.error("Exception while calling method.", e);
			return null;
		}

		return result;
	}

	/**
	 * DO NOT EVER USE THIS OUTSIDE OF A CONSTRUCTOR OR READRESOLVE() METHOD!
	 * SERIOUSLY, NEVER, EVER!
	 */
	public static <T> void setFinalField(final T instance, final String field, final Object value) {
		if ((instance == null) || (field == null)) {
			throw new NullPointerException();
		}

		Reflections.logger.debug("Searching for field {} in instance {} of type {}.", field, instance,
			instance.getClass());

		try {
			final Field f = Reflections.getSuperField(instance.getClass(), field);
			f.setAccessible(true);
			f.set(instance, value);
		}
		catch (NoSuchFieldException | SecurityException | IllegalArgumentException | IllegalAccessException e) {
			Reflections.logger.error("Exception while setting final field.", e);
		}
	}

	private static <T> Field getSuperField(final Class<T> clazz, final String field) throws NoSuchFieldException {
		try {
			return clazz.getDeclaredField(field);
		}
		catch (final NoSuchFieldException e) {
			final Class<? super T> superClass = clazz.getSuperclass();

			if (superClass == null) {
				throw e;
			}

			return Reflections.getSuperField(superClass, field);
		}
	}
}
