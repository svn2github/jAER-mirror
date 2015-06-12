package net.sf.jaer.controllers;

import java.nio.ByteBuffer;

import javafx.concurrent.Task;
import javafx.event.EventHandler;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import net.sf.jaer.GUISupport;
import net.sf.jaer.UsbDevice;

import org.usb4java.BufferUtils;

public class DeviceEraser extends Controller {
	public DeviceEraser(final UsbDevice device) {
		super(device);
	}

	@Override
	public VBox generateGUI() {
		final VBox firmwareFlashGUI = new VBox(10);

		GUISupport.addLabel(firmwareFlashGUI, "For older devices, we only support erasing the EEPROM.",
			"Erase device EEPROM, so that it is again an FX2 blank device after re-plugging.", null, null);

		GUISupport.addButtonWithMouseClickedHandler(firmwareFlashGUI, "Erase EEPROM", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					GUISupport.showDialogProgress(eraseEEPROMTask);

					final Thread t = new Thread(eraseEEPROMTask);
					t.setDaemon(true);
					t.start();
				}
			});

		return (firmwareFlashGUI);
	}

	private static final byte VR_EEPROM = (byte) 0xA2;
	private static final int MAX_TRANSFER_SIZE = 4096;
	private static final int MAX_EEPROM_SIZE = 32 * 1024;

	private final Task<Void> eraseEEPROMTask = new Task<Void>() {
		@Override
		protected Void call() throws Exception {
			updateProgress(0, 100);

			// Generate empty ByteBuffer (all zeros) to send to EEPROM.
			final ByteBuffer eraser = BufferUtils.allocateByteBuffer(DeviceEraser.MAX_TRANSFER_SIZE);
			eraser.put(new byte[DeviceEraser.MAX_TRANSFER_SIZE]);
			eraser.position(0); // Reset position to initial value.

			// Send out the actual data to the FX2 EEPROM, in 4 KB chunks.
			int fwLength = DeviceEraser.MAX_EEPROM_SIZE;
			int fwOffset = 0;

			// Support progress counter (98% allocated to app).
			updateProgress(2, 100);
			final double progressPerKB = 98.0 / (fwLength / 1024.0);

			while (fwLength > 0) {
				usbDevice.sendVendorRequest(DeviceEraser.VR_EEPROM, (short) (fwOffset & 0xFFFF), (short) 0, eraser);

				fwLength -= DeviceEraser.MAX_TRANSFER_SIZE;
				fwOffset += DeviceEraser.MAX_TRANSFER_SIZE;

				// Update progress based on index (reached length).
				updateProgress((long) (((fwOffset / 1024.0) * progressPerKB) + 2.0), 100);
			}

			updateProgress(100, 100);

			done();

			GUISupport.showDialogInformation("Operation completed successfully!");

			return null;
		}
	};
}
