//****************************************************************************//
//-- Packages ----------------------------------------------------------------//
//----------------------------------------------------------------------------//
package eu.visualize.ini.retinamodel;

import eu.seebetter.ini.chips.davis.HotPixelFilter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.Observer;
import java.util.Random;
import java.util.*;

import javax.media.opengl.GL2;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.glu.GLU;

import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.ApsDvsEventPacket;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.filter.LowpassFilter;
import net.sf.jaer.eventprocessing.filter.EventRateEstimator;
import net.sf.jaer.eventprocessing.filter.BackgroundActivityFilter;

//-- end packages ------------------------------------------------------------//
//****************************************************************************//
//****************************************************************************//
//-- Description -------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Models multiple object motion cells that are excited by on or off activity
// within their classical receptive field but are inhibited by synchronous on or
// off activity in their extended RF, such as that caused by a saccadic eye
// movement. Also gives direction of movement of object
// @author diederik
//-- end description ---------------------------------------------------------//
//****************************************************************************//
@Description("Models object motion cells known from mouse and salamander retina")
//@DevelopmentStatus(DevelopmentStatus.Status.Experimental)

//****************************************************************************//
//-- Main class OMCOD --------------------------------------------------------//
//----------------------------------------------------------------------------//
public class OMCOD extends AbstractRetinaModelCell implements FrameAnnotater, Observer {

    private final OMCODModel OMCODModel = new OMCODModel();
    public RosNodePublisher RosNodePublisher = new RosNodePublisher();
    //private final LowpassFilter medianCMFilter = new LowpassFilter(1);
    private EventRateEstimator eventRateFilter;
    private BackgroundActivityFilter backgroundActivityFilter;
    private HotPixelFilter hotPixelFilter;
    private Subunits subunits;
    private int nxmax;
    private int nymax;
    private float IFthreshold;
    private boolean enableSpikeDraw;
    private int counter = 0;
    private int lastIndex = 0;
    private int counter1 = 0;
    private int lastIndex1 = 0;
    private int counter2 = 0;
    private int lastIndex2 = 0;
    private boolean rememberReset1 = false;
    private boolean rememberReset2 = false;
    private int probabilityOfCorrectness = 5;
    private int timeStampRosUs;
    private float[][] inhibitionArray;
    private float[][] excitationArray;
    private float[][] membraneStateArray;
    private float[][] netSynapticInputArray;
    private int[][] timeStampArray;
    private int[][] lastTimeStampArray;
    private int[][] dtUSarray;
    private int[][] timeStampSpikeArray;
    private int[][] lastTimeStampSpikeArray;
    private int[][] dtUSspikeArray;
    private int[][] nSpikesArray; // counts spikes since last rendering cycle
    private int[][] lastSpikedOMCTracker1; // save the OMC cells that last spiked
    private int[][] lastSpikedOMCTracker2; // save the OMC cells that last spiked
    private int[] lastSpikedOMC; // save the OMC cell that last spiked
    private int[][] lastSpikedOMCArray; // save the OMC cells that last spiked
    private String direction = "Thinking";
//------------------------------------------------------------------------------    
    private float synapticWeight = getFloat("synapticWeight", 100f);
    private float vmemIncrease = getFloat("vmemIncrease", 100f);
    private float centerExcitationToSurroundInhibitionRatio = getFloat("centerExcitationToSurroundInhibitionRatio", 1f);
    private boolean surroundSuppressionEnabled = getBoolean("surroundSuppressionEnabled", false);
    private float subunitActivityBlobRadiusScale = getFloat("subunitActivityBlobRadiusScale", 0.022f);
    private float integrateAndFireThreshold = getFloat("integrateAndFireThreshold", 70f);
    private float increaseInThreshold = getFloat("increaseInThreshold", 10f);
    private float nonLinearityOrder = getFloat("nonLinearityOrder", 2f);
    private boolean startLogging = getBoolean("startLogging", false);
    private boolean deleteLogging = getBoolean("deleteLogging", false);
    private float barsHeight = getFloat("barsHeight", 10f);
    private int excludedEdgeSubunits = getInt("excludedEdgeSubunits", 0);
    private int showXcoord = getInt("showXcoord", 1);
    private int showYcoord = getInt("showYcoord", 1);
    private int Saturation = getInt("Saturation", 100);
    private boolean exponentialToTanh = getBoolean("exponentialToTanh", false);
    private boolean showQuadrants = getBoolean("showQuadrants", true);
    private boolean showTracker2 = getBoolean("showTracker2", false);
    private boolean showTracker1 = getBoolean("showTracker1", true);
    private boolean showTrackerCellsOnly = getBoolean("showTrackerCellsOnly", true);
    private int clusterSize = getInt("clusterSize", 4);
    private float focalLengthM = getFloat("focalLengthM", 0.001f);
    private float objectRealWidthXM = getFloat("objectRealWidthXM", 0.5f);
    private float eventRateTauMs = getFloat("eventRateTauMs", 100f);
    private float dtBackgroundUs = getFloat("dtBackgroundUs", 100000f);
    private int neuronDecayTimeconstantMs = getInt("neuronDecayTimeconstantMs", 100);
    private int operationRange = getInt("operationRange", 4);
    private int updateRosEveryUs = getInt("updateRosEveryUs", 100);
//------------------------------------------------------------------------------

//----------------------------------------------------------------------------//
//-- Initialise and ToolTip method -------------------------------------------//
//----------------------------------------------------------------------------//
    public OMCOD(AEChip chip) {
        super(chip);
        this.enableSpikeDraw = false;
        this.nxmax = chip.getSizeX() >> getSubunitSubsamplingBits();
        this.nymax = chip.getSizeY() >> getSubunitSubsamplingBits();
        this.nSpikesArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()]; // deleted -1 in all
        this.netSynapticInputArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.membraneStateArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.inhibitionArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.excitationArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.timeStampArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastTimeStampArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.dtUSarray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.timeStampSpikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastTimeStampSpikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.dtUSspikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastSpikedOMCTracker1 = new int[2][getClusterSize()];
        this.lastSpikedOMCTracker2 = new int[2][getClusterSize()];
        this.lastSpikedOMCArray = new int[2][getClusterSize()];

        eventRateFilter = new EventRateEstimator(chip);
        eventRateFilter.setEventRateTauMs(eventRateTauMs);

        backgroundActivityFilter = new BackgroundActivityFilter(chip);
        backgroundActivityFilter.setDt((int) dtBackgroundUs);
        backgroundActivityFilter.setSubsampleBy(0);
        hotPixelFilter = new HotPixelFilter(chip);

