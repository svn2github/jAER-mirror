
package uk.ac.imperial.vsbe;

import java.nio.IntBuffer;

/*
 * Class used to wrap frame data for a standard camera implementation in VSBE.
 * 
 * @author mlk
 */
public class Frame {
    private long timeStamp;
    private IntBuffer data;
    private int size = 0;
        
    public Frame() {
    }
        
    public int getSize() {
        return size;
    }
    
    public void setSize(int size) {
        if (size != this.size) {
            this.size = size;
            data = IntBuffer.allocate(size);
        }
    }
    
    public long getTimeStamp() {
        return timeStamp;
    }
    
    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }
    
    public IntBuffer getData() {
        return data;
    }

    public void setData(IntBuffer data) {
        this.data = data;
    }
    
    public boolean copyData(Frame frame) {
        // copyData frame data to passed array
        if (frame.size != size) return false;
        if (!data.hasArray() || !frame.getData().hasArray()) return false;
        frame.timeStamp = timeStamp;
        System.arraycopy(data.array(), 0, frame.getData().array(), 0, size);
        return true;
    }
    
    /*
    public boolean deepCopy(Frame frame) {
        if (!data.hasArray()) return false;
        frame.setSize(size);
        frame.timeStamp = timeStamp;
        System.arraycopy(data.array(), 0, frame.getData().array(), 0, size);
        return true;
    }
     */
}