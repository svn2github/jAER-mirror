
package uk.ac.imperial.vsbe;

/* Package private wrapper class for PSEye frame data */
class Frame {
    private long timeStamp;
    private int[] data;
    private int size = 0;
        
    public Frame() {
    }
        
    public int getSize() {
        return size;
    }
    
    public void setSize(int size) {
        if (size != this.size) {
            this.size = size;
            data = new int[size];
        }
    }
    
    public long getTimeStamp() {
        return timeStamp;
    }
    
    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }
    
    public int[] getData() {
        return data;
    }
    
    public void copyData(int[] target, int offset) {
        // copy frame data to passed array
        System.arraycopy(data, 0, target, offset, getSize());
    }
}