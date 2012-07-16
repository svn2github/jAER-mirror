/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jspikestack;

import java.lang.reflect.Array;

/**
 * This class defines a Neural net capable of both long and short term plasticity.
 * 
 * The units in this network contain "fast weights" - that is, weights overlaid 
 * on the regular weight matrix that decay over time and can be trained with an 
 * STDP rule.
 * 
 * @author oconnorp
 */
public class STPLayer <NetType extends SpikeStack,LayerType extends STPLayer> extends STDPLayer<NetType,LayerType,STPLayer.Globals> {

    public boolean enableFastSTDP=false;

    float[][] wOutFast;
    float[][] wLatFast;
    int[][] wOutFastTimes;
                        
//        @Override
//        public void initializeUnits(int nUnits)
//        {   // AHAHAH I tricked you Java! 
//            units=(UnitType[])Array.newInstance(Unit.class, nUnits);
//        }
                
        @Override
        public boolean isLearningEnabled()
        {   return enableFastSTDP || enableSTDP;            
        }

    public STPLayer(NetType network,jspikestack.Unit.Factory uf,int ind,Globals glo)
    {   super(network,uf,ind,glo);   
    }
    
//        @Override
//        public UnitType makeNewUnit(int index)
//        {   return (UnitType) new Unit(index);            
//        }
//        
//        public Layer(STPLayer st,int index)
//        {   super((NetType)st,index);   
//        }        

//    /** Determine whether to spend time looping through spikes */
//    @Override
//    public boolean isLearningEnabled()
//    {   return enableSTDP || enableFast;            
//    }

    @Override
    public void initializeUnits(int nUnits)
    {   super.initializeUnits(nUnits);
        wOutFast=new float[nUnits][];
        wOutFastTimes=new int[nUnits][];
    }
    
    @Override
    public void updateWeight(int inAddress,int outAddress,double deltaT)
    {   super.updateWeight(inAddress,outAddress,deltaT);

        /* Update the given fast weight */
        if (this.enableFastSTDP)
        {   
            wOutFast[inAddress][outAddress]+=glob.fastSTDP.calc(deltaT);  // Change weight!
            wOutFastTimes[inAddress][outAddress]=net.time; 


        }
    }

    @Override
    public float[] getForwardWeights(int index) {

        if (!enableFastSTDP)
            return wOut[index];

        float[] w=new float[wOut[index].length];

        for (int i=0; i<w.length; i++)
            w[i]=getOutWeight(index,i);

        return w;
    }

    @Override
    public float getOutWeight(int source,int dest)
    {
        if (!enableFastSTDP)
            return wOut[source][dest];

        return wOut[source][dest]+currentFastWeightValue(source,dest);
    }

    /** Compute present value of the fast weight */
    public float currentFastWeightValue(int source,int dest)
    {   

        return wOutFast[source][dest]*(float)Math.exp((wOutFastTimes[source][dest]-net.time)/glob.fastWeightTC);

    }

    @Override
    public void setWout(int sourceIndex,float[] wvec)
    {   super.setWout(sourceIndex,wvec);
        
        wOutFast[sourceIndex]=new float[wvec.length];
        wOutFastTimes[sourceIndex]=new int[wvec.length];
    }
    

    public static class Factory<LayerType extends BasicLayer> extends BasicLayer.Factory<LayerType>
    {
        Globals glob;

        public Factory()
        {   glob = new Globals();
        }

        @Override
        public <NetType extends SpikeStack,UnitType extends Unit> LayerType make(NetType net,Unit.Factory<?,UnitType> unitFactory,int layerIndex)
        {
            return (LayerType) new STPLayer(net,unitFactory,layerIndex,glob); // TODO: BAAAD.  I'm confused
        }
    }
        

    public static class Globals extends STDPLayer.Globals
    {

        public float fastWeightTC;

        public STDPLayer.Globals.STDPrule fastSTDP=new STDPLayer.Globals.STDPrule();

    }

    
    
    

        
        /** Extension of Regular LIF unit.. made to manage fast weights */
//        public class Unit extends SpikeStack.Layer.Unit
//        {
//            float[] WoutFast;           // Fast overlay weights
//            double[] WoutFastTimes;     // Time of last update of fastweights
//
//            public Unit(int index)
//            {   super(index);  
//            }
//
//
//            /* Get the forward weights from a given source */
//            @Override
//            public float[] getForwardWeights() {
//                
//                if (!enableFastSTDP)
//                    return Wout;
//                                    
//                float[] w=new float[Wout.length];
//                
//                for (int i=0; i<w.length; i++)
//                    w[i]=getOutWeight(i);
//                
//                return w;
//            }
//            
//            
//            
//            @Override
//            float getOutWeight(int index)
//            {
//                if (!enableFastSTDP)
//                    return Wout[index];
//                    
//                return Wout[index]+currentFastWeightValue(index);
//            }
//            
//            /** Set the output Weight vector.  NOTE: This also resets the fast weights */
//            @Override
//            public void setWout(float[] wvec)
//            {   Wout=wvec;
//                
//                WoutFast=new float[wvec.length];
//                WoutFastTimes=new double[wvec.length];
//            
//            }
// 
//            
//
//        }
    
    
    
    
//    public static class Initializer extends STDPLayer.Initializer
//    {   
//        STDPrule fastSTDP=new STDPLayer.STDPrule();;
//        float fastWeightTC;
//        
//        public Initializer(int nLayers)
//        {   super(nLayers);
//        }
//        
//        @Override
//        public LayerInitializer lay(int n)
//        {   return (LayerInitializer)layers[n];            
//        }
//        
//        public static class LayerInitializer extends STDPLayer.Initializer.LayerInitializer
//        {   
//            boolean enableFastSTDP=false;
//            float fastWeightInfluence=0;
//            
//            public LayerInitializer()
//            {   super();                
//            }
//        }
//    }
    
    
    
    
    
    
    
}
