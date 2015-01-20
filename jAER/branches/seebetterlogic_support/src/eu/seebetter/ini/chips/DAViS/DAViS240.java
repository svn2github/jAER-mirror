/*
 * created 26 Oct 2008 for new cDVSTest chip
 * adapted apr 2011 for cDVStest30 chip by tobi
 * adapted 25 oct 2011 for SeeBetter10/11 chips by tobi
 */
package eu.seebetter.ini.chips.DAViS;

import java.awt.Font;
import java.awt.geom.Rectangle2D;
import java.beans.PropertyChangeSupport;
import java.util.Iterator;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.media.opengl.GL;
import javax.media.opengl.GL2;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.glu.GLU;
import javax.media.opengl.glu.GLUquadric;
import javax.swing.JFrame;

import net.sf.jaer.Description;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.biasgen.BiasgenHardwareInterface;
import net.sf.jaer.chip.RetinaExtractor;
import net.sf.jaer.event.ApsDvsEvent;
import net.sf.jaer.event.ApsDvsEventPacket;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.TypedEvent;
import net.sf.jaer.eventprocessing.filter.ApsDvsEventFilter;
import net.sf.jaer.eventprocessing.filter.Info;
import net.sf.jaer.eventprocessing.filter.RefractoryFilter;
import net.sf.jaer.graphics.AEFrameChipRenderer;
import net.sf.jaer.graphics.ChipRendererDisplayMethodRGBA;
import net.sf.jaer.graphics.DisplayMethod;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.util.HasPropertyTooltips;
import net.sf.jaer.util.PropertyTooltipSupport;
import net.sf.jaer.util.RemoteControlCommand;
import net.sf.jaer.util.RemoteControlled;
import net.sf.jaer.util.histogram.AbstractHistogram;
import net.sf.jaer.util.histogram.SimpleHistogram;
import ch.unizh.ini.jaer.config.cpld.CPLDInt;

import com.jogamp.opengl.util.awt.TextRenderer;

import eu.seebetter.ini.chips.ApsDvsChip;
import eu.seebetter.ini.chips.DAViS.IMUSample.IncompleteIMUSampleException;

/**
 * <p>
 * DAViS240a/b have 240x180 pixels and are built in 180nm technology. DAViS240a has a rolling shutter APS readout and
 * DAViS240b has global shutter readout (but rolling shutter also possible with DAViS240b with different CPLD logic).
 * Both do APS CDS in digital domain off-chip, on host side, using difference between reset and signal reads.
 * <p>
 *
 * Describes retina and its event extractor and bias generator. Two constructors ara available, the vanilla constructor
 * is used for event playback and the one with a HardwareInterface parameter is useful for live capture.
 * {@link #setHardwareInterface} is used when the hardware interface is constructed after the retina object. The
 * constructor that takes a hardware interface also constructs the biasgen interface.
 *
 * @author tobi, christian
 */
@Description("DAViS240a/b 240x180 pixel APS-DVS DAVIS sensor")
public class DAViS240 extends ApsDvsChip implements RemoteControlled, Observer {
	private final int ADC_NUMBER_OF_TRAILING_ZEROS = Integer.numberOfTrailingZeros(ADC_READCYCLE_MASK); // speedup in
																										// loop
	// following define bit masks for various hardware data types.
	// The hardware interface translateEvents method packs the raw device data into 32 bit 'addresses' and timestamps.
	// timestamps are unwrapped and timestamp resets are handled in translateEvents. Addresses are filled with either AE
	// or ADC data.
	// AEs are filled in according the XMASK, YMASK, XSHIFT, YSHIFT below.
	/**
	 * bit masks/shifts for cDVS AE data
	 */
	private DAViS240DisplayMethod davisDisplayMethod = null;
	private AEFrameChipRenderer apsDVSrenderer;
	private int frameExposureStartTimestampUs = 0; // timestamp of first sample from frame (first sample read after
													// reset released)
	private int frameExposureEndTimestampUs; // end of exposure (first events of signal read)
	private int exposureDurationUs; // internal measured variable, set during rendering. Duration of frame expsosure in
									// us.
	private int frameIntervalUs; // internal measured variable, set during rendering. Time between this frame and
									// previous one.
	/**
	 * holds measured variable in Hz for GUI rendering of rate
	 */
	protected float frameRateHz;
	/**
	 * holds measured variable in ms for GUI rendering
	 */
	protected float exposureMs;
	/**
	 * Holds count of frames obtained by end of frame events
	 */
	private int frameCount = 0;
	private boolean snapshot = false;
	private DAViS240Config config;
	JFrame controlFrame = null;
	public static final short WIDTH = 240;
	public static final short HEIGHT = 180;
	int sx1 = getSizeX() - 1, sy1 = getSizeY() - 1;
	private int autoshotThresholdEvents = getPrefs().getInt("DAViS240.autoshotThresholdEvents", 0);
	private IMUSample imuSample; // latest IMUSample from sensor
	private final String CMD_EXPOSURE = "exposure";
	private final String CMD_EXPOSURE_CC = "exposureCC";
	private final String CMD_RS_SETTLE_CC = "resetSettleCC";

	private AutoExposureController autoExposureController = new AutoExposureController();

