package net.sf.jaer.controllers;

import java.io.File;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
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
import li.longi.libusb4java.utils.BufferUtils;
import net.sf.jaer.Files;
import net.sf.jaer.GUISupport;
import net.sf.jaer.UsbDevice;

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

		final TextField firmwareField = GUISupport.addTextField(firmwareToFlashBox, null, null);

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
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile("FX3 Image",
						DAViS_FX3.firmwareValidExtensions);

					if (loadFirmware == null) {
						return;
					}

					firmwareField.setText(loadFirmware.getAbsolutePath());
					firmwareFile = loadFirmware;
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

		final HBox logicToFlashBox = new HBox(10);
		fx3GUI.getChildren().add(logicToFlashBox);

		GUISupport.addLabel(logicToFlashBox, "Select FPGA logic file",
			"Select a FPGA logic file to upload to the device.", null, null);

		final TextField logicField = GUISupport.addTextField(logicToFlashBox, null, null);

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
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(logicToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadLogic = GUISupport.showDialogLoadFile("Bitstream", DAViS_FX3.logicValidExtensions);

					if (loadLogic == null) {
						return;
					}

					logicField.setText(loadLogic.getAbsolutePath());
					logicFile = loadLogic;
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

					try (final RandomAccessFile fwFile = new RandomAccessFile(logicFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						logicToRAM(buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

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

		// Set third byte to 0x20, to enable 30 MHz SPI boot transfer rate.
		fw.put(2, (byte) 0x20);

		// Write FX3 firmware.
		byteBufferToROM(fw, DAViS_FX3.FIRMWARE_START_ADDRESS, DAViS_FX3.FIRMWARE_MAX_SIZE);
	}

	private void logicToROM(final ByteBuffer logic) throws Exception {
		// Generate and write preamble first.
		final ByteBuffer preamble = BufferUtils.allocateByteBuffer(8);
		preamble.order(ByteOrder.LITTLE_ENDIAN);

		preamble.put(0, (byte) 'F');
		preamble.put(1, (byte) 'P');
		preamble.put(2, (byte) 'G');
		preamble.put(3, (byte) 'A');

		preamble.putInt(4, logic.limit());

		byteBufferToROM(preamble, DAViS_FX3.LOGIC_START_ADDRESS, DAViS_FX3.LOGIC_MAX_SIZE);

		// Write FPGA logic bitstream.
		byteBufferToROM(logic, DAViS_FX3.LOGIC_START_ADDRESS + 8, DAViS_FX3.LOGIC_MAX_SIZE - 8);
	}

	private void byteBufferToROM(final ByteBuffer data, final int startAddress, final int maxSize) throws Exception {
		// Check data size.
		int dataLength = data.limit();
		if (dataLength > maxSize) {
			throw new Exception("Size of data to write exceeds limits!");
		}

		// A Flash chip on SPI address 0 is our destination.
		// First we need to erase the required blocks.
		for (int i = startAddress; i < dataLength; i += 65536) {
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
}
