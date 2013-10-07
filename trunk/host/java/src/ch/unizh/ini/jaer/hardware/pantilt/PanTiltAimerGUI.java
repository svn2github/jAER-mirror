/*
 * PanTiltGUI.java
 *
 * Created on April 21, 2008, 11:50 AM
 */
package ch.unizh.ini.jaer.hardware.pantilt;

import ch.unizh.ini.jaer.hardware.pantilt.PanTiltAimer.Message;
import java.awt.Toolkit;
import java.util.ArrayList;
import java.util.logging.Level;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import net.sf.jaer.util.ExceptionListener;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Point;
import java.awt.event.*;
import java.awt.geom.*;
import java.beans.*;
import java.util.logging.Logger;

/**
 * Tests pantilt by mimicing mouse movements. Also can serve as calibration
 * source via PropertyChangeSupport.
 *
 * @author tobi
 */
public class PanTiltAimerGUI extends javax.swing.JFrame implements ExceptionListener {

    private PropertyChangeSupport support = new PropertyChangeSupport(this);
    Logger log = Logger.getLogger("PanTiltGUI");
    private PanTilt panTilt;
    private int w = 200, h = 200, x0 = 0, y0 = 0;
    private Point2D.Float lastPanTilt = new Point2D.Float(0.5f, 0.5f);
    private Point lastMousePressLocation = new Point(w / 2, h / 2);
    private boolean recordingEnabled = false;
    private Trajectory trajectory = new Trajectory();
    private float panLimit = 0.5f;
    private float tiltLimit = 0.5f;

    class Trajectory extends ArrayList<TrajectoryPoint> {

        long lastTime;
        TrajectoryPlayer player = null;

        void add(float pan, float tilt, int x, int y) {
            if (isEmpty()) {
                start();
            }
            long now = System.currentTimeMillis();
            add(new TrajectoryPoint(now - lastTime, pan, tilt, x, y));
            lastTime = now;
        }

        void start() {
            lastTime = System.currentTimeMillis();
        }

        @Override
        public void clear() {
            if (player != null) {
                player.cancel();
            }
            super.clear();
        }

        private void setPlaybackEnabled(boolean selected) {
            if (selected) {
                if (player != null) {
                    player.cancel();
                }
                player = new TrajectoryPlayer();
                player.start();
            } else {
                if (player != null) {
                    player.cancel();
                }
            }
        }

        private void paint() {
            if (isEmpty()) {
                return;
            }
            int n = size();
            int[] x = new int[n], y = new int[n];
            for (int i = 0; i < n; i++) {
                x[i] = get(i).x;
                y[i] = get(i).y;
            }
            calibrationPanel.getGraphics().drawPolyline(x, y, n);
        }

        class TrajectoryPlayer extends Thread {

            boolean cancelMe = false;

            void cancel() {
                cancelMe = true;
                synchronized (this) {
                    interrupt();
                }
            }

            @Override
            public void run() {
                boolean jittering = panTilt.isJitterEnabled();
                panTilt.setJitterEnabled(false);
                while (!cancelMe) {
                    for (TrajectoryPoint p : Trajectory.this) {
                        if (cancelMe) {
                            break;
                        }
                        setPanTilt(p.pan, p.tilt);
                        try {
                            Thread.sleep(p.timeMillis);
                        } catch (InterruptedException ex) {
                            break;
                        }
                    }
                }
                panTilt.setJitterEnabled(jittering);
            }
        }
    }

    class TrajectoryPoint {

        long timeMillis;
        float pan, tilt;
        int x, y;

        public TrajectoryPoint(long timeMillis, float pan, float tilt, int x, int y) {
            this.timeMillis = timeMillis;
            this.pan = pan;
            this.tilt = tilt;
            this.x = x;
            this.y = y;
        }
    }

    /**
     * Make the GUI.
     *
     * @param pt the pan tilt unit
     */
    public PanTiltAimerGUI(PanTilt pt) {
        panTilt = pt;
        initComponents();
        calibrationPanel.setPreferredSize(new Dimension(w, h));
//        HardwareInterfaceException.addExceptionListener(this);
        calibrationPanel.requestFocusInWindow();
        pack();
    }

