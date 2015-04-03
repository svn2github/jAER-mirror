/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing.filter;

import java.awt.Font;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.util.Arrays;
import java.util.Observable;
import java.util.Observer;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.awt.GLCanvas;
import com.jogamp.opengl.fixedfunc.GLMatrixFunc;

import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2DMouseAdaptor;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.graphics.ChipCanvas;
import net.sf.jaer.graphics.DisplayMethod2D;
import net.sf.jaer.graphics.FrameAnnotater;
import net.sf.jaer.util.EngineeringFormat;
import ch.unizh.ini.jaer.projects.davis.frames.ApsFrameExtractor;

import com.jogamp.opengl.util.awt.TextRenderer;

/**
 * Displays noise statistics for APS frames from DAVIS sensors.
 *
 * @author tobi
 */
@Description("Collects and displays APS noise statistics for a selected range of pixels")
public class ApsNoiseStatistics extends EventFilter2DMouseAdaptor implements FrameAnnotater, Observer {

    ApsFrameExtractor frameExtractor;
//    private int numFramesToAverage = getInt("numFramesToAverage", 10);
    public boolean temporalNoiseEnabled = getBoolean("temporalNoiseEnabled", true);
    public boolean spatialHistogramEnabled = getBoolean("spatialHistogramEnabled", true);
    public boolean scaleHistogramsIncludingOverflow = getBoolean("scaleHistogramsIncludingOverflow", true);
    public int histNumBins = getInt("histNumBins", 30);
    int startx, starty, endx, endy;
    private Point startPoint = null, endPoint = null, clickedPoint = null;
    protected Rectangle selectionRectangle = null;
    private static float lineWidth = 1f;
    private GLCanvas glCanvas;
    private ChipCanvas canvas;
    volatile boolean selecting = false;
    private Point currentMousePoint = null;
    private int[] currentAddress = null;
    EngineeringFormat engFmt = new EngineeringFormat();
    final private static float[] SELECT_COLOR = {.8f, 0, 0, .5f};
    private TextRenderer renderer = null;
    PixelStatistics stats = new PixelStatistics();
    final private static float[] GLOBAL_HIST_COLOR = {0, 0, .8f, .5f}, INDIV_HIST_COLOR = {0, .2f, .6f, .5f}, HIST_OVERFLOW_COLOR = {.6f, .4f, .2f, .6f};
    private int frameWidth, frameHeight; // set from frame extractor filter
//    private final Lock lock = new ReentrantLock(); // used to prevent open GL calls during mouse event handling at the same time as opengl rendering
    final float textScale = .3f;
    private boolean resetCalled = true;

