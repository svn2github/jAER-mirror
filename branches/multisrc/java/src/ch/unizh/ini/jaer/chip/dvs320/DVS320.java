/*
created 26 Oct 2008 for new DVS320 chip
 */
package ch.unizh.ini.jaer.chip.dvs320;

import ch.unizh.ini.jaer.chip.retina.*;
import net.sf.jaer.aemonitor.*;
import net.sf.jaer.biasgen.*;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.hardwareinterface.*;
import java.awt.BorderLayout;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Observable;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import net.sf.jaer.Description;
import net.sf.jaer.graphics.DisplayMethod;
import net.sf.jaer.util.RemoteControl;
import net.sf.jaer.util.RemoteControlCommand;
import net.sf.jaer.util.RemoteControlled;

/**
 * Describes DVS320 retina and its event extractor and bias generator.
 * Two constructors ara available, the vanilla constructor is used for event playback and the
 *one with a HardwareInterface parameter is useful for live capture.
 * {@link #setHardwareInterface} is used when the hardware interface is constructed after the retina object.
 *The constructor that takes a hardware interface also constructs the biasgen interface.
 * <p>
 * The DVS320 features 320x240 pixels, a fully configurable bias generator, 
 * and a configurable output selector for digital and analog current and voltage outputs for characterization.
 * The output is word serial and includes an intensity neuron which rides onto the other addresses.
 * DVS320 is built in UMC18 CIS process and has 14.5u pixels.
 *
 * @author tobi
 */
@Description("DVS320 320x240 Dynamic Vision Sensor")
public class DVS320 extends AETemporalConstastRetina implements HasIntensity {

    /** The computed intensity value. */
    private float intensity = 0;

    /** Creates a new instance of DVS320.  */
    public DVS320() {
        setName("DVS320");
        setSizeX(340);
        setSizeY(240);
        setNumCellTypes(3); // two are polarity and last is intensity
        setPixelHeightUm(14.5f);
        setPixelWidthUm(14.5f);
        setEventExtractor(new DVS320Extractor(this));
        setBiasgen(new DVS320.DVS320Biasgen(this));
        DisplayMethod m = getCanvas().getDisplayMethod(); // get default method
        DVSWithIntensityDisplayMethod intenDisplayMethod = new DVSWithIntensityDisplayMethod(getCanvas());
        intenDisplayMethod.setIntensitySource(this);
        getCanvas().removeDisplayMethod(m);
        getCanvas().addDisplayMethod(intenDisplayMethod);
        getCanvas().setDisplayMethod(intenDisplayMethod);
    }

    /** Creates a new instance of DVS320
     * @param hardwareInterface an existing hardware interface. This constructer is preferred. It makes a new DVS320Biasgen object to talk to the on-chip biasgen.
     */
    public DVS320(HardwareInterface hardwareInterface) {
        this();
        setHardwareInterface(hardwareInterface);
    }

    public float getIntensity() {
        return intensity;
    }

    public void setIntensity(float f) {
        intensity = f;
    }

    /** The event extractor. Each pixel has two polarities 0 and 1.
     * There is one extra neuron which signals absolute intensity.
     * <p>
     *The bits in the raw data coming from the device are as follows.
     * <p>
     *Bit 0 is polarity, on=1, off=0<br>
     *Bits 1-9 are x address (max value 320)<br>
     *Bits 10-17 are y address (max value 240) <br>
     *Bit 18 signals the special intensity neuron, 
     * but it always comes together with an x address.
     * It means there was an intensity spike AND a normal pixel spike.
     *<p>
     */
    public class DVS320Extractor extends RetinaExtractor {

//        public static final int XMASK = 0x3fe,  XSHIFT = 1,  YMASK = 0xff000,  YSHIFT = 12,  INTENSITYMASK = 0x40000;
         public static final int XMASK = 0x3fe,  XSHIFT = 1,  YMASK = 0x3fc00,  YSHIFT = 10,  INTENSITYMASK = 0x40000;
        private int lastIntenTs = 0;

        public DVS320Extractor(DVS320 chip) {
            super(chip);
        }


        private float avdt=100; // used to compute rolling average of intensity

