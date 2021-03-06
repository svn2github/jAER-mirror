/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.visualize.ini.convnet;

import ch.unizh.ini.jaer.hardware.pantilt.PanTiltCalibrationPoint;
import java.awt.Color;
import java.awt.Cursor;
import java.awt.Font;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Scanner;
import java.util.TreeMap;

import javax.swing.JFileChooser;
import javax.swing.JOptionPane;

import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventio.AEInputStream;
import net.sf.jaer.eventprocessing.EventFilter2DMouseAdaptor;
import net.sf.jaer.graphics.AEViewer;
import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;

import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.awt.GLCanvas;
import com.jogamp.opengl.glu.GLU;
import com.jogamp.opengl.glu.GLUquadric;
import com.jogamp.opengl.util.awt.TextRenderer;

import eu.seebetter.ini.chips.DavisChip;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutput;
import java.io.ObjectOutputStream;
import java.util.HashMap;
import java.util.Vector;
import javax.swing.filechooser.FileFilter;
import net.sf.jaer.eventio.AEFileInputStream;

/**
 * Labels location of target using mouse GUI in recorded data for later
 * supervised learning.
 *
 * @author tobi
 */
@DevelopmentStatus(DevelopmentStatus.Status.Stable)
@Description("Labels location of target using mouse GUI in recorded data for later supervised learning.")
public class TargetLabeler extends EventFilter2DMouseAdaptor implements PropertyChangeListener, KeyListener {

    private boolean mousePressed = false;
    private boolean shiftPressed = false;
    private boolean ctlPressed = false;
    private Point mousePoint = null;
    final float labelRadius = 5f;
    private GLUquadric mouseQuad = null;
    private TreeMap<Integer, SimultaneouTargetLocations> targetLocations = new TreeMap();
    private TargetLocation targetLocation = null;
    private DavisChip apsDvsChip = null;
    private int lastFrameNumber = -1;
    private int lastTimestamp = Integer.MIN_VALUE;
    private int currentFrameNumber = -1;
    private final String LAST_FOLDER_KEY = "lastFolder";
    TextRenderer textRenderer = null;
    private int minTargetPointIntervalUs = getInt("minTargetPointIntervalUs", 10000);
    private int targetRadius = getInt("targetRadius", 10);
    private int maxTimeLastTargetLocationValidUs = getInt("maxTimeLastTargetLocationValidUs", 100000);
    private int minSampleTimestamp = Integer.MAX_VALUE, maxSampleTimestamp = Integer.MIN_VALUE;
    private final int N_FRACTIONS = 1000;
    private boolean[] labeledFractions = new boolean[N_FRACTIONS];  // to annotate graphically what has been labeled so far in event stream
    private boolean[] targetPresentInFractions = new boolean[N_FRACTIONS];  // to annotate graphically what has been labeled so far in event stream
    private boolean showLabeledFraction = getBoolean("showLabeledFraction", true);
    private boolean showHelpText = getBoolean("showHelpText", true);
//    protected int maxTargets = getInt("maxTargets", 8);
    protected int currentTargetTypeID = getInt("currentTargetTypeID", 0);
    private ArrayList<TargetLocation> currentTargets = new ArrayList(10); // currently valid targets
    protected boolean eraseSamplesEnabled = false;
    private HashMap<String, String> mapDataFilenameToTargetFilename = new HashMap();

    private boolean propertyChangeListenerAdded = false;
    private String DEFAULT_FILENAME = "locations.txt";
    private String lastFileName = getString("lastFileName", DEFAULT_FILENAME);
    protected boolean showStatistics = getBoolean("showStatistics", true);

    private String lastDataFilename = null;

    // file statistics
    private long firstInputStreamTimestamp = 0, lastInputStreamTimestamp = 0, inputStreamDuration = 0;
    private long filePositionEvents = 0, fileLengthEvents = 0;
    private int filePositionTimestamp = 0;
    private boolean warnSave = true;

