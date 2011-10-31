package net.sf.jaer.graphics;

import java.nio.FloatBuffer;
import java.util.Observable;
import java.util.Observer;
import net.sf.jaer.chip.Chip2D;
import java.util.ArrayList;
import java.util.prefs.Preferences;

/**
A general class for rendering chip output to a 2d array of float values for drawing.
 * Various modes are possible, e.g. gray scale, red/green for polarity events, color-time,
 * multi-color for representing orientation or direction. Also allows continuous integration (accumulation) or time slices.
 * @see net.sf.jaer.graphics.AEChipRenderer for the class that renders AEChip events to a pixmap histogram
@author tobi
 *@see ChipRendererDisplayMethod
 */
public class Chip2DRenderer implements Observer {

    private int sizeX,  sizeY;
    protected Preferences prefs = Preferences.userNodeForPackage(Chip2DRenderer.class);
    /** the chip rendered for */
    protected Chip2D chip;
    /** determines whether frame is reset to starting value on each rendering cycle. True to accumulate. */
    protected boolean accumulateEnabled = false;
    protected ArrayList<FrameAnnotater> annotators = new ArrayList<FrameAnnotater>();
    protected int autoScaleValue = 1;
    /** false for manual scaling, true for auto-scaling of contrast */
    protected boolean autoscaleEnabled = prefs.getBoolean("Chip2DRenderer.autoscaleEnabled", false);
    /** the number of events for full scale saturated color */
    protected int colorScale; // set in constructor to preference value so that eventContrast also gets set
    /** the contrast attributed to an event, 
     * either level is multiplied or divided by this value depending on polarity of event. 
     * Gets set by setColorScale */
    protected float eventContrast = 1.1f;
    /** the rendered frame, RGB matrix of pixel values in 0-1 range.
    In Matlab convention, the first dimension is y, the second dimension is x, the third dimension is a 3 vector of RGB values.
     * @deprecated replaced by pixmap direct float buffer.
     */
    protected float[][][] fr;
    /** The rendered pixel map, ordered by RGB/row/col. The first 3 elements are the RBB float values of the LL pixel (x=0,y=0). The next 3 are
     * the RGB of the second pixel from the left in the bottom row (x=1,y=0). Pixel (0,1) is at position starting at 3*(chip.getSizeX()).
     */
    protected FloatBuffer pixmap;

    /**
     * The rendered pixel map, ordered by RGB/row/col. The first 3 elements are the RBB float values of the LL pixel (x=0,y=0). The next 3 are
     * the RGB of the second pixel from the left in the bottom row (x=1,y=0). Pixel (0,1) is at position starting at 3*(chip.getSizeX()) in the FloatBuffer.
     *
     * @return the pixmap
     * @see #getPixmapArray()  to return a float[] array
     */
    public FloatBuffer getPixmap() {
        return pixmap;
    }

//    public void setPixmapRGB(int x, int y, float[] rgb) {
//        setPixmapPosition(x, y);
//        pixmap.put(rgb);
//    }
//    private float[] rgb = new float[3];

//    public float[] getPixmapRGB(int x, int y) {
//        setPixmapPosition(x, y);
//        pixmap.get(rgb);
//        return rgb;
//    }

    /** Returns an int that can be used to index to a particular pixel's RGB start location in the pixmap.
     * The successive 3 entries are the float (0-1) RGB values.
     *
     * @param x pixel x, 0 is left side.
     * @param y pixel y, 0 is bottom.
     * @return index into pixmap.
     * @see #getPixmapArray()
     */
    public int getPixMapIndex(int x, int y) {
        return 3 * (x + y * sizeX);
    }

    /** Returns the pixmap 1-d array of pixel RGB values.
     *
     * @return the array.
     * @see #getPixMapIndex(int, int)
     */
    public float[] getPixmapArray() {
        return pixmap.array();
    }

//    public void setPixmapPosition(int x, int y) {
//        pixmap.position(3 * (x + y * sizeX));
//    }
//    private float pixmapGrayValue = 0;

    private FloatBuffer grayBuffer;

    private void resetPixmapGrayLevel(float value) {
        checkPixmapAllocation();
        final int n = 3 * chip.getNumPixels();
        boolean madebuffer = false;
        if (grayBuffer == null || grayBuffer.capacity() != n) {
            grayBuffer = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
            madebuffer = true;
        }
        if (madebuffer || value != grayValue) {
            grayBuffer.rewind();
            for (int i = 0; i < n; i++) {
                grayBuffer.put(value);
            }
            grayBuffer.rewind();
        }
        System.arraycopy(grayBuffer.array(), 0, pixmap.array(), 0, n);
        pixmap.rewind();
        pixmap.limit(n);
//        pixmapGrayValue = grayValue;
    }

    /** Subclasses should call checkPixmapAllocation to make sure the pixmap FloatBuffer is allocated before accessing it.
     *
     */
    protected void checkPixmapAllocation() {
        final int n = 3 * chip.getNumPixels();
        if (pixmap == null || pixmap.capacity() < n) {
            pixmap = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
        }
    }
    /** The gray value. */
    protected float grayValue = 0;
    /** The mouse-selected x pixel location, from left. */
    protected short xsel = -1;
    /** The mouse selected y pixel location, from bottom. */
    protected short ysel = -1;
    /** The count of spikes in the "selected" pixel. Rendering methods are responsible for maintaining this */
    protected int selectedPixelEventCount = 0;

