package net.sf.jaer;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

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
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.stage.WindowEvent;
import javafx.util.StringConverter;
import net.sf.jaer.controllers.Controller;
import net.sf.jaer.controllers.DAViS_FX2_SBL;
import net.sf.jaer.controllers.DAViS_FX3_SBL;
import net.sf.jaer.controllers.DeviceEraser;
import net.sf.jaer.controllers.FX2;
import net.sf.jaer.controllers.FX3;

import org.usb4java.BufferUtils;
import org.usb4java.Device;
import org.usb4java.DeviceDescriptor;
import org.usb4java.DeviceList;
import org.usb4java.LibUsb;

public final class Flashy extends Application {
	private static final Map<Short, Map<Short, Class<? extends Controller>>> supportedVidPids = new HashMap<>();
	static {
		// Add our own VID/PID combination (jAER Project/INI).
		final Map<Short, Class<? extends Controller>> iniPids = new HashMap<>();

		iniPids.put((short) 0x841A, DAViS_FX3_SBL.class); // DAVIS FX3
		iniPids.put((short) 0x841B, DAViS_FX2_SBL.class); // DAVIS FX2
		iniPids.put((short) 0x841C, DAViS_FX3_SBL.class); // Cochlea FX3

		// Support erasing of old devices.
		iniPids.put((short) 0x8400, DeviceEraser.class); // Old DVS128
		iniPids.put((short) 0x840D, DeviceEraser.class); // Old DAVIS FX2

		Flashy.supportedVidPids.put((short) 0x152A, iniPids);

		// Add the Cypress blank VID/PID combinations.
		final Map<Short, Class<? extends Controller>> cypressPids = new HashMap<>();

		cypressPids.put((short) 0x0053, FX3.class);
		cypressPids.put((short) 0x00F3, FX3.class);
		cypressPids.put((short) 0x8613, FX2.class);

		Flashy.supportedVidPids.put((short) 0x04B4, cypressPids);
	}

	private final Property<UsbDevice> selectedUsbDevice = new SimpleObjectProperty<>();
	private final VBox supplementalGUI = new VBox(10);

	public static void main(final String[] args) {
		// Launch the JavaFX application: do initialization and call start()
		// when ready.
		Application.launch(args);
	}

	private static void addToTab(final TabPane tabPane, final Pane content, final String name) {
		final ScrollPane p = new ScrollPane(content);

		p.setFitToWidth(true);
		p.setPrefHeight(Screen.getPrimary().getVisualBounds().getHeight());
		// TODO: is there a better way to maximize the ScrollPane content?

		final Tab t = new Tab(name);

		t.setContent(p);
		t.setClosable(false);

		tabPane.getTabs().add(t);
	}

