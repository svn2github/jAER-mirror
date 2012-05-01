

package uk.ac.imperial.vsbe;

import net.sf.jaer.aemonitor.AEPacketRaw;
import java.util.Collection;

/**
 * Wrapper to add frame size information to packet, necessary due to frame size changes
 * 
 * @author mlk11
 */
public class CameraFramePacketRaw extends AEPacketRaw {
    public int frameSize;
    public int nFrames;

    public CameraFramePacketRaw() {
        super();
    }

    public CameraFramePacketRaw(int[] addresses, int[] timestamps) {
        super(addresses, timestamps);
    }

    public CameraFramePacketRaw(int size) {
        super(size);
    }
    
    public CameraFramePacketRaw(AEPacketRaw one, AEPacketRaw two) {
        super(one, two);
    }

    public CameraFramePacketRaw(Collection<AEPacketRaw> collection) {
        super(collection);
    }
    
}
