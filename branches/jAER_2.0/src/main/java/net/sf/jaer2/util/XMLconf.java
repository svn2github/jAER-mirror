package net.sf.jaer2.util;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import com.google.common.collect.ImmutableList;
import com.thoughtworks.xstream.XStream;

public final class XMLconf {
	public static <T> void toXML(final T object, final List<PairRO<Class<?>, String>> fieldsToOmit) {
		final File toSave = GUISupport.showDialogSaveFile(ImmutableList.of(PairRO.of("XML", "*.xml")));

		if (toSave == null) {
			// Error in opening file, check dialog message for what went wrong.
			return;
		}

		XMLconf.toXML(object, fieldsToOmit, toSave);
	}

	public static <T> void toXML(final T object, final List<PairRO<Class<?>, String>> fieldsToOmit, final File xmlFile) {
		if (!GUISupport.checkWritePermissions(xmlFile)) {
			// Error in opening file.
			return;
		}

		// Create any necessary directories in the path.s
		xmlFile.getParentFile().mkdirs();

		try (FileWriter out = new FileWriter(xmlFile)) {
			final XStream xstream = new XStream();
			xstream.setMode(XStream.ID_REFERENCES);

			if (fieldsToOmit != null) {
				for (final PairRO<Class<?>, String> field : fieldsToOmit) {
					xstream.omitField(field.getFirst(), field.getSecond());
				}
			}

			xstream.toXML(object, out);
		}
		catch (final IOException e) {
			GUISupport.showDialogException(e);
		}
	}

	public static <T> T fromXML(final Class<T> clazz) {
		final File toLoad = GUISupport.showDialogLoadFile(ImmutableList.of(PairRO.of("XML", "*.xml")));

		if (toLoad == null) {
			// Error in opening file, check dialog message for what went wrong.
			return null;
		}

		return XMLconf.fromXML(clazz, toLoad);
	}

	public static <T> T fromXML(final Class<T> clazz, final File xmlFile) {
		if (!GUISupport.checkReadPermissions(xmlFile)) {
			// Error in opening file.
			return null;
		}

		final XStream xstream = new XStream();
		xstream.setMode(XStream.ID_REFERENCES);

		return clazz.cast(xstream.fromXML(xmlFile));
	}
}
