/*
 * CypressFX2Biasgen.java
 *
 * Created on 23 Jan 2008
 */
package net.sf.jaer.hardwareinterface.usb.cypressfx2libusb;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.io.FileReader;
import java.io.IOException;
import java.io.LineNumberReader;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.concurrent.ArrayBlockingQueue;

import javax.swing.ProgressMonitor;

import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import de.ailis.usb4java.libusb.Device;
import eu.seebetter.ini.chips.ApsDvsChip;
import eu.seebetter.ini.chips.sbret10.IMUSample;

/**
 * Adds functionality of apsDVS sensors to based CypressFX2Biasgen class. The
 * key method is translateEvents that parses
 * the data from the sensor to construct jAER raw events.
 *
 * @author Christian/Tobi
 */
public class ApsDvsHardwareInterface extends CypressFX2Biasgen {

	/** The USB product ID of this device */
	static public final short PID = (short) 0x840D;
	static public final short DID = (short) 0x0002;

	private boolean translateRowOnlyEvents = CypressFX2.prefs.getBoolean(
		"ApsDvsHardwareInterface.translateRowOnlyEvents", false);

	private volatile ArrayBlockingQueue<IMUSample> imuSampleQueue; // this queue
																	// is used
																	// for
																	// holding
																	// imu
																	// samples
																	// sent to
																	// aeReader

	/** Creates a new instance of CypressFX2Biasgen */
	public ApsDvsHardwareInterface(final Device device) {
		super(device);
		imuSampleQueue = new ArrayBlockingQueue<IMUSample>(1);
	}

	/**
	 * Overridden to use PortBit powerDown in biasgen
	 *
	 * @param powerDown
	 *            true to power off masterbias
	 * @throws HardwareInterfaceException
	 */
	@Override
	synchronized public void setPowerDown(final boolean powerDown) throws HardwareInterfaceException {
		if ((chip != null) && (chip instanceof ApsDvsChip)) {
			final ApsDvsChip apsDVSchip = (ApsDvsChip) chip;
			apsDVSchip.setPowerDown(powerDown);
		}
	}

	private byte[] parseHexData(final String firmwareFile) throws IOException {

		byte[] fwBuffer;
		// load firmware file (this is binary file of 8051 firmware)

		CypressFX2.log.info("reading firmware file " + firmwareFile);
		FileReader reader;
		LineNumberReader lineReader;
		String line;
		int length;
		// load firmware file (this is a lattice c file)
		try {

			reader = new FileReader(firmwareFile);
			lineReader = new LineNumberReader(reader);

			line = lineReader.readLine();
			while (!line.startsWith("xdata")) {
				line = lineReader.readLine();
			}
			final int scIndex = line.indexOf(";");
			final int eqIndex = line.indexOf("=");
			int index = 0;
			length = Integer.parseInt(line.substring(eqIndex + 2, scIndex));
			// log.info("File length: " + length);
			String[] tokens;
			fwBuffer = new byte[length];
			Short value;
			while (!line.endsWith("};")) {
				line = lineReader.readLine();
				tokens = line.split("0x");
				// System.out.println(line);
				for (int i = 1; i < tokens.length; i++) {
					value = Short.valueOf(tokens[i].substring(0, 2), 16);
					fwBuffer[index++] = value.byteValue();
					// System.out.println(fwBuffer[index-1]);
				}
			}
			// log.info("index" + index);

			lineReader.close();
		}
		catch (final IOException e) {
			close();
			CypressFX2.log.warning(e.getMessage());
			throw new IOException("can't load binary Cypress FX2 firmware file " + firmwareFile);
		}
		return fwBuffer;
	}

