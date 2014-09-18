package net.sf.jaer.controllers;

import java.nio.ByteBuffer;

import javafx.event.EventHandler;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import net.sf.jaer.GUISupport;
import net.sf.jaer.UsbDevice;

import org.usb4java.BufferUtils;

public class DVS128_FX2 extends Controller {
	public DVS128_FX2(final UsbDevice device) {
		super(device);
	}

	@Override
	public VBox generateGUI() {
		final VBox firmwareFlashGUI = new VBox(10);

		GUISupport.addLabel(firmwareFlashGUI, "On DVS 128, we only support erasing the EEPROM.",
			"Erase DVS128 EEPROM, so that it is again an FX2 blank device after re-plugging.", null, null);

		GUISupport.addButtonWithMouseClickedHandler(firmwareFlashGUI, "Erase EEPROM", true, null,
			new EventHandler<MouseEvent>() {
				@Override
				public void handle(@SuppressWarnings("unused") final MouseEvent arg0) {
					try {
						eraseEEPROM();
					}
					catch (final Exception e) {
						GUISupport.showDialogException(e);
						return;
					}
				}
			});

		return (firmwareFlashGUI);
	}

	private static final byte VR_EEPROM = (byte) 0xA2;
	private static final int MAX_TRANSFER_SIZE = 4096;
	private static final int MAX_EEPROM_SIZE = 32 * 1024;

	private void eraseEEPROM() throws Exception {
		// Generate empty ByteBuffer (all zeros) to send to EEPROM.
		final ByteBuffer eraser = BufferUtils.allocateByteBuffer(DVS128_FX2.MAX_TRANSFER_SIZE);
		eraser.put(new byte[DVS128_FX2.MAX_TRANSFER_SIZE]);
		eraser.position(0); // Reset position to initial value.

		// Send out the actual data to the FX2 EEPROM, in 4 KB chunks.
		int fwLength = DVS128_FX2.MAX_EEPROM_SIZE;
		int fwOffset = 0;

		while (fwLength > 0) {
			usbDevice.sendVendorRequest(DVS128_FX2.VR_EEPROM, (short) (fwOffset & 0xFFFF), (short) 0, eraser);

			fwLength -= DVS128_FX2.MAX_TRANSFER_SIZE;
			fwOffset += DVS128_FX2.MAX_TRANSFER_SIZE;
		}
	}
}