	/**
	 * Creates a new instance of cDVSTest20.
	 */
	public DAViS240() {
		setName("DAViS240");
		setDefaultPreferencesFile("biasgenSettings/Davis240a/David240aBasic.xml");
		setEventClass(ApsDvsEvent.class);
		setSizeX(WIDTH);
		setSizeY(HEIGHT);
		setNumCellTypes(3); // two are polarity and last is intensity
		setPixelHeightUm(18.5f);
		setPixelWidthUm(18.5f);

		setEventExtractor(new DAViS240Extractor(this));

		setBiasgen(config = new DAViS240Config(this));

		// hardware interface is ApsDvsHardwareInterface
		apsDVSrenderer = new AEFrameChipRenderer(this);
		apsDVSrenderer.setMaxADC(MAX_ADC);
		setRenderer(apsDVSrenderer);

		davisDisplayMethod = new DAViS240DisplayMethod(this);
		getCanvas().addDisplayMethod(davisDisplayMethod);
		getCanvas().setDisplayMethod(davisDisplayMethod);
		addDefaultEventFilter(ApsDvsEventFilter.class);
		addDefaultEventFilter(HotPixelFilter.class);
		addDefaultEventFilter(RefractoryFilter.class);
		addDefaultEventFilter(Info.class);

		if (getRemoteControl() != null) {
			getRemoteControl()
				.addCommandListener(this, CMD_EXPOSURE, CMD_EXPOSURE + " val - sets exposure. val in ms.");
			getRemoteControl().addCommandListener(this, CMD_EXPOSURE_CC,
				CMD_EXPOSURE_CC + " val - sets exposure. val in clock cycles");
			getRemoteControl().addCommandListener(this, CMD_RS_SETTLE_CC,
				CMD_RS_SETTLE_CC + " val - sets reset settling time. val in clock cycles");
		}
		addObserver(this); // we observe ourselves so that if hardware interface for example calls notifyListeners we
							// get informed
	}

	@Override
	public String processRemoteControlCommand(RemoteControlCommand command, String input) {
		log.info("processing RemoteControlCommand " + command + " with input=" + input);
		if (command == null) {
			return null;
		}
		String[] tokens = input.split(" ");
		if (tokens.length < 2) {
			return input + ": unknown command - did you forget the argument?";
		}
		if ((tokens[1] == null) || (tokens[1].length() == 0)) {
			return input + ": argument too short - need a number";
		}
		float v = 0;
		try {
			v = Float.parseFloat(tokens[1]);
		}
		catch (NumberFormatException e) {
			return input + ": bad argument? Caught " + e.toString();
		}
		String c = command.getCmdName();
		if (c.equals(CMD_EXPOSURE)) {
			config.setExposureDelayMs((int) v);
		}
		else if (c.equals(CMD_EXPOSURE_CC)) {
			config.exposure.set((int) v);
		}
		else if (c.equals(CMD_RS_SETTLE_CC)) {
			config.resSettle.set((int) v);
		}
		else {
			return input + ": unknown command";
		}
		return "successfully processed command " + input;
	}

	@Override
	public void setPowerDown(boolean powerDown) {
		config.powerDown.set(powerDown);
		try {
			config.sendOnChipConfigChain();
		}
		catch (HardwareInterfaceException ex) {
			Logger.getLogger(DAViS240.class.getName()).log(Level.SEVERE, null, ex);
		}
	}

	@Override
	public void setADCEnabled(boolean adcEnabled) {
		config.apsReadoutControl.setAdcEnabled(adcEnabled);
	}

	/**
	 * Creates a new instance of DAViS240
	 *
	 * @param hardwareInterface
	 *            an existing hardware interface. This constructor
	 *            is preferred. It makes a new cDVSTest10Biasgen object to talk to the
	 *            on-chip biasgen.
	 */
	public DAViS240(HardwareInterface hardwareInterface) {
		this();
		setHardwareInterface(hardwareInterface);
	}

	@Override
	public void controlExposure() {
		getAutoExposureController().controlExposure();
	}

	/**
	 * @return the autoExposureController
	 */
	public AutoExposureController getAutoExposureController() {
		return autoExposureController;
	}

	// int pixcnt=0; // TODO debug
	/**
	 * The event extractor. Each pixel has two polarities 0 and 1.
	 *
	 * <p>
	 * The bits in the raw data coming from the device are as follows.
	 * <p>
	 * Bit 0 is polarity, on=1, off=0<br>
	 * Bits 1-9 are x address (max value 320)<br>
	 * Bits 10-17 are y address (max value 240) <br>
	 * <p>
	 */
	public class DAViS240Extractor extends RetinaExtractor {
		private int autoshotEventsSinceLastShot = 0; // autoshot counter
		private int warningCount = 0;
		private static final int WARNING_COUNT_DIVIDER = 10000;

		public DAViS240Extractor(DAViS240 chip) {
			super(chip);
		}

		private IncompleteIMUSampleException incompleteIMUSampleException = null;
		private static final int IMU_WARNING_INTERVAL = 1000;
		private int missedImuSampleCounter = 0;
		private int badImuDataCounter = 0;