        chip.addObserver(this);
        final String use = "1) Key Parameters", fix = "2) Fixed Parameters", disp = "3) Display", log = "4) Logging";
//------------------------------------------------------------------------------
        setPropertyTooltip(disp, "showSubunits", "Enables showing subunit activity "
                + "annotation over retina output");
        setPropertyTooltip(disp, "showOutputCell", "Enables showing object motion cell "
                + "activity annotation over retina output");
        setPropertyTooltip(fix, "subunitSubsamplingBits", "Each subunit integrates "
                + "events from 2^n by 2^n pixels, where n=subunitSubsamplingBits");
        setPropertyTooltip(fix, "synapticWeight", "Subunit activity inputs to the "
                + "objectMotion neuron are weighted this much; use to adjust "
                + "response magnitude");
        setPropertyTooltip(fix, "vmemIncrease", "Increase in vmem per event received");
        setPropertyTooltip(use, "subunitDecayTimeconstantMs", "Subunit activity "
                + "decays with this time constant in ms");
        setPropertyTooltip(use, "neuronDecayTimeconstantMs", "decay Tau of IF neuron");
        setPropertyTooltip(disp, "enableSpikeSound", "Enables audio spike output from "
                + "objectMotion cell");
        setPropertyTooltip(fix, "maxSpikeRateHz", "Maximum spike rate of objectMotion "
                + "cell in Hz");
        setPropertyTooltip(fix, "centerExcitationToSurroundInhibitionRatio",
                "Inhibitory ON subunits are weighted by factor more than "
                + "excitatory OFF subunit activity to the object motion "
                + "cell");
        setPropertyTooltip(fix, "minUpdateIntervalUs", "subunits activities are "
                + "decayed to zero at least this often in us, even if they "
                + "receive no input");
        setPropertyTooltip(fix, "surroundSuppressionEnabled", "subunits are "
                + "suppressed by surrounding activity of same type; reduces "
                + "response to global dimming");
        setPropertyTooltip(disp, "subunitActivityBlobRadiusScale", "The blobs "
                + "represeting subunit activation are scaled by this factor");
        setPropertyTooltip(use, "integrateAndFireThreshold", "The ganglion cell will "
                + "fire if the difference between excitation and inhibition "
                + "overcomes this threshold");
        setPropertyTooltip(use, "increaseInThreshold", "increase in threshold of "
                + "OMC neuron depending on activity");
        setPropertyTooltip(fix, "poissonFiringEnabled", "The ganglion cell fires "
                + "according to Poisson rate model for net synaptic input");
        setPropertyTooltip(fix, "nonLinearityOrder", "The non-linear order of the "
                + "subunits' value before the total sum");
        setPropertyTooltip(log, "startLogging", "Start logging inhibition and "
                + "excitation");
        setPropertyTooltip(log, "deleteLogging", "Delete the logging of inhibition "
                + "and excitation");
        setPropertyTooltip(disp, "barsHeight", "set the magnitute of cen and sur if "
                + "the inhibition and excitation are out of range");
        setPropertyTooltip(fix, "excludedEdgeSubunits", "Set the number of subunits "
                + "excluded from computation at the edge");
        setPropertyTooltip(fix, "Saturation", "Set the maximum contribution of "
                + "a single subunit, where it saturates");
        setPropertyTooltip(use, "exponentialToTanh", "Switch from exponential "
                + "non-linearity to exponential tangent");
        setPropertyTooltip(disp, "showXcoord", "decide which Object Motion Cell to "
                + "show by selecting the X coordinate of the center");
        setPropertyTooltip(disp, "showYcoord", "decide which Object Motion Cell to "
                + "show by selecting the Y coordinate of the center");
        setPropertyTooltip(fix, "clusterSize", "decide how many Object Motion Cells' "
                + "outputs to integrate to get an envelope of the prey");
        setPropertyTooltip(disp, "showQuadrants", "show the quadrants of motion");
        setPropertyTooltip(disp, "showTrackerCellsOnly", "show only cells in tracker 1");
        setPropertyTooltip(disp, "showTracker1", "show tracker 1");
        setPropertyTooltip(disp, "showTracker2", "show tracker 2");
        setPropertyTooltip(fix, "objectRealWidthXM", "Object's to be followed real "
                + "width in meters");
        setPropertyTooltip(fix, "focalLengthM", "Lenses' focal length in meters");
        setPropertyTooltip(fix, "eventRateTauMs", "Tau of lowpass of event rate");
        setPropertyTooltip(use, "dtBackgroundUs", "Tau of Background activity filter");
        setPropertyTooltip(use, "operationRange", "Spatial correlation distance");
        setPropertyTooltip(use, "updateRosEveryUs", "Update ROS every set us");
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

    private int lastOMCODSpikeCheckTimestampUs = 0;

//----------------------------------------------------------------------------//
//-- Filter packet method ----------------------------------------------------//
//----------------------------------------------------------------------------//
    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        if (!(in.getEventPrototype() instanceof PolarityEvent)) {
            return eventRateFilter.filterPacket(backgroundActivityFilter.filterPacket(hotPixelFilter.filterPacket(in)));
        }
        if (in instanceof ApsDvsEventPacket) {
            checkOutputPacketEventType(eventRateFilter.filterPacket(backgroundActivityFilter.filterPacket(hotPixelFilter.filterPacket(in)))); // make sure memory is allocated to avoid leak. 
            // we don't use output packet but it is necesary to iterate over DVS events only
        }
        clearOutputPacket();
        if (subunits == null) {
            resetFilter();
        }
        for (Object o : hotPixelFilter.filterPacket(in)) {
            PolarityEvent e = (PolarityEvent) o;
            if (e.special) {
                continue;
            }
            subunits.update(e);
            int dt = e.timestamp - lastOMCODSpikeCheckTimestampUs;
            if (dt < 0) {
                lastOMCODSpikeCheckTimestampUs = e.timestamp;
                return in;
            }
            if (dt > minUpdateIntervalUs) {
                lastOMCODSpikeCheckTimestampUs = e.timestamp;
                OMCODModel.update(e.timestamp);
            }
        }