	@Override
	synchronized public void writeCPLDfirmware(final String svfFile) throws HardwareInterfaceException {
		byte[] bytearray;

		try {
			bytearray = parseHexData(svfFile);
		}
		catch (final Exception e) {
			e.printStackTrace();
			return;
		}

		ProgressMonitor progressMonitor = makeProgressMonitor("Writing CPLD configuration - do not unplug", 0,
			bytearray.length);

		final int numChunks = bytearray.length / MAX_CONTROL_XFER_SIZE; // this
																		// is
																		// number
																		// of
																		// full
																		// chunks
																		// to
																		// send
		int addr = 0;

		for (int i = 0; i < numChunks; i++) {
			sendVendorRequest(CypressFX2.VR_DOWNLOAD_FIRMWARE, (short) addr, (short) 0, bytearray, i
				* MAX_CONTROL_XFER_SIZE, MAX_CONTROL_XFER_SIZE);

			addr += MAX_CONTROL_XFER_SIZE; // change address of firmware
											// location

			if (progressMonitor.isCanceled()) {
				progressMonitor = makeProgressMonitor("Writing CPLD configuration - do not unplug", 0, bytearray.length);
			}

			progressMonitor.setProgress(addr);
			progressMonitor.setNote(String.format("sent %d of %d bytes of CPLD configuration", addr, bytearray.length));
		}

		// now send final (short) chunk
		final int numBytesLeft = bytearray.length % MAX_CONTROL_XFER_SIZE; // remainder

		if (numBytesLeft > 0) {
			// send remaining part of firmware
			sendVendorRequest(VR_EEPROM, (short) addr, (short) 0, bytearray, numChunks * MAX_CONTROL_XFER_SIZE,
				numBytesLeft);
		}

		try {
			sendVendorRequest(CypressFX2.VR_DOWNLOAD_FIRMWARE, (short) 0, (short) 1);
		}
		catch (final HardwareInterfaceException e) {
			try {
				Thread.sleep(2000);
				open();
			}
			catch (final Exception ee) {
			}
		}

		final ByteBuffer dataBuffer = sendVendorRequestIN(CypressFX2.VR_DOWNLOAD_FIRMWARE, (short) 0, (short) 0, 10);

		if (dataBuffer.get(1) != 0) {
			final int dataindex = (dataBuffer.get(6) << 24) | (dataBuffer.get(7) << 16) | (dataBuffer.get(8) << 8)
				| (dataBuffer.get(9));
			final int algoindex = (dataBuffer.get(2) << 24) | (dataBuffer.get(3) << 16) | (dataBuffer.get(4) << 8)
				| (dataBuffer.get(5));
			throw new HardwareInterfaceException("Unable to program CPLD, error code: " + dataBuffer.get(1)
				+ " algo index: " + algoindex + " data index " + dataindex);
		}

		progressMonitor.close();
	}

	/**
	 * Starts reader buffer pool thread and enables in endpoints for AEs. This
	 * method is overridden to construct
	 * our own reader with its translateEvents method
	 */
	@Override
	public void startAEReader() throws HardwareInterfaceException { // raphael:
																	// changed
																	// from
																	// private
																	// to
																	// protected,
		// because i need to access this method
		setAeReader(new RetinaAEReader(this));
		allocateAEBuffers();

		getAeReader().startThread(); // arg is number of errors before giving up
		HardwareInterfaceException.clearException();
	}

	boolean gotY = false; // TODO hack for debugging state machine

	/**
	 * If set, then row-only events are transmitted to raw packets from USB
	 * interface
	 *
	 * @param translateRowOnlyEvents
	 *            true to translate these parasitic events.
	 */
	public void setTranslateRowOnlyEvents(final boolean translateRowOnlyEvents) {
		this.translateRowOnlyEvents = translateRowOnlyEvents;
		CypressFX2.prefs.putBoolean("ApsDvsHardwareInterface.translateRowOnlyEvents", translateRowOnlyEvents);
	}

	public boolean isTranslateRowOnlyEvents() {
		return translateRowOnlyEvents;
	}

	/**
	 * This reader understands the format of raw USB data and translates to the
	 * AEPacketRaw
	 */
	public class RetinaAEReader extends CypressFX2.AEReader implements PropertyChangeListener {
		private static final int NONMONOTONIC_WARNING_COUNT = 30; // how many
																	// warnings
																	// to print
																	// after
																	// start or
																	// timestamp
		public static final int IMU_POLLING_INTERVAL_EVENTS = 100;

