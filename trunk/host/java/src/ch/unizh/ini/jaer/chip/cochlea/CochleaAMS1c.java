/*
 * CochleaAMSWithBiasgen.java
 *
 * Created on November 7, 2006, 11:29 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright November 7, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package ch.unizh.ini.jaer.chip.cochlea;

import ch.unizh.ini.jaer.chip.cochlea.CochleaAMS1c.Biasgen.Scanner;
import ch.unizh.ini.jaer.chip.cochlea.CochleaAMS1cADCSamples.ADCSample;
import ch.unizh.ini.jaer.chip.util.externaladc.ADCHardwareInterfaceProxy;
import ch.unizh.ini.jaer.chip.util.scanner.ScannerHardwareInterfaceProxy;
import ch.unizh.ini.jaer.projects.cochsoundloc.ITDFilter;
import java.util.ArrayList;
import java.util.Observer;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.prefs.PreferenceChangeEvent;
import javax.swing.JComponent;
import javax.swing.JMenuItem;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.biasgen.*;
import net.sf.jaer.biasgen.IPotArray;
import net.sf.jaer.biasgen.VDAC.DAC;
import net.sf.jaer.biasgen.VDAC.VPot;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.graphics.ChipRendererDisplayMethod;
import net.sf.jaer.graphics.DisplayMethod;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.graphics.SpaceTimeEventDisplayMethod;
import net.sf.jaer.hardwareinterface.*;
import com.sun.opengl.util.GLUT;
import java.awt.Graphics2D;
import java.util.Arrays;
import java.util.Iterator;
import java.util.Observable;
import java.util.prefs.PreferenceChangeListener;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.swing.JPanel;
import javax.swing.JSeparator;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import net.sf.jaer.Description;
import net.sf.jaer.hardwareinterface.usb.cypressfx2.CypressFX2;
import net.sf.jaer.util.RemoteControlCommand;
import net.sf.jaer.util.RemoteControlled;

/**
 * Extends Shih-Chii Liu's AMS cochlea AER chip to 
 * add bias generator interface, 
 * to be used when using the on-chip bias generator and the on-board DACs. 
 * This board also includes off-chip ADC for reading microphone inputs and scanned cochlea outputs.
 * The board also includes for the first time a shift-register based CPLD configuration register to configure CPLD functions.
 * Also implements ConfigBits, Scanner, and Equalizer configuration.
 * @author tobi
 */
@Description("Binaural AER silicon cochlea with 64 channels and 8 ganglion cells of two types per channel with many fixes to CochleaAMS1b")
public class CochleaAMS1c extends CochleaAMSNoBiasgen {

    final GLUT glut = new GLUT();
    /** Samples from ADC on CochleaAMS1c PCB */
    private CochleaAMS1cADCSamples adcSamples;
    private ch.unizh.ini.jaer.chip.cochlea.CochleaAMS1c.Biasgen ams1cbiasgen; // used to access scanner e.g. from delegate methods

    /** Creates a new instance of CochleaAMSWithBiasgen */
    public CochleaAMS1c() {
        super();
        setBiasgen((ams1cbiasgen = new CochleaAMS1c.Biasgen(this)));
        getCanvas().setBorderSpacePixels(40);
        setEventExtractor(new CochleaAMS1c.Extractor(this));
        getCanvas().addDisplayMethod(new CochleaAMS1cRollingCochleagramADCDisplayMethod(this));
        for (DisplayMethod m : getCanvas().getDisplayMethods()) {
            if (m instanceof ChipRendererDisplayMethod || m instanceof SpaceTimeEventDisplayMethod) {
                // add labels on frame of chip for these xy chip displays
                m.addAnnotator(new FrameAnnotater() {

                    @Override
                    public void setAnnotationEnabled(boolean yes) {
                    }

                    @Override
                    public boolean isAnnotationEnabled() {
                        return true;
                    }

                    // renders the string starting at x,y,z with angleDeg angle CCW from horizontal in degrees
                    void renderStrokeFontString(GL gl, float x, float y, float z, float angleDeg, String s) {
                        final int font = GLUT.STROKE_ROMAN;
                        final float scale = 2f / 104f; // chars will be about 1 pixel wide
                        gl.glPushMatrix();
                        gl.glTranslatef(x, y, z);
                        gl.glRotatef(angleDeg, 0, 0, 1);
                        gl.glScalef(scale, scale, scale);
                        gl.glLineWidth(2);
                        for (char c : s.toCharArray()) {
                            glut.glutStrokeCharacter(font, c);
                        }
                        gl.glPopMatrix();
                    }                    // chars about 104 model units wide
                    final float xlen = glut.glutStrokeLength(GLUT.STROKE_ROMAN, "channel"), ylen = glut.glutStrokeLength(GLUT.STROKE_ROMAN, "cell type");

                    @Override
                    public void annotate(GLAutoDrawable drawable) {
                        GL gl = drawable.getGL();
//                        gl.glBegin(GL.GL_LINES);
//                        gl.glColor3f(.5f, .5f, 0);
//                        gl.glVertex2f(0, 0);
//                        gl.glVertex2f(getSizeX() - 1, getSizeY() - 1);
//                        gl.glEnd();
                        gl.glPushMatrix();
                        {
                            gl.glColor3f(1, 1, 1); // must set color before raster position (raster position is like glVertex)
                            renderStrokeFontString(gl, -1, 16 / 2 - 5, 0, 90, "cell type");
                            renderStrokeFontString(gl, sizeX / 2 - 4, -3, 0, 0, "channel");
                            renderStrokeFontString(gl, 0, -3, 0, 0, "hi fr");
                            renderStrokeFontString(gl, sizeX - 15, -3, 0, 0, "low fr");
                        }
                        gl.glPopMatrix();
                    }
                });
                // add basic ADC samples drawing
//                m.addAnnotator(new FrameAnnotater() {
//
//                    @Override
//                    public void setAnnotationEnabled(boolean yes) {
//                    }
//
//                    @Override
//                    public boolean isAnnotationEnabled() {
//                        return true;
//                    }
//
//                    // renders the string starting at x,y,z with angleDeg angle CCW from horizontal in degrees
//                    void renderStrokeFontString(GL gl, float x, float y, float z, float angleDeg, String s) {
//                        final int font = GLUT.STROKE_ROMAN;
//                        final float scale = 2f / 104f; // chars will be about 1 pixel wide
//                        gl.glPushMatrix();
//                        gl.glTranslatef(x, y, z);
//                        gl.glRotatef(angleDeg, 0, 0, 1);
//                        gl.glScalef(scale, scale, scale);
//                        gl.glLineWidth(2);
//                        for (char c : s.toCharArray()) {
//                            glut.glutStrokeCharacter(font, c);
//                        }
//                        gl.glPopMatrix();
//                    }                    // chars about 104 model units wide
//                    final float xlen = glut.glutStrokeLength(GLUT.STROKE_ROMAN, "channel"), ylen = glut.glutStrokeLength(GLUT.STROKE_ROMAN, "cell type");
//
//                    @Override
//                    public void annotate(GLAutoDrawable drawable) {
//                        GL gl = drawable.getGL();
//                        gl.glPushMatrix();
//                        {
//                            adcSamples.swapBuffers();
//                            for (int i = 0; i < CochleaAMS1cADCSamples.NUM_CHANNELS; i++) {
//                                CochleaAMS1cADCSamples.ChannelBuffer cb = adcSamples.currentReadingDataBuffer.channelBuffers[i];
//                                int dt = cb.deltaTime();
//                                if (!cb.hasData() || dt == 0) {
//                                    continue;
//                                }
//                                ADCSample[] samples = cb.samples;
//                                int t0=samples[0].time;
//                                gl.glColor3f(1, 1, 1); // must set color before raster position (raster position is like glVertex)
//                                gl.glBegin(GL.GL_LINE_STRIP);
//                                int n=cb.size();
//                                for (int j=0;j<n;j++) {
//                                    ADCSample s=samples[j];
//                                    gl.glVertex2f(sizeX * ((float) (s.time-t0) / dt), sizeY * ((float) s.data / CochleaAMS1cADCSamples.MAX_ADC_VALUE));
//                                }
//                                gl.glEnd();
//                            }
//                        }
//                        gl.glPopMatrix();
//                    }
//                }); // annotater for adc samples
            }

        }
        adcSamples = new CochleaAMS1cADCSamples(this); // need biasgen / scanner first

    }

    private JComponent help1, help2,help3;
    
    @Override
    public void onDeregistration() {
        super.onDeregistration();
        if(getAeViewer()==null) return;
        getAeViewer().removeHelpItem(help1);
        getAeViewer().removeHelpItem(help2);
        getAeViewer().removeHelpItem(help3);
    }

    @Override
    public void onRegistration() {
        super.onRegistration();
        if(getAeViewer()==null) return;
        help1=getAeViewer().addHelpItem(new JSeparator());
        help1=getAeViewer().addHelpURLItem("https://svn.ini.uzh.ch/repos/tobi/cochlea/pcbs/CochleaAMS1c_USB/cochleaams1c.pdf", "CochleaAMS1c PCB design", "Protel design of board");
        help2=getAeViewer().addHelpURLItem("https://svn.ini.uzh.ch/repos/tobi/cochlea/pcbs/CochleaAMS1c_USB/CochleaAMS1c readme.pdf", "CochleaAMS1c README", "README file for CochleaAMS1c");
     }
    
    

    /** overrides the Chip setHardware interface to construct a biasgen if one doesn't exist already.
     * Sets the hardware interface and the bias generators hardware interface
     *@param hardwareInterface the interface
     */
    @Override
    public void setHardwareInterface(final HardwareInterface hardwareInterface) {
        this.hardwareInterface = hardwareInterface;
        try {
            if (getBiasgen() == null) {
                setBiasgen(new CochleaAMS1c.Biasgen(this));
            } else {
                getBiasgen().setHardwareInterface((BiasgenHardwareInterface) hardwareInterface); // from blank device we isSet bare CypressFX2 which is notifyChange BiasgenHardwareInterface so biasgen hardware interface is notifyChange set yet
            }
        } catch (ClassCastException e) {
            System.err.println(e.getMessage() + ": probably this chip object has a biasgen but the hardware interface doesn't, ignoring");
        }
    }

    /**
     * @return the adcSamples
     */
    public CochleaAMS1cADCSamples getAdcSamples() {
        return adcSamples;
    }

    interface ConfigBase {

        void addObserver(Observer o);

        String getName();

        String getDescription();
    }
    // following used in configuration

    interface ConfigBit extends ConfigBase {

        boolean isSet();

        void set(boolean yes);
    }

    interface ConfigInt extends ConfigBase {

        int get();

        void set(int v) throws IllegalArgumentException;
    }

    interface ConfigTristate extends ConfigBit {

        boolean isHiZ();

        void setHiZ(boolean yes);
    }

    public enum OffChipPreampGain {

        Low(0, "Low (40dB)"),
        Medium(1, "Medium (50dB)"),
        High(2, "High (60dB)");
        private final int code;
        private final String label;

        OffChipPreampGain(int code, String label) {
            this.code = code;
            this.label = label;
        }

