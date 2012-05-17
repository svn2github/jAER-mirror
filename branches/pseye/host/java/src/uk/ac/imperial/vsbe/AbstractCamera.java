
package uk.ac.imperial.vsbe;

import java.util.Observable;
import java.util.logging.Logger;
import net.sf.jaer.hardwareinterface.HardwareInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import javax.swing.JPanel;

/*
 * Abstract class used for a standard frame based camera implementation in VSBE.
 * Implements FrameSource to allow the chaining of multi-threaded frame queues.
 * 
 * @author mlk
 */
public abstract class AbstractCamera extends Observable implements HardwareInterface, FrameSource {
    /* Frame producer/consumer thread */
    protected FrameQueue stream = new FrameQueue();
    
    /* Flag camera started and collecting frames */
    public boolean isStarted = false;
    
    /* Copy contents of frame queue thread to buffer  
     * 
     * @param imgData: buffer frame data is copied to
     * @param offset: offset in imgData to copy data to  
     * @return true if data copied, false if not
     */
    public boolean getFrame(Frame frame)
    {
        // return if camera not already started
        if (!isStarted) return false;
        return stream.read(frame);
    } 
    
    public AbstractCamera() {}
    
    /* Mark camera as started and start frame queue thread  
     * 
     * @return always true
     */
    public boolean start() {
        // open consumer / producer thread
        stream.open(this);
        isStarted = true;
        return true;
    }
    
    /* Mark camera as stopped and stop frame queue thread  
     * 
     * @return always true
     */
    public boolean stop() {
        // close consumer / producer thread
        stream.close();
        isStarted = false;
        return true;
    }
    
    /* Return frame thread  
     * 
     * @return FrameQueue thread 
     */
    public FrameQueue getStream() {
        return stream;
    }
    
    /* Return a JPanel for changing camera settings 
     * 
     * @return control JPanel
     */
    public abstract JPanel getControlPanel();
    
    /* Return the log associated with the camera 
     * Allows for better error reporting
     * 
     * @return camera log
     */
    public abstract Logger getLog();
    
    /* Overrides from HardwareInterface Interface */
    @Override public abstract String getTypeName();
    @Override public abstract void close();
    @Override public abstract void open() throws HardwareInterfaceException;
    @Override public abstract boolean isOpen();
    
    /* Overrides from FrameSource Interface */
    @Override public abstract boolean read(Frame frame);
    @Override public abstract boolean peek(Frame frame);
    @Override public abstract int getFrameX();
    @Override public abstract int getFrameY();
    @Override public abstract int getPixelSize();
}