    public ApsNoiseStatistics(AEChip chip) {
        super(chip);
        if ((chip.getCanvas() != null) && (chip.getCanvas().getCanvas() != null)) {
            canvas = chip.getCanvas();
            glCanvas = (GLCanvas) chip.getCanvas().getCanvas();
            renderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 24), true, true);
        }
        currentAddress = new int[chip.getNumCellTypes()];
        Arrays.fill(currentAddress, -1);
        frameExtractor = new ApsFrameExtractor(chip);
        FilterChain chain = new FilterChain(chip);
        chain.add(frameExtractor);
        setEnclosedFilterChain(chain);
        chip.addObserver(this);
        setPropertyTooltip("scaleHistogramsIncludingOverflow", "Scales histograms to include overflows for ISIs that are outside of range");
        setPropertyTooltip("histNumBins", "number of bins in the spatial (FPN) histogram");
        setPropertyTooltip("spatialHistogramEnabled", "shows the spatial (FPN) histogram for mouse-selected region");
        setPropertyTooltip("temporalNoiseEnabled", "<html>shows the temporal noise (AC RMS) of pixels in mouse-selected region. <br> The AC RMS is computed for each pixel separately and the grand average AC RMS is displayed.");
    }

    @Override
    public void annotate(GLAutoDrawable drawable) {
        if (canvas.getDisplayMethod() instanceof DisplayMethod2D) {
            displayStats(drawable);
        }
    }

    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        frameWidth = frameExtractor.getWidth();
        frameHeight = frameExtractor.getHeight();
        frameExtractor.filterPacket(in);
        if (frameExtractor.hasNewFrame()) {
            if (resetCalled) {
//                frameExtractor.resetFilter(); // TODO we cannot call this before getting frame, because then frame will be set to zero in the frameExtractor and we'll get zeros
                stats.reset();
                resetCalled = false;
            }
            float[] frame = frameExtractor.getDisplayBuffer();
            stats.updateStatistics(frame);
        }
        return in;
    }

    public void displayStats(GLAutoDrawable drawable) {
        synchronized (glCanvas) { // sync on mouse listeners that call opengl methods
            if ((drawable == null) || (getSelectionRectangle() == null) || (chip.getCanvas() == null)) {
                return;
            }
            canvas = chip.getCanvas();
            glCanvas = (GLCanvas) canvas.getCanvas();
            int sx = chip.getSizeX(), sy = chip.getSizeY();
            Rectangle chipRect = new Rectangle(sx, sy);
            GL2 gl = drawable.getGL().getGL2();
            if (!chipRect.intersects(selectionRectangle)) {
                return;
            }
            drawSelectionRectangle(gl, getSelectionRectangle(), SELECT_COLOR);
            stats.draw(gl);
        }
    }

    /**
     * gets the selected region of pixels from the endpoint mouse event that is
     * passed in.
     *
     * @param e the endpoint (rectangle corner) of the selectionRectangle
     * rectangle
     */
    private void setSelectionRectangleFromMouseEvent(MouseEvent e) {
        Point p = getMousePoint(e);
        endPoint = p;
        startx = min(startPoint.x, endPoint.x);
        starty = min(startPoint.y, endPoint.y);
        endx = max(startPoint.x, endPoint.x);
        endy = max(startPoint.y, endPoint.y);
        int w = endx - startx;
        int h = endy - starty;
        setSelectionRectangle(new Rectangle(startx, starty, w, h));
    }

    /**
     * tests if address is in selectionRectangle
     *
     * @param e an event
     * @return true if rectangle contains the event (is strictly inside the
     * rectangle)
     */
    private boolean isInSelectionRectangle(BasicEvent e) {
        if (getSelectionRectangle().contains(e.x, e.y)) {
            return true;
        }
        return false;
    }

    /**
     * draws selectionRectangle rectangle on annotation
     *
     * @param gl GL context
     * @param r the rectangle
     * @param c the 3 vector RGB color to draw rectangle
     */
    private void drawSelectionRectangle(GL2 gl, Rectangle r, float[] c) {
        gl.glPushMatrix();
        gl.glColor3fv(c, 0);
        gl.glLineWidth(lineWidth);
        gl.glTranslatef(-.5f, -.5f, 0);
        gl.glBegin(GL.GL_LINE_LOOP);
        gl.glVertex2f(getSelectionRectangle().x, getSelectionRectangle().y);
        gl.glVertex2f(getSelectionRectangle().x + getSelectionRectangle().width, getSelectionRectangle().y);
        gl.glVertex2f(getSelectionRectangle().x + getSelectionRectangle().width, getSelectionRectangle().y + getSelectionRectangle().height);
        gl.glVertex2f(getSelectionRectangle().x, getSelectionRectangle().y + getSelectionRectangle().height);
        gl.glEnd();
        gl.glPopMatrix();

    }

    @Override
    synchronized public void resetFilter() {
        resetCalled = true;  // to handle reset during some point of iteration that gets partial new frame or something strange

    }

    @Override
    public void initFilter() {
    }

    private int min(int a, int b) {
        return a < b ? a : b;
    }

    private int max(int a, int b) {
        return a > b ? a : b;
    }

    private float min(float a, float b) {
        return a < b ? a : b;
    }

    private float max(float a, float b) {
        return a > b ? a : b;
    }

    private double min(double a, double b) {
        return a < b ? a : b;
    }

    private double max(double a, double b) {
        return a > b ? a : b;
    }

    /**
     * Sets the selection rectangle
     *
     * @param e
     */
    @Override
    public void mouseReleased(MouseEvent e) {
        if (startPoint == null) {
            return;
        }
        setSelectionRectangleFromMouseEvent(e);
        selecting = false;
    }

    /**
     * Starts the selection rectangle
     *
     * @param e
     */
    @Override
    public void mousePressed(MouseEvent e) {
        Point p = getMousePoint(e);
        startPoint = p;
        selecting = true;
    }

    /**
     * Sets the currentMousePoint and currentAddress[] array
     *
     * @param e
     */
    @Override
    public void mouseMoved(MouseEvent e) {
        currentMousePoint = getMousePoint(e);
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

    /**
     * Sets the selection rectangle
     *
     * @param e
     */
    @Override
    public void mouseDragged(MouseEvent e) {
        if (startPoint == null) {
            return;
        }
        setSelectionRectangleFromMouseEvent(e);
    }

    /**
     * Sets the clickedPoint field
     *
     * @param e
     */
    @Override
    public void mouseClicked(MouseEvent e) {
        Point p = getMousePoint(e);
        clickedPoint = p;
    }

    /**
     * Overridden so that when this EventFilter2D is selected/deselected to be
     * controlled in the FilterPanel the mouse listeners are installed/removed
     *
     * @param yes
     */
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

    /**
     * Called when the chip size is known
     *
     * @param o
     * @param arg
     */
    @Override
    synchronized public void update(Observable o, Object arg) {
        currentAddress = new int[chip.getNumCellTypes()];
        Arrays.fill(currentAddress, -1);
        frameExtractor.resetFilter();
    }

    /**
     * @return the selectionRectangle
     */
    public Rectangle getSelectionRectangle() {
        return selectionRectangle;
    }

    /**
     * @param selectionRectangle the selectionRectangle to set
     */
    synchronized public void setSelectionRectangle(Rectangle selectionRectangle) {
        if ((this.selectionRectangle == null) || !this.selectionRectangle.equals(selectionRectangle)) {
            stats.reset();
        }
        this.selectionRectangle = selectionRectangle;
    }

    private Point getMousePoint(MouseEvent e) {
        synchronized (glCanvas) { // sync here on opengl canvas because getPixelFromMouseEvent calls opengl and we don't want that during rendering
            return canvas.getPixelFromMouseEvent(e);
        }
    }

    /**
     * Keeps track of pixel statistics
     */
    class PixelStatistics {

        APSHist apsHist = new APSHist();
        TemporalNoise temporalNoise = new TemporalNoise();

        public PixelStatistics() {
        }

        /**
         * draws all statistics
         */
        void draw(GL2 gl) {

            apsHist.draw(gl);
            temporalNoise.draw(gl);
            if (currentMousePoint != null) {
                if (currentMousePoint.y <= 0) {
                    float sampleValue = ((float) currentMousePoint.x / chip.getSizeX()) * frameExtractor.getMaxADC();
                    gl.glColor3fv(SELECT_COLOR, 0);
                    renderer.begin3DRendering();
                    renderer.draw3D(String.format("%.0f", sampleValue), currentMousePoint.x, -4, 0, textScale);
                    renderer.end3DRendering();
                    gl.glLineWidth(3);
                    gl.glColor3fv(SELECT_COLOR, 0);
                    gl.glBegin(GL.GL_LINES);
                    gl.glVertex2f(currentMousePoint.x, 0);
                    gl.glVertex2f(currentMousePoint.x, chip.getSizeY());
                    gl.glEnd();
                }
            }
        }

        void reset() {
            apsHist.reset();
            temporalNoise.reset();
        }

        void updateStatistics(float[] frame) {
            if (selecting || (selectionRectangle == null)) {
                return; // don't bother if we haven't selected a region TODO maybe do entire frame
            }
            // itereate over pixels of selection rectangle to get pixels from frame
            int selx = 0, sely = 0, selIdx = 0;
            for (int x = selectionRectangle.x; x < (selectionRectangle.x + selectionRectangle.width); x++) {
                for (int y = selectionRectangle.y; y < (selectionRectangle.y + selectionRectangle.height); y++) {
                    int idx = frameExtractor.getIndex(x, y);
                    if (idx >= frame.length) {
//                        log.warning(String.format("index out of range: x=%d y=%d, idx=%d frame.length=%d", x, y, idx, frame.length));
                        return;
                    }
                    int sample = Math.round(frame[idx]);
                    if (spatialHistogramEnabled) {
                        apsHist.addSample(sample);
                    }
                    if (temporalNoiseEnabled) {
                        temporalNoise.addSample(selIdx, sample);
                    }
                    sely++;
                    selIdx++;
                }
                selx++;
            }
            if (temporalNoiseEnabled) {
                temporalNoise.compute();
            }
        }

        private class TemporalNoise {

            private double[] sums, sum2s, means, vars; // variance computations for pixels, each entry is one pixel cummulation
            private int[] pixelSampleCounts; // how many times each pixel has been sampled (should be same for all pixels)
            int nPixels = 0; // total number of pixels
            double mean = 0, var = 0, rmsAC = 0;
            double meanvar = 0;
            double meanmean = 0;
            double minmean, maxmean, minvar, maxvar;

            /**
             * Adds one pixel sample to temporal noise statistics
             *
             * @param idx indext of pixel
             * @param sample sample value
             */
            synchronized void addSample(int idx, int sample) {
                if (idx >= sums.length) {
                    return; // TODO some problem with selecting rectangle which gives 1x1 rectangle sometimes
                }
                sums[idx] += sample;
                sum2s[idx] += sample * sample;
                pixelSampleCounts[idx]++;
            }

            /**
             * computes temporal noise stats from collected pixel sample values
             */
            synchronized void compute() {
                if (pixelSampleCounts == null) {
                    return;
                }
                float sumvar = 0, summean = 0;
                minmean = Float.POSITIVE_INFINITY;
                minvar = Float.POSITIVE_INFINITY;
                maxmean = Float.NEGATIVE_INFINITY;
                maxvar = Float.NEGATIVE_INFINITY;
                // computes means and variances for each pixel over all frames
                for (int i = 0; i < pixelSampleCounts.length; i++) {
                    if (pixelSampleCounts[i] < 2) {
                        continue;
                    }
                    means[i] = sums[i] / pixelSampleCounts[i];
                    vars[i] = (sum2s[i] - ((sums[i] * sums[i]) / pixelSampleCounts[i])) / (pixelSampleCounts[i] - 1);
//                    if (vars[i] > 1000) {
//                        log.warning("suspiciously high variance");
//                    }
                }
                // compute grand averages
                for (int i = 0; i < pixelSampleCounts.length; i++) {
                    sumvar += vars[i];
                    summean += means[i];
                    minmean = min(means[i], minmean);
                    maxmean = max(means[i], maxmean);
                    minvar = min(vars[i], minvar);
                    maxvar = max(vars[i], maxvar);
                }
                meanvar = sumvar / pixelSampleCounts.length;
                meanmean = summean / pixelSampleCounts.length;
                rmsAC = (float) Math.sqrt(sumvar / pixelSampleCounts.length);
                nPixels = pixelSampleCounts.length;
            }

            synchronized void reset() {
                if (selectionRectangle == null) {
                    return;
                }
                nPixels = 0;
                final int length = selectionRectangle.width * selectionRectangle.height;
                if ((sums == null) || (sums.length != length)) {
                    sums = new double[length];
                    sum2s = new double[length];
                    means = new double[length];
                    vars = new double[length];
                    pixelSampleCounts = new int[length];
                } else {
                    Arrays.fill(sums, 0);
                    Arrays.fill(sum2s, 0);
                    Arrays.fill(means, 0);
                    Arrays.fill(vars, 0);
                    Arrays.fill(pixelSampleCounts, 0);
                }
            }

            /**
             * Draws the temporal noise statistics, including global averages
             * and plot of var vs mean
             */
            synchronized void draw(GL2 gl) {
                if (!temporalNoiseEnabled || (selectionRectangle == null) || (means == null) || (vars == null)) {
                    return;
                }
                renderer.setSmoothing(true);
                final float offset = .1f;
                final float x0 = chip.getSizeX() * offset, y0 = chip.getSizeY() * offset, x1 = chip.getSizeX() * (1 - offset), y1 = chip.getSizeY() * (1 - offset);

                // overall statistics
                String s = String.format("Temporal noise: %.1f+/-%.2f var=%.1f COV=%.1f%% N=%d", meanmean, rmsAC, meanvar, (100 * rmsAC) / meanmean, nPixels);
                renderer.begin3DRendering();
                renderer.setColor(GLOBAL_HIST_COLOR[0], GLOBAL_HIST_COLOR[1], GLOBAL_HIST_COLOR[2], 1f);
                renderer.draw3D(s, 1.5f * x0, y1, 0, textScale);
                renderer.end3DRendering();
                // draw plot
                gl.glLineWidth(lineWidth);
                gl.glColor3fv(GLOBAL_HIST_COLOR, 0);
                // axes
                gl.glBegin(GL.GL_LINES);
                gl.glVertex2f(x0, y0);
                gl.glVertex2f(x1, y0);
                gl.glVertex2f(x0, y0);
                gl.glVertex2f(x0, y1);
                gl.glEnd();
                // axes labels
                renderer.begin3DRendering();
                renderer.setColor(GLOBAL_HIST_COLOR[0], GLOBAL_HIST_COLOR[1], GLOBAL_HIST_COLOR[2], 1f);
                renderer.draw3D("signal", (x0 + x1) / 2, y0 / 2, 0, textScale);
                renderer.end3DRendering();
                gl.glMatrixMode(GLMatrixFunc.GL_MODELVIEW);
                gl.glPushMatrix();
                gl.glTranslatef(x0 / 2, (y0 + y1) / 2, 0);
//                gl.glRotatef(90,0,0, 0); // TODO doesn't work to rotate axes label
                renderer.begin3DRendering();
                renderer.draw3D("variance", 0, 0, 0, textScale);
                renderer.end3DRendering();
                gl.glPopMatrix();
                // axes limits
                renderer.begin3DRendering();
                renderer.setColor(GLOBAL_HIST_COLOR[0], GLOBAL_HIST_COLOR[1], GLOBAL_HIST_COLOR[2], 1f);
                renderer.draw3D(String.format("%.1f", minvar), x0 / 2, y0, 0, textScale);
                renderer.draw3D(String.format("%.1f", maxvar), x0 / 2, y1, 0, textScale);
                renderer.draw3D(String.format("%.1f", minmean), x0, y0 / 2, 0, textScale);
                renderer.draw3D(String.format("%.1f", maxmean), x1, y0 / 2, 0, textScale);
                renderer.end3DRendering();

                // data points
                gl.glPointSize(6);
                gl.glBegin(GL.GL_POINTS);
                final double meanrange = maxmean - minmean;
                final double varrange = maxvar - minvar;
                for (int i = 0; i < means.length; i++) {
                    final double x = x0 + (((x1 - x0) * (means[i] - minmean)) / meanrange);
                    final double y = y0 + (((y1 - y0) * (vars[i] - minvar)) / varrange);
                    gl.glVertex2d(x, y);
                }

                gl.glEnd();
            }
        }

        private class APSHist {

            int[] bins = new int[histNumBins];
            int lessCount = 0, moreCount = 0;
            int maxCount = 0;
            boolean virgin = true;
            int sampleMin = 0, sampleMax = 1023;

            public APSHist() {
            }

            void addSample(int sample) {
                int bin = getSampleBin(sample);
                if (bin < 0) {
                    lessCount++;
                    if (scaleHistogramsIncludingOverflow && (lessCount > maxCount)) {
                        maxCount = lessCount;
                    }
                } else if (bin >= histNumBins) {
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
            }

            /**
             * Draws the histogram
             *
             */
            void draw(GL2 gl) {
                if (!spatialHistogramEnabled) {
                    return;
                }
                float dx = (float) (chip.getSizeX() - 2) / (histNumBins + 2);
                float sy = (float) (chip.getSizeY() - 2) / maxCount;

                gl.glBegin(GL.GL_LINES);
                gl.glVertex2f(1, 1);
                gl.glVertex2f(chip.getSizeX() - 1, 1);
                gl.glEnd();

                if (lessCount > 0) {
                    gl.glPushAttrib(GL2.GL_COLOR | GL.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL.GL_LINE_STRIP);

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
                    gl.glPushAttrib(GL2.GL_COLOR | GL.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL.GL_LINE_STRIP);

                    float y = 1 + (sy * moreCount);
                    float x1 = 1 + (dx * (histNumBins + 2)), x2 = x1 + dx;
                    gl.glVertex2f(x1, 1);
                    gl.glVertex2f(x1, y);
                    gl.glVertex2f(x2, y);
                    gl.glVertex2f(x2, 1);
                    gl.glEnd();
                    gl.glPopAttrib();
                }
                if (maxCount > 0) {
                    gl.glBegin(GL.GL_LINE_STRIP);
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
                gl.glPushAttrib(GL2.GL_COLOR | GL.GL_LINE_WIDTH);
                gl.glLineWidth(lineWidth);
                gl.glColor4fv(color, 0);
                draw(gl);
                gl.glPopAttrib();
            }

            private void reset() {
                if ((bins == null) || (bins.length != histNumBins)) {
                    bins = new int[histNumBins];
                } else {
                    Arrays.fill(bins, 0);
                }
                lessCount = 0;
                moreCount = 0;
                maxCount = 0;
                virgin = true;
            }

            private int getSampleBin(int sample) {
                int bin = (int) Math.floor((histNumBins * ((float) sample - sampleMin)) / (sampleMax - sampleMin));
                return bin;
            }
        }
    }

    /**
     * @return the temporalNoiseEnabled
     */
    public boolean isTemporalNoiseEnabled() {
        return temporalNoiseEnabled;
    }

    /**
     * @param temporalNoiseEnabled the temporalNoiseEnabled to set
     */
    public void setTemporalNoiseEnabled(boolean temporalNoiseEnabled) {
        this.temporalNoiseEnabled = temporalNoiseEnabled;
        putBoolean("temporalNoiseEnabled", temporalNoiseEnabled);
    }

    /**
     * @return the spatialHistogramEnabled
     */
    public boolean isSpatialHistogramEnabled() {
        return spatialHistogramEnabled;
    }

    /**
     * @param spatialHistogramEnabled the spatialHistogramEnabled to set
     */
    public void setSpatialHistogramEnabled(boolean spatialHistogramEnabled) {
        this.spatialHistogramEnabled = spatialHistogramEnabled;
        putBoolean("spatialHistogramEnabled", spatialHistogramEnabled);
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

    /**
     * @return the histNumBins
     */
    public int getHistNumBins() {
        return histNumBins;
    }

    /**
     * @param histNumBins the histNumBins to set
     */
    synchronized public void setHistNumBins(int histNumBins) {
        if (histNumBins < 2) {
            histNumBins = 2;
        } else if (histNumBins > (frameExtractor.getMaxADC() + 1)) {
            histNumBins = frameExtractor.getMaxADC() + 1;
        }
        this.histNumBins = histNumBins;
        putInt("histNumBins", histNumBins);
        stats.reset();
    }
}
