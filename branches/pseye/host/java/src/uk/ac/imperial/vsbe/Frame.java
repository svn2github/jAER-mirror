
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
    
    private int width;
    private int height;
    private int pixelSize;
    private int size = 0;
        
    public Frame() {
    }
        
    public int getPixelSize() {
        return pixelSize;
    }

    public void setPixelSize(int pixelSize) {
        this.pixelSize = pixelSize;
    }

    public int getWidth() {
        return width;
    }

    public void setWidth(int x) {
        width = x;
    }

    public int getHeight() {
        return height;
    }

    public void setHeight(int y) {
        height = y;
    }
    
    public int getSize() {
        return size;
    }
    
    public void setSize(int width, int height, int pixelSize) {
        this.width = width;
        this.height = height;
        this.pixelSize = pixelSize;
        int size = width * height * pixelSize;
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
        // copyInPlace frame data to passed array
        if (frame.size != size) return false;
        if (!frame.getData().hasArray()) return false;
        frame.timeStamp = timeStamp;
        if (data.hasArray()) {
            System.arraycopy(data.array(), 0, frame.getData().array(), frame.getData().position(), size);
        }
        return true;
    }
    
    public boolean copy(Frame frame) {
        frame.timeStamp = timeStamp;
        frame.setSize(width, height, pixelSize);
        if (data.hasArray()) {
            System.arraycopy(data.array(), 0, frame.getData().array(), frame.getData().position(), size);
        }
        return true;
    }
}