/*
 * FViewer.java
 *
 * Created on December 24, 2005, 1:58 PM
 */

package ch.unizh.ini.caviar.graphics;

import ch.unizh.ini.caviar.*;
import ch.unizh.ini.caviar.aemonitor.*;
import ch.unizh.ini.caviar.aesequencer.*;
import ch.unizh.ini.caviar.biasgen.*;
import ch.unizh.ini.caviar.chip.*;
import ch.unizh.ini.caviar.chip.convolution.Conv32;
import ch.unizh.ini.caviar.chip.convolution.Conv64;
//import ch.unizh.ini.caviar.chip.convolution.Conv64NoNegativeEvents;
import ch.unizh.ini.caviar.chip.filter.*;
import ch.unizh.ini.caviar.chip.filter.SimpleOrientationFilter;
import ch.unizh.ini.caviar.chip.learning.Learning;
import ch.unizh.ini.caviar.chip.object.Tnc3;
import ch.unizh.ini.caviar.chip.retina.*;
import ch.unizh.ini.caviar.chip.tracking.*;
import ch.unizh.ini.caviar.event.*;
import ch.unizh.ini.caviar.eventio.*;
import ch.unizh.ini.caviar.hardwareinterface.*;
import ch.unizh.ini.caviar.hardwareinterface.usb.*;
import ch.unizh.ini.caviar.hardwareinterface.usb.CypressFX2.AEReader;
import ch.unizh.ini.caviar.stereopsis.StereoHardwareInterface;
import ch.unizh.ini.caviar.stereopsis.Tmpdiff128StereoPair;
import ch.unizh.ini.caviar.util.*;
import ch.unizh.ini.caviar.util.browser.*;
import com.sun.java.swing.plaf.windows.*;
import com.sun.opengl.utils.BufferUtils;
import java.awt.*;
import java.awt.datatransfer.*;
import java.awt.dnd.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.geom.AffineTransform;
import java.awt.image.*;
import java.beans.*;
import java.beans.PropertyChangeListener;
import java.io.*;
import java.lang.reflect.*;
import java.nio.*;
import java.nio.channels.FileChannel;
import java.text.*;
import java.util.*;
import java.util.concurrent.locks.*;
import java.util.logging.*;
import java.util.prefs.*;
import javax.imageio.*;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.plaf.basic.*;

/**
 * Shows retina live and allows for controlling view and recording and playing back events.
 * @author  tobi
 */
public class AEViewer extends javax.swing.JFrame implements PropertyChangeListener, DropTargetListener {
    // Robosapien control commands. The bits are reversed due to problem of firmware programming.
    final short RSV2_ROAR = (short)0x02EC;
    final short RSV2_WALKSTRAIGHT = (short)0x00C;
    final short RSV2_WALKBACK = (short)0x80C;
    final short RSV2_WALKLEFT = (short)0x40C;
    final short RSV2_WALKRIGHT = (short)0xC0C;
    final short RSV2_WALKUPLEFT = (short)0x20C;
    final short RSV2_WALKUPRIGHT = (short)0xA0C;
    final short RSV2_WALKDOWNLEFT = (short)0x60C;
    final short RSV2_WALKDOWNRIGHT = (short)0xE0C;
    final short RSV2_CHANGEGAIT = (short)0x09C;
    final short RSV2_DANCE = (short)0x0AC;
    final short RSV2_STOP = (short)0x55C;
    final short RSV2_SONIC = (short)0xC1C;
    final short RSV2_VISION = (short)0x01C;
    final short RSV2_LAUGH = (short)0x36C;
    
    int start_testing = 0;
    int stopsensing = 0;  // =1 when signals are not processed during turning
    long prevtime = 0; // start time of the turn
    int cmd = -1;
    
    public static String HELP_URL_USER_GUIDE="http://www.ini.unizh.ch/~tobi/caviar/INI-AE-Biasgen/";
    public static String HELP_URL_JAVADOC;
    static{
        String curDir = System.getProperty("user.dir");
        HELP_URL_JAVADOC="file://"+curDir+"/dist/javadoc/index.html";
//        System.out.println("HELP_URL_JAVADOC="+HELP_URL_JAVADOC);
    }
    public static String HELP_URL_USER_GUIDE_USB2_MINI;
    static{
        String curDir = System.getProperty("user.dir");
        File f=new File(curDir);
        File pf=f.getParentFile().getParentFile();
        HELP_URL_USER_GUIDE_USB2_MINI="file://"+pf.getPath()+"/doc/USBAERmini2userguide.pdf";
    }
    enum PlayMode { WAITING, LIVE, PLAYBACK, SEQUENCING, REMOTE}
    volatile private PlayMode playMode=PlayMode.WAITING;
    
    Preferences prefs=Preferences.userNodeForPackage(AEViewer.class);
    Logger log=Logger.getLogger("AEViewer");
    
    EventExtractor2D extractor=null;
    BiasgenFrame biasgenFrame=null;
    Biasgen biasgen=null;
    EventFilter2D filter1=null, filter2=null;
    ChipRenderer renderer=null;
    ClusterTracker tracker=null;
    AEMonitorInterface aemon=null;
    public ViewLoop viewLoop=null;
    FilterChain filterChain=null;
    FilterFrame filterFrame=null;
    ClusterTracker clusterTracker=null;
    RecentFiles recentFiles=null;
    File lastFile=null;
    File lastImageFile=null;
    File currentFile=null;
    FrameRater frameRater=new FrameRater();
    ChipCanvas chipCanvas;
    volatile boolean loggingEnabled=false;
    DateFormat loggingFilenameDateFormat=new SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ssZ");
    File loggingFile;
    AEOutputStream loggingOutputStream;
    private boolean activeRenderingEnabled=prefs.getBoolean("AEViewer.activeRenderingEnabled",true);
    private boolean openGLRenderingEnabled=prefs.getBoolean("AEViewer.openGLRenderingEnabled",true);
    private boolean renderBlankFramesEnabled=prefs.getBoolean("AEViewer.renderBlankFramesEnabled",false);
    DropTarget dropTarget;
    File draggedFile;
    private boolean loggingPlaybackImmediatelyEnabled=prefs.getBoolean("AEViewer.loggingPlaybackImmediatelyEnabled",false);
    private long loggingTimeLimit=0, loggingStartTime=System.currentTimeMillis();
    private boolean stereoModeEnabled=false;
    private boolean logFilteredEventsEnabled=prefs.getBoolean("AEViewer.logFilteredEventsEnabled",false);
    
    private AEChip chip;
    private String aeChipClassName=prefs.get("AEViewer.aeChipClassName",Tmpdiff128.class.getName());
    Class aeChipClass;
    
    WindowSaver windowSaver;
    CaviarViewer caviarViewer;
    
    
    /**
     * construct new instance and then set classname of device to show in it
     *
     * @param caviarViewer the manager of all viewers
     */
    public AEViewer(CaviarViewer caviarViewer){
        try {
            UIManager.setLookAndFeel(new WindowsLookAndFeel());
        } catch (Exception e) {
            log.warning(e.getMessage());
        }
        log.setLevel(Level.INFO);
        initComponents();
        this.caviarViewer=caviarViewer;
        if(caviarViewer!=null) caviarViewer.addViewer(this);
        
        
        int n=menuBar.getMenuCount();
        for(int i=0;i<n;i++){
            JMenu m=menuBar.getMenu(i);
            m.getPopupMenu().setLightWeightPopupEnabled(false);
        }
        
        String lastFilePath=prefs.get("AEViewer.lastFile","");
        lastFile=new File(lastFilePath);
        
        // recent files tracks recently used files *and* folders. recentFiles adds the anonymous listener
        // built here to open the selected file
        recentFiles=new RecentFiles(prefs, fileMenu, new ActionListener(){
            public void actionPerformed(ActionEvent evt){
                File f=new File(evt.getActionCommand());
                log.info("opening "+evt.getActionCommand());
                try{
                    if(f!=null && f.isFile()){
                        getAePlayer().startPlayback(f);
                        recentFiles.addFile(f);
                    }else if(f!=null && f.isDirectory()){
                        prefs.put("AEViewer.lastFile",f.getCanonicalPath());
                        aePlayer.openAEInputFileDialog();
                        recentFiles.addFile(f);
                    }
                }catch(Exception fnf){
                    fnf.printStackTrace();
//                    exceptionOccurred(fnf,this);
                    recentFiles.removeFile(f);
                }
            }
        });
        
        buildInterfaceMenu();
        buildDeviceMenu();
        // we need to do this after building device menu so that proper menu item radio button can be selected
        setAeChipClass(getAeChipClass()); // set default device - last chosen
        
        
        playerControlPanel.setVisible(false);
        
        pack();
        
        Runtime.getRuntime().addShutdownHook(new Thread(){
            public void run(){
                if(aemon!=null && aemon.isOpen()){
                    aemon.close();
                }
            }
        });
        
        setFocusable(true);
        requestFocus();
        viewLoop=new ViewLoop();
        viewLoop.start();
        dropTarget=new DropTarget(imagePanel,this);
        
        fixLoggingControls();
        
        // init menu items that are checkboxes to correct initial state
        viewActiveRenderingEnabledMenuItem.setSelected(isActiveRenderingEnabled());
        viewOpenGLEnabledMenuItem.setSelected(isOpenGLRenderingEnabled());
        loggingPlaybackImmediatelyCheckBoxMenuItem.setSelected(isLoggingPlaybackImmediatelyEnabled());
        subsampleEnabledCheckBoxMenuItem.setSelected(chip.isSubSamplingEnabled());
        acccumulateImageEnabledCheckBoxMenuItem.setSelected(renderer.isAccumulateEnabled());
        autoscaleContrastEnabledCheckBoxMenuItem.setSelected(renderer.isAutoscaleEnabled());
        pauseRenderingCheckBoxMenuItem.setSelected(isPaused());
        viewRenderBlankFramesCheckBoxMenuItem.setSelected(isRenderBlankFramesEnabled());
        logFilteredEventsCheckBoxMenuItem.setSelected(logFilteredEventsEnabled);
        
        if(caviarViewer!=null) electricalSyncEnabledCheckBoxMenuItem.setSelected(caviarViewer.isElectricalSyncEnabled());
        
        openHardwareIfNonambiguous();
    }
    
    void openHardwareIfNonambiguous(){
        // if we are are the only viewer, automatically set interface to the hardware interface if there is only 1 of them. otherwise force user choice
        if(caviarViewer!=null && caviarViewer.getViewers().size()==1 && HardwareInterfaceFactory.instance().getNumInterfacesAvailable()==1 ){
            log.info("opening unambiguous device");
            chip.setHardwareInterface(HardwareInterfaceFactory.instance().getFirstAvailableInterface());
        }
        
    }
    
    void buildDeviceMenu(){
        ButtonGroup deviceGroup=new ButtonGroup();
        for(Class deviceClass:AEChip.CHIP_CLASSSES){
            String deviceClassName=deviceClass.getName();
            JRadioButtonMenuItem b=new JRadioButtonMenuItem(deviceClassName);
            deviceMenu.add(b);
            b.addActionListener(new ActionListener(){
                public void actionPerformed(ActionEvent evt){
                    try{
                        String name=evt.getActionCommand();
                        Class cl=Class.forName(name);
                        setAeChipClass(cl);
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }
            });
            deviceGroup.add(b);
        }
    }
    
    public void zeroTimestamps(){
        if(aemon!=null && aemon.isOpen()) aemon.resetTimestamps();
    }
    
    
    public Class getAeChipClass() {
        if(aeChipClass==null) {
//            log.warning("AEViewer.getAeChipClass(): null aeChipClass, initializing to default "+aeChipClassName);
            try{
                aeChipClass=Class.forName(aeChipClassName);
            }catch(Exception e){
                e.printStackTrace();
                System.exit(1);
            }
        }
        return aeChipClass;
    }
    
    /** this sets window title according to actual state */
    public void setTitleAccordingToState(){
        String ts=null;
        switch(getPlayMode()){
            case LIVE:
                ts=getAeChipClass().getSimpleName()+" "+ aemon +" LIVE";
                break;
            case PLAYBACK:
                ts=currentFile.getName()+" PLAYING";
                break;
            case WAITING:
                ts="AEViewer - WAITING";
                break;
            case SEQUENCING:
                ts=getAeChipClass().getSimpleName()+" "+ aemon +" LIVE SEQUENCE-MONITOR";
                break;
        }
        setTitle(ts);
    }
    
    // sets the device class, e.g. Tmpdiff128, from the fully qual classname provided by the menu item itself
    public void setAeChipClass(Class deviceClass) {
//        log.infox("AEViewer.setAeChipClass("+deviceClass+")");
        try{
            if(filterFrame!=null) {
                filterFrame.dispose();
                filterFrame=null;
            }
            filtersToggleButton.setVisible(false);
            viewFiltersMenuItem.setEnabled(false);
            showBiasgen(false);
            Constructor<AEChip> constructor=deviceClass.getConstructor();
            if(getChip()==null){ // handle initial case
                constructChip(constructor);
            }else{
                synchronized(chip){ // handle live case -- this is not ideal thread programming - better to sync on a lock object in the run loop
                    synchronized(extractor){
                        synchronized(renderer){
                            constructChip(constructor);
                        }
                    }
                }
            }
            aeChipClass=deviceClass;
            prefs.put("AEViewer.aeChipClassName",aeChipClass.getName());
            if(aemon!=null){ // force reopen
                aemon.close();
            }
            makeCanvas();
            setTitleAccordingToState();
            Component[] devMenuComps=deviceMenu.getMenuComponents();
            for(int i=0;i<devMenuComps.length;i++){
                if(devMenuComps[i] instanceof JRadioButtonMenuItem){
                    JMenuItem item=(JRadioButtonMenuItem)devMenuComps[i];
                    if( item.getActionCommand().equals(aeChipClass.getName()) ){
                        item.setSelected(true);
                    }
                }
            }
            fixLoggingControls();
            filterChain=chip.getFilterChain();
            if(filterChain==null || filterChain.size()==0){
                filtersToggleButton.setVisible(false);
                viewFiltersMenuItem.setEnabled(false);
            }else{
                filterChain.reset();
                filtersToggleButton.setVisible(true);
                viewFiltersMenuItem.setEnabled(true);
            }
            if(chip.getHardwareInterface()!=null){
                log.warning("setting hardware interface of "+chip+" to "+chip.getHardwareInterface());
                aemon=(AEMonitorInterface)chip.getHardwareInterface();
            }
            filterFrame=chip.getFilterFrame();
            filterFrame.addWindowListener(new WindowAdapter() {
                public void windowClosed(WindowEvent e){
                    log.info(e.toString());
                    filtersToggleButton.setSelected(false);
                }
            });
            
            showFilters(false);
            // fix selected radio button for chip class
            if(deviceMenu.getItemCount()==0){
                log.warning("tried to select device in menu but no device menu has been built yet");
            }
            for(int i=0;i<deviceMenu.getItemCount();i++){
                JMenuItem m=deviceMenu.getItem(i);
                if(m!=null && m instanceof JRadioButtonMenuItem && m.getText()==aeChipClass.getName()) {
                    m.setSelected(true);
                    break;
                }
            }
        }catch(Exception e){
            e.printStackTrace();
        }
    }
    
    void constructChip(Constructor<AEChip> constructor){
        try{
//            System.out.println("AEViewer.constructChip(): constructing chip with constructor "+constructor);
            setChip(constructor.newInstance((java.lang.Object[])null));;
            extractor=chip.getEventExtractor();
            renderer=chip.getRenderer();
            getChip().setAeViewer(this);
        }catch(Exception e){
            System.err.println("AEViewer.constructChip exception "+e.getMessage());
            e.printStackTrace();
        }
    }
    
    synchronized void makeCanvas(){
        if(chipCanvas!=null) {
            imagePanel.remove(chipCanvas.getCanvas());
        }
        chipCanvas=chip.getCanvas();
        chipCanvas.setOpenGLEnabled(isOpenGLRenderingEnabled());
        imagePanel.add(chipCanvas.getCanvas());
        
        chipCanvas.getCanvas().invalidate();
        // find display menu reference and fill it with display menu for this canvas
        viewMenu.remove(displayMethodMenu);
        viewMenu.add(chipCanvas.getDisplayMethodMenu());
        displayMethodMenu=chipCanvas.getDisplayMethodMenu();
        viewMenu.invalidate();
        
        validate();
        pack();
        // causes a lot of flashing ... Toolkit.getDefaultToolkit().setDynamicLayout(true); // dynamic resizing  -- see if this bombs!
    }
    
    void setCurrentFile(File f){
        currentFile=new File(f.getPath());
        lastFile=currentFile;
        prefs.put("AEViewer.lastFile",lastFile.toString());
//        System.out.println("put AEViewer.lastFile="+lastFile);
        setTitleAccordingToState();
    }
    
    File getCurrentFile(){
        return currentFile;
    }
    
    FileInputStream fileInputStream;
    
    
    /** writes frames and frame sequences for video making using, e.g. adobe premiere */
    class CanvasFileWriter{
/*
 
 Part for OpenGL capture from http://www.cs.plu.edu/~dwolff/talks/jogl-ccsc/src/j_ScreenCapture/ScreenCaptureExample.java
 * Example 10: Screen capture
 *
 * This example demonstrates how to capture the OpenGL buffer into
 * a BufferedImage, and then optionally write it to a PNG file.
 *
 * Author: David Wolff
 *
 * Licensed under the Creative Commons Attribution License 2.5:
 * http://creativecommons.org/licenses/by/2.5/
 */
        
        boolean writingMovieEnabled=false;
        Canvas canvas;
        int frameNumber=0;
        java.io.File sequenceDir;
        String sequenceName="sequence";
        
        
        int snapshotNumber=0; // this is appended automatically to single snapshot filenames
        String snapshotName="snapshot";
        
        String getFilename(){
            return sequenceName+String.format("%04d.png",frameNumber);
        }
        
        synchronized void startWritingMovie(){
//            if(isOpenGLRenderingEnabled()){
//                JOptionPane.showMessageDialog(AEViewer.this,"Disable OpenGL graphics from the View menu first");
//                return;
//            }
            if(!isActiveRenderingEnabled()){
                JOptionPane.showMessageDialog(AEViewer.this,"Active rendering will be enabled for movie writing");
                setActiveRenderingEnabled(true);
                viewActiveRenderingEnabledMenuItem.setSelected(true);
            }
            sequenceName=JOptionPane.showInputDialog("Sequence name (this folder will be created)?");
            if(sequenceName==null || sequenceName.equals("")) {
                log.info("canceled image sequence");
                return;
            }
            log.info("creating directory "+sequenceName);
            sequenceDir=new File(sequenceName);
            if(sequenceDir.exists()){
                JOptionPane.showMessageDialog(AEViewer.this, sequenceName+" already exists");
                return;
            }
            boolean madeit=sequenceDir.mkdir();
            if(!madeit){
                JOptionPane.showMessageDialog(AEViewer.this, "couldn't create directory "+sequenceName);
                return;
            }
            frameNumber=0;
            writingMovieEnabled=true;
        }
        
        synchronized void stopWritingMovie(){
            writingMovieEnabled=false;
        }
        
        
        synchronized void writeMovieFrame(){
            try {
                Container container=getContentPane();
                canvas=chip.getCanvas().getCanvas();
                Rectangle r = canvas.getBounds();
                Image image = canvas.createImage(r.width, r.height);
                Graphics g = image.getGraphics();
                synchronized(container){
                    container.paintComponents(g);
                    if(!isOpenGLRenderingEnabled()){
                        chip.getCanvas().paint(g);
                        ImageIO.write((RenderedImage)image, "png", new File(sequenceDir,getFilename()));
                    }else if(chip.getCanvas().getImageOpenGL()!=null){
                        ImageIO.write(chip.getCanvas().getImageOpenGL(), "png", new File(sequenceDir,getFilename()));
                    }
                }
                frameNumber++;
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
        
//        /** Take an Image associated with a file, and wait until it is
//         *  done loading. Just a simple application of MediaTracker.
//         *  If you are loading multiple images, don't use this
//         *  consecutive times; instead use the version that takes
//         *  an array of images.
//         */
//
//        boolean waitForImage(Image image, Component c) {
//            MediaTracker tracker = new MediaTracker(c);
//            tracker.addImage(image, 0);
//            try {
//                tracker.waitForAll();
//            } catch(InterruptedException ie) {}
//            return(!tracker.isErrorAny());
//        }
        
        
        
        synchronized void writeSnapshotImage(){
            boolean wasPaused=isPaused();
            setPaused(true);
            JFileChooser fileChooser=new JFileChooser();
            String lastFilePath=prefs.get("AEViewer.lastFile",""); // get the last folder
            lastFile=new File(lastFilePath);
//            fileChooser.setFileFilter(datFileFilter);
            PNGFileFilter indexFileFilter=new PNGFileFilter();
            fileChooser.addChoosableFileFilter(indexFileFilter);
            fileChooser.setCurrentDirectory(lastFile); // sets the working directory of the chooser
            if(lastImageFile==null){
                lastImageFile=new File("snapshot.png");
            }
            fileChooser.setSelectedFile(lastImageFile);
            int retValue=fileChooser.showOpenDialog(AEViewer.this);
            if(retValue==JFileChooser.APPROVE_OPTION){
                lastImageFile=fileChooser.getSelectedFile();
                String suffix="";
                if(!lastImageFile.getName().endsWith(".png")) suffix=".png";
                try{
//                    if(!isOpenGLRenderingEnabled()){
                    Container container=getContentPane();
                    Rectangle r=container.getBounds();
                    Image image=container.createImage(r.width,r.height);
                    Graphics g=image.getGraphics();
                    synchronized(container){
                        container.paintComponents(g);
                        g.translate(0,statisticsPanel.getHeight());
                        chip.getCanvas().paint(g);
//                    ImageIO.write((RenderedImage)imageOpenGL, "png", new File(snapshotName+snapshotNumber+".png"));
                        log.info("writing image to file");
                        ImageIO.write((RenderedImage)image, "png", new File(lastImageFile.getPath()+suffix));
                    }
//                    }else{ // open gl canvas
//                    }
                    snapshotNumber++;
                }catch(Exception e){
                    e.printStackTrace();
                }
            }
            setPaused(wasPaused);
        }
        
        
        
    }
    
    synchronized void buildInterfaceMenu(){
//        System.out.println("AEViewer.buildInterfaceMenu");
        ButtonGroup bg=new ButtonGroup();
        interfaceMenu.removeAll();
        
        // make a 'none' item
        JRadioButtonMenuItem b=new JRadioButtonMenuItem("None");
        b.putClientProperty("HardwareInterface",null);
        interfaceMenu.add(b);
        bg.add(b);
        b.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent evt){
                log.info("selected null interface");
                chip.setHardwareInterface(null);
            }
        });
        interfaceMenu.add(new JSeparator());
        
        int n=HardwareInterfaceFactory.instance().getNumInterfacesAvailable();
        for(int i=0;i<n;i++){
            HardwareInterface hw=HardwareInterfaceFactory.instance().getInterface(i);
            b=new JRadioButtonMenuItem(hw.toString());
            b.putClientProperty("HardwareInterfaceNumber",new Integer(i));
            interfaceMenu.add(b);
            bg.add(b);
            b.addActionListener(new ActionListener(){
                public void actionPerformed(ActionEvent evt){
                    JComponent comp=(JComponent)evt.getSource();
                    int interfaceNumber=(Integer)comp.getClientProperty("HardwareInterfaceNumber");
                    HardwareInterface hw=HardwareInterfaceFactory.instance().getInterface(interfaceNumber);
//                    HardwareInterface hw=(HardwareInterface)comp.getClientProperty("HardwareInterface");
                    log.info("selected interface "+evt.getActionCommand()+" with HardwareInterface number"+interfaceNumber+" which is "+hw);
                    chip.setHardwareInterface(hw);
                }
            });
            if(chip!=null && chip.getHardwareInterface()==hw) b.setSelected(true);
        }
    }
    
