
package uk.ac.imperial.vsbe;

/**
 * Interface need for object to be called by a frame stream
 * @author mlk11
 */
public interface FrameStreamable {
    /* method called to get frame, non-blocking and returns true if sucessful */
    public boolean readFrameStream(int[] imgData, int offset);
    
    /* Used to get frame extent */
    public int getFrameX();
    public int getFrameY();
    
    /* Used to get frame pixel size in bytes */
    public int getPixelSize();
}
