/*
 * StdpFeatureLearningIV.java
 * 
 * Created on March 12, 2013
 * 
 * Implements 'Extraction of Temporally correlated features from dynamic vision 
 * sensors with spike-timing-dependent-plasticity' Paper in DVS
 * 
 * @author Haza
 *
 */
package ch.unizh.ini.jaer.projects.stdplearning;

import com.sun.opengl.util.GLUT;
import java.awt.Dimension;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.util.Observable;
import java.util.Observer;
import java.util.Random;
import java.util.logging.Level;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLCanvas;
import javax.media.opengl.GLEventListener;
import javax.media.opengl.glu.GLU;
import javax.swing.JFrame;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.eventio.AEFileInputStream;
import net.sf.jaer.eventio.AEInputStream;
import net.sf.jaer.eventprocessing.tracking.RectangularClusterTracker;
import net.sf.jaer.graphics.AEViewer;
import net.sf.jaer.graphics.AbstractAEPlayer;
import net.sf.jaer.graphics.FrameAnnotater;

@Description("Learns patterns in 2 layer Feedforward Neural Network around Rectangular Cluster Tracker")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)

public class StdpFeatureLearningV extends RectangularClusterTracker implements Observer, FrameAnnotater, PropertyChangeListener {

    // Controls
    protected int neuronsL1 = getPrefs().getInt("StdpFeatureLearningV.neuronsL1", 100);
    {
        setPropertyTooltip("neuronsL1", "Number of neurons in layer 1");
    }

    protected int neuronsL2 = getPrefs().getInt("StdpFeatureLearningV.neuronsL2", 10);
    {
        setPropertyTooltip("neuronsL2", "Number of neurons in layer 2");
    }

    protected int baseFireThres = getPrefs().getInt("StdpFeatureLearningV.baseFireThres", 40000);
    {
        setPropertyTooltip("baseFireThres", "Threshold directly affecting selectivity of neuron");
    }

    protected int minFireThres = getPrefs().getInt("StdpFeatureLearningV.minFireThres", 10000);
    {
        setPropertyTooltip("minFireThres", "Minimum threshold directly affecting selectivity of neuron");
    }

    protected int maxFireThres = getPrefs().getInt("StdpFeatureLearningV.maxFireThres", 100000);
    {
        setPropertyTooltip("maxFireThres", "Max threshold directly affecting selectivity of neuron");
    }

    protected int tLTP = getPrefs().getInt("StdpFeatureLearningV.tLTP", 2000);
    {
        setPropertyTooltip("tLTP", "time window during which LTP occurs (us)");
    }

    protected int tRefrac = getPrefs().getInt("StdpFeatureLearningV.tRefrac", 10000);
    {
        setPropertyTooltip("tRefrac", "Refractory period of neuron (us)");
    }

    protected int tInhibit = getPrefs().getInt("StdpFeatureLearningV.tInhibit", 1500);
    {
        setPropertyTooltip("tInhibit", "Refractory period of neuron (us)");
    }
    
    protected int tauLeak = getPrefs().getInt("StdpFeatureLearningV.tauLeak", 5000);
    {
        setPropertyTooltip("tauLeak", "Leak time constant (us)");
    }

    protected int wMin = getPrefs().getInt("StdpFeatureLearningV.wMin", 1);
    {
        setPropertyTooltip("wMin", "Minimum weight");
    }

    protected int wMax = getPrefs().getInt("StdpFeatureLearningV.wMax", 1000);
    {
        setPropertyTooltip("wMax", "Maximum weight");
    }
    
    protected int wInitMean = getPrefs().getInt("StdpFeatureLearningV.wInitMean", 800);
    {
        setPropertyTooltip("wInitMean", "Initial weight mean");
    }

    protected int wInitSTD = getPrefs().getInt("StdpFeatureLearningV.wInitSTD", 160);
    {
        setPropertyTooltip("wInitSTD", "Initial weight standard deviation");
    }

    protected int alphaPlus = getPrefs().getInt("StdpFeatureLearningV.alphaPlus", 100);
    {
        setPropertyTooltip("alphaPlus", "Weight increment");
    }

    protected int alphaMinus = getPrefs().getInt("StdpFeatureLearningV.alphaMinus", 50);
    {
        setPropertyTooltip("alphaMinus", "Weight decrement");
    }

    protected int betaPlus = getPrefs().getInt("StdpFeatureLearningV.betaPlus", 0);
    {
        setPropertyTooltip("betaPlus", "Weight increment damping factor");
    }

    protected int betaMinus = getPrefs().getInt("StdpFeatureLearningV.betaMinus", 0);
    {
        setPropertyTooltip("betaMinus", "Weight decrement damping factor");
    }

    protected boolean keepWeightsOnRewind = getPrefs().getBoolean("StdpFeatureLearningV.keepWeightsOnRewind", true);
    {
        setPropertyTooltip("keepWeightsOnRewind", "Resets everything on loop in Playback of file except for synapse weights");
    }

    protected boolean displayNeuronStatistics = getPrefs().getBoolean("StdpFeatureLearningV.displayNeuronStatistics", false);
    {
        setPropertyTooltip("displayNeuronStatistics", "Displays each Neurons weight matrix statistics: Mean");
    }

    protected boolean fireMaxOnlyOnceOnSpike = getPrefs().getBoolean("StdpFeatureLearningV.fireMaxOnlyOnceOnSpike", false);
    {
        setPropertyTooltip("fireMaxOnlyOnceOnSpike", "Input spike can only trigger at most one neuron to fire");
    }

    protected boolean displayCombinedPolarity = getPrefs().getBoolean("StdpFeatureLearningV.displayCombinedPolarity", true);
    {
        setPropertyTooltip("displayCombinedPolarity", "Display Combined Polarities in Neuron Weight Matrix");
    }
    
    // Input
    private int xPixels;        // Number of pixels in x direction for input
    private int yPixels;        // Number of pixels in y direction for input
    private int numPolarities;  // Indicates total number of polarities of pixels
    private int numLayers;      // Indicates total number of neuron layers in network 
    
    // Cluster
    private int numClusters;                // Total number of clusters 
    private int[] clusterID;                // Clusters ID number, used to distinguish between clusters that persist through time or newly created ones [cluster]
    private boolean[] clusterActive;        // Indicates whether cluster is currently active [cluster]
    private int[] xStart;                   // (0,0) Coordinate pixel for [cluster]
    private int[] yStart;                   // (0,0) Coordinate pixel for [cluster]
    