    void fixBiasgenControls(){
        if(aemon==null || (aemon!=null && !aemon.isOpen())){
            biasesToggleButton.setEnabled(false);
            biasesToggleButton.setVisible(false);
            viewBiasesMenuItem.setEnabled(false);
            return;
        }else if(aemon instanceof BiasgenHardwareInterface){
            log.info("enabling biasgen menu items");
            biasesToggleButton.setEnabled(true);
            biasesToggleButton.setVisible(true);
            viewBiasesMenuItem.setEnabled(true);
        }
        if(biasgenFrame!=null) {
            boolean vis=biasgenFrame.isVisible();
            biasesToggleButton.setSelected(vis);
        }
    }
    
    // opens the AE interface and handles stereo mode if two identical AERetina interfaces
    void openAEMonitor(){
        if(aemon!=null && aemon.isOpen()){
            return;
        }
        try{
            openHardwareIfNonambiguous();
            aemon=(AEMonitorInterface)chip.getHardwareInterface();
            
            if(aemon==null) {
                fixDeviceControlMenuItems();
                fixLoggingControls();
                fixBiasgenControls();
                return;
            }
            aemon.setChip(chip);
            aemon.open();
            fixLoggingControls();
            fixBiasgenControls();
            tickUs=aemon.getTimestampTickUs();
            // note it is important that this openAEMonitor succeeed BEFORE aemon is assigned to biasgen, which immeiately tries to openAEMonitor and download biases, creating a storm of complaints if not sucessful!
            
            if(aemon instanceof BiasgenHardwareInterface){
                chip.getBiasgen().sendIPotValues(chip.getBiasgen());
//                chip.setHardwareInterface(aemon); // if we do this, events do not start coming again after reconnect of device
//                biasgen=chip.getBiasgen();
//                if(biasgenFrame==null) {
//                    biasgenFrame=new BiasgenFrame(biasgen);  // should check if exists...
//                }
            }
            
            setPlaybackControlsEnabledState(true);
            setPlayMode(PlayMode.LIVE);
            setTitleAccordingToState();
            if(aemon instanceof CypressFX2MonitorSequencer) {
                
                buildMonSeqMenu();
                enableMonSeqMenu(true);
            }else {
                enableMonSeqMenu(false);
                
            }
        }catch(Exception e){
            log.warning(e.getMessage());
            aemon.close();
            aemon=null;
            setPlaybackControlsEnabledState(false);
            fixDeviceControlMenuItems();
            fixLoggingControls();
            fixBiasgenControls();
            setPlayMode(PlayMode.WAITING);
        }
        fixDeviceControlMenuItems();
    }
    
    void setPlaybackControlsEnabledState(boolean yes){
        loggingButton.setEnabled(yes);
        biasesToggleButton.setEnabled(yes);
        filtersToggleButton.setEnabled(yes);
    }
    
//    volatile boolean stop=false; // volatile because multiple threads will access
    
    int renderCount=0;
    int numEvents;
    AEPacketRaw aeRaw;
//    AEPacket2D ae;
    EventPacket packet;
//    EventPacket packetFiltered;
    boolean skipRender=false;
//    volatile private boolean paused=false; // multiple threads will access
    boolean overrunOccurred=false;
    int tickUs=1;
    public AEPlayer aePlayer=new AEPlayer();
    int noEventCounter=0;
    
    
    /** this class handles file input of AEs to control the number of events/sample or period of time in the sample, etc.
     *It handles the file input stream, opening a dialog box, etc.
     *It also handles synchronization of different viewers as follows:
     *<p>
     * If the viwer is not synchronized, then all calls from the GUI are passed directly to this instance of AEPlayer. Thus local control always happens.
     *<p>
     * If the viewer is sychronized, then all GUI calls pass instead to the CaviarViewer instance that contains (or started) this viewer. Then the CaviarViewer AEPlayer
     *calls all the viewers to take the player action (e.g. rewind, go to next slice, change direction).
     *<p>
     *Thus whichever controls the user uses to control playback, the viewers are all sychronized properly without recursively. The "master" is indicated by the GUI action,
     *which routes the request either to this instance's AEPlayer or to the CaviarViewer AEPlayer.
     */
    public class AEPlayer implements AEInputStreamInterface, AEPlayerInterface{
        private boolean flexTimeEnabled=false; // true to play constant # of events
        private int samplePeriodUs=20000; // ms/sample to shoot for
        private int sampleNumEvents=2048;
        boolean fileInputEnabled=false;
        AEInputStream fileAEInputStream=null;
        JFileChooser fileChooser;
        
        public boolean isChoosingFile(){
            return (fileChooser!=null && fileChooser.isVisible());
        }
        
        /** called when user asks to open data file file dialog */
        public void openAEInputFileDialog() {
//        try{Thread.currentThread().sleep(200);}catch(InterruptedException e){}
            float oldScale=chipCanvas.getScale();
            fileChooser=new JFileChooser();
//            new TypeAheadSelector(fileChooser);
            //com.sun.java.plaf.windows.WindowsFileChooserUI;
//            fileChooser.addKeyListener(new KeyAdapter() {
//                public void keyTyped(KeyEvent e){
//                    System.out.println("keycode="+e.getKeyCode());
//                }
//            });
//            System.out.println("fileChooser.getUIClassID()="+fileChooser.getUIClassID());
//            KeyListener[] keyListeners=fileChooser.getKeyListeners();
            ChipDataFilePreview preview=new ChipDataFilePreview(fileChooser,chip); // from book swing hacks
            new FileDeleter(fileChooser,preview);
            fileChooser.addPropertyChangeListener(preview);
            fileChooser.setAccessory(preview);
            String lastFilePath=prefs.get("AEViewer.lastFile",""); // get the last folder
            lastFile=new File(lastFilePath);
//            fileChooser.setFileFilter(datFileFilter);
            IndexFileFilter indexFileFilter=new IndexFileFilter();
            fileChooser.addChoosableFileFilter(indexFileFilter);
            DATFileFilter datFileFilter = new DATFileFilter();
            fileChooser.addChoosableFileFilter(datFileFilter);
            fileChooser.setCurrentDirectory(lastFile); // sets the working directory of the chooser
//            boolean wasPaused=isPaused();
            setPaused(true);
            int retValue=fileChooser.showOpenDialog(AEViewer.this);
            if(retValue==JFileChooser.APPROVE_OPTION){
                try{
                    lastFile=fileChooser.getSelectedFile();
                    if(lastFile!=null) recentFiles.addFile(lastFile);
                    startPlayback(lastFile);
                }catch(FileNotFoundException fnf){
                    fnf.printStackTrace();
//                exceptionOccurred(fnf,this);
                }
            }else{
                preview.showFile(null); // abort preview
            }
            fileChooser=null;
            chipCanvas.setScale(oldScale); // restore persistent scale so that we don't get tiny size on next startup
            setPaused(false);
        }
        
        public class FileDeleter extends KeyAdapter implements PropertyChangeListener{
            private JFileChooser chooser;
            private ChipDataFilePreview preview;
            File file=null;
            
            /** adds a keyreleased listener on the JFileChooser FilePane inner classes so that user can use Delete key to delete the file
             that is presently being shown in the preview window
             @param chooser the chooser
             @param preview the data file preview
             */
            public FileDeleter(JFileChooser chooser, ChipDataFilePreview preview) {
                this.chooser = chooser;
                this.preview=preview;
                chooser.addPropertyChangeListener(JFileChooser.SELECTED_FILE_CHANGED_PROPERTY,this);
                Component comp = addDeleteListener(chooser);
            }
            
            /** is called when the file selection is changed. Bound to the SELECTED_FILE_CHANGED_PROPERTY. */
            public void propertyChange(PropertyChangeEvent evt) {
                if(evt.getNewValue() instanceof File){
                    file=(File)evt.getNewValue();
                }else{
                    file=null;
                }
                System.out.println("**** new file="+file);
            }
            
            private Component addDeleteListener(Component comp) {
//            System.out.println("");
//            System.out.println("comp="+comp);
//            if (comp.getClass() == sun.swing.FilePane.class) return comp;
                
                if (comp instanceof Container) {
//                System.out.println(comp+"\n");
//                comp.addMouseListener(new MouseAdapter(){
//                    public void mouseEntered(MouseEvent e){
//                        System.out.println("mouse entered: "+e);
//                    }
//                });
                    if(comp.getClass().getEnclosingClass()==sun.swing.FilePane.class){
//                        System.out.println("******adding keyListener to "+comp);
                        comp.addKeyListener(new KeyAdapter(){
                            public void keyReleased(KeyEvent e){
                                if(e.getKeyCode()==KeyEvent.VK_DELETE){
//                                    System.out.println("delete key typed from "+e.getSource());
                                    deleteFile();
                                }
                            }
                        });
                    }
                    Component[] components = ((Container)comp).getComponents();
                    for(int i = 0; i < components.length; i++) {
                        Component child = addDeleteListener(components[i]);
                        if (child != null) return child;
                    }
                }
                return null;
            }
            
            void deleteFile(){
                if(file==null){
                    return;
                }
                System.out.println("trying to delete file "+file);
                preview.deleteCurrentFile();
            }
        }
        
        
        
        synchronized public void startPlayback(File file) throws FileNotFoundException {
            if(IndexFileFilter.getExtension(file).equals("index")){
                if(caviarViewer!=null) {
                    caviarViewer.getPlayer().startPlayback(file);
                }
                return;
            }
//            System.out.println("AEViewer.starting playback for DAT file "+file);
            fileInputStream=new FileInputStream(file);
            setCurrentFile(file);
            fileAEInputStream=new AEInputStream(fileInputStream);
            if(caviarViewer!=null && caviarViewer.getViewers().size()==1){
                try{
                    fileAEInputStream.rewind();
                }catch(IOException e){
                    e.printStackTrace();
                }
            }
            // don't waste cycles grabbing events while playing back
            if(aemon!=null && aemon.isOpen()) try{
                if (getPlayMode().equals(getPlayMode().SEQUENCING)) {
                    stopSequencing();
                } else {
                    aemon.setEventAcquisitionEnabled(false);
                }
                
            }catch(HardwareInterfaceException e){
                e.printStackTrace();
            }
            fileAEInputStream.getSupport().addPropertyChangeListener(AEViewer.this);
            closeMenuItem.setEnabled(true);
            increasePlaybackSpeedMenuItem.setEnabled(true);
            decreasePlaybackSpeedMenuItem.setEnabled(true);
            rewindPlaybackMenuItem.setEnabled(true);
            flextimePlaybackEnabledCheckBoxMenuItem.setEnabled(true);
            togglePlaybackDirectionMenuItem.setEnabled(true);
            toggleMarkCheckBoxMenuItem.setEnabled(true);
            if(!playerControlPanel.isVisible()) playerControlPanel.setVisible(true);
            setPlayMode(PlayMode.PLAYBACK);
            setTitleAccordingToState();
        }
        
        /** stops playback.
         *If not in PLAYBACK mode, then just returns.
         *If playing  back, could be waiting during sleep or during CyclicBarrier.await call in CaviarViewer. In case this is the case, we send
         *an interrupt to the the ViewLoop thread to stop this waiting.
         */
        public void stopPlayback(){
            
            
            if(getPlayMode()!=PlayMode.PLAYBACK){
                return;
            }
//            viewLoop.interrupt();
            
//            System.out.println("AEViewer.AEPlayer.stopPlayback() for file "+fileInputStream);
//            viewLoop.interrupt();
            if(aemon!=null && aemon.isOpen()) {
                try{
                    aemon.setEventAcquisitionEnabled(true);
                }catch(HardwareInterfaceException e){
                    setPlayMode(PlayMode.WAITING);
                    e.printStackTrace();
                }
                setPlayMode(PlayMode.LIVE);
            }else{
                setPlayMode(PlayMode.WAITING);
            }
            playerControlPanel.setVisible(false);
//        closeMenuItem.setEnabled(false);
            toggleMarkCheckBoxMenuItem.setEnabled(false);
            increasePlaybackSpeedMenuItem.setEnabled(false);
            decreasePlaybackSpeedMenuItem.setEnabled(false);
            rewindPlaybackMenuItem.setEnabled(false);
            flextimePlaybackEnabledCheckBoxMenuItem.setEnabled(false);
            togglePlaybackDirectionMenuItem.setEnabled(false);
            toggleMarkCheckBoxMenuItem.setEnabled(false);
            
            try {
                if(fileAEInputStream!=null){
                    fileAEInputStream.close();
                    fileAEInputStream=null;
                }
                if(fileInputStream!=null){
                    fileInputStream.close();
                    fileInputStream=null;
                }
            } catch (IOException ignore) {
                ignore.printStackTrace();
            }
            setTitleAccordingToState();
        }
        
        public void rewind() {
            if(fileAEInputStream==null){
                return;
            }
//            System.out.println(Thread.currentThread()+" AEViewer.AEPlayer.rewind() called, rewinding "+fileAEInputStream);
            try{
                fileAEInputStream.rewind();
                filterChain.reset();
            }catch(Exception e){
                System.err.println("rewind exception: "+e.getMessage());
                e.printStackTrace();
            }
        }
        
        public void pause(){
            AEViewer.this.setPaused(true);
        }
        
        public void resume(){
            AEViewer.this.setPaused(false);
        }
        
        /** sets the AEViewer paused flag */
        public void setPaused(boolean yes){
            AEViewer.this.setPaused(yes);
        }
        
        /** gets the AEViewer paused flag */
        public boolean isPaused() {
            return AEViewer.this.isPaused();
        }
        
        public AEPacketRaw getNextPacket(){
            return getNextPacket(null);
        }
        
        public AEPacketRaw getNextPacket(AEPlayerInterface player){
            if(player!=this) throw new UnsupportedOperationException("tried to get data from some other player");
            AEPacketRaw aeRaw=null;
            try{
                if(!aePlayer.isFlexTimeEnabled()){
                    aeRaw=fileAEInputStream.readPacketByTime(getAePlayer().getSamplePeriodUs());
                }else{
                    aeRaw=fileAEInputStream.readPacketByNumber(getAePlayer().getSampleNumEvents());
                }
//                if(aeRaw!=null) time=aeRaw.getLastTimestamp();
                return aeRaw;
            }catch(EOFException e){
                try{
                    Thread.currentThread().sleep(200);
                }catch(InterruptedException ignore){}
                // when we get to end, we now just wraps in either direction, to make it easier to explore the ends
//                System.out.println("***********"+this+" reached EOF, calling rewind");
                getAePlayer().rewind(); // we force a rewind on all players in case we are not the only one
//                                if(!aePlayer.isPlayingForwards())
                //getAePlayer().toggleDirection();
                return aeRaw;
            }catch(IOException io){
                io.printStackTrace();
                return null;
            }catch(NullPointerException np){
                np.printStackTrace();
                return new AEPacketRaw(0);
            }
        }
        
