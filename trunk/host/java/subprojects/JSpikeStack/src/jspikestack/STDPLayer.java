/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jspikestack;

import java.io.Serializable;

/**
 *
 * @author oconnorp
 */
public class STDPLayer<NetType extends SpikeStack,LayerType extends BasicLayer,GlobalParams extends STDPLayer.Globals> extends BasicLayer<NetType,LayerType> {
    
    
//    
//    public static <NetType extends SpikeStack> NetType makeNet()
//    {   return (NetType) new STPStack();
//    }
//    
    
    
        
//    public static class Layer <NetType extends STDPLayer,LayerType extends BasicLayer, UnitType extends Unit,GlobalParams extends STDPLayer.Layer.Globals> extends BasicLayer<NetType,LayerType,UnitType>
//    {
        int outBufferBookmark=0;   // Bookmark used for stdp learning
        int thisBufferBookmark=0;

        
        GlobalParams glob;
    
        
        public boolean enableSTDP=false;     // Enable STDP on the slow weights

        public STDPLayer(NetType network,Unit.Factory uf,int ind,GlobalParams glo)
        {   super(network,uf,ind);   
            glob=glo;
        }
        
        
        /** Actions to perform after input spike is processed */
        @Override
        public void updateActions()
        {   if (isLearningEnabled())
                stdpLearn();
        }
        
        
        /** Determine whether to spend time looping through spikes */
        public boolean isLearningEnabled()
        {   return enableSTDP;            
        }

        @Override
        public void reset()
        {   super.reset();
            outBufferBookmark=0;
            thisBufferBookmark=0;
        }

        /** Apply STDP learning rule
        * This rule is applied on the layer which owns the outgoing weights.
        * 
        * The layer keeps a "bookmark" of the current position, and advances it 
        * as it reads through spikes.
        */
        public void stdpLearn(){
            /* Idea: for every new spike in the outBuffer of the post-synaptic
            * layer, we want to look for relevant output spikes from this (pre-
            * synaptic) layer,  and adjust the weights according to the stdp 
            * rule.
            * 
            * Shorthand used for internal comments:
            * presyn: pre-synaptic layer
            * postsyn: post-synaptic layer
            * 
            */ 
            if (Lout.outBuffer.isEmpty() || outBuffer.isEmpty()) return;


            // While (postsyn buffer has events) && ( (current postsyn bookmark time) + (stdp window limit) < (current time) )
            while ((Lout.outBuffer.size() > outBufferBookmark) && (Lout.getOutputEvent(outBufferBookmark).time + glob.stdpWin < net.time))
            {   // Iterate over new output spikes

                // Get current output event
                Spike evout=Lout.getOutputEvent(outBufferBookmark); // TODO: REMOVE THIS F'ING CAST


                // Adjust the out-time back by the delay so it can be compared with the input time that caused it.
                double outTime=evout.time-net.delay;

                int tempBookmark=thisBufferBookmark;    // Temporary bookmark for iterating through presyn spikes around an output spike

                // While (there are presynapic events available) && (they come before the end of the relevant stdp window for the post-synaptic spike)
                while ((outBuffer.size() > tempBookmark) && (getOutputEvent(tempBookmark).time < evout.time+glob.stdpWin)) 
                {   // Iterate over input events (from this layer) pertaining to the output event

//                    Spike evin=outBuffer.get(tempBookmark);
                    Spike evin=getOutputEvent(tempBookmark);

                    if (evin.time + glob.stdpWin < outTime) // If input event is too early to be relevant
                    {   thisBufferBookmark++; // Shift up starting bookmark
                    }
                    else // presyn event is within relevant window, do STDP!
                    {   //System.out.println("dW: "+net.stdpRule(evout.time-evin.time));

                        updateWeight(evin.addr,evout.addr,outTime-evin.time);


                    }
                    tempBookmark++;
                } 
    //                System.out.println("t: "+evout.time+" outAddr:"+evout.addr+" nin:"+(tempBookmark-thisBufferBookmark));
                outBufferBookmark++;
            }
        }


        public void updateWeight(int inAddress,int outAddress,double deltaT)
        {
            if (this.enableSTDP)
                wOut[inAddress][outAddress]+=glob.stdp.calc(deltaT);  // Change weight!

        }


        
        public static class Factory<LayerType extends BasicLayer> extends BasicLayer.Factory<LayerType>
        {
            public Globals glob;
            
            public Factory()
            {   glob = new Globals();
            }
            
            @Override
            public <NetType extends SpikeStack,UnitType extends Unit> LayerType make(NetType net,Unit.Factory<?,UnitType> unitFactory,int layerIndex)
            {
                return (LayerType) new STDPLayer(net,unitFactory,layerIndex,glob); // TODO: BAAAD.  I'm confused
            }
        }
        
        
        public static class Globals extends NetController
        {
            public STDPrule stdp=new STDPrule();;
    
            public int stdpWin;

            @Override
            public String getName() {
                return "Layer Conroller Globals";
            }

            public static class STDPrule implements Serializable{

                public float plusStrength = 0.1f;
                public float minusStrength= -0.1f;

                public float stdpTCplus;
                public float stdpTCminus;

                /* Compute weight-change from post-pre time */
                public float calc(double dt) {   //System.out.println("dt: "+dt);
                    if (dt >= 0) {
                        return (float) (plusStrength * (Math.exp(-dt / stdpTCplus)));
                    } else {
                        return (float) (minusStrength * (Math.exp(dt / stdpTCminus)));
                    }
                }
                
            }
            
            
            /** Strength Constant of Pre-Before-Post */
            public float getPlusStrength() {
                return stdp.plusStrength;
            }

            /** Strength Constant of Pre-Before-Post */
            public void setPlusStrength(float plusStrength) {
                this.stdp.plusStrength = plusStrength;
            }

            /** Strength Constant of Post-Before-Pre */
            public float getMinusStrength() {
                return stdp.minusStrength;
            }

            /** Strength Constant of Post-Before-Pre */
            public void setMinusStrength(float minusStrength) {
                this.stdp.minusStrength = minusStrength;
            }

            /** Time constant of Pre-before-Post */
            public float getStdpTCplus() {
                return stdp.stdpTCplus;
            }

            /** Time constant of Pre-before-Post */
            public void setStdpTCplus(float stdpTCplus) {
                this.stdp.stdpTCplus = stdpTCplus;
            }

            /** Time Constant of Post-Before-Pre */
            public float getStdpTCminus() {
                return stdp.stdpTCminus;
            }

            /** Time Constant of Post-Before-Pre */
            public void setStdpTCminus(float stdpTCminus) {
                this.stdp.stdpTCminus = stdpTCminus;
            }
                
            
            
            
            
        }
        
        
        
        @Override
        public NetController getControls()
        {   return new Controller();
        }
        
        class Controller extends BasicLayer.Controller
        {   /** enable STDP learning? */
            public boolean isEnableSTDP() {
                return enableSTDP;
            }

            /** enable STDP learning? */
            public void setEnableSTDP(boolean enableSTDP) {
                STDPLayer.this.enableSTDP = enableSTDP;
            }
        }
        
        
        

//    }
    
    
    
    
}
