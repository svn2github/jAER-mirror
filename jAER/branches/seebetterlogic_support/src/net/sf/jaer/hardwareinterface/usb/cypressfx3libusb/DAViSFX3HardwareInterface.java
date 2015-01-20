/*
 * CypressFX3Biasgen.java
 *
 * Created on 23 Jan 2008
 */
package net.sf.jaer.hardwareinterface.usb.cypressfx3libusb;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;
import java.util.Arrays;

import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

import org.usb4java.Device;

import eu.seebetter.ini.chips.ApsDvsChip;
import eu.seebetter.ini.chips.DAViS.IMUSample;

/**
 * Adds functionality of apsDVS sensors to based CypressFX3Biasgen class. The
 * key method is translateEvents that parses
 * the data from the sensor to construct jAER raw events.
 *
 * @author Christian/Tobi
 */
public class DAViSFX3HardwareInterface extends CypressFX3Biasgen {

	protected DAViSFX3HardwareInterface(final Device device) {
		super(device);
	}

	/** The USB product ID of this device */
	static public final short PID = (short) 0x841A;
	static public final short DID = (short) 0x0000;

	/**
	 * Starts reader buffer pool thread and enables in endpoints for AEs. This
	 * method is overridden to construct
	 * our own reader with its translateEvents method
	 */
	@Override
	public void startAEReader() throws HardwareInterfaceException {
		setAeReader(new RetinaAEReader(this));
		allocateAEBuffers();

		getAeReader().startThread(); // arg is number of errors before giving up
		HardwareInterfaceException.clearException();
	}

	/**
	 * This reader understands the format of raw USB data and translates to the
	 * AEPacketRaw
	 */
	public class RetinaAEReader extends CypressFX3.AEReader implements PropertyChangeListener {
		private int wrapAdd;
		private int lastTimestamp;
		private int currentTimestamp;

		private int dvsTimestamp;
		private int dvsLastY;
		private boolean dvsGotY;

		private static final int APS_READOUT_TYPES_NUM = 2;
		private static final int APS_READOUT_RESET = 0;
		private static final int APS_READOUT_SIGNAL = 1;
		private boolean apsGlobalShutter;
		private boolean apsResetRead;
		private int apsCurrentReadoutType;
		private short[] apsCountX;
		private short[] apsCountY;
		private int apsTimestamp; // Need to preserve this for later events.

		private static final int IMU_DATA_LENGTH = 7;
		private final short[] imuEvents;
		private int imuCount;
		private int imuTmpData;
		private int imuTimestamp; // Need to preserve this for later events.

		public RetinaAEReader(final CypressFX3 cypress) throws HardwareInterfaceException {
			super(cypress);

			apsCountX = new short[APS_READOUT_TYPES_NUM];
			apsCountY = new short[APS_READOUT_TYPES_NUM];

			initFrame();

			imuEvents = new short[IMU_DATA_LENGTH];
		}

		private void checkMonotonicTimestamp() {
			if (currentTimestamp <= lastTimestamp) {
				CypressFX3.log.severe(toString() + ": non strictly-monotonic timestamp detected: lastTimestamp="
					+ lastTimestamp + ", currentTimestamp=" + currentTimestamp + ", difference="
					+ (lastTimestamp - currentTimestamp) + ".");
			}
		}

		private void initFrame() {
			apsCurrentReadoutType = APS_READOUT_RESET;
			Arrays.fill(apsCountX, 0, APS_READOUT_TYPES_NUM, (short) 0);
			Arrays.fill(apsCountY, 0, APS_READOUT_TYPES_NUM, (short) 0);
		}