        public void toggleDirection(){
            setSampleNumEvents(getSampleNumEvents() * -1);
            setSamplePeriodUs(getSamplePeriodUs() * -1);
        }
        public void speedUp(){
            setSampleNumEvents(getSampleNumEvents() * 2);
            setSamplePeriodUs(getSamplePeriodUs() * 2);
        }
        public void slowDown(){
            setSampleNumEvents(getSampleNumEvents() / 2); if (getSampleNumEvents()==0) setSampleNumEvents(1);
            setSamplePeriodUs(getSamplePeriodUs() / 2); if(getSamplePeriodUs()==0) setSamplePeriodUs(1);
            if(Math.abs(getSampleNumEvents())<1) setSampleNumEvents((int) Math.signum(getSampleNumEvents()));
            if(Math.abs(getSamplePeriodUs())<1) setSamplePeriodUs((int) Math.signum(getSamplePeriodUs()));
        }
        void toggleFlexTime(){
            setFlexTimeEnabled(!isFlexTimeEnabled());
        }
        public boolean isPlayingForwards(){
            return getSamplePeriodUs()>0;
        }
        
        public float getFractionalPosition() {
            if(fileAEInputStream==null){
                log.warning("AEViewer.AEPlayer.getFractionalPosition: null fileAEInputStream, returning 0");
                return 0;
            }
            return fileAEInputStream.getFractionalPosition();
        }
        
        public void mark() throws IOException {
            fileAEInputStream.mark();
        }
        
        public int position() {
            return fileAEInputStream.position();
        }
        
        public void position(int event) {
            fileAEInputStream.position(event);
        }
        
        public AEPacketRaw readPacketByNumber(int n) throws IOException {
            return fileAEInputStream.readPacketByNumber(n);
        }
        
        public AEPacketRaw readPacketByTime(int dt) throws IOException {
            return fileAEInputStream.readPacketByTime(dt);
        }
        
        public long size() {
            return fileAEInputStream.size();
        }
        
        public void unmark() {
            fileAEInputStream.unmark();
        }
        
//        public synchronized AEPacketRaw readPacketToTime(int time, boolean forwards) throws IOException {
//            return fileAEInputStream.readPacketToTime(time,forwards);
//        }
//
        public void setFractionalPosition(float frac) {
            fileAEInputStream.setFractionalPosition(frac);
        }
        
        public void setTime(int time) {
//            System.out.println(this+".setTime("+time+")");
            if(fileAEInputStream!=null){
                fileAEInputStream.setCurrentStartTimestamp(time);
            }else{
                log.warning("null AEInputStream");
            }
        }
        
        public int getTime() {
            if(fileAEInputStream==null) return 0;
            return fileAEInputStream.getMostRecentTimestamp();
        }
        
        public boolean isFlexTimeEnabled() {
            return flexTimeEnabled;
        }
        
        public void setFlexTimeEnabled(boolean flexTimeEnabled) {
            this.flexTimeEnabled = flexTimeEnabled;
        }
        
        public int getSamplePeriodUs() {
            return samplePeriodUs;
        }
        
        public void setSamplePeriodUs(int samplePeriodUs) {
            this.samplePeriodUs = samplePeriodUs;
        }
        
        public int getSampleNumEvents() {
            return sampleNumEvents;
        }
        
        public void setSampleNumEvents(int sampleNumEvents) {
            this.sampleNumEvents = sampleNumEvents;
        }
        
        public AEInputStream getAEInputStream() {
            return fileAEInputStream;
        }
        
    }
    
    
    /** This thread acquires events and renders them to the RetinaCanvas for active rendering. The other components render themselves
     * on the usual Swing rendering thread.
     */
    class ViewLoop extends Thread{
        Graphics2D g=null;
//        volatile boolean rerenderOtherComponents=false;
//        volatile boolean renderImageEnabled=true;
        volatile boolean singleStepEnabled=false, doSingleStep=false;
        int numRawEvents, numFilteredEvents;
        
        
        void renderPacket(EventPacket ae){
            if(aePlayer.isChoosingFile()) return; // don't render while filechooser is active
            boolean subsamplingEnabled=renderer.isSubsamplingEnabled();
            if(isPaused()){
                renderer.setSubsamplingEnabled(false);
            }
            renderer.render(packet);
            if(isPaused()){
                renderer.setSubsamplingEnabled(subsamplingEnabled);
            }
//            if(renderImageEnabled) {
            if(isActiveRenderingEnabled()){
                if(canvasFileWriter.writingMovieEnabled) chipCanvas.grabNextImage();
                chipCanvas.paintFrame(); // actively paint frame now, either with OpenGL or Java2D, depending on switch
            }else{
//                log.info("repaint by "+1000/frameRater.getDesiredFPS()+" ms");
                chipCanvas.repaint(1000/frameRater.getDesiredFPS()); // ask for repaint within frame time
            }
            
            if(canvasFileWriter.writingMovieEnabled){
                canvasFileWriter.writeMovieFrame();
            }
        } // renderEvents
        
        private EventPacket extractPacket(AEPacketRaw aeRaw){
            boolean subsamplingEnabled=renderer.isSubsamplingEnabled();
            if(isPaused()){
                extractor.setSubsamplingEnabled(false);
            }
            EventPacket packet=extractor.extractPacket(aeRaw);
            if(isPaused()){
                extractor.setSubsamplingEnabled(subsamplingEnabled);
            }
            return packet;
        }
        
        EngineeringFormat engFmt=new EngineeringFormat();
        long beforeTime=0, afterTime;
        int lastts=0;
        volatile boolean stop=false;
        
        /** the main loop - this is the 'game loop' of the program */
        synchronized public void run(){
            int[][] tmparray = new int[128][128];
            float cx=0,cy=0;  // centroid of events
            int totalcnt=0;   // total number of events within an iteration
            double cmdcnt=0;  // length of consecutive commands
            int guess=0; //cmd 0 straight, 1 right, 2 left, 3 u-turn
            SimpleOrientationFilter ofilter = null;
            RotateFilter rfilter = null;
            double ang = Math.PI/2;
            double cntscale = 1;
            double varx=0, vary=0;

            while(stop==false && !isInterrupted()){
                
                // now get the data to be displayed
                if(!isPaused() || isSingleStep()){
//                    if(isSingleStep()){
//                        log.info("getting data for single step");
//                    }
                    // if !paused we always get data. below, if singleStepEnabled, we set paused after getting data.
                    // when the user unpauses via menu, we disable singleStepEnabled
                    // another flag, doSingleStep, tells loop to do a single data acquisition and then pause again
                    // in this branch, get new data to show
                    frameRater.takeBefore();
                    switch(getPlayMode()){
                        case SEQUENCING:
                            AEMonitorSequencerInterface aemonseq = (AEMonitorSequencerInterface)chip.getHardwareInterface();
                            int position = 100*aemonseq.getNumEventsSent()/aemonseq.getNumEventsToSend();
                            sliderDontProcess=true;
                            playerSlider.setValue(position);
                            
                        case LIVE:
                            openAEMonitor();
                            if(aemon==null || !aemon.isOpen()) {
                                setPlayMode(PlayMode.WAITING);
                                try{Thread.currentThread().sleep(300);}catch(InterruptedException e){
                                    log.warning("LIVE openAEMonitor sleep interrupted");
                                }
                                continue;
                            }
                            overrunOccurred=aemon.overrunOccurred();
                            try{
                                // try to get an event to avoid rendering empty (black) frames
                                int triesLeft=15;
                                do{
                                    if(!isInterrupted()) {
                                        aemon=(AEMonitorInterface)chip.getHardwareInterface(); // keep setting aemon to be chip's interface, this is kludge
                                        if(aemon==null){
                                            System.err.println("AEViewer.ViewLoop.run(): null aeMon");
                                            throw new HardwareInterfaceException("hardware interface became null");
                                        }
                                        aeRaw=aemon.acquireAvailableEventsFromDriver();
//                                        System.out.println("got "+aeRaw);
                                    }
                                    if(aeRaw.getNumEvents()>0) break;
//                                    System.out.print("."); System.out.flush();
                                    try{Thread.currentThread().sleep(3);} catch(InterruptedException e){
                                        System.out.println("LIVE attempt to get data loop interrupted");
                                    }
                                }while(triesLeft-->0);
//                                if(aeRaw.getNumEvents()==0) {System.out.println("0"); System.out.flush();}
                                
                            }catch(HardwareInterfaceException e){
                                setPlayMode(PlayMode.WAITING);
                                e.printStackTrace();
                                aemon=null;
                                continue;
                            }
                            break;
                        case PLAYBACK:
//                            Thread thisThread=Thread.currentThread();
//                            System.out.println("thread "+thisThread+" getting events for renderCount="+renderCount);
                            aeRaw=getAePlayer().getNextPacket(aePlayer);
//                            System.out.println("."); System.out.flush();
                            break;
                        case REMOTE:
                            aeRaw=socketInputStream.readPacket();
                            break;
                        case WAITING:
//                            notify(); // notify waiter on this thread that we have gone to WAITING state
                            openAEMonitor();
                            if(aemon==null || !aemon.isOpen()) {
                                statisticsLabel.setText("Choose interface from Interface menu");
//                                setPlayMode(PlayMode.WAITING); // we don't need to set it again
                                try{Thread.currentThread().sleep(300);}catch(InterruptedException e){
                                    System.out.println("WAITING interrupted");
                                }
                                continue;
                            }
//                            synchronized(this){
//                                try{
//                                    Thread.currentThread().sleep(300);
//                                }catch(InterruptedException e){
//                                    System.out.println("WAITING interrupted");
//                                }
//                            }
//                            continue;
                    } // playMode switch to get data
                    
                    if(aeRaw==null){
//                        System.err.println("AEViewer.viewLoop.run(): null aeRaw");
                        fpsDelay();
                        continue;
                    }
                    
                    
                    numRawEvents=aeRaw.getNumEvents();
                    
                    if(socketOutputStream!=null){
                        try{
                            socketOutputStream.writePacket(aeRaw);
                        }catch(IOException e){
                            e.printStackTrace();
                            log.warning("sending packet "+aeRaw+" failed");
                        }
                    }
                    
                    // new style packet with reused event objects
                    packet=extractPacket(aeRaw);
                    cntscale = 1.0;
         
                    if (start_testing == 1) {
                        for(Object o:packet){
                            BasicEvent e=(BasicEvent)o;
                            tmparray[e.y][e.x]++;
                        }
                        cx = cy = 0;
                        totalcnt = 0;
                        if (stopsensing == 1) {
                            Date date = new Date();
                            if (date.getTime() - prevtime > 8000) {  // turn for 8s
                                stopsensing = 0;
                                if (cmd == 3) {
                                    cmd = -1;
                                    prevtime = date.getTime()+2000; // turn more for horizontal line
                                    stopsensing = 1;
                                    if (ang >= 0.3)
                                        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKRIGHT);
                                    else
                                        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKLEFT);
                                }
                                else if (cmd != 0) {
                                  ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKSTRAIGHT);
                                  cmd = 0;
                                }
                                
                                cmdcnt = 0;
                            }
                        } else { // !stopsensing
                            guess = 0;
                            for (int i=0; i<128; i++) {
                                for(int j=0; j<128; j++) {
                                    if (tmparray[i][j]>1) { // filter out some noise
                                        cx += i*tmparray[i][j];
                                        cy += j*tmparray[i][j];
                                        totalcnt += tmparray[i][j];
                                    }
                                }
                            }
                            
                            // compute centroid before passing throught the filters
                            if (totalcnt > 1) {
                                cx = cx/totalcnt;
                                cy = cy/totalcnt;

																// compute variance along x and y direction
                                varx = vary = 0.0;
                                for (int i=0; i<128; i++) {
                                    for(int j=0; j<128; j++) {
                                        if (tmparray[i][j]>1) {
                                            varx += (i*tmparray[i][j] - cx)*(i*tmparray[i][j] - cx);
                                            vary += (j*tmparray[i][j] - cy)*(j*tmparray[i][j] - cy);
                                        }
                                        tmparray[i][j] = 0;
                                    }
                                }
                                
                                // turn right if centroid on the left and vice versa
                                if (cx < 59 && cy < 100)
                                    guess = 2;
                                else if (cx > 69 && cy < 100)
                                    guess = 1;
                                else
                                    guess = 0;  // default: go straight
                            }
                        }
                    }                    
                    
                    // turn orientation filter and rotation filter on if not already done so
                    if (ofilter == null) {
                        try {
                            ofilter = (SimpleOrientationFilter)filterChain.findFilter(Class.forName("ch.unizh.ini.caviar.chip.filter.SimpleOrientationFilter"));
                        } catch (ClassNotFoundException ex) {
                            ex.printStackTrace();
                        }
                        ofilter.setFilterEnabled(true);
                    }
            
                    if (rfilter == null) {
                        try {
                            rfilter = (RotateFilter)filterChain.findFilter(Class.forName("ch.unizh.ini.caviar.chip.filter.RotateFilter"));
                        } catch (ClassNotFoundException ex) {
                            ex.printStackTrace();
                        }
                        rfilter.setFilterEnabled(true);
                    }
                    
                    try{
                        packet=filterChain.filterPacket(packet);
                    }catch(Exception e){
                        log.warning("Caught "+e+", disabling all filters");
                        e.printStackTrace();
                        for(EventFilter f:filterChain) f.setFilterEnabled(false);
                    }
                    if(packet==null) {
                        log.warning("null packet after filtering");
                        continue;
                    }
                    
                    // compute the mean orientation if centroid is within the center region
                    if (start_testing == 1 && stopsensing == 0 && cx >44 && cx <84 && cy <110) {
                        java.awt.geom.Point2D.Float p = ofilter.computeGlobalOriVector();
                        double x, y;
                        x = p.getX();
                        y = p.getY();
                        if (! Double.isNaN(Math.atan(y/x)))
                            ang = 0.7*ang + 0.3*Math.atan(y/x);
                        
                        if ((varx/vary >= 2 || (ang < Math.PI/4.0 && ang > -Math.PI/4.0)) && cy < 90 && totalcnt > 10) {
                            guess = 3;
                            cntscale = 2.0;
                        } 
                    }                        
                        
                        
                    if (start_testing == 1 && stopsensing == 0 && totalcnt > 10) {    
                        System.out.println(guess);
                        if (guess == cmd)
                            cmdcnt += cntscale;
                        else {
                            cmdcnt = 0;
                            cmd = guess;
                        }
                    if (cmdcnt>18) {
                            if (cmd == 1) {
                                System.out.println("RIGHT"); //left and right and reversed
                                //((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKUPLEFT);
                                ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKLEFT);
                            } else if (cmd == 2) {
                                System.out.println("LEFT");
                                //((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKUPRIGHT);
                                ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKRIGHT);
                            } else if (cmd == 3) {
                                System.out.println("STOP");
                                if (((int)(ang*10))%2 == 0)
                                    ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_ROAR);
                                else
                                    ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_LAUGH);
                            } 
                            
                            if (cmd > 0) {
                                stopsensing = 1;
                                Date date = new Date();
                                prevtime = date.getTime();
                                if (cmd == 3)
                                    prevtime += 3000;
                                else if (cmd == 1 || cmd ==2) {
                                    prevtime -= 4000;  // turn less when line is on the side
                                    if (cx > 44 && cx < 84)
                                        prevtime += 1000;
                                }
                            }
                            cmdcnt = 0;
                        }
                    }
                    
                    
                    if(loggingEnabled){
                        synchronized(loggingOutputStream){
                            try{
                                if(!logFilteredEventsEnabled){
                                    loggingOutputStream.writePacket(aeRaw);
                                }else{
                                    // log the reconstructed packet after filtering
                                    AEPacketRaw aeRawRecon=extractor.reconstructRawPacket(packet);
                                    loggingOutputStream.writePacket(aeRawRecon);
                                }
                            }catch(IOException e){
                                e.printStackTrace();
                                loggingEnabled=false;
                                try{ loggingOutputStream.close();}catch(IOException e2){e2.printStackTrace();}
                            }
                        }
                        if(loggingTimeLimit>0){
                            if(System.currentTimeMillis()-loggingStartTime>loggingTimeLimit){
                                log.info("logging time limit reached, stopping logging");
                                try{
                                    SwingUtilities.invokeAndWait(new Runnable(){
                                        public void run(){
                                            stopLogging(); // must run this in AWT thread because it messes with file menu
                                        }
                                    });
                                }catch(Exception e){
                                    e.printStackTrace();
                                }
                            }
                        }
                    }
                    numEvents=packet.getSize();
                    numFilteredEvents=packet.getSize();
                    
                    if(numFilteredEvents==0 && !isRenderBlankFramesEnabled()) {
//                        log.info("blank frame, not rendering it");
                        fpsDelay();
                        continue;
                    }
                    
                    if(numEvents==0){
                        noEventCounter++;
                    }else{
                        noEventCounter=0;
                    }
                    
                    
                    singleStepDone();
                } // getting data
                
                // we only got new events if we were NOT paused. but now we can apply filters, different rendering methods, etc in 'paused' condition
                
                makeStatisticsLabel();
