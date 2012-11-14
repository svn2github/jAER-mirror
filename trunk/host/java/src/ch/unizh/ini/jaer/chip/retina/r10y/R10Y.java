/*
 * DVS128.java
 *
 * Created on October 5, 2005, 11:36 AM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */
package ch.unizh.ini.jaer.chip.retina.r10y;

import ch.unizh.ini.jaer.chip.retina.AETemporalConstastRetina;
import ch.unizh.ini.jaer.chip.retina.DVSFunctionalControlPanel;
import ch.unizh.ini.jaer.chip.retina.DVSTweaks;
import ch.unizh.ini.jaer.chip.retina.r10y.R10Y.*;
import java.beans.PropertyChangeSupport;
import java.util.Observable;
import net.sf.jaer.aemonitor.*;
import net.sf.jaer.biasgen.*;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.graphics.*;
import net.sf.jaer.hardwareinterface.*;
import java.awt.BorderLayout;
import java.awt.event.*;
import java.io.*;
import java.util.ArrayList;
import java.util.Observer;
import javax.swing.*;
import javax.swing.JPanel;
import net.sf.jaer.Description;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.CypressFX2DVS128HardwareInterface;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.HasResettablePixelArray;
import net.sf.jaer.util.RemoteControlCommand;
import net.sf.jaer.util.RemoteControlled;

/**
 * Describes R10Y retina and its event extractor and bias generator.
 * 
 * @author tobi/junseok
 */
@Description("R10Y prototoype Dynamic Vision Sensor")
public class R10Y extends AETemporalConstastRetina implements Serializable, Observer, RemoteControlled {

    private JMenu chipMenu = null;
    private JMenuItem arrayResetMenuItem = null;
    private JMenuItem setArrayResetMenuItem = null;
    private PropertyChangeSupport support = new PropertyChangeSupport(this);
    public static final String CMD_TWEAK_THESHOLD = "threshold", CMD_TWEAK_ONOFF_BALANCE = "balance", CMD_TWEAK_BANDWIDTH = "bandwidth", CMD_TWEAK_MAX_FIRING_RATE = "maxfiringrate";
    private Biasgen biasgen;
    JComponent helpMenuItem1 = null, helpMenuItem2 = null, helpMenuItem3=null;
    public static final String HELP_URL_RETINA = "http://siliconretina.ini.uzh.ch";
    public static final String USER_GUIDE_URL_RETINA = "http://siliconretina.ini.uzh.ch/wiki/doku.php?id=userguide";
    public static final String FIRMWARE_CHANGELOG = "http://jaer.svn.sourceforge.net/viewvc/jaer/trunk/deviceFirmwarePCBLayout/CypressFX2/firmware_FX2LP_DVS128/CHANGELOG.txt?revision=HEAD&view=markup";

    /** Creates a new instance of DVS128. No biasgen is constructed for this constructor, because there is no hardware interface defined. */
    public R10Y() {
        setName("DVS128");
        setDefaultPreferencesFile("../../biasgenSettings/r10y/R10Y-Default.xml");
        setSizeX(128);
        setSizeY(128);
        setNumCellTypes(2);
        setPixelHeightUm(40);
        setPixelWidthUm(40);
        setEventExtractor(new Extractor(this));
        setBiasgen((biasgen = new R10Y.Biasgen(this)));
        if (getRemoteControl() != null) {
            getRemoteControl().addCommandListener(this, CMD_TWEAK_BANDWIDTH, CMD_TWEAK_BANDWIDTH + " val - tweaks bandwidth. val in range -1.0 to 1.0.");
            getRemoteControl().addCommandListener(this, CMD_TWEAK_ONOFF_BALANCE, CMD_TWEAK_ONOFF_BALANCE + " val - tweaks on/off balance; increase for more ON events. val in range -1.0 to 1.0.");
            getRemoteControl().addCommandListener(this, CMD_TWEAK_MAX_FIRING_RATE, CMD_TWEAK_MAX_FIRING_RATE + " val - tweaks max firing rate; increase to reduce refractory period. val in range -1.0 to 1.0.");
            getRemoteControl().addCommandListener(this, CMD_TWEAK_THESHOLD, CMD_TWEAK_THESHOLD + " val - tweaks threshold; increase to raise threshold. val in range -1.0 to 1.0.");
        }
        //        ChipCanvas c = getCanvas();
        addObserver(this);

        if (!biasgen.isInitialized()) {
            maybeLoadDefaultPreferences();  // call *after* biasgen is built so that we check for unitialized biases as well.
        }//        if(c!=null)c.setBorderSpacePixels(5);// make border smaller than default
    }