		/**
		 * extracts the meaning of the raw events.
		 *
		 * @param in
		 *            the raw events, can be null
		 * @return out the processed events. these are partially processed
		 *         in-place. empty packet is returned if null is supplied as in.
		 */
		@Override
		synchronized public EventPacket extractPacket(AEPacketRaw in) {
			if (!(chip instanceof ApsDvsChip)) {
				return null;
			}
			if (out == null) {
				out = new ApsDvsEventPacket(chip.getEventClass());
			}
			else {
				out.clear();
			}
			out.setRawPacket(in);
			if (in == null) {
				return out;
			}
			int n = in.getNumEvents(); // addresses.length;
			sx1 = chip.getSizeX() - 1;
			sy1 = chip.getSizeY() - 1;

			int[] datas = in.getAddresses();
			int[] timestamps = in.getTimestamps();
			OutputEventIterator outItr = out.outputIterator();
			// NOTE we must make sure we write ApsDvsEvents when we want them, not reuse the IMUSamples

			// at this point the raw data from the USB IN packet has already been digested to extract timestamps,
			// including timestamp wrap events and timestamp resets.
			// The datas array holds the data, which consists of a mixture of AEs and ADC values.
			// Here we extract the datas and leave the timestamps alone.
			// TODO entire rendering / processing approach is not very efficient now
			// System.out.println("Extracting new packet "+out);
			for (int i = 0; i < n; i++) { // TODO implement skipBy/subsampling, but without missing the frame start/end
											// events and still delivering frames
				int data = datas[i];

				if ((incompleteIMUSampleException != null)
					|| ((ApsDvsChip.ADDRESS_TYPE_IMU & data) == ApsDvsChip.ADDRESS_TYPE_IMU)) {
					if (IMUSample.extractSampleTypeCode(data) == 0) { // / only start getting an IMUSample at code 0,
																		// the first sample type
						try {
							IMUSample possibleSample = IMUSample.constructFromAEPacketRaw(in, i,
								incompleteIMUSampleException);
							i += IMUSample.SIZE_EVENTS - 1;
							incompleteIMUSampleException = null;
							imuSample = possibleSample; // asking for sample from AEChip now gives this value, but no
														// access to intermediate IMU samples
							imuSample.imuSampleEvent = true;
							outItr.writeToNextOutput(imuSample); // also write the event out to the next output event
																	// slot
							// System.out.println("at position "+(out.size-1)+" put "+imuSample);
							continue;
						}
						catch (IMUSample.IncompleteIMUSampleException ex) {
							incompleteIMUSampleException = ex;
							if ((missedImuSampleCounter++ % IMU_WARNING_INTERVAL) == 0) {
								log.warning(String.format("%s (obtained %d partial samples so far)", ex.toString(),
									missedImuSampleCounter));
							}
							break; // break out of loop because this packet only contained part of an IMUSample and
									// formed the end of the packet anyhow. Next time we come back here we will complete
									// the IMUSample
						}
						catch (IMUSample.BadIMUDataException ex2) {
							if ((badImuDataCounter++ % IMU_WARNING_INTERVAL) == 0) {
								log.warning(String.format("%s (%d bad samples so far)", ex2.toString(),
									badImuDataCounter));
							}
							incompleteIMUSampleException = null;
							continue; // continue because there may be other data
						}
					}

				}
				else if ((data & ApsDvsChip.ADDRESS_TYPE_MASK) == ApsDvsChip.ADDRESS_TYPE_DVS) {
					// DVS event
					ApsDvsEvent e = nextApsDvsEvent(outItr);
					if ((data & ApsDvsChip.EVENT_TYPE_MASK) == ApsDvsChip.EXTERNAL_INPUT_EVENT_ADDR) {
						e.adcSample = -1; // TODO hack to mark as not an ADC sample
						e.special = true; // TODO special is set here when capturing frames which will mess us up if
											// this is an IMUSample used as a plain ApsDvsEvent
						e.address = data;
						e.timestamp = (timestamps[i]);
						e.setIsDVS(true);
					}
					else {
						e.adcSample = -1; // TODO hack to mark as not an ADC sample
						e.special = false;
						e.address = data;
						e.timestamp = (timestamps[i]);
						e.polarity = (data & POLMASK) == POLMASK ? ApsDvsEvent.Polarity.On : ApsDvsEvent.Polarity.Off;
						e.type = (byte) ((data & POLMASK) == POLMASK ? 1 : 0);
						if ((getHardwareInterface() != null)
							&& (getHardwareInterface() instanceof net.sf.jaer.hardwareinterface.usb.cypressfx3libusb.CypressFX3)) {
							// New logic already rights the address in FPGA.
							e.x = (short) ((data & XMASK) >>> XSHIFT);
						}
						else {
							e.x = (short) (sx1 - ((data & XMASK) >>> XSHIFT));
						}
						e.y = (short) ((data & YMASK) >>> YSHIFT);
						e.setIsDVS(true);
						// System.out.println(data);
						// autoshot triggering
						autoshotEventsSinceLastShot++; // number DVS events captured here
					}
				}
				else if ((data & ApsDvsChip.ADDRESS_TYPE_MASK) == ApsDvsChip.ADDRESS_TYPE_APS) {
					// APS event
					ApsDvsEvent e = nextApsDvsEvent(outItr);
					e.adcSample = data & ADC_DATA_MASK;
					int sampleType = (data & ADC_READCYCLE_MASK) >> ADC_NUMBER_OF_TRAILING_ZEROS;
					switch (sampleType) {
						case 0:
							e.readoutType = ApsDvsEvent.ReadoutType.ResetRead;
							break;
						case 1:
							e.readoutType = ApsDvsEvent.ReadoutType.SignalRead;
							// log.info("got SignalRead event");
							break;
						case 3:
							log.warning("Event with readout cycle null was sent out!");
							break;
						default:
							if ((warningCount < 10) || ((warningCount % WARNING_COUNT_DIVIDER) == 0)) {
								log.warning("Event with unknown readout cycle was sent out! You might be reading a file that had the deprecated C readout mode enabled.");
							}
							warningCount++;
					}
					e.special = false;
					e.timestamp = (timestamps[i]);
					e.address = data;
					e.x = (short) (((data & XMASK) >>> XSHIFT));
					e.y = (short) ((data & YMASK) >>> YSHIFT);
					e.type = (byte) (2);
					boolean pixZero = (e.x == sx1) && (e.y == sy1);// first event of frame (addresses get flipped)
					if ((e.readoutType == ApsDvsEvent.ReadoutType.ResetRead) && pixZero) {
						createApsFlagEvent(outItr, ApsDvsEvent.ReadoutType.SOF, timestamps[i]);
						if (!config.chipConfigChain.configBits[6].isSet()) {
							// rolling shutter start of exposure (SOE)
							createApsFlagEvent(outItr, ApsDvsEvent.ReadoutType.SOE, timestamps[i]);
							frameIntervalUs = e.timestamp - frameExposureStartTimestampUs;
							frameExposureStartTimestampUs = e.timestamp;
						}
					}
					if (config.chipConfigChain.configBits[6].isSet() && e.isResetRead() && (e.x == 0) && (e.y == sy1)) {
						// global shutter start of exposure (SOE)
						createApsFlagEvent(outItr, ApsDvsEvent.ReadoutType.SOE, timestamps[i]);
						frameIntervalUs = e.timestamp - frameExposureStartTimestampUs;
						frameExposureStartTimestampUs = e.timestamp;
					}
					// end of exposure
					if (pixZero && e.isSignalRead()) {
						createApsFlagEvent(outItr, ApsDvsEvent.ReadoutType.EOE, timestamps[i]);
						frameExposureEndTimestampUs = e.timestamp;
						exposureDurationUs = e.timestamp - frameExposureStartTimestampUs;
					}
					if (e.isSignalRead() && (e.x == 0) && (e.y == 0)) {
						// if we use ResetRead+SignalRead+C readout, OR, if we use ResetRead-SignalRead readout and we
						// are at last APS pixel, then write EOF event
						// insert a new "end of frame" event not present in original data
						createApsFlagEvent(outItr, ApsDvsEvent.ReadoutType.EOF, timestamps[i]);
						if (snapshot) {
							snapshot = false;
							config.apsReadoutControl.setAdcEnabled(false);
						}
						setFrameCount(getFrameCount() + 1);
					}
				}
			}
			if ((getAutoshotThresholdEvents() > 0) && (autoshotEventsSinceLastShot > getAutoshotThresholdEvents())) {
				takeSnapshot();
				autoshotEventsSinceLastShot = 0;
			}
			// int imuEventCount=0, realImuEventCount=0;
			// for(Object e:out){
			// if(e instanceof IMUSample){
			// imuEventCount++;
			// IMUSample i=(IMUSample)e;
			// if(i.imuSampleEvent) realImuEventCount++;
			// }
			// }
			// System.out.println(String.format("packet has \ttotal %d, \timu type=%d, \treal imu data=%d events",
			// out.getSize(), imuEventCount, realImuEventCount));
			return out;
		} // extractPacket

