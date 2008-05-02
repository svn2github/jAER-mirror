/*
 * PanTiltGUI.java
 *
 * Created on April 21, 2008, 11:50 AM
 */
package ch.unizh.ini.hardware.pantilt;

import ch.unizh.ini.caviar.hardwareinterface.HardwareInterfaceException;
import ch.unizh.ini.caviar.util.ExceptionListener;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Point;
import java.awt.Toolkit;
import java.awt.event.*;
import java.awt.event.KeyEvent;
import java.awt.geom.*;
import java.beans.*;
import java.util.Vector;
import java.util.logging.Logger;

/**
 * Tests pantilt by mimicing mouse movements. Also can serve as calibration source via PropertyChangeSupport.
 * @author  tobi
 */
public class PanTiltGUI extends javax.swing.JFrame implements ExceptionListener {

    private PropertyChangeSupport support = new PropertyChangeSupport(this);
    Logger log = Logger.getLogger("PanTiltGUI");
    private PanTilt panTilt;
    private int w = 200,  h = 200,  x0 = 0,  y0 = 0;
    private Point2D.Float lastPanTilt = new Point2D.Float(0.5f, 0.5f);
    private Point lastMousePressLocation = new Point(w / 2, h / 2);
    Vector<Point> calibrationPoints=new Vector<Point>();
    public enum Message {AddSample, ClearSamples, ComputeCalibration};
    
    public PanTiltGUI(PanTilt pt) {
        panTilt = pt;
        initComponents();
        calibrationPanel.setPreferredSize(new Dimension(w, h));
        HardwareInterfaceException.addExceptionListener(this);
        calibrationPanel.requestFocusInWindow();
        pack();
    }

