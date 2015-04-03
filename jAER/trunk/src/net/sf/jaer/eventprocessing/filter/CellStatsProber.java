/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing.filter;

import java.awt.Font;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseWheelEvent;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Observable;
import java.util.Observer;

import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GL2GL3;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.awt.GLCanvas;

import net.sf.jaer.Description;
import net.sf.jaer.aemonitor.AEConstants;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.ChipCanvas;
import net.sf.jaer.graphics.ChipRendererDisplayMethod;
import net.sf.jaer.graphics.DisplayMethod;
import net.sf.jaer.graphics.DisplayMethod2D;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.EngineeringFormat;
import net.sf.jaer.util.SpikeSound;
import net.sf.jaer.util.filter.LowpassFilter;

import com.jogamp.opengl.util.awt.TextRenderer;
import net.sf.jaer.DevelopmentStatus;

/**
 * Collects and displays statistics for a selected range of pixels / cells.
 *
 * @author tobi
 *
 * This is part of jAER <a
 * href="http://jaerproject.net/">jaerproject.net</a>, licensed under the LGPL (<a
 * href="http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License">http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License</a>.
 */
@Description("Collects and displays statistics for a selected range of pixels / cells")
@DevelopmentStatus(DevelopmentStatus.Status.Stable)
public class CellStatsProber extends EventFilter2D implements FrameAnnotater, MouseListener, MouseMotionListener, Observer {

    public static DevelopmentStatus getDevelopementStatus() {
        return DevelopmentStatus.Beta;
    }
    private GLCanvas glCanvas;
    private ChipCanvas canvas;
    private DisplayMethod displayMethod;
    private ChipRendererDisplayMethod chipRendererDisplayMethod;
    Rectangle selection = null;
    private static float lineWidth = 1f;
    //    private JMenu popupMenu;
    int startx, starty, endx, endy;
    Point startPoint = null, endPoint = null, clickedPoint = null;
    //    private GLUT glut = new GLUT();
    private Stats stats = new Stats();
    private boolean rateEnabled = getBoolean("rateEnabled", true);
    private boolean isiHistEnabled = getBoolean("isiHistEnabled", true);
    private boolean separateEventTypes = getBoolean("separateEventTypes", true);
    private boolean logISIEnabled = getBoolean("logISIEnabled", false);
    private boolean spikeSoundEnabled = getBoolean("spikeSoundEnabled", true);
    private boolean scaleHistogramsIncludingOverflow = getBoolean("scaleHistogramsIncludingOverflow", true);
    SpikeSound spikeSound = null;
    private TextRenderer renderer = null;
    volatile boolean selecting = false;
    volatile float binTime = Float.NaN;
    final private static float[] SELECT_COLOR = {.8f, 0, 0, .5f};
    final private static float[] GLOBAL_HIST_COLOR = {0, 0, .8f, .5f}, INDIV_HIST_COLOR = {0, .2f, .6f, .5f}, HIST_OVERFLOW_COLOR = {.6f, .4f, .2f, .6f};
    private Point currentMousePoint = null;
    private int[] currentAddress = null;
    EngineeringFormat engFmt = new EngineeringFormat();