        public int code() {
            return code;
        }

        public String label() {
            return label;
        }
    };

    public enum OffChipPreamp_AGC_AR_Ratio {

        Fast(0, "Fast (1:500)"),
        Medium(1, "Medium (1:2000)"),
        Slow(2, "Slow (1:4000)");
        private final int code;
        private final String label;

        OffChipPreamp_AGC_AR_Ratio(int code, String label) {
            this.code = code;
            this.label = label;
        }

        public int code() {
            return code;
        }

        public String label() {
            return label;
        }
    };

    public enum Tristate {

        High, Low, HiZ;

        public boolean isHigh() {
            return this == Tristate.High;
        }

        public boolean isLow() {
            return this == Tristate.Low;
        }

        public boolean isHiZ() {
            return this == Tristate.HiZ;
        }
    }

    public class Biasgen extends net.sf.jaer.biasgen.Biasgen implements net.sf.jaer.biasgen.ChipControlPanel {

        private final short ADC_CONFIG = (short) 0x100;   //normal power mode, single ended, sequencer unused : (short) 0x908;
        private OnChipPreamp onchipPreamp;
        private OffChipPreamp offchipPreampLeft;
        private OffChipPreamp offchipPreampRight;
        private OffChipPreampARRatio offchipPreampARRatio;
        private ArrayList<HasPreference> hasPreferencesList = new ArrayList<HasPreference>();
        // lists of ports and CPLD config
        ArrayList<PortBit> portBits = new ArrayList();
        ArrayList<CPLDConfigValue> cpldConfigValues = new ArrayList();
        ArrayList<AbstractConfigValue> config = new ArrayList<AbstractConfigValue>();
        /** The DAC on the board. Specified with 5V reference even though Vdd=3.3 because the internal 2.5V reference is used and so that the VPot controls display correct voltage. */
        protected final DAC dac = new DAC(32, 12, 0, 5f, 3.3f); // the DAC object here is actually 2 16-bit DACs daisy-chained on the Cochlea board; both corresponding values need to be sent to change one value
        IPotArray ipots = new IPotArray(this);
        PotArray vpots = new PotArray(this);
//        private IPot diffOn, diffOff, refr, pr, sf, diff;
        private CypressFX2 cypress = null;
        // config bits/values
        // portA
        private PortBit hostResetTimestamps = new PortBit("a7", "hostResetTimestamps", "High to reset timestamps", false),
                runAERComm = new PortBit("a3", "runAERComm", "High to run CPLD state machine (send events)- also controls CPLDLED2", true);
//                timestampMaster = new PortBit("a1", "timestampMaster", "High to make this the master AER timing source"); // output from CPLD to signify it is the master
        // portC
        private PortBit runAdc = new PortBit("c0", "runAdc", "High to run ADC", true);
        // portD
        private PortBit vCtrlKillBit = new PortBit("d6", "vCtrlKill", "Setting high resets all neuron kill bit latches, but aerKillBit needs to be high also", false),
                aerKillBit = new PortBit("d7", "aerKillBit", "Set high to kill a neuron which is selected by address loaded via the Equalizer GUI; not used except to unkill all neurons with vCtrlKill", false);
        // portE
        // tobi changed config bits on rev1 board since e3/4 control maxim mic preamp attack/release and gain now

        private class PowerDownBit extends PortBit implements Observer {

            public PowerDownBit(Masterbias masterBias, String portBit, String name, String tip, boolean def) {
                super(portBit, name, tip, def);
                masterBias.addObserver(this);
            }

            @Override
            public void update(Observable o, Object arg) {
                if (o instanceof Masterbias) {
                    Masterbias m = (Masterbias) o;
                    if (arg != null && arg == Masterbias.EVENT_POWERDOWN) {
                        set(m.isPowerDownEnabled());
                    }
                }
            }
        }
        private PowerDownBit powerDown;
        private PortBit nCochleaReset = new PortBit("e3", "nCochleaReset", "High to reset all neuron and Q latches; global latch reset (1=reset); aka vReset", true);
//                nCpldReset = new PortBit("e7", "nCpldReset", "Low to reset CPLD"); // don't expose this, firmware unresets on init
        // CPLD config on CPLD shift register
        private CPLDBit yBit = new CPLDBit(0, "yBit", "Used to select whether bandpass (0) or lowpass (1) neurons are killed for local kill", false),
                selAER = new CPLDBit(3, "selAER", "Chooses whether lpf (0) or rectified (1) lpf output drives low-pass filter neurons", true),
                selIn = new CPLDBit(4, "selIn", "Parallel (1) or Cascaded (0) cochlea architecture", false);
        private CPLDInt onchipPreampGain = new CPLDInt(1, 2, "onchipPreampGain", "chooses onchip microphone preamp feedback resistor selection", 3);
        // adc configuration is stored in adcProxy; updates to here should update CPLD config below
        private CPLDInt adcConfig = new CPLDInt(11, 22, "adcConfig", "determines configuration of ADC - value depends on channel and sequencing enabled " + ADC_CONFIG, ADC_CONFIG),
                adcTrackTime = new CPLDInt(23, 38, "adcTrackTime", "ADC track time in clock cycles which are 15 cycles/us", 0),
                adcIdleTime = new CPLDInt(39, 54, "adcIdleTime", "ADC idle time after last acquisition in clock cycles which are 15 cycles/us", 0);
        // scanner config stored in scannerProxy; updates should update state of below fields
        private CPLDInt scanX = new CPLDInt(55, 61, "scanChannel", "cochlea tap to monitor when not scanning continuously", 0);
        private CPLDBit scanSel = new CPLDBit(62, "scanSel", "selects which on-chip cochlea scanner shift register to monitor for sync (0=BM, 1=Gang Cells) - also turns on CPLDLED1 near FXLED1", false), // TODO firmware controlled?
                scanContinuouslyEnabled = new CPLDBit(63, "scanContinuouslyEnabled", "enables continuous scanning of on-chip scanner", true);
        // preamp config stored in preamp objects
        // preamp left/right bits are swapped here to correspond to board
        private TriStateableCPLDBit preampAR = new TriStateableCPLDBit(5, 6, "preampAttackRelease", "offchip preamp attack/release ratio (0=attack/release ratio=1:500, 1=A/R=1:2000, HiZ=A/R=1:4000)", Tristate.Low),
                preampGainRight = new TriStateableCPLDBit(9, 10, "preampGain.Right", "offchip preamp gain bit (1=gain=40dB, 0=gain=50dB, HiZ=60dB if preamp threshold \"PreampAGCThreshold (TH)\"is set above 2V)", Tristate.HiZ),
                preampGainLeft = new TriStateableCPLDBit(7, 8, "preampGain.Left", "offchip preamp gain bit (1=gain=40dB, 0=gain=50dB, HiZ=60dB if preamp threshold \"PreampAGCThreshold (TH)\"is set above 2V)", Tristate.HiZ);
        // store all values here, then iterate over this array to build up CPLD shift register stuff and dialogs
//        volatile AbstractConfigValue[] config = {hostResetTimestamps, runAERComm,
//            runAdc, vCtrlKillBit, aerKillBit,
//            powerDown, nCochleaReset, yBit, selAER, selIn, onchipPreampGain,
//            adcConfig, adcTrackTime, adcIdleTime, scanX, scanSel,
//            scanContinuouslyEnabled, preampAR, preampGainLeft, preampGainRight
//        };
        CPLDConfig cpldConfig;
        /*
        #define DataSel 	1	// selects data shift register path (bitIn, clock, latch)
        #define AddrSel 	2	// selects channel selection shift register path
        #define BiasGenSel 	4	// selects biasgen shift register path
        #define ResCtr1 	8	// a preamp feedback resistor selection bitmask
        #define ResCtr2 	16	// another microphone preamp feedback resistor selection bitmask
        #define Vreset		32	// (1) to reset latch states
        #define SelIn		64	// Parallel (0) or Cascaded (1) Arch
        #define Ybit		128	// Chooses whether lpf (0) or bpf (1) neurons to be killed, use in conjunction with AddrSel and AERKillBit
         */
        Equalizer equalizer = new Equalizer();
        BufferIPot bufferIPot = new BufferIPot();
        boolean dacPowered = getPrefs().getBoolean("CochleaAMS1c.Biasgen.DAC.powered", true);
        private final VPot preampAGCThresholdPot; // used in Microphone preamp control panel
        // wraps around ADC, updates come back here to send CPLD config to hardware. Proxy used in GUI.
        private ADC adcProxy;
        private Scanner scanner;