    @Override
    public void paint(Graphics g) {
        final int r=6;
        super.paint(g);
        for(Point p:calibrationPoints){
                calibrationPanel.getGraphics().drawOval(p.x - r, p.y - r, r * 2, r * 2);
        }
    }

    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        statusLabel = new javax.swing.JLabel();
        calibrationPanel = new javax.swing.JPanel();
        jLabel5 = new javax.swing.JLabel();
        okButton = new javax.swing.JButton();
        cancelButton = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setTitle("PanTilt");
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
            .addGap(0, 424, Short.MAX_VALUE)
        );
        calibrationPanelLayout.setVerticalGroup(
            calibrationPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 281, Short.MAX_VALUE)
        );

        jLabel5.setText("<html>Move pan tilt to point near to corners of retina view.<br>Press key <em>s</em> for each sample.</html>");

        okButton.setText("OK");
        okButton.setToolTipText("Use points to calibrate");
        okButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                okButtonActionPerformed(evt);
            }
        });

        cancelButton.setText("Cancel");
        cancelButton.setToolTipText("Cancel calibration, keep old values");
        cancelButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cancelButtonActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                        .addGroup(layout.createSequentialGroup()
                            .addComponent(calibrationPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addContainerGap())
                        .addGroup(layout.createSequentialGroup()
                            .addComponent(jLabel5, javax.swing.GroupLayout.PREFERRED_SIZE, 270, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addContainerGap(168, Short.MAX_VALUE))
                        .addGroup(layout.createSequentialGroup()
                            .addComponent(statusLabel, javax.swing.GroupLayout.DEFAULT_SIZE, 437, Short.MAX_VALUE)
                            .addGap(1, 1, 1)))
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                        .addComponent(okButton, javax.swing.GroupLayout.PREFERRED_SIZE, 64, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(cancelButton)
                        .addContainerGap())))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jLabel5)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(calibrationPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(5, 5, 5)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(cancelButton)
                    .addComponent(okButton))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(statusLabel)
                .addGap(5, 5, 5))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents
    private float getPan(MouseEvent evt) {
        int x = evt.getX();
        float pan = (float) x / w;
        return pan;

    }

    private float getTilt(MouseEvent evt) {
        int y = evt.getY();
        float tilt = 1 - (float) (h - y) / h;
        return tilt;
    }

    private void setPanTilt(float pan, float tilt) {
        try {
            lastPanTilt.x = pan;
            lastPanTilt.y = tilt;
            panTilt.setPanTilt(pan, tilt);
            statusLabel.setText(String.format("%.3f, %.3f", pan, tilt));
        } catch (HardwareInterfaceException e) {
            log.warning(e.toString());
        }
    }

    private void calibrationPanelComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_calibrationPanelComponentResized
        w = calibrationPanel.getWidth();
        h = calibrationPanel.getHeight();
    }//GEN-LAST:event_calibrationPanelComponentResized

    private void calibrationPanelMouseDragged(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseDragged
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        setPanTilt(pan, tilt);
    }//GEN-LAST:event_calibrationPanelMouseDragged

    private void calibrationPanelMousePressed(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMousePressed
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        lastMousePressLocation = evt.getPoint();
        setPanTilt(pan, tilt);
        panTilt.stopJitter();
    }//GEN-LAST:event_calibrationPanelMousePressed

    private void calibrationPanelKeyPressed(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_calibrationPanelKeyPressed
        switch (evt.getKeyCode()) {
            case KeyEvent.VK_S:
            case KeyEvent.VK_SPACE:
                support.firePropertyChange(Message.AddSample.name(), null, lastPanTilt);
                calibrationPoints.add(lastMousePressLocation);
              repaint();
                return;
            case KeyEvent.VK_ENTER:
                support.firePropertyChange(Message.ComputeCalibration.name(), null, null);
                dispose();
            default:
                Toolkit.getDefaultToolkit().beep();
        }
    }//GEN-LAST:event_calibrationPanelKeyPressed

    private void cancelButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cancelButtonActionPerformed
        dispose();
        panTilt.stopJitter();
        log.info("calibration canceled");
    }//GEN-LAST:event_cancelButtonActionPerformed

    private void okButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_okButtonActionPerformed
        support.firePropertyChange("done", null, null);
        dispose();
        panTilt.stopJitter();
        log.info("calibration called for");
    }//GEN-LAST:event_okButtonActionPerformed

    private void calibrationPanelMouseReleased(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseReleased
        float pan = getPan(evt);
        float tilt = getTilt(evt);
        lastMousePressLocation = evt.getPoint();
        setPanTilt(pan, tilt);
        panTilt.startJitter();
    }//GEN-LAST:event_calibrationPanelMouseReleased

    private void formWindowClosed(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosed
        panTilt.stopJitter();
    }//GEN-LAST:event_formWindowClosed

    private void calibrationPanelMouseEntered(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseEntered
        setCursor(new java.awt.Cursor(java.awt.Cursor.CROSSHAIR_CURSOR));
    }//GEN-LAST:event_calibrationPanelMouseEntered

    private void calibrationPanelMouseExited(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_calibrationPanelMouseExited
        setCursor(new java.awt.Cursor(java.awt.Cursor.DEFAULT_CURSOR));
    }//GEN-LAST:event_calibrationPanelMouseExited

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {

            public void run() {
                new PanTiltGUI(new PanTilt()).setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel calibrationPanel;
    private javax.swing.JButton cancelButton;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JButton okButton;
    private javax.swing.JLabel statusLabel;
    // End of variables declaration//GEN-END:variables
    public void exceptionOccurred(Exception x, Object source) {
        statusLabel.setText(x.getMessage());
    }

    /** Property change events are fired to return events 
     * 
     * For sample messages "sample", the Point2D.Float object that is returned is the pan,tilt value for that point, i.e., the last 
     * pan,tilt value that has been set.
     * 
     * When samples have been chosen, "done" is passed.
     * 
     * @return the support. Add yourself as a listener to get notifications of new calibration points.
     */
    public PropertyChangeSupport getSupport() {
        return support;
    }
}
