package ch.unizh.ini.jaer.chip.cochlea;

import sf.net.jaer.chip.AEChip;
import sf.net.jaer.chip.TypedEventExtractor;


/**
 * Shih-Chii's and Andre's and Vincent's first cochleas (also for revision).
 * @author tobi
 */
public class CochleaAERb extends CochleaChip  {
    
    /** Creates a new instance of Tmpdiff128 */
    public CochleaAERb() {
        setName("CochleaAERb");
        setSizeX(32);
        setSizeY(2);
        setNumCellTypes(2); // right,left cochlea
        setEventExtractor(new Extractor(this));
        setBiasgen(null);
        setEventClass(BinauralCochleaEvent.class);
    }
    
    public class Extractor extends TypedEventExtractor{
        public Extractor(AEChip chip){
            super(chip);
            setXmask((short)31);
            setXshift((byte)0);
            setYmask((short)32);
            setYshift((byte)5);
            setTypemask((short)1);
            setTypeshift((byte)0);
//            setFliptype(true); // no 'type' so make all events have type 1=on type
        }
        
        @Override public byte getTypeFromAddress(int addr){
            return getYFromAddress(addr)%2==0? (byte)0: (byte)1;
        }
        
    }

}
