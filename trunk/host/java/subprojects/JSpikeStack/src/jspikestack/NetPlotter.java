/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package jspikestack;

import java.awt.*;
import java.util.Iterator;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.*;
import javax.swing.text.JTextComponent;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.CombinedDomainXYPlot;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYDotRenderer;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

/**
 *
 * @author oconnorp
 */
public class NetPlotter {
    
    SpikeStack net;
    
    public int updateMillis=30;           // Update interval, in milliseconds
    public float timeScale=1;               // Number of network-seconds per real-second 0: doesn't advance.  Inf advances as fast as CPU will allow
    
    boolean realTime=false;         // Set true for real-time computation.  In this case, the network will try to display up to the end of the output queue
    
    
    long lastnanotime=Integer.MIN_VALUE;
    
    double lastNetTime=0;
    
    JTextComponent jt;
    LayerStatePlotter[] layerStatePlots;
    
    public NetPlotter(SpikeStack network)
    {   net=network;        
    }
    
   
    public void raster()
    {   
        CombinedDomainXYPlot plot = new CombinedDomainXYPlot(new NumberAxis("Time"));
        
        // Build a plot for each layer
        for (Object lay:net.layers)
            plot.add(layerRaster((SpikeStack.Layer)lay),1);
        
        JFreeChart chart= new JFreeChart("Raster",JFreeChart.DEFAULT_TITLE_FONT, plot,true);
        
        // Put it in a frame!
        JFrame fr=new JFrame();
        fr.getContentPane().add(new ChartPanel(chart));
        fr.setSize(1200,1000);
        fr.setVisible(true);
    }
    
    /* Create a raster plot for a single layer */
    public XYPlot layerRaster(SpikeStack.Layer lay)
    {
        // Add the data
        Iterator<Spike> itr=lay.outBuffer.iterator();
        XYSeries data=new XYSeries("Events");
        for (int i=0; i<lay.outBuffer.size(); i++)
        {   Spike evt=itr.next();
            data.add((float)evt.time,evt.addr);
        }
        XYDataset raster = new XYSeriesCollection(data);
        
        //SamplingXYLineAndShapeRenderer renderer = new SamplingXYLineAndShapeRenderer(false, true);
        XYDotRenderer renderer = new XYDotRenderer();
        renderer.setDotWidth(2);
        renderer.setDotHeight(5);

        return new XYPlot(raster, null, new NumberAxis("Layer "+lay.ixLayer), renderer);
        
    }

    
    /* Create a layerStatePlots for the network */
    public JFrame createStatePlot()
    {
        int nLayers=net.nLayers();
        
        layerStatePlots=new LayerStatePlotter[nLayers];
        
        JFrame fr=new JFrame();
                
        
        fr.getContentPane().setBackground(Color.GRAY);
        //fr.setForeground(Color.black);
        fr.setLayout(new GridBagLayout());
        
        for (int i=0; i<nLayers; i++)
        {
            JPanel pan=new JPanel();
            
            pan.setBackground(Color.darkGray);
            
            pan.setLayout(new GridLayout());
            
            
            
            ImageDisplay disp=ImageDisplay.createOpenGLCanvas();
           // disp.resetFrame(.5f);
            
            // Assign sizes to the layers
            int sizeX;
            int sizeY;            
            if (net.lay(i).dimx * net.lay(i).dimy < net.lay(i).nUnits())
            {   sizeY=(int)Math.ceil(Math.sqrt(net.lay(i).nUnits()));
                sizeX=(int)Math.ceil(net.lay(i).nUnits()/(double)sizeY);
            }
            else 
            {   sizeX=net.lay(i).dimx;
                sizeY=net.lay(i).dimy;
            }
            disp.setImageSize(sizeX,sizeY);
            
            
//            disp.setBorderSpacePixels(5);
            disp.setPreferredSize(new Dimension(400,400));
                        
            GridBagConstraints c = new GridBagConstraints();
            c.fill=GridBagConstraints.HORIZONTAL;
            c.gridx=i;
            c.gridy=0;
            c.gridheight=2;
            
            pan.add(disp);  
            fr.getContentPane().add(pan,c);
            
            layerStatePlots[i]=new LayerStatePlotter(net.lay(i),disp);
        }
        
        GridBagConstraints c = new GridBagConstraints();
        c.fill=GridBagConstraints.HORIZONTAL;
        c.gridx=0;
        c.gridy=2;
        c.gridwidth=nLayers;
        JPanel j=new JPanel();
        j.setBackground(Color.black);
        
        jt=new JTextArea();
        jt.setBackground(Color.BLACK);
        jt.setForeground(Color.white);
        jt.setEditable(false);
        jt.setAlignmentY(.5f);
        
        
        
        jt.setPreferredSize(new Dimension(400,100));
        
        j.add(jt);
        
        fr.getContentPane().add(j,c);
        
        
        fr.pack();
       // fr.setSize(1000,400);
        fr.setVisible(true);        
                
        return fr;
    }
        
    
    /** Start Plotting the state */
    public void followState()
    {
        final JFrame fr=createStatePlot();
                
        
        class ViewLoop extends Thread{
            

            public ViewLoop() {
                super();
                setName("NetPlotter");
            }
            
            @Override
            public void run()
            {
                while (fr.isShowing())
                {
                    
                    // System.out.println("Loop checking in at : "+lastNetTime+updateMillis*timeScale);
                    
                    if (realTime)
                        state();                    
                    else
                        state(lastNetTime+updateMillis*timeScale);
                    
                    try {

                        Thread.sleep(updateMillis);
                    } catch (InterruptedException ex) {
                        Logger.getLogger(NetPlotter.class.getName()).log(Level.SEVERE, null, ex);
                    }
                    
                    
                }
            }
            
        }
        
        ViewLoop th=new ViewLoop();
        
        th.start();
        
        
        
    }
    