        /** extracts the meaning of the raw events.
         *@param in the raw events, can be null
         *@return out the processed events. these are partially processed in-place. empty packet is returned if null is supplied as in.
         */
        @Override
        synchronized public EventPacket extractPacket(AEPacketRaw in) {
            if (out == null) {
                out = new EventPacket<PolarityEvent>(chip.getEventClass());
            } else {
                out.clear();
            }
            if (in == null) {
                return out;
            }
            int n = in.getNumEvents(); //addresses.length;

            int skipBy = 1;
            if (isSubSamplingEnabled()) {
                while (n / skipBy > getSubsampleThresholdEventCount()) {
                    skipBy++;
                }
            }
            int[] a = in.getAddresses();
            int[] timestamps = in.getTimestamps();
            OutputEventIterator outItr = out.outputIterator();
            for (int i = 0; i < n; i += skipBy) { // bug here
                int addr = a[i];
                if ((addr & INTENSITYMASK) != 0) {// intensity spike, along with regular spike, just add in intensity spike
                    int dt = timestamps[i] - lastIntenTs;
                    if (dt > 50) {
                        avdt=0.2f*dt+0.8f*avdt;
                        setIntensity(50f / avdt); // ISI of this much gives intensity 1
                    }
                        lastIntenTs = timestamps[i];
//                    PolarityEvent e = (PolarityEvent) outItr.nextOutput();
//                    e.timestamp = (timestamps[i]);
//                    e.type = 2;
                }
                PolarityEvent e = (PolarityEvent) outItr.nextOutput();
                e.address=addr;
                e.timestamp = (timestamps[i]);
                e.x = (short) (((addr & XMASK) >>> XSHIFT));
                if (e.x < 0) {
                    e.x = 0;
                } else if (e.x > 319) {
                 //   e.x = 319; // TODO fix this artificial clamping of x address within space, masks symptoms
                }
                e.y = (short) ((addr & YMASK) >>> YSHIFT);
                if (e.y > 239) {
//                    log.warning("e.y="+e.y);
                    e.y = 239; // TODO fix this
                } else if (e.y < 0) {
                    e.y = 0; // TODO
                }
                e.type = (byte) (addr & 1);
                e.polarity = e.type == 1 ? PolarityEvent.Polarity.Off : PolarityEvent.Polarity.On;
            }
            return out;
        }
    }

    /** overrides the Chip setHardware interface to construct a biasgen if one doesn't exist already.
     * Sets the hardware interface and the bias generators hardware interface
     *@param hardwareInterface the interface
     */
    public void setHardwareInterface(final HardwareInterface hardwareInterface) {
        this.hardwareInterface = hardwareInterface;
        try {
            if (getBiasgen() == null) {
                setBiasgen(new DVS320.DVS320Biasgen(this));
            } else {
                getBiasgen().setHardwareInterface((BiasgenHardwareInterface) hardwareInterface);
            }
        } catch (ClassCastException e) {
            log.warning(e.getMessage() + ": probably this chip object has a biasgen but the hardware interface doesn't, ignoring");
        }
    }

    /**
     * Describes ConfigurableIPots on DVS320 retina chip as well as the other configuration bits which control, for example, which
     * outputs are selected. These are all configured by a single shared shift register. 
     * <p>
     * The pr, foll, and refr biases use the lowpower bias for their p src bias and the pr, foll and refr pfets
     * all have their psrcs wired to this shifted p src bias. Also, the pr, foll and refr biases also drive the same
     * shifted psrc bias with their own shifted psrc bias. Therefore all 4 of these biases (pr, foll, refr, and lowpower) should
     * have the same bufferbias bits. This constraint is enforced by software.
     * <p>
     * The output configuration bits follow the bias values and consist of 12 bits that select 3 outputs.
     * <nl>
     * <li> Bits 0-3 select the current output.
     * <li> 5 copies of digital Bits 4-8 select the digital output.
     * <li> Bits 
     * 
     * @author tobi
     */
    public class DVS320Biasgen extends net.sf.jaer.biasgen.Biasgen {

        ArrayList<HasPreference> hasPreferencesList = new ArrayList<HasPreference>();
        private ConfigurableIPotRev0 cas,  diffOn,  diffOff,  diff,  bulk;
        private ConstrainedConfigurableIPot refr,  pr,  foll,  lowpower;
        private ArrayList<ConstrainedConfigurableIPot> sharedBufferBiasList = new ArrayList<ConstrainedConfigurableIPot>();
        DVS320ControlPanel controlPanel;
        AllMuxes allMuxes = new AllMuxes(); // the output muxes