    public TargetLabeler(AEChip chip) {
        super(chip);
        if (chip instanceof DavisChip) {
            apsDvsChip = ((DavisChip) chip);
        }
        setPropertyTooltip("minTargetPointIntervalUs", "minimum interval between target positions in the database in us");
        setPropertyTooltip("targetRadius", "drawn radius of target in pixels");
        setPropertyTooltip("maxTimeLastTargetLocationValidUs", "this time after last sample, the data is shown as not yet been labeled. This time specifies how long a specified target location is valid after its last specified location.");
        setPropertyTooltip("saveLocations", "saves target locations");
        setPropertyTooltip("saveLocationsAs", "show file dialog to save target locations to a new file");
        setPropertyTooltip("loadLocations", "loads locations from a file");
        setPropertyTooltip("clearLocations", "clears all existing targets");
        setPropertyTooltip("showLabeledFraction", "shows labeled part of input by a bar with red=unlabeled, green=labeled, blue=current position");
        setPropertyTooltip("showHelpText", "shows help text on screen. Uncheck to hide");
        setPropertyTooltip("showStatistics", "shows statistics");
//        setPropertyTooltip("maxTargets", "maximum number of simultaneous targets to label");
        setPropertyTooltip("currentTargetTypeID", "ID code of current target to be labeled, e.g., 0=dog, 1=cat, etc. User must keep track of the mapping from ID codes to target classes.");
        setPropertyTooltip("eraseSamplesEnabled", "Use this mode erase all samples from current time and replace with current target labeling by mouse+shift+ctl.");
        Arrays.fill(labeledFractions, false);
        Arrays.fill(targetPresentInFractions, false);
        try {
            byte[] bytes = getPrefs().getByteArray("TargetLabeler.hashmap", null);
            if (bytes != null) {
                ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bytes));
                mapDataFilenameToTargetFilename = (HashMap<String, String>) in.readObject();
                in.close();
                log.info("loaded mapDataFilenameToTargetFilename: " + mapDataFilenameToTargetFilename.size() + " entries");
            } else {
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void mouseDragged(MouseEvent e) {

        Point p = (getMousePixel(e));
        if (p != null) {
            if (mousePoint != null) {
                mousePoint.setLocation(p);
            } else {
                mousePoint = new Point(p);
            }
        } else {
            mousePoint = null;
        }
    }

    @Override
    public void mouseReleased(MouseEvent e) {
        mousePressed = false;
    }

    @Override
    public void mousePressed(MouseEvent e) {
        mouseMoved(e);
    }

    @Override
    public void mouseMoved(MouseEvent e) {

        Point p = (getMousePixel(e));
        if (p != null) {
            if (mousePoint != null) {
                mousePoint.setLocation(p);
            } else {
                mousePoint = new Point(p);
            }
        } else {
            mousePoint = null;
        }
    }

    @Override
    synchronized public void annotate(GLAutoDrawable drawable) {

        if (!isFilterEnabled()) {
            return;
        }
        if (chip.getAeViewer().getPlayMode() != AEViewer.PlayMode.PLAYBACK) {
            return;
        }
        GL2 gl = drawable.getGL().getGL2();
        chipCanvas = chip.getCanvas();
        if (chipCanvas == null) {
            return;
        }
        glCanvas = (GLCanvas) chipCanvas.getCanvas();
        if (glCanvas == null) {
            return;
        }
        if (isSelected()) {
            Point mp = glCanvas.getMousePosition();
            Point p = chipCanvas.getPixelFromPoint(mp);
            if (p == null) {
                return;
            }
            checkBlend(gl);
            float[] compArray = new float[4];
            gl.glColor3fv(targetTypeColors[currentTargetTypeID % targetTypeColors.length].getColorComponents(compArray), 0);
            gl.glLineWidth(3f);
            gl.glPushMatrix();
            gl.glTranslatef(p.x, p.y, 0);
            gl.glBegin(GL2.GL_LINES);
            gl.glVertex2f(0, -CURSOR_SIZE_CHIP_PIXELS / 2);
            gl.glVertex2f(0, +CURSOR_SIZE_CHIP_PIXELS / 2);
            gl.glVertex2f(-CURSOR_SIZE_CHIP_PIXELS / 2, 0);
            gl.glVertex2f(+CURSOR_SIZE_CHIP_PIXELS / 2, 0);
            gl.glEnd();
            gl.glTranslatef(.5f, -.5f, 0);
            gl.glBegin(GL2.GL_LINES);
            gl.glVertex2f(0, -CURSOR_SIZE_CHIP_PIXELS / 2);
            gl.glVertex2f(0, +CURSOR_SIZE_CHIP_PIXELS / 2);
            gl.glVertex2f(-CURSOR_SIZE_CHIP_PIXELS / 2, 0);
            gl.glVertex2f(+CURSOR_SIZE_CHIP_PIXELS / 2, 0);
            gl.glEnd();
//            if (quad == null) {
//                quad = glu.gluNewQuadric();
//            }
//            glu.gluQuadricDrawStyle(quad, GLU.GLU_FILL);
//            glu.gluDisk(quad, 0, 3, 32, 1);
            gl.glPopMatrix();
        }
        if (textRenderer == null) {
            textRenderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 36));
            textRenderer.setColor(1, 1, 1, 1);
        }
        MultilineAnnotationTextRenderer.setColor(Color.CYAN);
        MultilineAnnotationTextRenderer.resetToYPositionPixels(chip.getSizeY() * .9f);
        MultilineAnnotationTextRenderer.setScale(.3f);
        StringBuilder sb = new StringBuilder();
        if (showHelpText) {
            sb.append("Shift + !Ctrl + mouse position: Specify no target present\n i.e. mark data as looked at\nClt + Shift + mouse position: Specify currentTargetTypeID is present at mouse location\n");
            MultilineAnnotationTextRenderer.renderMultilineString(sb.toString());
        }
        if (showStatistics) {
            MultilineAnnotationTextRenderer.renderMultilineString(String.format("%d TargetLocation samples specified\nFirst sample time: %.1fs, Last sample time: %.1fs\nCurrent frame number: %d\nCurrent # targets: %d",
                    targetLocations.size(),
                    minSampleTimestamp * 1e-6f,
                    maxSampleTimestamp * 1e-6f,
                    currentFrameNumber,
                    currentTargets.size()));
            if (shiftPressed && !ctlPressed) {
                MultilineAnnotationTextRenderer.renderMultilineString("Specifying no target");
            } else if (shiftPressed && ctlPressed) {
                MultilineAnnotationTextRenderer.renderMultilineString("Specifying target location");
            } else {
                MultilineAnnotationTextRenderer.renderMultilineString("Playing recorded target locations");
            }
        }
        for (TargetLocation t : currentTargets) {
            if (t.location != null) {
                t.draw(drawable, gl);
            }
        }