    public Chip2DRenderer() {
        setColorScale(prefs.getInt("Chip2DRenderer.colorScale", 1));
    }

    public Chip2DRenderer(Chip2D chip) {
        this();
        this.chip = chip;
        sizeX = chip.getSizeX();
        sizeY = chip.getSizeY();
        chip.addObserver(this);

    }

    /** decrease contrast */
    public int decreaseContrast() {
        int cs = getColorScale();
        cs++;
        if (cs > 255) {
            cs = 255;
        }
        setColorScale(cs);
        return getColorScale();
    }

    /**@return current color scale, full scale in events */
    public int getColorScale() {
        if (!autoscaleEnabled) {
            return colorScale;
        } else {
            return autoScaleValue;
        }
    }

    /** @return the gray level of the rendered data; used to determine whether a pixel needs to be drawn */
    public float getGrayValue() {
        return this.grayValue;
    }

    synchronized public void setGrayValue(float value) {
        grayValue = value;
    }

    /** A single pixel can be selected via the mouse and this returns the x pixel value.
     */
    public short getXsel() {
        return xsel;
    }

    /** A single pixel can be selected via the mouse and this returns the y pixel value.
     */
    public short getYsel() {
        return ysel;
    }

    /** increase image contrast */
    public int increaseContrast() {
        int cs = getColorScale();
        cs--;
        if (cs < 1) {
            cs = 1;
        }
        setColorScale(cs);
        return getColorScale();
    }

    public boolean isAccumulateEnabled() {
        return this.accumulateEnabled;
    }

    public boolean isAutoscaleEnabled() {
        return this.autoscaleEnabled;
    }

    public boolean isPixelSelected() {
        return xsel != -1 && ysel != -1;
    }

    public synchronized void removeAllAnnotators() {
        annotators.removeAll(annotators);
    }

//    public void resetChannel(float value, int channel) {
//        for (int i = 0; i < fr.length; i++) {
//            for (int j = 0; j < fr[i].length; j++) {
//                float[] f = fr[i][j];
//                f[channel] = value;
//            }
//        }
//    }

    /** Checks the frame buffer for the correct sizes;
    when constructed in superclass of a chip, sizes may not yet be set for chip. we can check every time
     * @deprecated replaced by pixmap
     */
    synchronized public void checkFr() {
        if (fr == null || fr.length == 0) {
            reallocateFr();
        }
    }

    /** reallocates the fr buffer using the current chip size
     @deprecated replaced by pixmap
     */
    private void reallocateFr() {
        if (chip == null) {
            return;
        }
        fr = new float[chip.getSizeY()][chip.getSizeX()][3];
        checkPixmapAllocation();
    }

    /** Resets the pixmap frame buffer to a given gray level.
     *
     * @param value gray level, 0-1 range.
     */
    synchronized public void resetFrame(float value) {
        resetPixmapGrayLevel(value);
        grayValue = value;
    }

    /** @param accumulateEnabled true to accumulate data to frame (don't reset to start value each cycle) */
    public void setAccumulateEnabled(final boolean accumulateEnabled) {
        this.accumulateEnabled = accumulateEnabled;
    }

    public void setAutoscaleEnabled(final boolean autoscaleEnabled) {
        this.autoscaleEnabled = autoscaleEnabled;
        prefs.putBoolean(("BinocularRenderer.autoscaleEnabled"), autoscaleEnabled);
    }

    /** set the color scale. 1 means a single event is full scale, 2 means a single event is half scale, etc.
     *only applies to some rendering methods.
     */
    public void setColorScale(int colorScale) {
        if (colorScale < 1) {
            colorScale = 1;
        }
        if (colorScale > 64) {
            colorScale = 64;
        }
        this.colorScale = colorScale;
        // we set eventContrast so that colorScale events takes us from .5 to 1, i.e., .5*(eventContrast^cs)=1, so eventContrast=2^(1/cs)
        eventContrast = (float) (Math.pow(2, 1.0 / colorScale)); // e.g. cs=1, eventContrast=2, cs=2, eventContrast=2^0.5, etc
        prefs.putInt("Chip2DRenderer.colorScale", colorScale);
    }

    /** Sets the x of the selected pixel.
     *
     * @param xsel
     */
    public void setXsel(short xsel) {
        this.xsel = xsel;
    }

    /** Sets the y of the selected pixel.
     *
     * @param ysel
     */
    public void setYsel(short ysel) {
        this.ysel = ysel;
    }

//    /** @return frame data.
//     * fr is the rendered event data that we draw. Y is the first dimension, X is the second dimension, RGB 3 vector is the last dimension.
//    @see #fr
//     * @deprecated replaced by pixmap
//     */
//    public float[][][] getFr() {
//        return fr;
//    }

    /** Returns the number of spikes in the selected pixel in the last rendered packet */
    public int getSelectedPixelEventCount() {
        return selectedPixelEventCount;
    }
    
    /** Sets the selected pixel event count to zero. */
    protected void resetSelectedPixelEventCount(){
        selectedPixelEventCount=0;
    }

    public void update(Observable o, Object arg) {
        if (o instanceof Chip2D) {
            if (arg instanceof String) {
                String s = (String) arg;
                if (s.equals(Chip2D.EVENT_SIZEX)) {
                    sizeX = chip.getSizeX();
                } else if (s.equals(Chip2D.EVENT_SIZEY)) {
                    sizeY = chip.getSizeY();
                }
            }
        }
    }
    }
