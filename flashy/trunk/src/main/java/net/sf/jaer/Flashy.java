package net.sf.jaer;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javafx.application.Application;
import javafx.beans.property.Property;
import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.event.EventHandler;
import javafx.geometry.Rectangle2D;
import javafx.scene.Scene;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.util.StringConverter;
import li.longi.libusb4java.Device;
import li.longi.libusb4java.DeviceDescriptor;
import li.longi.libusb4java.DeviceList;
import li.longi.libusb4java.LibUsb;

public final class Flashy extends Application {
	private static final Map<Short, List<Short>> supportedVidPids = new HashMap<>();
	static {
		// Add our own VID/PID combination (jAER Project/INI).
		final List<Short> iniPids = new ArrayList<>();
		for (int pid = 0x8400; pid <= 0x841F; pid++) {
			iniPids.add((short) pid);
		}

		Flashy.supportedVidPids.put((short) 0x152A, iniPids);
	}

	private static final List<String> firmwareValidExtensions = new ArrayList<>();
	static {
		Flashy.firmwareValidExtensions.add("*.bix");
		Flashy.firmwareValidExtensions.add("*.iic");
		Flashy.firmwareValidExtensions.add("*.hex");
		Flashy.firmwareValidExtensions.add("*.img");
	}

	private static final List<String> logicValidExtensions = new ArrayList<>();
	static {
		Flashy.logicValidExtensions.add("*.jed");
	}

	private File firmwareFile;
	private File logicFile;
	private final Property<UsbDevice> selectedUsbDevice = new SimpleObjectProperty<>();

	public static void main(final String[] args) {
		// Launch the JavaFX application: do initialization and call start()
		// when ready.
		Application.launch(args);
	}

	@Override
	public void start(final Stage primaryStage) {
		final VBox gui = new VBox(20);

		gui.getChildren().add(usbDeviceSelectGUI());
		gui.getChildren().add(usbInfoGUI());
		gui.getChildren().add(usbCommandGUI());
		gui.getChildren().add(firmwareFlashGUI());
		gui.getChildren().add(logicFlashGUI());

		final BorderPane main = new BorderPane();
		main.setCenter(gui);

		final Rectangle2D screen = Screen.getPrimary().getVisualBounds();
		final Scene rootScene = new Scene(main, screen.getWidth(), screen.getHeight(), Color.GRAY);

		primaryStage.setTitle("Firmware Flash Utility");
		primaryStage.setScene(rootScene);

		primaryStage.show();
	}

	private VBox usbDeviceSelectGUI() {
		final VBox usbDeviceSelectGUI = new VBox(10);

		// Get a list of all compatible USB devices.
		final List<UsbDevice> usbDevices = new ArrayList<>();

		LibUsb.init(null);

		final DeviceList list = new DeviceList();
		if (LibUsb.getDeviceList(null, list) > 0) {
			final Iterator<Device> devices = list.iterator();
			while (devices.hasNext()) {
				final Device dev = devices.next();

				final DeviceDescriptor devDesc = new DeviceDescriptor();
				LibUsb.getDeviceDescriptor(dev, devDesc);

				if (Flashy.supportedVidPids.containsKey(devDesc.idVendor())) {
					final List<Short> pids = Flashy.supportedVidPids.get(devDesc.idVendor());

					if (pids.contains(devDesc.idProduct())) {
						usbDevices.add(new UsbDevice(dev));
					}
				}
			}

			LibUsb.freeDeviceList(list, true);
		}

		GUISupport.addLabel(usbDeviceSelectGUI, "Select a device:", "Select a device on which to operate.", null, null);

		final ComboBox<UsbDevice> usbDevicesBox = GUISupport.addComboBox(usbDeviceSelectGUI, usbDevices, -1);

		usbDevicesBox.valueProperty().bindBidirectional(selectedUsbDevice);

		// Open the device when its selected.
		usbDevicesBox.valueProperty().addListener(new ChangeListener<UsbDevice>() {
			@Override
			public void changed(final ObservableValue<? extends UsbDevice> change, final UsbDevice oldVal, final UsbDevice newVal) {
				if (oldVal != null) {
					oldVal.close();
				}

				if (newVal != null) {
					try {
						newVal.open();
					}
					catch (final Exception e) {
						// Remove unopenable devices from list.
						usbDevicesBox.getItems().remove(newVal);
					}
				}
			}
		});

		return (usbDeviceSelectGUI);
	}

	private VBox usbInfoGUI() {
		final VBox usbInfoGUI = new VBox(10);

		final Label usbText = GUISupport.addLabel(usbInfoGUI, "", "USB device information.", null, null);

		usbText.textProperty().bindBidirectional(selectedUsbDevice, new StringConverter<UsbDevice>() {
			@Override
			public UsbDevice fromString(final String str) {
				return null;
			}

			@Override
			public String toString(final UsbDevice usb) {
				if (usb == null) {
					return ("No device selected.");
				}

				return (usb.fullDescription());
			}
		});

		return (usbInfoGUI);
	}

	private VBox usbCommandGUI() {
		final VBox usbCommandGUI = new VBox(10);

		return (usbCommandGUI);
	}

	private VBox firmwareFlashGUI() {
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
					|| !Files.checkExtensions(loadFirmware, Flashy.firmwareValidExtensions)) {
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
				final File loadFirmware = GUISupport.showDialogLoadFile("Binary", Flashy.firmwareValidExtensions);

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

	private VBox logicFlashGUI() {
		final VBox logicFlashGUI = new VBox(10);

		final HBox fileBox = new HBox(10);
		logicFlashGUI.getChildren().add(fileBox);

		GUISupport.addLabel(fileBox, "Select logic file", "Select a compatible logic file to upload to device.", null,
			null);

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
				final File loadLogic = new File(newVal);

				if (!Files.checkReadPermissions(loadLogic)
					|| !Files.checkExtensions(loadLogic, Flashy.firmwareValidExtensions)) {
					fileField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				fileField.setStyle("");
				logicFile = loadLogic;
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(fileBox, "Select file", true, null, new EventHandler<MouseEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
				final File loadLogic = GUISupport.showDialogLoadFile("Binary", Flashy.firmwareValidExtensions);

				if (loadLogic == null) {
					return;
				}

				fileField.setText(loadLogic.getAbsolutePath());
				logicFile = loadLogic;
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(logicFlashGUI, "Flash!", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (logicFile == null) {
						GUISupport.showDialogError("No file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
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

		return (logicFlashGUI);
	}
}
