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
import java.util.EnumSet;
import java.util.List;
import java.util.prefs.Preferences;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Task;
import javafx.event.EventHandler;
import javafx.scene.control.ComboBox;
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

public class DAViS_FX3_SBL extends Controller {
	private static final List<String> firmwareValidExtensions = new ArrayList<>();
	static {
		DAViS_FX3_SBL.firmwareValidExtensions.add("*.img");
	}

	private static final List<String> logicValidExtensions = new ArrayList<>();
	static {
		DAViS_FX3_SBL.logicValidExtensions.add("*.bit");
	}

	public DAViS_FX3_SBL(final UsbDevice device) {
		super(device);
	}

	private File firmwareFile;
	private File logicFile;
	private String serialNumber;

	private static enum ColorFilter {
		NONE("None", (byte) 0),
		RGBG("RGBG", (byte) 1),
		RGBW("RGBW", (byte) 2);

		private final String name;
		private final byte code;

		private ColorFilter(final String n, final byte c) {
			name = n;
			code = c;
		}

		public final byte getCode() {
			return (code);
		}

		@Override
		public final String toString() {
			return (name);
		}
	}

	@Override
	public VBox generateGUI() {
		final VBox fx3GUI = new VBox(10);

		final HBox firmwareToFlashBox = new HBox(10);
		fx3GUI.getChildren().add(firmwareToFlashBox);

		GUISupport.addLabel(firmwareToFlashBox, "Select FX3 firmware file",
			"Select a FX3 firmware file to upload to the device's Flash memory.", null, null);

		final Preferences defaultFolderNode = Preferences.userRoot().node("/defaultFolders");

		// Load default path, if exists.
		String savedPath = defaultFolderNode.get("fx3Firmware", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
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
					|| !Files.checkExtensions(loadFirmware, DAViS_FX3_SBL.firmwareValidExtensions)) {
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
						DAViS_FX3_SBL.firmwareValidExtensions, defaultFolderNode.get("fx3Firmware", ""));

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
					GUISupport.showDialogProgress(eraseROMTask);

					final Thread t = new Thread(eraseROMTask);
					t.setDaemon(true);
					t.start();
				}
			});

		final HBox logicToFlashBox = new HBox(10);
		fx3GUI.getChildren().add(logicToFlashBox);

		GUISupport.addLabel(logicToFlashBox, "Select FPGA logic file",
			"Select a FPGA logic file to upload to the device.", null, null);

		// Load default path, if exists.
		savedPath = defaultFolderNode.get("fx3Logic", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
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
					|| !Files.checkExtensions(loadLogic, DAViS_FX3_SBL.logicValidExtensions)) {
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
					final File loadLogic = GUISupport.showDialogLoadFile("Bitstream",
						DAViS_FX3_SBL.logicValidExtensions, defaultFolderNode.get("fx3Logic", ""));

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

					GUISupport.showDialogProgress(logicToFPGATask);

					final Thread t = new Thread(logicToFPGATask);
					t.setDaemon(true);
					t.start();
				}
			});

		final HBox serialNumberBox = new HBox(10);
		fx3GUI.getChildren().add(serialNumberBox);

		GUISupport.addLabel(serialNumberBox, "Serial Number", "Input a serial number to be written to the device.",
			null, null);

		// Load default serial number, if exists.
		final String savedSerialNumber = defaultFolderNode.get("fx3SNum", "");
		if (!savedSerialNumber.isEmpty()) {
			serialNumber = savedSerialNumber;
		}

		final TextField serialNumberField = GUISupport.addTextField(serialNumberBox,
			defaultFolderNode.get("fx3SNum", ""), null);

		serialNumberField.textProperty().addListener(new ChangeListener<String>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends String> val, final String oldVal, final String newVal) {
				if (newVal == null) {
					return;
				}

				// Check that the typed in file is valid, if not, color the
				// field background red.
				if (newVal.length() > DAViS_FX3_SBL.SNUM_SIZE) {
					serialNumberField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				serialNumberField.setStyle("");
				serialNumber = newVal;
				defaultFolderNode.put("fx3SNum", newVal);
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(serialNumberBox, "Write Serial Number", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					if ((serialNumber == null) || serialNumber.isEmpty()) {
						GUISupport.showDialogError("No serial number entered!");
						return;
					}

					if (serialNumber.length() > DAViS_FX3_SBL.SNUM_SIZE) {
						GUISupport.showDialogError("Serial number too long!");
						return;
					}

					try {
						serialNumberToROM(serialNumber.getBytes());
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		final HBox colorFilterBox = new HBox(10);
		fx3GUI.getChildren().add(colorFilterBox);

		GUISupport.addLabel(colorFilterBox, "Color Filter", "Select the type of color filter the device has.", null,
			null);

		final ComboBox<ColorFilter> colorFilterComboBox = GUISupport.addComboBox(colorFilterBox,
			EnumSet.allOf(ColorFilter.class), 0);

		GUISupport.addButtonWithMouseClickedHandler(colorFilterBox, "Write Color Filter", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final ColorFilter colorFilter = colorFilterComboBox.valueProperty().getValue();

					try {
						colorFilterToROM(colorFilter.getCode());
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		fx3GUI.getChildren().add(usbEPListenGUI());

		return (fx3GUI);
	}

	private static final byte VR_SPI_CONFIG = (byte) 0xB9;
	private static final byte VR_SPI_TRANSFER = (byte) 0xBB;
	private static final byte VR_SPI_ERASE = (byte) 0xBC;
	private static final byte VR_FPGA_UPLOAD = (byte) 0xBE;

	private static final int MAX_TRANSFER_SIZE = 4096;

	private static final int FLASH_MAX_SIZE = 8 * 1024 * 1024;
	private static final int FLASK_BLOCK_SIZE = 64 * 1024;

	private static final int FIRMWARE_START_ADDRESS = 0;
	private static final int FIRMWARE_MAX_SIZE = 192 * 1024;

	private static final int LOGIC_START_ADDRESS = DAViS_FX3_SBL.FIRMWARE_MAX_SIZE;
	private static final int LOGIC_MAX_SIZE = 2880 * 1024;

	private static final int DATA_START_ADDRESS = DAViS_FX3_SBL.FIRMWARE_MAX_SIZE + DAViS_FX3_SBL.LOGIC_MAX_SIZE;
	// private static final int DATA_MAX_SIZE = 5120 * 1024;
	private static final int DATA_HEADER_SIZE = 8;

	private static final int SNUM_START_ADDRESS = DAViS_FX3_SBL.DATA_START_ADDRESS;
	private static final int SNUM_SIZE = 8;

	private static final int CFILTER_START_ADDRESS = DAViS_FX3_SBL.SNUM_START_ADDRESS + DAViS_FX3_SBL.FLASK_BLOCK_SIZE;
	private static final int CFILTER_SIZE = 1;

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
		final ByteBufferToRomTask firmwareToROMTask = new ByteBufferToRomTask(data,
			DAViS_FX3_SBL.FIRMWARE_START_ADDRESS, DAViS_FX3_SBL.FIRMWARE_MAX_SIZE);

		GUISupport.showDialogProgress(firmwareToROMTask);

		final Thread t = new Thread(firmwareToROMTask);
		t.setDaemon(true);
		t.start();
	}

	private void serialNumberToROM(final byte[] sNumArray) throws Exception {
		// Check size of input array.
		if (sNumArray.length > DAViS_FX3_SBL.SNUM_SIZE) {
			throw new Exception("Size of serial number character array exceeds maximum!");
		}

		final ByteBuffer sNum = BufferUtils
			.allocateByteBuffer(DAViS_FX3_SBL.DATA_HEADER_SIZE + DAViS_FX3_SBL.SNUM_SIZE);
		sNum.order(ByteOrder.LITTLE_ENDIAN);

		// Get the bytes from the input array.
		sNum.position((DAViS_FX3_SBL.DATA_HEADER_SIZE + DAViS_FX3_SBL.SNUM_SIZE) - sNumArray.length);
		sNum.put(sNumArray, 0, sNumArray.length);

		// Pad with zeros at the front, if shorter.
		for (int i = 0; i < (DAViS_FX3_SBL.SNUM_SIZE - sNumArray.length); i++) {
			sNum.put(DAViS_FX3_SBL.DATA_HEADER_SIZE + i, (byte) '0');
		}

		// Write correct header.
		sNum.put(0, (byte) 'S');
		sNum.put(1, (byte) 'N');
		sNum.put(2, (byte) 'U');
		sNum.put(3, (byte) 'M');

		sNum.putInt(4, 8);

		sNum.position(0); // Reset position to initial value.

		// Write FX3 serial number.
		final ByteBufferToRomTask serialNumberToROMTask = new ByteBufferToRomTask(sNum,
			DAViS_FX3_SBL.SNUM_START_ADDRESS, DAViS_FX3_SBL.DATA_HEADER_SIZE + DAViS_FX3_SBL.SNUM_SIZE);

		final Thread t = new Thread(serialNumberToROMTask);
		t.setDaemon(true);
		t.start();
	}

	private void colorFilterToROM(final byte colorFilterByte) {
		final ByteBuffer cFilter = BufferUtils.allocateByteBuffer(DAViS_FX3_SBL.DATA_HEADER_SIZE
			+ DAViS_FX3_SBL.CFILTER_SIZE);
		cFilter.order(ByteOrder.LITTLE_ENDIAN);

		// Write correct header.
		cFilter.put(0, (byte) 'C');
		cFilter.put(1, (byte) 'O');
		cFilter.put(2, (byte) 'F');
		cFilter.put(3, (byte) 'I');

		cFilter.putInt(4, 1);

		// Put single byte containing color filter value.
		cFilter.put(8, colorFilterByte);

		cFilter.position(0); // Reset position to initial value.

		// Write color filter information to FX3 ROM.
		final ByteBufferToRomTask colorFilterToROMTask = new ByteBufferToRomTask(cFilter,
			DAViS_FX3_SBL.CFILTER_START_ADDRESS, DAViS_FX3_SBL.DATA_HEADER_SIZE + DAViS_FX3_SBL.CFILTER_SIZE);

		final Thread t = new Thread(colorFilterToROMTask);
		t.setDaemon(true);
		t.start();
	}

	private void logicToROM(final ByteBuffer logic) {
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
		final ByteBufferToRomTask logicToROMTask = new ByteBufferToRomTask(data, DAViS_FX3_SBL.LOGIC_START_ADDRESS,
			DAViS_FX3_SBL.LOGIC_MAX_SIZE);

		GUISupport.showDialogProgress(logicToROMTask);

		final Thread t = new Thread(logicToROMTask);
		t.setDaemon(true);
		t.start();
	}

	private class ByteBufferToRomTask extends Task<Void> {
		private final ByteBuffer data;
		private final int startAddress;
		private final int maxSize;

		public ByteBufferToRomTask(final ByteBuffer data, final int startAddress, final int maxSize) {
			this.data = data;
			this.startAddress = startAddress;
			this.maxSize = maxSize;
		}

		@Override
		protected Void call() throws Exception {
			updateProgress(0, 100);

			// Check data size.
			int dataLength = data.limit();
			if (dataLength > maxSize) {
				throw new Exception("Size of data to write exceeds limits!");
			}

			// A Flash chip on SPI address 0 is our destination.
			usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_SPI_CONFIG, (short) 0, (short) 0, null);

			// Support progress counter.
			updateProgress(2, 100);

			// First erase the required blocks on the Flash memory, 64KB at a
			// time.
			for (int i = startAddress; i < (startAddress + dataLength); i += (64 * 1024)) {
				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_SPI_ERASE, (short) ((i >>> 16) & 0xFFFF),
					(short) (i & 0xFFFF), null);
			}

			// Support progress counter (94% allocated to app).
			updateProgress(6, 100);
			final double progressPerKB = 94.0 / (dataLength / 1024.0);

			// And then we send out the actual data, in 4 KB chunks.
			int dataOffset = 0;

			while (dataLength > 0) {
				int localDataLength = DAViS_FX3_SBL.MAX_TRANSFER_SIZE;
				if (localDataLength > dataLength) {
					localDataLength = dataLength;
				}

				final ByteBuffer dataChunk = BufferUtils.slice(data, dataOffset, localDataLength);

				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_SPI_TRANSFER,
					(short) (((startAddress + dataOffset) >>> 16) & 0xFFFF),
					(short) ((startAddress + dataOffset) & 0xFFFF), dataChunk);

				dataLength -= localDataLength;
				dataOffset += localDataLength;

				// Update progress based on index (reached length).
				updateProgress((long) (((dataOffset / 1024.0) * progressPerKB) + 6.0), 100);
			}

			updateProgress(100, 100);

			done();

			return null;
		}
	}

	private final Task<Void> eraseROMTask = new Task<Void>() {
		@Override
		protected Void call() throws Exception {
			updateProgress(0, 100);

			// A Flash chip on SPI address 0 is our destination.
			usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_SPI_CONFIG, (short) 0, (short) 0, null);

			// Support progress counter (98% allocated to app).
			updateProgress(2, 100);
			final double progressPerKB = 98.0 / (DAViS_FX3_SBL.FLASH_MAX_SIZE / 1024.0);

			// First erase the required blocks on the Flash memory, 64KB at a
			// time.
			for (int i = 0; i < DAViS_FX3_SBL.FLASH_MAX_SIZE; i += (64 * 1024)) {
				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_SPI_ERASE, (short) ((i >>> 16) & 0xFFFF),
					(short) (i & 0xFFFF), null);

				// Update progress based on index (reached length).
				updateProgress((long) (((i / 1024.0) * progressPerKB) + 2.0), 100);
			}

			updateProgress(100, 100);

			done();

			return null;
		}
	};

	private final Task<Void> logicToFPGATask = new Task<Void>() {
		@Override
		protected Void call() throws Exception {
			updateProgress(0, 100);

			try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
				final FileChannel fwInChannel = fwFile.getChannel()) {
				final MappedByteBuffer logic = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
				logic.load();

				// Configure FPGA directly (0xBE vendor request).
				// Check data size.
				int logicLength = logic.limit();
				if (logicLength > DAViS_FX3_SBL.LOGIC_MAX_SIZE) {
					throw new Exception("Size of data to send exceeds limits!");
				}
				if (logicLength < DAViS_FX3_SBL.MAX_TRANSFER_SIZE) {
					throw new Exception("Size of data to send too small!");
				}

				// Initialize FPGA configuration.
				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_FPGA_UPLOAD, (short) 0, (short) 0, null);

				// Then send the first chunk, which also enables writing.
				int logicOffset = 0;

				ByteBuffer logicChunk = BufferUtils.slice(logic, logicOffset, DAViS_FX3_SBL.MAX_TRANSFER_SIZE);

				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_FPGA_UPLOAD, (short) 1, (short) 0, logicChunk);

				logicLength -= DAViS_FX3_SBL.MAX_TRANSFER_SIZE;
				logicOffset += DAViS_FX3_SBL.MAX_TRANSFER_SIZE;

				// Support progress counter (98% allocated to app).
				updateProgress(2, 100);
				final double progressPerKB = 98.0 / (logicLength / 1024.0);

				// And then we send out the actual data, in 4 KB chunks.
				while (logicLength > DAViS_FX3_SBL.MAX_TRANSFER_SIZE) {
					logicChunk = BufferUtils.slice(logic, logicOffset, DAViS_FX3_SBL.MAX_TRANSFER_SIZE);

					usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_FPGA_UPLOAD, (short) 2, (short) 0, logicChunk);

					logicLength -= DAViS_FX3_SBL.MAX_TRANSFER_SIZE;
					logicOffset += DAViS_FX3_SBL.MAX_TRANSFER_SIZE;

					// Update progress based on index (reached length).
					updateProgress((long) (((logicOffset / 1024.0) * progressPerKB) + 2.0), 100);
				}

				// Finally, we send out the last chunk of data and disable
				// writing.
				logicChunk = BufferUtils.slice(logic, logicOffset, logicLength);

				usbDevice.sendVendorRequest(DAViS_FX3_SBL.VR_FPGA_UPLOAD, (short) 3, (short) 0, logicChunk);

				// Cleanup ByteBuffer.
				logic.clear();
			}

			updateProgress(100, 100);

			done();

			return null;
		}
	};

	private int expData = 0;
	private final boolean fullDebug = false;
	private final boolean printOutput = true;
	private long dataCount = 0;
	private long errorCount = 0;

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

						if (printOutput) {
							System.out.println(output);
						}
						else {
							GUISupport.runOnJavaFXThread(() -> usbEP1OutputArea.appendText(output));
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
				if (t.buffer().limit() == 0) {
					if (fullDebug) {
						System.out.println("Zero Length Packet detected.\n");
					}

					return;
				}

				if (t.status() == LibUsb.TRANSFER_COMPLETED) {
					dataCount++;

					if ((dataCount & 0x0FFF) == 0) {
						GUISupport.runOnJavaFXThread(() -> usbEP2OutputArea.appendText(String.format(
							"%d: Got 4096 data buffers.\n", dataCount >>> 12)));
					}

					final ShortBuffer sBuf = t.buffer().order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();

					if (fullDebug) {
						if (sBuf.limit() >= 8) {
							System.out.println(String
								.format(
									"Length: %d\nFirst: %d, first+1: %d, first+2: %d, first+3: %d, first+4: %d, first+5: %d, first+6: %d, first+7: %d\nLast-7: %d, last-6: %d, last-5: %d, last-4: %d, last-3: %d, last-2: %d, last-1: %d, last: %d\n",
									(sBuf.limit()), (sBuf.get(0) & 0xFFFF), (sBuf.get(1) & 0xFFFF),
									(sBuf.get(2) & 0xFFFF), (sBuf.get(3) & 0xFFFF), (sBuf.get(4) & 0xFFFF),
									(sBuf.get(5) & 0xFFFF), (sBuf.get(6) & 0xFFFF), (sBuf.get(7) & 0xFFFF),
									(sBuf.get(sBuf.limit() - 8) & 0xFFFF), (sBuf.get(sBuf.limit() - 7) & 0xFFFF),
									(sBuf.get(sBuf.limit() - 6) & 0xFFFF), (sBuf.get(sBuf.limit() - 5) & 0xFFFF),
									(sBuf.get(sBuf.limit() - 4) & 0xFFFF), (sBuf.get(sBuf.limit() - 3) & 0xFFFF),
									(sBuf.get(sBuf.limit() - 2) & 0xFFFF), (sBuf.get(sBuf.limit() - 1) & 0xFFFF)));
						}
						else {
							System.out.println(String.format(
								"Small packet detected.\nLength: %d\nFirst: %d, last: %d\n", (sBuf.limit()),
								(sBuf.get(0) & 0xFFFF), (sBuf.get(sBuf.limit() - 1) & 0xFFFF)));
						}
					}

					for (int pos = 0; pos < sBuf.limit(); pos++) {
						final int usbData = (sBuf.get(pos) & 0xFFFF);

						if (usbData != expData) {
							errorCount++;

							final String output = String
								.format(
									"%d - Length: %d\nFirst: %d, last: %d\nMismatch detected, got: %d, expected: %d (difference: %d)\n",
									errorCount, (sBuf.limit()), (sBuf.get(0) & 0xFFFF),
									(sBuf.get(sBuf.limit() - 1) & 0xFFFF), usbData, expData, usbData - expData);

							if (printOutput) {
								System.out.println(output);
							}
							else {
								GUISupport.runOnJavaFXThread(() -> usbEP2OutputArea.appendText(output));
							}

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
