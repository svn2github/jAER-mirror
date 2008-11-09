/*
 *
 * Created on October 5, 2005, 11:36 AM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */
package ch.unizh.ini.caviar.chip.cochlea;

import ch.unizh.ini.caviar.aemonitor.AEPacketRaw;
import ch.unizh.ini.caviar.chip.AEChip;
import ch.unizh.ini.caviar.chip.TypedEventExtractor;
import ch.unizh.ini.caviar.event.BasicEvent;
import ch.unizh.ini.caviar.event.EventPacket;
import ch.unizh.ini.caviar.event.OutputEventIterator;
import ch.unizh.ini.caviar.event.TypedEvent;
import ch.unizh.ini.caviar.graphics.AEChipRenderer;
import ch.unizh.ini.caviar.util.chart.Chart.Renderer;
import java.awt.Color;

/**
 * For Shih-Chii's AMS cochlea with binaraul 64 stage cochlea each tap with 8 ganglion cells, 4 of LPF type and 4 of BPF type.
 *The bits in the raw address and the histogram display are arranged as shown in the following sketch. This class doesn't define the bias generator
so that it can be used when another besides the on-chip source supplies the bias voltages or inputs to the on-chip bias generator.
 *<p>
 *<img src="doc-files/cochleaAMSSketch.jpg" />
 *</p>
 * @author tobi
 */
public class CochleaAMSNoBiasgen extends CochleaChip {

    /** Creates a new instance of Tmpdiff128 */
    public CochleaAMSNoBiasgen() {
        setName("CochleaAMSNoBiasgen");
        setSizeX(64);
        setSizeY(16); // 4+4 cells/channel * 2 ears
//        setNumCellTypes(2); // right,left cochlea
        setNumCellTypes(4); // right,left cochlea plus lpf,bpf type of ganglion cell
        setEventExtractor(new Extractor(this));
        setBiasgen(null);
        setEventClass(CochleaAMSEvent.class);
        setRenderer(new Renderer(this));
    }

    public class Renderer extends AEChipRenderer{

        boolean didit=false;
        public Renderer(AEChip chip) {
            super(chip);
        }

        @Override
        protected void createMultiCellColors(int numCellTypes) {
            if(didit) return;
            didit=true;
            super.createMultiCellColors(numCellTypes);
            Color[] colors={Color.green,Color.red,Color.green,Color.red};
            int ind=0;
            for(int i=0;i<4;i++){
                for(int j=0;j<4;j++){
                    colors[i].getRGBColorComponents(multiCellColors[ind++]);
                }
            }
        }
    }
    
    /** Extract cochlea events. The event class returned by the extractor is CochleaAMSEvent.
     * The address are mapped as follows
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
     * EAR is the binaruaral ear. EAR=0 is left ear, EAR=1 is right ear.
     * <li>
     * LPFBPF is the ganglion cell type. LPFBPF=1 is a lowpass neuron, LPFBPF=1 is a bandpass neuron.
     * </ul>
     */
    public class Extractor extends TypedEventExtractor implements java.io.Serializable {

        public Extractor(AEChip chip) {
            super(chip);
            setEventClass(CochleaAMSEvent.class);
//            setXmask((short)(63<<2)); // tap bits are bits 2-7
//            setXshift((byte)2); // shift them right to get back to 0-63 after AND masking
//            setYmask((short)0x300); // we don't need y or type because these are overridden below
//            setYshift((byte)8);
//            setTypemask((short)2);
//            setTypeshift((byte)0);
//            setFliptype(true); // no 'type' so make all events have type 1=on type
        }

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
            boolean hasTypes = false;
            if (chip != null) {
                hasTypes = chip.getNumCellTypes() > 1;
            }
            OutputEventIterator<?> outItr = out.outputIterator();
            for (int i = 0; i < n; i += skipBy) {
                int addr = a[i];
                CochleaAMSEvent e = (CochleaAMSEvent) outItr.nextOutput();
                e.timestamp = (timestamps[i]);
                e.x = getXFromAddress(addr);
                e.y = getYFromAddress(addr);
                e.type = getTypeFromAddress(addr);
                j++;
                if (j == incEach) {
                    j = 0;
                    i++;
                }
//            System.out.println("a="+a[i]+" t="+e.timestamp+" x,y="+e.x+","+e.y);
            }
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
         *single y address that can be displayed in the 2d histogram.
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


}