		// TODO hack to reuse IMUSample events as ApsDvsEvents holding only APS or DVS data by using the special flags
		private ApsDvsEvent nextApsDvsEvent(OutputEventIterator outItr) {
			ApsDvsEvent e = (ApsDvsEvent) outItr.nextOutput();
			e.special = false;
			if (e instanceof IMUSample) {
				((IMUSample) e).imuSampleEvent = false;
			}
			return e;
		}

		/**
		 * creates a special ApsDvsEvent in output packet just for flagging APS
		 * frame markers such as start of frame, reset, end of frame.
		 *
		 * @param outItr
		 * @param flag
		 * @param timestamp
		 * @return
		 */
		private ApsDvsEvent createApsFlagEvent(OutputEventIterator outItr, ApsDvsEvent.ReadoutType flag, int timestamp) {
			ApsDvsEvent a = nextApsDvsEvent(outItr);
			a.adcSample = 0; // set this effectively as ADC sample even though fake
			a.timestamp = timestamp;
			a.x = -1;
			a.y = -1;
			a.readoutType = flag;
			return a;
		}

		@Override
		public AEPacketRaw reconstructRawPacket(EventPacket packet) {
			if (raw == null) {
				raw = new AEPacketRaw();
			}
			if (!(packet instanceof ApsDvsEventPacket)) {
				return null;
			}
			ApsDvsEventPacket apsDVSpacket = (ApsDvsEventPacket) packet;
			raw.ensureCapacity(packet.getSize());
			raw.setNumEvents(0);
			int[] a = raw.addresses;
			int[] ts = raw.timestamps;
			int n = apsDVSpacket.getSize();
			Iterator evItr = apsDVSpacket.fullIterator();
			int k = 0;
			while (evItr.hasNext()) {
				ApsDvsEvent e = (ApsDvsEvent) evItr.next();
				// not writing out these EOF events (which were synthesized on extraction) results in reconstructed
				// packets with giant time gaps, reason unknown
				if (e.isEndOfFrame()) {
					continue; // these EOF events were synthesized from data in first place
				}
				ts[k] = e.timestamp;
				a[k++] = reconstructRawAddressFromEvent(e);
			}
			raw.setNumEvents(k);
			return raw;
		}

