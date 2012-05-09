
package uk.ac.imperial.vsbe;

/*
 * Interface used by object when called by a multi threaded frame queue
 * 
 * @author mlk11
 */
public interface FrameSource {
    /* Copy contents of frame queue  
     * Non-blocking and returns true if sucessful.
     * 
     * @param frame: data frame data is copied to  
     * @return true if data copied, false if not
     */
    public boolean read(Frame frame);
    
    /* Return frame X extent
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of horizontal pixels
     */
    public int getFrameX();
    
    /* Return frame Y extent
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of vertical pixels
     */    
    public int getFrameY();
    
    /* Return pixel size in int
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of integers used by each pixels to represent data
     */
    public int getPixelSize();
}