    // Neuron
    private float[][] neuronL1Potential;        // Neuron Potential [cluster][neuronL1]
    private float[][] neuronL2Potential;        // Neuron Potential [cluster][neuronL2]
    private float[][][][] synapseWeightsL1;     // Synaptic weights of [neuronL1][polarity][x][y]
    private float[][] synapseWeightsL2;         // Synaptic weights of [neuronL2][neuronL1]
    private float[][][][] synapseWeightMapL2;   // Synaptic weights reconstruction of average activity in [neuronL2][polarity][x][y]
    private int[][][][] pixelSpikeTiming;       // Last spike time of [cluster][polarity][x][y]
    private int[][] neuronL1SpikeTiming;        // Last input spike time of [cluster][neuronL1]
    private int[][] neuronL1FireTiming;         // Last output fire time of [cluster][neuronL1]
    private int[][] neuronL2SpikeTiming;        // Last input spike time of [cluster][neuronL2]
    private int[][] neuronL2FireTiming;         // Last output fire time of [cluster][neuronL2]
    private boolean[] neuronSpikeTimingInit;    // Indicates whether variable has been initialized or needs to be reset for 
    private float fireThres;                    // Value at which neurons start to fire 
    private int[][] t0;                         // Timestamp at which neurons are over lateral inhibition in [cluster][layer]
    private int[][] nextNeuronToUpdate;         // Helps indicates neuron in which to start update, is generally neuron next to one which fired last [cluster][layer]
    private boolean[][] fireInhibitor;          // Inhibits all other neurons in group from firing [cluster][layer]
    private boolean rewind;                     // Indicates rewind in playback
            
    // Listeners
    private boolean viewerPropertyChangeListenerInit; // Indicates that listener for viewer changes has been initialized - used to detect open file and rewind

    // Display Variables 
    private GLU glu = null;                 // OpenGL Utilities
    private JFrame neuronL1Frame = null;      // Frame displaying neuronL1 weight matrix
    private GLCanvas neuronL1Canvas = null;   // Canvas on which neuronL1Frame is drawn
    private JFrame neuronL2Frame = null;      // Frame displaying neuronL1 weight matrix
    private GLCanvas neuronL2Canvas = null;   // Canvas on which neuronL1Frame is drawn

    /** 
     * Constructor 
     * @param chip Called with AEChip properties
     */
    public StdpFeatureLearningV(AEChip chip) {
        super(chip);
        chip.addObserver(this);
        initFilter();
    } // END CONSTRUCTOR

    /**
     * Called on creation
     * Initializes all 'final' size variables and declares arrays
     * resetFilter call at end of method actually initializes all values
     */    
    @Override
    public void initFilter() {
        super.initFilter();
        
        xPixels = 16;
        yPixels = xPixels;
        numPolarities = 2;
        numLayers = 2;

        numClusters = getMaxNumClusters();
        clusterID = new int[numClusters];
        clusterActive = new boolean[numClusters];
        xStart = new int[numClusters];                   
        yStart = new int[numClusters];                   
        
        neuronL1Potential = new float[numClusters][neuronsL1];
        neuronL2Potential = new float[numClusters][neuronsL2];
        synapseWeightsL1 = new float[neuronsL1][numPolarities][xPixels][yPixels];
        synapseWeightsL2 = new float[neuronsL2][neuronsL1];
        synapseWeightMapL2 = new float[neuronsL2][numPolarities][xPixels][yPixels];
        pixelSpikeTiming = new int[numClusters][numPolarities][xPixels][yPixels];
        neuronL1FireTiming = new int[numClusters][neuronsL1];
        neuronL2FireTiming = new int[numClusters][neuronsL2];
        neuronL1SpikeTiming = new int[numClusters][neuronsL1];
        neuronL2SpikeTiming = new int[numClusters][neuronsL2];
        neuronSpikeTimingInit = new boolean[numClusters];

        t0 = new int[numClusters][numLayers];
        nextNeuronToUpdate = new int[numClusters][numLayers];
        fireInhibitor = new boolean[numClusters][numLayers];

        viewerPropertyChangeListenerInit = false;
        
        rewind = false;
        
        fireThres = baseFireThres; 

        resetFilter();
    } // END METHOD

    /**
     * Called on filter reset which happens on creation of filter, on reset button press, and on rewind 
     * Initializes all variables which aren't final to their default values
     * Note that synapseWeights are either initialized to wInit parameters or left as they were previously
     */    
    @Override
    public synchronized void resetFilter() {
        super.resetFilter();

        // Reset all cluster neuron variables 
        for (int c=0; c<numClusters; c++) { 
            clusterActive[c] = false;
            clusterID[c] = c;
            resetCluster(c);
        }        

        // Keep current weights on rewind if keepWeightsOnRewind is enabled
        // Otherwise initialize random weights according to parameters
        if ((keepWeightsOnRewind == true && rewind == true) == false) {
            Random r = new Random(); // Used to generate random number for initial synapse weight
            // Layer 1 weights
            for (int nL1=0; nL1<neuronsL1; nL1++) 
                for (int p=0; p<numPolarities; p++) 
                    for (int x=0; x<xPixels; x++) 
                        for (int y=0; y<yPixels; y++) {
                            // wInit is Gaussian distributed 
                            double wInit = r.nextGaussian()*wInitSTD+wInitMean;
                            if (wInit < wMin) 
                                wInit = wMin;
                            if (wInit > wMax) 
                                wInit = wMax;
                            synapseWeightsL1[nL1][p][x][y] = (float) wInit; 
                        } // END LOOP - All synapses in L1
            // Layer 2 weights
            for (int nL2=0; nL2<neuronsL2; nL2++) 
                for (int nL1=0; nL1<neuronsL1; nL1++) {
                            // wInit is Gaussian distributed 
                            double wInit = r.nextGaussian()*wInitSTD+wInitMean;
                            if (wInit < wMin) 
                                wInit = wMin;
                            if (wInit > wMax) 
                                wInit = wMax;
                            synapseWeightsL2[nL2][nL1] = (float) wInit; 
                } // END LOOP - All synapses in L2
        } // END IF - Synapse Weight Initialization

        // Make sure rewind flag is turned off at end
        if (rewind == true) 
            rewind = false;

    } // END METHOD

    /**
     * Resets all internal neuron variables of individual cluster used in STDP Learning
     * Called on reset or whenever a new cluster is found
     */    
    private void resetCluster(int c) {
        neuronSpikeTimingInit[c] = false;

        for (int l=0; l<numLayers; l++) {
            t0[c][l] = 0;
            nextNeuronToUpdate[c][l] = 0;
            fireInhibitor[c][l] = false;
        }
        
        for (int nL1=0; nL1<neuronsL1; nL1++) {
            neuronL1Potential[c][nL1] = 0;
            neuronL1FireTiming[c][nL1] = 0;
        } // END LOOP - NeuronsL1

        for (int nL2=0; nL2<neuronsL2; nL2++) {
            neuronL2Potential[c][nL2] = 0;
            neuronL2FireTiming[c][nL2] = 0;
        } // END LOOP - NeuronsL2

        for (int p=0; p<numPolarities; p++) 
            for (int x=0; x<xPixels; x++) 
                for (int y=0; y<yPixels; y++) 
                    pixelSpikeTiming[c][p][x][y] = 0;
    } // END METHOD
    