        /** Creates a new instance of Biasgen for Tmpdiff128 with a given hardware interface
         *@param chip the chip this biasgen belongs to
         */
        public Biasgen(Chip chip) {
            super(chip);
            setName("CochleaAMS1c.Biasgen");
            powerDown = new PowerDownBit(getMasterbias(), "e2", "powerDown", "High to power down bias generator", false);
            equalizer.addObserver(this);
            bufferIPot.addObserver(this);

            cpldConfig = new CPLDConfig();  // stores everything in the CPLD configuration shift register
            for (CPLDConfigValue c : cpldConfigValues) {
                cpldConfig.add(c);
            }
            onchipPreamp = new OnChipPreamp(onchipPreampGain);
            offchipPreampLeft = new OffChipPreamp(preampGainLeft, Ear.Left);
            offchipPreampRight = new OffChipPreamp(preampGainRight, Ear.Right);
            offchipPreampARRatio = new OffChipPreampARRatio(preampAR);



            // inspect config to build up CPLDConfig

//    public IPot(Biasgen biasgen, String name, int shiftRegisterNumber, final Type type, Sex sex, int bitValue, int displayPosition, String tooltipString) {
            potArray = new IPotArray(this); //construct IPotArray whit shift register stuff

            ipots.addPot(new IPot(this, "VAGC", 0, IPot.Type.NORMAL, IPot.Sex.N, 0, 1, "Sets reference for AGC diffpair in SOS"));  // second to list bits loaded, just before buffer bias bits. displayed first in GUI
            ipots.addPot(new IPot(this, "Curstartbpf", 1, IPot.Type.NORMAL, IPot.Sex.P, 0, 2, "Sets master current to local DACs for BPF Iq"));
            ipots.addPot(new IPot(this, "DacBufferNb", 2, IPot.Type.NORMAL, IPot.Sex.N, 0, 3, "Sets bias current of amp in local DACs"));
            ipots.addPot(new IPot(this, "Vbp", 3, IPot.Type.NORMAL, IPot.Sex.P, 0, 4, "Sets bias for readout amp of BPF"));
            ipots.addPot(new IPot(this, "Ibias20OpAmp", 4, IPot.Type.NORMAL, IPot.Sex.P, 0, 5, "Bias current for preamp"));
//            ipots.addPot(new IPot(this, "N.C.", 5, IPot.Type.NORMAL, IPot.Sex.N, 0, 6, "not used"));
            ipots.addPot(new IPot(this, "Vioff", 5, IPot.Type.NORMAL, IPot.Sex.P, 0, 11, "Sets DC shift input to LPF"));
            ipots.addPot(new IPot(this, "Vsetio", 6, IPot.Type.CASCODE, IPot.Sex.P, 0, 7, "Sets 2I0 and I0 for LPF time constant"));
            ipots.addPot(new IPot(this, "Vdc1", 7, IPot.Type.NORMAL, IPot.Sex.P, 0, 8, "Sets DC shift for close end of cascade"));
            ipots.addPot(new IPot(this, "NeuronRp", 8, IPot.Type.NORMAL, IPot.Sex.P, 0, 9, "Sets bias current of neuron"));
            ipots.addPot(new IPot(this, "Vclbtgate", 9, IPot.Type.NORMAL, IPot.Sex.P, 0, 10, "Bias gate of CLBT"));
            ipots.addPot(new IPot(this, "N.C.", 10, IPot.Type.NORMAL, IPot.Sex.N, 0, 6, "not used"));
//            ipots.addPot(new IPot(this, "Vioff", 10, IPot.Type.NORMAL, IPot.Sex.P, 0, 11, "Sets DC shift input to LPF"));
            ipots.addPot(new IPot(this, "Vbias2", 11, IPot.Type.NORMAL, IPot.Sex.P, 0, 12, "Sets lower cutoff freq for cascade"));
            ipots.addPot(new IPot(this, "Ibias10OpAmp", 12, IPot.Type.NORMAL, IPot.Sex.P, 0, 13, "Bias current for preamp"));
            ipots.addPot(new IPot(this, "Vthbpf2", 13, IPot.Type.CASCODE, IPot.Sex.P, 0, 14, "Sets high end of threshold current for bpf neurons"));
            ipots.addPot(new IPot(this, "Follbias", 14, IPot.Type.NORMAL, IPot.Sex.N, 0, 15, "Bias for PADS"));
            ipots.addPot(new IPot(this, "pdbiasTX", 15, IPot.Type.NORMAL, IPot.Sex.N, 0, 16, "pulldown for AER TX"));
            ipots.addPot(new IPot(this, "Vrefract", 16, IPot.Type.NORMAL, IPot.Sex.N, 0, 17, "Sets refractory period for AER neurons"));
            ipots.addPot(new IPot(this, "VbampP", 17, IPot.Type.NORMAL, IPot.Sex.P, 0, 18, "Sets bias current for input amp to neurons"));
            ipots.addPot(new IPot(this, "Vcascode", 18, IPot.Type.CASCODE, IPot.Sex.N, 0, 19, "Sets cascode voltage"));
            ipots.addPot(new IPot(this, "Vbpf2", 19, IPot.Type.NORMAL, IPot.Sex.P, 0, 20, "Sets lower cutoff freq for BPF"));
            ipots.addPot(new IPot(this, "Ibias10OTA", 20, IPot.Type.NORMAL, IPot.Sex.N, 0, 21, "Bias current for OTA in preamp"));
            ipots.addPot(new IPot(this, "Vthbpf1", 21, IPot.Type.CASCODE, IPot.Sex.P, 0, 22, "Sets low end of threshold current to bpf neurons"));
            ipots.addPot(new IPot(this, "Curstart ", 22, IPot.Type.NORMAL, IPot.Sex.P, 0, 23, "Sets master current to local DACs for SOS Vq"));
            ipots.addPot(new IPot(this, "Vbias1", 23, IPot.Type.NORMAL, IPot.Sex.P, 0, 24, "Sets higher cutoff freq for SOS"));
            ipots.addPot(new IPot(this, "NeuronVleak", 24, IPot.Type.NORMAL, IPot.Sex.P, 0, 25, "Sets leak current for neuron"));
            ipots.addPot(new IPot(this, "Vioffbpfn", 25, IPot.Type.NORMAL, IPot.Sex.N, 0, 26, "Sets DC level for input to bpf"));
            ipots.addPot(new IPot(this, "Vcasbpf", 26, IPot.Type.CASCODE, IPot.Sex.P, 0, 27, "Sets cascode voltage in cm BPF"));
            ipots.addPot(new IPot(this, "Vdc2", 27, IPot.Type.NORMAL, IPot.Sex.P, 0, 28, "Sets DC shift for SOS at far end of cascade"));
            ipots.addPot(new IPot(this, "Vterm", 28, IPot.Type.CASCODE, IPot.Sex.N, 0, 29, "Sets bias current of terminator xtor in diffusor"));
            ipots.addPot(new IPot(this, "Vclbtcasc", 29, IPot.Type.CASCODE, IPot.Sex.P, 0, 30, "Sets cascode voltage in CLBT"));
            ipots.addPot(new IPot(this, "reqpuTX", 30, IPot.Type.NORMAL, IPot.Sex.P, 0, 31, "Sets pullup bias for AER req ckts"));
            ipots.addPot(new IPot(this, "Vbpf1", 31, IPot.Type.NORMAL, IPot.Sex.P, 0, 32, "Sets higher cutoff freq for BPF"));   // first bits loaded, at end of shift register

            getMasterbias().addObserver(powerDown);

//    public VPot(Chip chip, String name, DAC dac, int channel, Type type, Sex sex, int bitValue, int displayPosition, String tooltipString) {
            // top dac in schem/layout, first 16 channels of 32 total
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vterm", dac, 0, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets bias current of terminator xtor in diffusor"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefhres", dac, 1, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets source of terminator xtor in diffusor"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "VthAGC", dac, 2, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets input to diffpair that generates VQ"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefreadout", dac, 3, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets reference for readout amp"));
//            vpots.addPot(new VPot(CochleaAMS1c.this, "Vbpf2x", dac,         4, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "BiasDACBufferNBias", dac, 4, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets bias current of buffer in pixel DACs"));
//            vpots.addPot(new VPot(CochleaAMS1c.this, "Vbias2x", dac,        5, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefract", dac, 5, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets refractory period of neuron"));
//            vpots.addPot(new VPot(CochleaAMS1c.this, "Vbpf1x", dac,         6, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));
            vpots.addPot(preampAGCThresholdPot = new VPot(CochleaAMS1c.this, "PreampAGCThreshold (TH)", dac, 6, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Threshold for microphone preamp AGC gain reduction turn-on"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefpreamp", dac, 7, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets virtual group of microphone drain preamp"));
//            vpots.addPot(new VPot(CochleaAMS1c.this, "Vbias1x", dac,        8, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "NeuronRp", dac, 8, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets bias current of neuron comparator- overrides onchip bias"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vthbpf1x", dac, 9, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets threshold for BPF neuron"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vioffbpfn", dac, 10, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets DC level for BPF input"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "NeuronVleak", dac, 11, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets leak current for neuron - not connected on board"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "DCOutputLevel", dac, 12, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Microphone DC output level to cochlea chip"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vthbpf2x", dac, 13, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets threshold for BPF neuron"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "DACSpOut2", dac, 14, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "DACSpOut1", dac, 15, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "test dac bias"));

            // bot DAC in schem/layout, 2nd 16 channels
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vth4", dac, 16, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets high VT for LPF neuron"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vcas2x", dac, 17, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets cascode voltage for subtraction of neighboring filter outputs"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefo", dac, 18, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets src for output of CM LPF"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefn2", dac, 19, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets DC gain gain cascode bias in BPF"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vq", dac, 20, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets tau of feedback amp in SOS"));

            vpots.addPot(new VPot(CochleaAMS1c.this, "Vpf", dac, 21, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets bias current for scanner follower"));

            vpots.addPot(new VPot(CochleaAMS1c.this, "Vgain", dac, 22, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets bias for differencing amp in BPF/LPF"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vrefn", dac, 23, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets cascode bias in BPF"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "VAI0", dac, 24, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets tau of CLBT for ref current"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vdd1", dac, 25, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets up power to on-chip DAC"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vth1", dac, 26, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets low VT for LPF neuron"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vref", dac, 27, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets src for input of CM LPF"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vtau", dac, 28, Pot.Type.NORMAL, Pot.Sex.P, 0, 0, "Sets tau of forward amp in SOS"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "VcondVt", dac, 29, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "Sets VT of conductance neuron"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vpm", dac, 30, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "sets bias of horizontal element of diffusor"));
            vpots.addPot(new VPot(CochleaAMS1c.this, "Vhm", dac, 31, Pot.Type.NORMAL, Pot.Sex.N, 0, 0, "sets bias of horizontal element of diffusor"));
//            Pot.setModificationTrackingEnabled(false); // don't flag all biases modified on construction

            // ADC
            adcProxy = new ADC(CochleaAMS1c.this); // notifies us with updates 
            adcProxy.setMaxADCchannelValue(3);
            adcProxy.setMaxIdleTimeValue(0xffff / 15);
            adcProxy.setMaxTrackTimeValue(0xffff / 15);
            adcProxy.setMinTrackTimeValue(1);
            adcProxy.setMinIdleTimeValue(0);
            adcProxy.addObserver(this);

            // scanner proxy gets updated from scanner hardware bit changes
            scanner = new Scanner(CochleaAMS1c.this);
            scanContinuouslyEnabled.addObserver(scanner);
            scanX.addObserver(scanner);
            scanSel.addObserver(scanner);
            scanner.addObserver(this);

            for (PortBit b : portBits) {
                b.addObserver(this);
            }

            for (CPLDConfigValue c : cpldConfigValues) {
                c.addObserver(this);
            }

            loadPreferences();
//            Pot.setModificationTrackingEnabled(true);
        }

        void setOnchipGain(OnChipPreampGain gain) {
            getOnchipPreamp().setGain(gain);
        }

        OnChipPreampGain getOnchipGain() {
            return getOnchipPreamp().getGain();
        }

        void setOffchipLeftGain(OffChipPreampGain gain) {
            getOffchipPreampLeft().setGain(gain);
        }

        OffChipPreampGain getOffchipLeftGain() {
            return getOffchipPreampLeft().getGain();
        }

        void setOffchipRightGain(OffChipPreampGain gain) {
            getOffchipPreampRight().setGain(gain);
        }

        OffChipPreampGain getOffchipRightGain() {
            return getOffchipPreampRight().getGain();
        }

        public void setArRatio(OffChipPreamp_AGC_AR_Ratio arRatio) {
            offchipPreampARRatio.setArRatio(arRatio);
        }

        public OffChipPreamp_AGC_AR_Ratio getArRatio() {
            return offchipPreampARRatio.getArRatio();
        }

        @Override
        public void loadPreferences() {
            super.loadPreferences();
            if (hasPreferencesList != null) {
                for (HasPreference hp : hasPreferencesList) {
                    hp.loadPreference();
                }
            }
            if (ipots != null) {
                ipots.loadPreferences();
            }
            if (vpots != null) {
                vpots.loadPreferences();
            }
        }

        @Override
        public void storePreferences() {
            super.storePreferences();
            ipots.storePreferences();
            vpots.storePreferences();
            for (HasPreference hp : hasPreferencesList) {
                hp.storePreference();
            }
        }

        @Override
        public JPanel buildControlPanel() {
            CochleaAMS1cControlPanel myControlPanel = new CochleaAMS1cControlPanel(CochleaAMS1c.this);
            return myControlPanel;
        }

        @Override
        public void setHardwareInterface(BiasgenHardwareInterface hw) {
//            super.setHardwareInterface(hardwareInterface); // don't delegrate to super, handle entire configuration sending here
            if (hw == null) {
                cypress = null;
                hardwareInterface = null;
                return;
            }
            if (hw instanceof CochleaAMS1cHardwareInterface) {
                hardwareInterface = hw;
                cypress = (CypressFX2) hardwareInterface;
                log.info("set hardwareInterface CochleaAMS1cHardwareInterface=" + hardwareInterface.toString());
                try {
                    sendConfiguration();
                    //                resetAERComm();
                } catch (HardwareInterfaceException ex) {
                    log.warning(ex.toString());
                }
            }
        }
        /** Vendor request command understood by the cochleaAMS1c firmware in connection with  VENDOR_REQUEST_SEND_BIAS_BYTES */
        public final short CMD_IPOT = 1, CMD_RESET_EQUALIZER = 2,
                CMD_SCANNER = 3, CMD_EQUALIZER = 4,
                CMD_SETBIT = 5, CMD_VDAC = 6, CMD_INITDAC = 7,
                CMD_CPLD_CONFIG = 8;
        public final String[] CMD_NAMES = {"IPOT", "RESET_EQUALIZER", "SCANNER", "EQUALIZER", "SET_BIT", "VDAC", "INITDAC", "CPLD_CONFIG"};
        final byte[] emptyByteArray = new byte[0];

//        /** Does special reset cycle, in background thread TODO unused now */
//        void resetAERComm() {
//            Runnable r = new Runnable() {
//
//                @Override
//                public void run() {
//                    yBit.set(true);
//                    aerKillBit.set(false); // after kill bit changed, must wait
////                    nCpldReset.set(true);
//                    //  yBit.set(true);
//                    //           aerKillBit.set(false); // after kill bit changed, must wait
//                    try {
//                        Thread.sleep(50);
//                    } catch (InterruptedException e) {
//                    }
////                    nCpldReset.set(false);
//                    aerKillBit.set(true);
//                    try {
//                        Thread.sleep(50);
//                    } catch (InterruptedException e) {
//                    }
//                    yBit.set(false);
//                    aerKillBit.set(false);
//                    log.info("AER communication reset by toggling configuration bits");
//                    sendConfiguration();
//                }
//            };
//            Thread t = new Thread(r, "ResetAERComm");
//            t.start();
//        }
        /** convenience method for sending configuration to hardware. Sends vendor request VENDOR_REQUEST_SEND_BIAS_BYTES with subcommand cmd, index index and bytes bytes.
         * 
         * @param cmd the subcommand to set particular configuration, e.g. CMD_CPLD_CONFIG
         * @param index unused
         * @param bytes the payload
         * @throws HardwareInterfaceException 
         */
        void sendConfig(int cmd, int index, byte[] bytes) throws HardwareInterfaceException {

            // debug
            System.out.print(String.format("sending config cmd 0x%X, index=0x%X, with %d bytes", cmd, index, bytes.length));
            if (bytes == null || bytes.length == 0) {
                System.out.println("");
            } else {
                int max = 8;
                if (bytes.length < max) {
                    max = bytes.length;
                }
                System.out.print(" = ");
                for (int i = 0; i < max; i++) {
                    System.out.print(String.format("%X, ", bytes[i]));
                }
                System.out.println("");
            } // end debug


            if (bytes == null) {
                bytes = emptyByteArray;
            }
//            log.info(String.format("sending command vendor request cmd=%d, index=%d, and %d bytes", cmd, index, bytes.length));
            if (cypress != null) {
                cypress.sendVendorRequest(CypressFX2.VENDOR_REQUEST_SEND_BIAS_BYTES, (short) (0xffff & cmd), (short) (0xffff & index), bytes); // & to prevent sign extension for negative shorts
            }
        }

        /** convenience method for sending configuration to hardware. Sends vendor request VENDOR_REQUEST_SEND_BIAS_BYTES with subcommand cmd, index index and empty byte array.
         * 
         * @param cmd
         * @param index
         * @throws HardwareInterfaceException 
         */
        void sendConfig(int cmd, int index) throws HardwareInterfaceException {
            sendConfig(cmd, index, emptyByteArray);
        }

        /** The central point for communication with HW from biasgen. All objects in Biasgen are Observables
        and add Biasgen.this as Observer. They then call notifyObservers when their state changes.
         * Objects such as adcProxy store preferences for ADC, and update should update the hardware registers accordingly.
         * @param observable IPot, Scanner, etc
         * @param object notifyChange used at present
         */
        @Override
        synchronized public void update(Observable observable, Object object) {  // thread safe to ensure gui cannot retrigger this while it is sending something
//            if (!(observable instanceof CochleaAMS1c.Biasgen.Equalizer.EqualizerChannel)) {
//                log.info("Observable=" + observable + " Object=" + object);
//            }
//            if (cypress == null) { // TODO only really for debugging do we need to do even if no hardware
//                return;
//            }
            // sends a vendor request depending on type of update
            // vendor request is always VR_CONFIG
            // value is the type of update
            // index is sometimes used for 16 bitmask updates
            // bytes are the rest of data
            try {
                if (observable instanceof IPot || observable instanceof BufferIPot) { // must send all IPot values and set the select to the ipot shift register, this is done by the cypress
                    byte[] bytes = new byte[1 + ipots.getNumPots() * ipots.getPots().get(0).getNumBytes()];
                    int ind = 0;
                    Iterator itr = ((IPotArray) ipots).getShiftRegisterIterator();
                    while (itr.hasNext()) {
                        IPot p = (IPot) itr.next(); // iterates in order of shiftregister index, from Vbpf to VAGC
                        byte[] b = p.getBinaryRepresentation();
                        System.arraycopy(b, 0, bytes, ind, b.length);
                        ind += b.length;
                    }
                    bytes[ind] = (byte) bufferIPot.getValue(); // isSet 8 bitmask buffer bias value, this is *last* byte sent because it is at start of biasgen shift register
                    sendConfig(CMD_IPOT, 0, bytes); // the usual packing of ipots
                } else if (observable instanceof VPot) {
                    // There are 2 16-bit AD5391 DACs daisy chained; we need to send data for both 
                    // to change one of them. We can send all zero bytes to the one we're notifyChange changing and it will notifyChange affect any channel
                    // on that DAC. We also take responsibility to formatting all the bytes here so that they can just be piped out
                    // surrounded by nSync low during the 48 bit write on the controller.
                    VPot p = (VPot) observable;
                    sendDAC(p);
                } else if (observable instanceof TriStateablePortBit) { // tristateable should come first before configbit since it is subclass
                    TriStateablePortBit b = (TriStateablePortBit) observable;
                    byte[] bytes = {(byte) ((b.isSet() ? (byte) 1 : (byte) 0) | (b.isHiZ() ? (byte) 2 : (byte) 0))};
                    sendConfig(CMD_SETBIT, b.portbit, bytes); // sends value=CMD_SETBIT, index=portbit with (port(b=0,d=1,e=2)<<8)|bitmask(e.g. 00001000) in MSB/LSB, byte[0]= OR of value (1,0), hiZ=2/0, bit is set if tristate, unset if driving port
                } else if (observable instanceof PortBit) {
                    PortBit b = (PortBit) observable;
                    byte[] bytes = {b.isSet() ? (byte) 1 : (byte) 0};
                    sendConfig(CMD_SETBIT, b.portbit, bytes); // sends value=CMD_SETBIT, index=portbit with (port(b=0,d=1,e=2)<<8)|bitmask(e.g. 00001000) in MSB/LSB, byte[0]=value (1,0)
                } else if (observable instanceof CPLDConfigValue) {
                    sendCPLDConfig();
                    // sends value=CMD_SETBIT, index=portbit with (port(b=0,d=1,e=2)<<8)|bitmask(e.g. 00001000) in MSB/LSB, byte[0]=value (1,0)
                } else if (observable instanceof ch.unizh.ini.jaer.chip.cochlea.CochleaAMS1c.Biasgen.Scanner) {// TODO resolve with scannerProxy
// already handled by bits
//                    scanSel.set(true);
//                    scanX.set(scanner.getScanX());
//                    scanContinuouslyEnabled.set(scanner.isScanContinuouslyEnabled()); // must update cpld config bits from software scanner object
//                    byte[] bytes = cpldConfig.getBytes();
//                    sendConfig(CMD_CPLD_CONFIG, 0, bytes);
                } else if (observable instanceof Equalizer.EqualizerChannel) {
                    // sends 0 byte message (no data phase for speed)
                    Equalizer.EqualizerChannel c = (Equalizer.EqualizerChannel) observable;
                    int value = (c.channel << 8) + CMD_EQUALIZER; // value has cmd in LSB, channel in MSB
                    int index = c.qsos + (c.qbpf << 5) + (c.lpfkilled ? 1 << 10 : 0) + (c.bpfkilled ? 1 << 11 : 0); // index has b11=bpfkilled, b10=lpfkilled, b9:5=qbpf, b4:0=qsos
                    sendConfig(value, index);
//                        System.out.println(String.format("channel=%50s value=%16s index=%16s",c.toString(),Integer.toBinaryString(0xffff&value),Integer.toBinaryString(0xffff&index)));
                    // killed byte has 2 lsbs with bitmask 1=lpfkilled, bitmask 0=bpf killed, active high (1=kill, 0=alive)
                } else if (observable instanceof Equalizer) {
                    // TODO everything is in the equalizer channel, nothing yet in equalizer (e.g global settings)
                } else if (observable instanceof OnChipPreamp) { // TODO check if nothing needs to be done on update
                } else if (observable instanceof OffChipPreamp) {
                } else if (observable instanceof ADCHardwareInterfaceProxy) {
                    adcIdleTime.set(adcProxy.getIdleTime() * 15); // multiplication with 15 to get from us to clockcycles
                    adcTrackTime.set(adcProxy.getTrackTime() * 15); // multiplication with 15 to get from us to clockcycles
                    int lastChan = adcProxy.getADCChannel();
                    boolean seq = adcProxy.isSequencingEnabled();
                    // from AD7933/AD7934 datasheet
                    int config = (1 << 8) + (lastChan << 5) + (seq ? 6 : 0);
                    adcConfig.set(config);
                    sendCPLDConfig();
                    runAdc.setChanged();
                    runAdc.notifyObservers();
                } else {
                    super.update(observable, object);  // super (Biasgen) handles others, e.g. masterbias
                }
            } catch (HardwareInterfaceException e) {
                log.warning("On update() caught " + e.toString());
            }
        }

        // sends complex configuration information to multiple shift registers and off chip DACs
        void sendConfiguration() throws HardwareInterfaceException {
            if (!isOpen()) {
                open();
            }
            log.info("sending complete configuration");
            update(ipots.getPots().get(0), null); // calls back to update to send all IPot bits
            for (Pot v : vpots.getPots()) {
                update(v, v);
            }
            try {
                setDACPowered(isDACPowered());
            } catch (HardwareInterfaceException ex) {
                log.warning("setting power state of DACs: " + ex);
            }
            for (PortBit b : portBits) {
                b.setChanged();
                update(b, b);
            }

            for (Equalizer.EqualizerChannel c : equalizer.channels) {
                update(c, null);
            }

            sendCPLDConfig();

        }

        // sends VR to init DAC
        public void initDAC() throws HardwareInterfaceException {
            sendConfig(CMD_INITDAC, 0);
        }

        void sendDAC(VPot pot) throws HardwareInterfaceException {
            int chan = pot.getChannel();
            int value = pot.getBitValue();
            byte[] b = new byte[6]; // 2*24=48 bits
// original firmware code
//            unsigned char dat1 = 0x00; //00 00 0000;
//            unsigned char dat2 = 0xC0; //Reg1=1 Reg0=1 : Write output data
//            unsigned char dat3 = 0x00;
//
//            dat1 |= (address & 0x0F);
//            dat2 |= ((msb & 0x0F) << 2) | ((lsb & 0xC0)>>6) ;
//            dat3 |= (lsb << 2) | 0x03; // DEBUG; the last 2 bits are actually don't care
            byte msb = (byte) (0xff & ((0xf00 & value) >> 8));
            byte lsb = (byte) (0xff & value);
            byte dat1 = 0;
            byte dat2 = (byte) 0xC0;
            byte dat3 = 0;
            dat1 |= (0xff & ((chan % 16) & 0xf));
            dat2 |= ((msb & 0xf) << 2) | ((0xff & (lsb & 0xc0) >> 6));
            dat3 |= (0xff & ((lsb << 2)));
            if (chan < 16) { // these are first VPots in list; they need to be loaded first to isSet to the second DAC in the daisy chain
                b[0] = dat1;
                b[1] = dat2;
                b[2] = dat3;
                b[3] = 0;
                b[4] = 0;
                b[5] = 0;
            } else { // second DAC VPots, loaded second to end up at start of daisy chain shift register
                b[0] = 0;
                b[1] = 0;
                b[2] = 0;
                b[3] = dat1;
                b[4] = dat2;
                b[5] = dat3;
            }
//            System.out.print(String.format("value=%-6d channel=%-6d ",value,chan));
//            for(byte bi:b) System.out.print(String.format("%2h ", bi&0xff));
//            System.out.println();
            sendConfig(CMD_VDAC, 0, b); // value=CMD_VDAC, index=0, bytes as above
        }

        /** Sets the VDACs on the board to be powered or high impedance output. This is a global operation.
         * 
         * @param yes true to power up DACs
         * @throws net.sf.jaer.hardwareinterface.HardwareInterfaceException
         */
        public void setDACPowered(boolean yes) throws HardwareInterfaceException {
            putPref("CochleaAMS1c.Biasgen.DAC.powered", yes);
            byte[] b = new byte[6];
            Arrays.fill(b, (byte) 0);
            final byte up = (byte) 9, down = (byte) 8;
            if (yes) {
                b[0] = up;
                b[3] = up; // sends 09 00 00 to each DAC which is soft powerup
            } else {
                b[0] = down;
                b[3] = down;
            }
            sendConfig(CMD_VDAC, 0, b);
        }

        /** Returns the DAC powered state
         * 
         * @return true if powered up
         */
        public boolean isDACPowered() {
            return dacPowered;
        }

        /**
         * @return the onchipPreamp
         */
        public OnChipPreamp getOnchipPreamp() {
            return onchipPreamp;
        }

        /**
         * @return the offchipPreampLeft
         */
        public OffChipPreamp getOffchipPreampLeft() {
            return offchipPreampLeft;
        }

        /**
         * @return the offchipPreampRight
         */
        public OffChipPreamp getOffchipPreampRight() {
            return offchipPreampRight;
        }

        /**
         * @return the adcProxy
         */
        public ADCHardwareInterfaceProxy getAdcProxy() {
            return adcProxy;
        }

        /**
         * @return the scanner
         */
        public Scanner getScanner() {
            return scanner;
        }

        /**
         * @return the preampAGCThresholdPot
         */
        public VPot getPreampAGCThresholdPot() {
            return preampAGCThresholdPot;
        }

        private void sendCPLDConfig() throws HardwareInterfaceException {
//            boolean old = adcProxy.isADCEnabled(); // old state of whether ADC is running - now done in firmware

//            runAdc.set(false); // disable ADC before loading new configuration // TODO do this on device!!
            byte[] bytes = cpldConfig.getBytes();
            sendConfig(CMD_CPLD_CONFIG, 0, bytes);
//            if (old) {
//                runAdc.set(true); // reenable ADC
//            }
        }

        /** Resets equalizer channels to default state, and finally does sequence with special bits to ensure hardware latches are all cleared.
         * 
         */
        void resetEqualizer() {
            equalizer.reset();
        }

        class BufferIPot extends Observable implements RemoteControlled, PreferenceChangeListener, HasPreference {

            final int max = 63; // 8 bits
            private volatile int value;
            private final String key = "CochleaAMS1c.Biasgen.BufferIPot.value";

            BufferIPot() {
                if (getRemoteControl() != null) {
                    getRemoteControl().addCommandListener(this, "setbufferbias bitvalue", "Sets the buffer bias value");
                }
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
                hasPreferencesList.add(this);
            }

            public int getValue() {
                return value;
            }

            public void setValue(int value) {
                if (value > max) {
                    value = max;
                } else if (value < 0) {
                    value = 0;
                }
                if (this.value != value) {
                    setChanged();
                }
                this.value = value;

                notifyObservers();
            }

            @Override
            public String toString() {
                return String.format("BufferIPot with max=%d, value=%d", max, value);
            }

            @Override
            public String processRemoteControlCommand(RemoteControlCommand command, String input) {
                String[] tok = input.split("\\s");
                if (tok.length < 2) {
                    return "bufferbias " + getValue() + "\n";
                } else {
                    try {
                        int val = Integer.parseInt(tok[1]);
                        setValue(val);
                    } catch (NumberFormatException e) {
                        return "?\n";
                    }

                }
                return "bufferbias " + getValue() + "\n";
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key)) {
                    setValue(Integer.parseInt(e.getNewValue()));
                }
            }

            @Override
            public void loadPreference() {
                setValue(getPrefs().getInt(key, max / 2));
            }

            @Override
            public void storePreference() {
                putPref(key, value);
            }
        }