        /** Creates a new instance of DVS320Biasgen for DVS320 with a given hardware interface
         *@param chip the chip this biasgen belongs to
         */
        public DVS320Biasgen(Chip chip) {
            super(chip);
            setName("DVS320");

            getMasterbias().setKPrimeNFet(55e-3f); // estimated from tox=42A, mu_n=670 cm^2/Vs // TODO fix for UMC18 process
            getMasterbias().setMultiplier(9 * (24f / 2.4f) / (4.8f / 2.4f));  // =45  correct for dvs320
            getMasterbias().setWOverL(4.8f / 2.4f); // masterbias has nfet with w/l=2 at output 


            /*
            @param biasgen
            @param name
            @param shiftRegisterNumber the position in the shift register, 0 based, starting on end from which bits are loaded
            @param type (NORMAL, CASCODE)
            @param sex Sex (N, P)
            @param lowCurrentModeEnabled bias is normal (false) or in low current mode (true)
            @param enabled bias is enabled (true) or weakly tied to rail (false)
            @param bitValue initial bitValue
            @param bufferBitValue buffer bias bit value
            @param displayPosition position in GUI from top (logical order)
            @param tooltipString a String to display to user of GUI telling them what the pots does
             */
            setPotArray(new IPotArray(this));
            /*
             * pr
             * cas
             * foll
             * bulk
             * diff
             * on
             * off
             * refr
             * lowpower
             * pux
             * puy
             * pd
             * padfoll
             * ifThr
             * test
             */

            getPotArray().addPot(pr = new ConstrainedConfigurableIPot(this, "pr", 0, IPot.Type.NORMAL, IPot.Sex.P, false, true, 100, ConfigurableIPotRev0.maxBuffeBitValue, 1, "Photoreceptor, also biasgen test transistor gate input", sharedBufferBiasList));
            getPotArray().addPot(cas = new ConfigurableIPotRev0(this, "cas", 1, IPot.Type.CASCODE, IPot.Sex.N, false, true, 200, ConfigurableIPotRev0.maxBuffeBitValue, 2, "Photoreceptor cascode"));
            getPotArray().addPot(foll = new ConstrainedConfigurableIPot(this, "foll", 2, IPot.Type.NORMAL, IPot.Sex.P, false, true, 1000, ConfigurableIPotRev0.maxBuffeBitValue, 3, "Src follower buffer between photoreceptor and differentiator", sharedBufferBiasList));
            getPotArray().addPot(bulk = new ConfigurableIPotRev0(this, "bulk", 3, IPot.Type.NORMAL, IPot.Sex.N, false, true, 1000, ConfigurableIPotRev0.maxBuffeBitValue, 4, "Differentiator switch bulk bias"));
            getPotArray().addPot(diff = new ConfigurableIPotRev0(this, "diff", 4, IPot.Type.NORMAL, IPot.Sex.N, false, true, 2000, ConfigurableIPotRev0.maxBuffeBitValue, 5, "Differentiator"));
            getPotArray().addPot(diffOn = new ConfigurableIPotRev0(this, "on", 5, IPot.Type.NORMAL, IPot.Sex.N, false, true, 500, ConfigurableIPotRev0.maxBuffeBitValue, 6, "ON threshold - higher to raise threshold"));
            getPotArray().addPot(diffOff = new ConfigurableIPotRev0(this, "off", 6, IPot.Type.NORMAL, IPot.Sex.N, false, true, 0, ConfigurableIPotRev0.maxBuffeBitValue, 7, "OFF threshold, lower to raise threshold"));
            getPotArray().addPot(refr = new ConstrainedConfigurableIPot(this, "refr", 7, IPot.Type.NORMAL, IPot.Sex.P, false, true, 50, ConfigurableIPotRev0.maxBuffeBitValue, 8, "Refractory period", sharedBufferBiasList));
            getPotArray().addPot(lowpower = new ConstrainedConfigurableIPot(this, "lowpower", 8, IPot.Type.NORMAL, IPot.Sex.N, false, true, 50, ConfigurableIPotRev0.maxBuffeBitValue, 9, "Source bias for low current biases (pr, foll, refr)", sharedBufferBiasList));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "pux", 9, IPot.Type.NORMAL, IPot.Sex.P, false, true, ConfigurableIPotRev0.maxBitValue, ConfigurableIPotRev0.maxBuffeBitValue, 11, "2nd dimension AER static pullup"));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "puy", 10, IPot.Type.NORMAL, IPot.Sex.P, false, true, 0, ConfigurableIPotRev0.maxBuffeBitValue, 10, "1st dimension AER static pullup"));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "pd", 11, IPot.Type.NORMAL, IPot.Sex.N, false, true, 0, ConfigurableIPotRev0.maxBuffeBitValue, 11, "AER request pulldown"));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "padfoll", 12, IPot.Type.NORMAL, IPot.Sex.P, false, true, 300, ConfigurableIPotRev0.maxBuffeBitValue, 20, "voltage follower pads"));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "ifthr", 13, IPot.Type.NORMAL, IPot.Sex.N, false, true, 0, ConfigurableIPotRev0.maxBuffeBitValue, 30, "intensity (total photocurrent) IF neuron threshold, also gate and source biases for n/p test fets"));
            getPotArray().addPot(new ConfigurableIPotRev0(this, "test", 14, IPot.Type.NORMAL, IPot.Sex.N, false, true, 0, ConfigurableIPotRev0.maxBuffeBitValue, 100, "test bias - no functionality, NOT connected to test transistors"));

            sharedBufferBiasList.add(pr);
            sharedBufferBiasList.add(foll);
            sharedBufferBiasList.add(refr);
            sharedBufferBiasList.add(lowpower);

            loadPreferences();

        }

        @Override
        public void loadPreferences() {
            super.loadPreferences();
            if (hasPreferencesList != null) {
                for (HasPreference hp : hasPreferencesList) {
                    hp.loadPreference();
                }
            }
        }

        @Override
        public void storePreferences() {
            super.storePreferences();
            for (HasPreference hp : hasPreferencesList) {
                hp.storePreference();
            }
        }

        /**
         * 
         * Overrides the default method to add the custom control panel for configuring the DVS320 output muxes.
         * 
         * @return a new panel for controlling this bias generator functionally
         */
        @Override
        public JPanel buildControlPanel() {
//            if(controlPanel!=null) return controlPanel;
            JPanel panel = new JPanel();
            panel.setLayout(new BorderLayout());
            JTabbedPane pane = new JTabbedPane();

            pane.addTab("Biases", super.buildControlPanel());
            pane.addTab("Output control", new DVS320ControlPanel(DVS320.this));
            panel.add(pane, BorderLayout.CENTER);
            return panel;
        }

        @Override
        public byte[] formatConfigurationBytes(Biasgen biasgen) {
            byte[] biasBytes = super.formatConfigurationBytes(biasgen);
            byte[] configBytes = allMuxes.formatConfigurationBytes(); // the first nibble is the imux in big endian order, bit3 of the imux is the very first bit.
            byte[] allBytes = new byte[biasBytes.length + configBytes.length];
            System.arraycopy(configBytes, 0, allBytes, 0, configBytes.length); // first bits in byte array are loaded first to dvs320; the very first nibble is the imux since it is at the end of the long shift register.
            System.arraycopy(biasBytes, 0, allBytes, configBytes.length, biasBytes.length);
            return allBytes; // configBytes may be padded with extra bits to make up a byte, board needs to know this to chop off these bits
        }
        /** the change in current from an increase* or decrease* call */
        public final float RATIO = 1.05f;
        /** the minimum on/diff or diff/off current allowed by decreaseThreshold */
        public final float MIN_THRESHOLD_RATIO = 2f;
        public final float MAX_DIFF_ON_CURRENT = 6e-6f;
        public final float MIN_DIFF_OFF_CURRENT = 1e-9f;

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
            foll.changeByRatio(RATIO);
        }

        synchronized public void decreaseBandwidth() {
            pr.changeByRatio(1 / RATIO);
            foll.changeByRatio(1 / RATIO);
        }

        synchronized public void moreONType() {
            diffOn.changeByRatio(1 / RATIO);
            diffOff.changeByRatio(RATIO);
        }

        synchronized public void moreOFFType() {
            diffOn.changeByRatio(RATIO);
            diffOff.changeByRatio(1 / RATIO);
        }        // TODO fix functional biasgen panel to be more usable

        /** A mux for selecting output. */
        class OutputMux extends Observable implements HasPreference, RemoteControlled {

            int nSrBits;
            int nInputs;
            OutputMap map;
            private String name = "OutputMux";
            int selectedChannel = -1; // defaults to no input selected in the case of voltage and current, and channel 0 in the case of logic
            String bitString = null;
            final String CMD_SELECTMUX = "selectMux_";

            OutputMux(int nsr, int nin, OutputMap m) {
                nSrBits = nsr;
                nInputs = nin;
                map = m;
                hasPreferencesList.add(this);
            }

            public String toString() {
                return "OutputMux name=" + name + " nSrBits=" + nSrBits + " nInputs=" + nInputs + " selectedChannel=" + selectedChannel + " channelName=" + getChannelName(selectedChannel) + " code=" + getCode(selectedChannel) + " getBitString=" + bitString;
            }

            void select(int i) {
                selectWithoutNotify(i);
                setChanged();
                notifyObservers();
//                log.info("selected "+this);
            }

            void selectWithoutNotify(int i) {
                selectedChannel = i;
                try {
                    sendConfiguration(DVS320.DVS320Biasgen.this);
                } catch (HardwareInterfaceException ex) {
                    log.warning("selecting output: " + ex);
                }
            }

            void put(int k, String name) { // maps from channel to string name
                map.put(k, name);
            }

            OutputMap getMap() {
                return map;
            }

            int getCode(int i) { // returns shift register binary code for channel i
                return map.get(i);
            }

            /** Returns the bit string to send to the firmware to load a bit sequence for this mux in the shift register;
             * bits are loaded big endian, msb first but returned string has msb at right-most position, i.e. end of string.
             * @return big endian string e.g. code=11, s='1011', code=7, s='0111' for nSrBits=4.
             */
            String getBitString() {
                StringBuilder s = new StringBuilder();
                int code = selectedChannel != -1 ? getCode(selectedChannel) : 0; // code 0 if no channel selected
                int k = nSrBits - 1;
                while (k >= 0) {
                    int x = code & (1 << k); // start with msb
                    boolean b = (x == 0); // get bit
                    s.append(b ? '0' : '1'); // append to string 0 or 1, string grows with msb on left
                    k--;
                } // construct big endian string e.g. code=14, s='1011'
                bitString = s.toString();
                return bitString;
            }

            String getChannelName(int i) { // returns this channel name
                return map.nameMap.get(i);
            }

            public String getName() { // returns name of entire mux
                return name;
            }

            public void setName(String name) {
                this.name = name;
            }

            private String key() {
                return "DVS320." + getClass().getSimpleName() + "." + name + ".selectedChannel";
            }

            public void loadPreference() {
                select(getPrefs().getInt(key(), -1));
            }

            public void storePreference() {
                getPrefs().putInt(key(), selectedChannel);
            }

            /** Command is e.g. "selectMux_Currents 1".
             *
             * @param command the first token which dispatches the command here for this class of Mux.
             * @param input the command string.
             * @return some informative string for debugging bad commands.
             */
            public String processRemoteControlCommand(RemoteControlCommand command, String input) {
                String[] t = input.split("\\s");
                if (t.length < 2) {
                    return "? " + this + "\n";
                } else {
                    String s = t[0], a = t[1];
                    try {
                        select(Integer.parseInt(a));
                        return this + "\n";
                    } catch (NumberFormatException e) {
                        log.warning("Bad number format: " + input + " caused " + e);
                        return e.toString() + "\n";
                    } catch (Exception ex) {
                        log.warning(ex.toString());
                        return ex.toString();
                    }
                }
            }
//            public void preferenceChange(PreferenceChangeEvent evt) {
//                if(evt.getKey().equals(key())){
//                    select(Integer.parseInt(evt.getNewValue()));
//                }
//            }
        }

        class OutputMap extends HashMap<Integer, Integer> {

            HashMap<Integer, String> nameMap = new HashMap<Integer, String>();

            void put(int k, int v, String name) {
                put(k, v);
                nameMap.put(k, name);
            }

            void put(int k, String name) {
                nameMap.put(k, name);
            }
        }

        class VoltageOutputMap extends OutputMap {

            void put(int k, int v) {
                put(k, v, "Voltage " + k);
            }

            VoltageOutputMap() {
                put(0, 1);
                put(1, 3);
                put(2, 5);
                put(3, 7);
                put(4, 9);
                put(5, 11);
                put(6, 13);
                put(7, 15);
            }
        }

        class DigitalOutputMap extends OutputMap {

            DigitalOutputMap() {
                for (int i = 0; i < 16; i++) {
                    put(i, i, "DigOut " + i);
                }
            }
        }

        class CurrentOutputMap extends OutputMap {

            void put(int k, int v) {
                put(k, v, "Current " + k);
            }

            CurrentOutputMap() {
                put(0, 3); // in0 selected by bit3:0=3
                put(1, 7);
                put(2, 11);
                put(3, 15);
            }
        }

        class VoltageOutputMux extends OutputMux {

            VoltageOutputMux(int n) {
                super(4, 8, new VoltageOutputMap());
                setName("Voltages" + n);
            }
        }

        class LogicMux extends OutputMux {

            LogicMux(int n) {
                super(4, 16, new DigitalOutputMap());
                setName("LogicSignals" + n);
            }
        }

        class CurrentOutputMux extends OutputMux {

            CurrentOutputMux() {
                super(4, 4, new CurrentOutputMap());
                setName("Currents");
                RemoteControl rc = getRemoteControl();
                if (rc != null) {
                    rc.addCommandListener(this, CMD_SELECTMUX + getName() + " <channelNumber>", "Selects a multiplexer output");
                }
            }
        }

        // the output muxes on dvs320
        class AllMuxes extends ArrayList<OutputMux> {

            OutputMux[] vmuxes = {new VoltageOutputMux(1), new VoltageOutputMux(2), new VoltageOutputMux(3)};
            OutputMux[] dmuxes = {new LogicMux(1), new LogicMux(2), new LogicMux(3), new LogicMux(4), new LogicMux(5)};
            OutputMux imux = new CurrentOutputMux();

            byte[] formatConfigurationBytes() {
                int nBits = 0;
                StringBuilder s = new StringBuilder();
                for (OutputMux m : this) {
                    s.append(m.getBitString());
                    nBits += m.nSrBits;
                }
                BigInteger bi = new BigInteger(s.toString(), 2);
                byte[] byteArray = bi.toByteArray(); // finds minimal set of bytes in big endian format, with MSB as first element
                // we need to pad out to nbits worth of bytes 
                int nbytes = (nBits % 8 == 0) ? (nBits / 8) : (nBits / 8 + 1); // 8->1, 9->2
                byte[] bytes = new byte[nbytes];
                System.arraycopy(byteArray, 0, bytes, 0, byteArray.length);
//                System.out.println(String.format("%d bytes holding %d actual bits", bytes.length, nBits));
                return bytes;
            }

            AllMuxes() {
                add(imux); // first in list since at end of chain - bits must be sent first, before any biasgen bits
                addAll(Arrays.asList(dmuxes)); // next are 5 logic muxes
                addAll(Arrays.asList(vmuxes)); // finally send the 3 voltage muxes

                // labels go back from end of chain which is imux, followed by pin DigMux4, DigMux3, etc
                imux.put(0, "nTest"); // TODO these are swapped in the schematic on the biasgen symbol
                imux.put(1, "pTest"); // TODO nTest/pTest are swapped in chip biasgen schematic
                imux.put(2, "phC");
                imux.put(3, "NC");

                dmuxes[0].setName("DigMux4");
                dmuxes[1].setName("DigMux3");
                dmuxes[2].setName("DigMux2");
                dmuxes[3].setName("DigMux1");
                dmuxes[4].setName("DigMux0");

                dmuxes[0].put(0, "RXTop");
                dmuxes[0].put(1, "FF1c");
                dmuxes[0].put(2, "ResetFF1c");
                dmuxes[0].put(3, "reqY");
                dmuxes[0].put(4, "reqX");
                dmuxes[0].put(5, "nResetKeeperX");
                dmuxes[0].put(6, "ackX");
                dmuxes[0].put(7, "latch");
                dmuxes[0].put(8, "nAckY");
                dmuxes[0].put(9, "nRXOff");
                dmuxes[0].put(10, "AX");
                dmuxes[0].put(11, "nRXOn");
                dmuxes[0].put(12, "FF2x");
                dmuxes[0].put(13, "FF1x");
                dmuxes[0].put(14, "RXArb");
                dmuxes[0].put(15, "axArb");

                dmuxes[1].put(0, "RXTop");
                dmuxes[1].put(1, "FF1c");
                dmuxes[1].put(2, "ResetFF1c");
                dmuxes[1].put(3, "reqY");
                dmuxes[1].put(4, "reqX");
                dmuxes[1].put(5, "nResetKeeperX");
                dmuxes[1].put(6, "ackX");
                dmuxes[1].put(7, "latch");
                dmuxes[1].put(8, "nAckY");
                dmuxes[1].put(9, "nRXOff");
                dmuxes[1].put(10, "AX");
                dmuxes[1].put(11, "nRXOn");
                dmuxes[1].put(12, "FF2x");
                dmuxes[1].put(13, "FF1x");
                dmuxes[1].put(14, "RXArb");
                dmuxes[1].put(15, "axArb");

                dmuxes[2].put(0, "RXTop");
                dmuxes[2].put(1, "FF1c");
                dmuxes[2].put(2, "ResetFF1c");
                dmuxes[2].put(3, "reqY");
                dmuxes[2].put(4, "reqX");
                dmuxes[2].put(5, "nResetKeeperX");
                dmuxes[2].put(6, "ackX");
                dmuxes[2].put(7, "latch");
                dmuxes[2].put(8, "nAckY");
                dmuxes[2].put(9, "nRXOff");
                dmuxes[2].put(10, "AX");
                dmuxes[2].put(11, "nRXOn");
                dmuxes[2].put(12, "FF2x");
                dmuxes[2].put(13, "FF1x");
                dmuxes[2].put(14, "RXArb");
                dmuxes[2].put(15, "axArb");

                dmuxes[3].put(0, "RXTop");
                dmuxes[3].put(1, "FF1c");
                dmuxes[3].put(2, "ResetFF1c");
                dmuxes[3].put(3, "reqY");
                dmuxes[3].put(4, "reqX");
                dmuxes[3].put(5, "nResetKeeperX");
                dmuxes[3].put(6, "ackX");
                dmuxes[3].put(7, "latch");
                dmuxes[3].put(8, "nAckY");
                dmuxes[3].put(9, "nRXOff");
                dmuxes[3].put(10, "AX");
                dmuxes[3].put(11, "nRXOn");
                dmuxes[3].put(12, "FF2x");
                dmuxes[3].put(13, "FF1x");
                dmuxes[3].put(14, "RXArb");
                dmuxes[3].put(15, "axArb");

                dmuxes[4].put(0, "RXTop");
                dmuxes[4].put(1, "FF1c");
                dmuxes[4].put(2, "ResetFF1c");
                dmuxes[4].put(3, "reqY");
                dmuxes[4].put(4, "reqX");
                dmuxes[4].put(5, "nResetKeeperX");
                dmuxes[4].put(6, "ackX");
                dmuxes[4].put(7, "latch");
                dmuxes[4].put(8, "nAckY");
                dmuxes[4].put(9, "nRXOff");
                dmuxes[4].put(10, "AX");
                dmuxes[4].put(11, "nRXOn");
                dmuxes[4].put(12, "FF2x");
                dmuxes[4].put(13, "FF1x");
                dmuxes[4].put(14, "RXArb");
                dmuxes[4].put(15, "axArb");


                vmuxes[0].setName("AnaMux2");
                vmuxes[1].setName("AnaMux1");
                vmuxes[2].setName("AnaMux0");

                vmuxes[0].put(0, "testVpr");
                vmuxes[0].put(1, "testnResettpixel");
                vmuxes[0].put(2, "testOn");
                vmuxes[0].put(3, "testVd1ff");
                vmuxes[0].put(4, "testAY");
                vmuxes[0].put(5, "testnRY");
                vmuxes[0].put(6, "testAX");
                vmuxes[0].put(7, "testnRXOff");

                vmuxes[1].put(0, "testVpr");
                vmuxes[1].put(1, "testnResettpixel");
                vmuxes[1].put(2, "testOn");
                vmuxes[1].put(3, "testVd1ff");
                vmuxes[1].put(4, "testAY");
                vmuxes[1].put(5, "testnRY");
                vmuxes[1].put(6, "testAX");
                vmuxes[1].put(7, "testnRXOn");

                vmuxes[2].put(0, "testVpr");
                vmuxes[2].put(1, "testnResettpixel");
                vmuxes[2].put(2, "testOn");
                vmuxes[2].put(3, "testVd1ff");
                vmuxes[2].put(4, "testAY");
                vmuxes[2].put(5, "testnRY");
                vmuxes[2].put(6, "testAX");
                vmuxes[2].put(7, "testnOFF");
            }
        }
    }
} 
    
    
