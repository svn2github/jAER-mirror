package net.sf.jaer.graphics;
import com.jogamp.opengl.GLException;
import java.awt.Component;
import java.awt.Container;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.io.EOFException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import javax.swing.JFileChooser;
import javax.swing.filechooser.FileFilter;

import net.sf.jaer.aemonitor.AEPacketRaw;
import net.sf.jaer.eventio.AEDataFile;
import net.sf.jaer.eventio.AEFileInputStream;
import net.sf.jaer.eventio.AEFileInputStreamInterface;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.util.DATFileFilter;
import net.sf.jaer.util.IndexFileFilter;
/**
 * Handles file input of AEs to control the number of
 * events/sample or period of time in the sample, etc.
 * It handles the file input stream, opening a dialog box, etc.
 * It also handles synchronization of different AEViewers as follows
 * (this refers to multiple-AEViewer time-locked playback synchronization, not
 * java object locking):
 * <p>
 * If the viewer is not synchronized, then all calls from the GUI
 * are passed directly
 * to this instance of AEPlayer. Thus local control always happens.
 * <p>
 * If the viewer is synchronized, then all GUI calls pass
 * instead to the JAERViewer instance that contains
 * (or started) this viewer. Then the JAERViewer AEPlayer
 * calls all the viewers to take the player action (e.g. rewind,
 * go to next slice, change direction).
 * <p>
 * Thus whichever controls the user uses to control playback,
 * the viewers are all synchronized properly without recursively.
 * The "master" is indicated by the GUI action,
 * which routes the request either to this instance's AEPlayer
 * or to the JAERViewer AEPlayer.
 */
public class AEPlayer extends AbstractAEPlayer implements AEFileInputStreamInterface{
    boolean fileInputEnabled = false;
    JFileChooser fileChooser;

    /** Make a new AEPlayer
     *
     * @param viewer the viewer who is using us.
     * @param viewer from refactoring, refers to the same viewer
     */
    public AEPlayer (AEViewer viewer){
        super(viewer);
    }

    private boolean isSyncEnabled(){
        return viewer.getJaerViewer().isSyncEnabled();
    }

    @Override
    public boolean isChoosingFile (){
        return fileChooser != null && fileChooser.isVisible();
    }
    FileFilter lastFilter = null;

    /** Called when user asks to open data file file dialog.
     */
    @Override
    public void openAEInputFileDialog (){
//        try{Thread.currentThread().sleep(200);}catch(InterruptedException e){}
        float oldScale = viewer.chipCanvas.getScale();
        fileChooser = new JFileChooser();
//            new TypeAheadSelector(fileChooser);
        //com.sun.java.plaf.windows.WindowsFileChooserUI;
//            fileChooser.addKeyListener(new KeyAdapter() {
//                public void keyTyped(KeyEvent e){
//                    System.out.println("keycode="+e.getKeyCode());
//                }
//            });
//            System.out.println("fileChooser.getUIClassID()="+fileChooser.getUIClassID());
//            KeyListener[] keyListeners=fileChooser.getKeyListeners();
        ChipDataFilePreview preview = new ChipDataFilePreview(fileChooser,viewer.getChip());
        // from book swing hacks
        new FileDeleter(fileChooser,preview);
        fileChooser.addPropertyChangeListener(preview);
        fileChooser.setAccessory(preview);
        String lastFilePath = AEViewer.prefs.get("AEViewer.lastFile","");
        // get the last folder
        viewer.lastFile = new File(lastFilePath);
//            fileChooser.setFileFilter(datFileFilter);
        IndexFileFilter indexFileFilter = new IndexFileFilter();
        fileChooser.addChoosableFileFilter(indexFileFilter);
        DATFileFilter datFileFilter = new DATFileFilter();
        fileChooser.addChoosableFileFilter(datFileFilter);
        if ( lastFilter == null ){
            fileChooser.setFileFilter(datFileFilter);
        } else{
            fileChooser.setFileFilter(lastFilter);
        }
        fileChooser.setCurrentDirectory(viewer.lastFile);
        // sets the working directory of the chooser
//            boolean wasPaused=isPaused();
        setPaused(true);
        try{
            int retValue = fileChooser.showOpenDialog(viewer);
            if ( retValue == JFileChooser.APPROVE_OPTION ){
                lastFilter = fileChooser.getFileFilter();
                try{
                    viewer.lastFile = fileChooser.getSelectedFile();
                    if ( viewer.lastFile != null ){
                        viewer.recentFiles.addFile(viewer.lastFile);
                    }
                    startPlayback(viewer.lastFile);
                } catch ( IOException fnf ){
                    log.warning(fnf.toString());
                }
            } else{
                preview.showFile(null);
            }
        }catch(GLException e){
            log.warning(e.toString());
            preview.showFile(null);
        }
        fileChooser = null;
//        viewer.chipCanvas.setScale(oldScale);
        // restore persistent scale so that we don't get tiny size on next startup
        setPaused(false);
    }

