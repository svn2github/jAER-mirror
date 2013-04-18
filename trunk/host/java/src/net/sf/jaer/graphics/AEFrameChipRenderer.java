/*
 * ChipRenderer.java
 *
 * Created on May 2, 2006, 1:49 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */
package net.sf.jaer.graphics;

import net.sf.jaer.event.ApsDvsEvent;
import net.sf.jaer.event.ApsDvsEventPacket;
import eu.seebetter.ini.chips.sbret10.SBret10;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.*;
import net.sf.jaer.util.SpikeSound;
import java.awt.Color;
import java.beans.PropertyChangeSupport;
import java.nio.FloatBuffer;
import java.util.Arrays;
import java.util.Iterator;
import java.util.logging.Logger;
import javax.swing.JButton;
import net.sf.jaer.config.ApsDvsConfig;
import net.sf.jaer.util.filter.LowpassFilter2d;

/**
 * Class adpated from AEChipRenderer to render not only AE events but also
 * frames.
 * 
 * The frame buffer is RGBA so four bytes per pixel
 *
 * @author christian, tobi
 * @see ChipRendererDisplayMethod
 */
public class AEFrameChipRenderer extends AEChipRenderer {
    
    public int textureWidth; //due to hardware acceloration reasons, has to be a 2^x with x a natural number
    public int textureHeight; //due to hardware acceloration reasons, has to be a 2^x with x a natural number
    
    private int sizeX, sizeY, maxADC;
    private int timestamp = 0;
    private LowpassFilter2d lowpassFilter = new LowpassFilter2d();  // 2 lp values are min and max log intensities from each frame
    private float minValue, maxValue;
    public boolean textureRendering = true;
    private float[] onColor, offColor;
    private ApsDvsConfig config;
    
    protected FloatBuffer pixBuffer;
    protected FloatBuffer onMap, onBuffer;
    protected FloatBuffer offMap, offBuffer;
    
    /** PropertyChange */
    public static final String AGC_VALUES = "AGCValuesChanged";
    
    public AEFrameChipRenderer(AEChip chip) {
        super(chip);
        config = (ApsDvsConfig)chip.getBiasgen();
        setAGCTauMs(chip.getPrefs().getFloat("agcTauMs", 1000));
        onColor = new float[4];
        offColor = new float[4];
        resetFrame(0.5f);
    }


    /** Overridden to make gray buffer special for bDVS array */
    @Override
    protected void resetPixmapGrayLevel(float value) {
        maxValue = Float.MIN_VALUE;
        minValue = Float.MAX_VALUE;
        checkPixmapAllocation();
        final int n = 4 * textureWidth * textureHeight;
        boolean madebuffer = false;
        if (grayBuffer == null || grayBuffer.capacity() != n) {
            grayBuffer = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
            madebuffer = true;
        }
        if (madebuffer || value != grayValue) {
            grayBuffer.rewind();
            for (int y = 0; y < textureWidth; y++) {
                for (int x = 0; x < textureHeight; x++) {
                    if(config.isDisplayFrames()){
                        grayBuffer.put(0);
                        grayBuffer.put(0);
                        grayBuffer.put(0);
                        grayBuffer.put(1.0f);
                    } else {
                        grayBuffer.put(grayValue);
                        grayBuffer.put(grayValue);
                        grayBuffer.put(grayValue);
                        grayBuffer.put(1.0f);
                    }
                }
            }
            grayBuffer.rewind();
        }
        System.arraycopy(grayBuffer.array(), 0, pixmap.array(), 0, n);
        System.arraycopy(grayBuffer.array(), 0, pixBuffer.array(), 0, n);
        pixmap.rewind();
        pixBuffer.rewind();
        pixmap.limit(n);
        pixBuffer.limit(n);
        setColors();
        resetEventMaps();
    }
    
