
package uk.ac.imperial.vsbe;

import java.awt.BorderLayout;
import java.util.Observer;
import java.util.Observable;

/**
 * Panel to contain raw PSEye image.
 * 
 * @author tobi - modified mlk
 */
public class CameraFramePanel extends javax.swing.JPanel implements Observer {
    private AbstractCamera hardware;
    private CameraViewPanel rawCameraPanel = new CameraViewPanel();

    public CameraFramePanel(AbstractCamera hardware) {
        this.hardware = hardware;
        initComponents();
        this.hardware.addObserver(this);
        rawCameraPanel.reshape(0, 0, jPanel1.getWidth(), jPanel1.getHeight());
        jPanel1.add(rawCameraPanel, BorderLayout.CENTER);
    }

    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        showRawInputCB = new javax.swing.JCheckBox();
        jPanel1 = new javax.swing.JPanel();
        filler1 = new javax.swing.Box.Filler(new java.awt.Dimension(20, 0), new java.awt.Dimension(20, 0), new java.awt.Dimension(20, 32767));
        filler2 = new javax.swing.Box.Filler(new java.awt.Dimension(20, 0), new java.awt.Dimension(20, 0), new java.awt.Dimension(20, 32767));
        filler3 = new javax.swing.Box.Filler(new java.awt.Dimension(0, 20), new java.awt.Dimension(0, 20), new java.awt.Dimension(32767, 20));
        filler4 = new javax.swing.Box.Filler(new java.awt.Dimension(0, 10), new java.awt.Dimension(0, 10), new java.awt.Dimension(32767, 10));

        setBorder(javax.swing.BorderFactory.createTitledBorder("Raw camera input (when enabled)"));
        setMaximumSize(new java.awt.Dimension(430, 2147483647));
        setMinimumSize(new java.awt.Dimension(430, 50));
        setPreferredSize(new java.awt.Dimension(430, 329));
        setLayout(new java.awt.BorderLayout());

        showRawInputCB.setText("Show raw input");
        showRawInputCB.setToolTipText("Activates raw input panel to show camera output");
        showRawInputCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                showRawInputCBActionPerformed(evt);
            }
        });
        add(showRawInputCB, java.awt.BorderLayout.PAGE_START);

        jPanel1.setMaximumSize(new java.awt.Dimension(322, 242));
        jPanel1.setMinimumSize(new java.awt.Dimension(322, 242));
        jPanel1.setPreferredSize(new java.awt.Dimension(322, 242));
        jPanel1.setLayout(new java.awt.BorderLayout());
        jPanel1.add(filler1, java.awt.BorderLayout.LINE_START);
        jPanel1.add(filler2, java.awt.BorderLayout.LINE_END);
        jPanel1.add(filler3, java.awt.BorderLayout.PAGE_END);
        jPanel1.add(filler4, java.awt.BorderLayout.PAGE_START);

        add(jPanel1, java.awt.BorderLayout.CENTER);
    }// </editor-fold>//GEN-END:initComponents

    private void showRawInputCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_showRawInputCBActionPerformed
        // create raw data panel and fit in holder panel jPanel1 (used for layout)
        if (hardware != null) {
            if (showRawInputCB.isSelected()) {
                rawCameraPanel.setStream(hardware.stream);
                revalidate();
                if (!rawCameraPanel.animator.isAnimating()) 
                    rawCameraPanel.animator.start();
                hardware.addObserver(this);
            } else {
                if (rawCameraPanel.animator.isAnimating()) 
                    rawCameraPanel.animator.stop();
                hardware.deleteObserver(this);
                rawCameraPanel.setStream(null);
                revalidate();
            }
        }
}//GEN-LAST:event_showRawInputCBActionPerformed

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.Box.Filler filler1;
    private javax.swing.Box.Filler filler2;
    private javax.swing.Box.Filler filler3;
    private javax.swing.Box.Filler filler4;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JCheckBox showRawInputCB;
    // End of variables declaration//GEN-END:variables
    
    @Override
    public void update(Observable o, Object arg) {
        // check to see if camera resolution changed and if so reshape
        /*
        if (o != null && o == hardware) {
            rawCameraPanel.reshape(0, 0, hardware.stream.getFrameX(), 
                    hardware.stream.getFrameY());
        }
         */
    }
}
