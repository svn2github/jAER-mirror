/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.laser3d;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.logging.Level;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.event.PolarityEvent.Polarity;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;

/**
 * Filter a pulsed laserline
 *
 * @author Thomas Mantel
 */
@Description("Filters a clocked laserline using a event histogram over several the most recent periods as score for new events")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class FilterLaserline extends EventFilter2D implements FrameAnnotater {

    /*
     * Variables
     */
    private boolean isInitialized = false;
    private int laserPeriod = 0;
    private int lastTriggerTimestamp = 0;
    private int nBins = 0;
    private HistogramData onHist;
    private HistogramData offHist;
    PxlScoreMap pxlScoreMap;
    private ArrayList oldLaserLine; // previous laser line collection of float[2] that held the line coordinates
    private boolean showLaserLine = getBoolean("showLaserLine", true);
    private LaserLine laserLineNew = new LaserLine();
    private float[][] curBinWeights;
    private LaserlineLogfile laserlineLogfile;
    /**
     * Size of histogram history in periods
     */
    protected int histogramHistorySize = getInt("histogramHistorySize", 1000);
    /**
     * Moving average window length
     */
    protected int pxlScoreHistorySize = getInt("pxlScoreHistorySize", 20);
    /**
     * binsize for histogram (in us)
     */
    protected int binSize = getInt("binSize", 20);
    /**
     * Allows to display the score of each pixel with a score not equal 0
     */
    protected boolean showScoreMap = getBoolean("showScoreMap", false);
    /**
     * Use different weights for on and off events?
     */
    protected boolean useWeightedOnOff = getBoolean("useWeightedOnOff", true);
    /**
     * All pixels with a score above pxlScoreThreshold are classified as laser
     * line
     */
    protected float pxlScoreThreshold = getFloat("pxlScoreThreshold", .01f);
    /**
     * Subtract average of histogram to get scoring function?
     */
    protected boolean subtractAverage = getBoolean("subtractAverage", true);
    /**
     * Allow negative scores (only possible if average subraction is enabled)
     */
    protected boolean allowNegativeScores = getBoolean("allowNegativeScores", true);
    /**
     * while true, coordinates and timestamp of pixels classified as laser line
     * are written to output file
     */
    protected boolean writeLaserlineToFile = getBoolean("writeLaserlineToFile", false);
    /**
     * ALPHA status: give more weigth to most recent histogram
     */
    protected boolean useReinforcement = getBoolean("useReinforcement", false);
    private boolean returnInputPacket = getBoolean("returnInputPacket", false);
    private int laserLineMedianFilterLength = getInt("laserLineMedianFilterLength", 1);
    private boolean laserLineLinearlyInterpolateAcrossNaN = getBoolean("laserLineLinearlyInterpolateAcrossNaN", false);
    private boolean freezeScoreFunction = false; // don't store because score function is not saved to preferences yet

    /**
     * Creates new instance of FilterLaserline
     *
     * The real instantiation is done when filter is activated for the first
     * time (in method #filterPacket)
     *
     * @param chip
     */
    public FilterLaserline(AEChip chip) {
        super(chip);
        final String hi = "Event Histogram", sc = "Pixel Scoring", line = "Laser Line", deb = "Debugging", lg = "Logging";

        setPropertyTooltip(hi, "histogramHistorySize", "How many periods should be used for event histogram?");
        setPropertyTooltip(hi, "binSize", "Bin size of event histogram in us");
        setPropertyTooltip(sc, "pxlScoreHistorySize", "For how many periods should the pixel scores be saved?");
        setPropertyTooltip(sc, "useWeightedOnOff", "Use different weights for on and off events based on their pseudo-SNR?");
        setPropertyTooltip(sc, "subtractAverage", "Subtract average to get bin weight?");
        setPropertyTooltip(sc, "allowNegativeScores", "Allow negativ scores?");
        setPropertyTooltip(sc, "pxlScoreThreshold", "Minimum score of pixel to be on laserline");
        setPropertyTooltip(sc, "useReinforcement", "Use binweights of last period for new binweights");
        setPropertyTooltip(sc, "rollingAverageScoreMapUpdate", "Update the average score map using a rolling cursor that updates a single average map pixel for each input event");
        setPropertyTooltip(sc, "firFilterEnabled", "Use slower FIR average for score map rather than faster IIR filter");
        setPropertyTooltip(deb, "showScoreMap", "Display score of each pixel");
        setPropertyTooltip(lg, "writeLaserlineToFile", "Write laserline to file");
        setPropertyTooltip(deb, "showLaserLine", "Show the extracted laser line: peak location of score histogram for each colurm");
        setPropertyTooltip(deb, "returnInputPacket", "Return the input packet rather than the filtered laser line events to show the input packet");
        setPropertyTooltip(line, "laserLineMedianFilterLength", "<html>Median filter the laser line to remove outliers. <br>Actual median filter length is laserLineMedianFilterLength*2+1; <br>e.g. use 1 for a median filter of length 3. <br>Use 0 for no filtering. <br>NaN values anywhere in filter length are propogated out.");
        setPropertyTooltip(line, "laserLineLinearlyInterpolateAcrossNaN", "<html>Linearly interpolate laser line pixels across NaN values of score map.");
        setPropertyTooltip(deb, "freezeScoreFunction", "Freeze the score function to see effect on performance.");
    }

    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        // set class of output packets to Polarity Events
        checkOutputPacketEventType(in);
        OutputEventIterator outItr = getOutputPacket().outputIterator();
        // iterate over each event in packet
        for (Object e : in) {
            // check if filter is initialized yet
            if (!isInitialized) {
                BasicEvent ev = (BasicEvent) e;
                if (ev.special) {
                    // if new and last laserPeriod do not differ too much from each other 
                    // -> 2 consecutive periods must have about the same length before filter is initialized
                    if (Math.abs(laserPeriod - (ev.timestamp - lastTriggerTimestamp)) < 10) {
                        // Init filter
                        laserPeriod = ev.timestamp - lastTriggerTimestamp;
                        initFilter();
                    } else if (lastTriggerTimestamp > 0) {
                        laserPeriod = ev.timestamp - lastTriggerTimestamp;
                    }
                    lastTriggerTimestamp = ev.timestamp;
                }
            }
            if (isInitialized) {
                PolarityEvent ev = (PolarityEvent) e;
                if (ev.special) {
                    /*
                     * Update pxlScoreMap, histograms, curBinWeights, laserline
                     */
                    pxlScoreMap.updatePxlScoreAverageMap();
                    laserLineNew.update();

                    if (!freezeScoreFunction) {
                        onHist.updateBins();
                        offHist.updateBins();

                        updateBinWeights();
                    }

                    oldLaserLine = pxlScoreMap.updateLaserline(oldLaserLine); // TODO should not be needed with new laser line object

                    // save timestamp as most recent TriggerTimestamp
                    lastTriggerTimestamp = ev.timestamp;

                    // write laserline to out
                    if (!returnInputPacket) {
                        writeLaserlineToOutItr(outItr); // TODO still uses old laser line object
                    }

                    if (writeLaserlineToFile) {
                        // write laserline to file
                        if (laserlineLogfile != null) {
                            laserlineLogfile.write(oldLaserLine, lastTriggerTimestamp);
                        }
                    }
                } else {
                    // if not a special event
                    if (!freezeScoreFunction) {
                        // add to histogram
                        if (ev.polarity == Polarity.On) {
                            onHist.addToData((float) (ev.timestamp - lastTriggerTimestamp));
                        } else if (ev.polarity == Polarity.Off) {
                            offHist.addToData((float) (ev.timestamp - lastTriggerTimestamp));
                        }
                    }

                    // get score of event
                    float pxlScore = scoreEvent(ev);
                    // write score to pxlScoreMap
                    pxlScoreMap.addToScore(ev.x, ev.y, pxlScore);
                }
            }
        }
        return returnInputPacket ? in : getOutputPacket();
    }

    /**
     *
     */
    public void allocateMaps() {
        pxlScoreMap = new PxlScoreMap(chip.getSizeX(), chip.getSizeY(), this);
        oldLaserLine = new ArrayList(2 * chip.getSizeX());
        onHist = new HistogramData(histogramHistorySize, binSize, nBins, this);
        offHist = new HistogramData(histogramHistorySize, binSize, nBins, this);
        curBinWeights = new float[2][nBins];
    }

    @Override
    public void resetFilter() {
        /*
         * only reset when filter is initialized to avoid nullpointer exceptions
         */
        if (isInitialized) {
            pxlScoreMap.resetMap();
            oldLaserLine.clear();
            oldLaserLine.ensureCapacity(chip.getSizeX());
            if (!freezeScoreFunction) {
                onHist.resetHistData();
                offHist.resetHistData();
                Arrays.fill(curBinWeights[0], 0);
                Arrays.fill(curBinWeights[1], 0);
            }
            log.info("FilterLaserline resetted");
        } else {
            // check if arrays are allocated
            if (pxlScoreMap != null) {
                pxlScoreMap.resetMap();
                log.info("Pixelscore map resetted");
            }
            if (oldLaserLine != null) {
                oldLaserLine.clear();
                oldLaserLine.ensureCapacity(chip.getSizeX());
                log.info("Laserline array resetted");
            }
            if (!freezeScoreFunction) {
                if (onHist != null & offHist != null) {
                    onHist.resetHistData();
                    offHist.resetHistData();
                    log.info("Histogram data resetted");
                }
                if (curBinWeights != null) {
                    if (curBinWeights[0] != null & curBinWeights[1] != null) {
                        Arrays.fill(curBinWeights[0], 0);
                        Arrays.fill(curBinWeights[1], 0);
                        log.info("Bin weights resetted");
                    }
                }
            }
        }
    }

    @Override
    public void initFilter() {
        log.log(Level.INFO, "Initializing FilterLaserline, laserPeriod = {0}us", Integer.toString(laserPeriod));
        if (laserPeriod > 0 & binSize > 0) {
            nBins = (int) Math.ceil((float) laserPeriod / binSize);
            log.info("Number of score function bins = " + nBins);
        } else {
            log.severe("either laserPeriod or binSize is not greater than 0");
        }
        allocateMaps();
        pxlScoreMap.initMap();
        isInitialized = true;
        resetFilter();
    }

    private float scoreEvent(PolarityEvent ev) {
        float pxlScore = 0;
        int curBin = (int) ((ev.timestamp - lastTriggerTimestamp) / binSize);

        // check bin to avoid nullpointer exception
        if (curBin >= nBins) {
//            log.warning("bin number to big, omitting event");
            return pxlScore;
        } else if (curBin < 0) {
//            log.warning("bin number to small, omitting event");
            return pxlScore;
        }

        short pol;
        if (ev.polarity == Polarity.On) {
            pol = 0;
        } else {
            pol = 1;
        }

        pxlScore = curBinWeights[pol][curBin];
        return pxlScore;
    }

    private void updateBinWeights() {
        float[][] lastBinWeights = null;
        if (useReinforcement) {
            lastBinWeights = Arrays.copyOf(curBinWeights, nBins);
        }
        curBinWeights[0] = onHist.getNormalized(curBinWeights[0], subtractAverage);
        curBinWeights[1] = offHist.getNormalized(curBinWeights[1], subtractAverage);

        // use maximum on/off score as a weigthing factor (some sort of SNR for each polarity)
        float divisor = onHist.getMaxVal() + offHist.getMaxVal();
        if (divisor == 0) {
            divisor = 1.0f; // avoid divions by 0 (allthough should never happen)
        }
        float onFactor = onHist.getMaxVal() / divisor;
        float offFactor = offHist.getMaxVal() / divisor;

        for (int i = 0; i < nBins; i++) {
            if (useWeightedOnOff) {
                curBinWeights[0][i] *= onFactor;
                curBinWeights[1][i] *= offFactor;
            }
            if (useReinforcement) {
                // ALPHA status
                curBinWeights[0][i] = 0.4f * curBinWeights[0][i] + 0.6f * lastBinWeights[0][i];
                curBinWeights[1][i] = 0.4f * curBinWeights[1][i] + 0.6f * lastBinWeights[1][i];
            }
            if (!allowNegativeScores & curBinWeights[0][i] < 0) {
                curBinWeights[0][i] = 0;
            }
            if (!allowNegativeScores & curBinWeights[1][i] < 0) {
                curBinWeights[1][i] = 0;
            }
        }
    }

    private void writeLaserlineToOutItr(OutputEventIterator outItr) {
        // generate events for all pixels classified as laser line,
        // using the last triggerTimestamp as timestamp for all created events
        for (Object o : oldLaserLine) {
            float[] fpxl = (float[]) o;
            short[] pxl = new short[2];
            pxl[0] = (short) Math.round(fpxl[0]);
            pxl[1] = (short) Math.round(fpxl[1]);
            PolarityEvent outEvent = (PolarityEvent) outItr.nextOutput();
            outEvent.setTimestamp(lastTriggerTimestamp);
            outEvent.setX(pxl[0]);
            outEvent.setY(pxl[1]);
            // really important since address is saved in logfile, not x/y coordinates
            outEvent.setAddress(chip.getEventExtractor().getAddressFromCell(pxl[0], pxl[1], 0));
        }
    }

    int getLastTriggerTimestamp() {
        return this.lastTriggerTimestamp;
    }

    int getLaserPeriod() {
        return this.laserPeriod;
    }

    int getNBins() {
        return this.nBins;
    }

    /**
     * **************************
     * Methods for filter options **************************
     */
    /**
     * gets binSize
     *
     * @return
     */
    public int getBinSize() {
        return this.binSize;
    }

    /**
     * sets binSize
     *
     * @see #getBinSize
     * @param binSize
     */
    synchronized public void setBinSize(int binSize) {
        putInt("binSize", binSize);
        getSupport().firePropertyChange("binSize", this.binSize, binSize);
        isInitialized = false;
        this.binSize = binSize;
        initFilter();
    }

    /**
     *
     * @return
     */
    public int getMinBinSize() {
        return 1;
    }

    /**
     *
     * @return
     */
    public int getMaxBinSize() {
        return 50;
    }

    /**
     * gets histogramWindowSize
     *
     * @return
     */
    public int getHistogramHistorySize() {
        return this.histogramHistorySize;
    }

    /**
     * sets histogramWindowSize
     *
     * @param histogramHistorySize
     * @see #getBinSize
     */
    synchronized public void setHistogramHistorySize(int histogramHistorySize) {
        if (histogramHistorySize < 1) {
            histogramHistorySize = 1;
        }
        putInt("histogramHistorySize", histogramHistorySize);
        getSupport().firePropertyChange("histogramHistorySize", this.histogramHistorySize, histogramHistorySize);
        isInitialized = false;
        this.histogramHistorySize = histogramHistorySize;
        initFilter();
    }

    /**
     *
     * @return
     */
    public int getMinHistogramHistorySize() {
        return 1;
    }

    /**
     *
     * @return
     */
    public int getMaxHistogramHistorySize() {
        return 1000;
    }

    /**
     * gets useWeightedOnOff
     *
     * @return
     */
    public boolean getUseWeightedOnOff() {
        return this.useWeightedOnOff;
    }

    /**
     * sets useWeightedOnOff
     *
     * @see #getUseWeightedOnOff
     * @param useWeightedOnOff boolean
     */
    public void setUseWeightedOnOff(boolean useWeightedOnOff) {
        putBoolean("useWeightedOnOff", useWeightedOnOff);
        getSupport().firePropertyChange("useWeightedOnOff", this.useWeightedOnOff, useWeightedOnOff);
        this.useWeightedOnOff = useWeightedOnOff;
    }

    /**
     * gets useReinforcement
     *
     * @return
     */
    public boolean getUseReinforcement() {
        return this.useReinforcement;
    }

    /**
     * sets useReinforcement
     *
     * @see #getUseReinforcement
     * @param useReinforcement boolean
     */
    public void setUseReinforcement(boolean useReinforcement) {
        putBoolean("useReinforcement", useReinforcement);
        getSupport().firePropertyChange("useReinforcement", this.useReinforcement, useReinforcement);
        this.useReinforcement = useReinforcement;
    }

    /**
     * gets showScoreMap
     *
     * @return
     */
    public boolean getShowScoreMap() {
        return this.showScoreMap;
    }

    /**
     * sets showScoreMap
     *
     * @see #getShowScoreMap
     * @param showScoreMap boolean
     */
    public void setShowScoreMap(boolean showScoreMap) {
        putBoolean("showScoreMap", showScoreMap);
        this.showScoreMap = showScoreMap;
    }

    /**
     * gets pxlScoreThreshold
     *
     * @return pxlScoreThreshold
     */
    public float getPxlScoreThreshold() {
        return this.pxlScoreThreshold;
    }

    /**
     * sets pxlScoreThreshold
     *
     * @see #getPxlScoreThreshold
     * @param pxlScoreThreshold
     */
    public void setPxlScoreThreshold(float pxlScoreThreshold) {
        putFloat("pxlScoreThreshold", pxlScoreThreshold);
        getSupport().firePropertyChange("pxlScoreThreshold", this.pxlScoreThreshold, pxlScoreThreshold);
        this.pxlScoreThreshold = pxlScoreThreshold;
    }

    /**
     *
     * @return
     */
    public float getMinPxlScoreThreshold() {
        return 0;
    }

    /**
     *
     * @return
     */
    public float getMaxPxlScoreThreshold() {
        return 2;
    }

    /**
     * gets subtractAverage
     *
     * @return
     */
    public boolean getSubtractAverage() {
        return this.subtractAverage;
    }

    /**
     * sets subtractAverage
     *
     * @see #getSubtractAverage
     * @param subtractAverage boolean
     */
    public void setSubtractAverage(boolean subtractAverage) {
        putBoolean("subtractAverage", subtractAverage);
        getSupport().firePropertyChange("subtractAverage", this.subtractAverage, subtractAverage);
        this.subtractAverage = subtractAverage;
    }

    /**
     * gets allowNegativeScores
     *
     * @return
     */
    public boolean getAllowNegativeScores() {
        return this.allowNegativeScores;
    }

    /**
     * sets allowNegativeScores
     *
     * @see #getShowScoreMap
     * @param allowNegativeScores boolean
     */
    public void setAllowNegativeScores(boolean allowNegativeScores) {
        putBoolean("allowNegativeScores", allowNegativeScores);
        getSupport().firePropertyChange("allowNegativeScores", this.allowNegativeScores, allowNegativeScores);
        this.allowNegativeScores = allowNegativeScores;
    }

    /**
     * gets pxlScoreHistorySize
     *
     * @return
     */
    public int getPxlScoreHistorySize() {
        return this.pxlScoreHistorySize;
    }

    /**
     * sets pxlScoreHistorySize
     *
     * @see #getPxlScoreHistorySize
     * @param pxlScoreHistorySize
     */
    synchronized public void setPxlScoreHistorySize(int pxlScoreHistorySize) {
        putInt("pxlScoreHistorySize", pxlScoreHistorySize);
        getSupport().firePropertyChange("pxlScoreHistorySize", this.pxlScoreHistorySize, pxlScoreHistorySize);
        isInitialized = false;
        this.pxlScoreHistorySize = pxlScoreHistorySize;
        initFilter();
    }

    /**
     *
     * @return
     */
    public int getMinPxlScoreHistorySize() {
        return 0;
    }

    /**
     *
     * @return
     */
    public int getMaxPxlScoreHistorySize() {
        return 40;
    }

    /**
     * gets writeLaserlineToFile
     *
     * @return
     */
    public boolean getWriteLaserlineToFile() {
        return this.writeLaserlineToFile;
    }

    /**
     * sets writeLaserlineToFile
     *
     * @see #getWriteLaserlineToFile
     * @param writeLaserlineToFile boolean
     */
    public void setWriteLaserlineToFile(boolean writeLaserlineToFile) {
        putBoolean("writeLaserlineToFile", writeLaserlineToFile);
        getSupport().firePropertyChange("writeLaserlineToFile", this.writeLaserlineToFile, writeLaserlineToFile);
        this.writeLaserlineToFile = writeLaserlineToFile;
        if (writeLaserlineToFile) {
            DateFormat loggingFilenameDateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ssZ");
            laserlineLogfile = new LaserlineLogfile(log);
            laserlineLogfile.openFile("C:\\temp\\", "laserline-"
                    + loggingFilenameDateFormat.format(new Date()) + ".txt");
        } else if (!writeLaserlineToFile & laserlineLogfile != null) {
            laserlineLogfile.close();
        }
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        GL gl = drawable.getGL();
        if (pxlScoreMap == null) {
            return;
        }
        if (showScoreMap) {
            pxlScoreMap.draw(gl);
//            gl.glPointSize(4f);
//            gl.glBegin(GL.GL_POINTS);
//            {
//                float pxlScore;
//                for (int x = 0; x < chip.getSizeX(); x++) {
//                    for (int y = 0; y < chip.getSizeY(); y++) {
//                        pxlScore = pxlScoreMap.getScore(x, y);
//
//                        if (pxlScore > 0) {
//                            gl.glColor3d(0.0, 0.0, pxlScore);
//                            gl.glVertex2f(x, y);
//                        } else if (pxlScore < 0) {
//                            gl.glColor3d(0.0, pxlScore, 0.0);
//                            gl.glVertex2f(x, y);
//                        }
//                    }
//
//                }
//            }
//            gl.glEnd();
        }
        if (showLaserLine) {
            laserLineNew.draw(gl);
        }
    }

    /**
     * @return the showLaserLine
     */
    public boolean isShowLaserLine() {
        return showLaserLine;
    }

    /**
     * @param showLaserLine the showLaserLine to set
     */
    public void setShowLaserLine(boolean showLaserLine) {
        this.showLaserLine = showLaserLine;
        putBoolean("showLaserLine", showLaserLine);
    }

    public boolean isFirFilterEnabled() {
        return pxlScoreMap == null ? false : pxlScoreMap.isFirFilterEnabled(); // doesn't exist until maps are allocated, so we need to check
    }

    synchronized public void setFirFilterEnabled(boolean firFilterEnabled) {
        if (pxlScoreMap == null) {
            return;
        }
        pxlScoreMap.setFirFilterEnabled(firFilterEnabled);
    }

    /**
     * @return the returnInputPacket
     */
    public boolean isReturnInputPacket() {
        return returnInputPacket;
    }

    /**
     * @param returnInputPacket the returnInputPacket to set
     */
    public void setReturnInputPacket(boolean returnInputPacket) {
        this.returnInputPacket = returnInputPacket;
        putBoolean("returnInputPacket", returnInputPacket);
    }

    /**
     * @return the laserLineMedianFilterLength
     */
    public int getLaserLineMedianFilterLength() {
        return laserLineMedianFilterLength;
    }

    /**
     * @param laserLineMedianFilterLength the laserLineMedianFilterLength to set
     */
    synchronized public void setLaserLineMedianFilterLength(int laserLineMedianFilterLength) {
        if (laserLineMedianFilterLength < 0) {
            laserLineMedianFilterLength = 0;
        }
        this.laserLineMedianFilterLength = laserLineMedianFilterLength;
        putInt("laserLineMedianFilterLength", laserLineMedianFilterLength);
    }

    /**
     * @return the laserLineLinearlyInterpolateAcrossNaN
     */
    public boolean isLaserLineLinearlyInterpolateAcrossNaN() {
        return laserLineLinearlyInterpolateAcrossNaN;
    }

    /**
     * @param laserLineLinearlyInterpolateAcrossNaN the
     * laserLineLinearlyInterpolateAcrossNaN to set
     */
    synchronized public void setLaserLineLinearlyInterpolateAcrossNaN(boolean laserLineLinearlyInterpolateAcrossNaN) {
        this.laserLineLinearlyInterpolateAcrossNaN = laserLineLinearlyInterpolateAcrossNaN;
        putBoolean("laserLineLinearlyInterpolateAcrossNaN", laserLineLinearlyInterpolateAcrossNaN);
    }

    /**
     * @return the freezeScoreFunction
     */
    public boolean isFreezeScoreFunction() {
        return freezeScoreFunction;
    }

    /**
     * @param freezeScoreFunction the freezeScoreFunction to set
     */
    public void setFreezeScoreFunction(boolean freezeScoreFunction) {
        this.freezeScoreFunction = freezeScoreFunction;
    }

    public boolean isRollingAverageScoreMapUpdate() {
        return pxlScoreMap==null? false:pxlScoreMap.isRollingAverageScoreMapUpdate();
    }

    public void setRollingAverageScoreMapUpdate(boolean rollingAverageScoreMapUpdate) {
        pxlScoreMap.setRollingAverageScoreMapUpdate(rollingAverageScoreMapUpdate);
    }

    /**
     * Holds the determined laser line pixels
     */
    class LaserLine {

        Float[] ys; // the y positions of the line
//        float[] confidences; // the line confidence measure
        int n = 0;

        public LaserLine() {
        }

        void reset() {
            n = chip.getSizeX();
            if (ys == null) {
                ys = new Float[n];
            }
            Arrays.fill(ys, Float.NaN); // fills ys with NaN on reset, which indicate unknown laser line position
//            confidences = new float[n];
        }

        synchronized void draw(GL gl) {
            gl.glPushAttrib(GL.GL_ENABLE_BIT);
            gl.glLineStipple(1, (short) 0x7777);
            gl.glLineWidth(5);
            gl.glColor4f(1, 1, 1, 1f);
            gl.glEnable(GL.GL_LINE_STIPPLE);
            gl.glBegin(GL.GL_LINE_STRIP);
            for (int i = 0; i < n; i++) {
                if (!ys[i].isNaN()) { // skip over columns without valid score
                    gl.glVertex2f(i, ys[i]);
                } else { // interrupt lines at NaN
                    gl.glEnd();
                    gl.glBegin(GL.GL_LINE_STRIP);
                }
            }
            gl.glEnd();
            gl.glPopAttrib();
        }

        private void update() { // TODO awkward, LaserLine should be part of PxlScoreMap or both should be inner classes of FilterLaserline
            if (pxlScoreMap == null) {
                return;
            }
            reset();
            float[][] pxlScore = pxlScoreMap.getPxlScore();
            int mapSizeX = pxlScoreMap.getMapSizeX();
            int mapSizeY = pxlScoreMap.getMapSizeY();
            if (isRollingAverageScoreMapUpdate()) { // statistics are computed during each events update, we don't need to iterate over entire image here
                float[] colSums = pxlScoreMap.getColSums();
                float[] weightedColSums = pxlScoreMap.getWeightedColSums();
                for (int x = 0; x < mapSizeX; x++) {
                    if (weightedColSums[x] > 0) {
                        ys[x] = weightedColSums[x] / colSums[x];
                    }
                }
            } else {
                for (int x = 0; x < mapSizeX; x++) {
                    float sumScores = 0;
                    float sumWeightedCoord = 0;
                    for (int y = 0; y < mapSizeY; y++) {
                        if (pxlScore[x][y] > pxlScoreThreshold) {
                            sumWeightedCoord += (y * pxlScore[x][y]);
                            sumScores += pxlScore[x][y];
//                        y++;
//                        if (y >= mapSizeY) {
//                            break;
//                        }
                        }
                    }
                    if (sumScores > 0) {
                        ys[x] = sumWeightedCoord / sumScores;
                    }
                }
            }
            // debug
//            for(int x=0;x<n;x++){
//                ys[x]=new Float(x);
//            }
////            Arrays.fill(ys, new Float(1));
//            ys[0] = Float.NaN;
//            ys[1] = Float.NaN;
//            ys[2] = Float.NaN;
//            ys[64] = Float.NaN;
////            ys[65] = Float.NaN;
////            ys[66] = Float.NaN;
//            ys[67] = Float.NaN;
//            ys[125] = Float.NaN;
//            ys[126] = Float.NaN;
//            ys[127] = Float.NaN;
            if (laserLineMedianFilterLength > 0) {
                Float[] copy = new Float[n]; // copy is array of references, but no Floats are there yet

                // fill each element of copy with the median value of the ys around each index.
                // if the source value is NaN then leave it NaN
                // if idx is near the ends of the ys array, then fill with source value
                final int k2 = laserLineMedianFilterLength; // truncated to 1 for median filter length of 3
                System.arraycopy(ys, 0, copy, 0, k2); // fill in the ends of the copy
                System.arraycopy(ys, n - k2, copy, n - k2, k2);
                for (int x = k2; x < n - k2; x++) { // e.g. if laserLineMedianFilterLength=3, then from from 1 to n-2
                    if (Float.isNaN(ys[x])) { // if any element is NaN, then output of filter is NaN for all values in range of filter
                        Arrays.fill(copy, x - k2, x + k2 + 1, Float.NaN);
                        x += k2;
                    } else {
                        Float[] part = Arrays.copyOfRange(ys, x - k2, x + k2 + 1); // copy ys around the y value
                        // if the copy contains Float.NaN, the result of sorting are not specified
                        Arrays.sort(part); // sort that part of the array
                        copy[x] = part[k2]; // take middle value, this is median
                    }
                }
                synchronized (this) {
                    System.arraycopy(copy, 0, ys, 0, n); // copy the results back, synchronized with rendering it
                }
            }
            if (isLaserLineLinearlyInterpolateAcrossNaN()) {
                // march accross values. 
                // if we find a NaN value, the substitute with linear interpolation across two surrounding values that are not NaN.
                // for NaN at edges, substitute with edge value
                float y0 = Float.NaN, y1 = Float.NaN;
                for (int x = 0; x < n; x++) {
                    if (!Float.isNaN(ys[x])) {
                        y0 = ys[x];
                        break;
                    }
                }
                for (int x = n - 1; x >= 0; x--) {
                    if (!Float.isNaN(ys[x])) {
                        y1 = ys[x];
                        break;
                    }
                }
                for (int x = 0; x < n; x++) {
                    if (Float.isNaN(ys[x])) {
                        ys[x] = y0;
                        break;
                    }
                }
                for (int x = n - 1; x >= 0; x--) {
                    if (Float.isNaN(ys[x])) {
                        ys[x] = y1;
                        break;
                    }
                }
                // for other ys, substitute with linear interpolation across good values
                y0 = Float.NaN;
                y1 = Float.NaN; // real valued edge values across gap
                for (int x = 0; x < n; x++) {
                    if (!Float.isNaN(ys[x])) {
                        y0 = ys[x]; // if real value save it
                    } else { // we are a NaN 
                        int x0 = x, x1; // start and end indices of gap
                        // find next non NaN
                        while (++x < n && Float.isNaN(ys[x])); // skip gap
                        if (x >= n) {
                            break; // break out if we are at end already
                        }
                        x1 = x; // found real value here
                        y1 = ys[x]; // save it
                        final float d = x1 - x0 + 1; // this is gap length, e.g. x0=0, x1=2, d=3
                        for (int xi = x0; xi < x1; xi++) { // interpolate
                            ys[xi] = y0 + ((xi - x0 + 1) / d) * (y1 - y0); // for each of these x, compute linear interpolation from edge values
                        }
                    }
                }
            }

        }
    }
}