        // show labeled parts
        if (showLabeledFraction && (inputStreamDuration > 0)) {
            float dx = chip.getSizeX() / (float) N_FRACTIONS;
            float y = chip.getSizeY() / 5;
            float dy = chip.getSizeY() / 50;
            float x = 0;
            for (int i = 0; i < N_FRACTIONS; i++) {
                boolean b = labeledFractions[i];
                if (b) {
                    gl.glColor3f(0, 1, 0);
                } else {
                    gl.glColor3f(1, 0, 0);
                }
                gl.glRectf(x - (dx / 2), y, x + (dx / 2), y + (dy * (1 + (targetPresentInFractions[i] ? 1 : 0))));
//                gl.glRectf(x-dx/2, y, x + dx/2, y + dy * (1 + (currentTargets.size())));
                x += dx;
            }
            float curPosFrac = ((float) (filePositionTimestamp - firstInputStreamTimestamp) / inputStreamDuration);
            x = curPosFrac * chip.getSizeX();
            y = y + dy;
            gl.glColor3f(1, 1, 1);
            gl.glRectf(x - (dx / 2), y - (dy * 2), x + (dx / 2), y + dy);
        }

    }

    synchronized public void doClearLocations() {
        targetLocations.clear();
        minSampleTimestamp = Integer.MAX_VALUE;
        maxSampleTimestamp = Integer.MIN_VALUE;
        Arrays.fill(labeledFractions, false);
        Arrays.fill(targetPresentInFractions, false);
        currentTargets.clear();
    }

    synchronized public void doSaveLocationsAs() {
        String fn = mapDataFilenameToTargetFilename.getOrDefault(lastDataFilename, DEFAULT_FILENAME);
        JFileChooser c = new JFileChooser(fn);
        c.setSelectedFile(new File(fn));
        int ret = c.showSaveDialog(glCanvas);
        if (ret != JFileChooser.APPROVE_OPTION) {
            return;
        }
        lastFileName = c.getSelectedFile().toString();
        // end filename with -targets.txt
        File f = c.getSelectedFile();
        String s = f.getPath();
        if (!s.endsWith("-targets.txt")) {
            int idxdot = s.lastIndexOf('.');
            if (idxdot > 0) {
                s = s.substring(0, idxdot);
            }
            s = s + "-targets.txt";
            f = new File(s);
        }
        if (f.exists()) {
            int r = JOptionPane.showConfirmDialog(glCanvas, "File " + f.toString() + " already exists, overwrite it?");
            if (r != JOptionPane.OK_OPTION) {
                return;
            }
        }
        saveLocations(f);
        warnSave = false;
    }

    synchronized public void doSaveLocations() {
        if (warnSave) {
            int ret = JOptionPane.showConfirmDialog(chip.getAeViewer().getFilterFrame(), "Really overwrite " + lastFileName + " ?", "Overwrite warning", JOptionPane.WARNING_MESSAGE);
            if (ret != JOptionPane.YES_OPTION) {
                log.info("save canceled");
                return;
            }
        }
        File f = new File(lastFileName);
        saveLocations(new File(lastFileName));
    }

    synchronized public void doLoadLocations() {
        lastFileName = mapDataFilenameToTargetFilename.getOrDefault(lastDataFilename, DEFAULT_FILENAME);
        if (lastFileName != null && lastFileName.equals(DEFAULT_FILENAME)) {
            File f = chip.getAeViewer().getRecentFiles().getMostRecentFile();
            if (f == null) {
                lastFileName = DEFAULT_FILENAME;
            } else {
                lastFileName = f.getPath();
            }
        }
        JFileChooser c = new JFileChooser(lastFileName);
        c.setFileFilter(new FileFilter() {

            @Override
            public boolean accept(File f) {
                return f.isDirectory() || f.getName().toLowerCase().endsWith(".txt");
            }

            @Override
            public String getDescription() {
                return "Text target label files";
            }
        });
        c.setMultiSelectionEnabled(false);
        c.setSelectedFile(new File(lastFileName));
        int ret = c.showOpenDialog(glCanvas);
        if (ret != JFileChooser.APPROVE_OPTION) {
            return;
        }
        lastFileName = c.getSelectedFile().toString();
        putString("lastFileName", lastFileName);
        loadLocations(new File(lastFileName));
    }

    private TargetLocation lastNewTargetLocation = null;

    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        if (chip.getAeViewer().getPlayMode() != AEViewer.PlayMode.PLAYBACK) {
            return in;
        }
        if (!propertyChangeListenerAdded) {
            if (chip.getAeViewer() != null) {
                chip.getAeViewer().addPropertyChangeListener(this);
                propertyChangeListenerAdded = true;
            }
        }

