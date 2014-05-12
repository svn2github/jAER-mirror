package net.sf.jaer.controllers;

import java.io.File;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.ShortBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.prefs.Preferences;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Task;
import javafx.event.EventHandler;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import li.longi.USBTransferThread.RestrictedTransfer;
import li.longi.USBTransferThread.RestrictedTransferCallback;
import net.sf.jaer.Files;
import net.sf.jaer.GUISupport;
import net.sf.jaer.UsbDevice;

import org.usb4java.BufferUtils;
import org.usb4java.LibUsb;

public class DAViS_FX3 extends Controller {
	private static final List<String> firmwareValidExtensions = new ArrayList<>();
	static {
		DAViS_FX3.firmwareValidExtensions.add("*.img");
	}

	private static final List<String> logicValidExtensions = new ArrayList<>();
	static {
		DAViS_FX3.logicValidExtensions.add("*.bit");
	}

	public DAViS_FX3(final UsbDevice device) {
		super(device);
	}

	private File firmwareFile;
	private File logicFile;

	@Override
	public VBox generateGUI() {
		final VBox fx3GUI = new VBox(10);

		final HBox firmwareToFlashBox = new HBox(10);
		fx3GUI.getChildren().add(firmwareToFlashBox);

		GUISupport.addLabel(firmwareToFlashBox, "Select FX3 firmware file",
			"Select a FX3 firmware file to upload to the device.", null, null);

		final Preferences defaultFolderNode = Preferences.userRoot().node("/defaultFolders");

		// Load default path, if exists.
		String savedPath = defaultFolderNode.get("fx3Firmware", "");
		if (!savedPath.isEmpty()) {
			File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				firmwareFile = savedFile;
			}
		}

		final TextField firmwareField = GUISupport.addTextField(firmwareToFlashBox,
			defaultFolderNode.get("fx3Firmware", ""), null);