        /** Handles CPLD configuration shift register. This class maintains the information in the CPLD shift register. */
        class CPLDConfig {

            int numBits, minBit = Integer.MAX_VALUE, maxBit = Integer.MIN_VALUE;
            ArrayList<CPLDConfigValue> cpldConfigValues = new ArrayList();
            boolean[] bits;
            byte[] bytes = null;

            /** Computes the bits to be sent to the CPLD from all the CPLD config values: bits, tristateable bits, and ints.
             * Writes the bits boolean[] so that they are set according to the bit position, e.g. for a bit if startBit=0, then bits[0] is set.
             * 
             */
            private void compute() {
                if (minBit > 0) {
                    return; // notifyChange yet, we haven't filled in bit 0 yet
                }
                bits = new boolean[maxBit + 1];
                for (CPLDConfigValue v : cpldConfigValues) {
                    if (v instanceof CPLDBit) {
                        bits[v.startBit] = ((ConfigBit) v).isSet();
                        if (v instanceof TriStateableCPLDBit) {
                            bits[v.startBit + 1] = ((TriStateableCPLDBit) v).isHiZ(); // assumes hiZ bit is next one up
                        }
                    } else if (v instanceof ConfigInt) {
                        int i = ((ConfigInt) v).get();
                        for (int k = v.startBit; k < v.endBit; k++) {
                            bits[k] = (i & 1) == 1;
                            i = i >>> 1;
                        }
                    }
                }
            }