    /** Creates a new instance of DVS128
     * @param hardwareInterface an existing hardware interface. This constructor is preferred. It makes a new Biasgen object to talk to the on-chip biasgen.
     */
    public R10Y(HardwareInterface hardwareInterface) {
        this();
        setHardwareInterface(hardwareInterface);
    }

    /** Updates AEViewer specialized menu items according to capabilities of HardwareInterface.
     *
     * @param o the observable, i.e. this Chip.
     * @param arg the argument (e.g. the HardwareInterface).
     */
    public void update(Observable o, Object arg) {
        if (!(arg instanceof HardwareInterface)) {
            return;
        }
        if (arrayResetMenuItem == null && getHardwareInterface() != null && getHardwareInterface() instanceof HasResettablePixelArray) {
            arrayResetMenuItem = new JMenuItem("Momentarily reset pixel array");
            arrayResetMenuItem.setToolTipText("Applies a momentary reset to the pixel array");
            arrayResetMenuItem.addActionListener(new ActionListener() {

                public void actionPerformed(ActionEvent evt) {
                    HardwareInterface hw = getHardwareInterface();
                    if (hw == null || !(hw instanceof HasResettablePixelArray)) {
                        log.warning("cannot reset pixels with hardware interface=" + hw + " (class " + (hw != null ? hw.getClass() : null) + "), interface doesn't implement HasResettablePixelArray");
                        return;
                    }
                    log.info("resetting pixels");
                    ((HasResettablePixelArray) hw).resetPixelArray();
                    setArrayResetMenuItem.setSelected(false); // after this reset, the array will not be held in reset
                }
            });
            chipMenu.add(arrayResetMenuItem);

            setArrayResetMenuItem = new JCheckBoxMenuItem("Hold array in reset");
            setArrayResetMenuItem.setToolTipText("Sets the entire pixel array in reset");
            setArrayResetMenuItem.addActionListener(new ActionListener() {

                public void actionPerformed(ActionEvent evt) {
                    HardwareInterface hw = getHardwareInterface();
                    if (hw == null || !(hw instanceof HasResettablePixelArray)) {
                        log.warning("cannot reset pixels with hardware interface=" + hw + " (class " + hw.getClass() + "), interface doesn't implement HasResettablePixelArray");
                        return;
                    }
                    log.info("setting pixel array reset=" + setArrayResetMenuItem.isSelected());
                    ((HasResettablePixelArray) hw).setArrayReset(setArrayResetMenuItem.isSelected());
                }
            });

            chipMenu.add(setArrayResetMenuItem);
        }


        // if hw interface is not correct type then disable menu items
        if (getHardwareInterface() == null) {
            if (arrayResetMenuItem != null) {
                arrayResetMenuItem.setEnabled(false);
            }
            if (setArrayResetMenuItem != null) {
                setArrayResetMenuItem.setEnabled(false);
            }
        } else {
            if (!(getHardwareInterface() instanceof HasResettablePixelArray)) {
                if (arrayResetMenuItem != null) {
                    arrayResetMenuItem.setEnabled(false);
                }
                if (setArrayResetMenuItem != null) {
                    setArrayResetMenuItem.setEnabled(false);
                }
            } else {
                arrayResetMenuItem.setEnabled(true);
                setArrayResetMenuItem.setEnabled(true);
            }
        }

    }

    @Override
    public void onDeregistration() {
        super.onRegistration();
        if (getAeViewer() == null) {
            return;
        }
        getAeViewer().removeHelpItem(helpMenuItem1);
        getAeViewer().removeHelpItem(helpMenuItem2);
    }

