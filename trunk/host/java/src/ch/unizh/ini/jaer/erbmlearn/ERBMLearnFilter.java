/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.erbmlearn;

import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.eventprocessing.EventFilter2D;
import ch.unizh.ini.JEvtLearn.ERBM;
import com.sun.opengl.util.GLUT;
import java.awt.Dimension;
import java.beans.PropertyChangeListener;
import java.util.Observer;
import java.util.logging.Level;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLCanvas;
import javax.media.opengl.GLEventListener;
import javax.media.opengl.glu.GLU;
import javax.swing.JFrame;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.event.PolarityEvent.Polarity;
import net.sf.jaer.graphics.FrameAnnotater;
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
            
    // Display Variables 
    private GLU glu = null;                 // OpenGL Utilities
    private JFrame neuronFrame = null;      // Frame displaying neuron weight matrix
    private GLCanvas neuronCanvas = null;   // Canvas on which neuronFrame is drawn
    
    public ERBMLearnFilter(AEChip chip) {
        super(chip);
        erbm = new ERBM(vis_size, h_size);
        erbm.eta = 0.001;
        erbm.tau = 5;
    }

    /** The main filtering method. It computes the mean location using an event-driven update of location and then
     * filters out events that are outside this location by more than the radius.
     * @param in input packet
     * @return output packet
     */
    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {        
        int num_spikes = in.getSize();
        
        int [] layers = new int[num_spikes];
        double [] times = new double[num_spikes];
        int [] addrs = new int[num_spikes];
        
        int i = 0;
        for (BasicEvent o : in) { // iterate over all events in input packet
            if( ((PolarityEvent) o).polarity == Polarity.On){
                times[i] = (double) o.timestamp / 1e6;
                if(times[i] < erbm.sys_time){
                    this.log.warning("Timestamp under present: " + o.timestamp + " ");
                }
                layers[i] = 0;
                addrs[i] = (int) Math.round((float) o.y / (chip.getSizeY()-1) * (y_size-1)) * x_size +
                            (int) Math.round((float) o.x / (chip.getSizeX()-1) * (x_size-1));
                i++;
            }
        }
        
        if(num_spikes > 0){
            erbm.processSpikesUntil(times[0]);
            erbm.addSpikes(times, layers, addrs);
        }
        
        // Draw Neuron Weight Matrix
        if(show_weights){
            checkNeuronFrame();
            neuronCanvas.repaint();
        }
        return in; // return the output packet
    }

    /** called when filter is reset
     * 
     */
    @Override
    public void resetFilter() {
        erbm = new ERBM(vis_size, h_size);
    }

    @Override
    public void initFilter() {

    }

    void checkNeuronFrame() {
        if (neuronFrame == null || (neuronFrame != null && !neuronFrame.isVisible())) 
            createNeuronFrame();
    }

    void hideNeuronFrame(){
        if(neuronFrame!=null) 
            neuronFrame.setVisible(false);
    } 
    
    void createNeuronFrame() {
        // Initializes neuronFrame
        neuronFrame = new JFrame("Weight Matrix");
        neuronFrame.setPreferredSize(new Dimension(400, 400));
        // Creates drawing canvas
        neuronCanvas = new GLCanvas();
        // Adds listeners to canvas so that it will be updated as needed
        neuronCanvas.addGLEventListener(new GLEventListener() {
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
                int neuronPadding = 5;
                int neuronsPerRow = 10;
                int neuronsPerColumn = 10;
                int xPixelsPerNeuron = x_size + neuronPadding;
                int yPixelsPerNeuron = y_size + neuronPadding;
                int xPixelsPerRow = xPixelsPerNeuron * neuronsPerRow - neuronPadding;
                int yPixelsPerRow = yPixelsPerNeuron;
                int xPixelsPerColumn = xPixelsPerNeuron;
                int yPixelsPerColumn = yPixelsPerNeuron * neuronsPerRow - neuronPadding;
                
                // Draw in canvas
                GL gl = drawable.getGL();
                // Creates and scales drawing matrix so that each integer unit represents any given pixel
                gl.glLoadIdentity();
                gl.glScalef(drawable.getWidth() / (float) xPixelsPerRow, 
                        drawable.getHeight() / (float) yPixelsPerColumn, 1);
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

                    } // END LOOP - Row
                } // END LOOP - Column
                
                // Display Neuron Statistics - Mean, STD, Min, Max
                if (displayNeuronStatistics == true) {
                    final int font = GLUT.BITMAP_HELVETICA_12;
                    GLUT glut = chip.getCanvas().getGlut();
                    gl.glColor3f(1, 1, 1);
                    // Neuron info
                    gl.glRasterPos3f(0, yPixelsPerColumn, 0);
                    glut.glutBitmapString(font, String.format("Spikes: %d | M %.2f | wMax: %.2f | wMin: %2f | Time: %.2f | LastSpike[1]: %.2f | LastSpike[3]: %.2f",
                            erbm.spike_count, erbm.weights.mean(), wMax, wMin, erbm.last_update[1], 
                            erbm.last_spiked[1].max(), erbm.last_spiked[3].max()));
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
        
        // Add neuronCanvas to neuronFrame
        neuronFrame.getContentPane().add(neuronCanvas);
        // Causes window to be sized to fit the preferred size and layout of its subcomponents
        neuronFrame.pack();
        neuronFrame.setVisible(true);
    } // END METHOD    
    /**
     * Called when filter is turned off 
     * makes sure neuronFrame gets turned off
     */    
    @Override
    public synchronized void cleanup() {
        if(neuronFrame!=null) 
            neuronFrame.dispose();
    } // END METHOD

    /**
     * Resets the filter
     * Hides neuronFrame if filter is not enabled
     * @param yes true to reset
     */    
    @Override
    public synchronized void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        if(!isFilterEnabled())
            hideNeuronFrame();
    } // END METHOD
       
    
    public void setShowWeights(final boolean show_weights) {
        getPrefs().putBoolean("EDBNLearn.showWeights", show_weights);
        getSupport().firePropertyChange("showWeights", this.show_weights, show_weights);
        this.show_weights = show_weights;
    }    
    public boolean getShowWeights(){
        return this.show_weights;
    }
}
