
package uk.ac.imperial.vsbe;

import net.sf.jaer.aemonitor.AEPacketRaw;
import java.util.Collection;

/*
 * Class used for adding discrete frame parameters to a AEPacketRaw.
 * Can be extended later if necessary.
 * 
 * @author mlk
 */
public class CameraAEPacketRaw extends AEPacketRaw {
    /* Number of pixels in frame */
    public int frameSize;
    /* Number of frames in packet */
    public int nFrames;

    public CameraAEPacketRaw() {
        super();
    }

    public CameraAEPacketRaw(int[] addresses, int[] timestamps) {
        super(addresses, timestamps);
    }

    public CameraAEPacketRaw(int size) {
        super(size);
    }
    
    public CameraAEPacketRaw(AEPacketRaw one, AEPacketRaw two) {
        super(one, two);
    }

    public CameraAEPacketRaw(Collection<AEPacketRaw> collection) {
        super(collection);
    }
}
