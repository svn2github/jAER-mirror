/*
 * ThrdDetectCollision.java
 *
 * Created on 13. Februar 2008, 01:12
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package ch.unizh.ini.robothead.robotcontrol;

/**
 *
 * Thread that should be opened with every movement in KoalaGui and detects if there is an obstacle that reached the sensor threshold and is coming nearer...
 * This makes the robot stop
 *
 * @author jaeckeld
 */
public class ThrdDetectCollision implements Runnable{
    
    /** Creates a new instance of ThrdDetectCollision */
    public ThrdDetectCollision() {
    }
    
    public void run(){
        System.out.println("Thread Collision-Detection started...");
        
        while(KoalaControl.IsRobotMoving()){
            
            try {               
                Thread.sleep(100);          // ask every 200 ms
            } catch (InterruptedException ex) {
                ex.printStackTrace();
            }
        
            if(!KoalaControl.wayClear(KoalaControl.OldSens)){       // if way not clear
                KoalaControl.moveRobot(0,0);    // make robot stop...
                if(KoalaControl.registerPath)
                    KoalaControl.regCoordTime(); 
                KoalaControl.setRobotNotMoving();
                
                KoalaControl.IsThereObstacle=true;  // I have an obstacle
                
            }
        
        }
    }
    
}