//        currentTargets.clear();
        for (BasicEvent e : in) {
            if (e.isSpecial()) {
                continue;
            }
            if (apsDvsChip != null) {

                // update actual frame number, starting from 0 at start of recording (for playback or after rewind)
                // this can be messed up by jumping in the file using slider
                int newFrameNumber = apsDvsChip.getFrameCount();
                if (newFrameNumber != lastFrameNumber) {
                    if (newFrameNumber > lastFrameNumber) {
                        currentFrameNumber++;
                    } else if (newFrameNumber < lastFrameNumber) {
                        currentFrameNumber--;
                    }
                    lastFrameNumber = newFrameNumber;
                }

                if (((long) e.timestamp - (long) lastTimestamp) >= minTargetPointIntervalUs) {

                    // show the nearest TargetLocation if at least minTargetPointIntervalUs has passed by,
                    // or "No target" if the location was previously
                    Map.Entry<Integer, SimultaneouTargetLocations> mostRecentTargetsBeforeThisEvent = targetLocations.lowerEntry(e.timestamp);
                    if (mostRecentTargetsBeforeThisEvent != null) {
                        for (TargetLocation t : mostRecentTargetsBeforeThisEvent.getValue()) {
                            if ((t == null) || ((t != null) && ((e.timestamp - t.timestamp) > maxTimeLastTargetLocationValidUs))) {
                                targetLocation = null;
                            } else {
                                if (targetLocation != t) {
                                    targetLocation = t;
                                    currentTargets.add(targetLocation);
                                    markDataHasTarget(targetLocation.timestamp);
                                }
                            }
                        }
                    }

                    lastTimestamp = e.timestamp;
                    // find next saved target location that is just before this time (lowerEntry)
                    TargetLocation newTargetLocation = null;
                    if (shiftPressed && ctlPressed && (mousePoint != null)) { // specify (additional) target present
                        // add a labeled location sample
                        maybeEraseSamples(mostRecentTargetsBeforeThisEvent, e, lastNewTargetLocation);
                        newTargetLocation = new TargetLocation(currentFrameNumber, e.timestamp, mousePoint, currentTargetTypeID);

                        addSample(e.timestamp, newTargetLocation);
                        currentTargets.add(newTargetLocation);

                    } else if (shiftPressed && !ctlPressed) { // specify no target present now but mark recording as reviewed
                        markDataReviewedButNoTargetPresent(e.timestamp);
                    }
                    if (newTargetLocation != null) {
                        if (newTargetLocation.timestamp > maxSampleTimestamp) {
                            maxSampleTimestamp = newTargetLocation.timestamp;
                        }
                        if (newTargetLocation.timestamp < minSampleTimestamp) {
                            minSampleTimestamp = newTargetLocation.timestamp;
                        }
                    }
                    lastNewTargetLocation = newTargetLocation;
                }
                if (e.timestamp < lastTimestamp) {
                    lastTimestamp = e.timestamp;
                }

            }
        }

        //prune list of current targets to their valid lifetime, and remove leftover targets in the future
        ArrayList<TargetLocation> removeList = new ArrayList();
        for (TargetLocation t : currentTargets) {
            if (((t.timestamp + maxTimeLastTargetLocationValidUs) < in.getLastTimestamp()) || (t.timestamp > in.getLastTimestamp())) {
                removeList.add(t);
            }
        }
        currentTargets.removeAll(removeList);
        return in;
    }

    private void maybeEraseSamples(Map.Entry<Integer, SimultaneouTargetLocations> entry, BasicEvent e, TargetLocation lastSampleAdded) {
        if (!eraseSamplesEnabled || (entry == null)) {
            return;
        }
        boolean removed = false;
        for (TargetLocation t : entry.getValue()) { // ArrayList of TargetLocation
            if ((t != null) && (t != lastSampleAdded) && ((e.timestamp - entry.getKey()) < minTargetPointIntervalUs)) {
                log.info("removing previous " + entry.getValue() + " because entry.getValue()!=lastSampleAdded=" + (t != lastSampleAdded) + " && timestamp difference " + (e.timestamp - entry.getKey()) + " is < " + minTargetPointIntervalUs);
                targetLocations.remove(entry.getKey());
                removed = true;
            }
        }
        if (removed) {
            entry = null;
        }
    }

    @Override
    public void setSelected(boolean yes) {
        super.setSelected(yes); // register/deregister mouse listeners
        if (yes) {
            glCanvas.addKeyListener(this);
        } else {
            glCanvas.removeKeyListener(this);
        }
    }

    @Override
    public void resetFilter() {
    }

    @Override
    public void initFilter() {
    }

    /**
     * @return the minTargetPointIntervalUs
     */
    public int getMinTargetPointIntervalUs() {
        return minTargetPointIntervalUs;
    }

    /**
     * @param minTargetPointIntervalUs the minTargetPointIntervalUs to set
     */
    public void setMinTargetPointIntervalUs(int minTargetPointIntervalUs) {
        this.minTargetPointIntervalUs = minTargetPointIntervalUs;
        putInt("minTargetPointIntervalUs", minTargetPointIntervalUs);
    }

    @Override
    public void keyTyped(KeyEvent ke) {
    }

    @Override
    public void keyPressed(KeyEvent ke) {
        int k = ke.getKeyCode();
        if (k == KeyEvent.VK_SHIFT) {
            shiftPressed = true;
        } else if (k == KeyEvent.VK_CONTROL) {
            ctlPressed = true;
        }
    }

    @Override
    public void keyReleased(KeyEvent ke) {
        int k = ke.getKeyCode();
        if (k == KeyEvent.VK_SHIFT) {
            shiftPressed = false;
        } else if (k == KeyEvent.VK_CONTROL) {
            ctlPressed = false;
        }
    }

    /**
     * @return the targetRadius
     */
    public int getTargetRadius() {
        return targetRadius;
    }

    /**
     * @param targetRadius the targetRadius to set
     */
    public void setTargetRadius(int targetRadius) {
        this.targetRadius = targetRadius;
        putInt("targetRadius", targetRadius);
    }

    /**
     * @return the maxTimeLastTargetLocationValidUs
     */
    public int getMaxTimeLastTargetLocationValidUs() {
        return maxTimeLastTargetLocationValidUs;
    }

    /**
     * @param maxTimeLastTargetLocationValidUs the
     * maxTimeLastTargetLocationValidUs to set
     */
    public void setMaxTimeLastTargetLocationValidUs(int maxTimeLastTargetLocationValidUs) {
        if (maxTimeLastTargetLocationValidUs < minTargetPointIntervalUs) {
            maxTimeLastTargetLocationValidUs = minTargetPointIntervalUs;
        }
        this.maxTimeLastTargetLocationValidUs = maxTimeLastTargetLocationValidUs;
        putInt("maxTimeLastTargetLocationValidUs", maxTimeLastTargetLocationValidUs);

    }

    /**
     * Returns true if locations are specified already
     *
     * @return true if there are locations specified
     */
    public boolean hasLocations() {
        return !targetLocations.isEmpty();
    }

    /**
     * @return the targetLocation
     */
    public TargetLocation getTargetLocation() {
        return targetLocation;
    }

    private void addSample(int timestamp, TargetLocation newTargetLocation) {
        SimultaneouTargetLocations s = targetLocations.get(timestamp);
        if (s == null) {
            s = new SimultaneouTargetLocations();
            targetLocations.put(timestamp, s);
        }
        s.add(newTargetLocation);
    }

    private int getFractionOfFileDuration(int timestamp) {
        if (inputStreamDuration == 0) {
            return 0;
        }
        return (int) Math.floor((N_FRACTIONS * ((float) (timestamp - firstInputStreamTimestamp))) / inputStreamDuration);
    }

    private class TargetLocationComparator implements Comparator<TargetLocation> {

        @Override
        public int compare(TargetLocation o1, TargetLocation o2) {
            return Integer.valueOf(o1.frameNumber).compareTo(Integer.valueOf(o2.frameNumber));
        }

    }

    private final Color[] targetTypeColors = {Color.BLUE, Color.CYAN, Color.GREEN, Color.MAGENTA, Color.ORANGE, Color.PINK, Color.RED};

    /**
     * List of targets simultaneously present at a particular timestamp
     */
    private class SimultaneouTargetLocations extends ArrayList<TargetLocation> {

    }

    class TargetLocation {

        int timestamp;
        int frameNumber;
        Point location;
        int targetClassID; // class of target, i.e. car, person

        public TargetLocation(int frameNumber, int timestamp, Point location, int targetTypeID) {
            this.frameNumber = frameNumber;
            this.timestamp = timestamp;
            this.location = location != null ? new Point(location) : null;
            this.targetClassID = targetTypeID;
        }

        private void draw(GLAutoDrawable drawable, GL2 gl) {

//            if (getTargetLocation() != null && getTargetLocation().location == null) {
//                textRenderer.beginRendering(drawable.getSurfaceWidth(), drawable.getSurfaceHeight());
//                textRenderer.draw("Target not visible", chip.getSizeX() / 2, chip.getSizeY() / 2);
//                textRenderer.endRendering();
//                return;
//            }
            gl.glPushMatrix();
            gl.glTranslatef(location.x, location.y, 0f);
            float[] compArray = new float[4];
            gl.glColor3fv(targetTypeColors[targetClassID % targetTypeColors.length].getColorComponents(compArray), 0);
//            gl.glColor4f(0, 1, 0, .5f);
            if (mouseQuad == null) {
                mouseQuad = glu.gluNewQuadric();
            }
            glu.gluQuadricDrawStyle(mouseQuad, GLU.GLU_LINE);
            glu.gluDisk(mouseQuad, getTargetRadius(), getTargetRadius() + 1, 32, 1);
            gl.glPopMatrix();
        }

        @Override
        public String toString() {
            return String.format("TargetLocation frameNumber=%d timestamp=%d location=%s", frameNumber, timestamp, location == null ? "null" : location.toString());
        }

    }

    private void saveLocations(File f) {
        try {
            FileWriter writer = new FileWriter(f);
            writer.write(String.format("# target locations\n"));
            writer.write(String.format("# written %s\n", new Date().toString()));
//            writer.write("# maxTargets=" + maxTargets+"\n");
            writer.write(String.format("# frameNumber timestamp x y targetTypeID\n"));
            for (Map.Entry<Integer, SimultaneouTargetLocations> entry : targetLocations.entrySet()) {
                for (TargetLocation l : entry.getValue()) {
                    if (l.location != null) {
                        writer.write(String.format("%d %d %d %d %d\n", l.frameNumber, l.timestamp, l.location.x, l.location.y, l.targetClassID));
                    } else {
                        writer.write(String.format("%d %d -1 -1 -1\n", l.frameNumber, l.timestamp));
                    }
                }
            }
            writer.close();
            log.info("wrote locations to file " + f.getAbsolutePath());
            lastFileName = f.toString();
            putString("lastFileName", lastFileName);
            if (lastDataFilename != null) {
                mapDataFilenameToTargetFilename.put(lastDataFilename, lastFileName);
            }
            try {
                // Serialize to a byte array
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                ObjectOutput oos = new ObjectOutputStream(bos);
                oos.writeObject(mapDataFilenameToTargetFilename);
                oos.close();
                // Get the bytes of the serialized object
                byte[] buf = bos.toByteArray();
                getPrefs().putByteArray("TargetLabeler.hashmap", buf);
            } catch (Exception e) {
                e.printStackTrace();
            }
        } catch (IOException ex) {
            JOptionPane.showMessageDialog(glCanvas, ex.toString(), "Couldn't save locations", JOptionPane.WARNING_MESSAGE, null);
            return;
        }
    }

    /**
     * Loads last locations. Note that this is a lengthy operation
     */
    synchronized public void loadLastLocations() {
        if (lastFileName == null) {
            return;
        }
        File f = new File(lastFileName);
        if (!f.exists() || !f.isFile()) {
            return;
        }
        loadLocations(f);
    }

    synchronized private void loadLocations(File f) {
        log.info("loading " + f);
        try {
            setCursor(new Cursor(Cursor.WAIT_CURSOR));
            targetLocations.clear();
            minSampleTimestamp = Integer.MAX_VALUE;
            maxSampleTimestamp = Integer.MIN_VALUE;
            try {
                BufferedReader reader = new BufferedReader(new FileReader(f));
                String s = reader.readLine();
                StringBuilder sb = new StringBuilder();
                while ((s != null) && s.startsWith("#")) {
                    sb.append(s + "\n");
                    s = reader.readLine();
                }
                log.info("header lines on " + f.getAbsolutePath() + " are\n" + sb.toString());
                while (s != null) {
                    Scanner scanner = new Scanner(s);
                    try {
                        int frame = scanner.nextInt();
                        int ts = scanner.nextInt();
                        int x = scanner.nextInt();
                        int y = scanner.nextInt();
                        int targetTypeID = 0;
                        try {
                            targetTypeID = scanner.nextInt();
                        } catch (NoSuchElementException e) {
                            // older type file with only single target and no targetClassID
                        }
                        targetLocation = new TargetLocation(frame, ts,
                                new Point(x, y),
                                targetTypeID); // read target location
                    } catch (NoSuchElementException ex2) {
                        throw new IOException(("couldn't parse file " + f) == null ? "null" : f.toString() + ", got InputMismatchException on line: " + s);
                    }
                    if ((targetLocation.location.x == -1) && (targetLocation.location.y == -1)) {
                        targetLocation.location = null;
                    }
                    addSample(targetLocation.timestamp, targetLocation);
                    markDataHasTarget(targetLocation.timestamp);
                    if (targetLocation != null) {
                        if (targetLocation.timestamp > maxSampleTimestamp) {
                            maxSampleTimestamp = targetLocation.timestamp;
                        }
                        if (targetLocation.timestamp < minSampleTimestamp) {
                            minSampleTimestamp = targetLocation.timestamp;
                        }
                    }
                    s = reader.readLine();
                }
                log.info("done loading " + f);
                if (lastDataFilename != null) {
                    mapDataFilenameToTargetFilename.put(lastDataFilename, f.getPath());
                }
            } catch (FileNotFoundException ex) {
                JOptionPane.showMessageDialog(glCanvas, ("couldn't find file " + f) == null ? "null" : f.toString() + ": got exception " + ex.toString(), "Couldn't load locations", JOptionPane.WARNING_MESSAGE, null);
            } catch (IOException ex) {
                JOptionPane.showMessageDialog(glCanvas, ("IOException with file " + f) == null ? "null" : f.toString() + ": got exception " + ex.toString(), "Couldn't load locations", JOptionPane.WARNING_MESSAGE, null);
            }
        } finally {
            setCursor(Cursor.getDefaultCursor());
        }
    }

    /**
     * marks this point in time as reviewed already
     *
     * @param timestamp
     */
    private void markDataReviewedButNoTargetPresent(int timestamp) {
        if (inputStreamDuration == 0) {
            return;
        }
        int frac = getFractionOfFileDuration(timestamp);
        labeledFractions[frac] = true;
        targetPresentInFractions[frac] = false;
    }

    private void markDataHasTarget(int timestamp) {
        if (inputStreamDuration == 0) {
            return;
        }
        int frac = getFractionOfFileDuration(timestamp);
        if (frac < 0 || frac >= labeledFractions.length) {
            log.warning("fraction " + frac + " is out of range " + labeledFractions.length + ", something is wrong");
            return;
        }
        labeledFractions[frac] = true;
        targetPresentInFractions[frac] = true;
    }

    private void fixLabeledFraction() {
        if (chip.getAeInputStream() != null) {
            firstInputStreamTimestamp = chip.getAeInputStream().getFirstTimestamp();
            lastTimestamp = chip.getAeInputStream().getLastTimestamp();
            inputStreamDuration = chip.getAeInputStream().getDurationUs();
            fileLengthEvents = chip.getAeInputStream().size();
            if (inputStreamDuration > 0) {
                if ((targetLocations == null) || targetLocations.isEmpty()) {
                    Arrays.fill(labeledFractions, false);
                    return;
                }
                for (int t : targetLocations.keySet()) {
                    markDataHasTarget(t);
                }
            }
        }
    }

    /**
     * @return the showLabeledFraction
     */
    public boolean isShowLabeledFraction() {
        return showLabeledFraction;
    }

    /**
     * @param showLabeledFraction the showLabeledFraction to set
     */
    public void setShowLabeledFraction(boolean showLabeledFraction) {
        this.showLabeledFraction = showLabeledFraction;
        putBoolean("showLabeledFraction", showLabeledFraction);
    }

    /**
     * @return the showHelpText
     */
    public boolean isShowHelpText() {
        return showHelpText;
    }

    /**
     * @param showHelpText the showHelpText to set
     */
    public void setShowHelpText(boolean showHelpText) {
        this.showHelpText = showHelpText;
        putBoolean("showHelpText", showHelpText);
    }

    @Override
    public synchronized void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes); //To change body of generated methods, choose Tools | Templates.
        fixLabeledFraction();
    }