    @Override
    public void onRegistration() {
        super.onRegistration();
        if (getAeViewer() == null) {
            return;
        }
        helpMenuItem1 = getAeViewer().addHelpURLItem(HELP_URL_RETINA, "DVS128 wiki", "Opens wiki for DVS128 silicon retina");
        helpMenuItem2 = getAeViewer().addHelpURLItem(USER_GUIDE_URL_RETINA, "DVS128 user guide", "Opens user guide wiki for DVS128 silicon retina");
        helpMenuItem3 = getAeViewer().addHelpURLItem(FIRMWARE_CHANGELOG, "DVS128 Firmware Change Log", "Displays the head version of the DVS128 firmware change log");
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
        if (tokens[1] == null || tokens[1].length() == 0) {
            return input + ": argument too short - need a number";
        }
        float v = 0;
        try {
            v = Float.parseFloat(tokens[1]);
        } catch (NumberFormatException e) {
            return input + ": bad argument? Caught " + e.toString();
        }
        String c = command.getCmdName();
        if (c.equals(CMD_TWEAK_BANDWIDTH)) {
            biasgen.setBandwidthTweak(v);
        } else if (c.equals(CMD_TWEAK_ONOFF_BALANCE)) {
            biasgen.setOnOffBalanceTweak(v);
        } else if (c.equals(CMD_TWEAK_MAX_FIRING_RATE)) {
            biasgen.setMaxFiringRateTweak(v);
        } else if (c.equals(CMD_TWEAK_THESHOLD)) {
            biasgen.setThresholdTweak(v);
        } else {
            return input + ": unknown command";
        }
        return "successfully processed command " + input;
    }

    /** the event extractor for DVS128. DVS128 has two polarities 0 and 1. Here the polarity is flipped by the extractor so that the raw polarity 0 becomes 1
    in the extracted event. The ON events have raw polarity 0.
    1 is an ON event after event extraction, which flips the type. Raw polarity 1 is OFF event, which becomes 0 after extraction.
     */
    public class Extractor extends RetinaExtractor {

        final short XMASK = 0xfe, XSHIFT = 1, YMASK = 0x7f00, YSHIFT = 8;

        public Extractor(R10Y chip) {
            super(chip);
            setXmask((short) 0x00fe);
            setXshift((byte) 1);
            setYmask((short) 0x7f00);
            setYshift((byte) 8);
            setTypemask((short) 1);
            setTypeshift((byte) 0);
            setFlipx(true);
            setFlipy(false);
            setFliptype(true);
        }

        /** extracts the meaning of the raw events.
         *@param in the raw events, can be null
         *@return out the processed events. these are partially processed in-place. empty packet is returned if null is supplied as in. This event packet is reused
         * and should only be used by a single thread of execution or for a single input stream, or mysterious results may occur!
         */
        @Override
        synchronized public EventPacket extractPacket(AEPacketRaw in) {
            if (out == null) {
                out = new EventPacket<PolarityEvent>(chip.getEventClass());
            } else {
                out.clear();
            }
            extractPacket(in, out);
            return out;
        }
        private int printedSyncBitWarningCount = 3;