    /**
     * Receives Packets of information and passes it onto processing
     * @param in Input events can be null or empty.
     * @return The filtered events to be rendered
     */
    @Override
    synchronized public EventPacket filterPacket(EventPacket in) {
        super.filterPacket(in);  
        
        if (viewerPropertyChangeListenerInit == false) {
            chip.getAeViewer().addPropertyChangeListener(this);
            chip.getAeViewer().getAePlayer().getSupport().addPropertyChangeListener(this); 
            viewerPropertyChangeListenerInit = true;
        } // END IF
        
      
        // Update cluster information once per packet
        // That is, update x and yStart variables and reset cluster information for clusters which aren't persistent
        // And determine which clusters are active for learning or initialization
        updateClusters();

        // Event Iterator - Write only relevant events inside xPixels by yPixels window to out
        // Apply STDP Rule
        for (Object o : in) {
            // Cast to PolarityEvent since we are interested in timestamp and polarity of spike
            PolarityEvent e = (PolarityEvent) o;
            // Assume that current event's timestamp is initial neuronSpikeTiming for all clusters that need to reset
            for (int c=0; c<numClusters; c++) { 
                if (clusterActive[c] == true) {
                    if (neuronSpikeTimingInit[c] == false) {
                        for (int nL1=0; nL1<neuronsL1; nL1++) 
                            neuronL1SpikeTiming[c][nL1] = e.timestamp;
                        for (int nL2=0; nL2<neuronsL2; nL2++) 
                            neuronL2SpikeTiming[c][nL2] = e.timestamp;
                        neuronSpikeTimingInit[c] = true;
                    } else {
                        // Check what clusters the events belong to
                        if (e.x >= xStart[c] &&  e.x < xPixels + xStart[c] && 
                                e.y >= yStart[c] && e.y < yPixels + yStart[c]) 
                            applySTDPL1(c, e.getTimestamp(), e.getX()-xStart[c], e.getY()-yStart[c], e.getType());
                    } // END IF - neuronSpikeTimingInit
                } // END IF - Cluster Active
            } // END LOOP - numClusters 
        } // END LOOP - Event Iterator
        
        // Draw Neuron Weight Matrix
        checkNeuronFrame();
        neuronL1Canvas.repaint();
        neuronL2Canvas.repaint();

        // Output Filtered Events
        return in;
    } // END METHOD
    