	@Override
	public void start(final Stage primaryStage) {
		// Check minimum Java version requirement.
		final String javaVersionStr = System.getProperty("java.version");

		final String[] javaVersionComponentsStr = javaVersionStr.split("\\.|_", 4);

		final int[] javaVersionComponents = new int[javaVersionComponentsStr.length];
		int i = 0;
		for (final String component : javaVersionComponentsStr) {
			javaVersionComponents[i++] = Integer.parseInt(component);
		}

		// Check at least Java 1.8.0 Update 40.
		if ((javaVersionComponents[0] < 1) || (javaVersionComponents[1] < 8)
			|| ((javaVersionComponents.length == 4) && (javaVersionComponents[3] < 40))) {
			final VBox text = new VBox(20);
			GUISupport
				.addLabel(
					text,
					"Flashy requires at least Java 1.8 Update 40 to run. Please update your JRE/JDK to the latest Java 1.8 release.",
					null, null, null);

			final BorderPane main = new BorderPane();
			main.setCenter(text);

			final Scene rootScene = new Scene(main, 640, 240, Color.GRAY);

			primaryStage.setTitle("Firmware Flash Utility - Error");
			primaryStage.setScene(rootScene);

			primaryStage.show();

			return;
		}

		final VBox gui = new VBox(20);

		gui.getChildren().add(usbDeviceSelectGUI());

		final TabPane tabLayout = new TabPane();
		gui.getChildren().add(tabLayout);

		Flashy.addToTab(tabLayout, usbInfoGUI(), "Info");

		Flashy.addToTab(tabLayout, usbCommandGUI(), "Vendor Requests");

		Flashy.addToTab(tabLayout, supplementalGUI, "Device Specific");

		final BorderPane main = new BorderPane();
		main.setCenter(gui);

		final Rectangle2D screen = Screen.getPrimary().getVisualBounds();
		final Scene rootScene = new Scene(main, screen.getWidth(), screen.getHeight(), Color.GRAY);

		primaryStage.setTitle("Firmware Flash Utility");
		primaryStage.setScene(rootScene);

		primaryStage.setOnCloseRequest(new EventHandler<WindowEvent>() {
			@Override
			public void handle(@SuppressWarnings("unused") final WindowEvent evt) {
				if (selectedUsbDevice.getValue() != null) {
					selectedUsbDevice.getValue().close();
				}
			}
		});

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
					final Map<Short, Class<? extends Controller>> pids = Flashy.supportedVidPids
						.get(devDesc.idVendor());

					if (pids.containsKey(devDesc.idProduct())) {
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
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends UsbDevice> change, final UsbDevice oldVal,
				final UsbDevice newVal) {
				if (oldVal != null) {
					oldVal.close();
					supplementalGUI.getChildren().clear();
				}

				if (newVal != null) {
					try {
						newVal.open();
					}
					catch (final Exception e) {
						// Signal that this device can't be opened to user.
						GUISupport
							.showDialogError("Impossible to open this device.\n"
								+ "This is usally caused by the device not having the WinUSB driver properly installed on Windows or by permission problems on Linux.\n"
								+ "Please check the documentation on how to resolve this.");
						return;
					}

					final Map<Short, Class<? extends Controller>> pids = Flashy.supportedVidPids.get(newVal.getDevVID());

					if (pids.get(newVal.getDevPID()) != null) {
						final Controller newController = Controller.newInstanceForClassWithArgument(
							pids.get(newVal.getDevPID()), UsbDevice.class, newVal);

						final VBox controllerGUI = newController.generateGUI();
						if (controllerGUI != null) {
							supplementalGUI.getChildren().add(controllerGUI);
						}
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
			public UsbDevice fromString(@SuppressWarnings("unused") final String str) {
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

		// Select vendor request direction.
		final List<String> inOut = new ArrayList<>();
		inOut.add("IN");
		inOut.add("OUT");
		final ComboBox<String> directionBox = GUISupport.addComboBox(usbCommandGUI, inOut, 1);

		// Vendor request byte.
		GUISupport.addLabel(usbCommandGUI, "Vendor Request:", "Insert a value for the byte Vendor Request field.",
			null, null);
		final TextField vendorRequestField = GUISupport.addTextField(usbCommandGUI, "00", null);

		// Value short.
		GUISupport.addLabel(usbCommandGUI, "Value:", "Insert a value for the short Value field.", null, null);
		final TextField valueField = GUISupport.addTextField(usbCommandGUI, "0000", null);

		// Index short.
		GUISupport.addLabel(usbCommandGUI, "Index:", "Insert a value for the short Index field.", null, null);
		final TextField indexField = GUISupport.addTextField(usbCommandGUI, "0000", null);

		// Bytes of data to receive.
		GUISupport.addLabel(usbCommandGUI, "Data Length:", "Insert the amount of bytes you want to get back.", null,
			null);
		final TextField dataLengthField = GUISupport.addTextField(usbCommandGUI, "1", null);

		// Bytes of data to send.
		GUISupport.addLabel(usbCommandGUI, "Enter the bytes you want to send out:",
			"Enter the bytes to send to the device,  in hexadecimal form,  separated by a space.", null, null);
		final TextArea bytesToSendTextArea = new TextArea();
		usbCommandGUI.getChildren().add(bytesToSendTextArea);

		// Hide one or the other depending on direction.
		dataLengthField.setDisable(true);
		bytesToSendTextArea.setDisable(false);

		directionBox.valueProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> change, final String oldVal, final String newVal) {
				if (newVal.compareTo("IN") == 0) {
					dataLengthField.setDisable(false);
					bytesToSendTextArea.setDisable(true);
				}
				else {
					dataLengthField.setDisable(true);
					bytesToSendTextArea.setDisable(false);
				}
			}
		});

		// Display result.
		final Label resultLabel = GUISupport.addLabel(usbCommandGUI, "No results.",
			"Show results from Vendor Request.", null, null);

		// Send button.
		GUISupport.addButtonWithMouseClickedHandler(usbCommandGUI, "Send Request", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent evt) {
					if (selectedUsbDevice.getValue() == null) {
						GUISupport.showDialogError("You must select a device first!");
						return;
					}

					if (directionBox.getValue().compareTo("IN") == 0) {
						try (Scanner vendorRequestScanner = new Scanner(vendorRequestField.getText());
							Scanner valueScanner = new Scanner(valueField.getText());
							Scanner indexScanner = new Scanner(indexField.getText())) {
							final byte vendorRequest = (byte) vendorRequestScanner.nextShort(16);
							final short value = (short) valueScanner.nextInt(16);
							final short index = (short) indexScanner.nextInt(16);

							try {
								final ByteBuffer dataBuffer = selectedUsbDevice.getValue().sendVendorRequestIN(
									vendorRequest, value, index, Integer.parseInt(dataLengthField.getText()));

								final StringBuilder res = new StringBuilder();

								for (int i = 0; i < dataBuffer.limit(); i++) {
									if ((i % 64) == 0) {
										res.append("\n");
									}
									res.append(String.format("%02X ", dataBuffer.get() & 0xFF));
								}

								resultLabel.setText(res.toString());
							}
							catch (final Exception e) {
								GUISupport.showDialogException(e);
								return;
							}
						}
					}
					else {
						try (Scanner vendorRequestScanner = new Scanner(vendorRequestField.getText());
							Scanner valueScanner = new Scanner(valueField.getText());
							Scanner indexScanner = new Scanner(indexField.getText());
							Scanner bytesScan = new Scanner(bytesToSendTextArea.getText())) {
							final byte vendorRequest = (byte) vendorRequestScanner.nextShort(16);
							final short value = (short) valueScanner.nextInt(16);
							final short index = (short) indexScanner.nextInt(16);

							bytesScan.useDelimiter(" ");
							bytesScan.useRadix(16);

							// Get bytes from text area.
							final byte[] buf = new byte[bytesToSendTextArea.getText().length()];

							int counter = 0;
							while (bytesScan.hasNextShort()) {
								buf[counter] = (byte) (bytesScan.nextShort() & 0xFF);
								counter++;
							}

							final ByteBuffer dataBuffer = BufferUtils.allocateByteBuffer(counter);
							dataBuffer.put(buf, 0, counter);

							try {
								selectedUsbDevice.getValue().sendVendorRequest(vendorRequest, value, index, dataBuffer);
							}
							catch (final Exception e) {
								GUISupport.showDialogException(e);
								return;
							}
						}
					}
				}
			});

		return (usbCommandGUI);
	}
}