//                renderEvents(ae);
                renderPacket(packet);
                
                frameRater.takeAfter();
                renderCount++;
                
                fpsDelay();
            }
            log.warning("AEViewer.run(): stop="+stop+" isInterrupted="+isInterrupted());
            if(aemon!=null) aemon.close();
            
            if(windowSaver!=null)
                try {
                    windowSaver.saveSettings();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            
            chipCanvas.getCanvas().setVisible(false);
            remove(chipCanvas.getCanvas());
            if(caviarViewer!=null) {
                log.info("removing "+AEViewer.this+" viewer from caviar viewer list");
                caviarViewer.removeViewer(AEViewer.this); // we want to remove the viewer, not this inner class
            }
            dispose();
            if(caviarViewer==null || caviarViewer.getViewers().isEmpty()) System.exit(0);
        } // viewLoop.run()
        
        void fpsDelay(){
            if(!isPaused()){
                frameRater.delayForDesiredFPS();
            }else{
                synchronized(this){ try {wait(100);} catch (java.lang.InterruptedException e) {
                    System.out.println("viewLoop wait() interrupted: "+e.getMessage()+" cause is "+e.getCause());}
                }
            }
        }
        
        private void makeStatisticsLabel() {
            if(getAePlayer().isChoosingFile()) return; // don't render stats while user is choosing file
//            if(ae==null) return;
            if(packet==null) return;
            float dtMs=0;
            if(numEvents>0){
//                lastts=ae.getLastTimestamp();
                lastts=packet.getLastTimestamp();
            }
            if(numEvents>1){
                dtMs=(float)((lastts-packet.getFirstTimestamp())/(tickUs*1e3));
            }
            String thisTimeString=null;
            
            float ratekeps=packet.getEventRateHz()/1e3f;
            switch(getPlayMode()){
                case SEQUENCING:
                case LIVE:
                    if(aemon==null) return;
//                    ratekeps=aemon.getEstimatedEventRate()/1000f;
                    thisTimeString=String.format("%5.2f",lastts*aemon.getTimestampTickUs()*1e-6f);
                    break;
                case PLAYBACK:
//                    if(ae.getNumEvents()>2) ratekeps=(float)ae.getNumEvents()/(float)dtMs;
//                    if(packet.getSize()>2) ratekeps=(float)packet.getSize()/(float)dtMs;
                    thisTimeString=String.format("%5.2f",getAePlayer().getTime()*1e-6f); // hack here, we don't know timestamp from data file, we assume 1us
                    break;
            }
            String rateString=null;
            if(ratekeps>=1e3f) rateString="   >1 Meps"; else rateString=String.format("%5.2f keps",ratekeps);
            int cs=renderer.getColorScale();
            
            String ovstring;
            if(overrunOccurred){
                ovstring="(overrun)";
            }else{
                ovstring="";
            }
            String s=null;
            if(renderCount%10==0 || isPaused() || isSingleStep() || frameRater.getDesiredFPS()<20 ) {  // don't draw stats too fast
                if(numEvents==0) s=thisTimeString+ "s: No events";
                else {
                    String timeExpansionString;
                    if(getPlayMode()==PlayMode.LIVE || getPlayMode()==PlayMode.SEQUENCING){
                        timeExpansionString="";
                    }else{
                        float expansion=frameRater.getAverageFPS()*dtMs/1000f;
                        if(expansion>1){
                            timeExpansionString=String.format("%5.1fX",expansion);
                        }else{
                            timeExpansionString=String.format("%5.1f/",1/expansion);
                        }
                    }
                    
//                    String memUse=engFmt.format(Runtime.getRuntime().totalMemory()/1e6f);
                    
//                    s=String.format("<html><center>%8ss @ %4.1f s, %5d/%-5d evts %s, %s keps<br>%2.0f/%d fps %s, delay %2d ms, %s=%2d</center></html>",
                    s=String.format("%8ss@%ss, %5d/%-5d evts %s, %s %2.0f/%dfps %s, %2dms delay, %s=%2d",
                            engFmt.format((float)dtMs/1000),
                            thisTimeString,
                            numRawEvents,
                            numFilteredEvents,
                            ovstring,
                            rateString,
                            frameRater.getAverageFPS(),
                            frameRater.getDesiredFPS(),
                            timeExpansionString,
                            frameRater.getLastDelayMs(),
                            renderer.isAutoscaleEnabled()? "AS":"FS", // auto or fullscale rendering color
                            cs
//                            engFmt.format(Runtime.getRuntime().totalMemory()/1e6f)
                            );
                }
                setStatisticsLabel(s);
            }
        }
    }
    
    int lastStatisticsLabelWidth=0;
    void setStatisticsLabel(final String s){
        try {
            SwingUtilities.invokeAndWait(new Runnable(){
                public void run(){
                    statisticsLabel.setText(s);
                    if(statisticsLabel.getWidth()>statisticsPanel.getWidth()) {
//                        System.out.println("statisticsLabel width="+statisticsLabel.getWidth()+" > statisticsPanel width="+statisticsPanel.getWidth());
                        // possibly resize statistics font size
                        formComponentResized(null);
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    int getScreenRefreshRate(){
        int rate=60;
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        GraphicsDevice[] gs = ge.getScreenDevices();
        for (int i=0; i<gs.length; i++) {
            DisplayMode dm = gs[i].getDisplayMode();
            // Get refresh rate in Hz
            int refreshRate = dm.getRefreshRate();
            if (refreshRate == DisplayMode.REFRESH_RATE_UNKNOWN) {
                log.warning("AEViewer.getScreenRefreshRate: got unknown refresh rate for screen "+i+", assuming 60");
                refreshRate=60;
            }else{
//                log.info("AEViewer.getScreenRefreshRate: screen "+i+" has refresh rate "+refreshRate);
            }
            if(i==0) rate=refreshRate;
        }
        return rate;
    }
    
// computes and executes appropriate delayForDesiredFPS to try to maintain constant rendering rate
    class FrameRater{
        final int MAX_FPS=120;
        int desiredFPS= prefs.getInt("AEViewer.FrameRater.desiredFPS",getScreenRefreshRate());
        final int nSamples=10;
        long[] samplesNs=new long[nSamples];
        int index=0;
        int delayMs=1;
        int desiredPeriodMs=(int)(1000f/desiredFPS);
        
        
        void setDesiredFPS(int fps){
            if(fps<1) fps=1; else if(fps>MAX_FPS) fps=MAX_FPS;
            desiredFPS=fps;
            prefs.putInt("AEViewer.FrameRater.desiredFPS",fps);
            desiredPeriodMs=1000/fps;
        }
        
        int getDesiredFPS(){
            return desiredFPS;
        }
        
        float getAveragePeriodNs(){
            int sum=0;
            for(int i=0;i<nSamples;i++){
                sum+=samplesNs[i];
            }
            return (float)sum/nSamples;
        }
        
        float getAverageFPS(){
            return 1f/(getAveragePeriodNs()/1e9f);
        }
        
        float getLastFPS(){
            return 1f/(lastdt/1e9f);
        }
        
        int getLastDelayMs(){
            return delayMs;
        }
        
        long getLastDtNs(){
            return lastdt;
        }
        
        long beforeTimeNs=System.nanoTime(), lastdt, afterTimeNs;
        
        //  call this ONCE after capture/render. it will store the time since the last call
        void takeBefore(){
            beforeTimeNs=System.nanoTime();
        }
        
        long lastAfterTime=System.nanoTime();
        
        //  call this ONCE after capture/render. it will store the time since the last call
        void takeAfter(){
            afterTimeNs=System.nanoTime();
            lastdt=afterTimeNs-beforeTimeNs;
            samplesNs[index++]=afterTimeNs-lastAfterTime;
            lastAfterTime=afterTimeNs;
            if(index>=nSamples) index=0;
        }
        
        // call this to delayForDesiredFPS enough to make the total time including last sample period equal to desiredPeriodMs
        void delayForDesiredFPS(){
            delayMs=(int)Math.round(desiredPeriodMs-(float)getLastDtNs()/1000000);
            if(delayMs<0) delayMs=1;
            try {Thread.currentThread().sleep(delayMs);} catch (java.lang.InterruptedException e) {}
        }
        
    }
    
    public void stopMe(){
//        log.info(Thread.currentThread()+ "AEViewer.stopMe() called");
        switch(getPlayMode()){
            case PLAYBACK:
                getAePlayer().stopPlayback();
                break;
            case LIVE:
            case WAITING:
                viewLoop.stop=true;
                showBiasgen(false);
                break;
        }
// viewer is removed by WindowClosing event
//        if(caviarViewer!=null ){
//            log.info(this+" being removed from caviarViewer viewers list");
//            caviarViewer.getViewers().remove(this);
//        }
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc=" Generated Code ">//GEN-BEGIN:initComponents
    private void initComponents() {
        jProgressBar1 = new javax.swing.JProgressBar();
        renderModeButtonGroup = new javax.swing.ButtonGroup();
        statisticsPanel = new javax.swing.JPanel();
        statisticsLabel = new javax.swing.JLabel();
        imagePanel = new javax.swing.JPanel();
        mainToolBar = new javax.swing.JToolBar();
        jPanel2 = new javax.swing.JPanel();
        toolbarPanel = new javax.swing.JPanel();
        jPanel1 = new javax.swing.JPanel();
        biasesToggleButton = new javax.swing.JToggleButton();
        filtersToggleButton = new javax.swing.JToggleButton();
        loggingButton = new javax.swing.JToggleButton();
        playerControlPanel = new javax.swing.JPanel();
        playerSlider = new javax.swing.JSlider();
        jPanel3 = new javax.swing.JPanel();
        resizeIconLabel = new javax.swing.JLabel();
        jPanel4 = new javax.swing.JPanel();
        jButton3 = new javax.swing.JButton();
        sendroar = new javax.swing.JButton();
        sendup = new javax.swing.JButton();
        senddown = new javax.swing.JButton();
        sendleft = new javax.swing.JButton();
        sendright = new javax.swing.JButton();
        sendupleft = new javax.swing.JButton();
        sendupright = new javax.swing.JButton();
        jPanel5 = new javax.swing.JPanel();
        senddownleft = new javax.swing.JButton();
        senddownright = new javax.swing.JButton();
        sendsonic = new javax.swing.JButton();
        sendvision = new javax.swing.JButton();
        sendgaitchange = new javax.swing.JButton();
        sendstop = new javax.swing.JButton();
        starttest = new javax.swing.JButton();
        menuBar = new javax.swing.JMenuBar();
        fileMenu = new javax.swing.JMenu();
        newViewerMenuItem = new javax.swing.JMenuItem();
        openMenuItem = new javax.swing.JMenuItem();
        closeMenuItem = new javax.swing.JMenuItem();
        jSeparator7 = new javax.swing.JSeparator();
        fileSaveSetupMenItem = new javax.swing.JMenuItem();
        fileLoadSetupMenuItem = new javax.swing.JMenuItem();
        jSeparator8 = new javax.swing.JSeparator();
        saveImageMenuItem = new javax.swing.JMenuItem();
        saveImageSequenceMenuItem = new javax.swing.JMenuItem();
        jSeparator6 = new javax.swing.JSeparator();
        loggingMenuItem = new javax.swing.JMenuItem();
        loggingPlaybackImmediatelyCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        loggingSetTimelimitMenuItem = new javax.swing.JMenuItem();
        logFilteredEventsCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        serverSeparator = new javax.swing.JSeparator();
        spikeServerCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        openSocketInputStreamMenuItem = new javax.swing.JMenuItem();
        syncSeperator = new javax.swing.JSeparator();
        syncEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        electricalSyncEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        jSeparator5 = new javax.swing.JSeparator();
        exitMenuItem = new javax.swing.JMenuItem();
        viewMenu = new javax.swing.JMenu();
        viewBiasesMenuItem = new javax.swing.JMenuItem();
        viewFiltersMenuItem = new javax.swing.JMenuItem();
        jSeparator1 = new javax.swing.JSeparator();
        viewActiveRenderingEnabledMenuItem = new javax.swing.JCheckBoxMenuItem();
        viewOpenGLEnabledMenuItem = new javax.swing.JCheckBoxMenuItem();
        viewRenderBlankFramesCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        jSeparator3 = new javax.swing.JSeparator();
        cycleColorRenderingMethodMenuItem = new javax.swing.JMenuItem();
        increaseContrastMenuItem = new javax.swing.JMenuItem();
        decreaseContrastMenuItem = new javax.swing.JMenuItem();
        autoscaleContrastEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        jSeparator4 = new javax.swing.JSeparator();
        cycleDisplayMethodButton = new javax.swing.JMenuItem();
        displayMethodMenu = new javax.swing.JMenu();
        jSeparator12 = new javax.swing.JSeparator();
        acccumulateImageEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        viewIgnorePolarityCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        increaseFrameRateMenuItem = new javax.swing.JMenuItem();
        decreaseFrameRateMenuItem = new javax.swing.JMenuItem();
        pauseRenderingCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        viewSingleStepMenuItem = new javax.swing.JMenuItem();
        zeroTimestampsMenuItem = new javax.swing.JMenuItem();
        jSeparator2 = new javax.swing.JSeparator();
        subsampleEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        subSampleSizeMenuItem = new javax.swing.JMenuItem();
        jSeparator11 = new javax.swing.JSeparator();
        increasePlaybackSpeedMenuItem = new javax.swing.JMenuItem();
        decreasePlaybackSpeedMenuItem = new javax.swing.JMenuItem();
        rewindPlaybackMenuItem = new javax.swing.JMenuItem();
        flextimePlaybackEnabledCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        togglePlaybackDirectionMenuItem = new javax.swing.JMenuItem();
        toggleMarkCheckBoxMenuItem = new javax.swing.JCheckBoxMenuItem();
        measureTimeMenuItem = new javax.swing.JMenuItem();
        jSeparator10 = new javax.swing.JSeparator();
        zoomMenuItem = new javax.swing.JMenuItem();
        unzoomMenuItem = new javax.swing.JMenuItem();
        deviceMenu = new javax.swing.JMenu();
        interfaceMenu = new javax.swing.JMenu();
        refreshInterfaceMenuItem = new javax.swing.JMenuItem();
        controlMenu = new javax.swing.JMenu();
        increaseBufferSizeMenuItem = new javax.swing.JMenuItem();
        decreaseBufferSizeMenuItem = new javax.swing.JMenuItem();
        increaseNumBuffersMenuItem = new javax.swing.JMenuItem();
        decreaseNumBuffersMenuItem = new javax.swing.JMenuItem();
        jSeparator9 = new javax.swing.JSeparator();
        cypressFX2EEPROMMenuItem = new javax.swing.JMenuItem();
        monSeqMenu = new javax.swing.JMenu();
        monSeqOperationModeMenu = new javax.swing.JMenu();
        monSeqOpMode0 = new javax.swing.JMenuItem();
        monSeqOpMode1 = new javax.swing.JMenuItem();
        monSeqOpMode2 = new javax.swing.JMenuItem();
        monSeqOpMode3 = new javax.swing.JMenuItem();
        monSeqMissedEventsMenuItem = new javax.swing.JMenuItem();
        jSeparator13 = new javax.swing.JSeparator();
        sequenceMenuItem = new javax.swing.JMenuItem();
        helpMenu = new javax.swing.JMenu();
        contentMenuItem = new javax.swing.JMenuItem();
        helpUserGuideMenuItem = new javax.swing.JMenuItem();
        javadocMenuItem = new javax.swing.JMenuItem();
        aboutMenuItem = new javax.swing.JMenuItem();

        setTitle("Retina");
        addComponentListener(new java.awt.event.ComponentAdapter() {
            public void componentResized(java.awt.event.ComponentEvent evt) {
                formComponentResized(evt);
            }
        });
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                formWindowClosing(evt);
            }
        });

        statisticsPanel.setFocusable(false);
        statisticsPanel.addComponentListener(new java.awt.event.ComponentAdapter() {
            public void componentResized(java.awt.event.ComponentEvent evt) {
                statisticsPanelComponentResized(evt);
            }
        });

        statisticsLabel.setFont(new java.awt.Font("Courier New", 0, 11));
        statisticsLabel.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);
        statisticsLabel.setText("          starting up.....         ");
        statisticsLabel.setHorizontalTextPosition(javax.swing.SwingConstants.LEFT);
        statisticsPanel.add(statisticsLabel);

        getContentPane().add(statisticsPanel, java.awt.BorderLayout.NORTH);

        imagePanel.setLayout(new java.awt.BorderLayout());

        imagePanel.setEnabled(false);
        imagePanel.setFocusable(false);
        imagePanel.addMouseWheelListener(new java.awt.event.MouseWheelListener() {
            public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) {
                imagePanelMouseWheelMoved(evt);
            }
        });

        getContentPane().add(imagePanel, java.awt.BorderLayout.CENTER);

        getContentPane().add(mainToolBar, java.awt.BorderLayout.SOUTH);

        getContentPane().add(jPanel2, java.awt.BorderLayout.EAST);

        toolbarPanel.setLayout(new java.awt.BorderLayout());

        toolbarPanel.setMinimumSize(new java.awt.Dimension(555, 110));
        toolbarPanel.setPreferredSize(new java.awt.Dimension(555, 110));
        jPanel1.setLayout(new javax.swing.BoxLayout(jPanel1, javax.swing.BoxLayout.X_AXIS));

        jPanel1.setPreferredSize(new java.awt.Dimension(423, 35));
        biasesToggleButton.setText("Biasgen");
        biasesToggleButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                biasesToggleButtonActionPerformed(evt);
            }
        });

        jPanel1.add(biasesToggleButton);

        filtersToggleButton.setText("Filters");
        filtersToggleButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                filtersToggleButtonActionPerformed(evt);
            }
        });

        jPanel1.add(filtersToggleButton);

        loggingButton.setText("Start logging");
        jPanel1.add(loggingButton);

        playerControlPanel.setToolTipText("playback controls");
        playerControlPanel.setPreferredSize(new java.awt.Dimension(200, 35));
        playerSlider.setValue(0);
        playerSlider.setPreferredSize(new java.awt.Dimension(150, 25));
        playerSlider.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                playerSliderStateChanged(evt);
            }
        });

        playerControlPanel.add(playerSlider);

        jPanel1.add(playerControlPanel);

        toolbarPanel.add(jPanel1, java.awt.BorderLayout.NORTH);

        jPanel3.setLayout(new java.awt.BorderLayout());

        resizeIconLabel.setIcon(new TriangleSquareWindowsCornerIcon());
        resizeIconLabel.setVerticalAlignment(javax.swing.SwingConstants.BOTTOM);
        resizeIconLabel.addMouseMotionListener(new java.awt.event.MouseMotionAdapter() {
            public void mouseDragged(java.awt.event.MouseEvent evt) {
                resizeIconLabelMouseDragged(evt);
            }
        });
        resizeIconLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                resizeIconLabelMouseEntered(evt);
            }
            public void mouseExited(java.awt.event.MouseEvent evt) {
                resizeIconLabelMouseExited(evt);
            }
            public void mousePressed(java.awt.event.MouseEvent evt) {
                resizeIconLabelMousePressed(evt);
            }
        });

        jPanel3.add(resizeIconLabel, java.awt.BorderLayout.SOUTH);

        toolbarPanel.add(jPanel3, java.awt.BorderLayout.EAST);

        jButton3.setText("Dance");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });

        jPanel4.add(jButton3);

        sendroar.setText("Roar");
        sendroar.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendroarActionPerformed(evt);
            }
        });

        jPanel4.add(sendroar);

        sendup.setText(" Up");
        sendup.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendupActionPerformed(evt);
            }
        });

        jPanel4.add(sendup);

        senddown.setText("Down");
        senddown.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                senddownActionPerformed(evt);
            }
        });

        jPanel4.add(senddown);

        sendleft.setText("Left");
        sendleft.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendleftActionPerformed(evt);
            }
        });

        jPanel4.add(sendleft);

        sendright.setText("Right");
        sendright.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendrightActionPerformed(evt);
            }
        });

        jPanel4.add(sendright);

        sendupleft.setText("Up+Left");
        sendupleft.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendupleftActionPerformed(evt);
            }
        });

        jPanel4.add(sendupleft);

        sendupright.setText("Up+Right");
        sendupright.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                senduprightActionPerformed(evt);
            }
        });

        jPanel4.add(sendupright);

        toolbarPanel.add(jPanel4, java.awt.BorderLayout.CENTER);

        jPanel5.setMinimumSize(new java.awt.Dimension(10, 33));
        jPanel5.setPreferredSize(new java.awt.Dimension(10, 33));
        senddownleft.setText("Down+Left");
        senddownleft.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                senddownleftActionPerformed(evt);
            }
        });

        jPanel5.add(senddownleft);

        senddownright.setText("Down+Right");
        senddownright.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                senddownrightActionPerformed(evt);
            }
        });

        jPanel5.add(senddownright);

        sendsonic.setText("Sonic");
        sendsonic.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendsonicActionPerformed(evt);
            }
        });

        jPanel5.add(sendsonic);

        sendvision.setText("Vision");
        sendvision.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendvisionActionPerformed(evt);
            }
        });

        jPanel5.add(sendvision);

        sendgaitchange.setText("Gait Change");
        sendgaitchange.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendgaitchangeActionPerformed(evt);
            }
        });

        jPanel5.add(sendgaitchange);

        sendstop.setText("Stop");
        sendstop.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendstopActionPerformed(evt);
            }
        });

        jPanel5.add(sendstop);

        starttest.setText("Start Test");
        starttest.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                starttestActionPerformed(evt);
            }
        });

        jPanel5.add(starttest);

        toolbarPanel.add(jPanel5, java.awt.BorderLayout.SOUTH);

        getContentPane().add(toolbarPanel, java.awt.BorderLayout.SOUTH);

        fileMenu.setMnemonic('f');
        fileMenu.setText("File");
        newViewerMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_N, java.awt.event.InputEvent.CTRL_MASK));
        newViewerMenuItem.setMnemonic('N');
        newViewerMenuItem.setText("New viewer");
        newViewerMenuItem.setToolTipText("Opens a new viewer");
        newViewerMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                newViewerMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(newViewerMenuItem);

        openMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_O, 0));
        openMenuItem.setMnemonic('o');
        openMenuItem.setText("Open logged data file...");
        openMenuItem.setToolTipText("Opens a logged data file for playback");
        openMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                openMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(openMenuItem);

        closeMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_W, java.awt.event.InputEvent.CTRL_MASK));
        closeMenuItem.setMnemonic('C');
        closeMenuItem.setText("Close");
        closeMenuItem.setToolTipText("Closes this viewer or the playing data file");
        closeMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                closeMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(closeMenuItem);

        fileMenu.add(jSeparator7);

        fileSaveSetupMenItem.setText("Save setup...");
        fileSaveSetupMenItem.setToolTipText("Save the viewers and hardware interfaces setup");
        fileSaveSetupMenItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                fileSaveSetupMenItemActionPerformed(evt);
            }
        });

        fileMenu.add(fileSaveSetupMenItem);

        fileLoadSetupMenuItem.setText("Load setup...");
        fileLoadSetupMenuItem.setToolTipText("Load viewer setup");
        fileLoadSetupMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                fileLoadSetupMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(fileLoadSetupMenuItem);

        fileMenu.add(jSeparator8);

        saveImageMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, java.awt.event.InputEvent.ALT_MASK | java.awt.event.InputEvent.CTRL_MASK));
        saveImageMenuItem.setText("Save image as PNG");
        saveImageMenuItem.setToolTipText("Saves a single PNG of the canvas");
        saveImageMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveImageMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(saveImageMenuItem);

        saveImageSequenceMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_M, java.awt.event.InputEvent.ALT_MASK | java.awt.event.InputEvent.CTRL_MASK));
        saveImageSequenceMenuItem.setText("Save image sequence");
        saveImageSequenceMenuItem.setToolTipText("Saves sequence to a set of files in folder");
        saveImageSequenceMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveImageSequenceMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(saveImageSequenceMenuItem);

        fileMenu.add(jSeparator6);

        loggingMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_L, 0));
        loggingMenuItem.setText("Start logging data");
        fileMenu.add(loggingMenuItem);

        loggingPlaybackImmediatelyCheckBoxMenuItem.setText("Playback logged data immediately after logging enabled");
        loggingPlaybackImmediatelyCheckBoxMenuItem.setToolTipText("If enabled, logged data plays back immediately");
        loggingPlaybackImmediatelyCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                loggingPlaybackImmediatelyCheckBoxMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(loggingPlaybackImmediatelyCheckBoxMenuItem);

        loggingSetTimelimitMenuItem.setText("Set logging time limit...");
        loggingSetTimelimitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                loggingSetTimelimitMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(loggingSetTimelimitMenuItem);

        logFilteredEventsCheckBoxMenuItem.setText("Log filtered events enabled");
        logFilteredEventsCheckBoxMenuItem.setToolTipText("Enables logging of filtered events (reduces file size)");
        logFilteredEventsCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                logFilteredEventsCheckBoxMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(logFilteredEventsCheckBoxMenuItem);

        fileMenu.add(serverSeparator);

        spikeServerCheckBoxMenuItem.setText("Spike server enabled");
        spikeServerCheckBoxMenuItem.setToolTipText("Serves stream of raw events as multicast datagram packets");
        spikeServerCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                spikeServerCheckBoxMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(spikeServerCheckBoxMenuItem);

        openSocketInputStreamMenuItem.setText("Open remote server input stream");
        openSocketInputStreamMenuItem.setToolTipText("Opens a remote connection for datagram events");
        openSocketInputStreamMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                openSocketInputStreamMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(openSocketInputStreamMenuItem);

        fileMenu.add(syncSeperator);

        syncEnabledCheckBoxMenuItem.setText("Synchronized logging/playback enabled");
        syncEnabledCheckBoxMenuItem.setToolTipText("All viwers start/stop logging in synchrony and playback times are synchronized");
        fileMenu.add(syncEnabledCheckBoxMenuItem);

        electricalSyncEnabledCheckBoxMenuItem.setText("Electrical sync time enabled");
        electricalSyncEnabledCheckBoxMenuItem.setToolTipText("If enabled, specifies that boards can electrically synchronize timestamps");
        electricalSyncEnabledCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                electricalSyncEnabledCheckBoxMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(electricalSyncEnabledCheckBoxMenuItem);

        fileMenu.add(jSeparator5);

        exitMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_X, 0));
        exitMenuItem.setMnemonic('x');
        exitMenuItem.setText("Exit");
        exitMenuItem.setToolTipText("Exits all viewers");
        exitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                exitMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(exitMenuItem);

        menuBar.add(fileMenu);

        viewMenu.setMnemonic('v');
        viewMenu.setText("View");
        viewBiasesMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_B, java.awt.event.InputEvent.CTRL_MASK));
        viewBiasesMenuItem.setMnemonic('b');
        viewBiasesMenuItem.setText("Biases");
        viewBiasesMenuItem.setToolTipText("Shows bias generator controls");
        viewBiasesMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewBiasesMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewBiasesMenuItem);

        viewFiltersMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F, java.awt.event.InputEvent.CTRL_MASK));
        viewFiltersMenuItem.setMnemonic('f');
        viewFiltersMenuItem.setText("Filters");
        viewFiltersMenuItem.setToolTipText("Shows filter controls");
        viewFiltersMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewFiltersMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewFiltersMenuItem);

        viewMenu.add(jSeparator1);

        viewActiveRenderingEnabledMenuItem.setText("Active rendering enabled");
        viewActiveRenderingEnabledMenuItem.setToolTipText("Enables active display of each rendered frame");
        viewActiveRenderingEnabledMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewActiveRenderingEnabledMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewActiveRenderingEnabledMenuItem);

        viewOpenGLEnabledMenuItem.setText("Enable OpenGL rendering");
        viewOpenGLEnabledMenuItem.setToolTipText("Enables use of JOGL OpenGL library for rendering");
        viewOpenGLEnabledMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewOpenGLEnabledMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewOpenGLEnabledMenuItem);

        viewRenderBlankFramesCheckBoxMenuItem.setText("Render blank frames");
        viewRenderBlankFramesCheckBoxMenuItem.setToolTipText("If enabled, frames without events are rendered");
        viewRenderBlankFramesCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewRenderBlankFramesCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewRenderBlankFramesCheckBoxMenuItem);

        viewMenu.add(jSeparator3);

        cycleColorRenderingMethodMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_C, 0));
        cycleColorRenderingMethodMenuItem.setText("Cycle color rendering mode");
        cycleColorRenderingMethodMenuItem.setToolTipText("Changes rendering mode (gray, contrast, RG, color-time)");
        cycleColorRenderingMethodMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cycleColorRenderingMethodMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(cycleColorRenderingMethodMenuItem);

        increaseContrastMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_UP, 0));
        increaseContrastMenuItem.setText("Increase contrast");
        increaseContrastMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                increaseContrastMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(increaseContrastMenuItem);

        decreaseContrastMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_DOWN, 0));
        decreaseContrastMenuItem.setText("Decrease contrast");
        decreaseContrastMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                decreaseContrastMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(decreaseContrastMenuItem);

        autoscaleContrastEnabledCheckBoxMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_A, 0));
        autoscaleContrastEnabledCheckBoxMenuItem.setText("Autoscale contrast enabled");
        autoscaleContrastEnabledCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                autoscaleContrastEnabledCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(autoscaleContrastEnabledCheckBoxMenuItem);

        viewMenu.add(jSeparator4);

        cycleDisplayMethodButton.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_3, 0));
        cycleDisplayMethodButton.setText("Cycle display method");
        cycleDisplayMethodButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cycleDisplayMethodButtonActionPerformed(evt);
            }
        });

        viewMenu.add(cycleDisplayMethodButton);

        displayMethodMenu.setText("display methods (placeholder)");
        viewMenu.add(displayMethodMenu);

        viewMenu.add(jSeparator12);

        acccumulateImageEnabledCheckBoxMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_P, 0));
        acccumulateImageEnabledCheckBoxMenuItem.setText("Accumulate image");
        acccumulateImageEnabledCheckBoxMenuItem.setToolTipText("Rendered data accumulates over frames");
        acccumulateImageEnabledCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                acccumulateImageEnabledCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(acccumulateImageEnabledCheckBoxMenuItem);

        viewIgnorePolarityCheckBoxMenuItem.setText("Ignore cell type");
        viewIgnorePolarityCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewIgnorePolarityCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewIgnorePolarityCheckBoxMenuItem);

        increaseFrameRateMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_RIGHT, 0));
        increaseFrameRateMenuItem.setText("Increase rendering frame rate");
        increaseFrameRateMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                increaseFrameRateMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(increaseFrameRateMenuItem);

        decreaseFrameRateMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_LEFT, 0));
        decreaseFrameRateMenuItem.setText("Decrease rendering frame rate");
        decreaseFrameRateMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                decreaseFrameRateMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(decreaseFrameRateMenuItem);

        pauseRenderingCheckBoxMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_SPACE, 0));
        pauseRenderingCheckBoxMenuItem.setText("Paused");
        pauseRenderingCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                pauseRenderingCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(pauseRenderingCheckBoxMenuItem);

        viewSingleStepMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_PERIOD, 0));
        viewSingleStepMenuItem.setText("Single step");
        viewSingleStepMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                viewSingleStepMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(viewSingleStepMenuItem);

        zeroTimestampsMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_0, 0));
        zeroTimestampsMenuItem.setText("Zero timestamps");
        zeroTimestampsMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                zeroTimestampsMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(zeroTimestampsMenuItem);

        viewMenu.add(jSeparator2);

        subsampleEnabledCheckBoxMenuItem.setText("Enable subsample rendering");
        subsampleEnabledCheckBoxMenuItem.setToolTipText("use to speed up rendering");
        subsampleEnabledCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                subsampleEnabledCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(subsampleEnabledCheckBoxMenuItem);

        subSampleSizeMenuItem.setText("Choose rendering subsample limit...");
        subSampleSizeMenuItem.setToolTipText("Sets the number of events rendered in subsampling mode");
        subSampleSizeMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                subSampleSizeMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(subSampleSizeMenuItem);

        viewMenu.add(jSeparator11);

        increasePlaybackSpeedMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F, 0));
        increasePlaybackSpeedMenuItem.setText("Increase playback speed");
        increasePlaybackSpeedMenuItem.setEnabled(false);
        increasePlaybackSpeedMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                increasePlaybackSpeedMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(increasePlaybackSpeedMenuItem);

        decreasePlaybackSpeedMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, 0));
        decreasePlaybackSpeedMenuItem.setText("Decrease playback speed");
        decreasePlaybackSpeedMenuItem.setEnabled(false);
        decreasePlaybackSpeedMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                decreasePlaybackSpeedMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(decreasePlaybackSpeedMenuItem);

        rewindPlaybackMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_R, 0));
        rewindPlaybackMenuItem.setText("Rewind");
        rewindPlaybackMenuItem.setEnabled(false);
        rewindPlaybackMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                rewindPlaybackMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(rewindPlaybackMenuItem);

        flextimePlaybackEnabledCheckBoxMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_T, 0));
        flextimePlaybackEnabledCheckBoxMenuItem.setText("Flextime playback enabled");
        flextimePlaybackEnabledCheckBoxMenuItem.setToolTipText("Enables playback with constant number of events");
        flextimePlaybackEnabledCheckBoxMenuItem.setEnabled(false);
        flextimePlaybackEnabledCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                flextimePlaybackEnabledCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(flextimePlaybackEnabledCheckBoxMenuItem);

        togglePlaybackDirectionMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_B, 0));
        togglePlaybackDirectionMenuItem.setText("Toggle playback direction");
        togglePlaybackDirectionMenuItem.setEnabled(false);
        togglePlaybackDirectionMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                togglePlaybackDirectionMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(togglePlaybackDirectionMenuItem);

        toggleMarkCheckBoxMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_M, 0));
        toggleMarkCheckBoxMenuItem.setText("Toggle mark present location for rewind");
        toggleMarkCheckBoxMenuItem.setEnabled(false);
        toggleMarkCheckBoxMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                toggleMarkCheckBoxMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(toggleMarkCheckBoxMenuItem);

        measureTimeMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_1, 0));
        measureTimeMenuItem.setText("Measure time");
        measureTimeMenuItem.setToolTipText("Each click reports statistics about timing since last click");
        measureTimeMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                measureTimeMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(measureTimeMenuItem);

        viewMenu.add(jSeparator10);

        zoomMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_Z, 0));
        zoomMenuItem.setMnemonic('z');
        zoomMenuItem.setText("Zoom");
        zoomMenuItem.setToolTipText("drag mouse to draw zoom box");
        zoomMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                zoomMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(zoomMenuItem);

        unzoomMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_HOME, 0));
        unzoomMenuItem.setText("Unzoom");
        unzoomMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                unzoomMenuItemActionPerformed(evt);
            }
        });

        viewMenu.add(unzoomMenuItem);

        menuBar.add(viewMenu);

        deviceMenu.setMnemonic('d');
        deviceMenu.setText("AEChip");
        deviceMenu.setToolTipText("Specifies which chip is connected");
        deviceMenu.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                deviceMenuActionPerformed(evt);
            }
        });

        menuBar.add(deviceMenu);

        interfaceMenu.setMnemonic('i');
        interfaceMenu.setText("Interface");
        interfaceMenu.setToolTipText("Select the HW interface to use");
        interfaceMenu.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                interfaceMenuActionPerformed(evt);
            }
        });
        interfaceMenu.addMenuListener(new javax.swing.event.MenuListener() {
            public void menuCanceled(javax.swing.event.MenuEvent evt) {
            }
            public void menuDeselected(javax.swing.event.MenuEvent evt) {
            }
            public void menuSelected(javax.swing.event.MenuEvent evt) {
                interfaceMenuMenuSelected(evt);
            }
        });

        refreshInterfaceMenuItem.setText("Refresh");
        refreshInterfaceMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                refreshInterfaceMenuItemActionPerformed(evt);
            }
        });

        interfaceMenu.add(refreshInterfaceMenuItem);

        menuBar.add(interfaceMenu);

        controlMenu.setMnemonic('c');
        controlMenu.setText("CypressFX2");
        controlMenu.setToolTipText("control CypresFX2 driver parameters");
        increaseBufferSizeMenuItem.setText("Increase buffer size");
        increaseBufferSizeMenuItem.setToolTipText("Increases the host USB fifo size");
        increaseBufferSizeMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                increaseBufferSizeMenuItemActionPerformed(evt);
            }
        });

        controlMenu.add(increaseBufferSizeMenuItem);

        decreaseBufferSizeMenuItem.setText("Decrease buffer size");
        decreaseBufferSizeMenuItem.setToolTipText("Decreases the host USB fifo size");
        decreaseBufferSizeMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                decreaseBufferSizeMenuItemActionPerformed(evt);
            }
        });

        controlMenu.add(decreaseBufferSizeMenuItem);

        increaseNumBuffersMenuItem.setText("Increase number of buffers");
        increaseNumBuffersMenuItem.setToolTipText("Increases the host number of USB read buffers");
        increaseNumBuffersMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                increaseNumBuffersMenuItemActionPerformed(evt);
            }
        });

        controlMenu.add(increaseNumBuffersMenuItem);

        decreaseNumBuffersMenuItem.setText("Decrease num buffers");
        decreaseNumBuffersMenuItem.setToolTipText("Decreases the host number of USB read buffers");
        decreaseNumBuffersMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                decreaseNumBuffersMenuItemActionPerformed(evt);
            }
        });

        controlMenu.add(decreaseNumBuffersMenuItem);

        controlMenu.add(jSeparator9);

        cypressFX2EEPROMMenuItem.setText("CypressFX2 EEPPROM Utility");
        cypressFX2EEPROMMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cypressFX2EEPROMMenuItemActionPerformed(evt);
            }
        });

        controlMenu.add(cypressFX2EEPROMMenuItem);

        menuBar.add(controlMenu);

        monSeqMenu.setText("FX2MonSeq");
        monSeqMenu.setEnabled(false);
        monSeqMenu.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqMenuActionPerformed(evt);
            }
        });

        monSeqOperationModeMenu.setText("Menu");
        monSeqOperationModeMenu.setEnabled(false);
        monSeqOpMode0.setText("Item");
        monSeqOpMode0.setEnabled(false);
        monSeqOpMode0.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqOpMode0ActionPerformed(evt);
            }
        });

        monSeqOperationModeMenu.add(monSeqOpMode0);

        monSeqOpMode1.setText("Item");
        monSeqOpMode1.setEnabled(false);
        monSeqOpMode1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqOpMode1ActionPerformed(evt);
            }
        });

        monSeqOperationModeMenu.add(monSeqOpMode1);

        monSeqOpMode2.setText("Item");
        monSeqOpMode2.setEnabled(false);
        monSeqOpMode2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqOpMode2ActionPerformed(evt);
            }
        });

        monSeqOperationModeMenu.add(monSeqOpMode2);

        monSeqOpMode3.setText("Item");
        monSeqOpMode3.setEnabled(false);
        monSeqOpMode3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqOpMode3ActionPerformed(evt);
            }
        });

        monSeqOperationModeMenu.add(monSeqOpMode3);

        monSeqMenu.add(monSeqOperationModeMenu);

        monSeqMissedEventsMenuItem.setText("Get number of missed events");
        monSeqMissedEventsMenuItem.setEnabled(false);
        monSeqMissedEventsMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                monSeqMissedEventsMenuItemActionPerformed(evt);
            }
        });

        monSeqMenu.add(monSeqMissedEventsMenuItem);

        monSeqMenu.add(jSeparator13);

        sequenceMenuItem.setMnemonic('f');
        sequenceMenuItem.setText("Sequence data file...");
        sequenceMenuItem.setActionCommand("start");
        sequenceMenuItem.setEnabled(false);
        sequenceMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sequenceMenuItemActionPerformed(evt);
            }
        });

        monSeqMenu.add(sequenceMenuItem);

        menuBar.add(monSeqMenu);

        helpMenu.setMnemonic('h');
        helpMenu.setText("Help");
        contentMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F1, 0));
        contentMenuItem.setMnemonic('c');
        contentMenuItem.setText("Quick start & installation guide (online)");
        contentMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                contentMenuItemActionPerformed(evt);
            }
        });

        helpMenu.add(contentMenuItem);

        helpUserGuideMenuItem.setText("USB2 Mini user guide (PDF)");
        helpUserGuideMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                helpUserGuideMenuItemActionPerformed(evt);
            }
        });

        helpMenu.add(helpUserGuideMenuItem);

        javadocMenuItem.setText("Javadoc");
        javadocMenuItem.setToolTipText("Javadoc for classes");
        javadocMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                javadocMenuItemActionPerformed(evt);
            }
        });

        helpMenu.add(javadocMenuItem);

        aboutMenuItem.setText("About");
        aboutMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                aboutMenuItemActionPerformed(evt);
            }
        });

        helpMenu.add(aboutMenuItem);

        menuBar.add(helpMenu);

        setJMenuBar(menuBar);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void sendvisionActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendvisionActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_VISION);
    }//GEN-LAST:event_sendvisionActionPerformed

    private void sendsonicActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendsonicActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_SONIC);
    }//GEN-LAST:event_sendsonicActionPerformed

    private void starttestActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_starttestActionPerformed
        start_testing = 1;
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKSTRAIGHT);
        stopsensing = 1;
        Date date = new Date();
        prevtime = date.getTime()-2000;
        cmd = 0;
    }//GEN-LAST:event_starttestActionPerformed

    private void sendgaitchangeActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendgaitchangeActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_CHANGEGAIT);
    }//GEN-LAST:event_sendgaitchangeActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_DANCE);
    }//GEN-LAST:event_jButton3ActionPerformed

    private void sendstopActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendstopActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_STOP);
        start_testing = 0;
    }//GEN-LAST:event_sendstopActionPerformed

    private void senddownrightActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_senddownrightActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKDOWNRIGHT);
    }//GEN-LAST:event_senddownrightActionPerformed

    private void senddownleftActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_senddownleftActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKDOWNLEFT);
    }//GEN-LAST:event_senddownleftActionPerformed

    private void senduprightActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_senduprightActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKUPRIGHT);
    }//GEN-LAST:event_senduprightActionPerformed

    private void sendupleftActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendupleftActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKUPLEFT);
    }//GEN-LAST:event_sendupleftActionPerformed

    private void sendrightActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendrightActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKRIGHT);
    }//GEN-LAST:event_sendrightActionPerformed

    private void sendleftActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendleftActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKLEFT);
    }//GEN-LAST:event_sendleftActionPerformed

    private void senddownActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_senddownActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKBACK);
    }//GEN-LAST:event_senddownActionPerformed

    private void sendupActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendupActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_WALKSTRAIGHT);
    }//GEN-LAST:event_sendupActionPerformed

    private void sendroarActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendroarActionPerformed
        ((CypressFX2TmpdiffRetina)aemon).rsv2_sendcmd(RSV2_ROAR);
    }//GEN-LAST:event_sendroarActionPerformed
    
    volatile AESocketInputStream socketInputStream=null;
    
    private void openSocketInputStreamMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_openSocketInputStreamMenuItemActionPerformed
        if(socketInputStream==null){
            try{
                socketInputStream=new AESocketInputStream();
                setPlayMode(PlayMode.REMOTE);
            }catch(Exception e){
                e.printStackTrace();
            }
        }else{
            socketInputStream=null;
        }
    }//GEN-LAST:event_openSocketInputStreamMenuItemActionPerformed
    
    volatile AESocketOutputStream socketOutputStream=null;
    
    private void spikeServerCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_spikeServerCheckBoxMenuItemActionPerformed
        if(spikeServerCheckBoxMenuItem.isSelected()){
            if(socketOutputStream==null){
                socketOutputStream=new AESocketOutputStream();
            }
        }else{
            socketOutputStream=null;
        }
    }//GEN-LAST:event_spikeServerCheckBoxMenuItemActionPerformed
    
    private void logFilteredEventsCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_logFilteredEventsCheckBoxMenuItemActionPerformed
        logFilteredEventsEnabled=logFilteredEventsCheckBoxMenuItem.isSelected();
        prefs.putBoolean("AEViewer.logFilteredEventsEnabled",logFilteredEventsEnabled);
    }//GEN-LAST:event_logFilteredEventsCheckBoxMenuItemActionPerformed
    
    private void sequenceMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sequenceMenuItemActionPerformed
        
        if(evt.getActionCommand()=="start"){
            float oldScale=chipCanvas.getScale();
            AEMonitorSequencerInterface aemonseq=(AEMonitorSequencerInterface)chip.getHardwareInterface();
            try{
                if (aemonseq!=null)
                    aemonseq.stopMonitoringSequencing();
            } catch (HardwareInterfaceException e) {
                e.printStackTrace();
            }
            
            JFileChooser fileChooser=new JFileChooser();
            ChipDataFilePreview preview=new ChipDataFilePreview(fileChooser,chip); // from book swing hacks
            fileChooser.addPropertyChangeListener(preview);
            fileChooser.setAccessory(preview);
            
            String lastFilePath=prefs.get("AEViewer.lastFile",""); // get the last folder
            
            lastFile=new File(lastFilePath);
            
            DATFileFilter datFileFilter = new DATFileFilter();
            fileChooser.addChoosableFileFilter(datFileFilter);
            fileChooser.setCurrentDirectory(lastFile); // sets the working directory of the chooser
//            boolean wasPaused=isPaused();
//        setPaused(true);
            int retValue=fileChooser.showOpenDialog(this);
            if(retValue==JFileChooser.APPROVE_OPTION){
                lastFile=fileChooser.getSelectedFile();
                if(lastFile!=null) recentFiles.addFile(lastFile);
                SwingUtilities.invokeLater(new Runnable(){
                    public void run(){
                        sequenceFile(lastFile);
                    }
                });
            }
            fileChooser=null;
            //     setPaused(false);
            chipCanvas.setScale(oldScale);
        }else if(evt.getActionCommand()=="stop"){
            setPlayMode(PlayMode.LIVE);
            stopSequencing();
        }
    }//GEN-LAST:event_sequenceMenuItemActionPerformed
    
    private void sequenceFile(File file) {
        try {
            fileInputStream=new FileInputStream(file);
            setCurrentFile(file);
            AEInputStream fileAEInputStream=new AEInputStream(fileInputStream);
            
            int numberOfEvents = (int)fileAEInputStream.size();
            
            AEPacketRaw packet = fileAEInputStream.readPacketByNumber(numberOfEvents);
            
            // calculate interspike intervals
            int []ts=packet.getTimestamps();
            int []isi=new int[packet.getNumEvents()];
            
            isi[0]=ts[0];
            
            for (int i=1; i<packet.getNumEvents();i++) {
                isi[i]=ts[i]-ts[i-1];
                if (isi[i]<0) {
                    //  if (!(ts[i-1]>0 && ts[i]<0)) //if it is not an overflow, it is non-monotonic time, so set isi to zero
                    //{
                    log.info("non-monotonic time, set interspike interval to zero");
                    isi[i]=0;
                    //}
                }
            }
            packet.setTimestamps(isi);
            
            AEMonitorSequencerInterface aemonseq=(AEMonitorSequencerInterface)chip.getHardwareInterface();
            
            setPaused(false);
            
            aemonseq.setContinuousSequencingEnabled(true);
            aemonseq.startMonitoringSequencing(packet);
            setPlayMode(PlayMode.SEQUENCING);
            setTitleAccordingToState();
            sequenceMenuItem.setActionCommand("stop");
            sequenceMenuItem.setText("Stop sequencing data file");
            
            if(!playerControlPanel.isVisible()) playerControlPanel.setVisible(true);
            //   playerSlider.setVisible(true);
            playerSlider.setEnabled(false);
//            System.gc(); // garbage collect...
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private void stopSequencing(){
        try{
            if(chip!=null && chip.getHardwareInterface()!=null){
                ((AEMonitorSequencerInterface)chip.getHardwareInterface()).stopMonitoringSequencing();
            }
            
        }catch(HardwareInterfaceException e){
            e.printStackTrace();
        }
        sequenceMenuItem.setActionCommand("start");
        sequenceMenuItem.setText("Sequence data file...");
        playerControlPanel.setVisible(false);
        //   playerSlider.setVisible(true);
        playerSlider.setEnabled(true);
    }
    
    private void resizeIconLabelMouseExited(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_resizeIconLabelMouseExited
        setCursor(preResizeCursor);
    }//GEN-LAST:event_resizeIconLabelMouseExited
    
    Cursor preResizeCursor=Cursor.getDefaultCursor();
    
    private void resizeIconLabelMouseEntered(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_resizeIconLabelMouseEntered
        preResizeCursor=getCursor();
        setCursor(Cursor.getPredefinedCursor(Cursor.SE_RESIZE_CURSOR));
    }//GEN-LAST:event_resizeIconLabelMouseEntered
    
    Dimension oldSize;
    Point startResizePoint;
    
    private void resizeIconLabelMouseDragged(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_resizeIconLabelMouseDragged
        Point resizePoint=evt.getPoint();
        int widthInc=resizePoint.x-startResizePoint.x;
        int heightInc=resizePoint.y-startResizePoint.y;
        setSize(getWidth()+widthInc,getHeight()+heightInc);
    }//GEN-LAST:event_resizeIconLabelMouseDragged
    
    private void resizeIconLabelMousePressed(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_resizeIconLabelMousePressed
        oldSize=getSize();
        startResizePoint=evt.getPoint();
    }//GEN-LAST:event_resizeIconLabelMousePressed
    
    private void cycleDisplayMethodButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cycleDisplayMethodButtonActionPerformed
        chipCanvas.cycleDisplayMethod();
    }//GEN-LAST:event_cycleDisplayMethodButtonActionPerformed
    
    private void unzoomMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_unzoomMenuItemActionPerformed
        chipCanvas.unzoom();
    }//GEN-LAST:event_unzoomMenuItemActionPerformed
    
    private void zoomMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_zoomMenuItemActionPerformed
        chipCanvas.setZoomMode(true);
    }//GEN-LAST:event_zoomMenuItemActionPerformed
    
    private void viewIgnorePolarityCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewIgnorePolarityCheckBoxMenuItemActionPerformed
        chip.getRenderer().setIgnorePolarityEnabled(viewIgnorePolarityCheckBoxMenuItem.isSelected());
    }//GEN-LAST:event_viewIgnorePolarityCheckBoxMenuItemActionPerformed
    
    private void cypressFX2EEPROMMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cypressFX2EEPROMMenuItemActionPerformed
        new CypressFX2EEPROM().setVisible(true);
    }//GEN-LAST:event_cypressFX2EEPROMMenuItemActionPerformed
    
    private void loggingSetTimelimitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_loggingSetTimelimitMenuItemActionPerformed
        String ans=JOptionPane.showInputDialog(this,"Enter logging time limit in ms (0 for no limit)",loggingTimeLimit);
        try{
            int n=Integer.parseInt(ans);
            loggingTimeLimit=n;
        }catch(NumberFormatException e){
            Toolkit.getDefaultToolkit().beep();
        }
    }//GEN-LAST:event_loggingSetTimelimitMenuItemActionPerformed
    
    private void helpUserGuideMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_helpUserGuideMenuItemActionPerformed
        try{
            BrowserLauncher.openURL(HELP_URL_USER_GUIDE_USB2_MINI);
        }catch(IOException e){
            contentMenuItem.setText(e.getMessage());
        }
    }//GEN-LAST:event_helpUserGuideMenuItemActionPerformed
    
    private void formWindowClosed(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosed
        log.info("window closed event, calling stopMe");
        stopMe();
    }//GEN-LAST:event_formWindowClosed
    
    private void javadocMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_javadocMenuItemActionPerformed
        try{
            BrowserLauncher.openURL(HELP_URL_JAVADOC);
        }catch(IOException e){
            contentMenuItem.setText(e.getMessage());
        }
    }//GEN-LAST:event_javadocMenuItemActionPerformed
    
    private void viewRenderBlankFramesCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewRenderBlankFramesCheckBoxMenuItemActionPerformed
        setRenderBlankFramesEnabled(viewRenderBlankFramesCheckBoxMenuItem.isSelected());
    }//GEN-LAST:event_viewRenderBlankFramesCheckBoxMenuItemActionPerformed
    
    private void monSeqMissedEventsMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqMissedEventsMenuItemActionPerformed
        if (aemon instanceof CypressFX2MonitorSequencer) {
            CypressFX2MonitorSequencer fx=(CypressFX2MonitorSequencer)aemon;
            try{
                JOptionPane.showMessageDialog(this,fx + " missed approximately " + fx.getNumMissedEvents() + " events");
            } catch(Exception e){
                e.printStackTrace();
                aemon.close();
            }
        }
    }//GEN-LAST:event_monSeqMissedEventsMenuItemActionPerformed
    
    private void fileLoadSetupMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_fileLoadSetupMenuItemActionPerformed
        if(caviarViewer!=null)caviarViewer.loadSetup(null);
    }//GEN-LAST:event_fileLoadSetupMenuItemActionPerformed
    
    private void fileSaveSetupMenItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_fileSaveSetupMenItemActionPerformed
        if(caviarViewer!=null)caviarViewer.saveSetup(null);
    }//GEN-LAST:event_fileSaveSetupMenItemActionPerformed
    
    volatile boolean doSingleStepEnabled=false;
    
    synchronized public void doSingleStep(){
        setDoSingleStepEnabled(true);
    }
    
    public void setDoSingleStepEnabled(boolean yes){
        doSingleStepEnabled=yes;
    }
    
    synchronized public boolean isSingleStep(){
//        boolean isSingle=caviarViewer.getPlayer().isSingleStep();
//        return isSingle;
        return doSingleStepEnabled;
    }
    
    synchronized public void singleStepDone(){
        if(isSingleStep()){
            setDoSingleStepEnabled(false);
            setPaused(true);
        }
//        caviarViewer.getPlayer().singleStepDone();
    }
    
    private void viewSingleStepMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewSingleStepMenuItemActionPerformed
//        setPaused(true);
        caviarViewer.getPlayer().doSingleStep(this);
//        viewLoop.doSingleStep=true;
//        viewLoop.singleStepEnabled=true;
//        System.out.println("set singleStepEnabled=true, doSingleStep=true");
    }//GEN-LAST:event_viewSingleStepMenuItemActionPerformed
    
    private void electricalSyncEnabledCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_electricalSyncEnabledCheckBoxMenuItemActionPerformed
        if(caviarViewer!=null){
            caviarViewer.setElectricalSyncEnabled(electricalSyncEnabledCheckBoxMenuItem.isSelected());
        }
    }//GEN-LAST:event_electricalSyncEnabledCheckBoxMenuItemActionPerformed
    
    private void monSeqOpMode3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqOpMode3ActionPerformed
        if (aemon instanceof CypressFX2MonitorSequencer) {
            CypressFX2MonitorSequencer fx=(CypressFX2MonitorSequencer)aemon;
            try{
                fx.setOperationMode(3);
            } catch(Exception e){
                e.printStackTrace();
                aemon.close();
            }
        }
    }//GEN-LAST:event_monSeqOpMode3ActionPerformed
    
    private void monSeqOpMode2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqOpMode2ActionPerformed
        if (aemon instanceof CypressFX2MonitorSequencer) {
            CypressFX2MonitorSequencer fx=(CypressFX2MonitorSequencer)aemon;
            try{
                fx.setOperationMode(2);
            } catch(Exception e){
                e.printStackTrace();
                aemon.close();
            }
        }
    }//GEN-LAST:event_monSeqOpMode2ActionPerformed
    
    private void monSeqOpMode1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqOpMode1ActionPerformed
        if (aemon instanceof CypressFX2MonitorSequencer) {
            CypressFX2MonitorSequencer fx=(CypressFX2MonitorSequencer)aemon;
            try{
                fx.setOperationMode(1);
            } catch(Exception e){
                e.printStackTrace();
                aemon.close();
            }
        }
    }//GEN-LAST:event_monSeqOpMode1ActionPerformed
    
    private void monSeqOpMode0ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqOpMode0ActionPerformed
        if (aemon instanceof CypressFX2MonitorSequencer) {
            CypressFX2MonitorSequencer fx=(CypressFX2MonitorSequencer)aemon;
            try{
                fx.setOperationMode(0);
            } catch(Exception e){
                e.printStackTrace();
                aemon.close();
            }
        }
    }//GEN-LAST:event_monSeqOpMode0ActionPerformed
    
    private void buildMonSeqMenu() {
        monSeqMenu.getPopupMenu().setLightWeightPopupEnabled(false); // canvas is heavyweight so we need this to make menu popup show
        monSeqOperationModeMenu.getPopupMenu().setLightWeightPopupEnabled(false); // canvas is heavyweight so we need this to make menu popup show
        this.monSeqOperationModeMenu.setText("MonitorSequencer Operation Mode");
        this.monSeqOpMode0.setText("Trigger: Host, Tick: 1us");
        this.monSeqOpMode1.setText("Trigger: Host, Tick: 0.033us");
        this.monSeqOpMode2.setText("Trigger: Slave, Tick: 1us");
        this.monSeqOpMode3.setText("Trigger: Slave, Tick: 0.033us");
        this.monSeqMissedEventsMenuItem.setText("Get number of missed events");
    }
    
    private void enableMonSeqMenu(boolean state) {
        this.monSeqMenu.setEnabled(state);
        this.monSeqOperationModeMenu.setEnabled(false);
        this.monSeqOpMode0.setEnabled(false);
        this.monSeqOpMode1.setEnabled(false);
        this.monSeqOpMode2.setEnabled(false);
        this.monSeqOpMode3.setEnabled(false);
        this.monSeqMissedEventsMenuItem.setEnabled(state);
        this.sequenceMenuItem.setEnabled(state);
    }
    
    private void monSeqMenuActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_monSeqMenuActionPerformed
        
    }//GEN-LAST:event_monSeqMenuActionPerformed
    
    private void deviceMenuActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_deviceMenuActionPerformed