        /**
         * Extracts the meaning of the raw events. This form is used to supply an output packet. This method is used for real time
         * event filtering using a buffer of output events local to data acquisition. An AEPacketRaw may contain multiple events,
         * not all of them have to sent out as EventPackets. An AEPacketRaw is a set(!) of addresses and corresponding timing moments.
         *
         * A first filter (independent from the other ones) is implemented by subSamplingEnabled and getSubsampleThresholdEventCount.
         * The latter may limit the amount of samples in one package to say 50,000. If there are 160,000 events and there is a sub sample
         * threshold of 50,000, a "skip parameter" set to 3. Every so now and then the routine skips with 4, so we end up with 50,000.
         * It's an approximation, the amount of events may be less than 50,000. The events are extracted uniform from the input.
         *
         * @param in 		the raw events, can be null
         * @param out 		the processed events. these are partially processed in-place. empty packet is returned if null is
         * 					supplied as input.
         */
        @Override
        synchronized public void extractPacket(AEPacketRaw in, EventPacket out) {

            if (in == null) {
                return;
            }
            int n = in.getNumEvents(); //addresses.length;
            out.systemModificationTimeNs = in.systemModificationTimeNs;

            int skipBy = 1;
            if (isSubSamplingEnabled()) {
                while (n / skipBy > getSubsampleThresholdEventCount()) {
                    skipBy++;
                }
            }
            int sxm = sizeX - 1;
            int[] a = in.getAddresses();
            int[] timestamps = in.getTimestamps();
            OutputEventIterator outItr = out.outputIterator();
            for (int i = 0; i < n; i += skipBy) { // TODO bug here?
                int addr = a[i]; // TODO handle special events from hardware correctly
                PolarityEvent e = (PolarityEvent) outItr.nextOutput();
                e.address = addr;
                e.timestamp = (timestamps[i]);

                if ((addr&(CypressFX2DVS128HardwareInterface.SYNC_EVENT_BITMASK|BasicEvent.SPECIAL_EVENT_BIT_MASK))!=0) { // msb is set
                    e.setSpecial(true);
                    e.x = -1;
                    e.y = -1;
                    e.type = -1;
                    e.polarity = PolarityEvent.Polarity.On;
                    if (printedSyncBitWarningCount > 0) {
                        log.warning("raw address " + addr + " is >32767 (0xefff); either sync or stereo bit is set");
                        printedSyncBitWarningCount--;
                        if (printedSyncBitWarningCount == 0) {
                            log.warning("suppressing futher warnings about msb of raw address");
                        }
                    }
                } else {
                    e.setSpecial(false);
                    e.type = (byte) (1 - addr & 1);
                    e.polarity = e.type == 0 ? PolarityEvent.Polarity.Off : PolarityEvent.Polarity.On;
                    e.x = (short) (sxm - ((short) ((addr & XMASK) >>> XSHIFT)));
                    e.y = (short) ((addr & YMASK) >>> YSHIFT);
                }

            }
        }
    }

    /** overrides the Chip setHardware interface to construct a biasgen if one doesn't exist already.
     * Sets the hardware interface and the bias generators hardware interface
     *@param hardwareInterface the interface
     */
    @Override
    public void setHardwareInterface(final HardwareInterface hardwareInterface) {
        super.setHardwareInterface(hardwareInterface);
        this.hardwareInterface = hardwareInterface;
        try {
            if (getBiasgen() == null) {
                setBiasgen(new R10Y.Biasgen(this));
            } else {
                getBiasgen().setHardwareInterface((BiasgenHardwareInterface) hardwareInterface);
            }
        } catch (ClassCastException e) {
            System.err.println(e.getMessage() + ": probably this chip object has a biasgen but the hardware interface doesn't, ignoring");
        }
        setChanged();
        notifyObservers(hardwareInterface);
    }

//    /** Called when this DVS128 notified, e.g. by having its AEViewer set
//     @param the calling object
//     @param arg the argument passed
//     */
//    public void update(Observable o, Object arg) {
//        log.info("DVS128: received update from Observable="+o+", arg="+arg);
//    }
    /** Called when the AEViewer is set for this AEChip. Here we add the menu to the AEViewer.
     *
     * @param v the viewer
     */
    @Override
    public void setAeViewer(AEViewer v) {
        super.setAeViewer(v);
        if (v != null) {

            chipMenu = new JMenu("DVS128");
            chipMenu.getPopupMenu().setLightWeightPopupEnabled(false); // to paint on GLCanvas
            chipMenu.setToolTipText("Specialized menu for DVS128 chip");

            v.setMenu(chipMenu);
        }
    }

