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
    protected int histogramHistorySize = getPrefs().getInt("FilterLaserline.histogramHistorySize", 1000);
    /**
     * Moving average window length
     */
    protected int pxlScoreHistorySize = getPrefs().getInt("FilterLaserline.pxlScoreHistorySize", 3);
    /**
     * binsize for histogram (in us)
     */
    protected int binSize = getPrefs().getInt("FilterLaserline.binSize", 50);
    /**
     * Allows to display the score of each pixel with a score not equal 0
     */
    protected boolean showDebugPixels = getPrefs().getBoolean("FilterLaserline.showDebugPixels", false);
    /**
     * Use different weigths for on and off events?
     */
    protected boolean useWeightedOnOff = getPrefs().getBoolean("FilterLaserline.useWeightedOnOff", true);
    /**
     * All pixels with a score above pxlScoreThreshold are classified as laser
     * line
     */
    protected float pxlScoreThreshold = getPrefs().getFloat("FilterLaserline.pxlScoreThreshold", 1.5f);
    /**
     * Subtract average of histogram to get scoring function?
     */
    protected boolean subtractAverage = getPrefs().getBoolean("FilterLaserline.subtractAverage", true);
    /**
     * Allow negative scores (only possible if average subraction is enabled)
     */
    protected boolean allowNegativeScores = getPrefs().getBoolean("FilterLaserline.allowNegativeScores", true);
    /**
     * while true, coordinates and timestamp of pixels classified as laser line
     * are written to output file
     */
    protected boolean writeLaserlineToFile = getPrefs().getBoolean("FilterLaserline.writeLaserlineToFile", false);
    /**
     * ALPHA status: give more weigth to most recent histogram
     */
    protected boolean useReinforcement = getPrefs().getBoolean("FilterLaserline.useReinforcement", false);
    
    private boolean returnInputPacket=getBoolean("returnInputPacket",false);

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
        final String hi = "Event Histogram", sc = "Pixel Scoring", deb = "Debugging", lg = "Logging";

        setPropertyTooltip(hi, "histogramHistorySize", "How many periods should be used for event histogram?");
        setPropertyTooltip(hi, "binSize", "Bin size of event histogram in us");
        setPropertyTooltip(sc, "pxlScoreHistorySize", "For how many periods should the pixel scores be saved?");
        setPropertyTooltip(sc, "useWeightedOnOff", "Use different weights for on and off events based on their pseudo-SNR?");
        setPropertyTooltip(sc, "subtractAverage", "Subtract average to get bin weight?");
        setPropertyTooltip(sc, "allowNegativeScores", "Allow negativ scores?");
        setPropertyTooltip(sc, "pxlScoreThreshold", "Minimum score of pixel to be on laserline");
        setPropertyTooltip(sc, "useReinforcement", "Use binweights of last period for new binweights");
        setPropertyTooltip(sc, "firFilterEnabled", "Use slower FIR average for score map rather than faster IIR filter");
        setPropertyTooltip(deb, "showDebugPixels", "Display score of each pixel?");
        setPropertyTooltip(lg, "writeLaserlineToFile", "Write laserline to file?");
        setPropertyTooltip(deb, "showLaserLine", "Show the extracted laser line: peak location of score histogram for each colurm");
        setPropertyTooltip(deb, "returnInputPacket", "Return the input packet rather than the filtered laser line events to show the input packet");
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
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

                    onHist.updateBins();
                    offHist.updateBins();

                    updateBinWeights();

                    oldLaserLine = pxlScoreMap.updateLaserline(oldLaserLine);

                    // save timestamp as most recent TriggerTimestamp
                    lastTriggerTimestamp = ev.timestamp;

                    // write laserline to out
                    if(!returnInputPacket) writeLaserlineToOutItr(outItr);

                    if (writeLaserlineToFile) {
                        // write laserline to file
                        if (laserlineLogfile != null) {
                            laserlineLogfile.write(oldLaserLine, lastTriggerTimestamp);
                        }
                    }
                } else {
                    // if not a special event
                    // add to histogram
                    if (ev.polarity == Polarity.On) {
                        onHist.addToData((float) (ev.timestamp - lastTriggerTimestamp));
                    } else if (ev.polarity == Polarity.Off) {
                        offHist.addToData((float) (ev.timestamp - lastTriggerTimestamp));
                    }


                    // get score of event
                    float pxlScore = scoreEvent(ev);
                    // write score to pxlScoreMap
                    pxlScoreMap.addToScore(ev.x, ev.y, pxlScore);
                }
            }
        }
        return returnInputPacket? in:getOutputPacket();
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
            onHist.resetHistData();
            offHist.resetHistData();
            Arrays.fill(curBinWeights[0], 0);
            Arrays.fill(curBinWeights[1], 0);
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

    @Override
    public void initFilter() {
        log.log(Level.INFO, "Initializing FilterLaserline, laserPeriod = {0}us", Integer.toString(laserPeriod));
        if (laserPeriod > 0 & binSize > 0) {
            nBins = (int) Math.ceil((float) laserPeriod / binSize);
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
    public void setBinSize(int binSize) {
        getPrefs().putInt("FilterLaserline.binSize", binSize);
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
        return 1000;
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
    public void setHistogramHistorySize(int histogramHistorySize) {
        getPrefs().putInt("FilterLaserline.histogramWindowSize", histogramHistorySize);
        getSupport().firePropertyChange("histogramWindowSize", this.histogramHistorySize, histogramHistorySize);
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
        return 10000;
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
        getPrefs().putBoolean("FilterLaserline.useWeightedOnOff", useWeightedOnOff);
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
        getPrefs().putBoolean("FilterLaserline.useReinforcement", useReinforcement);
        getSupport().firePropertyChange("useReinforcement", this.useReinforcement, useReinforcement);
        this.useReinforcement = useReinforcement;
    }

    /**
     * gets showDebugPixels
     *
     * @return
     */
    public boolean getShowDebugPixels() {
        return this.showDebugPixels;
    }

    /**
     * sets showDebugPixels
     *
     * @see #getShowDebugPixels
     * @param showDebugPixels boolean
     */
    public void setShowDebugPixels(boolean showDebugPixels) {
        getPrefs().putBoolean("FilterLaserline.showDebugPixels", showDebugPixels);
        getSupport().firePropertyChange("showDebugPixels", this.showDebugPixels, showDebugPixels);
        this.showDebugPixels = showDebugPixels;
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
        getPrefs().putFloat("FilterLaserline.pxlScoreThreshold", pxlScoreThreshold);
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
        getPrefs().putBoolean("FilterLaserline.subtractAverage", subtractAverage);
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
     * @see #getShowDebugPixels
     * @param allowNegativeScores boolean
     */
    public void setAllowNegativeScores(boolean allowNegativeScores) {
        getPrefs().putBoolean("FilterLaserline.allowNegativeScores", allowNegativeScores);
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
    public void setPxlScoreHistorySize(int pxlScoreHistorySize) {
        getPrefs().putInt("FilterLaserline.pxlScoreHistorySize", pxlScoreHistorySize);
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
        return 10;
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
        getPrefs().putBoolean("FilterLaserline.writeLaserlineToFile", writeLaserlineToFile);
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
        if (showLaserLine) {
            laserLineNew.draw(gl);
        }
        if (showDebugPixels) {
            gl.glPointSize(4f);
            gl.glBegin(GL.GL_POINTS);
            {
                float pxlScore;
                for (int x = 0; x < chip.getSizeX(); x++) {
                    for (int y = 0; y < chip.getSizeY(); y++) {
                        pxlScore = pxlScoreMap.getScore(x, y);

                        if (pxlScore > 0) {
                            gl.glColor3d(0.0, 0.0, pxlScore);
                            gl.glVertex2f(x, y);
                        } else if (pxlScore < 0) {
                            gl.glColor3d(0.0, pxlScore, 0.0);
                            gl.glVertex2f(x, y);
                        }
                    }

                }
            }
            gl.glEnd();
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
        putBoolean("showLaserLine",showLaserLine);
    }

    public boolean isFirFilterEnabled() {
        return pxlScoreMap==null? false:pxlScoreMap.isFirFilterEnabled(); // doesn't exist until maps are allocated, so we need to check
    }

    public void setFirFilterEnabled(boolean firFilterEnabled) {
        if(pxlScoreMap==null) return;
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
    
    

    class LaserLine {

        Float[] ys; // the y positions of the line
//        float[] confidences; // the line confidence measure
        int n = 0;

        public LaserLine() {
        }

        void reset() {
            n = chip.getSizeX();
            if(ys==null) ys = new Float[n];
            Arrays.fill(ys, Float.NaN);
//            confidences = new float[n];
        }

        void draw(GL gl) {
            gl.glLineWidth(3);
            gl.glColor3f(1, 1, 1);
            gl.glBegin(GL.GL_LINE_STRIP);
            for (int i = 0; i < n; i++) {
                if (!ys[i].isNaN()) { // skip over columns without valid score
                    gl.glVertex2f(i, ys[i]);
                }
            }
            gl.glEnd();
        }

        private void update() { // TODO awkward, LaserLine should be part of PxlScoreMap or both should be inner classes of FilterLaserline
            if (pxlScoreMap == null) {
                return;
            }
            reset();
            float[][] pxlScore = pxlScoreMap.getPxlScore();
            int mapSizeX = pxlScoreMap.getMapSizeX();
            int mapSizeY = pxlScoreMap.getMapSizeY();
            for (int x = 0; x < mapSizeX; x++) {
                for (int y = 0; y < mapSizeX; y++) {
                    float sumScores = 0;
                    float sumWeightedCoord = 0;
                    while (pxlScore[x][y] > pxlScoreThreshold) {
                        sumWeightedCoord += (y * pxlScore[x][y]);
                        sumScores += pxlScore[x][y];
                        y++;
                        if (y >= mapSizeY) {
                            break;
                        }
                    }
                    if (sumScores > 0) {
                        ys[x] = sumWeightedCoord / sumScores;
                    }
                }
            }

        }
    }
}