    @Override
    public void setDoSingleStepEnabled (boolean b){
        viewer.doSingleStepEnabled = b;
    }

    @Override
    public void doSingleStep (){
//        log.info("doSingleStep");
        viewer.setDoSingleStepEnabled(true);
    }

  
    
    public class FileDeleter extends KeyAdapter implements PropertyChangeListener{
        private JFileChooser chooser;
        private ChipDataFilePreview preview;
        File file = null;

        /** adds a key-released listener on the JFileChooser FilePane inner classes so that user can use Delete key to delete the file
         * that is presently being shown in the preview window
         * @param chooser the chooser
         * @param preview the data file preview
         */
        public FileDeleter (JFileChooser chooser,ChipDataFilePreview preview){
            super();
            this.chooser = chooser;
            this.preview = preview;
            chooser.addPropertyChangeListener(JFileChooser.SELECTED_FILE_CHANGED_PROPERTY,this);
            Component comp = addDeleteListener(chooser);
        }

        /** is called when the file selection is changed. Bound to the SELECTED_FILE_CHANGED_PROPERTY. */
   @Override
         public void propertyChange (PropertyChangeEvent evt){
            // comes from chooser when new file is selected
            if ( evt.getNewValue() instanceof File ){
                file = (File)evt.getNewValue();
            } else{
                file = null;
            }
        }

        private Component addDeleteListener (Component comp){
//            System.out.println("");
//            System.out.println("comp="+comp);
//            if (comp.getClass() == sun.swing.FilePane.class) return comp;
            if ( comp instanceof Container ){
//                System.out.println(comp+"\n");
//                comp.addMouseListener(new MouseAdapter(){
//                    public void mouseEntered(MouseEvent e){
//                        System.out.println("mouse entered: "+e);
//                    }
//                });
                // if this is a known filepane class, then add a key listener for deleting log files.
                // may need to remove this in future release of java and
                //find a portable way to detect we are in the FilePane
//                    if(comp.getClass().getEnclosingClass()==sun.swing.FilePane.class) {
//                        System.out.println("******adding keyListener to "+comp);
                comp.addKeyListener(new KeyAdapter(){
                    @Override
                    public void keyReleased (KeyEvent e){
                        if ( e.getKeyCode() == KeyEvent.VK_DELETE ){
//                                    System.out.println("delete key typed from "+e.getSource());
                            deleteFile();
                        }
                    }
                });
//                    }
                Component[] components = ( (Container)comp ).getComponents();
                for ( int i = 0 ; i < components.length ; i++ ){
                    Component child = addDeleteListener(components[i]);
                    if ( child != null ){
                        return child;
                    }
                }
            }
            return null;
        }

        void deleteFile (){
            if ( file == null ){
                return;
            }
            log.fine("trying to delete file " + file);
            preview.deleteCurrentFile();
        }
    }