    /**
     * Describes IPots on R10Y retina chip. These are configured by a shift register.
     * This biasgen has one master bias control of 4 bits and each bias has 3 bits of individual control.
     *
     * The table below is the default bias values for R10.

Besides these values, we need to send 10 bits dummy (0000000000) before sending the bias values.

Thus, 45 bits, in total, should be sent to the shift register of R10.

The order of bits to the shift register (for the default values) is like this:

   00000000 1 0111 100 100 100 ...

* <pre>
Pin mapping of the new PCB for R10 is like this:

   FX2                 R10 (see Fig. 3-2(b) of ParameterSerializer_v00.docx)

CLOCK_B     ---->    PAD_BIAS_ENABLE

BITIN_B     ---->    PAD_BIAS_DATA

BITOUT_B    ---->    PAD_BIAS_OUT

LATCH_B     ---->    open (not connected)

POWERDOWN   ---->    PDA_PD
* 
* </pre>
* 
* Biases are as follows:
* <pre>
* (Total 35) 	Default 	Default (Variation/step) 	MAX/MIM 	Real BIAS (@default)
				(Variation/step) 
PDB_PD_MONITORING 	1			
IREF_TUNE<3:0> 	111	7.5kΩ (+0.15kΩ/step)	8.7kΩ /6.45kΩ 	Control all bias currents. 
		(2%/step) 	(+16%/ -14%) 	
SEL_BIASX<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASREQPD<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASREQ<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASREFR<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASPR<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASF<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step) 
			(+100%/ -75%) 	
SEL_BIASDIFFOFF<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	10nA (-2.5nA/step) 
			(+100%/ -75%) 	
SEL_BIASDIFFON<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	10nA (-2.5nA/step) 
			(+100%/ -75%) 	
SEL_BIASDIFF<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	10nA (-2.5nA/step) 
			(+100%/ -75%) 	
SEL_BIASCAS<2:0> 	100	80uA (-20uA/step) 	160uA /20uA	5nA (-1.25nA/step)
			(+100%/ -75%) 	
</pre>
* 
     * @author tobi
     */
    public class Biasgen extends net.sf.jaer.biasgen.Biasgen implements ChipControlPanel, DVSTweaks {

        private R10YBias diffOn, diffOff, refr, pr, sf, diff;
        private R10YBias iRefTuneBias;

