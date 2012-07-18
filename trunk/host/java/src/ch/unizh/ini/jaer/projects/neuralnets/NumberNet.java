/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.neuralnets;

import jspikestack.*;
import net.sf.jaer.chip.AEChip;

/**
 * 
 * @author Peter
 */
public class NumberNet extends SpikeFilter {

//    SpikeStack<STPLayer,Spike> net;
//    
//    STPLayer.Globals lg;
//    LIFUnit.Globals ug;
//    
    public NumberNet(AEChip chip)
    {   super(chip,2);
    }
    
    @Override
    public NetMapper makeMapper(SpikeStack net) {
        
        SingleSourceVisualMapper map=new SingleSourceVisualMapper();
        map.inDimX=(short)chip.getSizeX();
        map.inDimY=(short)chip.getSizeY(); 
        map.outDimX=net.lay(0).dimx;
        map.outDimY=net.lay(0).dimy;
        return map;
        
    }

//    @Override
//    public SpikeStack getInitialNet() {
//        
//        STPLayer.Factory<STPLayer> layerFactory=new STPLayer.Factory();
//        LIFUnit.Factory unitFactory=new LIFUnit.Factory(); 
//                
//        lg= layerFactory.glob;
//        ug = unitFactory.glob;
//        
//        
//        
//        net=new SpikeStack(layerFactory,unitFactory);
//        buildFromXML(net);
////        net.read.readFromXML(net);
//        return net;
//    }

    @Override
    public void customizeNet(SpikeStack netw) {
               
        if (!net.isBuilt())
            return;
        
        unitGlobs.setTau(100000);
        net.delay=12000;
        unitGlobs.setTref(5000);
        
        net.plot.timeScale=1f;
        
        // Set up connections
        float[] sigf={1, 1, 0, 1};
        net.setForwardStrength(sigf);
        float[] sigb={0, 1, 0, 1};
        net.setBackwardStrength(sigb);
        
        // Up the threshold
//        net.scaleThresholds(500);
        
        
        for (int i=0; i<net.nLayers(); i++)
            for (Unit u:net.lay(i).units)
                u.thresh*=600;
        
        
//        lg.fastWeightTC=2;
//        
//        net.lay(1).enableFastSTDP=true;
//        net.lay(3).enableFastSTDP=true;
//        
//            
//        
//        lg.fastSTDP.plusStrength=-.001f;
//        lg.fastSTDP.minusStrength=-.001f;   
//        lg.fastSTDP.stdpTCminus=10;
//        lg.fastSTDP.stdpTCplus=10;
//        
        net.plot.timeScale=1f;
        
        net.liveMode=true;
        net.plot.realTime=true;
        
        net.plot.updateMicros=100000;
        
        net.inputCurrents=true;
        net.lay(0).inputCurrentStrength=.5f;
        
        net.unrollRBMs();
        
    }

    @Override
    public String[] getInputNames() {
        return new String[] {"Retina"};
    }
    
    
    public float getInputCurrentStrength() {
        
        if (net==null)
            return 0;
        
        return net.lay(0).inputCurrentStrength;
    }

    
    public void setInputCurrentStrength(float inputCurrentStrength) {
        if (net==null)
            return;
        
        this.net.lay(0).inputCurrentStrength = inputCurrentStrength;
    }
    
    

}