// TODO add your handling code here:
    }//GEN-LAST:event_deviceMenuActionPerformed
    
    // used to print dt for measuring frequency from playback by using '1' keystrokes
    class Statistics{
        JFrame statFrame;
        JLabel statLabel;
        int lastTime=0, thisTime;
        EngineeringFormat fmt=new EngineeringFormat();{
            fmt.precision=2;
        }
        void printStats(){
            synchronized (aePlayer){
                thisTime=aePlayer.getTime();
                int dt=lastTime-thisTime;
                float dtSec=(float)((float)dt/1e6f+Float.MIN_VALUE);
                float freqHz=1/dtSec;
//                System.out.println(String.format("dt=%.2g s, freq=%.2g Hz",dtSec,freqHz));
                if(statFrame==null) {
                    statFrame=new JFrame("Statistics");
                    statLabel=new JLabel();
                    statFrame.getContentPane().setLayout(new BorderLayout());
                    statFrame.getContentPane().add(statLabel,BorderLayout.CENTER);
                    statFrame.pack();
                }
                String s="dt="+fmt.format(dtSec)+"s, freq="+fmt.format(freqHz)+" Hz";
                System.out.println(s);
                statLabel.setText(s);
                statLabel.revalidate();
                statFrame.pack();
                if(!statFrame.isVisible()) statFrame.setVisible(true);
                lastTime=thisTime;
            }
        }
    }
    
    Statistics statistics;
    
    private void measureTimeMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_measureTimeMenuItemActionPerformed
        if(statistics==null) statistics=new Statistics();
        statistics.printStats();
    }//GEN-LAST:event_measureTimeMenuItemActionPerformed
    
    private void formWindowClosing(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosing
        if(caviarViewer.getViewers().size()==1) {
            log.info("window closing event, only 1 viewer so calling System.exit");
            stopMe();
            System.exit(0);
        }else{
            log.info("window closing event, calling stopMe");
            stopMe();
        }
    }//GEN-LAST:event_formWindowClosing
    
    private void newViewerMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_newViewerMenuItemActionPerformed
        new AEViewer(caviarViewer).setVisible(true);
    }//GEN-LAST:event_newViewerMenuItemActionPerformed
    
    private void interfaceMenuMenuSelected(javax.swing.event.MenuEvent evt) {//GEN-FIRST:event_interfaceMenuMenuSelected
        buildInterfaceMenu();
    }//GEN-LAST:event_interfaceMenuMenuSelected
    
    private void interfaceMenuActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_interfaceMenuActionPerformed
        buildInterfaceMenu();
    }//GEN-LAST:event_interfaceMenuActionPerformed
    
    private void formComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_formComponentResized
        // handle statistics label font sizing here