		/**
		 * To handle filtered ApsDvsEvents, this method rewrites the fields of
		 * the raw address encoding x and y addresses to reflect the event's x
		 * and y fields.
		 *
		 * @param e
		 *            the ApsDvsEvent
		 * @return the raw address
		 */
		@Override
		public int reconstructRawAddressFromEvent(TypedEvent e) {
			int address = e.address;
			// if(e.x==0 && e.y==0){
			// log.info("start of frame event "+e);
			// }
			// if(e.x==-1 && e.y==-1){
			// log.info("end of frame event "+e);
			// }
			// e.x came from e.x = (short) (chip.getSizeX()-1-((data & XMASK) >>> XSHIFT)); // for DVS event, no x flip
			// if APS event
			if (((ApsDvsEvent) e).adcSample >= 0) {
				address = (address & ~XMASK) | ((e.x) << XSHIFT);
			}
			else {
				address = (address & ~XMASK) | ((sx1 - e.x) << XSHIFT);
			}
			// e.y came from e.y = (short) ((data & YMASK) >>> YSHIFT);
			address = (address & ~YMASK) | (e.y << YSHIFT);
			return address;
		}

		private void setFrameCount(int i) {
			frameCount = i;
		}
	} // extractor

	/**
	 * overrides the Chip setHardware interface to construct a biasgen if one
	 * doesn't exist already. Sets the hardware interface and the bias
	 * generators hardware interface
	 *
	 * @param hardwareInterface
	 *            the interface
	 */
	@Override
	public void setHardwareInterface(final HardwareInterface hardwareInterface) {
		this.hardwareInterface = hardwareInterface;
		DAViS240Config config;
		try {
			if (getBiasgen() == null) {
				setBiasgen(config = new DAViS240Config(this));
				// now we can addConfigValue the control panel
			}
			else {
				getBiasgen().setHardwareInterface((BiasgenHardwareInterface) hardwareInterface);
			}
		}
		catch (ClassCastException e) {
			log.warning(e.getMessage()
				+ ": probably this chip object has a biasgen but the hardware interface doesn't, ignoring");
		}
	}

	/**
	 * Displays data from SeeBetter test chip SeeBetter10/11.
	 *
	 * @author Tobi
	 */
	public class DAViS240DisplayMethod extends ChipRendererDisplayMethodRGBA {
		private static final int FONTSIZE = 10;
		private static final int FRAME_COUNTER_BAR_LENGTH_FRAMES = 10;

		private TextRenderer exposureRenderer = null;

		public DAViS240DisplayMethod(DAViS240 chip) {
			super(chip.getCanvas());
		}

		@Override
		public void display(GLAutoDrawable drawable) {
			getCanvas().setBorderSpacePixels(50);
			if (exposureRenderer == null) {
				exposureRenderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, FONTSIZE), true, true);
				exposureRenderer.setColor(1, 1, 1, 1);
			}

			super.display(drawable);

			if ((config.videoControl != null) && config.videoControl.displayFrames) {
				GL2 gl = drawable.getGL().getGL2();
				exposureRender(gl);
			}

			// draw sample histogram
			if (showImageHistogram && (renderer instanceof AEFrameChipRenderer)) {
				// System.out.println("drawing hist");
				final int size = 100;
				AbstractHistogram hist = ((AEFrameChipRenderer) renderer).getAdcSampleValueHistogram();
				GL2 gl = drawable.getGL().getGL2();
				gl.glPushAttrib(GL.GL_COLOR_BUFFER_BIT);
				gl.glColor3f(0, 0, 1);
				hist.draw(drawable, exposureRenderer, (sizeX / 2) - (size / 2), (sizeY / 2) + (size / 2), size, size);
				gl.glPopAttrib();
			}

