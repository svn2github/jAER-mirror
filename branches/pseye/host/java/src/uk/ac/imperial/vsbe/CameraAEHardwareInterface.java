
package uk.ac.imperial.vsbe;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeSupport;
import java.nio.IntBuffer;
import net.sf.jaer.aemonitor.AEListener;
import net.sf.jaer.aemonitor.AEMonitorInterface;
import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;

/*
 * Template class used to create a AEHardwareInterface for a standard frame 
 * based camera to handle packing CameraAEPacketRaw objects that hold frame data.
 * 
 * @author mlk
 */
public class CameraAEHardwareInterface<C extends AbstractCamera> implements AEMonitorInterface {

    /**
     * event supplied to listeners when new events are collected. this is final because it is just a marker for the listeners that new events are available
     */
    public final PropertyChangeEvent newEventPropertyChange = new PropertyChangeEvent(this, "NewEvents", null, null);
    private int frameCounter = 0;
    private long startTimeUs = System.currentTimeMillis() * 1000;
    protected AEChip chip = null;
    protected C camera = null;
    protected Frame frame = new Frame();
    
    protected PropertyChangeSupport support = new PropertyChangeSupport(this);
    private CameraAEPacketRaw packet = new CameraAEPacketRaw(320 * 240);

    public CameraAEHardwareInterface(C camera) {
        this.camera = camera;
    }
    
    /* Overrides from AEMonitorInterface. */
        
    /**
     * This camera returns frames. 
     * This method returns all frames of image data produced by the data capture thread. 
     * We pack this data into the AEPacketRaw and the 
     * consumer (the event extractor) interprets these to make events.
     * 
     * @return the raw RGBA pixel data from frames of the camera. The pixel data is packed in the AEPacketRaw addresses array. The pixel color data depends on the CameraMode of the CLCamera.
     * The timestamp of the frame is in the first timestamp of the packets timestamp array - the rest of the elements are untouched. The timestamps are untouched except for the first one, which is set to the System.currentTimeMillis*1000-startTimeUs.
     *
     */
    @Override
    public AEPacketRaw acquireAvailableEventsFromDriver() throws HardwareInterfaceException {
        // check camera running
        if (!camera.isStarted) return null;
        
        // keep consuming until queue empty
        int nframes = camera.stream.available();
        if (nframes == 0) return null;
        frame.setSize(camera.stream.getFrameX(), camera.stream.getFrameY(),
                    camera.stream.getPixelSize());
        int frameSize = frame.getSize();
        packet.ensureCapacity(nframes * frameSize);
        packet.numFrames = 0;
        
        int[] addresses = packet.getAddresses();
        
        // loop across available frames
        while (packet.numFrames < nframes) {
            frame.setData(IntBuffer.wrap(addresses, packet.numFrames * frameSize, frameSize));
            if (camera.getFrame(frame)) {
                packet.getTimestamps()[packet.numFrames * frameSize] = (int) (frame.getTimeStamp() - startTimeUs);
                packet.numFrames++;
                
                frameCounter++; // TODO notify AE listeners here or in thread acquiring frames
            }
        }
        packet.setNumEvents(nframes * frameSize);
        packet.setNumFrames(nframes);
        packet.setFrameSize(frameSize);
        support.firePropertyChange(newEventPropertyChange);
        return (AEPacketRaw) packet;
    }

    @Override
    public int getNumEventsAcquired() {
        if (packet == null) {
            return 0;
        } else {
            return packet.getNumEvents();
        }
    }

    /** Returns the collected event packet.
     * 
     * @return the packet of raw events, consisting of the pixels values.
     */
    @Override
    public AEPacketRaw getEvents() {
        return (AEPacketRaw) packet;
    }

    /** Resets the timestamps to the current system time in ms.
     * 
     */
    @Override
    public void resetTimestamps() {
        frameCounter = 0;
        startTimeUs = System.currentTimeMillis() * 1000;
    }

    @Override
    public boolean overrunOccurred() {
        return false;
    }

    @Override
    public int getAEBufferSize() {
        return 0;
    }

    @Override
    public void setAEBufferSize(int AEBufferSize) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    /** Starts and stops the camera.
     * 
     * @param enable true to run the camera
     * @throws HardwareInterfaceException 
     */
    @Override
    public void setEventAcquisitionEnabled(boolean enable) throws HardwareInterfaceException {
        if (enable) {
            camera.start();
        } else {
            camera.stop();
        }
    }

    @Override
    public boolean isEventAcquisitionEnabled() {
        return camera.isStarted;
    }

    /** Listeners are called on every new frame of data.
     * 
     * @param listener 
     */
    @Override
    public void addAEListener(AEListener listener) {
        support.addPropertyChangeListener(listener);
    }

    @Override
    public void removeAEListener(AEListener listener) {
        support.removePropertyChangeListener(listener);
    }

    @Override
    public int getMaxCapacity() {
        return 0;
    }

    public C getCamera() {
        return camera;
    }

    public void setCamera(C camera) {
        this.camera = camera;
    }

    @Override
    public int getEstimatedEventRate() {
        return 0;
    }

    @Override
    public int getTimestampTickUs() {
        return 1;
    }

    @Override
    public void setChip(AEChip chip) {
        this.chip = chip;
    }

    @Override
    public AEChip getChip() {
        return chip;
    }
    
    @Override
    public String toString() {
        return camera.toString();
    }

    /* Overrides from HardwareInterface extended by AEMonitorInterface.
     * Functions are forwarded to camera. */
    @Override public String getTypeName() { return camera.getTypeName(); }
    @Override public void close() { camera.close(); }
    @Override public void open() throws HardwareInterfaceException { camera.open(); }
    @Override public boolean isOpen() { return camera.isOpen(); }
}
