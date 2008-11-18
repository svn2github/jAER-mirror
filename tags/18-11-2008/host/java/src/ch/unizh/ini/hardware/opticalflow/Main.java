/*
 * Main.java
 *
 * Created on December 7, 2006, 8:55 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright December 7, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */

package ch.unizh.ini.hardware.opticalflow;

import ch.unizh.ini.caviar.biasgen.*;
import ch.unizh.ini.caviar.hardwareinterface.*;
import ch.unizh.ini.caviar.hardwareinterface.usb.*;
import ch.unizh.ini.caviar.hardwareinterface.usb.SiLabsC8051F320;
import ch.unizh.ini.hardware.opticalflow.chip.*;
import ch.unizh.ini.hardware.opticalflow.graphics.*;
import ch.unizh.ini.hardware.opticalflow.usbinterface.OpticalFlowHardwareInterfaceFactory;
import ch.unizh.ini.hardware.opticalflow.usbinterface.SiLabsC8051F320_OpticalFlowHardwareInterface;
import java.util.logging.Logger;

/**
 * The starter for the optical flow chip demo.
 
 * @author  tobi
 */
public class Main{
    
    static Logger log=Logger.getLogger("Main");
    public static void main(String[] args){
        
        Motion18 chip=new Motion18();
        MotionViewer viewer=new MotionViewer(chip);
        viewer.setVisible(true);
//        if(OpticalFlowHardwareInterfaceFactory.instance().getNumInterfacesAvailable()==0){
//            log.warning("no interfaces available, quitting");
//        }
//        try{
//            SiLabsC8051F320_OpticalFlowHardwareInterface siLabsIF = (SiLabsC8051F320_OpticalFlowHardwareInterface)OpticalFlowHardwareInterfaceFactory.instance().getFirstAvailableInterface();
//            chip.getBiasgen().setHardwareInterface(siLabsIF);
//            siLabsIF.open();
//        }catch(HardwareInterfaceException e){
//            e.printStackTrace();
//        }
    }
}