            void add(CPLDConfigValue val) {
                if (val.endBit < val.startBit) {
                    throw new RuntimeException("bad CPLDConfigValue with endBit<startBit: " + val);
                }

                if (val.endBit > maxBit) {
                    maxBit = val.endBit;
                }
                if (val.startBit < minBit) {
                    minBit = val.startBit;
                }

                cpldConfigValues.add(val);
                compute();

            }

            /** Returns byte[] to send to uC to load into CPLD shift register. 
             * This array is returned in big endian order so that
            the bytes sent will be sent in big endian order to the device, according to how they are handled in firmware
            and loaded into the CPLD shift register. In other words, the msb of the first byte returned (getBytes()[0] is the last bit
             * in the bits[] array of booleans, bit 63 in the case of 64 bits of CPLD SR contents.
             * 
             */
            private byte[] getBytes() {
                compute();
                int nBytes = bits.length / 8;
                if (bits.length % 8 != 0) {
                    nBytes++;
                }
                if (bytes == null || bytes.length != nBytes) {
                    bytes = new byte[nBytes];
                }
                Arrays.fill(bytes, (byte) 0);
                int byteCounter = 0;
                int bitcount = 0;
                for (int i = bits.length - 1; i >= 0; i--) { // start with msb and go down
                    bytes[byteCounter] = (byte) (0xff & bytes[byteCounter] << 1); // left shift the bits in this byte that are already there
//                    if (bits[i]) {
//                        System.out.println("true bit at bit " + i);
//                    }
                    bytes[byteCounter] = (byte) (0xff & (bytes[byteCounter] | (bits[i] ? 1 : 0))); // set or clear the current bit
                    bitcount++;
                    if ((bitcount) % 8 == 0) {
                        byteCounter++; // go to next byte when we finish each 8 bits
                    }
                }
                return bytes;
            }

            @Override
            public String toString() {
                return "CPLDConfig{" + "numBits=" + numBits + ", minBit=" + minBit + ", maxBit=" + maxBit + ", cpldConfigValues=" + cpldConfigValues + ", bits=" + bits + ", bytes=" + bytes + '}';
            }
        }

        /** A single bit of digital configuration, either controlled by dedicated Cypress port bit
         * or as part of the CPLD configuration shift register. */
        abstract class AbstractConfigValue extends Observable implements PreferenceChangeListener, HasPreference {

            protected String name, tip;
            protected String key = "AbstractConfigValue";

            public AbstractConfigValue(String name, String tip) {
                this.name = name;
                this.tip = tip;
                this.key = getClass().getSimpleName() + "." + name;
            }

            @Override
            public String toString() {
                return String.format("AbstractConfigValue name=%s key=%s", name, key);
            }

            public String getName() {
                return name;
            }

            @Override
            public synchronized void setChanged() {
                super.setChanged();
            }

            public String getDescription() {
                return tip;
            }
        }

        public class AbstractConfigBit extends AbstractConfigValue implements ConfigBit {

            protected volatile boolean value;
            protected boolean def; // default preference value

            public AbstractConfigBit(String name, String tip, boolean def) {
                super(name, tip);
                this.name = name;
                this.tip = tip;
                this.def = def;
                key = "CochleaAMS1c.Biasgen.ConfigBit." + name;
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
            }

            @Override
            public void set(boolean value) {
                if (this.value != value) {
                    setChanged();
                }
                this.value = value;
//                log.info("set " + this + " to value=" + value+" notifying "+countObservers()+" observers");
                notifyObservers();
            }

