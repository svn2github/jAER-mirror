package net.sf.jaer.controllers;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.util.ArrayList;
import java.util.List;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.event.EventHandler;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import li.longi.libusb4java.Device;
import net.sf.jaer.Files;
import net.sf.jaer.GUISupport;

public class Controller {
	private static final List<String> firmwareValidExtensions = new ArrayList<>();
	static {
		firmwareValidExtensions.add("*.bix");
		firmwareValidExtensions.add("*.iic");
		firmwareValidExtensions.add("*.hex");
		firmwareValidExtensions.add("*.img");
	}

	private static final List<String> logicValidExtensions = new ArrayList<>();
	static {
		logicValidExtensions.add("*.jed");
	}

	private File firmwareFile;

	public Controller(Device dev) {

	}

	public VBox firmwareFlashGUI() {
		final VBox firmwareFlashGUI = new VBox(10);

		final HBox fileBox = new HBox(10);
		firmwareFlashGUI.getChildren().add(fileBox);

		GUISupport.addLabel(fileBox, "Select firmware file", "Select a compatible firmware file to upload to device.",
			null, null);

		final TextField fileField = GUISupport.addTextField(fileBox, null, null);

		fileField.textProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> val, final String oldVal, final String newVal) {
				if (newVal == null) {
					return;
				}

				// Check that the typed in file is valid, if not, color the
				// field background red.
				final File loadFirmware = new File(newVal);

				if (!Files.checkReadPermissions(loadFirmware)
					|| !Files.checkExtensions(loadFirmware, firmwareValidExtensions)) {
					fileField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				fileField.setStyle("");
				firmwareFile = loadFirmware;
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(fileBox, "Select file", true, null, new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				final File loadFirmware = GUISupport.showDialogLoadFile("Binary", firmwareValidExtensions);

				if (loadFirmware == null) {
					return;
				}

				fileField.setText(loadFirmware.getAbsolutePath());
				firmwareFile = loadFirmware;
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareFlashGUI, "Flash!", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (firmwareFile == null) {
						GUISupport.showDialogError("No file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(firmwareFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						// TODO: writeToMemory(0x00, buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final IOException e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		return (firmwareFlashGUI);
	}
}
