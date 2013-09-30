/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.machinevision.frames;

import eu.seebetter.ini.chips.ApsDvsChip;
import net.sf.jaer.event.ApsDvsEvent;
import net.sf.jaer.event.ApsDvsEventPacket;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.util.Arrays;
import java.util.Iterator;
import javax.swing.JFrame;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.PolarityEvent;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.ImageDisplay;
import net.sf.jaer.graphics.ImageDisplay.Legend;

/**
 *
 * @author Christian Brändli
 */
@Description("Method to acquire a frame from a stream of APS sample events")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class ApsFrameExtractor extends EventFilter2D {

    private JFrame apsFrame = null;
    public ImageDisplay apsDisplay;
    private ApsDvsChip apsChip = null;
    private boolean newFrame, useExtRender;
    private float[] resetBuffer, signalBuffer;
    private float[] displayBuffer;
    private float[] apsDisplayPixmapBuffer;
    private double[] displayFrame;
    private int width, height, maxADC, maxIDX;
    private float grayValue;
    
    public static float logSafetyOffset = 10000.0f;

    public static enum Extraction {

        ResetFrame, SignalFrame, CDSframe
    };
    private boolean invertIntensity = getPrefs().getBoolean("ApsFrameExtractor.invertIntensity", false);

    {
        setPropertyTooltip("invertIntensity", "Should the allocation pixels be drawn");
    }
    
    
    private boolean preBufferFrame = getPrefs().getBoolean("ApsFrameExtractor.preBufferFrame", true);

    {
        setPropertyTooltip("preBufferFrame", "Only display and use complete frames");
    }
    
    
    private boolean logCompress = getPrefs().getBoolean("ApsFrameExtractor.logCompress", false);

    {
        setPropertyTooltip("logCompress", "Should the displayBuffer be log compressed");
    }
    
    
    private boolean logDecompress = getPrefs().getBoolean("ApsFrameExtractor.logDecompress", false);

    {
        setPropertyTooltip("logDecompress", "Should the logComressed displayBuffer be rendered normal");
    }
    
    
    private float displayContrast = getPrefs().getFloat("ApsFrameExtractor.displayContrast", 1.0f);

    {
        setPropertyTooltip("displayContrast", "Gain for the rendering of the APS display");
    }
    
    
    private float displayBrightness = getPrefs().getFloat("ApsFrameExtractor.displayBrightness", 0.0f);

    {
        setPropertyTooltip("displayBrightness", "Offset for the rendering of the APS display");
    }
    
    
    public Extraction extractionMethod = Extraction.valueOf(getPrefs().get("ApsFrameExtractor.extractionMethod", "CDSframe"));

    {
        setPropertyTooltip("extractionMethod", "Method to extract a frame");
    }
    

    public ApsFrameExtractor(AEChip chip) {
        super(chip);
        apsDisplay = ImageDisplay.createOpenGLCanvas();
        apsFrame = new JFrame("APS Frame");
        apsFrame.setPreferredSize(new Dimension(width * 4, height * 4));
        apsFrame.getContentPane().add(apsDisplay, BorderLayout.CENTER);
        apsFrame.pack();
        initFilter();
    }

    @Override
    public void initFilter() {
        resetFilter();
    }

    @Override
    public void resetFilter() {
        if (ApsDvsChip.class.isAssignableFrom(chip.getClass())) {
            apsChip = (ApsDvsChip) chip;
        } else {
            log.warning("The filter ApsFrameExtractor can only be used for chips that extend the ApsDvsChip class");
        }
        newFrame = false;
        width = chip.getSizeX();
        height = chip.getSizeY();
        maxIDX = width * height;
        maxADC = apsChip.getMaxADC();
        apsDisplay.setImageSize(width, height);
        resetBuffer = new float[width * height];
        signalBuffer = new float[width * height];
        displayFrame = new double[width * height];
        displayBuffer = new float[width * height];
        apsDisplayPixmapBuffer = new float[3 * width * height];
        Arrays.fill(resetBuffer, 0.0f);
        Arrays.fill(signalBuffer, 0.0f);
        Arrays.fill(displayFrame, 0.0f);
        Arrays.fill(displayBuffer, 0.0f);
        Arrays.fill(apsDisplayPixmapBuffer, 0.0f);
    }

    @Override
    public EventPacket<?> filterPacket(EventPacket<?> in) {
        checkMaps();

        ApsDvsEventPacket packet = (ApsDvsEventPacket) in;
        if (packet == null) {
            return null;
        }
        if (packet.getEventClass() != ApsDvsEvent.class) {
            log.warning("wrong input event class, got " + packet.getEventClass() + " but we need to have " + ApsDvsEvent.class);
            return null;
        }
        Iterator apsItr = packet.fullIterator();
        while (apsItr.hasNext()) {
            ApsDvsEvent e = (ApsDvsEvent) apsItr.next();
            if (e.isAdcSample()) {
                putAPSevent(e);
            }
        }

        apsDisplay.repaint();
        return in;
    }

    private void checkMaps() {
        apsDisplay.checkPixmapAllocation();
        if (!apsFrame.isVisible()) {
            apsFrame.setVisible(true);
        }
    }

    public void putAPSevent(ApsDvsEvent e) {
        if (!e.isAdcSample()) {
            return;
        }
        //if(e.isStartOfFrame())timestamp=e.timestamp;
        ApsDvsEvent.ReadoutType type = e.getReadoutType();
        float val = e.getAdcSample();
        int idx = getIndex(e.x, e.y);
        if (idx >= maxIDX) {
            return;
        }
        if (e.isStartOfFrame()) {
            if (newFrame && useExtRender) {
                log.warning("Acquistion of new frame started even though old frame was never delivered to ext renderer");
            }
        }
        if (idx < 0) {
            if (e.isEndOfFrame()) {
                if (preBufferFrame && displayBuffer != null) {
                    apsDisplay.setPixmapArray(apsDisplayPixmapBuffer);
                }
                newFrame = true;
            }
            return;
        }
        switch (type) {
            case SignalRead:
                signalBuffer[idx] = val;
                break;
            case ResetRead:
            default:
                resetBuffer[idx] = val;
                break;
        }
        switch (extractionMethod) {
            case ResetFrame:
                displayBuffer[idx] = resetBuffer[idx];
                break;
            case SignalFrame:
                displayBuffer[idx] = signalBuffer[idx];
                break;
            case CDSframe:
            default:
                displayBuffer[idx] = resetBuffer[idx] - signalBuffer[idx];
                break;
        }
        if (invertIntensity) {
            displayBuffer[idx] = maxADC - displayBuffer[idx];
        }
        if (logCompress) {
            displayBuffer[idx] = (float) Math.log(displayBuffer[idx] + logSafetyOffset);
        }
        if(logCompress && logDecompress){
            grayValue = scaleGrayValue((float) (Math.exp(displayBuffer[idx])-logSafetyOffset));
        }else{
            grayValue = scaleGrayValue(displayBuffer[idx]);
        }
        displayFrame[idx] = (double) grayValue;
        if (!useExtRender) {
            if (!preBufferFrame) {
                apsDisplay.setPixmapGray(e.x, e.y, grayValue);
            }else{
                apsDisplayPixmapBuffer[3 * idx] = grayValue;
                apsDisplayPixmapBuffer[3 * idx + 1] = grayValue;
                apsDisplayPixmapBuffer[3 * idx + 2] = grayValue;
            }
        }
    }

    private float scaleGrayValue(float value) {
        float v;
        v = (displayContrast * value + displayBrightness) / (float) maxADC;
        if (v < 0) {
            v = 0;
        } else if (v > 1) {
            v = 1;
        }
        return v;
    }
    
    public void updateDisplayValue(int xAddr, int yAddr, float value){
        if(logCompress && logDecompress){
            grayValue = scaleGrayValue((float) (Math.exp(value)-logSafetyOffset));
        }else{
            grayValue = scaleGrayValue(value);
        }
        apsDisplay.setPixmapGray(xAddr, yAddr, grayValue);
    }

    private int getIndex(int x, int y) {
        return y * width + x;
    }

    public boolean hasNewFrame() {
        return newFrame;
    }

    public double[] getNewFrame() {
        newFrame = false;
        return displayFrame;
    }
    
    public float[] getDisplayBuffer() {
        newFrame = false;
        return displayBuffer;
    }

    public void acquireNewFrame() {
        apsChip.takeSnapshot();
    }

    public void setExtRender(boolean setExt) {
        this.useExtRender = setExt;
    }

    public void setDisplayGrayFrame(double[] frame) {
        int xc = 0;
        int yc = 0;
        for (int i = 0; i < frame.length; i++) {
            apsDisplay.setPixmapGray(xc, yc, (float) frame[i]);
            xc++;
            if (xc == width) {
                xc = 0;
                yc++;
            }
        }
    }

    public void setDisplayFrameRGB(double[] frame) {
        int xc = 0;
        int yc = 0;
        for (int i = 0; i < frame.length; i += 3) {
            apsDisplay.setPixmapRGB(xc, yc, (float) frame[i + 2], (float) frame[i + 1], (float) frame[i]);
            xc++;
            if (xc == width) {
                xc = 0;
                yc++;
            }
        }
    }

    /**
     * @return the invertIntensity
     */
    public boolean isInvertIntensity() {
        return invertIntensity;
    }

    /**
     * @param invertIntensity the invertIntensity to set
     */
    public void setInvertIntensity(boolean invertIntensity) {
        this.invertIntensity = invertIntensity;
        prefs().putBoolean("ApsFrameExtractor.invertIntensity", invertIntensity);
    }

    /**
     * @return the invertIntensity
     */
    public boolean isPreBufferFrame() {
        return preBufferFrame;
    }

    /**
     * @param invertIntensity the invertIntensity to set
     */
    public void setPreBufferFrame(boolean preBuffer) {
        this.preBufferFrame = preBuffer;
        prefs().putBoolean("ApsFrameExtractor.preBufferFrame", preBufferFrame);
    }

    /**
     * @return the logDecompress
     */
    public boolean isLogDecompress() {
        return logDecompress;
    }

    /**
     * @param logDecompress the logDecompress to set
     */
    public void setLogDecompress(boolean logDecompress) {
        this.logDecompress = logDecompress;
        prefs().putBoolean("ApsFrameExtractor.logDecompress", logDecompress);
    }

    /**
     * @return the logCompress
     */
    public boolean isLogCompress() {
        return logCompress;
    }

    /**
     * @param logCompress the logCompress to set
     */
    public void setLogCompress(boolean logCompress) {
        this.logCompress = logCompress;
        prefs().putBoolean("ApsFrameExtractor.logCompress", logCompress);
    }

    /**
     * @return the displayContrast
     */
    public float getDisplayContrast() {
        return displayContrast;
    }

    /**
     * @param displayContrast the displayContrast to set
     */
    public void setDisplayContrast(float displayContrast) {
        this.displayContrast = displayContrast;
        prefs().putFloat("ApsFrameExtractor.displayContrast", displayContrast);
        resetFilter();
    }

    /**
     * @return the displayBrightness
     */
    public float getDisplayBrightness() {
        return displayBrightness;
    }

    /**
     * @param displayBrightness the displayBrightness to set
     */
    public void setDisplayBrightness(float displayBrightness) {
        this.displayBrightness = displayBrightness;
        prefs().putFloat("ApsFrameExtractor.displayBrightness", displayBrightness);
        resetFilter();
    }

    public Extraction getExtractionMethod() {
        return extractionMethod;
    }

    synchronized public void setExtractionMethod(Extraction extractionMethod) {
        getSupport().firePropertyChange("extractionMethod", this.extractionMethod, extractionMethod);
        getPrefs().put("ApsFrameExtractor.edgePixelMethod", extractionMethod.toString());
        this.extractionMethod = extractionMethod;
        resetFilter();
    }
}
