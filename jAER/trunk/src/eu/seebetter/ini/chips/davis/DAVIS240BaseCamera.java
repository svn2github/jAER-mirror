/*
 * created 26 Oct 2008 for new cDVSTest chip
 * adapted apr 2011 for cDVStest30 chip by tobi
 * adapted 25 oct 2011 for SeeBetter10/11 chips by tobi
 */
package eu.seebetter.ini.chips.davis;

import eu.seebetter.ini.chips.DavisChip;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.sf.jaer.Description;
import net.sf.jaer.graphics.AEFrameChipRenderer;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/**
 * <p>
 * DAViS240a/b have 240x180 pixels and are built in 180nm technology. DAViS240a
 * has a rolling shutter APS readout and DAViS240b has global shutter readout
 * (but rolling shutter also possible with DAViS240b with different CPLD logic).
 * Both do APS CDS in digital domain off-chip, on host side, using difference
 * between reset and signal reads.
 * <p>
 *
 * Describes retina and its event extractor and bias generator. Two constructors
 * ara available, the vanilla constructor is used for event playback and the one
 * with a HardwareInterface parameter is useful for live capture.
 * {@link #setHardwareInterface} is used when the hardware interface is
 * constructed after the retina object. The constructor that takes a hardware
 * interface also constructs the biasgen interface.
 *
 * @author tobi, christian
 */
@Description("DAVIS240 base class for 240x180 pixel APS-DVS DAVIS sensor")
abstract public class DAVIS240BaseCamera extends DavisBaseCamera {

    public static final short WIDTH_PIXELS = 240;
    public static final short HEIGHT_PIXELS = 180;
    protected Davis240Config davis240Config;

    /**
     * Creates a new instance.
     */
    public DAVIS240BaseCamera() {
        setName("DAVIS240BaseCamera");
        setDefaultPreferencesFile("biasgenSettings/Davis240a/David240aBasic.xml");
        setSizeX(WIDTH_PIXELS);
        setSizeY(HEIGHT_PIXELS);

  
        setBiasgen(davis240Config = new Davis240Config(this));

        apsDVSrenderer = new AEFrameChipRenderer(this); // must be called after configuration is constructed, because it needs to know if frames are enabled to reset pixmap
        apsDVSrenderer.setMaxADC(DavisChip.MAX_ADC);
        setRenderer(apsDVSrenderer);

        // hardware interface is ApsDvsHardwareInterface
        if (getRemoteControl() != null) {
            getRemoteControl()
                    .addCommandListener(this, CMD_EXPOSURE, CMD_EXPOSURE + " val - sets exposure. val in ms.");
//            getRemoteControl().addCommandListener(this, CMD_EXPOSURE_CC,
//                    CMD_EXPOSURE_CC + " val - sets exposureControlRegister. val in clock cycles");
//            getRemoteControl().addCommandListener(this, CMD_RS_SETTLE_CC,
//                    CMD_RS_SETTLE_CC + " val - sets reset settling time. val in clock cycles");  // can add back later if needed for device testing
        }

        // get informed
    }

    /**
     * Creates a new instance of DAViS240
     *
     * @param hardwareInterface an existing hardware interface. This constructor
     * is preferred. It makes a new cDVSTest10Biasgen object to talk to the
     * on-chip biasgen.
     */
    public DAVIS240BaseCamera(final HardwareInterface hardwareInterface) {
        this();
        setHardwareInterface(hardwareInterface);
    }

    @Override
    public void setPowerDown(final boolean powerDown) {
        davis240Config.powerDown.set(powerDown);
        try {
            davis240Config.sendOnChipConfigChain();
        } catch (final HardwareInterfaceException ex) {
            Logger.getLogger(DAVIS240BaseCamera.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    /**
     * Sets threshold for shooting a frame automatically
     *
     * @param thresholdEvents the number of events to trigger shot on. Less than
     * or equal to zero disables auto-shot.
     */
    @Override
    public void setAutoshotThresholdEvents(int thresholdEvents) {
        if (thresholdEvents < 0) {
            thresholdEvents = 0;
        }
        autoshotThresholdEvents = thresholdEvents;
        getPrefs().putInt("DAViS240.autoshotThresholdEvents", thresholdEvents);
        if (autoshotThresholdEvents == 0) {
            davis240Config.runAdc.set(true);
        }
    }

    @Override
    public void setADCEnabled(final boolean adcEnabled) {
        davis240Config.getApsReadoutControl().setAdcEnabled(adcEnabled);
    }

    /**
     * Triggers shot of one APS frame
     */
    @Override
    public void takeSnapshot() {
        snapshot = true;
        davis240Config.getApsReadoutControl().setAdcEnabled(true);
    }

}