    protected void resetEventMaps() {
        setColors();
        checkPixmapAllocation();
        final int n = 4 * textureWidth * textureHeight;
        if (grayBuffer == null || grayBuffer.capacity() != n) {
            grayBuffer = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
        }
        
        grayBuffer.rewind();
        Arrays.fill(grayBuffer.array(), 0.0f);
        System.arraycopy(grayBuffer.array(), 0, onMap.array(), 0, n);
        System.arraycopy(grayBuffer.array(), 0, offMap.array(), 0, n);
        
        grayBuffer.rewind();
        onMap.rewind();
        offMap.rewind();
        onMap.limit(n);
        offMap.limit(n);
    }
    
    @Override
    public synchronized void setColorMode(ColorMode colorMode) {
        super.setColorMode(colorMode);
        setColors();
    }
    
    private void setColors(){
        checkPixmapAllocation();
        switch (colorMode) {
            case GrayLevel:
            case Contrast:
                onColor[0] = 1.0f;
                onColor[1] = 1.0f;
                onColor[2] = 1.0f;
                onColor[3] = 0.0f;
                offColor[0] = 0.0f;
                offColor[1] = 0.0f;
                offColor[2] = 0.0f;
                offColor[3] = 0.0f;
                break;
            case RedGreen:
            default:
                onColor[0] = 0.0f;
                onColor[1] = 1.0f;
                onColor[2] = 0.0f;
                onColor[3] = 0.0f;
                offColor[0] = 1.0f;
                offColor[1] = 0.0f;
                offColor[2] = 0.0f;
                offColor[3] = 0.0f;
                break;
        }
    }

    @Override
    public synchronized void render(EventPacket pkt) {

        if (!(pkt instanceof ApsDvsEventPacket)) return;

        ApsDvsEventPacket packet = (ApsDvsEventPacket) pkt;

        checkPixmapAllocation();
        resetSelectedPixelEventCount(); // TODO fix locating pixel with xsel ysel

        if (packet == null) {
            return;
        }
        this.packet = packet;
        if (!(packet.getEventPrototype() instanceof ApsDvsEvent)) {
            log.warning("wrong input event class, got " + packet.getEventPrototype() + " but we need to have " + ApsDvsEvent.class);
            return;
        }
        if (!accumulateEnabled){
//            resetFrame(0.5f);
            resetEventMaps();
        }
            
        Iterator allItr = packet.fullIterator();
        while(allItr.hasNext()){
            //The iterator only iterates over the DVS events
            ApsDvsEvent e = (ApsDvsEvent) allItr.next();                        
            int type = e.getType();
            if(!e.isAdcSample()){
                if(config.isDisplayEvents()){
                    if (xsel >= 0 && ysel >= 0) { // find correct mouse pixel interpretation to make sounds for large pixels
                        int xs = xsel, ys = ysel;
                        if (e.x == xs && e.y == ys) {
                            playSpike(type);
                        }
                    }
                    updateEventMaps(e);
                }
            }else if(e.isAdcSample() && config.isDisplayFrames() && !chip.getAeViewer().isPaused()){ // TODO need to handle single step updates here
                updateFrameBuffer(e);
            }
        }
//        pixmap.rewind();
//        pixBuffer.rewind();
//        onMap.rewind();
//        offMap.rewind();
    }
    
    private void updateFrameBuffer(ApsDvsEvent e){
        float[] buf = pixBuffer.array();
        if(e.isA()){
            int index = getIndex(e.x, e.y);
            if(index<0 || index >= buf.length)return;
            float val = e.getAdcSample();
            buf[index] = val;
            buf[index+1] = val;
            buf[index+2] = val;
            if(e.isStartOfFrame())startFrame(e.timestamp);
        }else if(e.isB()){
            int index = getIndex(e.x, e.y);
            if(index<0 || index >= buf.length)return;
            float val = ((float)buf[index]-(float)e.getAdcSample());
            if (val < minValue) {
                minValue = val;
            } else if (val > maxValue) {
                maxValue = val;
            }
            val = normalizeFramePixel(val);
            buf[index] = val;
            buf[index+1] = val;
            buf[index+2] = val;
        }
        if(e.isEOF()){
            endFrame();
        }
    }
    
