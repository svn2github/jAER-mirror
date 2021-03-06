/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.seebetter.ini.chips.davis;

import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.chip.Chip;
import net.sf.jaer.event.ApsDvsEvent;
import net.sf.jaer.event.ApsDvsEventPacket;
import net.sf.jaer.event.ApsDvsEventRGBW;
import net.sf.jaer.event.ApsDvsEventRGBW.ColorFilter;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.TypedEvent;
import eu.seebetter.ini.chips.DavisChip;
import eu.seebetter.ini.chips.davis.imu.IMUSample;

/**
 * CDAVIS camera with heterogenous mixture of DAVIS and RGB APS global shutter
 * pixels camera
 *
 * @author Chenghan Li, Luca Longinotti, Tobi Delbruck
 */
@Description("DAVIS APS-DVS camera with RGBW CFA color filter array and 640x480 APS pixels and 320x240 DAVIS pixels")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class DavisRGBW640 extends Davis346BaseCamera {

    public static final short WIDTH_PIXELS = 640;
    public static final short HEIGHT_PIXELS = 480;
    protected DavisRGBW640Config davisConfig;

    public DavisRGBW640() {
        setName("DavisRGBW640");
        setDefaultPreferencesFile("biasgenSettings/DavisRGBW640/DavisRGBW640.xml");
        setSizeX(WIDTH_PIXELS);
        setSizeY(HEIGHT_PIXELS);

        setEventClass(ApsDvsEventRGBW.class);

        setBiasgen(davisConfig = new DavisRGBW640Config(this));

        setEventExtractor(new DavisRGBWEventExtractor(this));

        apsDVSrenderer = new DavisRGBW640Renderer(this); // must be called after configuration is constructed, because
        // it needs to know if frames are enabled to reset pixmap
        apsDVSrenderer.setMaxADC(DavisChip.MAX_ADC);
        setRenderer(apsDVSrenderer);
    }

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
    public class DavisRGBWEventExtractor extends DavisBaseCamera.DavisEventExtractor {

        public DavisRGBWEventExtractor(DavisBaseCamera chip) {
            super(chip);
        }

        /**
         * extracts the meaning of the raw events.
         *
         * @param in the raw events, can be null
         * @return out the processed events. these are partially processed
         * in-place. empty packet is returned if null is supplied as in.
         */
        @Override
        synchronized public EventPacket extractPacket(final AEPacketRaw in) {
            if (!(chip instanceof DavisChip)) {
                return null;
            }
            if (out == null) {
                out = new ApsDvsEventPacket(chip.getEventClass());
            } else {
                out.clear();
            }
            out.setRawPacket(in);
            if (in == null) {
                return out;
            }
            final int n = in.getNumEvents(); // addresses.length;
            int sx1 = chip.getSizeX() - 1;
            int sy1 = chip.getSizeY() - 1;

            final int[] datas = in.getAddresses();
            final int[] timestamps = in.getTimestamps();
            final OutputEventIterator outItr = out.outputIterator();
			// NOTE we must make sure we write ApsDvsEventRGBWs when we want them, not reuse the IMUSamples

			// at this point the raw data from the USB IN packet has already been digested to extract timestamps,
            // including timestamp wrap events and timestamp resets.
            // The datas array holds the data, which consists of a mixture of AEs and ADC values.
            // Here we extract the datas and leave the timestamps alone.
            // TODO entire rendering / processing approach is not very efficient now
            // System.out.println("Extracting new packet "+out);
            for (int i = 0; i < n; i++) { // TODO implement skipBy/subsampling, but without missing the frame start/end
                // events and still delivering frames
                final int data = datas[i];

                if ((incompleteIMUSampleException != null)
                        || ((DavisChip.ADDRESS_TYPE_IMU & data) == DavisChip.ADDRESS_TYPE_IMU)) {
                    if (IMUSample.extractSampleTypeCode(data) == 0) { // / only start getting an IMUSample at code 0,
                        // the first sample type
                        try {
                            final IMUSample possibleSample = IMUSample.constructFromAEPacketRaw(in, i,
                                    incompleteIMUSampleException);
                            i += IMUSample.SIZE_EVENTS - 1;
                            incompleteIMUSampleException = null;
                            imuSample = possibleSample; // asking for sample from AEChip now gives this value, but no
                            // access to intermediate IMU samples
                            imuSample.imuSampleEvent = true;
                            outItr.writeToNextOutput(imuSample); // also write the event out to the next output event
                            // slot
                            continue;
                        } catch (final IMUSample.IncompleteIMUSampleException ex) {
                            incompleteIMUSampleException = ex;
                            if ((missedImuSampleCounter++ % DavisEventExtractor.IMU_WARNING_INTERVAL) == 0) {
                                Chip.log.warning(String.format("%s (obtained %d partial samples so far)",
                                        ex.toString(), missedImuSampleCounter));
                            }
                            break; // break out of loop because this packet only contained part of an IMUSample and
                            // formed the end of the packet anyhow. Next time we come back here we will complete
                            // the IMUSample
                        } catch (final IMUSample.BadIMUDataException ex2) {
                            if ((badImuDataCounter++ % DavisEventExtractor.IMU_WARNING_INTERVAL) == 0) {
                                Chip.log.warning(String.format("%s (%d bad samples so far)", ex2.toString(),
                                        badImuDataCounter));
                            }
                            incompleteIMUSampleException = null;
                            continue; // continue because there may be other data
                        }
                    }

                } else if ((data & DavisChip.ADDRESS_TYPE_MASK) == DavisChip.ADDRESS_TYPE_DVS) {
                    // DVS event
                    final ApsDvsEventRGBW e = nextApsDvsEvent(outItr);
                    if ((data & DavisChip.EVENT_TYPE_MASK) == DavisChip.EXTERNAL_INPUT_EVENT_ADDR) {
                        e.adcSample = -1; // TODO hack to mark as not an ADC sample
                        e.special = true; // TODO special is set here when capturing frames which will mess us up if
                        // this is an IMUSample used as a plain ApsDvsEventRGBW
                        e.address = data;
                        e.timestamp = (timestamps[i]);
                        e.setIsDVS(true);
                    } else {
                        e.adcSample = -1; // TODO hack to mark as not an ADC sample
                        e.special = false;
                        e.address = data;
                        e.timestamp = (timestamps[i]);
                        e.polarity = (data & DavisChip.POLMASK) == DavisChip.POLMASK ? ApsDvsEventRGBW.Polarity.On
                                : ApsDvsEventRGBW.Polarity.Off;
                        e.type = (byte) ((data & DavisChip.POLMASK) == DavisChip.POLMASK ? 1 : 0);
						e.x = (short) (2 * (319 - ((data & DavisChip.XMASK) >>> DavisChip.XSHIFT)));
						e.y = (short) (2 * ((data & DavisChip.YMASK) >>> DavisChip.YSHIFT));
                        e.setIsDVS(true);
                        e.setColorFilter(ColorFilter.W);
						// System.out.println(data);
                        // autoshot triggering
                        autoshotEventsSinceLastShot++; // number DVS events captured here
                    }
                } else if ((data & DavisChip.ADDRESS_TYPE_MASK) == DavisChip.ADDRESS_TYPE_APS) {
					// APS event
                    // We first calculate the positions, so we can put events such as StartOfFrame at their
                    // right place, before the actual APS event denoting (0, 0) for example.
                    final int timestamp = timestamps[i];

                    short x = (short) (((data & DavisChip.XMASK) >>> DavisChip.XSHIFT));
                    short y = (short) ((data & DavisChip.YMASK) >>> DavisChip.YSHIFT);

                    ApsDvsEventRGBW.ColorFilter ColorFilter = ApsDvsEventRGBW.ColorFilter.Null;
                    if (((x % 2) == 1) && ((y % 2) == 1)) {
                        ColorFilter = ApsDvsEventRGBW.ColorFilter.R;// R
                    } else if (((x % 2) == 0) && ((y % 2) == 1)) {
                        ColorFilter = ApsDvsEventRGBW.ColorFilter.G;// G
                    } else if (((x % 2) == 0) && ((y % 2) == 0)) {
                        ColorFilter = ApsDvsEventRGBW.ColorFilter.B;// B
                    } else if (((x % 2) == 1) && ((y % 2) == 0)) {
                        ColorFilter = ApsDvsEventRGBW.ColorFilter.W;// w
                    }

                    final boolean pixFirst = firstFrameAddress(x, y); // First event of frame (addresses get flipped)
                    final boolean pixLast = lastFrameAddress(x, y); // Last event of frame (addresses get flipped)

                    ApsDvsEventRGBW.ReadoutType readoutType = ApsDvsEventRGBW.ReadoutType.Null;
                    switch ((data & DavisChip.ADC_READCYCLE_MASK) >>> ADC_NUMBER_OF_TRAILING_ZEROS) {
                        case 0:
                            readoutType = ApsDvsEventRGBW.ReadoutType.ResetRead;
                            break;

                        case 1:
                            readoutType = ApsDvsEventRGBW.ReadoutType.SignalRead;
                            break;

                        case 2:
                            readoutType = ApsDvsEventRGBW.ReadoutType.CpResetRead;
                            break;

                        case 3:
                            Chip.log.warning("Event with readout cycle null was sent out!");
                            break;

                        default:
                            if ((warningCount < 10)
                                    || ((warningCount % DavisEventExtractor.WARNING_COUNT_DIVIDER) == 0)) {
                                Chip.log.warning("Event with unknown readout cycle was sent out!.");
                            }
                            warningCount++;
                            break;
                    }

                    // Start of Frame (SOF)
                    if (pixFirst && !getDavisConfig().getApsReadoutControl().isGlobalShutterMode()
                            && (readoutType == ApsDvsEventRGBW.ReadoutType.ResetRead)) { // RS
                        createApsFlagEvent(outItr, ApsDvsEventRGBW.ReadoutType.SOF, timestamp);

                        frameIntervalUs = timestamp - frameExposureStartTimestampUs;
                        frameExposureStartTimestampUs = timestamp;
                    }
                    if (pixFirst && getDavisConfig().getApsReadoutControl().isGlobalShutterMode()
                            && (readoutType == ApsDvsEventRGBW.ReadoutType.SignalRead)) { // GS
                        createApsFlagEvent(outItr, ApsDvsEventRGBW.ReadoutType.SOF, timestamp);

                        frameIntervalUs = timestamp - frameExposureStartTimestampUs;
                        frameExposureStartTimestampUs = timestamp;
                    }

                    final ApsDvsEventRGBW e = nextApsDvsEvent(outItr);
                    e.adcSample = data & DavisChip.ADC_DATA_MASK;
                    e.readoutType = readoutType;
                    e.special = false;
                    e.timestamp = timestamp;
                    e.address = data;
                    e.x = x;
                    e.y = y;
                    e.type = (byte) (2);
                    e.setColorFilter(ColorFilter);

					// TODO: figure out exposure for both GS and RS, and start of frame for GS.
                    if (pixLast && !getDavisConfig().getApsReadoutControl().isGlobalShutterMode() && (readoutType == ApsDvsEventRGBW.ReadoutType.CpResetRead)) {
			// if we use ResetRead+SignalRead+C readout, OR, if we use ResetRead-SignalRead readout and we
                        // are at last APS pixel, then write EOF event
                        // insert a new "end of frame" event not present in original data
                        createApsFlagEvent(outItr, ApsDvsEventRGBW.ReadoutType.EOF, timestamp);

                        if (snapshot) {
                            snapshot = false;
                            getDavisConfig().getApsReadoutControl().setAdcEnabled(false);
                        }

                        setFrameCount(getFrameCount() + 1);
                    }
                    
                    if (pixLast && getDavisConfig().getApsReadoutControl().isGlobalShutterMode() && (readoutType == ApsDvsEventRGBW.ReadoutType.CpResetRead)) {
			// if we use ResetRead+SignalRead+C readout, OR, if we use ResetRead-SignalRead readout and we
                        // are at last APS pixel, then write EOF event
                        // insert a new "end of frame" event not present in original data
                        createApsFlagEvent(outItr, ApsDvsEventRGBW.ReadoutType.EOF, timestamp);

                        if (snapshot) {
                            snapshot = false;
                            getDavisConfig().getApsReadoutControl().setAdcEnabled(false);
                        }

                        setFrameCount(getFrameCount() + 1);
                    }
                }
            }

            if ((getAutoshotThresholdEvents() > 0) && (autoshotEventsSinceLastShot > getAutoshotThresholdEvents())) {
                takeSnapshot();
                autoshotEventsSinceLastShot = 0;
            }

            return out;
        } // extractPacket

        @Override
        protected ApsDvsEventRGBW nextApsDvsEvent(final OutputEventIterator outItr) {
            ApsDvsEvent e = super.nextApsDvsEvent(outItr);

            if (e instanceof ApsDvsEventRGBW) {
                ((ApsDvsEventRGBW) e).setColorFilter(null);
            }

            return (ApsDvsEventRGBW) e;
        }

        /**
         * To handle filtered ApsDvsEventRGBWs, this method rewrites the fields
         * of the raw address encoding x and y addresses to reflect the event's
         * x and y fields.
         *
         * @param e the ApsDvsEventRGBW
         * @return the raw address
         */
        @Override
        public int reconstructRawAddressFromEvent(final TypedEvent e) {
            int address = e.address;
			// if(e.x==0 && e.y==0){
            // log.info("start of frame event "+e);
            // }
            // if(e.x==-1 && e.y==-1){
            // log.info("end of frame event "+e);
            // }
            // e.x came from e.x = (short) (chip.getSizeX()-1-((data & XMASK) >>> XSHIFT)); // for DVS event, no x flip
            // if APS event
            if (((ApsDvsEventRGBW) e).adcSample >= 0) {
                address = (address & ~DavisChip.XMASK) | (((e.x) / 2) << DavisChip.XSHIFT);
            } else {
                address = (address & ~DavisChip.XMASK) | ((getSizeX() - 1 - (e.x / 2)) << DavisChip.XSHIFT);
            }
            // e.y came from e.y = (short) ((data & YMASK) >>> YSHIFT);
            address = (address & ~DavisChip.YMASK) | ((e.y / 2) << DavisChip.YSHIFT);
            return address;
        }

        public boolean firstFrameAddress(short x, short y) {
            return (x == 0) && (y == 0);
        }

        public boolean lastFrameAddress(short x, short y) {
            return (x == (getSizeX() - 1)) && (y == (getSizeY() - 1));
        }
    } // extractor
}
