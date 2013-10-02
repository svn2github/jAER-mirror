/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing.filter;

import ch.unizh.ini.jaer.projects.davis.frames.ApsFrameExtractor;
import com.sun.opengl.util.j2d.TextRenderer;
import java.awt.Font;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.util.Arrays;
import java.util.Observable;
import java.util.Observer;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLCanvas;
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

    public ApsNoiseStatistics(AEChip chip) {
        super(chip);
        if (chip.getCanvas() != null && chip.getCanvas().getCanvas() != null) {
            canvas = chip.getCanvas();
            glCanvas = (GLCanvas) chip.getCanvas().getCanvas();
            renderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 10), true, true);
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
        } else if (histNumBins > frameExtractor.getMaxADC()+1) {
            histNumBins = frameExtractor.getMaxADC()+1;
        }
        this.histNumBins = histNumBins;
        putInt("histNumBins", histNumBins);
        stats.reset();
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
            float[] frame = frameExtractor.getDisplayBuffer();
            stats.updateStatistics(frame);
        }
        return in;
    }

    public void displayStats(GLAutoDrawable drawable) {
        if (drawable == null || getSelectionRectangle() == null || chip.getCanvas() == null) {
            return;
        }
        canvas = chip.getCanvas();
        glCanvas = (GLCanvas) canvas.getCanvas();
        int sx = chip.getSizeX(), sy = chip.getSizeY();
        Rectangle chipRect = new Rectangle(sx, sy);
        GL gl = drawable.getGL();
        if (!chipRect.intersects(selectionRectangle)) {
            return;
        }
        drawSelectionRectangle(gl, getSelectionRectangle(), SELECT_COLOR);
        stats.draw(gl);
    }

    /**
     * gets the selected region of pixels from the endpoint mouse event that is
     * passed in.
     *
     * @param e the endpoint (rectangle corner) of the selectionRectangle
     * rectangle
     */
    private void setSelectionRectangleFromMouseEvent(MouseEvent e) {
        Point p = canvas.getPixelFromMouseEvent(e);
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
    private void drawSelectionRectangle(GL gl, Rectangle r, float[] c) {
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
    public void resetFilter() {
        frameExtractor.resetFilter();
        stats.reset();
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
        Point p = canvas.getPixelFromMouseEvent(e);
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
        Point p = canvas.getPixelFromMouseEvent(e);
        clickedPoint = p;
    }

    /**
     * Overridden so that when this EventFilter2D is selected/deselected to be
     * controlled in the FilterPanel the mouse listensers are installed/removed
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
    public void setSelectionRectangle(Rectangle selectionRectangle) {
        if (this.selectionRectangle == null || !this.selectionRectangle.equals(selectionRectangle)) {
            stats.reset();
        }
        this.selectionRectangle = selectionRectangle;
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
        void draw(GL gl) {
            apsHist.draw(gl);
            temporalNoise.draw(gl);
        }

        void reset() {
            apsHist.reset();
            temporalNoise.reset();
        }

        void updateStatistics(float[] frame) {
            if (selectionRectangle == null) {
                return; // don't bother if we haven't selected a region TODO maybe do entire frame 
            }
            // itereate over pixels of selection rectangle to get pixels from frame
            for (int x = selectionRectangle.x + 1; x < selectionRectangle.x + selectionRectangle.width - 1; x++) {
                for (int y = selectionRectangle.y + 1; y < selectionRectangle.y + selectionRectangle.height - 1; y++) {
                    int idx = frameExtractor.getIndex(x, y);
                    if (idx >= frame.length) {
                        log.warning(String.format("index out of range: x=%d y=%d, idx=% frame.length=%d", x, y, idx, frame.length));
                        return;
                    }
                    int sample = (int) frame[idx];
                    apsHist.addSample(sample);
                }
            }
        }

        private class TemporalNoise {

            private double[][] sum, sum2; // variance computation

            void draw(GL gl) {
            }

            void reset() {
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
                    if (scaleHistogramsIncludingOverflow && lessCount > maxCount) {
                        maxCount = lessCount;
                    }
                } else if (bin >= histNumBins) {
                    moreCount++;
                    if (scaleHistogramsIncludingOverflow && moreCount > maxCount) {
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
            void draw(GL gl) {

                float dx = (float) (chip.getSizeX() - 2) / (histNumBins + 2);
                float sy = (float) (chip.getSizeY() - 2) / maxCount;

                gl.glBegin(GL.GL_LINES);
                gl.glVertex2f(1, 1);
                gl.glVertex2f(chip.getSizeX() - 1, 1);
                gl.glEnd();

                if (lessCount > 0) {
                    gl.glPushAttrib(GL.GL_COLOR | GL.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL.GL_LINE_STRIP);

                    float y = 1 + sy * lessCount;
                    float x1 = -dx, x2 = x1 + dx;
                    gl.glVertex2f(x1, 1);
                    gl.glVertex2f(x1, y);
                    gl.glVertex2f(x2, y);
                    gl.glVertex2f(x2, 1);
                    gl.glEnd();
                    gl.glPopAttrib();
                }
                if (moreCount > 0) {
                    gl.glPushAttrib(GL.GL_COLOR | GL.GL_LINE_WIDTH);
                    gl.glColor4fv(HIST_OVERFLOW_COLOR, 0);
                    gl.glBegin(GL.GL_LINE_STRIP);

                    float y = 1 + sy * moreCount;
                    float x1 = 1 + dx * (histNumBins + 2), x2 = x1 + dx;
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
                        float y = 1 + sy * bins[i];
                        float x1 = 1 + dx * i, x2 = x1 + dx;
                        gl.glVertex2f(x1, 1);
                        gl.glVertex2f(x1, y);
                        gl.glVertex2f(x2, y);
                        gl.glVertex2f(x2, 1);
                    }
                    gl.glEnd();
                }
            }

            void draw(GL gl, float lineWidth, float[] color) {
                gl.glPushAttrib(GL.GL_COLOR | GL.GL_LINE_WIDTH);
                gl.glLineWidth(lineWidth);
                gl.glColor4fv(color, 0);
                draw(gl);
                gl.glPopAttrib();
            }

            private void reset() {
                if (bins == null || bins.length != histNumBins) {
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
                int bin = (int) Math.floor(histNumBins * ((float) sample - sampleMin) / (sampleMax - sampleMin));
                if (bin < 0) {
                    bin = 0;
                } else if (bin >= histNumBins) {
                    bin = histNumBins - 1;
                }
                return bin;
            }
        }
    }
}