        return in;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Drawing method ----------------------------------------------------------//
//----------------------------------------------------------------------------//
    @Override
    public void annotate(GLAutoDrawable drawable) {
        super.annotate(drawable);
        GL2 gl = drawable.getGL().getGL2();
        gl.glPushMatrix();
        if ((getShowXcoord() < getExcludedEdgeSubunits()) || (getShowYcoord() < getExcludedEdgeSubunits())
                || (getShowXcoord() > nxmax - 1 - getExcludedEdgeSubunits()) || (getShowYcoord() > nymax - 1 - getExcludedEdgeSubunits())) {
            setShowXcoord(excludedEdgeSubunits);
            setShowYcoord(excludedEdgeSubunits);
        }
        if (showOutputCell == false && (nSpikesArray[getShowXcoord()][getShowYcoord()] != 0)) { // Show single output
            gl.glPushMatrix();
            gl.glTranslatef((getShowXcoord() + 1) << getSubunitSubsamplingBits(), (getShowYcoord() + 1) << getSubunitSubsamplingBits(), 5);
            gl.glColor4f(1, 1, 1, .2f);
            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
            float radius = (chip.getMaxSize() * OMCODModel.spikeRateHz) / maxSpikeRateHz / 2;
            glu.gluDisk(quad, 0, radius, 32, 1);
            OMCODModel.resetSpikeCount();
            gl.glPopMatrix();
        }
        if (showOutputCell) { // Dispaly pink outputs
            if (enableSpikeDraw && nSpikesArray[lastSpikedOMC[0]][lastSpikedOMC[1]] != 0) {
                if (counter < getClusterSize() - 1) {
                    counter++;
                } else {
                    counter = 0;
                }
                if (counter == 0) {
                    lastIndex = getClusterSize() - 1;
                } else {
                    lastIndex = counter - 1;
                }
                //Store all spiked cells
                for (int i = 0; i < 2; i++) {
                    if (i == 0) {
                        lastSpikedOMCArray[i][counter] = lastSpikedOMC[0];
                    } else {
                        lastSpikedOMCArray[i][counter] = lastSpikedOMC[1];
                    }
                }

                //Tracker 1
                if (rememberReset1) { // Start anywhere after reset
                    for (int j = 0; j < getClusterSize(); j++) {
                        for (int i = 0; i < 2; i++) {
                            if (i == 0) {
                                lastSpikedOMCTracker1[i][j] = lastSpikedOMC[0];
                            } else {
                                lastSpikedOMCTracker1[i][j] = lastSpikedOMC[1];
                            }
                        }
                    }
                    rememberReset1 = false;
                }

                if ((Math.abs((lastSpikedOMC[0] - lastSpikedOMCTracker1[0][lastIndex])) < getOperationRange())
                        && (Math.abs((lastSpikedOMC[1] - lastSpikedOMCTracker1[1][lastIndex])) < getOperationRange())
                        ||// Spatial correlation with last spike
                        //spatial correlation with corners
                        ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[0])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[2])) < getOperationRange()) || (Math.abs((lastSpikedOMC[1] - findClusterCorners()[3])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[1])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[2])) < getOperationRange()) || (Math.abs((lastSpikedOMC[1] - findClusterCorners()[3])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[2])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[0])) < getOperationRange()) || (Math.abs((lastSpikedOMC[0] - findClusterCorners()[1])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[3])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[0])) < getOperationRange()) || (Math.abs((lastSpikedOMC[0] - findClusterCorners()[1])) < getOperationRange())))) {
                    if (counter1 < getClusterSize() - 1) {
                        counter1++;
                    } else {
                        counter1 = 0;
                    }
                    if (counter1 == 0) {
                        lastIndex1 = getClusterSize() - 1;
                    } else {
                        lastIndex1 = counter1 - 1;
                    }
                    for (int i = 0; i < 2; i++) {
                        if (i == 0) {
                            lastSpikedOMCTracker1[i][counter1] = lastSpikedOMC[0];
                        } else {
                            lastSpikedOMCTracker1[i][counter1] = lastSpikedOMC[1];
                        }
                    }
                    probabilityOfCorrectness = 5;
                } else { // If outside operation range, reevaluate decision
                    //Probability count
                    probabilityOfCorrectness = probabilityOfCorrectness - 1;

                    if (probabilityOfCorrectness == 0) {
                        resetTracker1();
                        probabilityOfCorrectness = 5;
                    }

                }

                //Tracker 2
                if (rememberReset2) { // Start anywhere after reset
                    for (int j = 0; j < getClusterSize(); j++) {
                        for (int i = 0; i < 2; i++) {
                            if (i == 0) {
                                lastSpikedOMCTracker2[i][j] = lastSpikedOMC[0];
                            } else {
                                lastSpikedOMCTracker2[i][j] = lastSpikedOMC[1];
                            }
                        }
                    }
                    rememberReset2 = false;
                }

                if ((Math.abs((lastSpikedOMC[0] - lastSpikedOMCTracker2[0][lastIndex])) < getOperationRange())
                        && (Math.abs((lastSpikedOMC[1] - lastSpikedOMCTracker2[1][lastIndex])) < getOperationRange())
                        ||// Spatial correlation with last spike
                        //spatial correlation with corners
                        ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[4])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[6])) < getOperationRange()) || (Math.abs((lastSpikedOMC[1] - findClusterCorners()[7])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[5])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[6])) < getOperationRange()) || (Math.abs((lastSpikedOMC[1] - findClusterCorners()[7])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[6])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[4])) < getOperationRange()) || (Math.abs((lastSpikedOMC[0] - findClusterCorners()[5])) < getOperationRange())))
                        || ((Math.abs((lastSpikedOMC[1] - findClusterCorners()[7])) < getOperationRange())
                        && ((Math.abs((lastSpikedOMC[0] - findClusterCorners()[4])) < getOperationRange()) || (Math.abs((lastSpikedOMC[0] - findClusterCorners()[5])) < getOperationRange())))) {
                    if (counter2 < getClusterSize() - 1) {
                        counter2++;
                    } else {
                        counter2 = 0;
                    }
                    if (counter2 == 0) {
                        lastIndex2 = getClusterSize() - 1;
                    } else {
                        lastIndex2 = counter2 - 1;
                    }
                    for (int i = 0; i < 2; i++) {
                        if (i == 0) {
                            lastSpikedOMCTracker2[i][counter2] = lastSpikedOMC[0];
                        } else {
                            lastSpikedOMCTracker2[i][counter2] = lastSpikedOMC[1];
                        }
                    }
                }

                // Render all outputs
                gl.glPushMatrix();
                //gl.glColor4f(12, 0, 1, .3f); // pink
                gl.glColor4f(1, 0, 0, 1f); // red
                if (!showTrackerCellsOnly) {
                    gl.glRectf((lastSpikedOMC[0] << getSubunitSubsamplingBits()),
                            (lastSpikedOMC[1] << getSubunitSubsamplingBits()),
                            (lastSpikedOMC[0] + 2 << getSubunitSubsamplingBits()),
                            (lastSpikedOMC[1] + 2 << getSubunitSubsamplingBits()));
                } else {
                    gl.glRectf((lastSpikedOMCTracker1[0][counter1] << getSubunitSubsamplingBits()),
                            (lastSpikedOMCTracker1[1][counter1] << getSubunitSubsamplingBits()),
                            (lastSpikedOMCTracker1[0][counter1] + 2 << getSubunitSubsamplingBits()),
                            (lastSpikedOMCTracker1[1][counter1] + 2 << getSubunitSubsamplingBits()));
                }
                gl.glPopMatrix();

                gl.glPushMatrix();
                renderer.begin3DRendering();
                renderer.setColor(12, 0, 1, .3f);
                renderer.draw3D("OMC( " + lastSpikedOMC[0] + " , " + lastSpikedOMC[1] + " )", -55, 60, 0, .4f);
                renderer.end3DRendering();
                enableSpikeDraw = false;
                gl.glPopMatrix();
            }
            OMCODModel.resetSpikeCount();
        }
        if (showTracker1) {
            // Reset tracker after a second of no OMC events 
            // (current timestamp - timestamp of last spiked OMC)
            if (lastOMCODSpikeCheckTimestampUs - lastTimeStampSpikeArray[lastSpikedOMC[0]][lastSpikedOMC[1]] > 5000000) {
                resetTracker1();
                resetTracker2();
            }
            // Reset tracker after a second of no OMC events in its neighbourhood 
            // (current timestamp - timestamp of last spiked OMC of tracker, spatially correlated then)
            if (lastOMCODSpikeCheckTimestampUs - lastTimeStampSpikeArray[lastSpikedOMCTracker1[0][counter1]][lastSpikedOMCTracker1[1][counter1]] > 5000000) {
                resetTracker1();
            }
            // Reset tracker after a second of no OMC events in its neighbourhood 
            // (current timestamp - timestamp of last spiked OMC of tracker, spatially correlated then)
            if (lastOMCODSpikeCheckTimestampUs - lastTimeStampSpikeArray[lastSpikedOMCTracker2[0][counter1]][lastSpikedOMCTracker2[1][counter1]] > 500000) {
                resetTracker2();
            }

            // Render tracker cluster 1
            gl.glPushMatrix();
            gl.glColor4f(184, 47, 243, .1f);
            gl.glRectf(findClusterCorners()[0] << getSubunitSubsamplingBits(), findClusterCorners()[2] << getSubunitSubsamplingBits(),
                    (findClusterCorners()[1] + 2) << getSubunitSubsamplingBits(), (findClusterCorners()[3] + 2) << getSubunitSubsamplingBits());
            gl.glPopMatrix();

            // Yellow contour 1
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 1.0f, 0.0f);
            gl.glBegin(GL2.GL_LINE_STRIP);
            gl.glVertex2f(findClusterCorners()[0] << getSubunitSubsamplingBits(), (findClusterCorners()[2]) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[1] + 2 << getSubunitSubsamplingBits(), (findClusterCorners()[2]) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[1] + 2 << getSubunitSubsamplingBits(), (findClusterCorners()[3] + 2) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[0] << getSubunitSubsamplingBits(), (findClusterCorners()[3] + 2) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[0] << getSubunitSubsamplingBits(), (findClusterCorners()[2]) << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();

            // Draw center of mass 1
            gl.glPushMatrix();
            gl.glTranslatef((findCenterOfMass(findClusterCorners())[0] + 1) << getSubunitSubsamplingBits(),
                    (findCenterOfMass(findClusterCorners())[1] + 1) << getSubunitSubsamplingBits(), 5);
            gl.glColor4f(0, 0, 1, .4f);
            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
            glu.gluDisk(quad, 0, 3, 32, 1);
            gl.glPopMatrix();

            // Draw median center of mass 
            gl.glPushMatrix();
            gl.glTranslatef((findMedianCenterOfMass(lastSpikedOMCArray)[0] + 1) << getSubunitSubsamplingBits(),
                    (findMedianCenterOfMass(lastSpikedOMCArray)[1] + 1) << getSubunitSubsamplingBits(), 5);
            gl.glColor4f(0, 1, 255, .3f);
            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
            glu.gluDisk(quad, 0, 3, 32, 1);
            gl.glPopMatrix();

            // Send data to RosNodePublisher (-90 to center for davis, -64 for DVS128)
            if (lastOMCODSpikeCheckTimestampUs - timeStampRosUs > getUpdateRosEveryUs()) {
                RosNodePublisher.setXcoordinate((findCenterOfMass(findClusterCorners())[0] << getSubunitSubsamplingBits()) - 90);
                RosNodePublisher.setYcoordinate((findCenterOfMass(findClusterCorners())[1] << getSubunitSubsamplingBits()) - 90);
                RosNodePublisher.setZcoordinate(distanceToTravel(((findClusterCorners()[1] + 2) << getSubunitSubsamplingBits())
                        - (findClusterCorners()[0] << getSubunitSubsamplingBits())));
                timeStampRosUs = lastOMCODSpikeCheckTimestampUs;
            }
        }

        if (showTracker2) {
            // Render tracker cluster 2
            gl.glPushMatrix();
            gl.glColor4f(184, 47, 243, .1f);
            gl.glRectf(findClusterCorners()[4] << getSubunitSubsamplingBits(), findClusterCorners()[6] << getSubunitSubsamplingBits(),
                    (findClusterCorners()[5] + 2) << getSubunitSubsamplingBits(), (findClusterCorners()[7] + 2) << getSubunitSubsamplingBits());
            gl.glPopMatrix();

            // Blue contour 2
            gl.glPushMatrix();
            gl.glColor3f(0.0f, 0.0f, 1.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(findClusterCorners()[4] << getSubunitSubsamplingBits(), (findClusterCorners()[6]) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[5] + 2 << getSubunitSubsamplingBits(), (findClusterCorners()[6]) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[5] + 2 << getSubunitSubsamplingBits(), (findClusterCorners()[7] + 2) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[4] << getSubunitSubsamplingBits(), (findClusterCorners()[7] + 2) << getSubunitSubsamplingBits());
            gl.glVertex2f(findClusterCorners()[4] << getSubunitSubsamplingBits(), (findClusterCorners()[6]) << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();

            // Draw center of mass 2
            gl.glPushMatrix();
            gl.glTranslatef((findCenterOfMass(findClusterCorners())[2] + 1) << getSubunitSubsamplingBits(),
                    (findCenterOfMass(findClusterCorners())[3] + 1) << getSubunitSubsamplingBits(), 5);
            gl.glColor4f(1, 0, 0, .4f);
            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
            glu.gluDisk(quad, 0, 3, 32, 1);
            gl.glPopMatrix();
        }
        if (showSubunits) { // Show subunits
            gl.glPushMatrix();
            gl.glColor4f(0, 1, 0, .3f);
            gl.glRectf(-10, 4, -5, 4 + barsHeight * inhibitionArray[getShowXcoord()][getShowYcoord()]);
            gl.glColor4f(1, 0, 0, .3f);
            gl.glRectf(-20, 4, -15, 4 + barsHeight * excitationArray[getShowXcoord()][getShowYcoord()]);
            gl.glPopMatrix();
            gl.glPushMatrix();
            renderer.begin3DRendering();
            renderer.setColor(0, 1, 0, .3f);
            renderer.draw3D("sur", -10, 0, 0, .4f);
            renderer.setColor(1, 0, 0, .3f);
            renderer.draw3D("cen", -20, 0, 0, .4f);
            renderer.end3DRendering();
            subunits.render(gl);
            gl.glPopMatrix();
        }

        gl.glPushMatrix();

        renderer.begin3DRendering();

        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "OMCshow( " + getShowXcoord() + " , " + getShowYcoord() + " )", -55, 30, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "OMCini: " + inhibitionArray[getShowXcoord()][getShowYcoord()], -55, 90, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "OMCex: " + excitationArray[getShowXcoord()][getShowYcoord()], -55, 80, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "OMCmem: " + membraneStateArray[getShowXcoord()][getShowYcoord()], -55, 100, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "Average Event Rate: " + eventRateFilter.getFilteredEventRate() + " Ev/s", -55, 70, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "Current Threshold: " + IFthreshold, -55, 110, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        directions(findCenterOfMass(findClusterCorners()));
        renderer.draw3D(
                "Direction: " + direction, -55, 50, 0, .4f); // x y width height
        renderer.setColor(
                1, 1, 0, .3f);
        renderer.draw3D(
                "Object at: " + distanceToTravel(((findClusterCorners()[1] + 2) << getSubunitSubsamplingBits())
                        - (findClusterCorners()[0] << getSubunitSubsamplingBits())) + " m", -55, 40, 0, .4f); // x y width height
        renderer.end3DRendering();

        // render all the subunits now
        gridOn(drawable);

        gl.glPopMatrix();
        if (showTracker1) {
            // Render probability of Correctness of tracker 1
            gl.glPushMatrix();
            renderer.begin3DRendering();
            renderer.setColor(0, 1, 255, .3f);
            renderer.draw3D("Probability", -20, 0, 0, .4f);
            renderer.end3DRendering();
            subunits.render(gl);
            gl.glPopMatrix();

            gl.glPushMatrix();
            gl.glColor4f(0, 1, 255, .3f);
            gl.glRectf(-10, 4, -5, 4 + 20 * probabilityOfCorrectness);
            gl.glPopMatrix();
        }

        gl.glPopMatrix();
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//    

//----------------------------------------------------------------------------//
//-- Reset subunits method ---------------------------------------------------//
//----------------------------------------------------------------------------//
    @Override
    public void resetFilter() {
        this.nxmax = chip.getSizeX() >> getSubunitSubsamplingBits();
        this.nymax = chip.getSizeY() >> getSubunitSubsamplingBits();

        this.nSpikesArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()]; // deleted -1 in all
        this.netSynapticInputArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.membraneStateArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.inhibitionArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.excitationArray = new float[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.timeStampArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastTimeStampArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.dtUSarray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.timeStampSpikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastTimeStampSpikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.dtUSspikeArray = new int[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
        this.lastSpikedOMC = new int[2];
        this.lastSpikedOMCTracker1 = new int[2][getClusterSize()];
        this.lastSpikedOMCTracker1 = new int[2][getClusterSize()];
        for (int j = 0; j < getClusterSize(); j++) {
            for (int i = 0; i < 2; i++) {
                if (i == 0) {
                    lastSpikedOMCTracker1[i][j] = lastSpikedOMC[0];
                } else {
                    lastSpikedOMCTracker1[i][j] = lastSpikedOMC[1];
                }
            }
        }
        this.lastSpikedOMCArray = new int[2][getClusterSize()];
        for (int j = 0; j < getClusterSize(); j++) {
            for (int i = 0; i < 2; i++) {
                if (i == 0) {
                    lastSpikedOMCArray[i][j] = lastSpikedOMC[0];
                } else {
                    lastSpikedOMCArray[i][j] = lastSpikedOMC[1];
                }
            }
        }
        this.lastSpikedOMCTracker2 = new int[2][getClusterSize()];
        for (int j = 0; j < getClusterSize(); j++) {
            for (int i = 0; i < 2; i++) {
                if (i == 0) {
                    lastSpikedOMCTracker2[i][j] = lastSpikedOMC[0];
                } else {
                    lastSpikedOMCTracker2[i][j] = lastSpikedOMC[1];
                }
            }
        }
        subunits = new Subunits();
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Initialise filter method ------------------------------------------------//
//----------------------------------------------------------------------------//
    @Override
    public void initFilter() {
        resetFilter();
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Reset tracker anywhere --------------------------------------------------//
//----------------------------------------------------------------------------//
    public void resetTracker1() {
        rememberReset1 = true;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Reset tracker anywhere --------------------------------------------------//
//----------------------------------------------------------------------------//
    public void resetTracker2() {
        rememberReset2 = true;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Plot grid method ------------------------------------------------//
//----------------------------------------------------------------------------//
    public void gridOn(GLAutoDrawable drawable) {
        if (showQuadrants) {
            GL2 gl = drawable.getGL().getGL2();
            // Quadrants
            int divisionX = (int) (chip.getSizeX() >> getSubunitSubsamplingBits()) / 3;
            int divisionY = (int) (chip.getSizeY() >> getSubunitSubsamplingBits()) / 3;
            //1
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f((0 << getSubunitSubsamplingBits()), (0 << getSubunitSubsamplingBits()));
            gl.glVertex2f((divisionX << getSubunitSubsamplingBits()), (0 << getSubunitSubsamplingBits()));
            gl.glVertex2f((divisionX << getSubunitSubsamplingBits()), (divisionY << getSubunitSubsamplingBits()));
            gl.glVertex2f((0 << getSubunitSubsamplingBits()), (divisionY << getSubunitSubsamplingBits()));
            gl.glVertex2f((0 << getSubunitSubsamplingBits()), (0 << getSubunitSubsamplingBits()));
            gl.glEnd();
            gl.glPopMatrix();
            //2
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //3
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), 0 << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //4
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //5
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(0 << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //6
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //7
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //8
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
            //9
            gl.glPushMatrix();
            gl.glColor3f(1.0f, 0.0f, 0.0f);
            gl.glBegin(gl.GL_LINE_STRIP);
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax << getSubunitSubsamplingBits());
            gl.glVertex2f(nxmax - divisionX << getSubunitSubsamplingBits(), nymax - divisionY << getSubunitSubsamplingBits());
            gl.glEnd();
            gl.glPopMatrix();
        }
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Tracker corners method --------------------------------------------------//
//----------------------------------------------------------------------------// 
    int[] findClusterCorners() {
        int minx1 = lastSpikedOMCTracker1[0][0];
        int miny1 = lastSpikedOMCTracker1[1][0];
        int maxx1 = lastSpikedOMCTracker1[0][0];
        int maxy1 = lastSpikedOMCTracker1[1][0];
        int minx2 = lastSpikedOMCTracker2[0][0];
        int miny2 = lastSpikedOMCTracker2[1][0];
        int maxx2 = lastSpikedOMCTracker2[0][0];
        int maxy2 = lastSpikedOMCTracker2[1][0];
        int[] corners = new int[8];
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker1[0][i] < minx1) {
                minx1 = lastSpikedOMCTracker1[0][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker1[0][i] > maxx1) {
                maxx1 = lastSpikedOMCTracker1[0][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker1[1][i] < miny1) {
                miny1 = lastSpikedOMCTracker1[1][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker1[1][i] > maxy1) {
                maxy1 = lastSpikedOMCTracker1[1][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker2[0][i] < minx2) {
                minx2 = lastSpikedOMCTracker2[0][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker2[0][i] > maxx2) {
                maxx2 = lastSpikedOMCTracker2[0][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker2[1][i] < miny2) {
                miny2 = lastSpikedOMCTracker2[1][i];
            }
        }
        for (int i = 0; i < getClusterSize(); i++) {
            if (lastSpikedOMCTracker2[1][i] > maxy2) {
                maxy2 = lastSpikedOMCTracker2[1][i];
            }
        }
        corners[0] = minx1;
        corners[1] = maxx1;
        corners[2] = miny1;
        corners[3] = maxy1;
        corners[4] = minx2;
        corners[5] = maxx2;
        corners[6] = miny2;
        corners[7] = maxy2;
        return corners;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Center of mass finder method --------------------------------------------//
//----------------------------------------------------------------------------// 
    int[] findCenterOfMass(int[] corners) {
        int minx1 = corners[0];
        int maxx1 = corners[1];
        int miny1 = corners[2];
        int maxy1 = corners[3];
        int minx2 = corners[4];
        int maxx2 = corners[5];
        int miny2 = corners[6];
        int maxy2 = corners[7];
        int[] centerOfMass = new int[4];
        centerOfMass[0] = (minx1 + maxx1) / 2;// Find x of CM
        centerOfMass[1] = (miny1 + maxy1) / 2; // Find y of CM
        centerOfMass[2] = (minx2 + maxx2) / 2;// Find x of CM
        centerOfMass[3] = (miny2 + maxy2) / 2; // Find y of CM
        return centerOfMass;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Center of mass finder method --------------------------------------------//
//----------------------------------------------------------------------------// 
    int[] findMedianCenterOfMass(int[][] arrayOfSpikedCells) {
        int[] medianCenterOfMass = new int[2];
        int xPosition[] = new int[getClusterSize()];
        int yPosition[] = new int[getClusterSize()];
        for (int i = 0; i < getClusterSize(); i++) {
            xPosition[i] = arrayOfSpikedCells[0][i];
            yPosition[i] = arrayOfSpikedCells[1][i];
        }
        Arrays.sort(xPosition);
        Arrays.sort(yPosition);

        double pos1x = Math.floor((xPosition.length - 1) / 2);
        double pos2x = Math.ceil((xPosition.length - 1) / 2);
        double pos1y = Math.floor((yPosition.length - 1) / 2);
        double pos2y = Math.ceil((yPosition.length - 1) / 2);

        if (pos1x == pos2x) {
            medianCenterOfMass[0] = xPosition[(int) pos1x];
        } else {
            medianCenterOfMass[0] = (xPosition[(int) pos1x] + xPosition[(int) pos2x]) / 2;
        }

        if (pos1y == pos2y) {
            medianCenterOfMass[1] = yPosition[(int) pos1y];
        } else {
            medianCenterOfMass[1] = (yPosition[(int) pos1y] + yPosition[(int) pos2y]) / 2;
        }
        return medianCenterOfMass;
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Directions method -------------------------------------------------------//
//----------------------------------------------------------------------------// 
    void directions(int[] centerOfMass) {
        int CMx = centerOfMass[0];
        int CMy = centerOfMass[1];
        int divisionX = (int) (chip.getSizeX() >> getSubunitSubsamplingBits()) / 3;
        int divisionY = (int) (chip.getSizeY() >> getSubunitSubsamplingBits()) / 3;

        if (CMx > 0 && CMy > 0 && CMx < divisionX && CMy < divisionY) { //1
            direction = "[1] Bottom-Left: Turn Left";
        } else if (CMx > divisionX && CMy > 0 && CMx < nxmax - divisionX && CMy < divisionY) { //2
            direction = "[2] Bottom-Center: Stay still";
        } else if (CMx > nxmax - divisionX && CMy > 0 && CMx < nxmax && CMy < divisionY) { //3
            direction = "[3] Bottom-Right: Turn Right";
        } else if (CMx > 0 && CMy > divisionY && CMx < divisionX && CMy < nymax - divisionY) { //4
            direction = "[4] Center-Left: Go + Turn Left";
        } else if (CMx > divisionX && CMy > divisionY && CMx < nxmax - divisionX && CMy < nymax - divisionY) { //5
            direction = "[5] Center: Go straight";
        } else if (CMx > nxmax - divisionX && CMy > divisionY && CMx < nxmax && CMy < nymax - divisionY) { //6
            direction = "[6] Center-Right: ? Go + Turn Right";
        } else if (CMx > 0 && CMy > nymax - divisionY && CMx < divisionX && CMy < nymax) { //7
            direction = "[7] Top-Left: ? Go more + Turn Left";
        } else if (CMx > divisionX && CMy > nymax - divisionY && CMx < nxmax - divisionX && CMy < nymax) { //8
            direction = "[8] Top-Center: ? Go more straight";
        } else if (CMx > nxmax - divisionX && CMy > nymax - divisionY && CMx < nxmax && CMy < nymax) { //9
            direction = "[9] Top-Right: ? Go more + Turn Right";
        }
    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Distance to be travelled method -----------------------------------------//
//----------------------------------------------------------------------------// 
    float distanceToTravel(int objectDetectedWidthX) {
        float pixelSizeM = 0.000018f; // pixelSize 18 um DAVIS/40 um DVS
        float distanceToObject = (focalLengthM * objectRealWidthXM) / (objectDetectedWidthX * pixelSizeM);
        return distanceToObject;

    }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//****************************************************************************//
//-- Subunits class ----------------------------------------------------------//
//----------------------------------------------------------------------------//
    // handles all subunits on and off
    private class Subunits {

        Subunit[][] subunits;
        int ntot;
        int lastUpdateTimestamp;
        FileOutputStream out; // declare a file output object
        PrintStream p; // declare a print stream object        
//----------------------------------------------------------------------------//
//-- Reset Subunits method ---------------------------------------------------//
//----------------------------------------------------------------------------//

        public Subunits() {
            reset();
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//        

//----------------------------------------------------------------------------//
//-- Update events method ----------------------------------------------------//
//----------------------------------------------------------------------------//
        synchronized public void update(PolarityEvent e) {
            // subsample retina address to clump retina input pixel blocks.
            int x = e.x >> getSubunitSubsamplingBits(), y = e.y >> getSubunitSubsamplingBits();
            if ((x < nxmax) && (y < nymax)) {
                switch (e.polarity) {
                    case Off: // these subunits are excited by OFF events and in turn excite the approach cell
                        subunits[x][y].updatepos(e);
                        break;
                    case On: // these are excited by ON activity and in turn inhibit the approach cell
                        subunits[x][y].updatepos(e);
                        break;
                    // all subunits are excited by any retina on or off activity
                }
            }
            maybeDecayAll(e);
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Decay subunits method ---------------------------------------------------//
//----------------------------------------------------------------------------//
        void maybeDecayAll(BasicEvent e) {
            int dt = e.timestamp - lastUpdateTimestamp;
            if (dt < 0) {
                lastUpdateTimestamp = e.timestamp;
                return;
            }
            if (dt > minUpdateIntervalUs) {
                lastUpdateTimestamp = e.timestamp;

                // update Neuron RGC
                float decayFactor2 = (float) Math.exp(-dt / (1000 * neuronDecayTimeconstantMs));
                for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                    for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                        membraneStateArray[omcx][omcy] *= decayFactor2;
                    }
                }

                // now update all subunits to RC decay activity toward zero
                float decayFactor1 = (float) Math.exp(-dt / (1000 * subunitDecayTimeconstantMs));
                for (int x = 0; x < nxmax; x++) {
                    for (int y = 0; y < nymax; y++) {
                        subunits[x][y].decayBy(decayFactor1);
                    }
                }
            }
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Inhibition Calculation method -------------------------------------------//
//----------------------------------------------------------------------------//        
        float computeInhibitionToOutputCell(int omcx, int omcy) {
            // For all subunits, excluding the edge ones and the last ones (far right and bottom)
            // Find inhibition around center made of [omcx,omcy], [omcx+1,omcy+1], [omcx+1,omcy], [omcx,omcy+1]
            inhibitionArray[omcx][omcy] = 0;
            for (int x = getExcludedEdgeSubunits(); x < (nxmax - getExcludedEdgeSubunits()); x++) {
                for (int y = getExcludedEdgeSubunits(); y < (nymax - getExcludedEdgeSubunits()); y++) {
//------------------------------------------------------------------------------
                    // Select computation type
                    if (!exponentialToTanh) {// Use non-linear model (given the nonlinearity order)
                        if (((x != omcx) && (y != omcy)) || ((x != omcx + 1) && (y != omcy + 1))
                                || ((x != omcx) && (y != omcy + 1)) || ((x != omcx + 1) && (y != omcy))) {
                            //if(Math.pow(subunits[x][y].computeInputToCell(),nonLinearityOrder) < Saturation){ // If squared subunit less than limit
                            //    inhibitionArray[omcx][omcy] += (float) Math.pow(subunits[x][y].computeInputToCell(),nonLinearityOrder);
                            //}
                            if (synapticWeight * synapticWeight * subunits[x][y].computeInputToCell() * subunits[x][y].computeInputToCell() < Saturation) { // If squared subunit less than limit
                                inhibitionArray[omcx][omcy] += (float) synapticWeight * synapticWeight * subunits[x][y].computeInputToCell() * subunits[x][y].computeInputToCell();
                            } else {
                                inhibitionArray[omcx][omcy] += Saturation;
                            }
                        }
                    } else { // Use tanh model (given saturation value): preferred method
                        if (((x != omcx) && (y != omcy)) || ((x != omcx + 1) && (y != omcy + 1))
                                || ((x != omcx) && (y != omcy + 1)) || ((x != omcx + 1) && (y != omcy))) {
                            inhibitionArray[omcx][omcy] += Saturation * Math.tanh(synapticWeight * subunits[x][y].computeInputToCell());
                        }
                    }
//------------------------------------------------------------------------------
                }
            }
//------------------------------------------------------------------------------
            inhibitionArray[omcx][omcy] /= (ntot - 4); // Divide by the number of subunits to normalise
            //inhibitionArray[omcx][omcy] = inhibitionArray[omcx][omcy]; // Give a synaptic weight (a simple scalar value)
//------------------------------------------------------------------------------
            // Log inhibitionArray
            if (startLogging == true) {
                try {
                    if (omcx == 0 && omcy == 0) {
                        // Create a new file output stream
                        FileOutputStream out = new FileOutputStream(new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\inhibitionArray1.txt"), true);
                        // Connect print stream to the output stream
                        p = new PrintStream(out);
                        p.print(inhibitionArray[omcx][omcy]);
                        p.print(", ");
                        p.print(omcx);
                        p.print(", ");
                        p.print(omcy);
                        p.print(", ");
                        p.println(lastUpdateTimestamp);
                        p.close();
                    }
                } catch (Exception e) {
                    System.err.println("Error writing to file");
                }
            } // Delete inhibitionArray
            if (deleteLogging == true) {
                File fout = new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\inhibitionArray.txt");
                fout.delete();
            }
            return inhibitionArray[omcx][omcy];
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//        

//----------------------------------------------------------------------------//
//-- Excitation Calculation method -------------------------------------------//
//----------------------------------------------------------------------------//
        float computeExcitationToOutputCell(int omcx, int omcy) {
            // For all subunits, excluding the edge ones and the last ones (far right and bottom)
            // Select computation type
            excitationArray[omcx][omcy] = 0;
            if (!exponentialToTanh) {// Use non-linear model (given the nonlinearity order)
                // Average of 4 central cells
                for (int x = omcx; x <= omcx + 1; x++) {
                    for (int y = omcy; y <= omcy + 1; y++) {
                        //if(Math.pow(subunits[x][y].computeInputToCell(),nonLinearityOrder) < Saturation){
                        //    excitationArray[omcx][omcy] += (float) Math.pow(subunits[x][y].computeInputToCell(),nonLinearityOrder);
                        //}
                        if (synapticWeight * synapticWeight * subunits[x][y].computeInputToCell() * subunits[x][y].computeInputToCell() < Saturation) {
                            excitationArray[omcx][omcy] += (float) synapticWeight * synapticWeight * subunits[x][y].computeInputToCell() * subunits[x][y].computeInputToCell();
                        } else {
                            excitationArray[omcx][omcy] += Saturation;
                        }
                    }
                }
                excitationArray[omcx][omcy] /= 4;
            } // Ignore surround
            else { // Use tanh model (given saturation value): preferred method
                // Average of 4 central cells
                excitationArray[omcx][omcy] = (float) ((Saturation * Math.tanh((synapticWeight * subunits[omcx][omcy].computeInputToCell())))
                        + (Saturation * Math.tanh((synapticWeight * subunits[omcx + 1][omcy + 1].computeInputToCell())))
                        + (Saturation * Math.tanh((synapticWeight * subunits[omcx + 1][omcy].computeInputToCell())))
                        + (Saturation * Math.tanh((synapticWeight * subunits[omcx][omcy + 1].computeInputToCell())))) / 4;
            } // Ignore surround            
//------------------------------------------------------------------------------
            // Log excitationArray
            if (startLogging == true) {
                try {
                    if (omcx == 0 && omcy == 0) {
                        // Create a new file output stream
                        FileOutputStream out = new FileOutputStream(new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\excitationArray.txt"), true);
                        // Connect print stream to the output stream
                        p = new PrintStream(out);
                        p.print(excitationArray[omcx][omcy]);
                        p.print(", ");
                        p.print(omcx);
                        p.print(", ");
                        p.print(omcy);
                        p.print(", ");
                        p.println(lastUpdateTimestamp);
                        p.close();
                    }
                } catch (Exception e) {
                    System.err.println("Error writing to file");
                }
            }
            if (deleteLogging == true) {
                File fout = new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\excitationArray.txt");
                fout.delete();
            }
            excitationArray[omcx][omcy] = centerExcitationToSurroundInhibitionRatio * excitationArray[omcx][omcy];
            return excitationArray[omcx][omcy];
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Reset method ------------------------------------------------------------//
//----------------------------------------------------------------------------//
        synchronized private void reset() {
            // Reset size
            ntot = (nxmax - getExcludedEdgeSubunits()) * (nymax - getExcludedEdgeSubunits());
            subunits = new Subunit[nxmax - 2 * getExcludedEdgeSubunits()][nymax - 2 * getExcludedEdgeSubunits()];
            for (int x = getExcludedEdgeSubunits(); x < nxmax - getExcludedEdgeSubunits(); x++) {
                for (int y = getExcludedEdgeSubunits(); y < nymax - getExcludedEdgeSubunits(); y++) {
                    subunits[x][y] = new Subunit(x, y, subunits);
                }
            }
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Rendering of subunits method --------------------------------------------//
//----------------------------------------------------------------------------//
        private void render(GL2 gl) {
            if (showSubunits) {
                final float alpha = .2f;
                glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
                int off = (1 << (getSubunitSubsamplingBits())) / 2;
                for (int x = getExcludedEdgeSubunits(); x < (nxmax - getExcludedEdgeSubunits()); x++) {
                    for (int y = getExcludedEdgeSubunits(); y < (nymax - getExcludedEdgeSubunits()); y++) {
                        gl.glPushMatrix();
                        gl.glTranslatef((x << getSubunitSubsamplingBits()) + off, (y << getSubunitSubsamplingBits()) + off, 5);
                        if (((x == getShowXcoord()) && (y == getShowYcoord())) || ((x == getShowXcoord() + 1) && (y == getShowYcoord() + 1))
                                || ((x == getShowXcoord()) && (y == getShowYcoord() + 1)) || ((x == getShowXcoord() + 1) && (y == getShowYcoord()))) {
                            gl.glColor4f(1, 0, 0, alpha);
                        } else {
                            gl.glColor4f(0, 1, 0, alpha);
                        }
                        glu.gluDisk(quad, 0, subunitActivityBlobRadiusScale * subunits[x][y].computeInputToCell(), 16, 1);
                        gl.glPopMatrix();
                    }
                }
                renderer.begin3DRendering();
                renderer.setColor(1, 0, 0, 1);
                renderer.draw3D("Center", 0, chip.getSizeY(), 0, .5f);
                renderer.setColor(0, 1, 0, 1);
                renderer.draw3D("Surround", chip.getSizeX() / 2, chip.getSizeY(), 0, .5f);
                renderer.end3DRendering();
            }
        }
    }
//-- end of Subunits class ---------------------------------------------------//
//****************************************************************************//

//****************************************************************************//
//-- Subunit class (to model single subunit and deal with vmem) --------------//
//----------------------------------------------------------------------------//
// polarity is ignored here and only handled on update of object Motion cell
    private class Subunit {

        float vmem;
        int x, y;
        Subunit[][] mySubunits;

//----------------------------------------------------------------------------//
//-- Constructor method ------------------------------------------------------//
//----------------------------------------------------------------------------//
        public Subunit(int x, int y, Subunit[][] mySubunits) {
            this.x = x;
            this.y = y;
            this.mySubunits = mySubunits;
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Decay method ------------------------------------------------------------//
//----------------------------------------------------------------------------//
        public void decayBy(float factor) {
            vmem *= factor;
        }
//----------------------------------------------------------------------------//        
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Update positive events method -------------------------------------------//
//----------------------------------------------------------------------------//
        public void updatepos(PolarityEvent e) {
            vmem += vmemIncrease;
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Update negative events method -------------------------------------------//
//----------------------------------------------------------------------------//
        public void updateneg(PolarityEvent e) {
            vmem -= vmemIncrease;
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Compute input to cell method --------------------------------------------//
//----------------------------------------------------------------------------//        
        // subunit input is pure rectification
        public float computeInputToCell() {
            if (!surroundSuppressionEnabled) {
                return vmem;
            } else {
                // Here we return the half-rectified local difference between ourselves and our neighbors
                int n = 0;
                float sum = 0;
                if ((x + 1) < nxmax) {
                    sum += mySubunits[x + 1][y].vmem;
                    n++;
                }
                if ((x - 1) >= 0) {
                    sum += mySubunits[x - 1][y].vmem;
                    n++;
                }
                if ((y + 1) < nymax) {
                    sum += mySubunits[x][y + 1].vmem;
                    n++;
                }
                if ((y - 1) >= 0) {
                    sum += mySubunits[x][y - 1].vmem;
                    n++;
                }
                sum /= n;
                float result = vmem - sum;
                if (result < 0) {
                    return 0;
                } else {
                    return result; // half rectify result
                }
            }
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
    }
//-- end Subunit class -------------------------------------------------------//
//****************************************************************************//

//****************************************************************************//
//-- class OMCODModel (OMC model) --------------------------------------------//
//----------------------------------------------------------------------------//
// models soma and integration and spiking of objectMotion cell
    private class OMCODModel {

        Random r = new Random();
        private final LowpassFilter isiFilter = new LowpassFilter(300);
        private boolean initialized = false;
        float spikeRateHz = 0;
        boolean result = false;

//----------------------------------------------------------------------------//
//-- Update to check firing method -------------------------------------------//
//----------------------------------------------------------------------------//
        synchronized private boolean update(int timestamp) {
            // compute subunit input to us
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nxmax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    timeStampArray[omcx][omcy] = timestamp;
                    netSynapticInputArray[omcx][omcy] = (subunits.computeExcitationToOutputCell(omcx, omcy) - subunits.computeInhibitionToOutputCell(omcx, omcy));
                    dtUSarray[omcx][omcy] = timeStampArray[omcx][omcy] - lastTimeStampArray[omcx][omcy];
                    if (dtUSarray[omcx][omcy] < 0) {
                        dtUSarray[omcx][omcy] = 0; // to handle negative dt
                    }
                    lastTimeStampArray[omcx][omcy] = timeStampArray[omcx][omcy];
                    if (poissonFiringEnabled) {
                        float spikeRate = netSynapticInputArray[omcx][omcy];
                        if (spikeRate < 0) {
                            result = false;
                        }
                        if (spikeRate > maxSpikeRateHz) {
                            spikeRate = maxSpikeRateHz;
                        }
                        if (r.nextFloat() < (spikeRate * 1e-6f * dtUSarray[omcx][omcy])) {
                            spike(timeStampArray[omcx][omcy], omcx, omcy);
                            result = true;
                        } else {
                            result = false;
                        }
                    } else { // IF neuron
                        membraneStateArray[omcx][omcy] += netSynapticInputArray[omcx][omcy] * dtUSarray[omcx][omcy] * 1e-6f;
                        if (eventRateFilter.getFilteredEventRate() > 100000) {
                            IFthreshold = integrateAndFireThreshold + increaseInThreshold;
                        } else if (eventRateFilter.getFilteredEventRate() < 400) {
                            IFthreshold = 10000; //Just very high if only noise is present
                        } else {
                            IFthreshold = integrateAndFireThreshold;
                        }
                        if (membraneStateArray[omcx][omcy] > IFthreshold) {
                            spike(timeStampArray[omcx][omcy], omcx, omcy);
                            membraneStateArray[omcx][omcy] = 0;
                            result = true;
                        } else if (membraneStateArray[omcx][omcy] < -10) {
                            membraneStateArray[omcx][omcy] = 0;
                            result = false;
                        } else {
                            result = false;
                        }
                    }
                }
            }
            return result;
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Spike method ------------------------------------------------------------//
//----------------------------------------------------------------------------//
        void spike(int timestamp, int omcx, int omcy) {
            timeStampSpikeArray[omcx][omcy] = timestamp;
            // Log OMC array
            if (startLogging == true) {
                try {
                    // Create a new file output stream
                    FileOutputStream out = new FileOutputStream(new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\lastSpikedOMC.txt"), true);
                    // Connect print stream to the output stream
                    PrintStream p = new PrintStream(out);
                    p.print(omcx);
                    p.print(", ");
                    p.print(omcy);
                    p.print(", ");
                    p.println(timestamp);
                    p.close();

                } catch (Exception e) {
                    System.err.println("Error writing to file");
                }
            }
            if (deleteLogging == true) {
                File fout = new File("C:\\Users\\Diederik Paul Moeys\\Desktop\\lastSpikedOMC.txt");
                fout.delete();
            }
            enableSpikeDraw = true;
            lastSpikedOMC[0] = omcx;
            lastSpikedOMC[1] = omcy;
            if (enableSpikeSound) {
                if (omcx == getShowXcoord() && omcy == getShowYcoord()) {
                    spikeSound.play();
                }
            }
            nSpikesArray[omcx][omcy]++;
            dtUSspikeArray[omcx][omcy] = timeStampSpikeArray[omcx][omcy] - lastTimeStampSpikeArray[omcx][omcy];
            if (initialized && (dtUSspikeArray[omcx][omcy] >= 0)) {
                float avgIsiUs = isiFilter.filter(dtUSspikeArray[omcx][omcy], timeStampSpikeArray[omcx][omcy]);
                spikeRateHz = 1e6f / avgIsiUs;
            } else {
                initialized = true;
            }
            lastTimeStampSpikeArray[omcx][omcy] = timeStampSpikeArray[omcx][omcy];
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Reset method ------------------------------------------------------------//
//----------------------------------------------------------------------------//
        void reset() {
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    membraneStateArray[omcx][omcy] = 0;
                }
            }
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    netSynapticInputArray[omcx][omcy] = 0;
                }
            }
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    inhibitionArray[omcx][omcy] = 0;
                }
            }
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    excitationArray[omcx][omcy] = 0;
                }
            }
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    nSpikesArray[omcx][omcy] = 0;
                }
            }
            isiFilter.reset();
            //medianCMFilter.reset();
            initialized = false;
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
//-- Reset spike count method ------------------------------------------------//
//----------------------------------------------------------------------------//        
        private void resetSpikeCount() {
            for (int omcx = getExcludedEdgeSubunits(); omcx < (nymax - 1 - getExcludedEdgeSubunits()); omcx++) {
                for (int omcy = getExcludedEdgeSubunits(); omcy < (nymax - 1 - getExcludedEdgeSubunits()); omcy++) {
                    nSpikesArray[omcx][omcy] = 0;
                }
            }
        }
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
    }
//-- end class OMCODModel-----------------------------------------------------//    
//****************************************************************************//    

//----------------------------------------------------------------------------//
//-- Set and Get methods -----------------------------------------------------//
//----------------------------------------------------------------------------//
// @return the subunitDecayTimeconstantMs
    public float getSubunitDecayTimeconstantMs() {
        return subunitDecayTimeconstantMs;
    }
//------------------------------------------------------------------------------

    public int getNeuronDecayTimeconstantMs() {
        return neuronDecayTimeconstantMs;
    }

    // @param neuronDecayTimeconstantMs the neuronDecayTimeconstantMs to set
    public synchronized void setNeuronDecayTimeconstantMs(int neuronDecayTimeconstantMs) {
        this.neuronDecayTimeconstantMs = neuronDecayTimeconstantMs;
        putInt("neuronDecayTimeconstantMs", neuronDecayTimeconstantMs);
    }
//------------------------------------------------------------------------------

    @Override
    public int getSubunitSubsamplingBits() {
        return subunitSubsamplingBits;
    }

    // @param subunitSubsamplingBits the subunitSubsamplingBits to set
    @Override
    public synchronized void setSubunitSubsamplingBits(int subunitSubsamplingBits) {
        this.subunitSubsamplingBits = subunitSubsamplingBits;
        putInt("subunitSubsamplingBits", subunitSubsamplingBits);
        resetFilter();
        OMCODModel.reset();
    }
//------------------------------------------------------------------------------
    // @return the clusterSize

    public int getClusterSize() {
        return clusterSize;
    }

    // @param clusterSize the clusterSize
    public void setClusterSize(int clusterSize) {
        this.clusterSize = clusterSize;
        putInt("clusterSize", clusterSize);
        resetFilter();
        OMCODModel.reset();
    }
//------------------------------------------------------------------------------    
    // @return the subunitActivityBlobRadiusScale

    public float getSubunitActivityBlobRadiusScale() {
        return subunitActivityBlobRadiusScale;
    }

    // @param subunitActivityBlobRadiusScale the subunitActivityBlobRadiusScale
    public void setSubunitActivityBlobRadiusScale(float subunitActivityBlobRadiusScale) {
        this.subunitActivityBlobRadiusScale = subunitActivityBlobRadiusScale;
        putFloat("subunitActivityBlobRadiusScale", subunitActivityBlobRadiusScale);
    }
//------------------------------------------------------------------------------
    // @return the integrateAndFireThreshold

    public float getIntegrateAndFireThreshold() {
        return integrateAndFireThreshold;
    }

    // @param integrateAndFireThreshold the integrateAndFireThreshold to set
    public void setIntegrateAndFireThreshold(float integrateAndFireThreshold) {
        this.integrateAndFireThreshold = integrateAndFireThreshold;
        putFloat("integrateAndFireThreshold", integrateAndFireThreshold);
    }
//------------------------------------------------------------------------------
    // @return the increaseInThreshold

    public float getIncreaseInThreshold() {
        return increaseInThreshold;
    }

    // @param increaseInThreshold the increaseInThreshold to set
    public void setIncreaseInThreshold(float increaseInThreshold) {
        this.increaseInThreshold = increaseInThreshold;
        putFloat("increaseInThreshold", increaseInThreshold);
    }
//------------------------------------------------------------------------------
    // @return the showXcoord

    public int getShowXcoord() {
        return showXcoord;
    }

    // @param showXcoord the showXcoord to set
    public void setShowXcoord(int showXcoord) {
        this.showXcoord = showXcoord;
        putInt("showXcoord", showXcoord);
        resetFilter();
        OMCODModel.reset();
    }
//------------------------------------------------------------------------------
    // @return the showYcoord    

    public int getShowYcoord() {
        return showYcoord;
    }

    // @param showYcoord the showYcoord to set
    public void setShowYcoord(int showYcoord) {
        this.showYcoord = showYcoord;
        putInt("showYcoord", showYcoord);
        resetFilter();
        OMCODModel.reset();
    }
//------------------------------------------------------------------------------
    // @return the nonLinearityOrder

    public float getNonLinearityOrder() {
        return nonLinearityOrder;
    }

    // @param nonLinearityOrder the nonLinearityOrder to set
    public void setNonLinearityOrder(float nonLinearityOrder) {
        this.nonLinearityOrder = nonLinearityOrder;
        putFloat("nonLinearityOrder", nonLinearityOrder);
    }
//------------------------------------------------------------------------------    
    // @return the synapticWeight

    public float getSynapticWeight() {
        return synapticWeight;
    }

    // @param synapticWeight the synapticWeight to set
    public void setSynapticWeight(float synapticWeight) {
        this.synapticWeight = synapticWeight;
        putFloat("synapticWeight", synapticWeight);
    }
//------------------------------------------------------------------------------    
    // @return the vmemIncrease

    public float getVmemIncrease() {
        return vmemIncrease;
    }

    // @param vmemIncrease the vmemIncrease to set
    public void setVmemIncrease(float vmemIncrease) {
        this.vmemIncrease = vmemIncrease;
        putFloat("vmemIncrease", vmemIncrease);
    }
//------------------------------------------------------------------------------
    // @return the barsHeight

    public float getBarsHeight() {
        return barsHeight;
    }

    // @param barsHeight the barsHeight to set
    public void setBarsHeight(float barsHeight) {
        this.barsHeight = barsHeight;
        putFloat("barsHeight", barsHeight);
    }
//------------------------------------------------------------------------------
    // @return the excludedEdgeSubunits

    public int getExcludedEdgeSubunits() {
        return excludedEdgeSubunits;
    }

    // @param excludedEdgeSubunits the excludedEdgeSubunits to set
    public void setExcludedEdgeSubunits(int excludedEdgeSubunits) {
        this.excludedEdgeSubunits = excludedEdgeSubunits;
        putFloat("excludedEdgeSubunits", excludedEdgeSubunits);
        resetFilter();
        OMCODModel.reset();
    }
//------------------------------------------------------------------------------
    // @return the onOffWeightRatio

    public float getCenterExcitationToSurroundInhibitionRatio() {
        return centerExcitationToSurroundInhibitionRatio;
    }

    // @param onOffWeightRatio the onOffWeightRatio to set
    public void setCenterExcitationToSurroundInhibitionRatio(float onOffWeightRatio) {
        this.centerExcitationToSurroundInhibitionRatio = onOffWeightRatio;
        putFloat("centerExcitationToSurroundInhibitionRatio", onOffWeightRatio);
    }
//------------------------------------------------------------------------------
    // @return the objectRealWidthXM

    public float getObjectRealWidthXM() {
        return objectRealWidthXM;
    }

    // @param objectRealWidthXM the objectRealWidthXM to set
    public void setObjectRealWidthXM(float objectRealWidthXM) {
        this.objectRealWidthXM = objectRealWidthXM;
        putFloat("objectRealWidthXM", objectRealWidthXM);
    }
//------------------------------------------------------------------------------
    // @return the focalLengthM

    public float getFocalLengthM() {
        return focalLengthM;
    }

    // @param focalLengthM the focalLengthM to set
    public void setFocalLengthM(float focalLengthM) {
        this.focalLengthM = focalLengthM;
        putFloat("focalLengthM", focalLengthM);
    }
//------------------------------------------------------------------------------    
    // @return the Saturation

    public int getSaturation() {
        return Saturation;
    }

    // @param Saturation the Saturation to set
    public void setSaturation(int Saturation) {
        this.Saturation = Saturation;
        putInt("Saturation", Saturation);
    }
//------------------------------------------------------------------------------
    // @return the deleteLogging

    public boolean isDeleteLogging() {
        return deleteLogging;
    }

    // @param deleteLogging the deleteLogging to set
    public void setDeleteLogging(boolean deleteLogging) {
        this.deleteLogging = deleteLogging;
        putBoolean("deleteLogging", deleteLogging);
    }
//------------------------------------------------------------------------------
    // @return the exponentialToTanh

    public boolean isExponentialToTanh() {
        return exponentialToTanh;
    }

    // @param exponentialToTanh the exponentialToTanh to set
    public void setExponentialToTanh(boolean exponentialToTanh) {
        this.exponentialToTanh = exponentialToTanh;
        putBoolean("exponentialToTanh", exponentialToTanh);
    }
//------------------------------------------------------------------------------
    // return the startLogging

    public boolean isStartLogging() {
        return startLogging;
    }

    // @param startLogging the startLogging to set
    public void setStartLogging(boolean startLogging) {
        this.startLogging = startLogging;
        putBoolean("startLogging", startLogging);
    }

//------------------------------------------------------------------------------
    // @return the showQuadrants
    public boolean isShowQuadrants() {
        return showQuadrants;
    }

    // @param showQuadrants the showQuadrants to set
    public void setShowQuadrants(boolean showQuadrants) {
        this.showQuadrants = showQuadrants;
        putBoolean("showQuadrants", showQuadrants);
    }
//------------------------------------------------------------------------------
    // @return the showTracker2

    public boolean isShowTracker2() {
        return showTracker2;
    }

    // @param showTracker2 the showTracker2 to set
    public void setShowTracker2(boolean showTracker2) {
        this.showTracker2 = showTracker2;
        putBoolean("showTracker2", showTracker2);
    }
//------------------------------------------------------------------------------
    // @return the showTracker1

    public boolean isShowTracker1() {
        return showTracker1;
    }

    // @param showTracker1 the showTracker1 to set
    public void setShowTracker1(boolean showTracker1) {
        this.showTracker1 = showTracker1;
        putBoolean("showTracker1", showTracker1);
    }
//------------------------------------------------------------------------------
    // @return the showTrackerCellsOnly

    public boolean isShowTrackerCellsOnly() {
        return showTrackerCellsOnly;
    }

    // @param showTrackerCellsOnly the showTrackerCellsOnly to set
    public void setShowTrackerCellsOnly(boolean showTrackerCellsOnly) {
        this.showTrackerCellsOnly = showTrackerCellsOnly;
        putBoolean("showTrackerCellsOnly", showTrackerCellsOnly);
    }
    //------------------------------------------------------------------------------
    // @return the surroundSuppressionEnabled

    public boolean isSurroundSuppressionEnabled() {
        return surroundSuppressionEnabled;
    }

    // @param surroundSuppressionEnabled the surroundSuppressionEnabled to set
    public void setSurroundSuppressionEnabled(boolean surroundSuppressionEnabled) {
        this.surroundSuppressionEnabled = surroundSuppressionEnabled;
        putBoolean("surroundSuppressionEnabled", surroundSuppressionEnabled);
    }
//------------------------------------------------------------------------------
    // @return the eventRateTauMs

    public float getEventRateTauMs() {
        return eventRateTauMs;
    }

    // @param eventRateTauMs the eventRateTauMs to set
    public void setEventRateTauMs(float eventRateTauMs) {
        this.eventRateTauMs = eventRateTauMs;
        putFloat("eventRateTauMs", eventRateTauMs);
    }
//------------------------------------------------------------------------------
    // @return the dtBackgroundUs

    public float getDtBackgroundUs() {
        return dtBackgroundUs;
    }

    // @param dtBackgroundUs the dtBackgroundUs to set
    public void setDtBackgroundUs(float dtBackgroundUs) {
        this.dtBackgroundUs = dtBackgroundUs;
        putFloat("dtBackgroundUs", dtBackgroundUs);
    }
//------------------------------------------------------------------------------
    // @return the operationRange

    public int getOperationRange() {
        return operationRange;
    }

    // @param operationRange the operationRange to set
    public void setOperationRange(int operationRange) {
        this.operationRange = operationRange;
        putInt("operationRange", operationRange);
    }
//------------------------------------------------------------------------------
    // @return the updateRosEveryUs

    public int getUpdateRosEveryUs() {
        return updateRosEveryUs;
    }

    // @param updateRosEveryUs the updateRosEveryUs to set
    public void setUpdateRosEveryUs(int updateRosEveryUs) {
        this.updateRosEveryUs = updateRosEveryUs;
        putInt("updateRosEveryUs", updateRosEveryUs);
    }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
}
//-- Class OMCOD -------------------------------------------------------------//
//****************************************************************************//