		public RetinaAEReader(final CypressFX2 cypress) throws HardwareInterfaceException {
			super(cypress);
			resetFrameAddressCounters();
			getSupport().addPropertyChangeListener(CypressFX2.PROPERTY_CHANGE_ASYNC_STATUS_MSG, this);
		}

		/**
		 * Method to translate the UsbIoBuffer for the DVS320 sensor which uses
		 * the 32 bit address space.
		 * <p>
		 * It has a CPLD to timestamp events and uses the CypressFX2 in slave
		 * FIFO mode.
		 * <p>
		 * The DVS320 has a burst mode readout mechanism that outputs a row
		 * address, then all the latched column addresses. The columns are
		 * output left to right. A timestamp is only meaningful at the row
		 * addresses level. Therefore the board timestamps on row address, and
		 * then sends the data in the following sequence: timestamp, row, col,
		 * col, col,....,timestamp,row,col,col...
		 * <p>
		 * Intensity information is transmitted by bit 8, which is set by the
		 * chip The bit encoding of the data is as follows <literal> Address bit
		 * Address bit pattern 0 LSB Y or Polarity ON=1 1 Y1 or LSB X 2 Y2 or X1
		 * 3 Y3 or X2 4 Y4 or X3 5 Y5 or X4 6 Y6 or X5 7 Y7 (MSBY) or X6 8
		 * intensity or X7. This bit is set for a Y address if the intensity
		 * neuron has spiked. This bit is also X7 for X addreses. 9 X8 (MSBX) 10
		 * Y=0, X=1 </literal>
		 *
		 * The two msbs of the raw 16 bit data are used to tag the type of data,
		 * e.g. address, timestamp, or special events wrap or reset host
		 * timestamps. <literal> Address Name 00xx xxxx xxxx xxxx pixel address
		 * 01xx xxxx xxxx xxxx timestamp 10xx xxxx xxxx xxxx wrap 11xx xxxx xxxx
		 * xxxx timestamp reset </literal>
		 *
		 * The msb of the 16 bit timestamp is used to signal a wrap (the actual
		 * timestamp is only 15 bits). The wrapAdd is incremented when an empty
		 * event is received which has the timestamp bit 15 set to one.
		 * <p>
		 * Therefore for a valid event only 15 bits of the 16 transmitted
		 * timestamp bits are valid, bit 15 is the status bit. overflow happens
		 * every 32 ms. This way, no roll overs go by undetected, and the
		 * problem of invalid wraps doesn't arise.
		 *
		 * @param minusEventEffect
		 *            the data buffer
		 * @see #translateEvents
		 */
		static private final byte XBIT = (byte) 0x08;
		static private final byte TRIGGER_BIT = (byte) 0x10;
		public static final int TYPE_WORD_BIT = 0x2000;
		public static final int FRAME_START_BIT = 0x1000;
		private int lasty = 0;
		private int currentts = 0;
		private int lastts = 0;
		private int nonmonotonicTimestampWarningCount = RetinaAEReader.NONMONOTONIC_WARNING_COUNT;

		private int[] countX;
		private int[] countY;
		private final int numReadoutTypes = 3;