        /** Creates a new instance of Biasgen for DVS128 with a given hardware interface
         *@param chip the chip this biasgen belongs to
         */
        public Biasgen(Chip chip) {
            super(chip);
            setName("R10Y");

            iRefTuneBias=new R10YBias(this, "IRef Master", 0, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "IREF_TUNE: scales all biases by this current value");
            iRefTuneBias.setNumBits(4);
            

//  /** Creates a new instance of IPot
//     *@param biasgen
//     *@param name
//     *@param shiftRegisterNumber the position in the shift register, 0 based, starting on end from which bits are loaded
//     *@param type (NORMAL, CASCODE)
//     *@param sex Sex (N, P)
//     * @param bitValue initial bitValue
//     *@param displayPosition position in GUI from top (logical order)
//     *@param tooltipString a String to display to user of GUI telling them what the pots does
//     */
////    public IPot(Biasgen biasgen, String name, int shiftRegisterNumber, final Type type, Sex sex, int bitValue, int displayPosition, String tooltipString) {

            // create potArray according to our needs
            setPotArray(new IPotArray(this));

            getPotArray().addPot(iRefTuneBias);
            
            getPotArray().addPot(new R10YBias(this, "X", 1, IPot.Type.NORMAL, IPot.Sex.N, 4, 0, "Bias X: function ???????"));
            getPotArray().addPot(new R10YBias(this, "injGnd", 10, IPot.Type.CASCODE, IPot.Sex.P, 0, 7, "Differentiator switch level, higher to turn on more"));
            getPotArray().addPot(new R10YBias(this, "reqPd", 9, IPot.Type.NORMAL, IPot.Sex.N, 0, 12, "AER request pulldown"));
            getPotArray().addPot(new R10YBias(this, "puX", 8, IPot.Type.NORMAL, IPot.Sex.P, 0, 11, "2nd dimension AER static pullup"));
            getPotArray().addPot(diffOff = new R10YBias(this, "diffOff", 7, IPot.Type.NORMAL, IPot.Sex.N, 0, 6, "OFF threshold, lower to raise threshold"));
            getPotArray().addPot(new R10YBias(this, "req", 6, IPot.Type.NORMAL, IPot.Sex.N, 0, 8, "OFF request inverter bias"));
            getPotArray().addPot(refr = new R10YBias(this, "refr", 5, IPot.Type.NORMAL, IPot.Sex.P, 0, 9, "Refractory period"));
            getPotArray().addPot(new R10YBias(this, "puY", 4, IPot.Type.NORMAL, IPot.Sex.P, 0, 10, "1st dimension AER static pullup"));
            getPotArray().addPot(diffOn = new R10YBias(this, "diffOn", 3, IPot.Type.NORMAL, IPot.Sex.N, 0, 5, "ON threshold - higher to raise threshold"));
            getPotArray().addPot(diff = new R10YBias(this, "diff", 2, IPot.Type.NORMAL, IPot.Sex.N, 0, 4, "Differentiator"));
            getPotArray().addPot(sf = new R10YBias(this, "foll", 1, IPot.Type.NORMAL, IPot.Sex.P, 0, 3, "Src follower buffer between photoreceptor and differentiator"));
            getPotArray().addPot(pr = new R10YBias(this, "Pr", 0, IPot.Type.NORMAL, IPot.Sex.P, 0, 1, "Photoreceptor"));

            loadPreferences();

        }

//        /** sends the ipot values over the hardware interface if there is not a batch edit occuring.
//         *@param biasgen the bias generator object.
//         * This parameter is necessary because the same method is used in the hardware interface,
//         * which doesn't know about the particular bias generator instance.
//         *@throws HardwareInterfaceException if there is a hardware error. If there is no interface, prints a message and just returns.
//         *@see #startBatchEdit
//         *@see #endBatchEdit
//         **/
//        public void sendConfiguration(Biasgen biasgen) throws HardwareInterfaceException {
//            if (hardwareInterface == null) {
////            log.warning("Biasgen.sendIPotValues(): no hardware interface");
//                return;
//            }
//            if (!isBatchEditOccurring() && hardwareInterface != null) {
////            log.info("calling hardwareInterface.sendConfiguration");
////            hardwareInterface.se(this);
//            }
//        }
        /** the change in current from an increase* or decrease* call */
        public final float RATIO = 1.05f;
        /** the minimum on/diff or diff/off current allowed by decreaseThreshold */
        public final float MIN_THRESHOLD_RATIO = 4f;
        public final float MAX_DIFF_ON_CURRENT = 12e-6f;
        public final float MIN_DIFF_OFF_CURRENT = 1e-10f;

        synchronized public void increaseThreshold() {
            if (diffOn.getCurrent() * RATIO > MAX_DIFF_ON_CURRENT) {
                return;
            }
            if (diffOff.getCurrent() / RATIO < MIN_DIFF_OFF_CURRENT) {
                return;
            }
            diffOn.changeByRatio(RATIO);
            diffOff.changeByRatio(1 / RATIO);
        }

        synchronized public void decreaseThreshold() {
            float diffI = diff.getCurrent();
            if (diffOn.getCurrent() / MIN_THRESHOLD_RATIO < diffI) {
                return;
            }
            if (diffOff.getCurrent() > diffI / MIN_THRESHOLD_RATIO) {
                return;
            }
            diffOff.changeByRatio(RATIO);
            diffOn.changeByRatio(1 / RATIO);
        }

        synchronized public void increaseRefractoryPeriod() {
            refr.changeByRatio(1 / RATIO);
        }

        synchronized public void decreaseRefractoryPeriod() {
            refr.changeByRatio(RATIO);
        }

        synchronized public void increaseBandwidth() {
            pr.changeByRatio(RATIO);
            sf.changeByRatio(RATIO);
        }

        synchronized public void decreaseBandwidth() {
            pr.changeByRatio(1 / RATIO);
            sf.changeByRatio(1 / RATIO);
        }

        synchronized public void moreONType() {
            diffOn.changeByRatio(1 / RATIO);
            diffOff.changeByRatio(RATIO);
        }

        synchronized public void moreOFFType() {
            diffOn.changeByRatio(RATIO);
            diffOff.changeByRatio(1 / RATIO);
        }
        JComponent expertTab, basicTab;

