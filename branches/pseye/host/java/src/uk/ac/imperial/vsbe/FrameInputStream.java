
package uk.ac.imperial.vsbe;

import java.util.concurrent.Callable;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.ExecutionException;

/* Package private class to handle frame data thread producer and 
 * and consumer 
 */
public class FrameInputStream implements FrameStreamable {
    /* Variables used by threaded data capture from camera */
    /* Number of buffers in consumer and producer queues */
    protected static final int BUFFER_SIZE = 6;
    protected int bufferSize;    
    protected ArrayBlockingQueue<Frame> consumerQueue;
    protected ArrayBlockingQueue<Frame> producerQueue;
    
    /* frame producer thread */
    protected FrameProducer producer;
    /* flag to show producer/consumer running */
    protected volatile boolean running = false;

    // service and return status for running data capture thread
    protected ExecutorService executor;
    protected Future<Boolean> status;
    
    protected FrameStreamable source = null;
    /* current frame size, volatile to ensure all frames of consistent size between threads */
    public int frameSize;
    protected long timeStamp = 0;
        
    public FrameInputStream()  {
        this(BUFFER_SIZE);
    }
    
    public FrameInputStream(int bufferSize) 
    {
        this.bufferSize = bufferSize;
        consumerQueue = new ArrayBlockingQueue<Frame>(bufferSize);
        producerQueue = new ArrayBlockingQueue<Frame>(bufferSize);

        /* create initial frames */
        while (producerQueue.remainingCapacity() > 0)  {
            producerQueue.offer(new Frame());
        }
        
        // Create new thread for reading from camera or stop any existing thread
        executor = Executors.newSingleThreadExecutor();
        
        // Create producer
        producer = new FrameProducer(this);
    }
               
    /* start producing frames */
    public synchronized void open(FrameStreamable source) {
        if (running) close();
        
        // set source
        this.source = source;

        running = true;
        status = executor.submit(producer);
    }
    
        // close stream cleaning up
    public synchronized void close() {
        if (!running) return;
        
        // wait until producer thread had completed
        running = false;
        if (status != null) {
            try {
                status.get();
            } 
            catch (ExecutionException e) {}
            catch (InterruptedException e) {}
        }
        source = null;
    }
    
    /* destroy thread not used leave to garbage collector
    public void destroy() {
        // shutdown thread and wait maximum 10 seconds for threads to end
        executor.shutdown();
        try {
            executor.awaitTermination(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {}
        executor = null;
    }
    */    
    
    // return number of available frames
    public synchronized int available() {
        return consumerQueue.size();
    }
    
    public synchronized long getLastTimeStamp() {
        return timeStamp;
    }
    
    // streamable methods
    @Override
    public synchronized boolean readFrameStream(int[] imgData, int offset) {
        if (!running) return false;
        
        // get frame from consumer queue
        Frame frame = consumerQueue.poll();
        if (frame == null) return false;
            
        // copy frame data to passed array
        frame.copyData(imgData, offset);
        timeStamp = frame.getTimeStamp();
            
        // put frame back into producer queue
        producerQueue.offer(frame);
        
        return true;
    }
    
    /* Used to get frame extent */
    @Override
    public int getFrameX() {
        if (source != null) return source.getFrameX();
        else return 0;
    }
    
    @Override
    public int getFrameY() {
        if (source != null) return source.getFrameY();
        else return 0;
    };
    
    /* Used to get frame pixel size in bytes */
    @Override
    public int getPixelSize() {
        if (source != null) return source.getPixelSize();
        else return 0;   
    }
    
    class FrameProducer implements Callable<Boolean> {
        private FrameInputStream stream;
        private int frameSize;
            
        public FrameProducer(FrameInputStream stream) 
        {
            this.stream = stream;
        }
        
        @Override
        public Boolean call() {
            Frame frame = null;
            
            // calculate frame size
            frameSize = stream.getPixelSize() * stream.getFrameX() * stream.getFrameY();
        
            // set queued frame sizes
            for (Frame f : stream.producerQueue) {
                    f.setSize(frameSize);
            }
            
            // boolean signal to stop thread (volatile and atomic)
            while (stream.running) {
                // get usable frame from producer queue
                if (frame == null) frame = stream.producerQueue.poll();
                
                if (frame != null) {
                    // check for return of frame data
                    // no need to sleep here as wait time out will accomplish same thing
                    if (stream.source.readFrameStream(frame.getData(), 0)) {
                        frame.setTimeStamp(System.currentTimeMillis() * 1000);
                        // place filled frame in consumer queue
                        stream.consumerQueue.offer(frame);
                        frame = null;
                    }
                }
                else {
                    // make thread wait - used for consumer to catch up
                    try {
                        Thread.sleep(50);
                    } catch (InterruptedException e) {}
                }
            }

            // thread stopped but still have an active frame so return
            if (frame != null) stream.producerQueue.offer(frame);
            
            // ensure all frames are in the producer queue
            frame = consumerQueue.poll();
            while (frame != null) {
                producerQueue.offer(frame);
                frame = consumerQueue.poll();
            }
            
            return true;
        }
    }
}    