    @Override
    public void paint(Graphics g) {
        final int r = 6;
        super.paint(g);
        float[] ptvals = panTilt.getPanTiltValues();
        float p = ptvals[0], t = ptvals[1];

        trajectory.paint();
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jButton1 = new javax.swing.JButton();
        statusLabel = new javax.swing.JLabel();
        calibrationPanel = new javax.swing.JPanel();
        jLabel5 = new javax.swing.JLabel();
        recordCB = new javax.swing.JCheckBox();
        clearBut = new javax.swing.JButton();
        loopTB = new javax.swing.JToggleButton();
        centerBut = new javax.swing.JButton();
        relaxBut = new javax.swing.JButton();
        execFlatTrajector = new javax.swing.JButton();

        jButton1.setText("jButton1");

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setTitle("PanTiltAimer");
        setCursor(new java.awt.Cursor(java.awt.Cursor.CROSSHAIR_CURSOR));
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosed(java.awt.event.WindowEvent evt) {
                formWindowClosed(evt);
            }
        });

        statusLabel.setText("exception status");
        statusLabel.setBorder(javax.swing.BorderFactory.createLineBorder(new java.awt.Color(0, 0, 0)));

        calibrationPanel.setBackground(new java.awt.Color(255, 255, 255));
        calibrationPanel.setBorder(javax.swing.BorderFactory.createEtchedBorder());
        calibrationPanel.setToolTipText("Drag or click mouse to aim pan-tilt");
        calibrationPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                calibrationPanelMouseEntered(evt);
            }
            public void mouseExited(java.awt.event.MouseEvent evt) {
                calibrationPanelMouseExited(evt);
            }
            public void mousePressed(java.awt.event.MouseEvent evt) {
                calibrationPanelMousePressed(evt);
            }
            public void mouseReleased(java.awt.event.MouseEvent evt) {
                calibrationPanelMouseReleased(evt);
            }
        });
        calibrationPanel.addComponentListener(new java.awt.event.ComponentAdapter() {
            public void componentResized(java.awt.event.ComponentEvent evt) {
                calibrationPanelComponentResized(evt);
            }
        });
        calibrationPanel.addMouseMotionListener(new java.awt.event.MouseMotionAdapter() {
            public void mouseDragged(java.awt.event.MouseEvent evt) {
                calibrationPanelMouseDragged(evt);
            }
        });
        calibrationPanel.addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyPressed(java.awt.event.KeyEvent evt) {
                calibrationPanelKeyPressed(evt);
            }
        });

        javax.swing.GroupLayout calibrationPanelLayout = new javax.swing.GroupLayout(calibrationPanel);
        calibrationPanel.setLayout(calibrationPanelLayout);
        calibrationPanelLayout.setHorizontalGroup(
            calibrationPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );
        calibrationPanelLayout.setVerticalGroup(
            calibrationPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 307, Short.MAX_VALUE)
        );

        jLabel5.setText("<html>Drag or click  mouse to aim pan tilt. Use <b>r</b> to toggle recording a trajectory.</html>");

        recordCB.setText("Record trajectory");
        recordCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                recordCBActionPerformed(evt);
            }
        });

        clearBut.setText("Clear trajectory");
        clearBut.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                clearButActionPerformed(evt);
            }
        });

        loopTB.setText("Loop trajectory");
        loopTB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                loopTBActionPerformed(evt);
            }
        });

        centerBut.setText("Center");
        centerBut.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                centerButActionPerformed(evt);
            }
        });

        relaxBut.setText("Relax");
        relaxBut.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                relaxButActionPerformed(evt);
            }
        });
        
        execFlatTrajector.setText("Execute Flat Trajectory");
        execFlatTrajector.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	execFlatTrajectorActionPerformed(evt);
            }
        });


        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addGroup(layout.createSequentialGroup()
                        .addContainerGap()
                        .addComponent(calibrationPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                    .addGroup(javax.swing.GroupLayout.Alignment.LEADING, layout.createSequentialGroup()
                        .addGap(1, 1, 1)
                        .addComponent(statusLabel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                    .addGroup(javax.swing.GroupLayout.Alignment.LEADING, layout.createSequentialGroup()
                        .addContainerGap()
                        .addComponent(jLabel5, javax.swing.GroupLayout.PREFERRED_SIZE, 141, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addGroup(layout.createSequentialGroup()
                                .addComponent(recordCB)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                                .addComponent(clearBut)
                                .addGap(0, 0, Short.MAX_VALUE))
                            .addGroup(layout.createSequentialGroup()
                                .addComponent(loopTB)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                                .addComponent(centerBut)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                                .addComponent(execFlatTrajector)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                                .addComponent(relaxBut)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)))))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(recordCB)
                            .addComponent(clearBut))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(loopTB)
                            .addComponent(relaxBut)
                            .addComponent(centerBut)
                            .addComponent(execFlatTrajector))
                        .addGap(0, 3, Short.MAX_VALUE))
                    .addComponent(jLabel5))
                .addGap(18, 18, 18)
                .addComponent(calibrationPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(statusLabel)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private float getPan(MouseEvent evt) {
        int x = evt.getX();
        float pan = (float) x / w;
//        log.info("computed pan="+pan);
        return pan;

    }

    private float getTilt(MouseEvent evt) {
        int y = evt.getY();
        float tilt = 1 - (float) (h - y) / h;
//        log.info("computed tilt="+tilt);
        return tilt;
    }

    private void setPanTilt(float pan, float tilt) {
        try {
            pan = clipPan(pan);
            tilt = clipTilt(tilt);
            lastPanTilt.x = pan;
            lastPanTilt.y = tilt;
            panTilt.setPanTiltValues(pan, tilt);
            support.firePropertyChange(Message.PanTiltSet.name(), null, new Point2D.Float(pan, tilt));
            statusLabel.setText(String.format("%.3f, %.3f", pan, tilt));
        } catch (HardwareInterfaceException e) {
            log.warning(e.toString());
        }
    }

    private float clipPan(float pan) {
        if (pan > 0.5f + panLimit) {
            pan = 0.5f + panLimit;
        } else if (pan < .5f - panLimit) {
            pan = .5f - panLimit;
        }
        return pan;
    }

    private float clipTilt(float tilt) {
        if (tilt > 0.5f + tiltLimit) {
            tilt = 0.5f + tiltLimit;
        } else if (tilt < .5f - tiltLimit) {
            tilt = .5f - tiltLimit;
        }
        return tilt;
    }

    public Point getMouseFromPanTilt(Point2D.Float pt) {
        return new Point((int) (calibrationPanel.getWidth() * pt.x), (int) (calibrationPanel.getHeight() * pt.y));
    }

    public Point2D.Float getPanTiltFromMouse(Point mouse) {
        return new Point2D.Float((float) mouse.x / calibrationPanel.getWidth(), (float) mouse.y / calibrationPanel.getHeight());
    }

    private void calibrationPanelComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_calibrationPanelComponentResized
        w = calibrationPanel.getWidth();
        h = calibrationPanel.getHeight();
    }//GEN-LAST:event_calibrationPanelComponentResized

    private void calibrationPanelMouseDragged(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseDragged
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        setPanTilt(pan, tilt);
        if (isRecordingEnabled()) {
            trajectory.add(pan, tilt, evt.getX(), evt.getY());
            repaint();
        }
    }//GEN-LAST:event_calibrationPanelMouseDragged

    private void calibrationPanelMousePressed(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMousePressed
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        lastMousePressLocation = evt.getPoint();
        setPanTilt(pan, tilt);
        if (panTilt.isJitterEnabled()) {
            panTilt.stopJitter();
        }
    }//GEN-LAST:event_calibrationPanelMousePressed

    private void calibrationPanelKeyPressed(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_calibrationPanelKeyPressed
        switch (evt.getKeyCode()) {
            case KeyEvent.VK_R:
                // send a message with pantilt and mouse filled in, tracker will fill in retina if there is a tracked locaton
                setRecordingEnabled(!isRecordingEnabled());
                repaint();
                break;
            case KeyEvent.VK_ESCAPE:
                support.firePropertyChange(Message.AbortRecording.name(), null, null);
                trajectory.clear();
                setRecordingEnabled(false);
                break;
            default:
                Toolkit.getDefaultToolkit().beep();
        }
    }//GEN-LAST:event_calibrationPanelKeyPressed

    private void calibrationPanelMouseReleased(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseReleased
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        lastMousePressLocation = evt.getPoint();
        setPanTilt(pan, tilt);
        if (panTilt.isJitterEnabled()) {
            panTilt.startJitter();
        }
    }//GEN-LAST:event_calibrationPanelMouseReleased

    private void formWindowClosed(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosed
        panTilt.stopJitter();
    }//GEN-LAST:event_formWindowClosed

    private void calibrationPanelMouseEntered(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseEntered
        setCursor(new java.awt.Cursor(java.awt.Cursor.CROSSHAIR_CURSOR));
        calibrationPanel.requestFocus();
    }//GEN-LAST:event_calibrationPanelMouseEntered

    private void calibrationPanelMouseExited(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseExited
        setCursor(new java.awt.Cursor(java.awt.Cursor.DEFAULT_CURSOR));
    }//GEN-LAST:event_calibrationPanelMouseExited

    private void clearButActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_clearButActionPerformed
        support.firePropertyChange(Message.ClearRecording.name(), null, null);
        trajectory.clear();
        repaint();
    }//GEN-LAST:event_clearButActionPerformed

    private void recordCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_recordCBActionPerformed
        setRecordingEnabled(recordCB.isSelected());
    }//GEN-LAST:event_recordCBActionPerformed

    private void loopTBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_loopTBActionPerformed
        trajectory.setPlaybackEnabled(loopTB.isSelected());

    }//GEN-LAST:event_loopTBActionPerformed

    private void centerButActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_centerButActionPerformed
        boolean jittering=panTilt.isJitterEnabled();
        panTilt.setJitterEnabled(false);
        setPanTilt(.5f, .5f);
        panTilt.setJitterEnabled(jittering);
    }//GEN-LAST:event_centerButActionPerformed

    private void relaxButActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_relaxButActionPerformed
        if (panTilt != null && panTilt.getServoInterface() != null) {
            try {
                panTilt.stopJitter();
                panTilt.getServoInterface().disableAllServos();
            } catch (HardwareInterfaceException ex) {
                log.warning(ex.toString());
            }
        }
    }//GEN-LAST:event_relaxButActionPerformed
    
    private void execFlatTrajectorActionPerformed(java.awt.event.ActionEvent evt) {                                          
        boolean jittering=panTilt.isJitterEnabled();
        panTilt.setJitterEnabled(false);
        
        clearButActionPerformed(null);

        Runnable move = new Runnable() {
            @Override
            public void run() {
                for (int i = 0; i < 50; i++) {
                    // Center camera to start from.
                    setPanTilt(.5f, .5f);

                    try {
                        float from = 0.5f;
                        float to = 0.45f;
                        int sleepTime = 10;
                        
                        // Back and forth.
                        for (float d = from; d > to; d -= 0.001f) {
                            Thread.sleep(sleepTime);
                            setPanTilt(d, 0.5f);
                        }
                        
                        for (float d = to; d < from; d += 0.001f) {
                            Thread.sleep(sleepTime);
                            setPanTilt(d, 0.5f);
                        }
                    } catch (InterruptedException ex) {
                        Logger.getLogger(PanTiltAimerGUI.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            }
        };

        // Execute in thread to not block main data acquisition.
        Thread t = new Thread(move);
        t.start();

        // Center again at end.
        setPanTilt(.5f, .5f);

        panTilt.setJitterEnabled(jittering);
    }
    
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel calibrationPanel;
    private javax.swing.JButton centerBut;
    private javax.swing.JButton clearBut;
    private javax.swing.JButton jButton1;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JToggleButton loopTB;
    private javax.swing.JCheckBox recordCB;
    private javax.swing.JButton relaxBut;
    private javax.swing.JLabel statusLabel;
    private javax.swing.JButton execFlatTrajector;
    // End of variables declaration//GEN-END:variables

    public void exceptionOccurred(Exception x, Object source) {
        statusLabel.setText(x.getMessage());
    }

    /**
     * Property change events are fired to return events
     *
     * For sample messages "sample", the Point2D.Float object that is returned
     * is the pan,tilt value for that point, i.e., the last pan,tilt value that
     * has been set.
     *
     * When samples have been chosen, "done" is passed.
     *
     * @return the support. Add yourself as a listener to get notifications of
     * new user aiming points.
     */
    public PropertyChangeSupport getSupport() {
        return support;
    }

    /**
     * @return the recordingEnabled
     */
    private boolean isRecordingEnabled() {
        return recordingEnabled;
    }

    /**
     * @param recordingEnabled the recordingEnabled to set
     */
    private void setRecordingEnabled(boolean recordingEnabled) {
        boolean old = this.recordingEnabled;
        this.recordingEnabled = recordingEnabled;
        recordCB.setSelected(recordingEnabled);
        support.firePropertyChange(Message.SetRecordingEnabled.name(), old, recordingEnabled);
    }

    /**
     * @return the panTiltLimit
     */
    public float getPanTiltLimit() {
        return panLimit;
    }

    /**
     * @param panTiltLimit the panTiltLimit to set
     */
    public void setPanTiltLimit(float panLimit, float tiltLimit) {
        this.panLimit = panLimit;
        this.tiltLimit = tiltLimit;
    }
}
