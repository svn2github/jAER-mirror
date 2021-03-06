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
import java.util.prefs.Preferences;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.event.EventHandler;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import net.sf.jaer.Files;
import net.sf.jaer.GUISupport;
import net.sf.jaer.UsbDevice;

import org.usb4java.BufferUtils;

public class FX3 extends Controller {
	private static final List<String> firmwareRAMValidExtensions = new ArrayList<>();
	static {
		FX3.firmwareRAMValidExtensions.add("*.img");
	}

	public FX3(final UsbDevice device) {
		super(device);
	}

	private File firmwareRAMFile;

	@Override
	public VBox generateGUI() {
		final VBox firmwareFlashGUI = new VBox(10);

		final HBox firmwareToFlashBox = new HBox(10);
		firmwareFlashGUI.getChildren().add(firmwareToFlashBox);

		GUISupport.addLabel(firmwareToFlashBox, "Select FX3 firmware file",
			"Select a FX3 firmware file to upload to the device's RAM.", null, null);

		final Preferences defaultFolderNode = Preferences.userRoot().node("/defaultFolders");

		// Load default path, if exists.
		final String savedPath = defaultFolderNode.get("fx3RAMFirmware", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				firmwareRAMFile = savedFile;
			}
		}

		final TextField firmwareField = GUISupport.addTextField(firmwareToFlashBox,
			defaultFolderNode.get("fx3RAMFirmware", ""), null);

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
					|| !Files.checkExtensions(loadFirmware, FX3.firmwareRAMValidExtensions)) {
					firmwareField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				firmwareField.setStyle("");
				firmwareRAMFile = loadFirmware;
				defaultFolderNode.put("fx3RAMFirmware", loadFirmware.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile("FX3 RAM Image",
						FX3.firmwareRAMValidExtensions, defaultFolderNode.get("fx3RAMFirmware", ""));

					if (loadFirmware == null) {
						return;
					}

					firmwareField.setText(loadFirmware.getAbsolutePath());
					firmwareRAMFile = loadFirmware;
					defaultFolderNode.put("fx3RAMFirmware", loadFirmware.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(firmwareFlashGUI, "Upload FX3 firmware to RAM", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (firmwareRAMFile == null) {
						GUISupport.showDialogError("No FX3 RAM firmware file selected!");
						return;
					}

					try (final RandomAccessFile fwFile = new RandomAccessFile(firmwareRAMFile, "r");
						final FileChannel fwInChannel = fwFile.getChannel()) {
						final MappedByteBuffer buf = fwInChannel.map(MapMode.READ_ONLY, 0, fwInChannel.size());
						buf.load();

						firmwareToRAM(buf);

						// Cleanup ByteBuffer.
						buf.clear();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		return (firmwareFlashGUI);
	}

	private static final byte VR_FIRMWARE = (byte) 0xA0;
	private static final int MAX_TRANSFER_SIZE = 4096;
	private static final int IMAGE_MAX_SIZE = 192 * 1024;

	private void firmwareToRAM(final ByteBuffer fw) throws Exception {
		// Check signature.
		if ((fw.get(0) != 'C') || (fw.get(1) != 'Y')) {
			throw new Exception("Illegal signature for firmware file.");
		}

		// Setup counters.
		int fwLength = fw.limit() - 4; // -2 for signature, -2 for dummy bytes
		int fwOffset = 4;

		// Ensure the values we read are little-endian.
		fw.order(ByteOrder.LITTLE_ENDIAN);

		// Check data size.
		if (fwLength > FX3.IMAGE_MAX_SIZE) {
			throw new Exception("Size of firmware to write to RAM exceeds limits!");
		}

		// Checksum.
		long fwChecksum = 0;

		while (fwLength > 0) {
			// Read firmware chunk information from file.
			int chunkLength = fw.getInt(fwOffset);
			final int chunkAddress = fw.getInt(fwOffset + 4);

			// Convert length to bytes (it's in 32bit words).
			chunkLength *= 4;

			// If chunkLength is zero, then we're done.
			if (chunkLength == 0) {
				// Get and verify checksum.
				final long fwExpectedChecksum = (fw.getInt(fwOffset + 8) & 0xFFFFFFFFL);

				if ((fwChecksum & 0xFFFFFFFFL) != fwExpectedChecksum) {
					throw new Exception("Firmware checksum doesn't match expected value!");
				}

				// Transfer control to newly uploaded firmware.
				usbDevice.sendVendorRequest(FX3.VR_FIRMWARE, (short) (chunkAddress & 0xFFFF),
					(short) ((chunkAddress >>> 16) & 0xFFFF), null);

				// Exit.
				break;
			}

			// Get current piece of firmware to transfer.
			final ByteBuffer chunkData = BufferUtils.slice(fw, fwOffset + 8, chunkLength);

			// Ensure this is little-endian for the checksum calculation.
			chunkData.order(ByteOrder.LITTLE_ENDIAN);

			// Calculate checksum.
			for (int i = 0; i < chunkLength; i += 4) {
				fwChecksum += (chunkData.getInt(i) & 0xFFFFFFFFL);
			}

			// Update counters.
			fwOffset += (8 + chunkLength);
			fwLength -= (8 + chunkLength);

			// Upload firmware, then verify it. Must be done in small, maximum
			// 4K sized chunks.
			int chunkOffset = 0;

			while (chunkLength > 0) {
				int localChunkLength = FX3.MAX_TRANSFER_SIZE;
				if (localChunkLength > chunkLength) {
					localChunkLength = chunkLength;
				}

				// Send vendor request to upload firmware.
				final ByteBuffer uploadData = BufferUtils.slice(chunkData, chunkOffset, localChunkLength);
				usbDevice.sendVendorRequest(FX3.VR_FIRMWARE, (short) ((chunkAddress + chunkOffset) & 0xFFFF),
					(short) (((chunkAddress + chunkOffset) >>> 16) & 0xFFFF), uploadData);

				// Send vendor request to read back firmware and verify it.
				final ByteBuffer readBackData = usbDevice.sendVendorRequestIN(FX3.VR_FIRMWARE,
					(short) ((chunkAddress + chunkOffset) & 0xFFFF),
					(short) (((chunkAddress + chunkOffset) >>> 16) & 0xFFFF), localChunkLength);

				if (readBackData.compareTo(uploadData) != 0) {
					throw new Exception("Failed to verify firmware chunk.");
				}

				// Update counters (chunk loop).
				chunkLength -= localChunkLength;
				chunkOffset += localChunkLength;
			}
		}
	}
}
