package net.sf.jaer.controllers;

import java.io.File;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.ShortBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.util.ArrayList;
import java.util.List;
import java.util.prefs.Preferences;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
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

public class DAViS_FX2_SBL extends Controller {
	private static final List<String> firmwareValidExtensions = new ArrayList<>();
	static {
		DAViS_FX2_SBL.firmwareValidExtensions.add("*.iic");
	}

	private static final List<String> logicValidExtensions = new ArrayList<>();
	static {
		DAViS_FX2_SBL.logicValidExtensions.add("*.xsvf");
	}

	public DAViS_FX2_SBL(final UsbDevice device) {
		super(device);
	}

	private File firmwareFile;
	private File logicFile;
	private String serialNumber;

	@Override
	public VBox generateGUI() {
		final VBox fx2GUI = new VBox(10);

		final HBox firmwareToFlashBox = new HBox(10);
		fx2GUI.getChildren().add(firmwareToFlashBox);

		GUISupport.addLabel(firmwareToFlashBox, "Select FX2 firmware file",
			"Select a FX2 firmware file to upload to the device's EEPROM memory.", null, null);

		final Preferences defaultFolderNode = Preferences.userRoot().node("/defaultFolders");

		// Load default path, if exists.
		String savedPath = defaultFolderNode.get("fx2Firmware", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				firmwareFile = savedFile;
			}
		}