    public CellStatsProber(AEChip chip) {
        super(chip);
        if ((chip.getCanvas() != null) && (chip.getCanvas().getCanvas() != null)) {
            canvas = chip.getCanvas();
            glCanvas = (GLCanvas) chip.getCanvas().getCanvas();
            renderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 10), true, true);
        }
        currentAddress = new int[chip.getNumCellTypes()];
        Arrays.fill(currentAddress, -1);
        chip.addObserver(this);
        final String h = "ISIs", e = "Event rate";
        setPropertyTooltip(h, "isiHistEnabled", "enable histogramming interspike intervals");
        setPropertyTooltip(h, "isiMinUs", "min ISI in us");
        setPropertyTooltip(h, "isiMaxUs", "max ISI in us");
        setPropertyTooltip(h, "isiAutoScalingEnabled", "autoscale bounds for ISI histogram");
        setPropertyTooltip(h, "isiNumBins", "number of bins in the ISI");
        setPropertyTooltip(h, "showAverageISIHistogram", "shows the average of the individual ISI histograms. The contributing histograms for each pixel are separate for each event type (e.g. ON/OFF)");
        setPropertyTooltip(h, "showIndividualISIHistograms", "show the ISI histograms of all the cells in the selection. Each event type (e.g. ON/OFF) will generate its own histogram");
        setPropertyTooltip(h, "logISIEnabled", "histograms have logarithmically spaced bins rather than linearly spaced bins");

        setPropertyTooltip(e, "rateEnabled", "show measured individual average event rate for selected region in Hz");
        setPropertyTooltip(e, "rateTauMs", "lowpass filter time constant in ms for measuring event rate");
        setPropertyTooltip("spikeSoundEnabled", "enable playing spike sound whenever the selected region has events");
        setPropertyTooltip(h, "individualISIsEnabled", "enables individual ISI statistics for each cell in selection. Disabling lumps all cells into one for ISI computation.");
        setPropertyTooltip(h, "separateEventTypes", "Separate average histogram into individual event types for each pixel. If unchecked, then all event types for a pixel are lumped together for ISIs.");
        setPropertyTooltip(h, "scaleHistogramsIncludingOverflow", "Scales histograms to include overflows for ISIs that are outside of range");

    }

    public void displayStats(GLAutoDrawable drawable) {
        if ((drawable == null) || (selection == null) || (chip.getCanvas() == null)) {
            return;
        }
        canvas = chip.getCanvas();
        glCanvas = (GLCanvas) canvas.getCanvas();
        int sx = chip.getSizeX(), sy = chip.getSizeY();
        Rectangle chipRect = new Rectangle(sx, sy);
        GL2 gl = drawable.getGL().getGL2();
        if (!chipRect.intersects(selection)) {
            return;
        }
        drawSelection(gl, selection, SELECT_COLOR);
        stats.drawStats(drawable);
        stats.play();

    }

    private void getSelection(MouseEvent e) {
        Point p = canvas.getPixelFromMouseEvent(e);
        endPoint = p;
        startx = min(startPoint.x, endPoint.x);
        starty = min(startPoint.y, endPoint.y);
        endx = max(startPoint.x, endPoint.x);
        endy = max(startPoint.y, endPoint.y);
        int w = endx - startx;
        int h = endy - starty;
        selection = new Rectangle(startx, starty, w, h);
    }

    private boolean inSelection(BasicEvent e) {
        if (selection.contains(e.x, e.y)) {
            return true;
        }
        return false;
    }

    public void showContextMenu() {
    }

    private void drawSelection(GL2 gl, Rectangle r, float[] c) {
        gl.glPushMatrix();
        gl.glColor3fv(c, 0);
        gl.glLineWidth(lineWidth);
        gl.glTranslatef(-.5f, -.5f, 0);
        gl.glBegin(GL2.GL_LINE_LOOP);
        gl.glVertex2f(selection.x, selection.y);
        gl.glVertex2f(selection.x + selection.width, selection.y);
        gl.glVertex2f(selection.x + selection.width, selection.y + selection.height);
        gl.glVertex2f(selection.x, selection.y + selection.height);
        gl.glEnd();
        gl.glPopMatrix();

    }

    @Override
    public EventPacket filterPacket(EventPacket in) {
        checkOutputPacketEventType(in); // added to prevent memory leak when iterating ApsDVSEventPacket - tobi
        if (!selecting) {
            stats.collectStats(in);
        }
        return in; // should this be out rather than in for scheme for iterating dvs or apsdvs event packets? - tobi
    }

    @Override
    synchronized public void resetFilter() {
        //        selection = null;
        stats.resetISIs();
    }

    @Override
    public void initFilter() {
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        if (canvas.getDisplayMethod() instanceof DisplayMethod2D) {
            //            chipRendererDisplayMethod = (ChipRendererDisplayMethod) canvas.getDisplayMethod();
            displayStats(drawable);
        }
    }

    /**
     * @return the rateEnabled
     */
    public boolean isRateEnabled() {
        return rateEnabled;
    }

    /**
     * @param rateEnabled the rateEnabled to set
     */
    public void setRateEnabled(boolean rateEnabled) {
        this.rateEnabled = rateEnabled;
        putBoolean("rateEnabled", rateEnabled);
    }

    /**
     * @return the isiHistEnabled
     */
    public boolean isIsiHistEnabled() {
        return isiHistEnabled;
    }

    /**
     * @param isiHistEnabled the isiHistEnabled to set
     */
    public void setIsiHistEnabled(boolean isiHistEnabled) {
        this.isiHistEnabled = isiHistEnabled;
        putBoolean("isiHistEnabled", isiHistEnabled);
    }

    /**
     * @return the spikeSoundEnabled
     */
    public boolean isSpikeSoundEnabled() {
        return spikeSoundEnabled;
    }

    /**
     * @param spikeSoundEnabled the spikeSoundEnabled to set
     */
    public void setSpikeSoundEnabled(boolean spikeSoundEnabled) {
        this.spikeSoundEnabled = spikeSoundEnabled;
        putBoolean("spikeSoundEnabled", spikeSoundEnabled);
    }

    public void mouseWheelMoved(MouseWheelEvent e) {
    }

    @Override
    public void mouseReleased(MouseEvent e) {
        if (startPoint == null) {
            return;
        }
        getSelection(e);
        selecting = false;
        stats.resetISIs();
    }

    private int min(int a, int b) {
        return a < b ? a : b;
    }

    private int max(int a, int b) {
        return a > b ? a : b;
    }

    @Override
    public void mousePressed(MouseEvent e) {
        Point p = canvas.getPixelFromMouseEvent(e);
        startPoint = p;
        selecting = true;
    }

    @Override
    public void mouseMoved(MouseEvent e) {
        currentMousePoint = canvas.getPixelFromMouseEvent(e);
        for (int k = 0; k < chip.getNumCellTypes(); k++) {
            currentAddress[k] = chip.getEventExtractor().getAddressFromCell(currentMousePoint.x, currentMousePoint.y, k);
            //            System.out.println(currentMousePoint+" gives currentAddress["+k+"]="+currentAddress[k]);
        }
    }

    @Override
    public void mouseExited(MouseEvent e) {
        selecting = false;
    }

    @Override
    public void mouseEntered(MouseEvent e) {
    }

    @Override
    public void mouseDragged(MouseEvent e) {
        if (startPoint == null) {
            return;
        }
        getSelection(e);
    }

    @Override
    public void mouseClicked(MouseEvent e) {
        Point p = canvas.getPixelFromMouseEvent(e);
        clickedPoint = p;
    }

    @Override
    public void setSelected(boolean yes) {
        super.setSelected(yes);
        if (glCanvas == null) {
            return;
        }
        if (yes) {
            glCanvas.addMouseListener(this);
            glCanvas.addMouseMotionListener(this);

        } else {
            glCanvas.removeMouseListener(this);
            glCanvas.removeMouseMotionListener(this);
        }
    }

    public void setRateTauMs(float tauMs) {
        stats.setRateTauMs(tauMs);
    }

    public float getRateTauMs() {
        return stats.getRateTauMs();
    }

    public void setIsiNumBins(int isiNumBins) {
        stats.setIsiNumBins(isiNumBins);
    }

    public void setIsiMinUs(int isiMinUs) {
        stats.setIsiMinUs(isiMinUs);
    }

    public void setIsiMaxUs(int isiMaxUs) {
        stats.setIsiMaxUs(isiMaxUs);
    }

    public void setIsiAutoScalingEnabled(boolean isiAutoScalingEnabled) {
        stats.setIsiAutoScalingEnabled(isiAutoScalingEnabled);
    }

    public boolean isIsiAutoScalingEnabled() {
        return stats.isIsiAutoScalingEnabled();
    }

    public void setIndividualISIsEnabled(boolean individualISIsEnabled) {
        stats.setIndividualISIsEnabled(individualISIsEnabled);
    }

    public boolean isIndividualISIsEnabled() {
        return stats.isIndividualISIsEnabled();
    }

    public int getIsiNumBins() {
        return stats.getIsiNumBins();
    }

    public int getIsiMinUs() {
        return stats.getIsiMinUs();
    }

    public int getIsiMaxUs() {
        return stats.getIsiMaxUs();
    }

    public void setShowAverageISIHistogram(boolean showAverageISIHistogram) {
        stats.setShowAverageISIHistogram(showAverageISIHistogram);
    }

    public boolean isShowAverageISIHistogram() {
        return stats.isShowAverageISIHistogram();
    }

    public void setShowIndividualISIHistograms(boolean showIndividualISIHistograms) {
        stats.setShowIndividualISIHistograms(showIndividualISIHistograms);
    }

    public boolean isShowIndividualISIHistograms() {
        return stats.isShowIndividualISIHistograms();
    }

    @Override
    synchronized public void update(Observable o, Object arg) {
        currentAddress = new int[chip.getNumCellTypes()];
        Arrays.fill(currentAddress, -1);
    }

	//    /**
    //     * @return the separateEventTypes
    //     */
    //    public boolean isSeparateEventTypes() {
    //        return separateEventTypes;
    //    }
    //
    //    /**
    //     * @param separateEventTypes the separateEventTypes to set
    //     */
    //    public void setSeparateEventTypes(boolean separateEventTypes) {
    //        this.separateEventTypes = separateEventTypes;
    //        putBoolean("separateEventTypes", separateEventTypes);
    //    }
    /**
     * @return the logISIEnabled
     */
    public boolean isLogISIEnabled() {
        return logISIEnabled;
    }

    /**
     * @param logISIEnabled the logISIEnabled to set
     */
    public void setLogISIEnabled(boolean logISIEnabled) {
        boolean old = this.logISIEnabled;
        if (logISIEnabled != old) {
            stats.resetISIs();
        }
        this.logISIEnabled = logISIEnabled;
        putBoolean("logISIEnabled", logISIEnabled);

    }

    /**
     * @return the scaleHistogramsIncludingOverflow
     */
    public boolean isScaleHistogramsIncludingOverflow() {
        return scaleHistogramsIncludingOverflow;
    }

    /**
     * @param scaleHistogramsIncludingOverflow the
     * scaleHistogramsIncludingOverflow to set
     */
    public void setScaleHistogramsIncludingOverflow(boolean scaleHistogramsIncludingOverflow) {
        this.scaleHistogramsIncludingOverflow = scaleHistogramsIncludingOverflow;
        putBoolean("scaleHistogramsIncludingOverflow", scaleHistogramsIncludingOverflow);
    }

    private class Stats {

        public void setRateTauMs(float tauMs) {
            rateFilter.setTauMs(tauMs);
            putFloat("rateTauMs", tauMs);
        }

        public float getRateTauMs() {
            return rateFilter.getTauMs();
        }
        private int isiMinUs = getInt("isiMinUs", 0),
                isiMaxUs = getInt("isiMaxUs", 100000),
                isiNumBins = getInt("isiNumBins", 100);
        private double logIsiMin = isiMinUs <= 0 ? 0 : Math.log(isiMinUs), logIsiMax = Math.log(isiMaxUs);
		//              private int[] bins = new int[isiNumBins];
        //        private int lessCount = 0, moreCount = 0;
        //        private int maxCount = 0;
        private boolean isiAutoScalingEnabled = getBoolean("isiAutoScalingEnabled", false);
        private boolean individualISIsEnabled = getBoolean("individualISIsEnabled", true);
        private boolean showAverageISIHistogram = getBoolean("showAverageISIHistogram", true);
        private boolean showIndividualISIHistograms = getBoolean("showIndividualISIHistograms", true);

        public LowpassFilter getRateFilter() {
            return rateFilter;
        }
        private LowpassFilter rateFilter = new LowpassFilter();

        {
            rateFilter.setTauMs(getFloat("rateTauMs", 10));
        }
        boolean initialized = false;
        float instantaneousRate = 0, filteredRate = 0;
        int count = 0;
        private HashMap<Integer, ISIHist> histMap = new HashMap();
        ISIHist globalHist = new ISIHist(-1);
        ISIHist[] averageTypeHistograms = null;
        private int nPixels = 0;

        synchronized public void collectStats(EventPacket<BasicEvent> in) {
            if (selection == null) {
                return;
            }
            nPixels = ((selection.width) * (selection.height));
            stats.count = 0;
            for (BasicEvent e : in) {
                if (e.isSpecial()) {
                    continue;
                }
                if (e.isFilteredOut()) {
                    continue; // added to deal with filteredOut events at the end of packets, which are not filtered out by the EventPacket inputIterator()
                }
                if (inSelection(e)) {
                    stats.count++;
                    if (isiHistEnabled) {
                        if (individualISIsEnabled) {
                            ISIHist h = histMap.get(e.address);
                            if (h == null) {
                                h = new ISIHist(e.address);
                                histMap.put(e.address, h);
                                //                                System.out.println("added hist for "+e);
                            }
                            h.addEvent(e);
                        } else {
                            globalHist.addEvent(e);
                        }
                    }
                    globalHist.lastT = e.timestamp;
                }
            }
            if (stats.count > 0) {
                measureAverageEPS(globalHist.lastT, stats.count);
            }
            if (individualISIsEnabled) {
                globalHist.reset();
                for (ISIHist h : histMap.values()) {
                    for (int i = 0; i < isiNumBins; i++) {
                        int v = globalHist.bins[i] += h.bins[i];
                        if (v > globalHist.maxCount) {
                            globalHist.maxCount = v;
                        }
                        globalHist.lessCount += h.lessCount;
                        globalHist.moreCount += h.moreCount;
                        if (scaleHistogramsIncludingOverflow && (globalHist.lessCount > globalHist.maxCount)) {
                            globalHist.maxCount = globalHist.lessCount;
                        }
                        if (scaleHistogramsIncludingOverflow && (globalHist.moreCount > globalHist.maxCount)) {
                            globalHist.maxCount = globalHist.moreCount;
                        }
                    }
                }
            }
        }

        /**
         * @return the showAverageISIHistogram
         */
        public boolean isShowAverageISIHistogram() {
            return showAverageISIHistogram;
        }

        /**
         * @param showAverageISIHistogram the showAverageISIHistogram to set
         */
        public void setShowAverageISIHistogram(boolean showAverageISIHistogram) {
            this.showAverageISIHistogram = showAverageISIHistogram;
            putBoolean("showAverageISIHistogram", showAverageISIHistogram);
        }

        /**
         * @return the showIndividualISIHistograms
         */
        public boolean isShowIndividualISIHistograms() {
            return showIndividualISIHistograms;
        }

        /**
         * @param showIndividualISIHistograms the showIndividualISIHistograms to
         * set
         */
        public void setShowIndividualISIHistograms(boolean showIndividualISIHistograms) {
            this.showIndividualISIHistograms = showIndividualISIHistograms;
            putBoolean("showIndividualISIHistograms", showIndividualISIHistograms);
        }

        private class ISIHist {

            int[] bins = new int[isiNumBins];
            int lessCount = 0, moreCount = 0;
            int maxCount = 0;
            int lastT = 0, prevLastT = 0;
            boolean virgin = true;
            int address = -1;

            public ISIHist(int addr) {
                address = addr;
            }

            void addEvent(BasicEvent e) {
                if (virgin) {
                    lastT = e.timestamp;
                    virgin = false;
                    return;
                }
                int isi = e.timestamp - lastT;
                if (isi < 0) {
                    lastT = e.timestamp; // handle wrapping
                    return;
                }
                if (isiAutoScalingEnabled) {
                    if (isi > isiMaxUs) {
                        setIsiMaxUs(isi);
                    } else if (isi < isiMinUs) {
                        setIsiMinUs(isi);
                    }
                }
                int bin = getIsiBin(isi);
                if (bin < 0) {
                    lessCount++;
                    if (scaleHistogramsIncludingOverflow && (lessCount > maxCount)) {
                        maxCount = lessCount;
                    }
                } else if (bin >= isiNumBins) {
                    moreCount++;
                    if (scaleHistogramsIncludingOverflow && (moreCount > maxCount)) {
                        maxCount = moreCount;
                    }
                } else {
                    int v = ++bins[bin];
                    if (v > maxCount) {
                        maxCount = v;
                    }
                }
                lastT = e.timestamp;
            }

            /**
             * Draws the histogram
             *
             */
            void draw(GL2 gl) {

                float dx = (float) (chip.getSizeX() - 2) / (isiNumBins + 2);
                float sy = (float) (chip.getSizeY() - 2) / maxCount;

                gl.glBegin(GL2.GL_LINES);
                gl.glVertex2f(1, 1);
                gl.glVertex2f(chip.getSizeX() - 1, 1);
                gl.glEnd();

                if (lessCount > 0) {
                    gl.glPushAttrib(GL2GL3.GL_COLOR | GL2.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL2.GL_LINE_STRIP);

                    float y = 1 + (sy * lessCount);
                    float x1 = -dx, x2 = x1 + dx;
                    gl.glVertex2f(x1, 1);
                    gl.glVertex2f(x1, y);
                    gl.glVertex2f(x2, y);
                    gl.glVertex2f(x2, 1);
                    gl.glEnd();
                    gl.glPopAttrib();
                }
                if (moreCount > 0) {
                    gl.glPushAttrib(GL2GL3.GL_COLOR | GL2.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL2.GL_LINE_STRIP);

                    float y = 1 + (sy * moreCount);
                    float x1 = 1 + (dx * (isiNumBins + 2)), x2 = x1 + dx;
                    gl.glVertex2f(x1, 1);
                    gl.glVertex2f(x1, y);
                    gl.glVertex2f(x2, y);
                    gl.glVertex2f(x2, 1);
                    gl.glEnd();
                    gl.glPopAttrib();
                }
                if (maxCount > 0) {
                    gl.glBegin(GL2.GL_LINE_STRIP);
                    for (int i = 0; i < bins.length; i++) {
                        float y = 1 + (sy * bins[i]);
                        float x1 = 1 + (dx * i), x2 = x1 + dx;
                        gl.glVertex2f(x1, 1);
                        gl.glVertex2f(x1, y);
                        gl.glVertex2f(x2, y);
                        gl.glVertex2f(x2, 1);
                    }
                    gl.glEnd();
                }
            }

            void draw(GL2 gl, float lineWidth, float[] color) {
                gl.glPushAttrib(GL2GL3.GL_COLOR | GL2.GL_LINE_WIDTH);
                gl.glLineWidth(lineWidth);
                gl.glColor4fv(color, 0);
                draw(gl);
                gl.glPopAttrib();
            }

            private void reset() {
                if ((bins == null) || (bins.length != isiNumBins)) {
                    bins = new int[isiNumBins];
                } else {
                    Arrays.fill(globalHist.bins, 0);
                }
                lessCount = 0;
                moreCount = 0;
                maxCount = 0;
                virgin = true;
            }
        }

        @Override
        public String toString() {
            return String.format("%10d events, %15s eps", count, engFmt.format(filteredRate));
        }

        /**
         * @param lastT last spike time in us
         * @param n number of events
         */
        private void measureAverageEPS(int lastT, int n) {
            if (!rateEnabled) {
                return;
            }
            final float maxRate = 10e6f;
            if (!initialized) {
                globalHist.prevLastT = lastT;
                initialized = true;
            }
            int dt = lastT - globalHist.prevLastT;
            globalHist.prevLastT = lastT;
            if (dt < 0) {
                initialized = false;
            }
            if (dt == 0) {
                instantaneousRate = maxRate; // if the time interval is zero, use the max rate
            } else {
                instantaneousRate = (1e6f * n) / (dt * AEConstants.TICK_DEFAULT_US);
            }
            filteredRate = rateFilter.filter(instantaneousRate / nPixels, lastT);
        }

        synchronized private void drawStats(GLAutoDrawable drawable) {
            GL2 gl = drawable.getGL().getGL2();

            renderer.begin3DRendering();
			//            renderer.beginRendering(drawable.getWidth(), drawable.getHeight());
            // optionally set the color
            renderer.setColor(1, 1, 1, 0.8f);
            if (rateEnabled) {
                renderer.draw3D(toString(), 1, chip.getSizeY() - 4, 0, .5f); // TODO fix string n lines
            }
            // ... more draw commands, color changes, etc.
            renderer.end3DRendering();

            // draw hist
            if (isiHistEnabled) {
                renderer.draw3D(String.format("%d", isiMinUs), -1, -3, 0, 0.5f);
                renderer.draw3D(String.format("%d", isiMaxUs), chip.getSizeX() - 8, -3, 0, 0.5f);
                renderer.draw3D(logISIEnabled ? "log" : "linear", -15, -3, 0, 0.5f);

                if (individualISIsEnabled) {
                    if (showAverageISIHistogram) {
                        gl.glPushMatrix();
                        globalHist.draw(gl, 2, GLOBAL_HIST_COLOR);
                        gl.glPopMatrix();
                    }
                    if (showIndividualISIHistograms) {
                        int n = histMap.size();
                        gl.glPushMatrix();
                        int k = 0;
                        gl.glLineWidth(1);
                        gl.glColor4fv(INDIV_HIST_COLOR, 0);
                        for (ISIHist h : histMap.values()) {
                            gl.glPushMatrix();
                            gl.glScalef(1, 1f / n, 1); // if n=10 and sy=128 then scale=1/10 scale so that all n fit in viewpoort of chip, each one is scaled to chip size y
                            boolean sel = false;
                            for (int a : currentAddress) {
                                if (a == h.address) {
                                    sel = true;
                                }
                            }
                            if (!sel) {
                                h.draw(gl);
                            } else {
                                h.draw(gl, 1, SELECT_COLOR);
                            }
                            gl.glPopMatrix();
                            gl.glTranslatef(0, (float) chip.getSizeY() / n, 0);
                        }
                        gl.glPopMatrix();
                    }
                } else {
                    globalHist.draw(gl, 1, GLOBAL_HIST_COLOR);
                }
                if (currentMousePoint != null) {
                    if (currentMousePoint.y <= 0) {

                        if (!logISIEnabled) {
                            binTime = (((float) currentMousePoint.x / chip.getSizeX()) * (stats.isiMaxUs - stats.isiMinUs)) + stats.isiMinUs;
                        } else {
                            binTime = (float) Math.exp((((float) currentMousePoint.x / chip.getSizeX()) * (stats.logIsiMax - stats.logIsiMin)) + stats.logIsiMin);
                        }
                        gl.glColor3fv(SELECT_COLOR, 0);
                        renderer.draw3D(String.format("%.0f us", binTime), currentMousePoint.x, -4, 0, .5f);
                        gl.glLineWidth(3);
                        gl.glColor3fv(SELECT_COLOR, 0);
                        gl.glBegin(GL2.GL_LINES);
                        gl.glVertex2f(currentMousePoint.x, 0);
                        gl.glVertex2f(currentMousePoint.x, chip.getSizeY());
                        gl.glEnd();
                    }
                }
            }
        }

        private void play() {
            if (!spikeSoundEnabled) {
                return;
            }
            if (spikeSound == null) {
                spikeSound = new SpikeSound();
            }
            if (count > 0) {
                spikeSound.play();
            }
        }

        /**
         * @return the individualISIsEnabled
         */
        public boolean isIndividualISIsEnabled() {
            return individualISIsEnabled;
        }

        /**
         * @param individualISIsEnabled the individualISIsEnabled to set
         */
        public void setIndividualISIsEnabled(boolean individualISIsEnabled) {
            this.individualISIsEnabled = individualISIsEnabled;
            putBoolean("individualISIsEnabled", individualISIsEnabled);
        }

        /**
         * @return the isiMinUs
         */
        public int getIsiMinUs() {
            return isiMinUs;
        }

        /**
         * @param isiMinUs the isiMinUs to set
         */
        synchronized public void setIsiMinUs(int isiMinUs) {
            if (this.isiMinUs == isiMinUs) {
                return;
            }
            int old = this.isiMinUs;
            this.isiMinUs = isiMinUs;
            logIsiMin = isiMinUs <= 0 ? 0 : Math.log(isiMinUs);
            logIsiMax = Math.log(isiMaxUs);
            if (isiAutoScalingEnabled) {
                getSupport().firePropertyChange("isiMinUs", old, isiMinUs);
            } else {
                putInt("isiMinUs", isiMinUs);
            }
            resetISIs();
        }

        /**
         * @return the isiMaxUs
         */
        public int getIsiMaxUs() {
            return isiMaxUs;
        }

        /**
         * @param isiMaxUs the isiMaxUs to set
         */
        synchronized public void setIsiMaxUs(int isiMaxUs) {
            if (this.isiMaxUs == isiMaxUs) {
                return;
            }
            int old = this.isiMaxUs;
            this.isiMaxUs = isiMaxUs;
            logIsiMax = Math.log(isiMaxUs);
            if (isiAutoScalingEnabled) {
                getSupport().firePropertyChange("isiMaxUs", old, isiMaxUs);
            } else {
                putInt("isiMaxUs", isiMaxUs);
            }
            resetISIs();
        }

        synchronized private void resetISIs() {
            globalHist.reset();
            histMap.clear();
        }

        private int getIsiBin(int isi) {
            if (isi < isiMinUs) {
                return -1;
            } else if (isi > isiMaxUs) {
                return isiNumBins;
            } else {
                if (!logISIEnabled) {
                    int binSize = (isiMaxUs - isiMinUs) / isiNumBins;
                    if (binSize <= 0) {
                        return -1;
                    }
                    return (isi - isiMinUs) / binSize;
                } else {
                    double logISI = isi <= 0 ? 0 : Math.log(isi);
                    double binSize = (logIsiMax - logIsiMin) / isiNumBins;
                    if (binSize <= 0) {
                        return -1;
                    }
                    return (int) Math.floor((logISI - logIsiMin) / binSize);
                }
            }
        }

        /**
         * @return the isiNumBins
         */
        public int getIsiNumBins() {
            return isiNumBins;
        }

        /**
         * @param isiNumBins the isiNumBins to set
         */
        synchronized public void setIsiNumBins(int isiNumBins) {
            if (isiNumBins == this.isiNumBins) {
                return;
            }
            int old = this.isiNumBins;
            if (isiNumBins < 1) {
                isiNumBins = 1;
            }
            this.isiNumBins = isiNumBins;
            resetISIs();
            putInt("isiNumBins", isiNumBins);
            getSupport().firePropertyChange("isiNumBins", old, isiNumBins);
        }

        /**
         * @return the isiAutoScalingEnabled
         */
        public boolean isIsiAutoScalingEnabled() {
            return isiAutoScalingEnabled;
        }

        /**
         * @param isiAutoScalingEnabled the isiAutoScalingEnabled to set
         */
        synchronized public void setIsiAutoScalingEnabled(boolean isiAutoScalingEnabled) {
            this.isiAutoScalingEnabled = isiAutoScalingEnabled;
            putBoolean("isiAutoScalingEnabled", isiAutoScalingEnabled);
        }
    }
}
