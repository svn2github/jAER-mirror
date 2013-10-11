/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.erbmlearn;

import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import ch.unizh.ini.JEvtLearn.ERBM;
import com.sun.opengl.util.GLUT;
import java.awt.Dimension;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLCanvas;
import javax.media.opengl.GLEventListener;
import javax.media.opengl.glu.GLU;
import javax.swing.JFrame;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.event.PolarityEvent.Polarity;
import org.apache.commons.lang3.ArrayUtils;
/**
 *
 * @author danny
 */
@Description("Class for online learning of event-based RBMs") // this annotation is used for tooltip to this class in the chooser. 
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class ERBMLearnFilter extends EventFilter2D {

    ERBM erbm;    
    
    int x_size = 28;
    int y_size = 28;
    
    int vis_size = x_size * y_size;
    int h_size = 100;
    
    boolean show_weights = false;
    boolean displayNeuronStatistics = true;
    float wMin = -2;
    float wMax =  2;
    
    float vis_tau = 0.1f;
    float learn_rate = 0.001f;

    float thrVisMin = -2;
    float thrVisMax =  2;
    float thrHidMin = -2;
    float thrHidMax =  2;
    
    // Display Variables 
    private GLU glu = null;                 // OpenGL Utilities
    private JFrame weightFrame = null;      // Frame displaying neuron weight matrix
    private GLCanvas weightCanvas = null;   // Canvas on which weightFrame is drawn
    
    public ERBMLearnFilter(AEChip chip) {
        super(chip);
        erbm = new ERBM(vis_size, h_size);
    }

    /** The main filtering method. It computes the mean location using an event-driven update of location and then
     * filters out events that are outside this location by more than the radius.
     * @param in input packet
     * @return output packet
     */
    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {        
        List<Integer> layers = new ArrayList<Integer>();
        List<Double> times = new ArrayList<Double>();
        List<Integer> addrs = new ArrayList<Integer>();
        
        for (BasicEvent o : in) { // iterate over all events in input packet
            if( ((PolarityEvent) o).polarity == Polarity.Off){
                times.add((double) o.timestamp / 1e6);
                layers.add(0);
                addrs.add((int) Math.round((float) o.y / (chip.getSizeY()-1) * (y_size-1)) * x_size +
                            (int) Math.round((float) o.x / (chip.getSizeX()-1) * (x_size-1)));
            }
        }
        if(erbm.pq.size() > 40000){
            log.log(Level.WARNING, "Aw crap, priority queue exploding in size.");
        }
        if(times.size() > 0){
            erbm.processSpikesUntil(times.get(times.size() - 1));
            erbm.addSpikes(ArrayUtils.toPrimitive(times.toArray(new Double[times.size()])), 
                           ArrayUtils.toPrimitive(layers.toArray(new Integer[layers.size()])), 
                           ArrayUtils.toPrimitive(addrs.toArray(new Integer[addrs.size()])));
        }
        
        // Draw Neuron Weight Matrix
        if(show_weights){
            checkWeightFrame();
            weightCanvas.repaint();
        }
        return in; // return the output packet
    }

    /** called when filter is reset
     * 
     */
    @Override
    public void resetFilter() {
        erbm = new ERBM(vis_size, h_size);
        
        erbm.eta = 0.050;
        erbm.thresh_eta = 0;
        erbm.t_refrac = 0.010;
        erbm.tau = 0.1;
        erbm.inp_scale = 0.05;
    }

    @Override
    public void initFilter() {

    }

    void checkWeightFrame() {
        if (weightFrame == null || (weightFrame != null && !weightFrame.isVisible())) 
            createWeightFrame();
    }

    void hideWeightFrame(){
        if(weightFrame!=null) 
            weightFrame.setVisible(false);
    } 
    
    
    void createWeightFrame() {
        // Initializes weightFrame
        weightFrame = new JFrame("Weight Matrix");
        weightFrame.setPreferredSize(new Dimension(400, 400));
        // Creates drawing canvas
        weightCanvas = new GLCanvas();
        // Adds listeners to canvas so that it will be updated as needed
        weightCanvas.addGLEventListener(new GLEventListener() {
            // Called by the drawable immediately after the OpenGL context is initialized
            @Override
            public void init(GLAutoDrawable drawable) {
            
            }

            // Called by the drawable to initiate OpenGL rendering by the client
            // Used to draw and update canvas
            @Override
            synchronized public void display(GLAutoDrawable drawable) {
                if (erbm.weights == null) 
                    return;

                // Prepare drawing canvas
                int border_width  =  2;
                int weightPadding = 20;
                int neuronPadding = 5;
                int neuronsPerRow = 10;
                int neuronsPerColumn = 10;
                int xPixelsPerNeuron = x_size + neuronPadding;
                int yPixelsPerNeuron = y_size + neuronPadding;
                int xPixelsPerRow = xPixelsPerNeuron * neuronsPerRow - neuronPadding;
                int yPixelsPerRow = yPixelsPerNeuron;
                int xPixelsPerColumn = xPixelsPerNeuron;
                int yPixelsPerColumn = yPixelsPerNeuron * neuronsPerRow - neuronPadding;
                int yThreshStart = yPixelsPerColumn + weightPadding;
                
                int totX = xPixelsPerRow;
                int totY = yThreshStart + y_size + neuronPadding;
                
                // Draw in canvas
                GL gl = drawable.getGL();
                // Creates and scales drawing matrix so that each integer unit represents any given pixel
                gl.glLoadIdentity();
                gl.glScalef(drawable.getWidth() / (float) totX, 
                            drawable.getHeight() / (float) totY, 1);
                // Sets the background color for when glClear is called
                gl.glClearColor(0, 0, 0, 0);
                gl.glClear(GL.GL_COLOR_BUFFER_BIT);
                
                int rowOffset;
                int columnOffset;

                //float[][] weights = (float [][]) erbm.weights.toArray2();
                wMax = (float) erbm.weights.max();
                wMin = (float) erbm.weights.min();
                // Draw all Neurons
                for (int c=0; c < neuronsPerColumn; c++) {                    
                    columnOffset = c*yPixelsPerNeuron;
                    for (int r=0; r < neuronsPerRow; r++) {
                        // Adjust x Group Offset
                        rowOffset = r*xPixelsPerNeuron; 
                        
                        // Draw weights for this neuron
                        for (int x=0; x < x_size; x++) {
                            for (int y=0; y < y_size; y++) {
                                float w = ((float) erbm.weights.get(y*x_size + x, c*neuronsPerRow + r) - wMin) / (float) (wMax - wMin);
                                gl.glColor3f(w, w, w);
                                gl.glRectf(rowOffset+x, columnOffset+y, 
                                           rowOffset+x+1, columnOffset+y+1);                                
                            } // END LOOP - Y                            
                        } // END LOOP - X
                        
                        float border = (float) Math.exp( (float) -(erbm.sys_time - erbm.last_spiked[1].get(c*neuronsPerRow + r)) / vis_tau);
                        gl.glColor3f(0, 0, border);
                        
                        gl.glLineWidth(border_width);
                        gl.glBegin(GL.GL_LINE_STRIP);
                        gl.glVertex2d(rowOffset-1, columnOffset-1);
                        gl.glVertex2d(rowOffset-1, columnOffset+1+y_size);
                        gl.glVertex2d(rowOffset+1+x_size, columnOffset+1+y_size);
                        gl.glVertex2d(rowOffset+1+x_size, columnOffset-1);
                        gl.glVertex2d(rowOffset-1, columnOffset-1);
                        gl.glEnd();                     
                    } // END LOOP - Row
                } // END LOOP - Column
                
                // Display Neuron Statistics - Mean, STD, Min, Max
                if (displayNeuronStatistics == true) {
                    final int font = GLUT.BITMAP_HELVETICA_12;
                    GLUT glut = chip.getCanvas().getGlut();
                    gl.glColor3f(1, 1, 1);
                    // Neuron info
                    gl.glRasterPos3f(0, yPixelsPerColumn + neuronPadding, 0);
                    glut.glutBitmapString(font, String.format("M %.2f | wMax: %.2f | wMin: %2f | Time: %.2f | LastSpike[1]: %.2f | LastSpike[3]: %.2f",
                            erbm.weights.mean(), wMax, wMin, erbm.last_update[1], 
                            erbm.last_spiked[1].max(), erbm.last_spiked[3].max()));
                } 

                // Draw thresholds for visible
                thrVisMax = (float) erbm.thr[0].max();
                thrVisMin = (float) erbm.thr[0].min();                
                for (int x=0; x < x_size; x++) {
                    for (int y=0; y < y_size; y++) {
                        float thr = ((float) erbm.thr[0].get(y*x_size +x) - thrVisMin) / (float) (thrVisMax - thrVisMin);
                        gl.glColor3f(thr, thr, thr);
                        gl.glRectf(x, yThreshStart+y, 
                                   x+1, yThreshStart+y+1);
                    } // END LOOP - Y
                } // END LOOP - X
            
                // Draw thresholds for hidden
                int dim_hid = (int) Math.round(Math.sqrt(h_size));
                float xHScale = x_size / dim_hid;
                float yHScale = x_size / dim_hid;
                thrHidMax = (float) erbm.thr[1].max();
                thrHidMin = (float) erbm.thr[1].min();                
                for (int x=0; x < dim_hid; x++) {
                    for (int y=0; y < dim_hid; y++) {
                        float thr = ((float) erbm.thr[1].get(y*dim_hid +x) - thrHidMin) / (float) (thrHidMax - thrHidMin);
                        gl.glColor3f(thr, thr, thr);
                        gl.glRectf(neuronPadding+x_size+(x*xHScale),   yThreshStart+y*yHScale, 
                                   neuronPadding+x_size+(x+1)*xHScale, yThreshStart+(y+1)*yHScale);
                    } // END LOOP - Y
                } // END LOOP - X

                int xReconStart = (int) (neuronPadding+x_size+(dim_hid+1)*xHScale + neuronPadding);
                int yReconStart = (int) yThreshStart + neuronPadding;
                
                // Draw reconstruction
                float rMax = (float) erbm.v_recon.max();
                float rMin = (float) erbm.v_recon.min();
                for (int x=0; x < x_size; x++) {
                    for (int y=0; y < y_size; y++) {
                        float r = ((float) erbm.v_recon.get(y*x_size+x) - rMin) / (float) (rMax - rMin);
                        gl.glColor3f(r/1.5f, r/1.5f, r);
                        gl.glRectf(xReconStart+x, yReconStart+y, 
                                   xReconStart+x+1, yReconStart+y+1);                                
                    } // END LOOP - Y                            
                } // END LOOP - X                
                
                // Display Neuron Statistics - Mean, STD, Min, Max
                if (displayNeuronStatistics == true) {
                    final int font = GLUT.BITMAP_HELVETICA_12;
                    GLUT glut = chip.getCanvas().getGlut();
                    gl.glColor3f(1, 1, 1);
                    // Neuron info
                    gl.glRasterPos3f(0, yThreshStart + y_size + neuronPadding, 0);
                    glut.glutBitmapString(font, String.format("thrVisMax: %.2f | thrVisMin: %2f | thrHidMax: %.2f | thrHidMin: %2f | rMax %.2f | rMin: %.2f | Spikes[0]: %,d | Spikes[1]: %,d | Spikes[2]: %,d | Spikes[3]: %,d",
                            thrVisMax, thrVisMin, thrHidMax, thrHidMin, rMax, rMin,
                            erbm.spike_count[0], erbm.spike_count[1], erbm.spike_count[2], erbm.spike_count[3]));
                } 
                
                // Log error if there is any in OpenGL
                int error = gl.glGetError();
                if (error != GL.GL_NO_ERROR) {
                    if (glu == null) 
                        glu = new GLU();
                    log.log(Level.WARNING, "GL error number {0} {1}", new Object[]{error, glu.gluErrorString(error)});
                } // END IF
            } // END METHOD - Display

            // Called by the drawable during the first repaint after the component has been resized 
            // Adds a border to canvas by adding perspective to it and then flattening out image
            @Override
            synchronized public void reshape(GLAutoDrawable drawable, int x, int y, int width, int height) {
                GL gl = drawable.getGL();
                final int border = 10;
                gl.glMatrixMode(GL.GL_PROJECTION);
                gl.glLoadIdentity(); 
                gl.glOrtho(-border, drawable.getWidth() + border, -border, drawable.getHeight() + border, 10000, -10000);
                gl.glMatrixMode(GL.GL_MODELVIEW);
                gl.glViewport(0, 0, width, height);
            } // END METHOD

            // Called by drawable when display mode or display device has changed
            @Override
            public void displayChanged(GLAutoDrawable drawable, boolean modeChanged, boolean deviceChanged) {
 
            } // END METHOD
        }); // END SCOPE - GLEventListener
        
        // Add weightCanvas to weightFrame
        weightFrame.getContentPane().add(weightCanvas);
        // Causes window to be sized to fit the preferred size and layout of its subcomponents
        weightFrame.pack();
        weightFrame.setVisible(true);
    } // END METHOD    
    /**
     * Called when filter is turned off 
     * makes sure weightFrame gets turned off
     */    
    @Override
    public synchronized void cleanup() {
        if(weightFrame!=null) 
            weightFrame.dispose();
    } // END METHOD

    /**
     * Resets the filter
     * Hides weightFrame if filter is not enabled
     * @param yes true to reset
     */    
    @Override
    public synchronized void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        if(!isFilterEnabled())
            hideWeightFrame();
    } // END METHOD
       
    
    public void setShowWeights(final boolean show_weights) {
        getPrefs().putBoolean("EDBNLearn.showWeights", show_weights);
        getSupport().firePropertyChange("showWeights", this.show_weights, show_weights);
        this.show_weights = show_weights;
    }    
    public boolean getShowWeights(){
        return this.show_weights;
    }    
    public void setTRefrac(final double t_refrac) {
        getPrefs().putDouble("EDBNLearn.t_refrac", t_refrac);
        getSupport().firePropertyChange("t_refrac", erbm.t_refrac, t_refrac);
        erbm.t_refrac = t_refrac;
    }    
    public double getTRefrac(){
        return erbm.t_refrac;
    }    
    
    public void setVisTau(final float vis_tau) {
        getPrefs().putFloat("EDBNLearn.vis_tau", vis_tau);
        getSupport().firePropertyChange("vis_tau", this.vis_tau, vis_tau);
        this.vis_tau = vis_tau;
    }    
    public float getVisTau(){
        return this.vis_tau;
    }       
        
    public void setLearnRate(final float learn_rate) {
        getPrefs().putFloat("EDBNLearn.learn_rate", learn_rate);
        getSupport().firePropertyChange("learn_rate", erbm.eta, learn_rate);
        erbm.eta = learn_rate;
    }    
    public float getLearnRate(){
        return (float) erbm.eta;
    }
    
    public void setThrLearnRate(final float thr_learn_rate) {
        getPrefs().putFloat("EDBNLearn.thr_learn_rate", thr_learn_rate);
        getSupport().firePropertyChange("thr_learn_rate", erbm.thresh_eta, thr_learn_rate);
        erbm.thresh_eta = thr_learn_rate;
    }    
    public float getThrLearnRate(){
        return (float) erbm.thresh_eta;
    }    
    
    public void setTau(final float tau) {
        getPrefs().putFloat("EDBNLearn.tau", tau);
        getSupport().firePropertyChange("tau", erbm.tau, tau);
        erbm.tau = tau;
    }    
    public float getTau(){
        return (float) erbm.tau;
    }         
    
    public void setReconTau(final float recon_tau) {
        getPrefs().putFloat("EDBNLearn.recon_tau", recon_tau);
        getSupport().firePropertyChange("recon_tau", erbm.recon_tau, recon_tau);
        erbm.recon_tau = recon_tau;
    }    
    public float getReconTau(){
        return (float) erbm.recon_tau;
    }  
    
    public void setSTDPWin(final float stdp_win) {
        getPrefs().putFloat("EDBNLearn.stdp_win", stdp_win);
        getSupport().firePropertyChange("stdp_win", erbm.stdp_lag, stdp_win);
        erbm.stdp_lag = stdp_win;
    }    
    public float getSTDPWin(){
        return (float) erbm.stdp_lag;
    }      
}
