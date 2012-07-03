/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package uk.ac.imperial.pseye.seebetter;


/**
 *
 * @author mlk11
 */
public interface SeeBetterChipInterface {
    public int getApsIntensityGain();
    public void setApsIntensityGain(int apsIntensityGain);
    
    public int getApsIntensityOffset();
    public void setApsIntensityOffset(int apsIntensityOffset);
    
    public boolean getAgcEnabled();
    public void setAgcEnabled(boolean agcEnabled);
    
    public boolean getDisplayIntensity();
    public void setDisplayIntensity(boolean displayIntensity);

    public boolean getDisplayLogIntensityChangeEvents();
    public void setDisplayLogIntensityChangeEvents(boolean displayLogIntensityChangeEvents);

    public boolean getUseDVSExtrapolation();
    public void setUseDVSExtrapolation(boolean useDVSExtrapolation);
    
    public void setAGCTauMs(float tauMs);
    public float getTauMs();
    
    public int getMaxADC();
}