			// Draw last IMU output
			if (config.isDisplayImu() && (chip instanceof DAViS240)) {
				IMUSample imuSample = ((DAViS240) chip).getImuSample();
				if (imuSample != null) {
					imuRender(drawable, imuSample);
				}
			}
		}

		TextRenderer imuTextRenderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 36));
		GLU glu = null;
		GLUquadric accelCircle = null;

		private void imuRender(GLAutoDrawable drawable, IMUSample imuSample) {
			// System.out.println("on rendering: "+imuSample.toString());
			GL2 gl = drawable.getGL().getGL2();
			gl.glPushMatrix();

			gl.glTranslatef(chip.getSizeX() / 2, chip.getSizeY() / 2, 0);
			gl.glLineWidth(3);

			final float vectorScale = 1.5f;
			final float textScale = .2f;
			final float trans = .7f;
			float x, y;

			// gyro pan/tilt
			gl.glColor3f(1f, 0, 1);
			gl.glBegin(GL.GL_LINES);
			gl.glVertex2f(0, 0);
			x = (vectorScale * imuSample.getGyroYawY() * HEIGHT) / IMUSample.getFullScaleGyroDegPerSec();
			y = (vectorScale * imuSample.getGyroTiltX() * HEIGHT) / IMUSample.getFullScaleGyroDegPerSec();
			gl.glVertex2f(x, y);
			gl.glEnd();

			imuTextRenderer.begin3DRendering();
			imuTextRenderer.setColor(1f, 0, 1, trans);
			imuTextRenderer.draw3D(String.format("%.2f,%.2f dps", imuSample.getGyroYawY(), imuSample.getGyroTiltX()),
				x, y + 5, 0, textScale); // x,y,z, scale factor
			imuTextRenderer.end3DRendering();

			// gyro roll
			x = (vectorScale * imuSample.getGyroRollZ() * HEIGHT) / IMUSample.getFullScaleGyroDegPerSec();
			y = chip.getSizeY() * .25f;
			gl.glBegin(GL.GL_LINES);
			gl.glVertex2f(0, y);
			gl.glVertex2f(x, y);
			gl.glEnd();

			imuTextRenderer.begin3DRendering();
			imuTextRenderer.draw3D(String.format("%.2f dps", imuSample.getGyroRollZ()), x, y, 0, textScale);
			imuTextRenderer.end3DRendering();

			// acceleration x,y
			x = (vectorScale * imuSample.getAccelX() * HEIGHT) / IMUSample.getFullScaleAccelG();
			y = (vectorScale * imuSample.getAccelY() * HEIGHT) / IMUSample.getFullScaleAccelG();
			gl.glColor3f(0, 1, 0);
			gl.glBegin(GL.GL_LINES);
			gl.glVertex2f(0, 0);
			gl.glVertex2f(x, y);
			gl.glEnd();

			imuTextRenderer.begin3DRendering();
			imuTextRenderer.setColor(0, .5f, 0, trans);
			imuTextRenderer.draw3D(String.format("%.2f,%.2f g", imuSample.getAccelX(), imuSample.getAccelY()), x, y, 0,
				textScale); // x,y,z, scale factor
			imuTextRenderer.end3DRendering();

			// acceleration z, drawn as circle
			if (glu == null) {
				glu = new GLU();
			}
			if (accelCircle == null) {
				accelCircle = glu.gluNewQuadric();
			}
			final float az = ((vectorScale * imuSample.getAccelZ() * HEIGHT)) / IMUSample.getFullScaleAccelG();
			final float rim = .5f;
			glu.gluQuadricDrawStyle(accelCircle, GLU.GLU_FILL);
			glu.gluDisk(accelCircle, az - rim, az + rim, 16, 1);

			imuTextRenderer.begin3DRendering();
			imuTextRenderer.setColor(0, .5f, 0, trans);
			final String saz = String.format("%.2f g", imuSample.getAccelZ());
			Rectangle2D rect = imuTextRenderer.getBounds(saz);
			imuTextRenderer.draw3D(saz, az, -(float) rect.getHeight() * textScale * 0.5f, 0, textScale);
			imuTextRenderer.end3DRendering();

			// color annotation to show what is being rendered
			imuTextRenderer.begin3DRendering();
			imuTextRenderer.setColor(1, 1, 1, trans);
			final String ratestr = String.format("IMU: timestamp=%-+9.3fs last dtMs=%-6.1fms  avg dtMs=%-6.1fms",
				1e-6f * imuSample.getTimestampUs(), imuSample.getDeltaTimeUs() * .001f,
				IMUSample.getAverageSampleIntervalUs() / 1000);
			Rectangle2D raterect = imuTextRenderer.getBounds(ratestr);
			imuTextRenderer.draw3D(ratestr, -(float) raterect.getWidth() * textScale * 0.5f * .7f, -12, 0,
				textScale * .7f); // x,y,z, scale factor
			imuTextRenderer.end3DRendering();

			gl.glPopMatrix();
		}

		private void exposureRender(GL2 gl) {
			gl.glPushMatrix();

			exposureRenderer.begin3DRendering();
			if (frameIntervalUs > 0) {
				setFrameRateHz((float) 1000000 / frameIntervalUs);
			}
			setExposureMs((float) exposureDurationUs / 1000);
			String s = String.format("Frame: %d; Exposure %.2f ms; Frame rate: %.2f Hz", getFrameCount(), exposureMs,
				frameRateHz);
			exposureRenderer.draw3D(s, 0, HEIGHT + (FONTSIZE / 2), 0, .5f); // x,y,z, scale factor
			exposureRenderer.end3DRendering();

			int nframes = frameCount % FRAME_COUNTER_BAR_LENGTH_FRAMES;
			int rectw = WIDTH / FRAME_COUNTER_BAR_LENGTH_FRAMES;
			gl.glColor4f(1, 1, 1, .5f);
			for (int i = 0; i < nframes; i++) {
				gl.glRectf(nframes * rectw, HEIGHT + 1, ((nframes + 1) * rectw) - 3, (HEIGHT + (FONTSIZE / 2)) - 1);
			}
			gl.glPopMatrix();
		}
	}

	/**
	 * Returns the preferred DisplayMethod, or ChipRendererDisplayMethod if null
	 * preference.
	 *
	 * @return the method, or null.
	 * @see #setPreferredDisplayMethod
	 */
	@Override
	public DisplayMethod getPreferredDisplayMethod() {
		return new ChipRendererDisplayMethodRGBA(getCanvas());
	}

	@Override
	public int getMaxADC() {
		return MAX_ADC;
	}

	/**
	 * Sets the measured frame rate. Does not change parameters, only used for
	 * recording measured quantity and informing GUI listeners.
	 *
	 * @param frameRateHz
	 *            the frameRateHz to set
	 */
	private void setFrameRateHz(float frameRateHz) {
		float old = this.frameRateHz;
		this.frameRateHz = frameRateHz;
		getSupport().firePropertyChange(PROPERTY_FRAME_RATE_HZ, old, this.frameRateHz);
	}

	/**
	 * Sets the measured exposure. Does not change parameters, only used for
	 * recording measured quantity.
	 *
	 * @param exposureMs
	 *            the exposureMs to set
	 */
	private void setExposureMs(float exposureMs) {
		float old = this.exposureMs;
		this.exposureMs = exposureMs;
		getSupport().firePropertyChange(PROPERTY_EXPOSURE_MS, old, this.exposureMs);
	}

	@Override
	public float getFrameRateHz() {
		return frameRateHz;
	}

	@Override
	public float getExposureMs() {
		return exposureMs;
	}

	@Override
	public int getFrameExposureStartTimestampUs() {
		return frameExposureStartTimestampUs;
	}

	@Override
	public int getFrameExposureEndTimestampUs() {
		return frameExposureEndTimestampUs;
	}

	/**
	 * Returns the frame counter. This value is set on each end-of-frame sample.
	 * It increases without bound and is not affected by rewinding a played-back recording, for instance.
	 *
	 * @return the frameCount
	 */
	@Override
	public int getFrameCount() {
		return frameCount;
	}

	/**
	 * Triggers shot of one APS frame
	 */
	@Override
	public void takeSnapshot() {
		snapshot = true;
		config.apsReadoutControl.setAdcEnabled(true);
	}

	/**
	 * Sets threshold for shooting a frame automatically
	 *
	 * @param thresholdEvents
	 *            the number of events to trigger shot on. Less than
	 *            or equal to zero disables auto-shot.
	 */
	@Override
	public void setAutoshotThresholdEvents(int thresholdEvents) {
		if (thresholdEvents < 0) {
			thresholdEvents = 0;
		}
		autoshotThresholdEvents = thresholdEvents;
		getPrefs().putInt("DAViS240.autoshotThresholdEvents", thresholdEvents);
		if (autoshotThresholdEvents == 0) {
			config.runAdc.set(true);
		}
	}

	/**
	 * Returns threshold for auto-shot.
	 *
	 * @return events to shoot frame
	 */
	@Override
	public int getAutoshotThresholdEvents() {
		return autoshotThresholdEvents;
	}

	@Override
	public void setAutoExposureEnabled(boolean yes) {
		getAutoExposureController().setAutoExposureEnabled(yes);
	}

	@Override
	public boolean isAutoExposureEnabled() {
		return getAutoExposureController().isAutoExposureEnabled();
	}

	private boolean showImageHistogram = getPrefs().getBoolean("DAViS240.showImageHistogram", false);

	@Override
	public boolean isShowImageHistogram() {
		return showImageHistogram;
	}

	@Override
	public void setShowImageHistogram(boolean yes) {
		showImageHistogram = yes;
		getPrefs().putBoolean("DAViS240.showImageHistogram", yes);
	}

	/**
	 * Controls exposure automatically to try to optimize captured gray levels
	 *
	 */
	public class AutoExposureController implements HasPropertyTooltips { // TODO not implemented yet
		private boolean autoExposureEnabled = getPrefs().getBoolean("autoExposureEnabled", false);

		private float expDelta = .05f; // exposure change if incorrectly exposed
		private float underOverFractionThreshold = 0.2f; // threshold for fraction of total pixels that are underexposed
															// or overexposed
		private PropertyTooltipSupport tooltipSupport = new PropertyTooltipSupport();
		private PropertyChangeSupport propertyChangeSupport = new PropertyChangeSupport(this);
		SimpleHistogram hist = null;
		SimpleHistogram.Statistics stats = null;
		private float lowBoundary = getPrefs().getFloat("AutoExposureController.lowBoundary", 0.1f);
		private float highBoundary = getPrefs().getFloat("AutoExposureController.highBoundary", 0.9f);

		public AutoExposureController() {
			tooltipSupport.setPropertyTooltip("expDelta", "fractional change of exposure when under or overexposed");
			tooltipSupport.setPropertyTooltip("underOverFractionThreshold",
				"fraction of pixel values under xor over exposed to trigger exposure change");
			tooltipSupport.setPropertyTooltip("lowBoundary", "Upper edge of histogram range considered as low values");
			tooltipSupport
				.setPropertyTooltip("highBoundary", "Lower edge of histogram range considered as high values");
			tooltipSupport.setPropertyTooltip("autoExposureEnabled",
				"Exposure time is automatically controlled when this flag is true");
		}

		@Override
		public String getPropertyTooltip(String propertyName) {
			return tooltipSupport.getPropertyTooltip(propertyName);
		}

		public void setAutoExposureEnabled(boolean yes) {
			boolean old = this.autoExposureEnabled;
			this.autoExposureEnabled = yes;
			propertyChangeSupport.firePropertyChange("autoExposureEnabled", old, yes);
			getPrefs().putBoolean("autoExposureEnabled", yes);
		}

		public boolean isAutoExposureEnabled() {
			return this.autoExposureEnabled;
		}

		public void controlExposure() {
			if (!autoExposureEnabled) {
				return;
			}
			hist = apsDVSrenderer.getAdcSampleValueHistogram();
			if (hist == null) {
				return;
			}
			stats = hist.getStatistics();
			if (stats == null) {
				return;
			}
			stats.setLowBoundary(lowBoundary);
			stats.setHighBoundary(highBoundary);
			hist.computeStatistics();
			CPLDInt exposure = config.exposure;

			int currentExposure = exposure.get(), newExposure = 0;
			if ((stats.fracLow >= underOverFractionThreshold) && (stats.fracHigh < underOverFractionThreshold)) {
				newExposure = Math.round(currentExposure * (1 + expDelta));
				if (newExposure == currentExposure) {
					newExposure++; // ensure increase
				}
				if (newExposure > exposure.getMax()) {
					newExposure = exposure.getMax();
				}
				if (newExposure != currentExposure) {
					exposure.set(newExposure);
				}
				log.log(
					Level.INFO,
					"Underexposed: {0}\n{1}",
					new Object[] { stats.toString(),
						String.format("oldExposure=%8d newExposure=%8d", currentExposure, newExposure) });
			}
			else if ((stats.fracLow < underOverFractionThreshold) && (stats.fracHigh >= underOverFractionThreshold)) {
				newExposure = Math.round(currentExposure * (1 - expDelta));
				if (newExposure == currentExposure) {
					newExposure--; // ensure decrease even with rounding.
				}
				if (newExposure < exposure.getMin()) {
					newExposure = exposure.getMin();
				}
				if (newExposure != currentExposure) {
					exposure.set(newExposure);
				}
				log.log(
					Level.INFO,
					"Overexposed: {0}\n{1}",
					new Object[] { stats.toString(),
						String.format("oldExposure=%8d newExposure=%8d", currentExposure, newExposure) });
			}
			else {
				// log.info(stats.toString());
			}
		}

		/**
		 * Gets by what relative amount the exposure is changed on each frame if
		 * under or over exposed.
		 *
		 * @return the expDelta
		 */
		public float getExpDelta() {
			return expDelta;
		}

		/**
		 * Sets by what relative amount the exposure is changed on each frame if
		 * under or over exposed.
		 *
		 * @param expDelta
		 *            the expDelta to set
		 */
		public void setExpDelta(float expDelta) {
			this.expDelta = expDelta;
			getPrefs().putFloat("expDelta", expDelta);
		}

		/**
		 * Gets the fraction of pixel values that must be under xor over exposed
		 * to change exposure automatically.
		 *
		 * @return the underOverFractionThreshold
		 */
		public float getUnderOverFractionThreshold() {
			return underOverFractionThreshold;
		}

		/**
		 * Gets the fraction of pixel values that must be under xor over exposed
		 * to change exposure automatically.
		 *
		 * @param underOverFractionThreshold
		 *            the underOverFractionThreshold to
		 *            set
		 */
		public void setUnderOverFractionThreshold(float underOverFractionThreshold) {
			this.underOverFractionThreshold = underOverFractionThreshold;
			getPrefs().putFloat("underOverFractionThreshold", underOverFractionThreshold);
		}

		public float getLowBoundary() {
			return lowBoundary;
		}

		public void setLowBoundary(float lowBoundary) {
			this.lowBoundary = lowBoundary;
			getPrefs().putFloat("AutoExposureController.lowBoundary", lowBoundary);
		}

		public float getHighBoundary() {
			return highBoundary;
		}

		public void setHighBoundary(float highBoundary) {
			this.highBoundary = highBoundary;
			getPrefs().putFloat("AutoExposureController.highBoundary", highBoundary);
		}

		/**
		 * @return the propertyChangeSupport
		 */
		public PropertyChangeSupport getPropertyChangeSupport() {
			return propertyChangeSupport;
		}
	}

	/**
	 * Returns the current Inertial Measurement Unit sample.
	 *
	 * @return the imuSample, or null if there is no sample
	 */
	public IMUSample getImuSample() {
		return imuSample;
	}

	@Override
	public void update(Observable o, Object arg) {
		// TODO Auto-generated method stub
	}
}