//    /**
//     * @return the maxTargets
//     */
//    public int getMaxTargets() {
//        return maxTargets;
//    }
//
//    /**
//     * @param maxTargets the maxTargets to set
//     */
//    public void setMaxTargets(int maxTargets) {
//        this.maxTargets = maxTargets;
//    }
    /**
     * @return the currentTargetTypeID
     */
    public int getCurrentTargetTypeID() {
        return currentTargetTypeID;
    }

    /**
     * @param currentTargetTypeID the currentTargetTypeID to set
     */
    public void setCurrentTargetTypeID(int currentTargetTypeID) {
//        if (currentTargetTypeID >= maxTargets) {
//            currentTargetTypeID = maxTargets;
//        }
        this.currentTargetTypeID = currentTargetTypeID;
        putInt("currentTargetTypeID", currentTargetTypeID);
    }

    /**
     * @return the eraseSamplesEnabled
     */
    public boolean isEraseSamplesEnabled() {
        return eraseSamplesEnabled;
    }

    /**
     * @param relabelSingleTargetEnabled the eraseSamplesEnabled to set
     */
    public void setEraseSamplesEnabled(boolean relabelSingleTargetEnabled) {
        this.eraseSamplesEnabled = relabelSingleTargetEnabled;
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        switch (evt.getPropertyName()) {
            case AEInputStream.EVENT_POSITION:
                filePositionEvents = (long) evt.getNewValue();
                filePositionTimestamp = chip.getAeInputStream().getMostRecentTimestamp();
                break;
            case AEInputStream.EVENT_REWIND:
            case AEInputStream.EVENT_REPOSITIONED:
                log.info("rewind to start or mark position or reposition event " + evt.toString());
                if (evt.getNewValue() instanceof Long) {
                    long position = (long) evt.getNewValue();
                    if (chip.getAeInputStream() == null) {
                        log.warning("AE input stream is null, cannot determine timestamp after rewind");
                        return;
                    }
                    int timestamp = chip.getAeInputStream().getMostRecentTimestamp();
                    Map.Entry<Integer, SimultaneouTargetLocations> targetsBeforeRewind = targetLocations.lowerEntry(timestamp);
                    if (targetsBeforeRewind != null) {
                        currentFrameNumber = targetsBeforeRewind.getValue().get(0).frameNumber;
                        lastFrameNumber = currentFrameNumber - 1;
                        lastTimestamp = targetsBeforeRewind.getValue().get(0).timestamp;
                    } else {
                        currentFrameNumber = 0;
                        lastFrameNumber = currentFrameNumber - 1;
                        lastInputStreamTimestamp = Integer.MIN_VALUE;
                    }
                } else {
                    log.warning("couldn't determine stream position after rewind from PropertyChangeEvent " + evt.toString());
                }
                break;
            case AEInputStream.EVENT_INIT:
                fixLabeledFraction();
                warnSave = true;
                if (evt.getNewValue() instanceof AEFileInputStream) {
                    File f = ((AEFileInputStream) evt.getNewValue()).getFile();
                    lastDataFilename = f.getPath();
                }
                break;
        }
    }

    /**
     * @return the showStatistics
     */
    public boolean isShowStatistics() {
        return showStatistics;
    }

    /**
     * @param showStatistics the showStatistics to set
     */
    public void setShowStatistics(boolean showStatistics) {
        this.showStatistics = showStatistics;
        putBoolean("showStatistics", showStatistics);
    }

}