    private void startFrame(int ts){
        timestamp=ts;
        maxValue = Float.MIN_VALUE;
        minValue = Float.MAX_VALUE;
    }
    
    private void endFrame(){
        System.arraycopy(pixBuffer.array(), 0, pixmap.array(), 0, pixmap.array().length);
        if (minValue > 0 && maxValue > 0) { // don't adapt to first frame which is all zeros
            java.awt.geom.Point2D.Float filter2d = lowpassFilter.filter2d((float)minValue, (float)maxValue, timestamp);
            getSupport().firePropertyChange(AGC_VALUES, null, filter2d); // inform listeners (GUI) of new AGC min/max filterd log intensity values
        }
    }
    
    /** changes alpha of ON map
     * @param index 0-(size of pixel array-1) of pixel
     */
    private void updateEventMaps(ApsDvsEvent e){
        float[] map;
        int index = getIndex(e.x, e.y);
        if(e.polarity == ApsDvsEvent.Polarity.On){
            map = onMap.array();
        }else{
            map = offMap.array();
        }
        if(index<0 || index>=map.length)return;
        if(colorMode == ColorMode.ColorTime){
            int ts0 = packet.getFirstTimestamp();
            float dt = packet.getDurationUs();
            int ind = (int) Math.floor((NUM_TIME_COLORS - 1) * (e.timestamp - ts0) / dt);
            if (ind < 0) {
                ind = 0;
            } else if (ind >= timeColors.length) {
                ind = timeColors.length - 1;
            }
            map[index] = timeColors[ind][0];
            map[index + 1] = timeColors[ind][1];
            map[index + 2] = timeColors[ind][2];
            map[index + 3] = 0.5f;
        }else{
            float alpha = map[index+3]+(1.0f/(float)colorScale);
            alpha = normalizeEvent(alpha);
            if(e.polarity == PolarityEvent.Polarity.On){
                map[index] = onColor[0];
                map[index+1] = onColor[1];
                map[index+2] = onColor[2];
            }else{
                map[index] = offColor[0];
                map[index+1] = offColor[1];
                map[index+2] = offColor[2];
            }
            map[index+3] = alpha;
        }
    }
    
    final int INTERVAL_BETWEEEN_OUT_OF_BOUNDS_EXCEPTIONS_PRINTED_MS=1000;
    private long lastWarningPrintedTimeMs=Integer.MAX_VALUE;
    
    private int getIndex(int x, int y){
        if (x < 0 || y < 0 || x >= sizeX || y >= sizeY) {
            if (System.currentTimeMillis() - lastWarningPrintedTimeMs > INTERVAL_BETWEEEN_OUT_OF_BOUNDS_EXCEPTIONS_PRINTED_MS) {
                log.warning(String.format("Event x=%d y=%d out of bounds and cannot be rendered in bounds sizeX=%d sizeY=%d- delaying next warning for %dms", x, y, sizeX, sizeY,INTERVAL_BETWEEEN_OUT_OF_BOUNDS_EXCEPTIONS_PRINTED_MS));
                lastWarningPrintedTimeMs = System.currentTimeMillis();
            }
            return -1;
        }
        if(textureRendering){
            return  4* (x + y * textureWidth);
        }else{
            return 4* (x + y * sizeX);
        }
    }
    
    @Override
    protected void checkPixmapAllocation() {
        if(sizeX != chip.getSizeX() || sizeY != chip.getSizeY()){
            sizeX = chip.getSizeX();
            textureWidth = ceilingPow2(sizeX);
            sizeY = chip.getSizeY();
            textureHeight = ceilingPow2(sizeY);
        }
        final int n = 4 * textureWidth * textureHeight;
        if (pixmap == null || pixmap.capacity() < n || pixBuffer.capacity() < n || onMap.capacity() < n || offMap.capacity() < n) {
            pixmap = FloatBuffer.allocate(n); // BufferUtil.newFloatBuffer(n);
            pixBuffer = FloatBuffer.allocate(n);
            onMap = FloatBuffer.allocate(n);
            offMap = FloatBuffer.allocate(n);
        }
    }
    