		firmwareField.textProperty().addListener(new ChangeListener<String>() {
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
					|| !Files.checkExtensions(loadFirmware, DAViS_FX3.firmwareValidExtensions)) {
					firmwareField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				firmwareField.setStyle("");
				firmwareFile = loadFirmware;
				defaultFolderNode.put("fx3Firmware", loadFirmware.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile("FX3 Image",
						DAViS_FX3.firmwareValidExtensions, defaultFolderNode.get("fx3Firmware", ""));

					if (loadFirmware == null) {
						return;
					}

					firmwareField.setText(loadFirmware.getAbsolutePath());
					firmwareFile = loadFirmware;
					defaultFolderNode.put("fx3Firmware", loadFirmware.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Flash FX3 firmware", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (firmwareFile == null) {
						GUISupport.showDialogError("No FX3 firmware file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(firmwareFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						firmwareToROM(buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Erase Flash", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					try {
						eraseROM();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		final HBox logicToFlashBox = new HBox(10);
		fx3GUI.getChildren().add(logicToFlashBox);

		GUISupport.addLabel(logicToFlashBox, "Select FPGA logic file",
			"Select a FPGA logic file to upload to the device.", null, null);

		// Load default path, if exists.
		savedPath = defaultFolderNode.get("fx3Logic", "");
		if (!savedPath.isEmpty()) {
			File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				logicFile = savedFile;
			}
		}

		final TextField logicField = GUISupport.addTextField(logicToFlashBox, defaultFolderNode.get("fx3Logic", ""),
			null);

		logicField.textProperty().addListener(new ChangeListener<String>() {
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
					|| !Files.checkExtensions(loadLogic, DAViS_FX3.logicValidExtensions)) {
					logicField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				logicField.setStyle("");
				logicFile = loadLogic;
				defaultFolderNode.put("fx3Logic", loadLogic.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadLogic = GUISupport.showDialogLoadFile("Bitstream", DAViS_FX3.logicValidExtensions,
						defaultFolderNode.get("fx3Logic", ""));

					if (loadLogic == null) {
						return;
					}

					logicField.setText(loadLogic.getAbsolutePath());
					logicFile = loadLogic;
					defaultFolderNode.put("fx3Logic", loadLogic.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Flash FPGA bitstream", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (logicFile == null) {
						GUISupport.showDialogError("No FPGA bitstream file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						logicToROM(buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Upload FPGA bitstream", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (logicFile == null) {
						GUISupport.showDialogError("No FPGA bitstream file selected!");
						return;
					}

					final Task<Integer> worker = new Task<Integer>() {
						@Override
						protected Integer call() throws Exception {
							try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
								final FileChannel fwInChannel = fwFile.getChannel()) {
								final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
								buf.load();

								updateProgress(10, 100);

								// Load file to RAM.
								logicToRAM(buf);

								updateProgress(95, 100);

								// Cleanup ByteBuffer.
								buf.clear();

								updateProgress(100, 100);
							}

							return 0;
						}
					};

					GUISupport.showDialogProgress(worker);

					final Thread t = new Thread(worker);
					t.start();
				}
			});

		fx3GUI.getChildren().add(usbEPListenGUI());

		return (fx3GUI);
	}

	private static final int MAX_TRANSFER_SIZE = 4096;
	private static final int FIRMWARE_START_ADDRESS = 0x000000;
	private static final int FIRMWARE_MAX_SIZE = 0x030000;
	private static final int LOGIC_START_ADDRESS = 0x030000;
	private static final int LOGIC_MAX_SIZE = 0x090000;

	// private static final int DATA_START_ADDRESS = 0x0C0000;
	// private static final int DATA_MAX_SIZE = 0x040000;

	private void firmwareToROM(final ByteBuffer fw) throws Exception {
		// Check signature.
		if ((fw.get(0) != 'C') || (fw.get(1) != 'Y')) {
			throw new Exception("Illegal signature for firmware file.");
		}

		// Make a copy so we can manipulate it.
		final ByteBuffer data = BufferUtils.allocateByteBuffer(fw.limit());
		data.order(ByteOrder.LITTLE_ENDIAN);

		data.put(fw);
		data.position(0); // Reset position to initial value.

		// Set third byte to 0x20, to enable 30 MHz SPI boot transfer rate.
		data.put(2, (byte) 0x20);

		// Write FX3 firmware.
		byteBufferToROM(data, DAViS_FX3.FIRMWARE_START_ADDRESS, DAViS_FX3.FIRMWARE_MAX_SIZE);
	}

	private void logicToROM(final ByteBuffer logic) throws Exception {
		// Generate preamble and concatenate the bitstream after it.
		final ByteBuffer data = BufferUtils.allocateByteBuffer(logic.limit() + 8);
		data.order(ByteOrder.LITTLE_ENDIAN);

		data.put(0, (byte) 'F');
		data.put(1, (byte) 'P');
		data.put(2, (byte) 'G');
		data.put(3, (byte) 'A');

		data.putInt(4, logic.limit());

		data.position(8); // Set position to after preamble.
		data.put(logic); // Copy bitstream.
		data.position(0); // Reset position to initial value.

		// Write preamble and FPGA logic bitstream together.
		byteBufferToROM(data, DAViS_FX3.LOGIC_START_ADDRESS, DAViS_FX3.LOGIC_MAX_SIZE);
	}

	private void byteBufferToROM(final ByteBuffer data, final int startAddress, final int maxSize) throws Exception {
		// Check data size.
		int dataLength = data.limit();
		if (dataLength > maxSize) {
			throw new Exception("Size of data to write exceeds limits!");
		}

		// A Flash chip on SPI address 0 is our destination.
		usbDevice.sendVendorRequest((byte) 0xB9, (short) 0, (short) 0, null);

		// First erase the required blocks on the Flash memory.
		for (int i = startAddress; i < (startAddress + dataLength); i += 65536) {
			usbDevice.sendVendorRequest((byte) 0xBC, (short) ((i >>> 16) & 0xFFFF), (short) (i & 0xFFFF), null);
		}

		// And then we send out the actual data, in 4 KB chunks.
		int dataOffset = 0;

		while (dataLength > 0) {
			int localDataLength = DAViS_FX3.MAX_TRANSFER_SIZE;
			if (localDataLength > dataLength) {
				localDataLength = dataLength;
			}

			final ByteBuffer dataChunk = BufferUtils.slice(data, dataOffset, localDataLength);

			usbDevice.sendVendorRequest((byte) 0xBB, (short) (((startAddress + dataOffset) >>> 16) & 0xFFFF),
				(short) ((startAddress + dataOffset) & 0xFFFF), dataChunk);

			dataLength -= localDataLength;
			dataOffset += localDataLength;
		}
	}

	private void logicToRAM(final ByteBuffer logic) throws Exception {
		// Configure FPGA directly (0xBE vendor request).
		// Check data size.
		int logicLength = logic.limit();
		if (logicLength > DAViS_FX3.LOGIC_MAX_SIZE) {
			throw new Exception("Size of data to send exceeds limits!");
		}
		if (logicLength < DAViS_FX3.MAX_TRANSFER_SIZE) {
			throw new Exception("Size of data to send too small!");
		}

		// Initialize FPGA configuration.
		usbDevice.sendVendorRequest((byte) 0xBE, (short) 0, (short) 0, null);

		// Then send the first chunk, which also enables writing.
		int logicOffset = 0;

		ByteBuffer logicChunk = BufferUtils.slice(logic, logicOffset, DAViS_FX3.MAX_TRANSFER_SIZE);

		usbDevice.sendVendorRequest((byte) 0xBE, (short) 1, (short) 0, logicChunk);

		logicLength -= DAViS_FX3.MAX_TRANSFER_SIZE;
		logicOffset += DAViS_FX3.MAX_TRANSFER_SIZE;

		// And then we send out the actual data, in 4 KB chunks.
		while (logicLength > DAViS_FX3.MAX_TRANSFER_SIZE) {
			logicChunk = BufferUtils.slice(logic, logicOffset, DAViS_FX3.MAX_TRANSFER_SIZE);

			usbDevice.sendVendorRequest((byte) 0xBE, (short) 2, (short) 0, logicChunk);

			logicLength -= DAViS_FX3.MAX_TRANSFER_SIZE;
			logicOffset += DAViS_FX3.MAX_TRANSFER_SIZE;
		}

		// Finally, we send out the last chunk of data and disable writing.
		logicChunk = BufferUtils.slice(logic, logicOffset, logicLength);

		usbDevice.sendVendorRequest((byte) 0xBE, (short) 3, (short) 0, logicChunk);
	}

	private void eraseROM() throws Exception {
		// A Flash chip on SPI address 0 is our destination.
		usbDevice.sendVendorRequest((byte) 0xB9, (short) 0, (short) 0, null);

		// First erase the required blocks on the Flash memory.
		for (int i = 0; i < 0x100000; i += 65536) {
			usbDevice.sendVendorRequest((byte) 0xBC, (short) ((i >>> 16) & 0xFFFF), (short) (i & 0xFFFF), null);
		}
	}

	private int expData = 0;
	private long imuCount = 0;
	private long dataCount = 0;

	private VBox usbEPListenGUI() {
		final VBox usbEPListenGUI = new VBox(10);

		GUISupport.addLabel(usbEPListenGUI, "USB endpoint 1 stream", "USB endpoint 1 data.", null, null);

		final TextArea usbEP1OutputArea = new TextArea();
		usbEPListenGUI.getChildren().add(usbEP1OutputArea);

		usbDevice.listenToEP((byte) 0x81, LibUsb.TRANSFER_TYPE_INTERRUPT, 4, 64, new RestrictedTransferCallback() {
			@Override
			public void processTransfer(final RestrictedTransfer t) {
				if (t.status() == LibUsb.TRANSFER_COMPLETED) {
					// Print error messages.
					if ((t.buffer().get(0) == 0x00) && (t.buffer().limit() <= 64)) {
						final int errorCode = t.buffer().get(1) & 0xFF;

						final int timeStamp = t.buffer().getInt(2);

						final byte[] errorMsgBytes = new byte[t.buffer().limit() - 6];
						t.buffer().position(6);
						t.buffer().get(errorMsgBytes, 0, errorMsgBytes.length);
						t.buffer().position(0);
						final String errorMsg = new String(errorMsgBytes, StandardCharsets.UTF_8);

						final String output = String.format("%s - Error: 0x%02X, Time: %d\n", errorMsg, errorCode,
							timeStamp);

						GUISupport.runOnJavaFXThread(() -> usbEP1OutputArea.appendText(output));
					}
					else if ((t.buffer().get(0) == 0x01) && (t.buffer().limit() == 15)) {
						// This is an IMU sample. Just count it.
						imuCount++;

						if ((imuCount & 0x03FF) == 0) {
							GUISupport.runOnJavaFXThread(() -> usbEP1OutputArea.appendText(String.format(
								"%d: Got 1024 IMU events.\n", imuCount >>> 10)));
						}
					}
				}
			}

			@Override
			public void prepareTransfer(@SuppressWarnings("unused") final RestrictedTransfer t) {
				// Nothing to do here.
			}
		});

		GUISupport.addLabel(usbEPListenGUI, "USB endpoint 2 stream", "USB endpoint 2 data.", null, null);

		final TextArea usbEP2OutputArea = new TextArea();
		usbEPListenGUI.getChildren().add(usbEP2OutputArea);

		usbDevice.listenToEP((byte) 0x82, LibUsb.TRANSFER_TYPE_BULK, 8, 8192, new RestrictedTransferCallback() {
			@Override
			public void processTransfer(final RestrictedTransfer t) {
				if (t.status() == LibUsb.TRANSFER_COMPLETED) {
					dataCount++;

					if ((dataCount & 0x0FFF) == 0) {
						GUISupport.runOnJavaFXThread(() -> usbEP2OutputArea.appendText(String.format(
							"%d: Got 4096 data buffers.\n", dataCount >>> 12)));
					}

					final ShortBuffer sBuf = t.buffer().order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();

					for (int pos = 0; pos < sBuf.limit(); pos++) {
						final int usbData = (sBuf.get(pos) & 0xFFFF);

						if (usbData != expData) {
							System.out.println(String.format("Mismatch detected, got: %d, expected: %d", usbData,
								expData));
							System.out.println(String.format(
								"First: %d, last-4: %d, last-3: %d, last-2: %d, last-1: %d, last: %d\n",
								(sBuf.get(0) & 0xFFFF), (sBuf.get(sBuf.limit() - 5) & 0xFFFF),
								(sBuf.get(sBuf.limit() - 4) & 0xFFFF), (sBuf.get(sBuf.limit() - 3) & 0xFFFF),
								(sBuf.get(sBuf.limit() - 2) & 0xFFFF), (sBuf.get(sBuf.limit() - 1) & 0xFFFF)));
							expData = usbData;
						}

						expData++;

						if (expData == 65536) {
							expData = 0;
						}
					}
				}
			}

			@Override
			public void prepareTransfer(@SuppressWarnings("unused") final RestrictedTransfer t) {
				// Nothing to do here.
			}
		});

		return (usbEPListenGUI);
	}
}