		@Override
		protected void translateEvents(final ByteBuffer b) {
			try {
				// data from cDVS is stateful. 2 bytes sent for each word of
				// data can consist of either timestamp, y
				// address, x address, or ADC value.
				// The type of data is determined from bits in these two bytes.

				// if(tobiLogger.isEnabled()==false)
				// tobiLogger.setEnabled(true); //debug
				synchronized (aePacketRawPool) {
					final AEPacketRaw buffer = aePacketRawPool.writeBuffer();

					int bytesSent = b.limit();
					if ((bytesSent % 2) != 0) {
						System.err.println("warning: " + bytesSent + " bytes sent, which is not multiple of 2");
						bytesSent = (bytesSent / 2) * 2; // truncate off any
															// extra part-event
					}

					final int[] addresses = buffer.getAddresses();
					final int[] timestamps = buffer.getTimestamps();
					// log.info("received " + bytesSent + " bytes");
					// write the start of the packet
					buffer.lastCaptureIndex = eventCounter;
					// tobiLogger.log("#packet");
					for (int i = 0; i < bytesSent; i += 2) {
						// tobiLogger.log(String.format("%d %x %x",eventCounter,buf[i],buf[i+1]));
						// // DEBUG
						// int val=(buf[i+1] << 8) + buf[i]; // 16 bit value of
						// data
						final int dataword = (0xff & b.get(i)) | (0xff00 & (b.get(i + 1) << 8)); // data
																									// sent
																									// little
						// endian

						final int code = (b.get(i + 1) & 0xC0) >> 6; // gets two
																		// bits
																		// at
																		// XX00
																		// 0000
																		// 0000
																		// 0000.
						// (val&0xC000)>>>14;
						// log.info("code " + code);
						final int xmask = (ApsDvsChip.XMASK | ApsDvsChip.POLMASK) >>> ApsDvsChip.POLSHIFT;
						switch (code) {
							case 0: // address
								// If the data is an address, we write out an
								// address value if we either get an ADC
								// reading or an x address.
								// We also write a (fake) address if
								// we get two y addresses in a row, which occurs
								// when the on-chip AE state machine
								// doesn't properly function.
								// Here we also read y addresses but do not
								// write out any output address until we get
								// either 1) an x-address, or 2)
								// another y address without intervening
								// x-address.
								// NOTE that because ADC events do not have a
								// timestamp, the size of the addresses and
								// timestamps data are not the same.
								// To simplify data structure handling in
								// AEPacketRaw and AEPacketRawPool,
								// ADC events are timestamped just like
								// address-events. ADC events get the timestamp
								// of
								// the most recently preceeding address-event.
								// NOTE2: unmasked bits are read as 1's from the
								// hardware. Therefore it is crucial to
								// properly mask bits.
								if ((eventCounter >= aeBufferSize) || (buffer.overrunOccuredFlag)) {
									buffer.overrunOccuredFlag = true; // throw
																		// away
																		// events
																		// if we
																		// have
																		// overrun
																		// the
																		// output
									// arrays
								}
								else {
									if ((dataword & RetinaAEReader.TYPE_WORD_BIT) == RetinaAEReader.TYPE_WORD_BIT) {
										if ((dataword & RetinaAEReader.FRAME_START_BIT) == RetinaAEReader.FRAME_START_BIT) {
											resetFrameAddressCounters();
										}
										final int readcycle = (dataword & ApsDvsChip.ADC_READCYCLE_MASK) >> ApsDvsChip.ADC_READCYCLE_SHIFT;
										if (countY[readcycle] >= chip.getSizeY()) {
											countY[readcycle] = 0;
											countX[readcycle]++;
										}
										final int xAddr = (short) (chip.getSizeX() - 1 - countX[readcycle]);
										final int yAddr = (short) (chip.getSizeY() - 1 - countY[readcycle]);
										countY[readcycle]++;
										addresses[eventCounter] = ApsDvsChip.ADDRESS_TYPE_APS
											| (yAddr << ApsDvsChip.YSHIFT) | (xAddr << ApsDvsChip.XSHIFT)
											| (dataword & (ApsDvsChip.ADC_READCYCLE_MASK | ApsDvsChip.ADC_DATA_MASK));
										timestamps[eventCounter] = currentts; // ADC
																				// event
																				// gets
																				// last
																				// timestamp
										eventCounter++;
										// System.out.println("ADC word: " +
										// (dataword&SeeBetter20.ADC_DATA_MASK));
									}
									else if ((b.get(i + 1) & RetinaAEReader.TRIGGER_BIT) == RetinaAEReader.TRIGGER_BIT) {
										addresses[eventCounter] = 256; // combine
																		// current
																		// bits
																		// with
																		// last
																		// y
																		// address
																		// bits
										// and send
										timestamps[eventCounter] = currentts;
										eventCounter++;
									}
									else if ((b.get(i + 1) & RetinaAEReader.XBIT) == RetinaAEReader.XBIT) {// //
										// received
										// an X
										// address,
										// write out
										// event
										// to addresses/timestamps output arrays
										// x adddress
										addresses[eventCounter] = (lasty << ApsDvsChip.YSHIFT)
											| ((dataword & xmask) << ApsDvsChip.POLSHIFT); // combine
																							// current
																							// bits
																							// with
										// last y address bits and
										// send
										timestamps[eventCounter] = currentts; // add
																				// in
																				// the
																				// wrap
																				// offset
																				// and
																				// convert
																				// to
										// 1us tick
										eventCounter++;
										// log.info("X: "+((dataword &
										// ApsDvsChip.XMASK)>>1));
										gotY = false;
									}
									else { // row address came
										if (gotY) { // no col address, last one
													// was row only event
											if (translateRowOnlyEvents) {// make
																			// row-only
																			// event

												addresses[eventCounter] = (lasty << ApsDvsChip.YSHIFT); // combine
												// current bits
												// with last y
												// address bits
												// and send
												timestamps[eventCounter] = currentts; // add
																						// in
																						// the
																						// wrap
																						// offset
																						// and
												// convert to 1us tick
												eventCounter++;
											}

										}
										// y address
										final int ymask = (ApsDvsChip.YMASK >>> ApsDvsChip.YSHIFT);
										lasty = ymask & dataword; // (0xFF &
																	// buf[i]);
																	// //
										gotY = true;
										// log.info("Y: "+lasty+" - data "+dataword+" - mask: "+(ApsDvsChip.YMASK
										// >>>
										// ApsDvsChip.YSHIFT));
									}
								}
								break;
							case 1: // timestamp
								lastts = currentts;
								currentts = ((0x3f & b.get(i + 1)) << 8) | (b.get(i) & 0xff);
								currentts = (TICK_US * (currentts + wrapAdd));
								if ((lastts > currentts) && (nonmonotonicTimestampWarningCount-- > 0)) {
									CypressFX2.log.warning("non-monotonic timestamp: currentts=" + currentts
										+ " lastts=" + lastts + " currentts-lastts=" + (currentts - lastts));
								}
								// log.info("received timestamp");
								break;
							case 2: // wrap
								wrapAdd += 0x4000L;
								// log.info("wrap");
								break;
							case 3: // ts reset event
								nonmonotonicTimestampWarningCount = RetinaAEReader.NONMONOTONIC_WARNING_COUNT;
								resetTimestamps();
								// log.info("timestamp reset");
								break;
						}

						// write IMUSample to AEPacketRaw if we have one
						if ((eventCounter % RetinaAEReader.IMU_POLLING_INTERVAL_EVENTS) == 0) {
							final IMUSample imuSample = imuSampleQueue.poll();
							if (imuSample != null) {
								imuSample.setTimestamp(currentts);
								eventCounter += imuSample.writeToPacket(buffer, eventCounter);
							}
						}
					} // end for

					buffer.setNumEvents(eventCounter);
					// write capture size
					buffer.lastCaptureLength = eventCounter - buffer.lastCaptureIndex;

					// log.info("packet size " + buffer.lastCaptureLength +
					// " number of Y addresses " + numberOfY);
					// if (NumberOfWrapEvents!=0) {
					// System.out.println("Number of wrap events received: "+
					// NumberOfWrapEvents);
					// }
					// System.out.println("wrapAdd : "+ wrapAdd);
				} // sync on aePacketRawPool
			}
			catch (final java.lang.IndexOutOfBoundsException e) {
				CypressFX2.log.warning(e.toString());
			}
		}

		private void resetFrameAddressCounters() {
			if ((countX == null) || (countY == null)) {
				countX = new int[numReadoutTypes];
				countY = new int[numReadoutTypes];
			}
			Arrays.fill(countX, 0, numReadoutTypes, (short) 0);
			Arrays.fill(countY, 0, numReadoutTypes, (short) 0);
		}

		@Override
		public void propertyChange(final PropertyChangeEvent evt) {
			try {
				final ByteBuffer buf = (ByteBuffer) evt.getNewValue();
				try {
					final IMUSample sample = new IMUSample(buf, currentts);
					imuSampleQueue.put(sample);
				}
				catch (final InterruptedException ex) {
					CypressFX2.log.warning("putting IMUSample to queue was interrupted");
				}

			}
			catch (final ClassCastException e) {
				CypressFX2.log.warning("receieved wrong type of data for the IMU: " + e.toString());
			}
		}
	}
}
