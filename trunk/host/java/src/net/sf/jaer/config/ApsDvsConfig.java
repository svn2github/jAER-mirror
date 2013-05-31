/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.config;

/**
 * Configuration interface for apsDVS vision sensor output rendering.
 * 
 * @author Christian
 */
public interface ApsDvsConfig {
    
    public abstract boolean isDisplayFrames();
    
    public abstract void setDisplayFrames(boolean displayFrames);
    
    public abstract boolean isDisplayEvents();
    
    public abstract void setDisplayEvents(boolean displayEvents);
    
    public abstract boolean isUseAutoContrast();
    
    public abstract void setUseAutoContrast(boolean useAutoContrast);
    
    public abstract float getContrast();
    
    public abstract void setContrast(float contrast);
    
    public abstract float getBrightness();
    
    public abstract void setBrightness(float brightness);
    
    public abstract float getGamma();
    public abstract void setGamma(float gamma);
    
    abstract public void setFrameDelayMs(int ms);
    abstract public int getFrameDelayMs();
    
    abstract public void setExposureDelayUs(int us);
    abstract public int getExposureDelayUs();
    
    abstract public void setAutoShotEventThreshold(int threshold);
    abstract public int getAutoShotEventThreshold();
    
}