    /** Overrides color scale setting to NOT update the stored accumulated pixmap when the color scale is changed.
    
     * */
    @Override
    synchronized public void setColorScale(int colorScale) {
        int old = this.colorScale;
        if (colorScale < 1) {
            colorScale = 1;
        }
        if (colorScale > 128) {
            colorScale = 128;
        }
        this.colorScale = colorScale;
        prefs.putInt("Chip2DRenderer.colorScale", colorScale);
    }
    
     private static int ceilingPow2(int n) {
        int pow2 = 1;
        while (n > pow2) {
        pow2 = pow2<<1;
        }
        return pow2;
    }
     
     public FloatBuffer getOnMap(){
         onMap.rewind();
         checkPixmapAllocation();
         return onMap;
     }
     
     public FloatBuffer getOffMap(){
         offMap.rewind();
         checkPixmapAllocation();
         return offMap;
     }
     
    @Override
    public int getPixMapIndex(int x, int y) {
        return 4 * (x + y * sizeX);
    }
    
    @Override
    public int getWidth(){
        return textureWidth;
    }
    
    @Override
    public int getHeight(){
        return textureHeight;
    }

    private float normalizeFramePixel(float value) {
        float v;
        if (!config.isUseAutoContrast()) {
            v = (float) (config.getContrast()*value+config.getBrightness()) / (float) maxADC;
        } else {
            java.awt.geom.Point2D.Float filter2d = lowpassFilter.getValue2d();
            float offset = filter2d.x;
            float range = (filter2d.y - filter2d.x);
            v = ((value - offset)) / (range);
//           System.out.println("offset="+offset+" range="+range+" value="+value+" v="+v);
        }
        if (v < 0) {
            v = 0;
        } else if (v > 1) {
            v = 1;
        }
        return v;
    }
    
    private float normalizeEvent(float value) {
        if (value < 0) {
            value = 0;
        } else if (value > 1) {
            value = 1;
        }
        return value;
    }

    public float getAGCTauMs() {
        return lowpassFilter.getTauMs();
    }

    public void setAGCTauMs(float tauMs) {
        if (tauMs < 10) {
            tauMs = 10;
        }
        lowpassFilter.setTauMs(tauMs);
        chip.getPrefs().putFloat("agcTauMs", tauMs);
    }

    public void applyAGCValues() {
        java.awt.geom.Point2D.Float f = lowpassFilter.getValue2d();
        config.setBrightness(agcOffset());
        config.setContrast(agcGain());
    }

    private int agcOffset() {
        return (int) lowpassFilter.getValue2d().x;
    }

    private int agcGain() {
        java.awt.geom.Point2D.Float f = lowpassFilter.getValue2d();
        float diff = f.y - f.x;
        if (diff < 1) {
            return 1;
        }
        int gain = (int) (maxADC / (f.y - f.x));
        return gain;
    }
    
    public int getMaxADC(){
        return maxADC;
    }
    
    public void setMaxADC(int max){
        maxADC = max;
    }
    
    public void resetAutoContrast(){
        
    }
    
    /** @return the gray level of the rendered data; used to determine whether a pixel needs to be drawn */
    @Override
    public float getGrayValue() {
        if(config.isDisplayFrames() || colorMode==ColorMode.Contrast || colorMode==ColorMode.GrayLevel){
            grayValue = 0.5f;
        }else{
            grayValue = 0.0f;
        }
        return this.grayValue;
    }
    
    public boolean isDisplayFrames(){
        return config.isDisplayFrames();
    }
    
    public boolean isDisplayEvents(){
        return config.isDisplayEvents();
    }

}
