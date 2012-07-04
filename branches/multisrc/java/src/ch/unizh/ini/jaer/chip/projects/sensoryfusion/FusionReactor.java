/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.chip.projects.sensoryfusion;

import java.util.ArrayList;
import java.util.EnumMap;
import javax.swing.JPanel;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.MultiSensoryFilter;
import net.sf.jaer.graphics.Chip2DRenderer;
import net.sf.jaer.graphics.DisplayWriter;

/**
 *
 * @author Peter
 */
public class FusionReactor extends MultiSensoryFilter {

   // Chip2DRenderer mat=new Chip2DRenderer();
    final ShowMat mat=new ShowMat();
    
    class ShowMat implements DisplayWriter{

        JPanel p;
        
        @Override
        public void setWatched(boolean displayed) {
            
        }

        @Override
        public void setPanel(JPanel imagePanel) {
            p=imagePanel;
        }

        @Override
        public JPanel getPanel() {
            return p;
        }

        @Override
        public void display() {
            System.out.println("Running Display Method");
        }
        
    }
    
    public enum xxx {AAA,BBB};
    
    
    public FusionReactor(AEChip chip)
    {   super(chip,2);    
    }
    
    
//    public Class<Enum> getOpts(){
//        return xxx.valueOf(xxx.class,"AAA").getDeclaringClass();
////        return xxx.class.getDeclaringClass();
//    }
    
    @Override
    public EventPacket filterPacket(EventPacket<?> in) {
        
        
        return in;
        
    }

    @Override
    public void resetFilter() {
        
    }

    @Override
    public void initFilter() {
        addDisplayWriter(mat);
    }
        
    @Override
    public String[] getInputNames() {
        String[] s = {"inputA","inputB"};
        return s;
    }


}