        /** @return a new panel for controlling this bias generator functionally
         */
        @Override
        public JPanel buildControlPanel() {
            JPanel panel = new JPanel();
            panel.setLayout(new BorderLayout());
            final JTabbedPane pane = new JTabbedPane();

            pane.addTab("Basic controls", basicTab = new DVSFunctionalControlPanel(R10Y.this));
            pane.addTab("Expert controls", expertTab = super.buildControlPanel());
            panel.add(pane, BorderLayout.CENTER);
            pane.setSelectedIndex(getPrefs().getInt("DVS128.selectedBiasgenControlTab", 0));
            pane.addMouseListener(new java.awt.event.MouseAdapter() {

                public void mouseClicked(java.awt.event.MouseEvent evt) {
                    getPrefs().putInt("DVS128.selectedBiasgenControlTab", pane.getSelectedIndex());
                }
            });

            return panel;
        }
        private float bandwidth = 1, maxFiringRate = 1, threshold = 1, onOffBalance = 1;

        /** Tweaks bandwidth around nominal value.
         * 
         * @param val -1 to 1 range
         */
        public void setBandwidthTweak(float val) {
            if (val > 1) {
                val = 1;
            } else if (val < -1) {
                val = -1;
            }
            float old = bandwidth;
            bandwidth = val;
            final float MAX = 300;
            pr.changeByRatioFromPreferred(PotTweakerUtilities.getRatioTweak(val, MAX));
            sf.changeByRatioFromPreferred(PotTweakerUtilities.getRatioTweak(val, MAX));
            getSupport().firePropertyChange(DVSTweaks.BANDWIDTH, old, val);
        }

        /**
         * Tweaks max firing rate (refractory period), larger is shorter refractory period.
         * 
         * @param val  -1 to 1 range
         */
        public void setMaxFiringRateTweak(float val) {
            if (val > 1) {
                val = 1;
            } else if (val < -1) {
                val = -1;
            }
            float old = maxFiringRate;
            maxFiringRate = val;
            final float MAX = 300;
            refr.changeByRatioFromPreferred(PotTweakerUtilities.getRatioTweak(val, MAX));
            getSupport().firePropertyChange(DVSTweaks.MAX_FIRING_RATE, old, val);
        }

        /**
         *  Tweaks threshold, larger is higher threshold.
         * @param val  -1 to 1 range
         */
        public void setThresholdTweak(float val) {
            if (val > 1) {
                val = 1;
            } else if (val < -1) {
                val = -1;
            }
            float old = threshold;
            final float MAX = 100;
            threshold = val;
            diffOn.changeByRatioFromPreferred(PotTweakerUtilities.getRatioTweak(val, MAX));
            diffOff.changeByRatioFromPreferred(1 / PotTweakerUtilities.getRatioTweak(val, MAX));
            getSupport().firePropertyChange(DVSTweaks.THRESHOLD, old, val);

        }

        /**
         * Tweaks balance of on/off events. Increase for more ON events.
         * 
         * @param val -1 to 1 range. 
         */
        public void setOnOffBalanceTweak(float val) {
            if (val > 1) {
                val = 1;
            } else if (val < -1) {
                val = -1;
            }
            float old = onOffBalance;
            onOffBalance = val;
            final float MAX = 100;
            diff.changeByRatioFromPreferred(PotTweakerUtilities.getRatioTweak(val, MAX));
            getSupport().firePropertyChange(DVSTweaks.ON_OFF_BALANCE, old, val);
        }

        @Override
        public float getBandwidthTweak() {
            return bandwidth;
        }

        @Override
        public float getThresholdTweak() {
            return threshold;
        }

        @Override
        public float getMaxFiringRateTweak() {
            return maxFiringRate;
        }

        @Override
        public float getOnOffBalanceTweak() {
            return onOffBalance;
        }
    } // DVS128Biasgen

    /**
     * Fires PropertyChangeEvents when biases are tweaked according to {@link ch.unizh.ini.jaer.chip.retina.DVSTweaks}.
     * 
     * @return the support
     */
    public PropertyChangeSupport getSupport() {
        return support;
    }
}
