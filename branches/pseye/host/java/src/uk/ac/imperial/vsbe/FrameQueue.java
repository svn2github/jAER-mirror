
package uk.ac.imperial.vsbe;

import java.util.concurrent.Callable;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.ExecutionException;

/*
 * Class to create single consumer / producer thread for acquiring frame data
 * from a conventional camera.
 * Implements FrameSource to allow chaining
 * 
 * NOTE: does not handle frame size changes, needs to be re-opened
 * 
 * @author mlk11
 */
public class FrameQueue implements FrameSource {
    /* Default number of frames in consumer and producer queues */
    protected static final int BUFFER_SIZE = 8;
    protected int bufferSize;    
    protected ArrayBlockingQueue<Frame> consumerQueue;
    protected ArrayBlockingQueue<Frame> producerQueue;
    
    /* Frame producer thread */
    protected FrameProducer producer;
    /* Flag to show producer/consumer running */
    protected volatile boolean running = false;

    /* Service and return status for running data capture thread */
    protected ExecutorService executor;
    protected Future<Boolean> status;
    
    /* source to collect frames from */
    protected FrameSource source = null;
    
    /* Construct queue with default buffer size  
     * 
     */
    public FrameQueue()  {
        this(BUFFER_SIZE);
    }
    
    /* Construct queue  
     * 
     * @param bufferSize: Number of frames for producer / consumer queues
     */
    public FrameQueue(int bufferSize) 
    {
        // Create blocking queues
        this.bufferSize = bufferSize;
        consumerQueue = new ArrayBlockingQueue<Frame>(bufferSize);
        producerQueue = new ArrayBlockingQueue<Frame>(bufferSize);

        // Fill producer queue with empty frames
        while (producerQueue.remainingCapacity() > 0)  {
            producerQueue.offer(new Frame());
        }
        
        // Create new thread for reading from camera
        executor = Executors.newSingleThreadExecutor();
        
        // Create producer
        producer = new FrameProducer(this);
    }
               
    /* Start collecting frames  
     * 
     * @param source: Source of frame data using read
     */
    public synchronized void open(FrameSource source) {
        // Close threads if already open
        if (running) close();
        
        // Set source
        this.source = source;
        if (source != null) {
            // Start the producer thread
            running = true;
            status = executor.submit(producer);
        }
    }
    
    /* Stop collecting frames and close producer thread
     * 
     */
    public synchronized void close() {
        // Return if not running
        if (!running) return;
        
        // Wait for producer thread to complete
        running = false;
        if (status != null) {
            try {
                // Busy wait 
                status.get();
            } 
            catch (ExecutionException e) {}
            catch (InterruptedException e) {}
        }
        // Remove reference to source for GC
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
    
    /* Number of available frames 
     * 
     * @return: Number of frames in consumer queue
     */
    public synchronized int available() {
        return consumerQueue.size();
    }
    
    /* Overrides of FrameSource */
    
    /* Copy the consumed frame data
     * 
     * @param imgData: buffer to copyInPlace data to
     * @param offset: offset in imgData to copyInPlace data to
     * @return: true on success
     */
    @Override
    public synchronized boolean read(Frame frame, boolean inPlace) {
        // Check running
        if (!running) return false;
        
        // Get frame from consumer queue
        Frame f = null;
        
        // Copy frame data to passed array
        if (!inPlace) {
            f = consumerQueue.peek();
            if (f == null) return false;
            return f.copy(frame);
        }
        
        f = consumerQueue.poll();
        if (f == null) return false;
        boolean copied = f.copyInPlace(frame);  
        // Put read frame back into producer queue
        producerQueue.offer(f);
        
        return copied;
    }
    
    /* Return frame X extent from source
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of horizontal pixels
     */
    @Override
    public int getFrameX() {
        if (source != null) return source.getFrameX();
        else return 0;
    }
    
    /* Return frame Y extent from source
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of vertical pixels
     */ 
    @Override
    public int getFrameY() {
        if (source != null) return source.getFrameY();
        else return 0;
    };
    
    /* Return pixel size in int from source
     * Used to ensure all buffers have correct capacity.
     * 
     * @return Number of integers used by each pixels to represent data
     */
    @Override
    public int getPixelSize() {
        if (source != null) return source.getPixelSize();
        else return 0;   
    }
    
    /* 
     * Inner class wrapping frame producer thread  
     * 
     */
    class FrameProducer implements Callable<Boolean> {
        private FrameQueue queue;
        
        /* Construct producer for passed queue
         * 
         * @param queue: FramQueue producer belongs to
         */
        public FrameProducer(FrameQueue queue) 
        {
            this.queue = queue;
        }
        
        /* Function called by thread
         * 
         * @return: true when complete
         */
        @Override
        public Boolean call() {
            Frame frame = null;

            // Set frame sizes
            for (Frame f : queue.producerQueue) {
                    f.setSize(queue.getFrameX(), queue.getFrameY(),
                            queue.getPixelSize());
            }
            
            while (queue.running) {
                // Get usable frame from producer queue
                if (frame == null) frame = queue.producerQueue.poll();
                
                if (frame != null) {
                    // Check for return of frame data
                    if (queue.source.read(frame, true)) {
                        frame.setTimeStamp(System.currentTimeMillis() * 1000);
                        // Place filled frame in consumer queue
                        queue.consumerQueue.offer(frame);
                        frame = null;
                    }
                }
                else {
                    // Make thread wait - used to allow consumer to catch up
                    try {
                        Thread.sleep(50);
                    } catch (InterruptedException e) {}
                }
            }

            // Thread stopped but still have an active frame so return to consumer
            if (frame != null) queue.producerQueue.offer(frame);
            
            // Ensure all frames are returned to producer queue
            frame = consumerQueue.poll();
            while (frame != null) {
                producerQueue.offer(frame);
                frame = consumerQueue.poll();
            }
            
            return true;
        }
    }
}    