//        System.out.println("*****************frame resize");
        double fw=getWidth();
        double lw=statisticsLabel.getWidth();
        
        if(fw<200) fw=200;
        double r=fw/lw;
        final double mn=.3, mx=2.3;
        if(r<mn) r=mn; if(r>mx) r=mx;
        
        final int minFont=8, maxFont=36;
//        System.out.println("frame/label width="+r);
        Font f=statisticsLabel.getFont();
        int size=f.getSize();
        int newsize=(int)Math.floor(size*r);
        if(newsize<minFont) newsize=minFont; if(newsize>maxFont) newsize=maxFont;
        if(size==newsize) return;
        Font nf=f.deriveFont((float)newsize);
//        System.out.println("old font="+f);
//        System.out.println("new font="+nf);
        statisticsLabel.setFont(nf);
        
    }//GEN-LAST:event_formComponentResized
    
    private void statisticsPanelComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_statisticsPanelComponentResized
        
//        statisticsPanel.revalidate();
    }//GEN-LAST:event_statisticsPanelComponentResized
    
    private void saveImageSequenceMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveImageSequenceMenuItemActionPerformed
        if(canvasFileWriter.writingMovieEnabled){
            canvasFileWriter.stopWritingMovie();
            saveImageSequenceMenuItem.setText("Start writing image sequence");
        }else{
            canvasFileWriter.startWritingMovie();
            saveImageSequenceMenuItem.setText("Stop writing sequence");
        }
    }//GEN-LAST:event_saveImageSequenceMenuItemActionPerformed
    
    CanvasFileWriter canvasFileWriter=new CanvasFileWriter();
    
    private void saveImageMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveImageMenuItemActionPerformed
        synchronized(chipCanvas){
            canvasFileWriter.writeSnapshotImage(); // chipCanvas must be drawn with java (not openGL) for this to work
        }
    }//GEN-LAST:event_saveImageMenuItemActionPerformed
    
    private void refreshInterfaceMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_refreshInterfaceMenuItemActionPerformed
        // TODO add your handling code here:
    }//GEN-LAST:event_refreshInterfaceMenuItemActionPerformed
    
    private void toggleMarkCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_toggleMarkCheckBoxMenuItemActionPerformed
        try{
            synchronized(getAePlayer()){
                if(toggleMarkCheckBoxMenuItem.isSelected()){
                    getAePlayer().mark();
//                    Dictionary<Integer,JLabel> dict=new Dictionary<Integer,JLabel>();
                    Hashtable<Integer,JLabel> markTable=new Hashtable<Integer,JLabel>();
                    markTable.put(playerSlider.getValue(),new JLabel("^"));
                    playerSlider.setLabelTable(markTable);
                    playerSlider.setPaintLabels(true);
                }else{
                    getAePlayer().unmark();
                    playerSlider.setPaintLabels(false);
                }
            }
        }catch(IOException e){
            e.printStackTrace();
        }
    }//GEN-LAST:event_toggleMarkCheckBoxMenuItemActionPerformed
    
    private void subSampleSizeMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_subSampleSizeMenuItemActionPerformed
        String ans=JOptionPane.showInputDialog(this,"Enter limit to number of rendered events",renderer.getSubsampleThresholdEventCount());
        try{
            int n=Integer.parseInt(ans);
            renderer.setSubsampleThresholdEventCount(n);
            extractor.setSubsampleThresholdEventCount(n);
        }catch(NumberFormatException e){
            Toolkit.getDefaultToolkit().beep();
        }
    }//GEN-LAST:event_subSampleSizeMenuItemActionPerformed
    
    private void filtersToggleButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_filtersToggleButtonActionPerformed
        showFilters(filtersToggleButton.isSelected());
    }//GEN-LAST:event_filtersToggleButtonActionPerformed
    
    private void biasesToggleButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_biasesToggleButtonActionPerformed
        showBiasgen(biasesToggleButton.isSelected());
    }//GEN-LAST:event_biasesToggleButtonActionPerformed
    
    private void imagePanelMouseWheelMoved(java.awt.event.MouseWheelEvent evt) {//GEN-FIRST:event_imagePanelMouseWheelMoved
        int rotation=evt.getWheelRotation();
        renderer.setColorScale(renderer.getColorScale()+rotation);
    }//GEN-LAST:event_imagePanelMouseWheelMoved
    
    private void loggingPlaybackImmediatelyCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_loggingPlaybackImmediatelyCheckBoxMenuItemActionPerformed
        setLoggingPlaybackImmediatelyEnabled(!isLoggingPlaybackImmediatelyEnabled());
    }//GEN-LAST:event_loggingPlaybackImmediatelyCheckBoxMenuItemActionPerformed
    
    private void togglePlaybackDirectionMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_togglePlaybackDirectionMenuItemActionPerformed
        getAePlayer().toggleDirection();
    }//GEN-LAST:event_togglePlaybackDirectionMenuItemActionPerformed
    
    private void flextimePlaybackEnabledCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_flextimePlaybackEnabledCheckBoxMenuItemActionPerformed
        if(!caviarViewer.isSyncEnabled() || caviarViewer.getViewers().size()==1) {
            aePlayer.toggleFlexTime();
        }else{
            JOptionPane.showMessageDialog(this,"Flextime playback doesn't make sense for sychronized viewing");
            flextimePlaybackEnabledCheckBoxMenuItem.setSelected(false);
        }
    }//GEN-LAST:event_flextimePlaybackEnabledCheckBoxMenuItemActionPerformed
    
    private void rewindPlaybackMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_rewindPlaybackMenuItemActionPerformed
        getAePlayer().rewind();
    }//GEN-LAST:event_rewindPlaybackMenuItemActionPerformed
    
    private void decreasePlaybackSpeedMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_decreasePlaybackSpeedMenuItemActionPerformed
        getAePlayer().slowDown();
    }//GEN-LAST:event_decreasePlaybackSpeedMenuItemActionPerformed
    
    private void increasePlaybackSpeedMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_increasePlaybackSpeedMenuItemActionPerformed
        getAePlayer().speedUp();
    }//GEN-LAST:event_increasePlaybackSpeedMenuItemActionPerformed
    
    private void autoscaleContrastEnabledCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_autoscaleContrastEnabledCheckBoxMenuItemActionPerformed
        renderer.setAutoscaleEnabled(!renderer.isAutoscaleEnabled());;
    }//GEN-LAST:event_autoscaleContrastEnabledCheckBoxMenuItemActionPerformed
    
    private void acccumulateImageEnabledCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_acccumulateImageEnabledCheckBoxMenuItemActionPerformed
        renderer.setAccumulateEnabled(!renderer.isAccumulateEnabled());
    }//GEN-LAST:event_acccumulateImageEnabledCheckBoxMenuItemActionPerformed
    
    private void zeroTimestampsMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_zeroTimestampsMenuItemActionPerformed
        if(caviarViewer!=null && caviarViewer.isSyncEnabled() && !caviarViewer.isElectricalSyncEnabled()){
            caviarViewer.zeroTimestamps();
        } else{
            zeroTimestamps();
        }
    }//GEN-LAST:event_zeroTimestampsMenuItemActionPerformed
    
    private void pauseRenderingCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_pauseRenderingCheckBoxMenuItemActionPerformed
        setPaused(!isPaused());
        if(!isPaused()) {
//            viewLoop.singleStepEnabled=false;
//            System.out.println("pauseRenderingCheckBoxMenuItemActionPerformed: set singleStepEnabled=false");
        }
    }//GEN-LAST:event_pauseRenderingCheckBoxMenuItemActionPerformed
    
    private void decreaseFrameRateMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_decreaseFrameRateMenuItemActionPerformed
//            case KeyEvent.VK_LEFT: // slower
        setFrameRate(getFrameRate()/2);
//                break;
//            case KeyEvent.VK_RIGHT: //faster
//                setFrameRate(getFrameRate()*2);
//                break;
        
    }//GEN-LAST:event_decreaseFrameRateMenuItemActionPerformed
    
    private void increaseFrameRateMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_increaseFrameRateMenuItemActionPerformed
//            case KeyEvent.VK_LEFT: // slower
//                setFrameRate(getFrameRate()/2);
//                break;
//            case KeyEvent.VK_RIGHT: //faster
        setFrameRate(getFrameRate()*2);
//                break;
        
    }//GEN-LAST:event_increaseFrameRateMenuItemActionPerformed
    
    private void decreaseContrastMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_decreaseContrastMenuItemActionPerformed
        renderer.setColorScale(renderer.getColorScale()+1);
    }//GEN-LAST:event_decreaseContrastMenuItemActionPerformed
    
    private void increaseContrastMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_increaseContrastMenuItemActionPerformed
        renderer.setColorScale(renderer.getColorScale()-1);
    }//GEN-LAST:event_increaseContrastMenuItemActionPerformed
    
    private void cycleColorRenderingMethodMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cycleColorRenderingMethodMenuItemActionPerformed
        renderer.cycleColorMode();
    }//GEN-LAST:event_cycleColorRenderingMethodMenuItemActionPerformed
    
    private void subsampleEnabledCheckBoxMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_subsampleEnabledCheckBoxMenuItemActionPerformed
        chip.setSubSamplingEnabled(subsampleEnabledCheckBoxMenuItem.isSelected());
    }//GEN-LAST:event_subsampleEnabledCheckBoxMenuItemActionPerformed
    
    private void closeMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_closeMenuItemActionPerformed
        stopMe();
    }//GEN-LAST:event_closeMenuItemActionPerformed
    
    private void viewOpenGLEnabledMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewOpenGLEnabledMenuItemActionPerformed
        synchronized(chip.getCanvas()){
            setOpenGLRenderingEnabled(viewOpenGLEnabledMenuItem.isSelected());
        }
    }//GEN-LAST:event_viewOpenGLEnabledMenuItemActionPerformed
    
    
    private void viewActiveRenderingEnabledMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewActiveRenderingEnabledMenuItemActionPerformed
        setActiveRenderingEnabled(viewActiveRenderingEnabledMenuItem.isSelected());
    }//GEN-LAST:event_viewActiveRenderingEnabledMenuItemActionPerformed
    void fixDeviceControlMenuItems(){
//        log.info("fixing device control menu");
        int k=controlMenu.getMenuComponentCount();
        if(aemon==null || (!(aemon instanceof ReaderBufferControl) && !aemon.isOpen())){
            for(int i=0;i<k;i++){
                if(controlMenu.getMenuComponent(i) instanceof JMenuItem){
                    ((JMenuItem)controlMenu.getMenuComponent(i)).setEnabled(false);
                }
            }
        }else if(aemon!=null && (aemon instanceof ReaderBufferControl) && aemon.isOpen()){
            ReaderBufferControl readerControl=(ReaderBufferControl)aemon;
            try{
                CypressFX2 fx2=(CypressFX2)aemon;
                PropertyChangeSupport support=fx2.getSupport();
                // propertyChange method in this file deals with these events
                if(!support.hasListeners("readerStarted")) {
                    support.addPropertyChangeListener("readerStarted",this); // when the reader starts running, we get called back to fix device control menu
                }
            }catch(ClassCastException e){
                log.warning("tried to add "+aemon+" as listener for reader start/stop in device control menu but this is probably a stereo interface");
            }
            if(readerControl==null) return;
            int n=readerControl.getNumBuffers();
            int f=readerControl.getFifoSize();
            decreaseNumBuffersMenuItem.setText("Decrease num buffers to "+(n-1));
            increaseNumBuffersMenuItem.setText("Increase num buffers to "+(n+1));
            decreaseBufferSizeMenuItem.setText("Decrease FIFO size to "+(f/2));
            increaseBufferSizeMenuItem.setText("Increase FIFO size to "+(f*2));
            decreaseBufferSizeMenuItem.setEnabled(true);
            increaseBufferSizeMenuItem.setEnabled(true);
            decreaseNumBuffersMenuItem.setEnabled(true);
            increaseNumBuffersMenuItem.setEnabled(true);
        }
        cypressFX2EEPROMMenuItem.setEnabled(true); // always set the true to be able to launch utility even if the device is not a retina
    }
    
    private void decreaseNumBuffersMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_decreaseNumBuffersMenuItemActionPerformed
        if(aemon!=null && aemon instanceof ReaderBufferControl && aemon.isOpen()){
            ReaderBufferControl reader=(ReaderBufferControl)aemon;
            int n=reader.getNumBuffers()-1;
            if(n<1) n=1;
            reader.setNumBuffers(n);
            fixDeviceControlMenuItems();
        }
        
    }//GEN-LAST:event_decreaseNumBuffersMenuItemActionPerformed
    
    private void increaseNumBuffersMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_increaseNumBuffersMenuItemActionPerformed
        if(aemon!=null && aemon instanceof ReaderBufferControl && aemon.isOpen()){
            ReaderBufferControl reader=(ReaderBufferControl)aemon;
            int n=reader.getNumBuffers()+1;
            reader.setNumBuffers(n);
            fixDeviceControlMenuItems();
        }
    }//GEN-LAST:event_increaseNumBuffersMenuItemActionPerformed
    
    private void decreaseBufferSizeMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_decreaseBufferSizeMenuItemActionPerformed
        if(aemon!=null && aemon instanceof ReaderBufferControl && aemon.isOpen()){
            ReaderBufferControl reader=(ReaderBufferControl)aemon;
            int n=reader.getFifoSize()/2;
            reader.setFifoSize(n);
            fixDeviceControlMenuItems();
        }
    }//GEN-LAST:event_decreaseBufferSizeMenuItemActionPerformed
    
    private void increaseBufferSizeMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_increaseBufferSizeMenuItemActionPerformed
        if(aemon!=null && aemon instanceof ReaderBufferControl && aemon.isOpen()){
            ReaderBufferControl reader=(ReaderBufferControl)aemon;
            int n=reader.getFifoSize()*2;
            reader.setFifoSize(n);
            fixDeviceControlMenuItems();
        }
    }//GEN-LAST:event_increaseBufferSizeMenuItemActionPerformed
    
    private void viewFiltersMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewFiltersMenuItemActionPerformed
        showFilters(true);
    }//GEN-LAST:event_viewFiltersMenuItemActionPerformed
    
    private void viewBiasesMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_viewBiasesMenuItemActionPerformed
        showBiasgen(true);
    }//GEN-LAST:event_viewBiasesMenuItemActionPerformed
    
    //avoid stateChanged events from slider that is set by player
    volatile boolean sliderDontProcess=false;
    
    /** messages come back here from e.g. programmatic state changes, like a new aePlayer file posiiton.
     * This methods sets the GUI components to a consistent state, using a flag to tell the slider that it has not been set by
     * a user mouse action
     */
    public void propertyChange(PropertyChangeEvent evt) {
        if(evt.getPropertyName().equals("position")){
//            System.out.println("slider property change new val="+evt.getNewValue());
            sliderDontProcess=true;
            // note this cool semaphore/flag trick to avoid processing the
            // event generated when we programmatically set the slider position here
            playerSlider.setValue(Math.round(aePlayer.getFractionalPosition()*100));
        }else if(evt.getPropertyName().equals("readerStarted")){
            log.info("AEViewer.propertyChange: AEReader started, fixing device control menu");
            // cypress reader started, can set device control for cypress usbio reader thread
            fixDeviceControlMenuItems();
        }
    }
    
    private void playerSliderStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_playerSliderStateChanged
        if(sliderDontProcess){
            sliderDontProcess=false; // to avoid player callbacks generating more AWT events
            return;
        }
        float fracPos=(float)playerSlider.getValue()/(playerSlider.getMaximum());
        
        synchronized(aePlayer){
            try{
                int oldtime=aePlayer.getAEInputStream().getMostRecentTimestamp();
                aePlayer.setFractionalPosition(fracPos); // sets position in events
                int time=aePlayer.getAEInputStream().getMostRecentTimestamp();
                aePlayer.getAEInputStream().setCurrentStartTimestamp(time);
//                log.info(this+" slider set time to "+time);
                if(caviarViewer.getViewers().size()>1) {
                    if(time<oldtime){
                        // we need to set position in all viewers so that we catch up to present desired time
                        AEPlayerInterface p;
                        AEInputStream is;
                        try{
                            for(AEViewer v:caviarViewer.getViewers()){
                                if(true){
                                    p=v.aePlayer; // we want local play here!
                                    is=p.getAEInputStream();
                                    if(is!=null){
                                        is.rewind();
                                    }else{
                                        log.warning("null ae input stream on reposition");
                                    }
                                    
                                }
                            }
                            caviarViewer.getPlayer().setTime(time);
                        }catch(Exception e){
                            e.printStackTrace();
                        }
                    }
                }
            }catch(IllegalArgumentException e){
                e.printStackTrace();
            }
//            System.out.println("playerSlider state changed new pos="+pos);
        }
    }//GEN-LAST:event_playerSliderStateChanged
    
    private void contentMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_contentMenuItemActionPerformed
        try{
            BrowserLauncher.openURL(HELP_URL_USER_GUIDE);
        }catch(IOException e){
            contentMenuItem.setText(e.getMessage());
        }
    }//GEN-LAST:event_contentMenuItemActionPerformed
    
    private void aboutMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aboutMenuItemActionPerformed
        new AEViewerAboutDialog(new javax.swing.JFrame(), true).setVisible(true);
    }//GEN-LAST:event_aboutMenuItemActionPerformed
    
    
    
    private void openMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_openMenuItemActionPerformed
        getAePlayer().openAEInputFileDialog();
    }//GEN-LAST:event_openMenuItemActionPerformed
    
    void showFilters(boolean yes){
        if(filterFrame!=null) {
            filterFrame.setVisible(yes);
        }
        filtersToggleButton.setSelected(yes);
    }

    
    
    void showBiasgen(final boolean yes){
        SwingUtilities.invokeLater(new Runnable(){
            public void run(){
                if(chip.getBiasgen()==null  ){ // this chip has no biasgen - but it won't have one until HW interface is opened for it successfully
                    if(biasgenFrame!=null) biasgenFrame.dispose();
//            biasesToggleButton.setEnabled(false);  // chip don't have biasgen until it has HW interface, which it doesn't at first....
                    return;
                }else{
                    biasesToggleButton.setEnabled(true);
                    viewBiasesMenuItem.setEnabled(true);
                }
                if(biasgen!=chip.getBiasgen()){ // biasgen changed
                    if(biasgenFrame!=null) biasgenFrame.dispose();
                    biasgenFrame=new BiasgenFrame(chip);
                    biasgenFrame.addWindowListener(new WindowAdapter() {
                        public void windowClosed(WindowEvent e){
                            log.info(e.toString());
                            biasesToggleButton.setSelected(false);
                        }
                    });
                }
                if(biasgenFrame!=null){
                    biasgenFrame.setVisible(yes);
                }
                biasesToggleButton.setSelected(yes);
                biasgen=chip.getBiasgen();
                
            }
        });
    }
    
    synchronized public void toggleLogging(){
        if(caviarViewer!=null && caviarViewer.isSyncEnabled() && caviarViewer.getViewers().size()>1)
            caviarViewer.toggleSynchronizedLogging();
        else{
            if(loggingEnabled)
                stopLogging();
            else
                startLogging();
        }
//        if(loggingButton.isSelected()){
//            if(caviarViewer!=null && caviarViewer.isSyncEnabled() ) caviarViewer.startSynchronizedLogging(); else startLogging();
//        }else{
//            if(caviarViewer!=null && caviarViewer.isSyncEnabled()) caviarViewer.stopSynchronizedLogging(); else stopLogging();
//        }
    }
    
    void fixLoggingControls(){
//        System.out.println("fixing logging controls, loggingEnabled="+loggingEnabled);
        if(aemon==null || (aemon!=null && !aemon.isOpen())){
            loggingButton.setEnabled(false);
            loggingMenuItem.setEnabled(false);
            return;
        }else{
            loggingButton.setEnabled(true);
            loggingMenuItem.setEnabled(true);
        }
        if(loggingEnabled){
            loggingButton.setText("Stop logging");
            loggingButton.setSelected(true);
            loggingMenuItem.setText("Stop logging data");
        }else{
            loggingButton.setText("Start logging");
            loggingButton.setSelected(false);
            loggingMenuItem.setText("Start logging data");
        }
    }
    
    synchronized public File startLogging(){
//        if(playMode!=PlayMode.LIVE) return null;
        String dateString=loggingFilenameDateFormat.format(new Date());
        String className=chip.getClass().getSimpleName();
        int suffixNumber=0;
        boolean suceeded=false;
        String filename;
        do{
            filename=className+"-"+dateString+"-"+suffixNumber+AEDataFile.DATA_FILE_EXTENSION;
            loggingFile=new File(filename);
            if(!loggingFile.isFile()) suceeded=true;
        }while(suceeded==false && suffixNumber++<=5);
        if(suceeded==false){
            System.err.println("AEViewer.startLogging(): could not open a unigue new file for logging after trying up to "+filename);
            return null;
        }
        try{
            loggingOutputStream=new AEOutputStream(new BufferedOutputStream(new FileOutputStream(loggingFile)));
            loggingEnabled=true;
            log.info("starting logging at "+dateString);
            setCurrentFile(loggingFile);
            loggingEnabled=true;
            fixLoggingControls();
            if(loggingTimeLimit>0){
                loggingStartTime=System.currentTimeMillis();
            }
//            aemon.resetTimestamps();
        }catch(FileNotFoundException e){
            loggingFile=null;
            e.printStackTrace();
        }
        return loggingFile;
    }
    
    synchronized public void stopLogging(){
        if(loggingEnabled){
            if(loggingButton.isSelected()) loggingButton.setSelected(false);
            loggingButton.setText("Start logging");
            loggingMenuItem.setText("Start logging data");
            try{
                synchronized(loggingOutputStream){
                    loggingEnabled=false;
                    loggingOutputStream.close();
                }
                String dateString= loggingFilenameDateFormat.format(new Date());
                log.info("stopping logging at "+dateString);
                recentFiles.addFile(loggingFile);
            }catch(IOException e){
                e.printStackTrace();
            }
            if(isLoggingPlaybackImmediatelyEnabled()){
                try{
                    getAePlayer().startPlayback(loggingFile);
                }catch(FileNotFoundException e){
                    e.printStackTrace();
                }
            }
            loggingEnabled=false;
        }
        fixLoggingControls();
    }
    
    public String toString(){
        return getTitle();
    }
    
    private void exitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_exitMenuItemActionPerformed