    /**
     * Check for property changes coming from AEViewer and AEFileInputStream
     * Every FileOpen create new FileInputStream listener which would detect when playback is looped 
     * @param evt event coming from AEViewer or AEFileInputStream
     */
    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if (evt.getSource() instanceof AEFileInputStream) {
            if (evt.getPropertyName().equals(AEInputStream.EVENT_REWIND)) { 
                rewind = true;
            } else if (evt.getPropertyName().equals(AEInputStream.EVENT_WRAPPED_TIME)) {
                rewind = true;
            } // END IF
        } else if (evt.getSource() instanceof AEViewer) {
            if (evt.getPropertyName().equals(AEViewer.EVENT_FILEOPEN)) { 
                log.info("File Open");
                AbstractAEPlayer player = chip.getAeViewer().getAePlayer();
                AEFileInputStream in = (AEFileInputStream) (player.getAEInputStream());
                in.getSupport().addPropertyChangeListener(this);
                // Treat FileOpen same as a rewind
                rewind = true;
                resetFilter();
            } // END IF
        } // END IF
    } // END IF

    /**
     * Updates cluster internal variables based on new cluster information
     * Called by filterPacket every time new event packet comes in
     * Updates xStart and yStart variables for all clusters 
     * Resets cluster internal STDP variables if new clusters are available
     */
    private void updateClusters() {
        Cluster[] tempCluster = new Cluster[numClusters];       // Holds visible clusters in clusters
        boolean[] tempClusterFound = new boolean[numClusters];  // Indicates if visible cluster ID in clusters has been found in clusterID  
        boolean[] clusterFound = new boolean[numClusters];      // Indicates if clusterID has been found and updated

        // Initialize variables 
        for (int c=0; c<numClusters; c++) {
            clusterActive[c] = false;
            tempClusterFound[c] = false;
            clusterFound[c] = false;
        } // END LOOP
        
        // Store all visible cluster IDs in an array 
        // Store the number of available clusters
        int idx = 0;
        for (Cluster c : clusters) {
            if (c.isVisible()) {
                tempCluster[idx] = c;
                if (idx<numClusters) {
                    idx++;
                } else {
                    break;
                }
            }
        } // END LOOP

        // Search through visible clusters to see if it already exists in clusterID
        // Tag these clusters and update them
        for (int i=0; i<idx; i++) {
            for (int cID=0; cID<numClusters; cID++) {
                if (clusterID[cID] == tempCluster[i].getClusterNumber()) {
                    tempClusterFound[i] = true;
                    clusterFound[cID] = true;
                    xStart[cID] = (int) (tempCluster[i].getLocation().x-xPixels/2f);
                    yStart[cID] = (int) (tempCluster[i].getLocation().y-yPixels/2f);
                    clusterActive[cID] = true;
                } // END IF 
            } // END LOOP - numClusters
        } // END LOOP - Visible Clusters
            
        // Search through visible clusters 
        // If it has not been tagged 
        // Then place it at first untagged location of clusterID and update/reset it
        // Mark as tagged
        for (int i=0; i<idx; i++) {
            if (tempClusterFound[i] == false) {
                for (int cID=0; cID<numClusters; cID++) {
                    if (clusterFound[cID] == false) {
                        tempClusterFound[i] = true;
                        clusterFound[cID] = true;
                        clusterID[cID] = tempCluster[i].getClusterNumber();
                        xStart[cID] = (int) (tempCluster[i].getLocation().x-xPixels/2f);
                        yStart[cID] = (int) (tempCluster[i].getLocation().y-yPixels/2f);
                        clusterActive[cID] = true;
                        resetCluster(cID);
                        break;
                    } // END IF - clusterFound
                } // END LOOP - numClusters
            } // END IF - tempClusterFound
        } // END LOOP - Visible Clusters

    } // END METHOD

    /**
     * Applies STDP Learning Rule
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     */
    private void applySTDPL1(int c, int ts, int x, int y, int polarity) {
        int layer = 0; // Corresponds to Layer 1
        // If Neurons aren't inhibited
        if (ts >= t0[c][layer]) {
            // Update all Neuron Integration states
            for (int nIdx=0; nIdx<neuronsL1; nIdx++) {
                // Start update from neuron next to the one that fired last
                int n = (nextNeuronToUpdate[c][layer] + nIdx) % neuronsL1;
                // Make sure neuron is not in its refractory period
                if (ts >= neuronL1FireTiming[c][n]+tRefrac) {
                    boolean potentialAboveThres = updateNeuronL1IntegrationState(c, n, ts, polarity, x, y);
                    // Only update synapses if fireInhibitor is disabled
                    // fireInhibitor will only be enabled if fireMaxOnlyOnceOnSpike is on 
                    // and a neuron has already fired for the given input spike / event
                    if (fireInhibitor[c][layer] == false) 
                        // If Neuron Fires Then 
                        if (potentialAboveThres == true) {
                            // Update synapse weights of these neurons
                            updateSynapseWeights(c, layer, n, ts);
                            // Inhibit all neurons
                            t0[c][layer] = ts + tInhibit;
                            // Update neuron fire timing maps
                            neuronL1FireTiming[c][n] = ts;
                            // STDP FOR LAYER 2 - MAKE CODE BETTER ASAP
                            applySTDPL2(c, ts, n);
                            // Update which neuron to start updating on next spike
                            nextNeuronToUpdate[c][layer]=n+1;
                            // If we allow neuron to fire only once per spike, then finish updating potentials for all neurons and inhibit firing
                            if (fireMaxOnlyOnceOnSpike == true) 
                                fireInhibitor[c][layer] = true;
                        } // END IF - Fire 
                } // END IF - Refractory period
            } // END LOOP - Neurons
        } // END IF - Inhibition
        // Make sure fireInhibitor is turned off after all neurons have been updated
        fireInhibitor[c][layer] = false;
        // Update pixel spike timing maps
        pixelSpikeTiming[c][polarity][x][y] = ts;
    } // END METHOD
    
    /**
     * Applies STDP Learning Rule
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     * @param e Polarity Events which are considered input spikes into the neurons
     */
    private void applySTDPL2(int c, int ts, int nL1) {
        int layer = 1; // Corresponds to Layer 2 L2
        // If Neurons aren't inhibited
        if (ts >= t0[c][layer]) {
            // Update all Neuron Integration states
            for (int nIdx=0; nIdx<neuronsL2; nIdx++) {
                // Start update from neuron next to the one that fired last
                int n = (nextNeuronToUpdate[c][layer] + nIdx) % neuronsL2;
                // Make sure neuron is not in its refractory period
                if (ts >= neuronL2FireTiming[c][n]+tRefrac) {
                    boolean potentialAboveThres = updateNeuronL2IntegrationState(c, n, ts, nL1);
                    // Only update synapses if fireInhibitor is disabled
                    // fireInhibitor will only be enabled if fireMaxOnlyOnceOnSpike is on 
                    // and a neuron has already fired for the given input spike / event
                    if (fireInhibitor[c][layer] == false) 
                        // If Neuron Fires Then 
                        if (potentialAboveThres == true) {
                            // Update synapse weights of these neurons
                            updateSynapseWeights(c, layer, n, ts);
                            // Inhibit all neurons
                            t0[c][layer] = ts + tInhibit;
                            // Update neuron fire timing maps
                            neuronL2FireTiming[c][n] = ts;
                            // Update which neuron to start updating on next spike
                            nextNeuronToUpdate[c][layer]=n+1;
                            // If we allow neuron to fire only once per spike, then finish updating potentials for all neurons and inhibit firing
                            if (fireMaxOnlyOnceOnSpike == true) 
                                fireInhibitor[c][layer] = true;
                        } // END IF - Fire 
                } // END IF - Refractory period
            } // END LOOP - Neurons
        } // END IF - Inhibition
        // Make sure fireInhibitor is turned off after all neurons have been updated
        fireInhibitor[c][layer] = false;
    } // END METHOD    
    
    /**
     * Updates Neuron Integration State every time there is a spike, tells whether neuron fires
     * @param group Current neuron group
     * @param neuron Current neuron
     * @param ts Current time stamp
     * @param polarity Current Polarity - On or Off
     * @param x X address of pixel / spike
     * @param y Y address of pixel / spike
     * @return boolean indicating whether neuron has fired 
     */
    private boolean updateNeuronL1IntegrationState(int c, int neuron, int ts, int polarity, int x, int y) {
        // Neuron Update equation
        double temp = - (ts - neuronL1SpikeTiming[c][neuron]) / (double) tauLeak;
        neuronL1Potential[c][neuron] = neuronL1Potential[c][neuron] * (float) Math.exp(temp) + synapseWeightsL1[neuron][polarity][x][y];  
        neuronL1SpikeTiming[c][neuron] = ts;
        // If updated potential is above firing threshold, then fire and reset
        if (neuronL1Potential[c][neuron] >= fireThres) {
            neuronL1Potential[c][neuron] = 0;
            return true;
        } else {
            return false;
        } // END IF
    } // END METHOD

    /**
     * Updates Neuron Integration State every time there is a spike, tells whether neuron fires
     * @param group Current neuron group
     * @param neuron Current neuron
     * @param ts Current time stamp
     * @param polarity Current Polarity - On or Off
     * @param x X address of pixel / spike
     * @param y Y address of pixel / spike
     * @return boolean indicating whether neuron has fired 
     */
    private boolean updateNeuronL2IntegrationState(int c, int neuron, int ts, int neuronL1) {
        float fireThresL2 = fireThres / 1000f;
        // Neuron Update equation
        double temp = - (ts - neuronL2SpikeTiming[c][neuron]) / (double) tauLeak;
        neuronL2Potential[c][neuron] = neuronL2Potential[c][neuron] * (float) Math.exp(temp) + synapseWeightsL2[neuron][neuronL1];  
        neuronL2SpikeTiming[c][neuron] = ts;
        // If updated potential is above firing threshold, then fire and reset
        if (neuronL2Potential[c][neuron] >= fireThresL2) {
            neuronL2Potential[c][neuron] = 0;
            return true;
        } else {
            return false;
        } // END IF
    } // END METHOD

    /**
     * Updates Weights of synapses connecting pixels to the neurons according to STDP Learning Rule
     * @param neuron Current firing neuron
     * @param ts Current spike time stamp
     */
    private void updateSynapseWeights(int c, int layer, int neuron, int ts) {
        // Update synapses for all polarities and pixels depending on STDP Rule
        // L1
        if (layer == 0) {
            for (int p=0; p<numPolarities; p++)
                for (int x=0; x<xPixels; x++)
                    for (int y=0; y<yPixels; y++) {
                        // LTP - Long Term Potentiation
                        if (ts-pixelSpikeTiming[c][p][x][y]<=tLTP) {
                            synapseWeightsL1[neuron][p][x][y] = synapseWeightsL1[neuron][p][x][y] + 
                                    alphaPlus * (float) Math.exp(-betaPlus * 
                                    (synapseWeightsL1[neuron][p][x][y] - wMin) / (double) (wMax - wMin));
                            // Cut off at wMax
                            if (synapseWeightsL1[neuron][p][x][y] > wMax) 
                                synapseWeightsL1[neuron][p][x][y] = wMax;
                        // LTD - Long Term Depression
                        } else {
                            synapseWeightsL1[neuron][p][x][y] = synapseWeightsL1[neuron][p][x][y] - 
                                    alphaMinus * (float) Math.exp(-betaMinus * 
                                    (wMax - synapseWeightsL1[neuron][p][x][y]) / (double) (wMax - wMin));
                            // Cut off at wMin
                            if (synapseWeightsL1[neuron][p][x][y] < wMin) 
                                synapseWeightsL1[neuron][p][x][y] = wMin;
                        } // END IF - STDP Rule
                    } // END IF - All synapses
        // L2
        } else if (layer == 1) {
            int tLTPL2 = tLTP*10;
            for (int nL1=0; nL1<neuronsL1; nL1++) {
                // LTP - Long Term Potentiation
                if (ts-neuronL1FireTiming[c][nL1]<=tLTPL2) {
                    synapseWeightsL2[neuron][nL1] = synapseWeightsL2[neuron][nL1] + 
                            alphaPlus * (float) Math.exp(-betaPlus * 
                            (synapseWeightsL2[neuron][nL1] - wMin) / (double) (wMax - wMin));
                    // Cut off at wMax
                    if (synapseWeightsL2[neuron][nL1] > wMax) 
                        synapseWeightsL2[neuron][nL1] = wMax;
                // LTD - Long Term Depression
                } else {
                    synapseWeightsL2[neuron][nL1] = synapseWeightsL2[neuron][nL1] - 
                            alphaMinus * (float) Math.exp(-betaMinus * 
                            (wMax - synapseWeightsL2[neuron][nL1]) / (double) (wMax - wMin));
                    // Cut off at wMin
                    if (synapseWeightsL2[neuron][nL1] < wMin) 
                        synapseWeightsL2[neuron][nL1] = wMin;
                } // END IF - STDP Rule
            } // END IF - All synapses
        } // END IF
    } // END METHOD

    
    private void constructSynapseWeightMapL2() {
        // Clear map
        for (int nL2=0; nL2<neuronsL2; nL2++) 
            for (int p=0; p<numPolarities; p++) 
                for (int x=0; x<xPixels; x++) 
                    for (int y=0; y<yPixels; y++) 
                        synapseWeightMapL2[nL2][p][x][y] = 0;
                
        // Sum all weighted synapse weight matrices
        for (int nL2=0; nL2<neuronsL2; nL2++) 
            for (int nL1=0; nL1<neuronsL1; nL1++) 
                for (int p=0; p<numPolarities; p++) 
                    for (int x=0; x<xPixels; x++) 
                        for (int y=0; y<yPixels; y++) 
                            synapseWeightMapL2[nL2][p][x][y] = synapseWeightMapL2[nL2][p][x][y] + 
                                    synapseWeightsL1[nL1][p][x][y]*(synapseWeightsL2[nL2][nL1]-wMin) / 
                                    (float) (wMax-wMin);
        
        // Normalize 
        for (int nL2=0; nL2<neuronsL2; nL2++) 
            for (int p=0; p<numPolarities; p++) 
                for (int x=0; x<xPixels; x++) 
                    for (int y=0; y<yPixels; y++) 
                        synapseWeightMapL2[nL2][p][x][y] = synapseWeightMapL2[nL2][p][x][y] /
                                (float)neuronsL1; // CHECK - FIX
    }

    /**
     * Checks that Neuron Weight Matrix is always being displayed
     * Creates it if it is not
     */
    void checkNeuronFrame() {
        if (neuronL1Frame == null || (neuronL1Frame != null && !neuronL1Frame.isVisible())) 
            createNeuronL1Frame();
        if (neuronL2Frame == null || (neuronL2Frame != null && !neuronL2Frame.isVisible())) 
            createNeuronL2Frame();
    } // END METHOD

    /**
     * Hides neuronFrame
     */
    void hideNeuronFrame() {
        if(neuronL1Frame!=null) 
            neuronL1Frame.setVisible(false);
        if(neuronL2Frame!=null) 
            neuronL2Frame.setVisible(false);
    } // END METHOD
    
    /**
     * Creates Neuron Weight Matrix Frame
     */
    void createNeuronL1Frame() {
        // Initializes neuronFrame
        neuronL1Frame = new JFrame("Neuron Layer 1 Synapse Weight Matrix");
        neuronL1Frame.setPreferredSize(new Dimension(400, 400));
        // Creates drawing canvas
        neuronL1Canvas = new GLCanvas();
        // Adds listeners to canvas so that it will be updated as needed
        neuronL1Canvas.addGLEventListener(new GLEventListener() {
            // Called by the drawable immediately after the OpenGL context is initialized
            @Override
            public void init(GLAutoDrawable drawable) {
            
            }

            // Called by the drawable to initiate OpenGL rendering by the client
            // Used to draw and update canvas
            @Override
            synchronized public void display(GLAutoDrawable drawable) {
                if (synapseWeightsL1 == null) 
                    return;

                // Prepare drawing canvas
                int neuronPadding = 5;
                int xPixelsPerNeuron = xPixels + neuronPadding;
                int yPixelsPerNeuron = yPixels * numPolarities + neuronPadding;
                int neuronsPerRow = (int) Math.sqrt((double) neuronsL1); 
                int neuronsPerColumn = (int) Math.ceil((double)neuronsL1 / neuronsPerRow);
                int pixelsPerRow = xPixelsPerNeuron * neuronsPerRow - neuronPadding;
                int pixelsPerColumn = yPixelsPerNeuron * neuronsPerColumn - neuronPadding;
                
                // Draw in canvas
                GL gl = drawable.getGL();
                // Creates and scales drawing matrix so that each integer unit represents any given pixel
                gl.glLoadIdentity();
                gl.glScalef(drawable.getWidth() / (float) pixelsPerRow, 
                        drawable.getHeight() / (float) pixelsPerColumn, 1);
                // Sets the background color for when glClear is called
                gl.glClearColor(0, 0, 0, 0);
                gl.glClear(GL.GL_COLOR_BUFFER_BIT);
                
                int xOffset = 0;
                int yOffset = 0;

                // Draw all L1 Neurons
                // Draw weight matrix
                for (int n=0; n<neuronsL1; n++) {
                    for (int x=0; x<xPixels; x++) {
                        for (int y=0; y<yPixels; y++) {
                            // Handle Polarity cases independently, not through a for loop
                            float wOFF = (synapseWeightsL1[n][0][x][y] - wMin) / (float) (wMax - wMin);
                            float wON = (synapseWeightsL1[n][1][x][y] - wMin) / (float) (wMax - wMin);
                            if (displayCombinedPolarity == true) {
                                gl.glColor3f(wON, 0, wOFF);
                                gl.glRectf(xOffset+x, yOffset+y+yPixels, 
                                        xOffset+x + 1, yOffset+y+yPixels + 1);
                            } else if (displayCombinedPolarity == false) {
                                gl.glColor3f(wOFF, wOFF, 0);
                                gl.glRectf(xOffset+x, yOffset+y, 
                                        xOffset+x + 1, yOffset+y + 1);
                                gl.glColor3f(0, wON, wON);
                                gl.glRectf(xOffset+x, yOffset+y + yPixels, 
                                        xOffset+x + 1, yOffset+y + yPixels + 1);
                            } // END IF - Display Polarity
                        } // END LOOP - Y
                    } // END LOOP - X

                    // Display Neuron Statistics - Mean, STD, Min, Max
                    if (displayNeuronStatistics == true) {
                        final int font = GLUT.BITMAP_HELVETICA_12;
                        GLUT glut = chip.getCanvas().getGlut();
                        gl.glColor3f(1, 1, 1);
                        // Neuron info
                        gl.glRasterPos3f(xOffset, yOffset, 0);
                        glut.glutBitmapString(font, String.format("M %.2f", getNeuronMeanWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+4, 0);
                        //glut.glutBitmapString(font, String.format("S %.2f", getNeuronSTDWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+8, 0);
                        //glut.glutBitmapString(font, String.format("- %.2f", getNeuronMinWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+12, 0);
                        //glut.glutBitmapString(font, String.format("+ %.2f", getNeuronMaxWeight(n)));
                    } // END IF 

                    // Draw Box around firing neuron with color corresponding to 
                    // Neuron Firing Rate in given Packet
//                    if (neuronFireHistogram == true) {
//                        float color = neuronFire[n]/(float)numNeuronFire;
//                        gl.glPushMatrix();
//                        gl.glLineWidth(1f);
//                        gl.glBegin(GL.GL_LINE_LOOP);
//                        gl.glColor3f(color,color,color);
//                        gl.glVertex2f(xOffset,yOffset);
//                        gl.glVertex2f(xOffset,yOffset+yPixels*2);
//                        gl.glVertex2f(xOffset+xPixels,yOffset+yPixels*2);
//                        gl.glVertex2f(xOffset,yOffset+yPixels*2);
//                        gl.glEnd();
//                        gl.glPopMatrix();
//                    } // END IF

                    // Adjust x and y Offsets
                    xOffset += xPixelsPerNeuron; 
                    if (n%neuronsPerRow == neuronsPerRow-1) {
                        xOffset = 0;
                        yOffset += yPixelsPerNeuron;
                    } // END IF
                } // END LOOP - Neuron
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
        neuronL1Frame.getContentPane().add(neuronL1Canvas);
        // Causes window to be sized to fit the preferred size and layout of its subcomponents
        neuronL1Frame.pack();
        neuronL1Frame.setVisible(true);
    } // END METHOD

    /**
     * Creates Neuron Weight Matrix Frame
     */
    void createNeuronL2Frame() {
        // Initializes neuronFrame
        neuronL2Frame = new JFrame("Neuron Layer 2 Synapse Weight Matrix");
        neuronL2Frame.setPreferredSize(new Dimension(400, 400));
        // Creates drawing canvas
        neuronL2Canvas = new GLCanvas();
        // Adds listeners to canvas so that it will be updated as needed
        neuronL2Canvas.addGLEventListener(new GLEventListener() {
            // Called by the drawable immediately after the OpenGL context is initialized
            @Override
            public void init(GLAutoDrawable drawable) {
            
            }

            // Called by the drawable to initiate OpenGL rendering by the client
            // Used to draw and update canvas
            @Override
            synchronized public void display(GLAutoDrawable drawable) {
                if (synapseWeightsL2 == null) 
                    return;

                constructSynapseWeightMapL2();
                
                // Prepare drawing canvas
                int neuronPadding = 5;
                int xPixelsPerNeuron = xPixels + neuronPadding;
                int yPixelsPerNeuron = yPixels * numPolarities + neuronPadding;
                int neuronsPerRow = (int) Math.sqrt((double) neuronsL2); 
                int neuronsPerColumn = (int) Math.ceil((double)neuronsL2 / neuronsPerRow);
                int pixelsPerRow = xPixelsPerNeuron * neuronsPerRow - neuronPadding;
                int pixelsPerColumn = yPixelsPerNeuron * neuronsPerColumn - neuronPadding;
                
                // Draw in canvas
                GL gl = drawable.getGL();
                // Creates and scales drawing matrix so that each integer unit represents any given pixel
                gl.glLoadIdentity();
                gl.glScalef(drawable.getWidth() / (float) pixelsPerRow, 
                        drawable.getHeight() / (float) pixelsPerColumn, 1);
                // Sets the background color for when glClear is called
                gl.glClearColor(0, 0, 0, 0);
                gl.glClear(GL.GL_COLOR_BUFFER_BIT);
                
                int xOffset = 0;
                int yOffset = 0;

                // Draw all Neurons
                // Draw weight matrix
                for (int n=0; n<neuronsL2; n++) {
                    for (int x=0; x<xPixels; x++) {
                        for (int y=0; y<yPixels; y++) {
                            // Handle Polarity cases independently, not through a for loop
                            //float wOFF = (synapseWeightMapL2[n][0][x][y] - wMin) / (float) (wMax - wMin);
                            //float wON = (synapseWeightMapL2[n][1][x][y] - wMin) / (float) (wMax - wMin);
                            float wOFF = (synapseWeightMapL2[n][0][x][y]- wMin) / (float) (wMax - wMin);
                            float wON = (synapseWeightMapL2[n][1][x][y] - wMin) / (float) (wMax - wMin);
                            if (displayCombinedPolarity == true) {
                                gl.glColor3f(wON, 0, wOFF);
                                gl.glRectf(xOffset+x, yOffset+y+yPixels, 
                                        xOffset+x + 1, yOffset+y+yPixels + 1);
                            } else if (displayCombinedPolarity == false) {
                                gl.glColor3f(wOFF, wOFF, 0);
                                gl.glRectf(xOffset+x, yOffset+y, 
                                        xOffset+x + 1, yOffset+y + 1);
                                gl.glColor3f(0, wON, wON);
                                gl.glRectf(xOffset+x, yOffset+y + yPixels, 
                                        xOffset+x + 1, yOffset+y + yPixels + 1);
                            } // END IF - Display Polarity
                        } // END LOOP - Y
                    } // END LOOP - X

                    // Display Neuron Statistics - Mean, STD, Min, Max
//                    if (displayNeuronStatistics == true) {
//                        final int font = GLUT.BITMAP_HELVETICA_12;
//                        GLUT glut = chip.getCanvas().getGlut();
//                        gl.glColor3f(1, 1, 1);
                        // Neuron info
//                        gl.glRasterPos3f(xOffset, yOffset, 0);
//                        glut.glutBitmapString(font, String.format("M %.2f", getNeuronMeanWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+4, 0);
                        //glut.glutBitmapString(font, String.format("S %.2f", getNeuronSTDWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+8, 0);
                        //glut.glutBitmapString(font, String.format("- %.2f", getNeuronMinWeight(n)));
                        //gl.glRasterPos3f(xOffset, yOffset+12, 0);
                        //glut.glutBitmapString(font, String.format("+ %.2f", getNeuronMaxWeight(n)));
//                    } // END IF 

                    // Draw Box around firing neuron with color corresponding to 
                    // Neuron Firing Rate in given Packet
//                    if (neuronFireHistogram == true) {
//                        float color = neuronFire[n]/(float)numNeuronFire;
//                        gl.glPushMatrix();
//                        gl.glLineWidth(1f);
//                        gl.glBegin(GL.GL_LINE_LOOP);
//                        gl.glColor3f(color,color,color);
//                        gl.glVertex2f(xOffset,yOffset);
//                        gl.glVertex2f(xOffset,yOffset+yPixels*2);
//                        gl.glVertex2f(xOffset+xPixels,yOffset+yPixels*2);
//                        gl.glVertex2f(xOffset,yOffset+yPixels*2);
//                        gl.glEnd();
//                        gl.glPopMatrix();
//                    } // END IF

                    // Adjust x and y Offsets
                    xOffset += xPixelsPerNeuron; 
                    if (n%neuronsPerRow == neuronsPerRow-1) {
                        xOffset = 0;
                        yOffset += yPixelsPerNeuron;
                    } // END IF
                } // END LOOP - Neuron
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
        neuronL2Frame.getContentPane().add(neuronL2Canvas);
        // Causes window to be sized to fit the preferred size and layout of its subcomponents
        neuronL2Frame.pack();
        neuronL2Frame.setVisible(true);
    } // END METHOD

    /**
     * Called when filter is turned off 
     * makes sure neuronFrame gets turned off
     */    
    @Override
    public synchronized void cleanup() {
        if(neuronL1Frame!=null) 
            neuronL1Frame.dispose();
        if(neuronL2Frame!=null) 
            neuronL2Frame.dispose();
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
    
    /** 
     * Annotation or drawing method
     * @param drawable OpenGL Rendering Object
     */
    @Override
    public void annotate (GLAutoDrawable drawable) {
        super.annotate(drawable);

        if (!isAnnotationEnabled()) 
            return;
        GL gl = drawable.getGL();
        if (gl == null) 
            return;

        final int font = GLUT.BITMAP_HELVETICA_18;
        GLUT glut = chip.getCanvas().getGlut();
//        if (adaptiveFireThres == true) {
//            gl.glColor3f(1f, 1f, 1f);
//            for (int c=0; c<numClusters; c++) {
//                gl.glRasterPos3f(0, c*5, 0);
//                glut.glutBitmapString(font, String.format("Fire Threshold: %5.0f", fireThres[c]));
//            }
//        }

        // Draw Box around relevant pixels with label of cluster number
        for (int c=0; c<numClusters; c++) {
            //if (clusterActive[c] == true) {
                // Box
                gl.glPushMatrix();
                gl.glLineWidth(1f);
                gl.glBegin(GL.GL_LINE_LOOP);
                gl.glColor3f(1f,1f,1f);
                gl.glVertex2f(xStart[c]-1,yStart[c]-1);
                gl.glVertex2f(xStart[c]+xPixels,yStart[c]-1);
                gl.glVertex2f(xStart[c]+xPixels,yStart[c]+yPixels);
                gl.glVertex2f(xStart[c]-1,yStart[c]+yPixels);
                gl.glEnd();
                gl.glPopMatrix();
                // Label
                gl.glColor3f(1f, 1f, 1f);
                gl.glRasterPos3f(xStart[c], yStart[c], 0);
                glut.glutBitmapString(font, String.format("%d", c));
            //}
        }
    } // END METHOD

    /**
     * Called when objects being observed change and send a message
     * Re initialize filter if camera pixel size has changed
     * @param o Object that has changed
     * @param arg Message object has sent about change
     */    
    @Override
    public void update(Observable o, Object arg) {
        super.update(o, arg);
        if (arg != null && (arg == AEChip.EVENT_SIZEX || arg == AEChip.EVENT_SIZEY)) 
            initFilter();
    } // END METHOD
    
    /** 
     * Overrides setMaxNumClusters to make sure that all variables and arrays are reallocated
     * @param maxNumClusters Maximum number of visible clusters 
     */
    @Override
    public void setMaxNumClusters(final int maxNumClusters) {
        super.setMaxNumClusters(maxNumClusters);
        // Set numCluster and all its variable
        initFilter();
    }

    /**
     * Returns Mean of Neuron's weights
     * @param neuron Current neuron
     * @return mean
     */
    public float getNeuronMeanWeight(int neuron) {
        float mean = 0;
        for (int p=0; p<numPolarities; p++)
            for (int x=0; x<xPixels; x++)
                for (int y=0; y<yPixels; y++)
                    mean += synapseWeightsL1[neuron][p][x][y];
        return mean/(numPolarities*xPixels*yPixels);
    } // END METHOD
                    
    /**
     * Returns Standard Deviation of Neuron's weights
     * @param group Current group
     * @param neuron Current neuron
     * @return standard deviation
     */
    public float getNeuronSTDWeight(int neuron) {
        float mean = getNeuronMeanWeight(neuron);
        float var = 0;
        for (int p=0; p<numPolarities; p++)
            for (int x=0; x<xPixels; x++)
                for (int y=0; y<yPixels; y++)
                    var += (mean-synapseWeightsL1[neuron][p][x][y])*(mean-synapseWeightsL1[neuron][p][x][y]);
        double std = Math.sqrt(var/(double)(numPolarities*xPixels*yPixels));
        return (float) std;
    } // END METHOD
                    
    /**
     * Returns Minimum of Neuron's weights
     * @param group Current group
     * @param neuron Current neuron
     * @return minimum
     */
    public float getNeuronMinWeight(int neuron) {
        float min = synapseWeightsL1[neuron][0][0][0];
        for (int p=0; p<numPolarities; p++)
            for (int x=0; x<xPixels; x++)
                for (int y=0; y<yPixels; y++)
                    if (min > synapseWeightsL1[neuron][p][x][y]) 
                        min = synapseWeightsL1[neuron][p][x][y];
        return min;
    } // END METHOD
                    
    /**
     * Returns Maximum of Neuron's weights
     * @param group Current group
     * @param neuron Current neuron
     * @return maximum
     */
    public float getNeuronMaxWeight(int neuron) {
        float max = synapseWeightsL1[neuron][0][0][0];
        for (int p=0; p<numPolarities; p++)
            for (int x=0; x<xPixels; x++)
                for (int y=0; y<yPixels; y++)
                    if (max < synapseWeightsL1[neuron][p][x][y]) 
                        max = synapseWeightsL1[neuron][p][x][y];
        return max;
    }
                    
    public int getNeuronsL1() {
        return this.neuronsL1;
    }
    public void setNeuronsL1(final int neuronsL1) {
        getPrefs().putInt("StdpFeatureLearningV.neuronsL1", neuronsL1);
        getSupport().firePropertyChange("neuronsL1", this.neuronsL1, neuronsL1);
        this.neuronsL1 = neuronsL1;
        initFilter();
    }
    public int getNeuronsL1Min() {
        return 1;
    }
    public int getNeuronsL1Max() {
        return 1000;
    }
    // END neurons
    
    public int getNeuronsL2() {
        return this.neuronsL2;
    }
    public void setNeuronsL2(final int neuronsL2) {
        getPrefs().putInt("StdpFeatureLearningV.neuronsL2", neuronsL2);
        getSupport().firePropertyChange("neuronsL2", this.neuronsL2, neuronsL2);
        this.neuronsL2 = neuronsL2;
        initFilter();
    }
    public int getNeuronsL2Min() {
        return 1;
    }
    public int getNeuronsL2Max() {
        return 1000;
    }
    // END neuronsL2
    
    public int getBaseFireThres() {
        return this.baseFireThres;
    }
    public void setBaseFireThres(final int baseFireThres) {
        getPrefs().putInt("StdpFeatureLearningV.baseFireThres", baseFireThres);
        getSupport().firePropertyChange("baseFireThres", this.baseFireThres, baseFireThres);
        this.baseFireThres = baseFireThres;
    }
    public int getBaseFireThresMin() {
        return 1;
    }
    public int getBaseFireThresMax() {
        return 100000;
    }
    // END baseFireThres

    public int getMinFireThres() {
        return this.minFireThres;
    }
    public void setMinFireThres(final int minFireThres) {
        getPrefs().putInt("StdpFeatureLearningV.minFireThres", minFireThres);
        getSupport().firePropertyChange("minFireThres", this.minFireThres, minFireThres);
        this.minFireThres = minFireThres;
    }
    public int getMinFireThresMin() {
        return 1;
    }
    public int getMinFireThresMax() {
        return 100000;
    }
    // END minFireThres

    public int getMaxFireThres() {
        return this.maxFireThres;
    }
    public void setMaxFireThres(final int maxFireThres) {
        getPrefs().putInt("StdpFeatureLearningV.maxFireThres", maxFireThres);
        getSupport().firePropertyChange("maxFireThres", this.maxFireThres, maxFireThres);
        this.maxFireThres = maxFireThres;
    }
    public int getMaxFireThresMin() {
        return 1;
    }
    public int getMaxFireThresMax() {
        return 100000;
    }
    // END maxFireThres

    public int getTLTP() {
        return this.tLTP;
    }
    public void setTLTP(final int tLTP) {
        getPrefs().putInt("StdpFeatureLearningV.tLTP", tLTP);
        getSupport().firePropertyChange("tLTP", this.tLTP, tLTP);
        this.tLTP = tLTP;
    }
    public int getTLTPMin() {
        return 1;
    }
    public int getTLTPMax() {
        return 100000;
    }
    // END tLTP
    
    public int getTRefrac() {
        return this.tRefrac;
    }
    public void setTRefrac(final int tRefrac) {
        getPrefs().putInt("StdpFeatureLearningV.tRefrac", tRefrac);
        getSupport().firePropertyChange("tRefrac", this.tRefrac, tRefrac);
        this.tRefrac = tRefrac;
    }
    public int getTRefracMin() {
        return 1;
    }
    public int getTRefracMax() {
        return 100000;
    }
    // END tRefrac
    
    public int getTInhibit() {
        return this.tInhibit;
    }
    public void setTInhibit(final int tInhibit) {
        getPrefs().putInt("StdpFeatureLearningV.tInhibit", tInhibit);
        getSupport().firePropertyChange("tInhibit", this.tInhibit, tInhibit);
        this.tInhibit = tInhibit;
    }
    public int getTInhibitMin() {
        return 1;
    }
    public int getTInhibitMax() {
        return 100000;
    }
    // END tRefrac

    public int getTauLeak() {
        return this.tauLeak;
    }
    public void setTauLeak(final int tauLeak) {
        getPrefs().putInt("StdpFeatureLearningV.tauLeak", tauLeak);
        getSupport().firePropertyChange("tauLeak", this.tauLeak, tauLeak);
        this.tauLeak = tauLeak;
    }
    public int getTauLeakMin() {
        return 1;
    }
    public int getTauLeakMax() {
        return 100000;
    }
    // END tauLeak
    
    public int getWMin() {
        return this.wMin;
    }
    public void setWMin(final int wMin) {
        getPrefs().putInt("StdpFeatureLearningV.wMin", wMin);
        getSupport().firePropertyChange("wMin", this.wMin, wMin);
        this.wMin = wMin;
    }
    public int getWMinMin() {
        return 1;
    }
    public int getWMinMax() {
        return 10000;
    }
    // END wMin
    
    public int getWMax() {
        return this.wMax;
    }
    public void setWMax(final int wMax) {
        getPrefs().putInt("StdpFeatureLearningV.wMax", wMax);
        getSupport().firePropertyChange("wMax", this.wMax, wMax);
        this.wMax = wMax;
    }
    public int getWMaxMin() {
        return 1;
    }
    public int getWMaxMax() {
        return 10000;
    }
    // END wMax

    public int getWInitMean() {
        return this.wInitMean;
    }
    public void setWInitMean(final int wInitMean) {
        getPrefs().putInt("StdpFeatureLearningV.wInitMean", wInitMean);
        getSupport().firePropertyChange("wInitMean", this.wInitMean, wInitMean);
        this.wInitMean = wInitMean;
    }
    public int getWInitMeanMin() {
        return 1;
    }
    public int getWInitMeanMax() {
        return 10000;
    }
    // END wInitMean
    
    public int getWInitSTD() {
        return this.wInitSTD;
    }
    public void setWInitSTD(final int wInitSTD) {
        getPrefs().putInt("StdpFeatureLearningV.wInitSTD", wInitSTD);
        getSupport().firePropertyChange("wInitSTD", this.wInitSTD, wInitSTD);
        this.wInitSTD = wInitSTD;
    }
    public int getWInitSTDMin() {
        return 1;
    }
    public int getWInitSTDMax() {
        return 10000;
    }
    // END wInitSTD

    public int getAlphaPlus() {
        return this.alphaPlus;
    }
    public void setAlphaPlus(final int alphaPlus) {
        getPrefs().putInt("StdpFeatureLearningV.alphaPlus", alphaPlus);
        getSupport().firePropertyChange("alphaPlus", this.alphaPlus, alphaPlus);
        this.alphaPlus = alphaPlus;
    }
    public int getAlphaPlusMin() {
        return 0;
    }
    public int getAlphaPlusMax() {
        return 1000;
    }
    // END alphaPlus

    public int getAlphaMinus() {
        return this.alphaMinus;
    }
    public void setAlphaMinus(final int alphaMinus) {
        getPrefs().putInt("StdpFeatureLearningV.alphaMinus", alphaMinus);
        getSupport().firePropertyChange("alphaMinus", this.alphaMinus, alphaMinus);
        this.alphaMinus = alphaMinus;
    }
    public int getAlphaMinusMin() {
        return 0;
    }
    public int getAlphaMinusMax() {
        return 1000;
    }
    // END alphaMinus

    public int getBetaPlus() {
        return this.betaPlus;
    }
    public void setBetaPlus(final int betaPlus) {
        getPrefs().putInt("StdpFeatureLearningV.betaPlus", betaPlus);
        getSupport().firePropertyChange("betaPlus", this.betaPlus, betaPlus);
        this.betaPlus = betaPlus;
    }
    public int getBetaPlusMin() {
        return 0;
    }
    public int getBetaPlusMax() {
        return 1000;
    }
    // END betaPlus

    public int getBetaMinus() {
        return this.betaMinus;
    }
    public void setBetaMinus(final int betaMinus) {
        getPrefs().putInt("StdpFeatureLearningV.betaMinus", betaMinus);
        getSupport().firePropertyChange("betaMinus", this.betaMinus, betaMinus);
        this.betaMinus = betaMinus;
    }
    public int getBetaMinusMin() {
        return 0;
    }
    public int getBetaMinusMax() {
        return 1000;
    }
    // END betaMinus
    
    public boolean isKeepWeightsOnRewind() {
        return keepWeightsOnRewind;
    }
    synchronized public void setKeepWeightsOnRewind(boolean keepWeightsOnRewind) {
        this.keepWeightsOnRewind = keepWeightsOnRewind;
    }
    // END keepWeightsOnRewind

    public boolean isDisplayNeuronStatistics() {
        return displayNeuronStatistics;
    }
    synchronized public void setDisplayNeuronStatistics(boolean displayNeuronStatistics) {
        this.displayNeuronStatistics = displayNeuronStatistics;
    }
    // END displayNeuronStatistics

    public boolean isFireMaxOnlyOnceOnSpike() {
        return fireMaxOnlyOnceOnSpike;
    }
    synchronized public void setFireMaxOnlyOnceOnSpike(boolean fireMaxOnlyOnceOnSpike) {
        this.fireMaxOnlyOnceOnSpike = fireMaxOnlyOnceOnSpike;
    }
    // END fireMaxOnlyOnceOnSpike

    public boolean isDisplayCombinedPolarity() {
        return displayCombinedPolarity;
    }
    synchronized public void setDisplayCombinedPolarity(boolean displayCombinedPolarity) {
        this.displayCombinedPolarity = displayCombinedPolarity;
    }
    // END displayCombinedPolarity

} 