            @Override
            public boolean isSet() {
                return value;
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key)) {
//                    log.info(this+" preferenceChange(): event="+e+" key="+e.getKey()+" newValue="+e.getNewValue());
                    boolean newv = Boolean.parseBoolean(e.getNewValue());
                    set(newv);
                }
            }

            @Override
            public void loadPreference() {
                set(getPrefs().getBoolean(key, def));
            }

            @Override
            public void storePreference() {
                putPref(key, value); // will eventually call pref change listener which will call set again
            }

            @Override
            public String toString() {
                return String.format("AbstractConfigBit name=%s key=%s value=%s", name, key, value);
            }
        }

        /** A direct bit output from CypressFX2 port. */
        public class PortBit extends AbstractConfigBit implements ConfigBit {

            String portBitString;
            int port;
            short portbit; // has port as char in MSB, bitmask in LSB
            int bitmask;

            public PortBit(String portBit, String name, String tip, boolean def) {
                super(name, tip, def);
                if (portBit == null || portBit.length() != 2) {
                    throw new Error("BitConfig portBit=" + portBit + " but must be 2 characters");
                }
                String s = portBit.toLowerCase();
                if (!(s.startsWith("a") || s.startsWith("c") || s.startsWith("d") || s.startsWith("e"))) {
                    throw new Error("BitConfig portBit=" + portBit + " but must be 2 characters and start with A, C, D, or E");
                }
                portBitString = portBit;
                char ch = s.charAt(0);
                switch (ch) {
                    case 'a':
                        port = 0;
                        break;
                    case 'c':
                        port = 1;
                        break;
                    case 'd':
                        port = 2;
                        break;
                    case 'e':
                        port = 3;
                        break;
                    default:
                        throw new Error("BitConfig portBit=" + portBit + " but must be 2 characters and start with A, C, D, or E");
                }
                bitmask = 1 << Integer.valueOf(s.substring(1, 2));
                portbit = (short) (0xffff & ((port << 8) + (0xff & bitmask)));
                portBits.add(this);
                config.add(this);
            }

            @Override
            public String toString() {
                return String.format("PortBit name=%s port=%s value=%s", name, portBitString, value);
            }
        }

        /** Adds a hiZ state to the bit to set port bit to input */
        class TriStateablePortBit extends PortBit implements ConfigTristate {

            private volatile boolean hiZEnabled = false;
            String hiZKey;
            Tristate def;

            TriStateablePortBit(String portBit, String name, String tip, Tristate def) {
                super(portBit, name, tip, def.isHigh());
                this.def = def;
                hiZKey = "CochleaAMS1c.Biasgen.BitConfig." + name + ".hiZEnabled";
                loadPreference();
            }

            /**
             * @return the hiZEnabled
             */
            @Override
            public boolean isHiZ() {
                return hiZEnabled;
            }

            /**
             * @param hiZEnabled the hiZEnabled to set
             */
            @Override
            public void setHiZ(boolean hiZEnabled) {
                if (this.hiZEnabled != hiZEnabled) {
                    setChanged();
                }
                this.hiZEnabled = hiZEnabled;
                notifyObservers();
            }

            @Override
            public String toString() {
                return String.format("TriStateablePortBit name=%s portbit=%s value=%s hiZEnabled=%s", name, portBitString, Boolean.toString(isSet()), hiZEnabled);
            }

            @Override
            public void loadPreference() {
                super.loadPreference();
                setHiZ(getPrefs().getBoolean(key, def.isHiZ()));
            }

            @Override
            public void storePreference() {
                super.storePreference();
                putPref(key, hiZEnabled); // will eventually call pref change listener which will call set again
            }
        }

        class CPLDConfigValue extends AbstractConfigValue {

            protected int startBit, endBit;
            protected int nBits = 8;

            public CPLDConfigValue(int startBit, int endBit, String name, String tip) {
                super(name, tip);
                this.startBit = startBit;
                this.endBit = endBit;
                nBits = endBit - startBit + 1;
                hasPreferencesList.add(this);
                cpldConfigValues.add(this);
                config.add(this);
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent evt) {
            }

            @Override
            public void loadPreference() {
            }

            @Override
            public void storePreference() {
            }

            @Override
            public String toString() {
                return "CPLDConfigValue{" + "name=" + name + " startBit=" + startBit + "endBit=" + endBit + "nBits=" + nBits + '}';
            }
        }

        /** A bit output from CPLD port. */
        public class CPLDBit extends CPLDConfigValue implements ConfigBit {

            int pos; // bit position from lsb position in CPLD config
            boolean value;
            boolean def;

            /** Constructs new CPLDBit.
             * 
             * @param pos position in shift register
             * @param name name label
             * @param tip tool-tip
             * @param def default preferred value
             */
            public CPLDBit(int pos, String name, String tip, boolean def) {
                super(pos, pos, name, tip);
                this.pos = pos;
                this.def = def;
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
//                hasPreferencesList.add(this);
            }

            @Override
            public void set(boolean value) {
                if (this.value != value) {
                    setChanged();
                }
                this.value = value;
//                log.info("set " + this + " to value=" + value+" notifying "+countObservers()+" observers");
                notifyObservers();
            }

            @Override
            public boolean isSet() {
                return value;
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key)) {
//                    log.info(this+" preferenceChange(): event="+e+" key="+e.getKey()+" newValue="+e.getNewValue());
                    boolean newv = Boolean.parseBoolean(e.getNewValue());
                    set(newv);
                }
            }

            @Override
            public void loadPreference() {
                set(getPrefs().getBoolean(key, def));
            }

            @Override
            public void storePreference() {
                putPref(key, value); // will eventually call pref change listener which will call set again
            }

            @Override
            public String toString() {
                return "CPLDBit{" + " name=" + name + " pos=" + pos + " value=" + value + '}';
            }
        }

        /** Adds a hiZ state to the bit to set port bit to input */
        class TriStateableCPLDBit extends CPLDBit implements ConfigTristate {

            private int hiZBit;
            private volatile boolean hiZEnabled = false;
            String hiZKey;
            Tristate def;

            TriStateableCPLDBit(int valBit, int hiZBit, String name, String tip, Tristate def) {
                super(valBit, name, tip, def == Tristate.High);
                this.def = def;
                this.hiZBit = hiZBit;
                hiZKey = "CochleaAMS1c.Biasgen.TriStateableCPLDBit." + name + ".hiZEnabled";
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
//                hasPreferencesList.add(this);
            }

            /**
             * @return the hiZEnabled
             */
            public boolean isHiZ() {
                return hiZEnabled;
            }

            /**
             * @param hiZEnabled the hiZEnabled to set
             */
            public void setHiZ(boolean hiZEnabled) {
                if (this.hiZEnabled != hiZEnabled) {
                    setChanged();
                }
                this.hiZEnabled = hiZEnabled;
                notifyObservers();
            }

            @Override
            public String toString() {
                return String.format("TriStateableCPLDBit name=%s shiftregpos=%d value=%s hiZ=%s", name, pos, Boolean.toString(isSet()), hiZEnabled);
            }

            @Override
            public void loadPreference() {
                super.loadPreference();
                setHiZ(getPrefs().getBoolean(key, false));
            }

            @Override
            public void storePreference() {
                super.storePreference();
                putPref(key, hiZEnabled); // will eventually call pref change listener which will call set again
            }
        }

        /** A integer configuration on CPLD shift register. */
        class CPLDInt extends CPLDConfigValue implements ConfigInt {

            private volatile int value;
            private int def;

            CPLDInt(int startBit, int endBit, String name, String tip, int def) {
                super(startBit, endBit, name, tip);
                this.startBit = startBit;
                this.endBit = endBit;
                this.def = def;
                key = "CochleaAMS1c.Biasgen.CPLDInt." + name;
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
//                hasPreferencesList.add(this);
            }

            @Override
            public void set(int value) throws IllegalArgumentException {
                if (value < 0 || value >= 1 << nBits) {
                    throw new IllegalArgumentException("tried to store value=" + value + " which larger than permitted value of " + (1 << nBits) + " or is negative in " + this);
                }
                if (this.value != value) {
                    setChanged();
                }
                this.value = value;
//                log.info("set " + this + " to value=" + value+" notifying "+countObservers()+" observers");
                notifyObservers();
            }

            @Override
            public int get() {
                return value;
            }

            @Override
            public String toString() {
                return String.format("CPLDInt name=%s value=%d", name, value);
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key)) {
//                    log.info(this+" preferenceChange(): event="+e+" key="+e.getKey()+" newValue="+e.getNewValue());
                    int newv = Integer.parseInt(e.getNewValue());
                    set(newv);
                }
            }

            @Override
            public void loadPreference() {
                set(getPrefs().getInt(key, def));
            }

            @Override
            public void storePreference() {
                putPref(key, value); // will eventually call pref change listener which will call set again
            }
        }

        public class ADC extends ADCHardwareInterfaceProxy implements Observer {

            public ADC(Chip chip) {
                super(chip);
            }

            @Override
            public boolean isADCEnabled() {
                return runAdc.isSet();
            }

            @Override
            public void setADCEnabled(boolean yes) {
                super.setADCEnabled(yes);
                runAdc.set(yes);
            }

            @Override
            public void update(Observable o, Object arg) {
                throw new UnsupportedOperationException("Not supported yet.");
            }
        }

        /** Extends base scanner class to control the relevant bits and parameters of the hardware */
        public class Scanner extends ScannerHardwareInterfaceProxy implements PreferenceChangeListener, HasPreference, Observer {

            public final int nstages = 64;
            public final int minPeriod = 10; // to avoid FX2 getting swamped by interrupts for scanclk
            public final int maxPeriod = 255;

            public Scanner(CochleaAMS1c chip) {
                super(chip);
                loadPreference();
                getPrefs().addPreferenceChangeListener(this);
                hasPreferencesList.add(this);
            }

            public int getPeriod() {
                return getAdcProxy().getIdleTime() + getAdcProxy().getTrackTime();
            }

            /** Sets the scan rate using the ADC idleTime setting, indirectly. 
             * 
             * @param period 
             */
            public void setPeriod(int period) {
                boolean old = getAdcProxy().isADCEnabled();
                getAdcProxy().setADCEnabled(false);
                getAdcProxy().setIdleTime(period); // TODO fix period units using track time + conversion time + idleTime
                if (old) {
                    getAdcProxy().setADCEnabled(old);
                }
            }

            @Override
            public int getScanX() {
                return Biasgen.this.scanX.get();
            }

            @Override
            public boolean isScanContinuouslyEnabled() {
                return Biasgen.this.scanContinuouslyEnabled.isSet();
            }

            @Override
            public void setScanContinuouslyEnabled(boolean scanContinuouslyEnabled) {
                super.setScanContinuouslyEnabled(scanContinuouslyEnabled);
                Biasgen.this.scanContinuouslyEnabled.set(scanContinuouslyEnabled);
            }

            @Override
            public void setScanX(int scanX) {
                super.setScanX(scanX);
                Biasgen.this.scanX.set(scanX);
            }

            public void setScanGanglionCellVMem(boolean yes) {
                Biasgen.this.scanSel.set(yes);
            }

            public void setScanBasMemV(boolean yes) {
                Biasgen.this.scanSel.set(!yes);
            }

            public boolean isScanGangCellVMem() {
                return Biasgen.this.scanSel.isSet();
            }

            public boolean isScanBasMemV() {
                return !Biasgen.this.scanSel.isSet();
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
//                if (e.getKey().equals("CochleaAMS1c.Biasgen.Scanner.currentStage")) {
//                    setCurrentStage(Integer.parseInt(e.getNewValue()));
//                } else if (e.getKey().equals("CochleaAMS1c.Biasgen.Scanner.currentStage")) {
//                    setContinuousScanningEnabled(Boolean.parseBoolean(e.getNewValue()));
//                }
            }

            @Override
            public void loadPreference() {
                setScanX(Biasgen.this.scanX.get());
                setScanContinuouslyEnabled(Biasgen.this.scanContinuouslyEnabled.isSet());
                setScanGanglionCellVMem(scanSel.isSet());
            }

            @Override
            public void storePreference() {
            }

            @Override
            public String toString() {
                return "Scanner{" + "currentStage=" + getScanX() + ", scanContinuouslyEnabled=" + isScanContinuouslyEnabled() + ", period=" + getPeriod() + '}';
            }

            @Override
            public void update(Observable o, Object arg) {
                if (o == Biasgen.this.scanContinuouslyEnabled) {
                    setScanContinuouslyEnabled(Biasgen.this.scanContinuouslyEnabled.isSet());
                } else if (o == Biasgen.this.scanSel) {
                    setScanGanglionCellVMem(scanSel.isSet());
                } else if (o == Biasgen.this.scanX) {
                    setScanX(Biasgen.this.scanX.get());
                }
            }
        }

        /** Encapsulates each channels equalizer. Information is sent to device as
         * <p>
         * <img source="doc-files/equalizerBits.png"/>
         * where the index field of the vendor request has the quality and kill bit information.
         */
        class Equalizer extends Observable { // describes the local gain and Q registers and the kill bits

            final int numChannels = 128, maxValue = 31;
//            private int globalGain = 15;
//            private int globalQuality = 15;
            EqualizerChannel[] channels = new EqualizerChannel[numChannels];

            Equalizer() {
                for (int i = 0; i < numChannels; i++) {
                    channels[i] = new EqualizerChannel(i);
                    channels[i].addObserver(Biasgen.this); // CochleaAMS1c.Biasgen observes each equalizer channel
                }
            }

            /** Resets equalizer channels to default state, and finally does sequence with special bits to ensure hardware latches are all cleared.
             * 
             */
            void reset() {
                log.info("resetting all Equalizer states to default");
                for (EqualizerChannel c : channels) {
                    c.reset();
                }
                // TODO special dance with logic bits to reset here 

            }

//            public int getGlobalGain() {
//                return globalGain;
//            }
//
//            public void setGlobalGain(int globalGain) {
//                this.globalGain = globalGain;
//                for(EqualizerChannel c:channels){
//                    c.setQBPF(globalGain);
//                }
//            }
//
//            public int getGlobalQuality() {
//                return globalQuality;
//            }
//
//            public void setGlobalQuality(int globalQuality) {
//                this.globalQuality = globalQuality;
//                for(EqualizerChannel c:channels){
//                    c.setQBPF(globalGain);
//                }
//            }
            class EqualizerChannel extends Observable implements ChangeListener, PreferenceChangeListener, HasPreference {

                final int max = 31;
                int channel;
                private String prefsKey;
                private volatile int qsos;
                private volatile int qbpf;
                private volatile boolean bpfkilled, lpfkilled;

                EqualizerChannel(int n) {
                    channel = n;
                    prefsKey = "CochleaAMS1c.Biasgen.Equalizer.EqualizerChannel." + channel + ".";
                    loadPreference();
                    getPrefs().addPreferenceChangeListener(this);
                    hasPreferencesList.add(this);
                }

                @Override
                public String toString() {
                    return String.format("EqualizerChannel: channel=%-3d qbpf=%-2d qsos=%-2d bpfkilled=%-6s lpfkilled=%-6s", channel, qbpf, qsos, Boolean.toString(bpfkilled), Boolean.toString(lpfkilled));
                }

                public int getQSOS() {
                    return qsos;
                }

                public void setQSOS(int qsos) {
                    if (this.qsos != qsos) {
                        setChanged();
                    }
                    this.qsos = qsos;
                    notifyObservers();
                }

                public int getQBPF() {
                    return qbpf;
                }

                public void setQBPF(int qbpf) {
                    if (this.qbpf != qbpf) {
                        setChanged();
                    }
                    this.qbpf = qbpf;
                    notifyObservers();
                }

                public boolean isLpfKilled() {
                    return lpfkilled;
                }

                public void setLpfKilled(boolean killed) {
                    if (killed != this.lpfkilled) {
                        setChanged();
                    }
                    this.lpfkilled = killed;
                    notifyObservers();
                }

                public boolean isBpfkilled() {
                    return bpfkilled;
                }

                public void setBpfKilled(boolean bpfkilled) {
                    if (bpfkilled != this.bpfkilled) {
                        setChanged();
                    }
                    this.bpfkilled = bpfkilled;
                    notifyObservers();
                }

                @Override
                public void stateChanged(ChangeEvent e) {
                    if (e.getSource() instanceof CochleaAMS1cControlPanel.EqualizerSlider) {
                        CochleaAMS1cControlPanel.EqualizerSlider s = (CochleaAMS1cControlPanel.EqualizerSlider) e.getSource();
                        if (s instanceof CochleaAMS1cControlPanel.QSOSSlider) {
                            s.channel.setQSOS(s.getValue());
                        }
                        if (s instanceof CochleaAMS1cControlPanel.QBPFSlider) {
                            s.channel.setQBPF(s.getValue());
                        }
//                        setChanged();
//                        notifyObservers();
                    } else if (e.getSource() instanceof CochleaAMS1cControlPanel.KillBox) {
                        CochleaAMS1cControlPanel.KillBox b = (CochleaAMS1cControlPanel.KillBox) e.getSource();
                        if (b instanceof CochleaAMS1cControlPanel.LPFKillBox) {
                            b.channel.setLpfKilled(b.isSelected());
//                            System.out.println("LPF: "+b.channel.toString());
                        } else {
                            b.channel.setBpfKilled(b.isSelected());
//                            System.out.println("BPF: "+b.channel.toString());
                        }
//                        setChanged();
//                        notifyObservers();
                    }
                }

                @Override
                public void preferenceChange(PreferenceChangeEvent e) {
                    if (e.getKey().equals(prefsKey + "qsos")) {
                        setQSOS(Integer.parseInt(e.getNewValue()));
                    } else if (e.getKey().equals(prefsKey + "qbpf")) {
                        setQBPF(Integer.parseInt(e.getNewValue()));
                    } else if (e.getKey().equals(prefsKey + "bpfkilled")) {
                        setBpfKilled(Boolean.parseBoolean(e.getNewValue()));
                    } else if (e.getKey().equals(prefsKey + "lpfkilled")) {
                        setLpfKilled(Boolean.parseBoolean(e.getNewValue()));
                    }
                }

                @Override
                public final void loadPreference() {
                    qsos = getPrefs().getInt(prefsKey + "qsos", 15);
                    qbpf = getPrefs().getInt(prefsKey + "qbpf", 15);
                    bpfkilled = getPrefs().getBoolean(prefsKey + "bpfkilled", false);
                    lpfkilled = getPrefs().getBoolean(prefsKey + "lpfkilled", false);
                    setChanged();
                    notifyObservers();
                }

                @Override
                public void storePreference() {
                    putPref(prefsKey + "bpfkilled", bpfkilled);
                    putPref(prefsKey + "lpfkilled", lpfkilled);
                    putPref(prefsKey + "qbpf", qbpf);
                    putPref(prefsKey + "qsos", qsos);
                }

                private void reset() {
                    setBpfKilled(false);
                    setLpfKilled(false);
                    setQBPF(0);
                    setQSOS(0);
                }
            }
        } // equalizer

        /** Represents the on-chip preamps */
        class OnChipPreamp extends Observable implements PreferenceChangeListener, HasPreference {

            protected String key = "OnChipPreamp";
            String initgain = getPrefs().get("OnChipPreampGain", OnChipPreampGain.High.name());
            OnChipPreampGain gain = OnChipPreampGain.valueOf(initgain);
            CPLDInt gainBits;

            public OnChipPreamp(CPLDInt gainBits) {
                this.gainBits = gainBits;
                loadPreference();
                hasPreferencesList.add(this);
            }

            void setGain(OnChipPreampGain gain) {
                if (this.gain != gain) {
                    setChanged();
                }
                this.gain = gain;
                gainBits.set(gain.code); // sends the new bit values via listener update on gainBits
                notifyObservers(this); // handle in update()
            }

            OnChipPreampGain getGain() {
                return gain;
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key)) {
                    log.info(this + " preferenceChange(): event=" + e + " key=" + e.getKey() + " newValue=" + e.getNewValue());
                    setGain(OnChipPreampGain.valueOf(e.getNewValue()));
                }
            }

            @Override
            public void loadPreference() {
                try {
                    setGain(OnChipPreampGain.valueOf(getPrefs().get(key, OnChipPreampGain.High.name())));
                } catch (Exception e) {
                    setGain(OnChipPreampGain.High);
                }
            }

            @Override
            public void storePreference() {
                putPref(key, gain.toString()); // will eventually call pref change listener which will call set again
            }

            @Override
            public String toString() {
                return "OnChipPreamp{" + "key=" + key + ", gain=" + gain + '}';
            }
        }//preamp

        /** Represents the combined off-chip AGC attack/release ratio setting; this setting common for both preamps. */
        class OffChipPreampARRatio extends Observable implements PreferenceChangeListener, HasPreference {

            final String arkey = "OffChipPreamp.arRatio";
            TriStateableCPLDBit arBit;
            private OffChipPreamp_AGC_AR_Ratio arRatio;

            public OffChipPreampARRatio(TriStateableCPLDBit arBit) {
                this.arBit = arBit;
                loadPreference();
                hasPreferencesList.add(this);
            }

            /**
             * @return the arRatio
             */
            public OffChipPreamp_AGC_AR_Ratio getArRatio() {
                return arRatio;
            }

            /** Sets offchip preamp AGC attack/release ratio via
            <pre> 
             * private TriStateableCPLDBit preampAR = new TriStateableCPLDBit(5, 6, "preampAttack/Release", "offchip preamp attack/release ratio (0=attack/release ratio=1:500, 1=A/R=1:2000, HiZ=A/R=1:4000)"),
             * </pre>
             * @param gain 
             */
            public void setArRatio(OffChipPreamp_AGC_AR_Ratio arRatio) {
                if (this.arRatio != arRatio) {
                    setChanged();
                }
                this.arRatio = arRatio;
                switch (arRatio) {
                    case Fast:
                        arBit.set(false);
                        arBit.setHiZ(false);
                        break;
                    case Medium:
                        arBit.set(true);
                        arBit.setHiZ(false);
                        break;
                    case Slow:
                        arBit.setHiZ(true);
                }
                notifyObservers();
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(arkey)) {
                    log.info(this + " preferenceChange(): event=" + e + " key=" + e.getKey() + " newValue=" + e.getNewValue());
                    setArRatio(OffChipPreamp_AGC_AR_Ratio.valueOf(e.getNewValue()));
                }
            }

            @Override
            public void loadPreference() {
                try {
                    setArRatio(OffChipPreamp_AGC_AR_Ratio.valueOf(getPrefs().get(arkey, OffChipPreamp_AGC_AR_Ratio.Fast.name())));
                } catch (Exception e) {
                    setArRatio(OffChipPreamp_AGC_AR_Ratio.Medium);
                }
            }

            @Override
            public void storePreference() {
                putPref(arkey, arRatio.toString()); // will eventually call pref change listener which will call set again
            }
        }

        /** Represents a single off-chip pre-amplifier. */
        class OffChipPreamp extends Observable implements PreferenceChangeListener, HasPreference {

            Ear ear = Ear.Both;
            final String gainkey = "OffChipPreamp.gain";
            private OffChipPreampGain gain;
            TriStateableCPLDBit gainBit;

            public OffChipPreamp(TriStateableCPLDBit gainBit, Ear ear) {
                this.gainBit = gainBit;
                this.ear = ear;
                loadPreference();
                hasPreferencesList.add(this);
            }

            /** Sets off-chip pre-amp gain via
            <pre> 
            preampGainLeft = new TriStateableCPLDBit(5, 6, "preamp gain, left", "offchip preamp gain bit (1=gain=40dB, 0=gain=50dB, HiZ=60dB if preamp threshold \"PreampAGCThreshold (TH)\"is set above 2V)"),
             * </pre>
             * @param gain 
             */
            void setGain(OffChipPreampGain gain) {
                if (this.gain != gain) {
                    setChanged();
                }
                this.gain = gain;
                switch (gain) {
                    case High:
                        gainBit.setHiZ(true);
                        break;
                    case Medium:
                        gainBit.setHiZ(false);
                        gainBit.set(false);
                        break;
                    case Low:
                        gainBit.setHiZ(false);
                        gainBit.set(true);
                }
                notifyObservers(this); // handle in update()
            }

            OffChipPreampGain getGain() {
                return gain;
            }

            @Override
            public void preferenceChange(PreferenceChangeEvent e) {
                if (e.getKey().equals(key())) {
                    log.info(this + " preferenceChange(): event=" + e + " key=" + e.getKey() + " newValue=" + e.getNewValue());
                    setGain(OffChipPreampGain.valueOf(e.getNewValue()));
                }
            }

            @Override
            public void loadPreference() {
                try {
                    setGain(OffChipPreampGain.valueOf(getPrefs().get(key(), OffChipPreampGain.High.name())));
                } catch (Exception e) {
                    setGain(OffChipPreampGain.High);
                }
            }

            @Override
            public void storePreference() {
                putPref(key(), gain.toString()); // will eventually call pref change listener which will call set again
            }

            @Override
            public String toString() {
                return "OffChipPreamp{" + " gainkey=" + key() + ", gain=" + gain + '}';
            }

            private String key() {
                return gainkey + "." + ear.toString();
            }
        }// offchip preamp
    } // biasgen

    /** Enum for on-chip preamp gain values */
    public enum OnChipPreampGain {

        Low(0, "Low (100 kohm)"),
        Medium(1, "Medium (200 kohm)"),
        High(2, "High (400 kohm)");
        private final int code;
        private final String label;

        OnChipPreampGain(int code, String label) {
            this.code = code;
            this.label = label;
        }

        public int code() {
            return code;
        }
//        @Override
//        public String toString() {
//            return label;
//        }
    }

    /** Used for preamp preferences */
    public enum Ear {

        Left, Right, Both
    };

    /** Extract cochlea events from CochleaAMS1c including the ADC samples that are intermixed with cochlea AER data. 
     * <p>
     * The event class returned by the extractor is CochleaAMSEvent.
     * <p>
     * The 10 bits of AER address are mapped as follows
     * <pre>
     * TX0 - AE0 
     * TX1 - AE1
     * ...
     * TX7 - AE7
     * TY0 - AE8
     * TY1 - AE9
     * AE15:10 are unused and are unconnected - they should be masked out in software.
     * </pre>
     * 
     * <table border="1px">
     * <tr><td>15<td>14<td>13<td>12<td>11<td>10<td>9<td>8<td>7<td>6<td>5<td>4<td>3<td>2<td>1<td>0
     * <tr><td>x<td>x<td>x<td>x<td>x<td>x<td>TH1<td>TH0<td>CH5<td>CH4<td>CH3<td>CH2<td>CH1<td>CH0<td>EAR<td>LPFBPF
     * </table>
     * <ul>
     * <li>
     * TH1:0 are the ganglion cell. TH1:0=00 is the one biased with Vth1, TH1:0=01 is biased with Vth2, etc. TH1:0=11 is biased with Vth4. Vth1 and Vth4 are external voltage biaes.
     * <li>
     * CH5:0 are the channel address. 0 is the base (input) responsive to high frequencies. 63 is the apex responding to low frequencies.
     * <li>
     * EAR is the binaural ear. EAR=0 is left ear, EAR=1 is right ear.
     * <li>
     * LPFBPF is the ganglion cell type. LPFBPF=1 is a low-pass neuron, LPFBPF=1 is a bandpass neuron.
     * </ul>
     */
    public class Extractor extends TypedEventExtractor {

        public Extractor(AEChip chip) {
            super(chip);
        }

        /**
         * Extracts the meaning of the raw events. This form is used to supply an output packet. This method is used for real time
         * event filtering using a buffer of output events local to data acquisition. An AEPacketRaw may contain multiple events, 
         * not all of them have to sent out as EventPackets. An AEPacketRaw is a set(!) of addresses and corresponding timing moments.
         * 
         * A first filter (independent from the other ones) is implemented by subSamplingEnabled and getSubsampleThresholdEventCount. 
         * The latter may limit the amount of samples in one package to say 50,000. If there are 160,000 events and there is a sub samples 
         * threshold of 50,000, a "skip parameter" set to 3. Every so now and then the routine skips with 4, so we end up with 50,000.
         * It's an approximation, the amount of events may be less than 50,000. The events are extracted uniform from the input. 
         * 
         * @param in 		the raw events, can be null
         * @param out 		the processed events. these are partially processed in-place. empty packet is returned if null is
         * 					supplied as input.
         */
        @Override
        synchronized public void extractPacket(AEPacketRaw in, EventPacket out) {
            out.clear();
            if (in == null) {
                return;
            }
            int n = in.getNumEvents(); //addresses.length;

            int skipBy = 1, incEach = 0, j = 0;
            if (isSubSamplingEnabled()) {
                skipBy = n / getSubsampleThresholdEventCount();
                incEach = getSubsampleThresholdEventCount() / (n % getSubsampleThresholdEventCount());
            }
            if (skipBy == 0) {
                incEach = 0;
                skipBy = 1;
            }

            int[] a = in.getAddresses();
            int[] timestamps = in.getTimestamps();
//            boolean hasTypes = false;
//            if (chip != null) {
//                hasTypes = chip.getNumCellTypes() > 1;
//            }
            OutputEventIterator<?> outItr = out.outputIterator();
            for (int i = 0; i < n; i += skipBy) {
                int addr = a[i];
                int ts = timestamps[i];
                if (CochleaAMS1cHardwareInterface.isAERAddress(addr) ) {
                    CochleaAMSEvent e = (CochleaAMSEvent) outItr.nextOutput();
                    e.address = addr;
                    e.timestamp = (ts);
                    e.x = getXFromAddress(addr);
                    e.y = getYFromAddress(addr);
                    e.type = (byte) e.y; // overridden to just set cell type uniquely
                    j++;
                    if (j == incEach) {
                        j = 0;
                        i++;
                    }
//                    System.out.println("timestamp=" + e.timestamp + " address=" + addr);
                } else { // adc sample
//                    if (CochleaAMS1cHardwareInterface.isScannerSyncBit(addr)) {
//                        getAdcSamples().swapBuffers();  // the hardware interface here swaps the reading and writing buffers so that new data goes into the other buffer and the old data will be displayed by the rendering thread
//                    }
                    adcSamples.put(CochleaAMS1cHardwareInterface.adcChannel(addr), timestamps[i], CochleaAMS1cHardwareInterface.adcSample(addr), CochleaAMS1cHardwareInterface.isScannerSyncBit(addr));
//                    System.out.println("ADC sample: timestamp=" + timestamps[i] + " addr=" + addr
//                            + " adcChannel=" + CochleaAMS1cHardwareInterface.adcChannel(addr)
//                            + " adcSample=" + CochleaAMS1cHardwareInterface.adcSample(addr)
//                            + " isScannerSyncBit=" + CochleaAMS1cHardwareInterface.isScannerSyncBit(addr));

                }
//            System.out.println("a="+a[i]+" t="+e.timestamp+" x,y="+e.x+","+e.y);
            }
            adcSamples.setHasScannerData(getScanner().isScanContinuouslyEnabled());
        }

        /** Overrides default extractor so that cochlea channels are returned, 
         * numbered from x=0 (base, high frequencies, input end) to x=63 (apex, low frequencies).
         * 
         * @param addr raw address.
         * @return channel, from 0 to 63.
         */
        @Override
        public short getXFromAddress(int addr) {
            short tap = (short) (((addr & 0xfc) >>> 2)); // addr&(1111 1100) >>2, 6 bits, max 63, min 0
            return tap;
        }

        /** Overrides default extract to define type of event the same as the Y address.
         *@param addr the raw address.
         *@return the type
         */
        @Override
        public byte getTypeFromAddress(int addr) {
//            return (byte)((addr&0x02)>>>1);
            return (byte) getYFromAddress(addr);
        }

        /** Overrides default extractor to spread all outputs from a tap (left/right, ganglion cell, LPF/HPF) into a
         *single unique y address that can be displayed in the 2d histogram.
         * The y returned goes like this from 0-15: left LPF(4) right LPF(4) left BPF(4) right BPF(4). Eech group of 4 ganglion cells goes
         * from Vth1 to Vth4.
         *@param addr the raw address
         *@return the Y address
         */
        @Override
        public short getYFromAddress(int addr) {
//            int gangCell=(addr&0x300)>>>8; // each tap has 8 ganglion cells, 4 of each of LPF/BPF type
//            int lpfBpf=(addr&0x01)<<2; // lowpass/bandpass ganglion cell type
//            int leftRight=(addr&0x02)<<2; // left/right cochlea. see javadoc jpg scan for layout
//            short v=(short)(gangCell+lpfBpf+leftRight);
            int lpfBpf = (addr & 0x01) << 3; // LPF=8 BPF=0 ganglion cell type
            int rightLeft = (addr & 0x02) << 1; // right=4 left=0 cochlea
            int thr = (0x300 & addr) >> 8; // thr=0 to 4
            short v = (short) (lpfBpf + rightLeft + thr);
            return v;
        }
    }

    public Scanner getScanner() {
        if (ams1cbiasgen == null) {
            return null;
        }
        return ams1cbiasgen.getScanner();
    }
}
