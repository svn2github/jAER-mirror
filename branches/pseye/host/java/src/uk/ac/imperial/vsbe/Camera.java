
package uk.ac.imperial.vsbe;

import java.util.Observable;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import javax.swing.JPanel;

/**
 * Wrapper class for standard camera used by VSBE
 * 
 * @author mlk
 */
public abstract class Camera extends Observable implements HardwareInterface, FrameStreamable {
    // Wrapper class for frame producer/consumer thread
    protected FrameInputStream stream = new FrameInputStream();
    public boolean isStarted = false;
    
    /* Gets timestamped frame data from capture thread */
    public boolean getFrame(int[] imgData, int offset)
    {
        // return if camera not started
        if (!isStarted) return false;
        return stream.readFrameStream(imgData, offset);
    }
    
    public boolean getFrame(int[] imgData)
    {
        return getFrame(imgData, 0);
    }    
    
    public Camera() {
    }
    
    /* start and stop camera framemanager */
    public boolean start() {
        stream.open(this);
        isStarted = true;
        return true;
    }
    
    public boolean stop() {
        stream.close();
        isStarted = false;
        return true;
    }
    
    public FrameInputStream getStream() {
        return stream;
    }
    
    public abstract JPanel getControlPanel();
}
