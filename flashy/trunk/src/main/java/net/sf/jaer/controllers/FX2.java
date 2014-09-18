package net.sf.jaer.controllers;

import java.io.File;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
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

public class FX2 extends Controller {
	private static final List<String> firmwareRAMValidExtensions = new ArrayList<>();
	static {
		FX2.firmwareRAMValidExtensions.add("*.bix");
	}

	public FX2(final UsbDevice device) {
		super(device);
	}

	private File firmwareRAMFile;

	@Override
	public VBox generateGUI() {
		final VBox firmwareFlashGUI = new VBox(10);

		final HBox firmwareToFlashBox = new HBox(10);
		firmwareFlashGUI.getChildren().add(firmwareToFlashBox);

		GUISupport.addLabel(firmwareToFlashBox, "Select FX2 firmware file",
			"Select a FX2 firmware file to upload to the device's RAM.", null, null);

		final Preferences defaultFolderNode = Preferences.userRoot().node("/defaultFolders");

		// Load default path, if exists.
		final String savedPath = defaultFolderNode.get("fx2RAMFirmware", "");
		if (!savedPath.isEmpty()) {
			final File savedFile = new File(savedPath);
			if (savedFile.exists() && Files.checkReadPermissions(savedFile)) {
				firmwareRAMFile = savedFile;
			}
		}

		final TextField firmwareField = GUISupport.addTextField(firmwareToFlashBox,
			defaultFolderNode.get("fx2RAMFirmware", ""), null);

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
					|| !Files.checkExtensions(loadFirmware, FX2.firmwareRAMValidExtensions)) {
					firmwareField.setStyle("-fx-background-color: #FF5757");
					return;
				}

				firmwareField.setStyle("");
				firmwareRAMFile = loadFirmware;
				defaultFolderNode.put("fx2RAMFirmware", loadFirmware.getAbsolutePath());
			}
		});

		GUISupport.addButtonWithMouseClickedHandler(firmwareToFlashBox, "Select file", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent mouse) {
					final File loadFirmware = GUISupport.showDialogLoadFile("FX2 RAM Image",
						FX2.firmwareRAMValidExtensions, defaultFolderNode.get("fx2RAMFirmware", ""));

					if (loadFirmware == null) {
						return;
					}

					firmwareField.setText(loadFirmware.getAbsolutePath());
					firmwareRAMFile = loadFirmware;
					defaultFolderNode.put("fx2RAMFirmware", loadFirmware.getAbsolutePath());
				}
			});

		GUISupport.addButtonWithMouseClickedHandler(firmwareFlashGUI, "Upload FX2 firmware to RAM", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					if (firmwareRAMFile == null) {
						GUISupport.showDialogError("No FX2 RAM firmware file selected!");
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
	private static final short CPUCS_ADDR = (short) 0xE600;
	private static final int MAX_TRANSFER_SIZE = 4096;
	private static final int IMAGE_MAX_SIZE = 16 * 1024;

	private void firmwareToRAM(final ByteBuffer fw) throws Exception {
		// Check data size.
		int fwLength = fw.limit();
		if (fwLength > FX2.IMAGE_MAX_SIZE) {
			throw new Exception("Size of firmware to write to RAM exceeds limits!");
		}

		// Put the FX2's 8051 CPU into reset.
		final ByteBuffer resetBuf = BufferUtils.allocateByteBuffer(1);
		resetBuf.put(0, (byte) 1);
		usbDevice.sendVendorRequest(FX2.VR_FIRMWARE, FX2.CPUCS_ADDR, (short) 0, resetBuf);

		// Send out the actual data to the FX2 RAM, in 4 KB chunks.
		int fwOffset = 0;

		while (fwLength > 0) {
			int localDataLength = FX2.MAX_TRANSFER_SIZE;
			if (localDataLength > fwLength) {
				localDataLength = fwLength;
			}

			final ByteBuffer dataChunk = BufferUtils.slice(fw, fwOffset, localDataLength);

			// Just wValue is enough for the address (16 bit), since the RAM is
			// limited to 16KB.
			usbDevice.sendVendorRequest(FX2.VR_FIRMWARE, (short) (fwOffset & 0xFFFF), (short) 0, dataChunk);

			fwLength -= localDataLength;
			fwOffset += localDataLength;
		}

		// Take the FX2's 8051 CPU out of reset.
		resetBuf.put(0, (byte) 0);
		usbDevice.sendVendorRequest(FX2.VR_FIRMWARE, FX2.CPUCS_ADDR, (short) 0, resetBuf);
	}
}
