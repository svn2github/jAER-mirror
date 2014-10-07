/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.eventbasedfeatures;

import net.sf.jaer.chip.AEChip;

/**
 *
 * @author Varad
 */
public class BCIRCLE extends DescriptorScheme{
    
    public BCIRCLE(AEChip chip, ConvolutionFeatureScheme featurescheme){
        super(chip, featurescheme);   
        size = 17;
        descPixels = new int[size];
        index = new int[size][size];
        createLookUpTable();                
    }

    @Override
    public void constructKeyPointDescriptor(KeyPoint kp) {
        
        int[] xcoords = getXArray(kp);
        int[] ycoords = getYArray(kp);
        
        for( int i = 0; i < xcoords.length; i++ ){
            descPixels[i] = getIndex(xcoords[i], ycoords[i]);
        }
        
        for(int i = 0; i < size-1; i++){           
            int indexi = descPixels[i];
            for(int j = i+1; j < size; j++){
                int indexj = descPixels[j];    
                if((featurescheme.detector.grayvalue[3*indexi] > featurescheme.detector.grayvalue[3*indexj]) && (i<j)){
                    kp.descriptorString[index[i][j]] = true;                          
                }
            }   
        }        
    }
    
    public int[] getXArray(KeyPoint kp){
        int[] xarray = {kp.x, kp.x, kp.x+1, kp.x+2, kp.x+3, kp.x+3, kp.x+3, kp.x+2, kp.x+1, kp.x, kp.x-1, kp.x-2, kp.x-3, kp.x-3, kp.x-3, kp.x-2, kp.x-1};
        return xarray;
    }
    
    public int[] getYArray(KeyPoint kp){
        int[] yarray = {kp.y, kp.y+3, kp.y+3, kp.y+2, kp.y+1, kp.y, kp.y-1, kp.y-2, kp.y-3, kp.y-3, kp.y-3, kp.y-2, kp.y-1, kp.y, kp.y+1, kp.y+2, kp.y+3};
        return yarray;
    } 
}