    /* Update the state plot */
    public void state()
    {   state(net.time);        
    }
    
    /* Update the state plot */
    public void state(double upToTime)
    {
        
        // Can't progress further than present.
            upToTime=Math.min(upToTime,net.time);
        
//        long t=System.nanoTime();
        
        // 
//        float updatemillis=(float)updateTime;
        
                
//        if (realTime) {
//            try {
//                Thread.sleep(updatemillis);
//            } catch (InterruptedException ex) {
//                Logger.getLogger(NetPlotter.class.getName()).log(Level.SEVERE, null, ex);
//            }
//        }
        
//        // If not yet ready for next frame, return
//        if ((net.time-lastNetTime)*timeScale < updateTime)
//            return;
        
//        double newNetTime=net.time;
                
        if (layerStatePlots==null)
            createStatePlot();
        
        for (int i=0; i<net.nLayers(); i++)
            layerStatePlots[i].update(upToTime);
        
        
        jt.setText("Time: "+(int)upToTime+"ms\nNetTime: "+(int)net.time+"ms");
        
//        System.out.println(net.time+" "+(t-lastnanotime));
// 
//        lastnanotime=t;
        
        
//        try {
//            
//            Thread.sleep((int)updatemillis);
//        } catch (InterruptedException ex) {
//            Logger.getLogger(NetPlotter.class.getName()).log(Level.SEVERE, null, ex);
//        }
        
        lastNetTime=upToTime;
//        lastNetTime=net.time;
            
    }
    
    public class LayerStatePlotter
    {   float tau;
        SpikeStack.Layer layer;
        ImageDisplay disp;
        float[] state;  // Array of unit states.
        
        double lastTime;
        
        float minState=Float.NaN;
        float maxState=Float.NaN;
        
        float adaptationRate=1f;  // Adaptation rate of the limits.
        
        int outBookmark;
        
        public LayerStatePlotter(SpikeStack.Layer lay,ImageDisplay display)
        {   tau=lay.net.tau;
            layer=lay;
            disp=display;

            state=new float[lay.nUnits()];
            outBookmark=0;
            
        }
        
        public void update()
        {   update(net.time);
        }
        
        /* Update layerStatePlots to current network time */
        public void update(double toTime)
        {
//            double time=layer.net.time;
            
            
                        
            float smin=Float.MAX_VALUE;
            float smax=-Float.MAX_VALUE;
            
            // Step 1: Decay present state
            for (int i=0; i<state.length; i++)
            {   state[i]*=Math.exp((lastTime-toTime)/tau);     
                if (state[i]<smin) smin=state[i];
                if (state[i]>smax) smax=state[i];
            }
            
            
//        System.out.println(net.time);
        
                
            
            // Step 2: Add new events to state
            while (outBookmark<layer.outBuffer.size())
            {   Spike ev=layer.getOutputEvent(outBookmark);
                if (ev.time>toTime)
                    break;
                state[ev.addr]+=Math.exp((ev.time-toTime)/tau);
                if (state[ev.addr]<smin) smin=state[ev.addr];
                if (state[ev.addr]>smax) smax=state[ev.addr];
                outBookmark++;
            }
            
            
            // Step 3: Set the color scale limits
            if (Float.isNaN(minState))
            {   minState=smin;
                maxState=smax;
            }
            else if (adaptationRate==1)
            {   minState=smin;
                maxState=smax; 
            }
            else
            {   float invad=1-adaptationRate;
                minState=smin*adaptationRate+invad*minState;
                maxState=smax*adaptationRate+invad*maxState;                
            }
            
            // Step 4: plot                        
            for (int i=0; i<state.length; i++)
            {   disp.setPixmapGray(i,(state[i]-minState)/(maxState-minState));                
            }
            
            lastTime=toTime;
            
            disp.repaint();
        }
        
                
    }
        
}