    /** Starts playback on the data file.
    If the file is an index file,
    the JAERViewer is called to start playback of the set of data files.
    Fires a property change event "fileopen", after playMode is changed to PLAYBACK.
    @param file the File to play.
     */
    @Override
    public synchronized void startPlayback (File file) throws IOException{
        log.info("starting playback with file="+file);
        super.startPlayback(file);
        if ( file == null || !file.isFile() ){
            throw new FileNotFoundException("file not found: " + file);
        }
        // idea is that we set open the file and set playback mode and the ViewLoop.run
        // loop will then render from the file.
        // TODO problem is that ViewLoop run loop is still running
        // and opens hardware during this call, esp at high frame rate,
        // which sets playmode LIVE, ignoring open file and playback.
        String ext="."+IndexFileFilter.getExtension(file); // TODO change to use of a new static method in AEDataFile for determining file type
        if (ext.equals(AEDataFile.INDEX_FILE_EXTENSION) || ext.equals(AEDataFile.OLD_INDEX_FILE_EXTENSION) ){
            if ( viewer.getJaerViewer() != null ){
                viewer.getJaerViewer().getSyncPlayer().startPlayback(file);
            }
            return;
        }
//            System.out.println("AEViewer.starting playback for DAT file "+file);
        viewer.setCurrentFile(file);
        int tries=20;
        while(viewer.getChip()==null && tries-->0){
            log.info("null AEChip in AEViewer, waiting... "+tries);
            try {
                Thread.sleep(500);
            } catch (InterruptedException ex) {
                break;
            }
        }
        if(viewer.getChip()==null){
            throw new IOException("chip is not set in AEViewer so we cannot contruct the file input stream for it");
        }
        aeFileInputStream = viewer.getChip().constuctFileInputStream(file); // new AEFileInputStream(file);
        aeFileInputStream.setNonMonotonicTimeExceptionsChecked(viewer.getCheckNonMonotonicTimeExceptionsEnabledCheckBoxMenuItem().isSelected());
        aeFileInputStream.setTimestampResetBitmask(viewer.getAeFileInputStreamTimestampResetBitmask());
        aeFileInputStream.setFile(file);
        aeFileInputStream.getSupport().addPropertyChangeListener(viewer);
        // so that users of the stream can get the file information
        if ( viewer.getJaerViewer() != null && viewer.getJaerViewer().getViewers().size() == 1 ){
            // if there is only one viewer, start it there
            try{
                aeFileInputStream.rewind();
            } catch ( IOException e ){
                e.printStackTrace();
            }
        }
        // don't waste cycles grabbing events while playing back
            viewer.setPlayMode(AEViewer.PlayMode.PLAYBACK);
        // TODO ugly remove/add of new control panel to associate it with correct player
//            playerControlPanel.remove(getPlayerControls());
//            setPlayerControls(new AePlayerAdvancedControlsPanel(AEViewer.this));
//            playerControlPanel.add(getPlayerControls());
        viewer.getPlayerControls().addMeToPropertyChangeListeners(aeFileInputStream);
        // so that slider is updated when position changes
        viewer.setPlaybackControlsEnabledState(true);
        viewer.fixLoggingControls();
            // TODO we grab the monitor for the viewLoop here, any other thread which may change playmode should also grab it
        if ( viewer.aemon != null && viewer.aemon.isOpen() ){
            try{
                if ( viewer.getPlayMode().equals(viewer.getPlayMode().SEQUENCING) ){
                    viewer.stopSequencing();
                } else{
                    viewer.aemon.setEventAcquisitionEnabled(false);
                }
            } catch ( HardwareInterfaceException e ){
                e.printStackTrace();
            }
        }
        getSupport().firePropertyChange(EVENT_FILEOPEN,null,file);
    }

