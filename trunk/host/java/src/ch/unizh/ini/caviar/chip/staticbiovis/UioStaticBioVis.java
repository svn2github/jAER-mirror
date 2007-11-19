/*
 * UioStaticBioVis.java
 *
 * Created on 13. november 2007, 13:12
 *
 * Describes the StaticBioVis Chip by Jenny Anna Maria Olsson
 */

package ch.unizh.ini.caviar.chip.staticbiovis;

import ch.unizh.ini.caviar.chip.AEChip;
import ch.unizh.ini.caviar.chip.TypedEventExtractor;
import ch.unizh.ini.caviar.event.*;
import ch.unizh.ini.caviar.graphics.*;
import java.io.*;

/**
 * The chip is a 92x92 pixels imager which converts illumination into a 
 * frequency of events.
 *
 * The class uses UioCameraRenderer to display frames with Gray-Levels on a 
 * black background and UioStaticBioVisDisplayMethod to generate an image of 
 * the pixel output.
 *
 * @author Jenny Anna Maria Olsson (jaolsson@ifi.uio.no)
 */
public class UioStaticBioVis extends AEChip {
    
    /** Creates a new instance of UioStaticBioVis */
    public UioStaticBioVis() {
        setSizeX(92);
        setSizeY(92);
        setNumCellTypes(1); // there are two types (positive and negative) of events from each x,y
        setEventClass(TypedEvent.class); // the chip puts out these kinds of events
        setEventExtractor(new Extractor(this)); // we use the default extractor here
        setBiasgen(null); // don't have one on this chip
        setRenderer(new UioCameraRenderer(this));

        /* To not bother everyone with my own display methods. */
        DisplayMethod cdm = new UioStaticBioVisDisplayMethod(getCanvas());
        getCanvas().addDisplayMethod(cdm);
        getCanvas().setDisplayMethod(cdm);       

    }
    
    public class Extractor extends TypedEventExtractor implements java.io.Serializable{
        public Extractor(AEChip chip){
            super(chip);
            setEventClass(TypedEvent.class);
            setXmask((short)0x007f); // mask this part for x
            setXshift((byte)0); // don't shift x
            setYmask((short)0x7f00);
            setYshift((byte)8);
            setTypemask((short)0);
            setTypeshift((byte)0);
            setFlipx(true);
        }
    }
    
}