		@Override
		protected void translateEvents(final ByteBuffer b) {
			synchronized (aePacketRawPool) {
				final AEPacketRaw buffer = aePacketRawPool.writeBuffer();

				// Truncate off any extra partial event.
				if ((b.limit() & 0x01) != 0) {
					CypressFX3.log.severe(b.limit() + " bytes received via USB, which is not a multiple of two.");
					b.limit(b.limit() & ~0x01);
				}

				final int[] addresses = buffer.getAddresses();
				final int[] timestamps = buffer.getTimestamps();

				buffer.lastCaptureIndex = eventCounter;

				final ShortBuffer sBuf = b.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();

				for (int i = 0; i < sBuf.limit(); i++) {
					if ((eventCounter >= aeBufferSize) || (buffer.overrunOccuredFlag)) {
						buffer.overrunOccuredFlag = true;

						// Throw away the rest on buffer overrun.
						continue;
					}

					final short event = sBuf.get(i);

					// Check if timestamp
					if ((event & 0x8000) != 0) {
						// Is a timestamp! Expand to 32 bits. (Tick is 1us already.)
						lastTimestamp = currentTimestamp;
						currentTimestamp = wrapAdd + (event & 0x7FFF);

						// Check monotonicity of timestamps.
						checkMonotonicTimestamp();
					}
					else {
						// Look at the code, to determine event and data
						// type
						final byte code = (byte) ((event & 0x7000) >>> 12);
						final short data = (short) (event & 0x0FFF);

						switch (code) {
							case 0: // Special event
								switch (data) {
									case 0: // Ignore this, but log it.
										CypressFX3.log.severe("Caught special reserved event!");
										break;

									case 1: // Timetamp reset
										wrapAdd = 0;
										lastTimestamp = 0;
										currentTimestamp = 0;
										dvsTimestamp = 0;
										apsTimestamp = 0;
										imuTimestamp = 0;

										CypressFX3.log.info("Timestamp reset event received on " + super.toString());
										break;

									case 2: // External input (falling edge)
									case 3: // External input (rising edge)
									case 4: // External input (pulse)
										CypressFX3.log.fine("External input event received.");

										addresses[eventCounter] = ApsDvsChip.EXTERNAL_INPUT_EVENT_ADDR;
										timestamps[eventCounter++] = currentTimestamp;
										break;

									case 5: // IMU Start (6 axes)
										CypressFX3.log.fine("IMU6 Start event received.");

										imuCount = 0;
										imuTimestamp = currentTimestamp;

										break;

									case 7: // IMU End
										CypressFX3.log.fine("IMU End event received.");

										if (imuCount == (2 * IMU_DATA_LENGTH)) {
											final IMUSample imuSample = new IMUSample(imuTimestamp, imuEvents);
											eventCounter += imuSample.writeToPacket(buffer, eventCounter);
										}
										else {
											// TODO: CypressFX3.log.info("IMU End: failed to validate IMU sample count ("
											//	+ imuCount + "), discarding samples.");
										}
										break;

									case 8: // APS Global Shutter Frame Start
										CypressFX3.log.fine("APS GS Frame Start event received.");
										apsGlobalShutter = true;
										apsResetRead = true;

										initFrame();
										apsTimestamp = currentTimestamp;

										break;

									case 9: // APS Rolling Shutter Frame Start
										CypressFX3.log.fine("APS RS Frame Start event received.");
										apsGlobalShutter = false;
										apsResetRead = true;

										initFrame();
										apsTimestamp = currentTimestamp;

										break;

									case 10: // APS Frame End
										CypressFX3.log.fine("APS Frame End event received.");

										for (int j = 0; j < APS_READOUT_TYPES_NUM; j++) {
											int checkValue = chip.getSizeX();

											// Check reset read against zero if
											// disabled.
											if ((j == APS_READOUT_RESET) && !apsResetRead) {
												checkValue = 0;
											}

											if (apsCountX[j] != checkValue) {
												CypressFX3.log.severe("APS Frame End: wrong column count [" + j + " - "
													+ apsCountX[j] + "] detected.");
											}
										}

										apsTimestamp = currentTimestamp;

										break;

									case 11: // APS Reset Column Start
										CypressFX3.log.fine("APS Reset Column Start event received.");

										apsCurrentReadoutType = APS_READOUT_RESET;
										apsCountY[apsCurrentReadoutType] = 0;
										apsTimestamp = currentTimestamp;

										break;

									case 12: // APS Signal Column Start
										CypressFX3.log.fine("APS Signal Column Start event received.");

										apsCurrentReadoutType = APS_READOUT_SIGNAL;
										apsCountY[apsCurrentReadoutType] = 0;
										apsTimestamp = currentTimestamp;

										break;

									case 13: // APS Column End
										CypressFX3.log.fine("APS Column End event received.");

										if (apsCountY[apsCurrentReadoutType] != chip.getSizeY()) {
											CypressFX3.log.severe("APS Column End: wrong row count ["
												+ apsCurrentReadoutType + " - " + apsCountY[apsCurrentReadoutType]
												+ "] detected.");
										}

										apsCountX[apsCurrentReadoutType]++;
										apsTimestamp = currentTimestamp;

										break;

									case 14: // APS Global Shutter Frame Start with no Reset Read
										CypressFX3.log.fine("APS GS NORST Frame Start event received.");
										apsGlobalShutter = true;
										apsResetRead = false;

										initFrame();
										apsTimestamp = currentTimestamp;

										break;

									case 15: // APS Rolling Shutter Frame Start with no Reset Read
										CypressFX3.log.fine("APS RS NORST Frame Start event received.");
										apsGlobalShutter = false;
										apsResetRead = false;

										initFrame();
										apsTimestamp = currentTimestamp;

										break;

									case 16:
									case 17:
									case 18:
									case 19:
									case 20:
									case 21:
									case 22:
									case 23:
									case 24:
									case 25:
									case 26:
									case 27:
									case 28:
									case 29:
									case 30:
									case 31:
										CypressFX3.log.fine("IMU Scale Config event (" + data + ") received.");

										// At this point the IMU event count should be zero (reset by start).
										if (imuCount != 0) {
											CypressFX3.log
												.info("IMU Scale Config: previous IMU start event missed, attempting recovery.");
										}

										// TODO: this is ignored for now.
										// Accel/Gyro Scale is not taken into consideration at this point.

										break;

									default:
										CypressFX3.log.severe("Caught special event that can't be handled.");
										break;
								}
								break;

							case 1: // Y address
								// Check range conformity.
								if (data >= chip.getSizeY()) {
									CypressFX3.log.severe("DVS: Y address out of range (0-" + (chip.getSizeY() - 1)
										+ "): " + data + ".");
									break; // Skip invalid Y address (don't update lastY).
								}

								if (dvsGotY) {
									addresses[eventCounter] = ((dvsLastY << ApsDvsChip.YSHIFT) & ApsDvsChip.YMASK);
									timestamps[eventCounter++] = dvsTimestamp;
									CypressFX3.log.info("DVS: row-only event received for address Y=" + dvsLastY + ".");
								}

								dvsLastY = data;
								dvsGotY = true;
								dvsTimestamp = currentTimestamp;

								break;

							case 2: // X address, Polarity OFF
							case 3: // X address, Polarity ON
								// Check range conformity.
								if (data >= chip.getSizeX()) {
									CypressFX3.log.severe("DVS: X address out of range (0-" + (chip.getSizeX() - 1)
										+ "): " + data + ".");
									break; // Skip invalid event.
								}

								addresses[eventCounter] = ((dvsLastY << ApsDvsChip.YSHIFT) & ApsDvsChip.YMASK)
									| ((data << ApsDvsChip.XSHIFT) & ApsDvsChip.XMASK)
									| (((code & 0x01) << ApsDvsChip.POLSHIFT) & ApsDvsChip.POLMASK);
								timestamps[eventCounter++] = dvsTimestamp;

								dvsGotY = false;

								break;

							case 4: // APS ADC sample
								// Let's check that apsCountY is not above the maximum. This could happen
								// if start/end of column events are discarded (no wait on transfer stall).
								if (apsCountY[apsCurrentReadoutType] >= chip.getSizeY()) {
									CypressFX3.log
										.fine("APS ADC sample: row count is at maximum, discarding further samples.");
									break;
								}

								int xPos = chip.getSizeX() - 1 - apsCountX[apsCurrentReadoutType];
								int yPos = chip.getSizeY() - 1 - apsCountY[apsCurrentReadoutType];

								apsCountY[apsCurrentReadoutType]++;

								addresses[eventCounter] = ApsDvsChip.ADDRESS_TYPE_APS
									| ((yPos << ApsDvsChip.YSHIFT) & ApsDvsChip.YMASK)
									| ((xPos << ApsDvsChip.XSHIFT) & ApsDvsChip.XMASK)
									| ((apsCurrentReadoutType << ApsDvsChip.ADC_READCYCLE_SHIFT) & ApsDvsChip.ADC_READCYCLE_MASK)
									| (data & ApsDvsChip.ADC_DATA_MASK);
								timestamps[eventCounter++] = apsTimestamp;

								break;

							case 5: // Misc 8bit data, used currently only
								// for IMU events in DAVIS FX3 boards.
								final byte misc8Code = (byte) ((data & 0x0F00) >>> 8);
								final byte misc8Data = (byte) (data & 0x00FF);

								switch (misc8Code) {
									case 0:
										// TODO: ignore for now.
										break;

									default:
										CypressFX3.log.severe("Caught Misc8 event that can't be handled.");
										break;
								}

								break;

							case 7: // Timestamp wrap
								// Each wrap is 2^15 us (~32ms), and we have
								// to multiply it with the wrap counter,
								// which is located in the data part of this
								// event.
								wrapAdd += (0x8000L * data);

								lastTimestamp = currentTimestamp;
								currentTimestamp = wrapAdd;

								// Check monotonicity of timestamps.
								checkMonotonicTimestamp();

								CypressFX3.log.fine(String.format(
									"Timestamp wrap event received on %s with multiplier of %d.", super.toString(),
									data));
								break;

							default:
								CypressFX3.log.severe("Caught event that can't be handled.");
								break;
						}
					}
				} // end loop over usb data buffer

				buffer.setNumEvents(eventCounter);
				// write capture size
				buffer.lastCaptureLength = eventCounter - buffer.lastCaptureIndex;
			} // sync on aePacketRawPool
		}

		@Override
		public void propertyChange(final PropertyChangeEvent arg0) {
			// Do nothing here, IMU comes directly via event-stream.
		}
	}
}