    /** stops playback.
     *If not in PLAYBACK mode, then just returns.
     *If playing  back, could be waiting during sleep or during CyclicBarrier.await call in CaviarViewer. In case this is the case, we send
     *an interrupt to the the ViewLoop thread to stop this waiting.
     */
   @Override
     public void stopPlayback (){
        if ( viewer.getPlayMode() != AEViewer.PlayMode.PLAYBACK ){
            return;
        }

        if ( viewer.aemon != null && viewer.aemon.isOpen() ){
            try{
                viewer.aemon.setEventAcquisitionEnabled(true);
            } catch ( HardwareInterfaceException e ){
                viewer.setPlayMode(AEViewer.PlayMode.WAITING);
                e.printStackTrace();
            }
            viewer.setPlayMode(AEViewer.PlayMode.LIVE);
        } else{
            viewer.setPlayMode(AEViewer.PlayMode.WAITING);
        }
        viewer.setPlaybackControlsEnabledState(false);
        try{
            if ( aeFileInputStream != null ){
                aeFileInputStream.close();
                aeFileInputStream = null;
            }
        } catch ( IOException ignore ){
            ignore.printStackTrace();
        }
        viewer.setTitleAccordingToState();
    }

    @Override
    public void rewind (){
        if ( aeFileInputStream == null ){
            return;
        }
//            System.out.println(Thread.currentThread()+" AEViewer.AEPlayer.rewind() called, rewinding "+aeFileInputStream);
        try{
            aeFileInputStream.rewind();
            viewer.filterChain.reset();
        } catch ( Exception e ){
            log.warning("rewind exception: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public void pause (){
        super.pause();
        viewer.setPaused(true);
    }

    @Override
    public void resume (){
        super.resume();
        viewer.setPaused(false);
    }

    /** sets the AEViewer paused flag */
    @Override
    public void setPaused (boolean yes){
        super.setPaused(yes);
        viewer.setPaused(yes);
    }

    /** gets the AEViewer paused flag */
    @Override
    public boolean isPaused (){
        return viewer.isPaused();
    }

   @Override
     public AEPacketRaw getNextPacket (){
        return getNextPacket(null);
    }

   @Override
     public AEPacketRaw getNextPacket (AbstractAEPlayer player){
        if ( player != this ){
            throw new UnsupportedOperationException("tried to get data from some other player");
        }
        AEPacketRaw aeRaw = null;
        try{
            if ( !viewer.aePlayer.isFlexTimeEnabled() ){
                aeRaw = aeFileInputStream.readPacketByTime(viewer.getAePlayer().getTimesliceUs());
            } else{
                aeRaw = aeFileInputStream.readPacketByNumber(viewer.getAePlayer().getPacketSizeEvents());
            }
//                if(aeRaw!=null) time=aeRaw.getLastTimestamp();
            return aeRaw;
        } catch ( EOFException e ){
            try{
                Thread.sleep(200);
            } catch ( InterruptedException ignore ){
            }
            // when we get to end, we now just wraps in either direction, to make it easier to explore the ends
//                System.out.println("***********"+this+" reached EOF, calling rewind");
            if(repeat){
                viewer.getAePlayer().rewind();
            }
            // we force a rewind on all players in case we are not the only one
//                                if(!aePlayer.isPlayingForwards())
            //getAePlayer().toggleDirection();
            return aeRaw;
        } catch ( Exception anyOtherException ){
            log.warning(anyOtherException.toString() + ", returning empty AEPacketRaw");
            anyOtherException.printStackTrace();
            return new AEPacketRaw(0);
        }
    }

    /** Tries to adjust timeslice to approach realtime playback.
     *
     */
    @Override
    public void adjustTimesliceForRealtimePlayback (){
        if ( !isRealtimeEnabled() || isPaused() ){
            return;
        }
        float fps = viewer.getFrameRater().getAverageFPS();
        float samplePeriodS = getTimesliceUs() * 1.0E-6F;
        float factor = fps * samplePeriodS;
//            System.out.println("fps=" + fps + " samplePeriodS=" + samplePeriodS + " factor=" + factor);
//            if ( factor < 1.2 || factor > 0.8f ){
        setTimesliceUs((int)( getTimesliceUs() / factor ));
    }

    @Override
    public float getFractionalPosition (){
        if ( aeFileInputStream == null ){
            log.warning("AEViewer.AEPlayer.getFractionalPosition: null fileAEInputStream, returning 0");
            return 0;
        }
        float fracPos = aeFileInputStream.getFractionalPosition();
        return fracPos;
    }

    @Override
    public long position (){
        return aeFileInputStream.position();
    }

   @Override
     public void position (long event){
        aeFileInputStream.position(event);
    }

   @Override
     public AEPacketRaw readPacketByNumber (int n) throws IOException{
        return aeFileInputStream.readPacketByNumber(n);
    }

    @Override
    public AEPacketRaw readPacketByTime (int dt) throws IOException{
        return aeFileInputStream.readPacketByTime(dt);
    }

     @Override
   public long size (){
        return aeFileInputStream.size();
    }

    @Override
    public void clearMarks() {
        aeFileInputStream.clearMarks();
    }

    @Override
    public long getMarkInPosition() {
        return aeFileInputStream.getMarkInPosition();
    }

    @Override
    public long getMarkOutPosition() {
        return aeFileInputStream.getMarkOutPosition();
    }

    @Override
    public boolean isMarkInSet() {
        return aeFileInputStream.isMarkInSet();
    }

    @Override
    public boolean isMarkOutSet() {
        return aeFileInputStream.isMarkOutSet();
    }

      @Override
    public long setMarkIn() {
        return aeFileInputStream.setMarkIn();
    }

    @Override
    public long setMarkOut() {
        return aeFileInputStream.setMarkOut();
    }
     
     
    @Override
    public void setFractionalPosition (float frac){
        aeFileInputStream.setFractionalPosition(frac);
    }

    @Override
    public void setTime (int time){
//            System.out.println(this+".setTime("+time+")");
        if ( aeFileInputStream != null ){
            aeFileInputStream.setCurrentStartTimestamp(time);
        } else{
            log.warning("null AEInputStream");
            Thread.dumpStack();
        }
    }

    @Override
    public int getTime (){
        if ( aeFileInputStream == null ){
            return 0;
        }
        return aeFileInputStream.getMostRecentTimestamp();
    }

    @Override
    public AEFileInputStream getAEInputStream (){
        return aeFileInputStream;
    }
    
    /**
     * Returns state of repeat.
     *
     * @return true if the playback is repeated.
     */
    @Override
    public boolean isRepeat() {
        return aeFileInputStream.isRepeat();
    }

    /**
     * repeats playback. Fires property change "paused" or "resumed".
     *
     * @param yes true to pause, false to resume.
     */
    @Override
    public void setRepeat(boolean yes) {
        boolean old = repeat;
        repeat = yes;
        support.firePropertyChange(repeat ? EVENT_REPEAT_ON : EVENT_REPEAT_OFF, old, repeat);
        aeFileInputStream.setRepeat(repeat);
    }

  /** Says if checking for non-monotonic timestamps in input file is enabled.
     * 
     * @return true if enabled.
     */    
    @Override
    public boolean isNonMonotonicTimeExceptionsChecked (){
        if ( aeFileInputStream == null ){
            return false;
        }
        return aeFileInputStream.isNonMonotonicTimeExceptionsChecked();
    }

    /** Enables or disables checking for non-monotonic timestamps in input file.
     * 
     * @param yes true to check and log exceptions (up to some limit)
     */
    @Override
    public void setNonMonotonicTimeExceptionsChecked (boolean yes){
        if ( aeFileInputStream == null ){
            log.warning("null fileAEInputStream");
            return;
        }
        aeFileInputStream.setNonMonotonicTimeExceptionsChecked(yes);
    }
}