		final TextField firmwareField = GUISupport.addTextField(firmwareToFlashBox,
			defaultFolderNode.get("fx2Firmware", ""), null);

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
					|| !Files.checkExtensions(loadFirmware, DAViS_FX2_SBL.firmwareValidExtensions)) {
					firmwareField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				firmwareField.setStyle("");
				firmwareFile = loadFirmware;
				defaultFolderNode.put("fx2Firmware", loadFirmware.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile("FX2 Image",
						DAViS_FX2_SBL.firmwareValidExtensions, defaultFolderNode.get("fx2Firmware", ""));

					if (loadFirmware == null) {
						return;
					}

					firmwareField.setText(loadFirmware.getAbsolutePath());
					firmwareFile = loadFirmware;
					defaultFolderNode.put("fx2Firmware", loadFirmware.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Flash FX2 firmware", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (firmwareFile == null) {
						GUISupport.showDialogError("No FX2 firmware file selected!");
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
		fx2GUI.getChildren().add(logicToFlashBox);

		GUISupport.addLabel(logicToFlashBox, "Select CPLD logic file",
			"Select a CPLD logic file to upload to the device.", null, null);

		// Load default path, if exists.
		savedPath = defaultFolderNode.get("fx2Logic", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				logicFile = savedFile;
			}
		}

		final TextField logicField = GUISupport.addTextField(logicToFlashBox, defaultFolderNode.get("fx2Logic", ""),
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
					|| !Files.checkExtensions(loadLogic, DAViS_FX2_SBL.logicValidExtensions)) {
					logicField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				logicField.setStyle("");
				logicFile = loadLogic;
				defaultFolderNode.put("fx2Logic", loadLogic.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadLogic = GUISupport.showDialogLoadFile("Bitstream",
						DAViS_FX2_SBL.logicValidExtensions, defaultFolderNode.get("fx2Logic", ""));

					if (loadLogic == null) {
						return;
					}

					logicField.setText(loadLogic.getAbsolutePath());
					logicFile = loadLogic;
					defaultFolderNode.put("fx2Logic", loadLogic.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Upload CPLD bitstream", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (logicFile == null) {
						GUISupport.showDialogError("No CPLD bitstream file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						// Load file to CPLD.
						logicToCPLD(buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		final HBox serialNumberBox = new HBox(10);
		fx2GUI.getChildren().add(serialNumberBox);

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
				if (newVal.length() > DAViS_FX2_SBL.SNUM_MAX_SIZE) {
					logicField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				logicField.setStyle("");
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

					if (serialNumber.length() > DAViS_FX2_SBL.SNUM_MAX_SIZE) {
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

		fx2GUI.getChildren().add(usbEPListenGUI());

		return (fx2GUI);
	}

	private static final byte VR_EEPROM = (byte) 0xBD;
	private static final byte VR_CPLD_UPLOAD = (byte) 0xBE;

	private static final int MAX_TRANSFER_SIZE = 4096;

	private static final int EEPROM_MAX_SIZE = 32 * 1024;

	private static final int FIRMWARE_START_ADDRESS = 0;
	private static final int FIRMWARE_MAX_SIZE = DAViS_FX2_SBL.EEPROM_MAX_SIZE - 8;

	private static final int SNUM_START_ADDRESS = DAViS_FX2_SBL.FIRMWARE_MAX_SIZE;
	private static final int SNUM_MAX_SIZE = 8;

	// IIC files go directly to EEPROM.
	private void firmwareToROM(final ByteBuffer fw) throws Exception {
		// Check signature.
		if ((fw.get(0) != (byte) 0xC2)) {
			throw new Exception("Illegal signature for firmware file.");
		}

		// Write FX2 firmware.
		byteBufferToROM(fw, DAViS_FX2_SBL.FIRMWARE_START_ADDRESS, DAViS_FX2_SBL.FIRMWARE_MAX_SIZE);
	}

	private void serialNumberToROM(final byte[] sNumArray) throws Exception {
		// Check size of input array.
		if (sNumArray.length > DAViS_FX2_SBL.SNUM_MAX_SIZE) {
			throw new Exception("Size of serial number character array exceeds maximum!");
		}

		final ByteBuffer sNum = BufferUtils.allocateByteBuffer(DAViS_FX2_SBL.SNUM_MAX_SIZE);
		sNum.order(ByteOrder.LITTLE_ENDIAN);

		// Get the bytes from the input array.
		sNum.position(DAViS_FX2_SBL.SNUM_MAX_SIZE - sNumArray.length);
		sNum.put(sNumArray, 0, sNumArray.length);

		// Pad with zeros at the front, if shorter.
		for (int i = 0; i < (DAViS_FX2_SBL.SNUM_MAX_SIZE - sNumArray.length); i++) {
			sNum.put(i, (byte) '0');
		}

		sNum.position(0); // Reset position to initial value.

		// Write FX2 serial number.
		byteBufferToROM(sNum, DAViS_FX2_SBL.SNUM_START_ADDRESS, DAViS_FX2_SBL.SNUM_MAX_SIZE);
	}

	private void byteBufferToROM(final ByteBuffer data, final int startAddress, final int maxSize) throws Exception {
		// Check data size.
		int dataLength = data.limit();
		if (dataLength > maxSize) {
			throw new Exception("Size of data to write exceeds limits!");
		}

		// Send out the actual data to the EEPROM, in 4 KB chunks.
		int dataOffset = 0;

		while (dataLength > 0) {
			int localDataLength = DAViS_FX2_SBL.MAX_TRANSFER_SIZE;
			if (localDataLength > dataLength) {
				localDataLength = dataLength;
			}

			final ByteBuffer dataChunk = BufferUtils.slice(data, dataOffset, localDataLength);

			// Just wValue is enough for the address (16 bit), since the EEPROM
			// is just 32KB at the most.
			usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_EEPROM, (short) ((startAddress + dataOffset) & 0xFFFF),
				(short) 0, dataChunk);

			dataLength -= localDataLength;
			dataOffset += localDataLength;
		}
	}

	private void eraseROM() throws Exception {
		// Generate empty ByteBuffer (all zeros) to send to EEPROM.
		final ByteBuffer eraser = BufferUtils.allocateByteBuffer(DAViS_FX2_SBL.MAX_TRANSFER_SIZE);
		eraser.put(new byte[DAViS_FX2_SBL.MAX_TRANSFER_SIZE]);
		eraser.position(0); // Reset position to initial value.

		// Send out the actual data to the FX2 EEPROM, in 4 KB chunks.
		int fwLength = DAViS_FX2_SBL.EEPROM_MAX_SIZE;
		int fwOffset = 0;

		while (fwLength > 0) {
			usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_EEPROM, (short) (fwOffset & 0xFFFF), (short) 0, eraser);

			fwLength -= DAViS_FX2_SBL.MAX_TRANSFER_SIZE;
			fwOffset += DAViS_FX2_SBL.MAX_TRANSFER_SIZE;
		}
	}

	/* XSVF instruction encoding, from Xilinx */
	private static final byte XCOMPLETE = (byte) 0;
	private static final byte XTDOMASK = (byte) 1;
	private static final byte XSIR = (byte) 2;
	private static final byte XSDR = (byte) 3;
	private static final byte XRUNTEST = (byte) 4;
	/* Reserved 5 - Illegal Command */
	/* Reserved 6 - Illegal Command */
	private static final byte XREPEAT = (byte) 7;
	private static final byte XSDRSIZE = (byte) 8;
	private static final byte XSDRTDO = (byte) 9;
	/* Reserved 10 - Illegal Command */
	/* Reserved 11 - Illegal Command */
	private static final byte XSDRB = (byte) 12;
	private static final byte XSDRC = (byte) 13;
	private static final byte XSDRE = (byte) 14;
	private static final byte XSDRTDOB = (byte) 15;
	private static final byte XSDRTDOC = (byte) 16;
	private static final byte XSDRTDOE = (byte) 17;
	private static final byte XSTATE = (byte) 18; /* 4.00 */
	private static final byte XENDIR = (byte) 19; /* 4.04 */
	private static final byte XENDDR = (byte) 20; /* 4.04 */
	private static final byte XSIR2 = (byte) 21; /* 4.10 */
	private static final byte XCOMMENT = (byte) 22; /* 4.14 */
	private static final byte XWAIT = (byte) 23; /* 5.00 */

	private void logicToCPLD(final ByteBuffer logic) throws Exception {
		// Configure CPLD directly (0xBE vendor request).
		// Check data size.
		final int logicLength = logic.limit();
		if (logicLength < DAViS_FX2_SBL.MAX_TRANSFER_SIZE) {
			throw new Exception("Size of data to send too small!");
		}

		int commandLength = 1, index = 0, length = 0;

		// Get first command.
		byte command = logic.get(index);

		// Wait until XCOMPLETE.
		while (command != DAViS_FX2_SBL.XCOMPLETE) {
			switch (command) {
				case XTDOMASK:
					commandLength = length + 1;
					break;

				case XREPEAT:
					commandLength = 2;
					break;

				case XRUNTEST:
					commandLength = 5;
					break;

				case XSIR:
					commandLength = (((logic.get(index + 1) & 0xFF) + 7) / 8) + 2;
					break;

				case XSIR2:
					commandLength = (((((logic.get(index + 1) & 0xFF) << 8) | (logic.get(index + 2) & 0xFF)) + 7) / 8) + 3;
					break;

				case XSDR:
					commandLength = length + 1;
					break;

				case XSDRSIZE:
					commandLength = 5;

					length = ((((logic.get(index + 1) & 0xFF) << 24) | ((logic.get(index + 2) & 0xFF) << 16)
						| ((logic.get(index + 3) & 0xFF) << 8) | (logic.get(index + 4) & 0xFF)) + 7) / 8;
					break;

				case XSDRTDO:
					commandLength = (2 * length) + 1;
					break;

				case XSDRB:
					commandLength = length + 1;
					break;

				case XSDRC:
					commandLength = length + 1;
					break;

				case XSDRE:
					commandLength = length + 1;
					break;

				case XSDRTDOB:
					commandLength = (2 * length) + 1;
					break;

				case XSDRTDOC:
					commandLength = (2 * length) + 1;
					break;

				case XSDRTDOE:
					commandLength = (2 * length) + 1;
					break;

				case XSTATE:
					commandLength = 2;
					break;

				case XENDIR:
					commandLength = 2;
					break;

				case XENDDR:
					commandLength = 2;
					break;

				case XCOMMENT:
					commandLength = 2;

					// Found comment, skipping.
					while (logic.get((index + commandLength) - 1) != 0x00) {
						commandLength += 1;
					}
					break;

				case XWAIT:
					commandLength = 7;
					break;

				default:
					// Unknown XSVF command, stop programming.
					usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, (short) 0, (short) 0, null);
					throw new Exception("Unknown XSVF command.");
			}

			final ByteBuffer logicChunk = BufferUtils.slice(logic, index, commandLength);

			usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, command, (short) 0, logicChunk);

			// System.out.println(String.format("Sent VR_CPLD_UPLOAD, with command %d at index %d, length %d", command, index, commandLength));

			// Get result.
			final ByteBuffer result = usbDevice.sendVendorRequestIN(DAViS_FX2_SBL.VR_CPLD_UPLOAD, (short) 0, (short) 0,
				2);

			if ((result.limit() == 0) || (result.get(0) != DAViS_FX2_SBL.VR_CPLD_UPLOAD)) {
				// Invalid response from device, stop programming.
				usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, (short) 0, (short) 0, null);
				throw new Exception("Invalid response from device.");
			}

			if (result.get(1) == 10) {
				// Overlong command (error code 10), stop programming.
				usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, (short) 0, (short) 0, null);
				throw new Exception("Overlong command.");
			}
			else if (result.get(1) > 0) {
				// XSVF error encountered, stop programming.
				usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, (short) 0, (short) 0, null);
				throw new Exception(String.format("XSVF error encountered (error %d).", result.get(1) & 0xFF));
			}

			index += commandLength;

			// Get next command to execute.
			command = logic.get(index);
		}

		// Done, send XCOMPLETE.
		usbDevice.sendVendorRequest(DAViS_FX2_SBL.VR_CPLD_UPLOAD, DAViS_FX2_SBL.XCOMPLETE, (short) 0, null);
	}

	private int expData = 0;
	private final boolean fullDebug = false;
	private final boolean printOutput = true;
	private long dataCount = 0;

	private VBox usbEPListenGUI() {
		final VBox usbEPListenGUI = new VBox(10);

		GUISupport.addLabel(usbEPListenGUI, "USB endpoint 6 stream", "USB endpoint 6 data.", null, null);

		final TextArea usbEP6OutputArea = new TextArea();
		usbEPListenGUI.getChildren().add(usbEP6OutputArea);

		usbDevice.listenToEP((byte) 0x86, LibUsb.TRANSFER_TYPE_BULK, 8, 4096, new RestrictedTransferCallback() {
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
						GUISupport.runOnJavaFXThread(() -> usbEP6OutputArea.appendText(String.format(
							"%d: Got 4096 data buffers.\n", dataCount >>> 12)));
					}

					final ShortBuffer sBuf = t.buffer().order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();

					if (fullDebug) {
						if (sBuf.limit() >= 8) {
							System.out.println(String
								.format(
									"Length: %d\nFirst: %d, first+1: %d\nLast-7: %d, last-6: %d, last-5: %d, last-4: %d, last-3: %d, last-2: %d, last-1: %d, last: %d\n",
									(sBuf.limit()), (sBuf.get(0) & 0xFFFF), (sBuf.get(1) & 0xFFFF),
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
							final String output = String
								.format(
									"Length: %d\nFirst: %d, last: %d\nMismatch detected, got: %d, expected: %d (difference: %d)\n",
									(sBuf.limit()), (sBuf.get(0) & 0xFFFF), (sBuf.get(sBuf.limit() - 1) & 0xFFFF),
									usbData, expData, usbData - expData);

							if (printOutput) {
								System.out.println(output);
							}
							else {
								GUISupport.runOnJavaFXThread(() -> usbEP6OutputArea.appendText(output));
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