//        System.exit(0);
        stopMe();
        if(aemon!=null && aemon.isOpen()) aemon.close();
        System.exit(0);
    }//GEN-LAST:event_exitMenuItemActionPerformed
    
//    /**
//     * @param args the command line arguments
//     */
//    public static void main(String args[]) {
//        try {
//            UIManager.setLookAndFeel(new WindowsLookAndFeel());
//        } catch (Exception e) {
//
//        }
//        java.awt.EventQueue.invokeLater(new Runnable() {
//            public void run() {
//                new AEViewer().setVisible(true);
//            }
//        });
//    }
    
    public int getFrameRate() {
        return frameRater.getDesiredFPS();
    }
    
    public void setFrameRate(int renderDesiredFrameRateHz) {
        frameRater.setDesiredFPS(renderDesiredFrameRateHz);
    }
    
    public boolean isPaused() {
        return caviarViewer.getPlayer().isPaused();
    }
    
    /** sets paused. If viewing is synchronized, then all viwewers will be paused.
     *@param paused true to pause
     */
    public void setPaused(boolean paused) {
        caviarViewer.getPlayer().setPaused(paused);
    }
    
    public boolean isActiveRenderingEnabled() {
        return activeRenderingEnabled;
    }
    
    public void setActiveRenderingEnabled(boolean activeRenderingEnabled) {
        this.activeRenderingEnabled = activeRenderingEnabled;
        prefs.putBoolean("AEViewer.activeRenderingEnabled",activeRenderingEnabled);
    }
    
    public boolean isOpenGLRenderingEnabled() {
        return openGLRenderingEnabled;
    }
    
    public void setOpenGLRenderingEnabled(boolean openGLRenderingEnabled) {
        this.openGLRenderingEnabled = openGLRenderingEnabled;
        getChip().getCanvas().setOpenGLEnabled(openGLRenderingEnabled);
        prefs.putBoolean("AEViewer.openGLRenderingEnabled",openGLRenderingEnabled);
//        makeCanvas();
    }
    
    
    // drag and drop data file onto frame to play it
//          Called while a drag operation is ongoing, when the mouse pointer enters the operable part of the drop site for the DropTarget registered with this listener.
    public  void 	dragEnter(DropTargetDragEvent dtde){
        Transferable transferable=dtde.getTransferable();
        try{
            if(transferable.isDataFlavorSupported(DataFlavor.javaFileListFlavor)){
                java.util.List<File> files=(java.util.List<File>)transferable.getTransferData(DataFlavor.javaFileListFlavor);
                for(File f:files){
                    if(f.getName().endsWith(AEDataFile.DATA_FILE_EXTENSION) || f.getName().endsWith(AEDataFile.INDEX_FILE_EXTENSION))  draggedFile=f; else draggedFile=null;
                }
//                System.out.println("AEViewer.dragEnter(): draqged file="+draggedFile);
            }
        }catch(UnsupportedFlavorException e){
            e.printStackTrace();
        }catch(IOException e){
            e.printStackTrace();
        }
        
    }
    
//          Called while a drag operation is ongoing, when the mouse pointer has exited the operable part of the drop site for the DropTarget registered with this listener.
    public void 	dragExit(DropTargetEvent dte){
        draggedFile=null;
    }
//          Called when a drag operation is ongoing, while the mouse pointer is still over the operable part of the drop site for the DropTarget registered with this listener.
    public  void 	dragOver(DropTargetDragEvent dtde){}
    
    //  Called when the drag operation has terminated with a drop on the operable part of the drop site for the DropTarget registered with this listener.
    public void drop(DropTargetDropEvent dtde){
        if(draggedFile!=null){
            log.info("AEViewer.drop(): opening file "+draggedFile);
            try{
                recentFiles.addFile(draggedFile);
                aePlayer.startPlayback(draggedFile);
            }catch(FileNotFoundException e){
                e.printStackTrace();
            }
        }
    }
    
//          Called if the user has modified the current drop gesture.
    public void dropActionChanged(DropTargetDragEvent dtde){}
    
    public boolean isLoggingPlaybackImmediatelyEnabled() {
        return loggingPlaybackImmediatelyEnabled;
    }
    
    public void setLoggingPlaybackImmediatelyEnabled(boolean loggingPlaybackImmediatelyEnabled) {
        this.loggingPlaybackImmediatelyEnabled = loggingPlaybackImmediatelyEnabled;
        prefs.putBoolean("AEViewer.loggingPlaybackImmediatelyEnabled",loggingPlaybackImmediatelyEnabled);
    }
    
    /** @return the chip we are displaying */
    public AEChip getChip() {
        return chip;
    }
    
    public void setChip(AEChip chip) {
        this.chip = chip;
    }
    
    public boolean isRenderBlankFramesEnabled() {
        return renderBlankFramesEnabled;
    }
    
    public void setRenderBlankFramesEnabled(boolean renderBlankFramesEnabled) {
        this.renderBlankFramesEnabled = renderBlankFramesEnabled;
        prefs.putBoolean("AEViewer.renderBlankFramesEnabled",renderBlankFramesEnabled);
//        log.info("renderBlankFramesEnabled="+renderBlankFramesEnabled);
    }
    
    public javax.swing.JMenu getFileMenu() {
        return fileMenu;
    }
    
    /** used in CaviarViewer to control sync'ed logging */
    public javax.swing.JMenuItem getLoggingMenuItem() {
        return loggingMenuItem;
    }
    
    public void setLoggingMenuItem(javax.swing.JMenuItem loggingMenuItem) {
        this.loggingMenuItem = loggingMenuItem;
    }
    
    /** this toggle button is used in CaviarViewer to assign an action to start and stop logging for (possibly) all viewers */
    public javax.swing.JToggleButton getLoggingButton() {
        return loggingButton;
    }
    
    public void setLoggingButton(javax.swing.JToggleButton b){
        this.loggingButton=b;
    }
    
    public JCheckBoxMenuItem getSyncEnabledCheckBoxMenuItem() {
        return syncEnabledCheckBoxMenuItem;
    }
    
    public void setSyncEnabledCheckBoxMenuItem(javax.swing.JCheckBoxMenuItem syncEnabledCheckBoxMenuItem) {
        this.syncEnabledCheckBoxMenuItem = syncEnabledCheckBoxMenuItem;
    }
    
    /** @return the local player, unless we are part of a synchronized playback gruop */
    public AEPlayerInterface getAePlayer() {
        if(caviarViewer==null || !caviarViewer.isSyncEnabled() || caviarViewer.getViewers().size()==1) return aePlayer;
        return caviarViewer.getPlayer();
    }
    
    public javax.swing.JCheckBoxMenuItem getElectricalSyncEnabledCheckBoxMenuItem() {
        return electricalSyncEnabledCheckBoxMenuItem;
    }
    
    public PlayMode getPlayMode() {
        return playMode;
    }
    
    /** sets mode, LIVE, PLAYBACK, WAITING, etc */
    public void setPlayMode(PlayMode playMode) {
        // there can be a race condition where user tries to open file, this sets
        // playMode to PLAYBACK but run() method in ViewLoop sets it back to WAITING
        this.playMode = playMode;
        log.info("set playMode="+playMode);
    }
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JMenuItem aboutMenuItem;
    private javax.swing.JCheckBoxMenuItem acccumulateImageEnabledCheckBoxMenuItem;
    private javax.swing.JCheckBoxMenuItem autoscaleContrastEnabledCheckBoxMenuItem;
    private javax.swing.JToggleButton biasesToggleButton;
    private javax.swing.JMenuItem closeMenuItem;
    private javax.swing.JMenuItem contentMenuItem;
    private javax.swing.JMenu controlMenu;
    private javax.swing.JMenuItem cycleColorRenderingMethodMenuItem;
    private javax.swing.JMenuItem cycleDisplayMethodButton;
    private javax.swing.JMenuItem cypressFX2EEPROMMenuItem;
    private javax.swing.JMenuItem decreaseBufferSizeMenuItem;
    private javax.swing.JMenuItem decreaseContrastMenuItem;
    private javax.swing.JMenuItem decreaseFrameRateMenuItem;
    private javax.swing.JMenuItem decreaseNumBuffersMenuItem;
    private javax.swing.JMenuItem decreasePlaybackSpeedMenuItem;
    private javax.swing.JMenu deviceMenu;
    private javax.swing.JMenu displayMethodMenu;
    private javax.swing.JCheckBoxMenuItem electricalSyncEnabledCheckBoxMenuItem;
    private javax.swing.JMenuItem exitMenuItem;
    private javax.swing.JMenuItem fileLoadSetupMenuItem;
    private javax.swing.JMenu fileMenu;
    private javax.swing.JMenuItem fileSaveSetupMenItem;
    private javax.swing.JToggleButton filtersToggleButton;
    private javax.swing.JCheckBoxMenuItem flextimePlaybackEnabledCheckBoxMenuItem;
    private javax.swing.JMenu helpMenu;
    private javax.swing.JMenuItem helpUserGuideMenuItem;
    private javax.swing.JPanel imagePanel;
    private javax.swing.JMenuItem increaseBufferSizeMenuItem;
    private javax.swing.JMenuItem increaseContrastMenuItem;
    private javax.swing.JMenuItem increaseFrameRateMenuItem;
    private javax.swing.JMenuItem increaseNumBuffersMenuItem;
    private javax.swing.JMenuItem increasePlaybackSpeedMenuItem;
    private javax.swing.JMenu interfaceMenu;
    private javax.swing.JButton jButton3;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel4;
    private javax.swing.JPanel jPanel5;
    private javax.swing.JProgressBar jProgressBar1;
    private javax.swing.JSeparator jSeparator1;
    private javax.swing.JSeparator jSeparator10;
    private javax.swing.JSeparator jSeparator11;
    private javax.swing.JSeparator jSeparator12;
    private javax.swing.JSeparator jSeparator13;
    private javax.swing.JSeparator jSeparator2;
    private javax.swing.JSeparator jSeparator3;
    private javax.swing.JSeparator jSeparator4;
    private javax.swing.JSeparator jSeparator5;
    private javax.swing.JSeparator jSeparator6;
    private javax.swing.JSeparator jSeparator7;
    private javax.swing.JSeparator jSeparator8;
    private javax.swing.JSeparator jSeparator9;
    private javax.swing.JMenuItem javadocMenuItem;
    private javax.swing.JCheckBoxMenuItem logFilteredEventsCheckBoxMenuItem;
    private javax.swing.JToggleButton loggingButton;
    private javax.swing.JMenuItem loggingMenuItem;
    private javax.swing.JCheckBoxMenuItem loggingPlaybackImmediatelyCheckBoxMenuItem;
    private javax.swing.JMenuItem loggingSetTimelimitMenuItem;
    private javax.swing.JToolBar mainToolBar;
    private javax.swing.JMenuItem measureTimeMenuItem;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JMenu monSeqMenu;
    private javax.swing.JMenuItem monSeqMissedEventsMenuItem;
    private javax.swing.JMenuItem monSeqOpMode0;
    private javax.swing.JMenuItem monSeqOpMode1;
    private javax.swing.JMenuItem monSeqOpMode2;
    private javax.swing.JMenuItem monSeqOpMode3;
    private javax.swing.JMenu monSeqOperationModeMenu;
    private javax.swing.JMenuItem newViewerMenuItem;
    private javax.swing.JMenuItem openMenuItem;
    private javax.swing.JMenuItem openSocketInputStreamMenuItem;
    private javax.swing.JCheckBoxMenuItem pauseRenderingCheckBoxMenuItem;
    private javax.swing.JPanel playerControlPanel;
    private javax.swing.JSlider playerSlider;
    private javax.swing.JMenuItem refreshInterfaceMenuItem;
    private javax.swing.ButtonGroup renderModeButtonGroup;
    private javax.swing.JLabel resizeIconLabel;
    private javax.swing.JMenuItem rewindPlaybackMenuItem;
    private javax.swing.JMenuItem saveImageMenuItem;
    private javax.swing.JMenuItem saveImageSequenceMenuItem;
    private javax.swing.JButton senddown;
    private javax.swing.JButton senddownleft;
    private javax.swing.JButton senddownright;
    private javax.swing.JButton sendgaitchange;
    private javax.swing.JButton sendleft;
    private javax.swing.JButton sendright;
    private javax.swing.JButton sendroar;
    private javax.swing.JButton sendsonic;
    private javax.swing.JButton sendstop;
    private javax.swing.JButton sendup;
    private javax.swing.JButton sendupleft;
    private javax.swing.JButton sendupright;
    private javax.swing.JButton sendvision;
    private javax.swing.JMenuItem sequenceMenuItem;
    private javax.swing.JSeparator serverSeparator;
    private javax.swing.JCheckBoxMenuItem spikeServerCheckBoxMenuItem;
    private javax.swing.JButton starttest;
    private javax.swing.JLabel statisticsLabel;
    private javax.swing.JPanel statisticsPanel;
    private javax.swing.JMenuItem subSampleSizeMenuItem;
    private javax.swing.JCheckBoxMenuItem subsampleEnabledCheckBoxMenuItem;
    private javax.swing.JCheckBoxMenuItem syncEnabledCheckBoxMenuItem;
    private javax.swing.JSeparator syncSeperator;
    private javax.swing.JCheckBoxMenuItem toggleMarkCheckBoxMenuItem;
    private javax.swing.JMenuItem togglePlaybackDirectionMenuItem;
    private javax.swing.JPanel toolbarPanel;
    private javax.swing.JMenuItem unzoomMenuItem;
    private javax.swing.JCheckBoxMenuItem viewActiveRenderingEnabledMenuItem;
    private javax.swing.JMenuItem viewBiasesMenuItem;
    private javax.swing.JMenuItem viewFiltersMenuItem;
    private javax.swing.JCheckBoxMenuItem viewIgnorePolarityCheckBoxMenuItem;
    private javax.swing.JMenu viewMenu;
    private javax.swing.JCheckBoxMenuItem viewOpenGLEnabledMenuItem;
    private javax.swing.JCheckBoxMenuItem viewRenderBlankFramesCheckBoxMenuItem;
    private javax.swing.JMenuItem viewSingleStepMenuItem;
    private javax.swing.JMenuItem zeroTimestampsMenuItem;
    private javax.swing.JMenuItem zoomMenuItem;
    // End of variables declaration//GEN-END:variables
    
}
