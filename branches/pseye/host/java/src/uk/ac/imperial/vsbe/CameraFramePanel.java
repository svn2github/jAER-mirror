
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
        rawCameraPanel.reshape(0, 0, jPanel1.getWidth(), jPanel1.getHeight());
        jPanel1.add(rawCameraPanel, BorderLayout.CENTER);
    }
    
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        showRawInputCB = new javax.swing.JCheckBox();
        jPanel1 = new javax.swing.JPanel();

        setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Raw camera input (when enabled)"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        setMinimumSize(new java.awt.Dimension(320, 240));
        setPreferredSize(new java.awt.Dimension(320, 240));
        setLayout(new java.awt.BorderLayout());

        showRawInputCB.setText("Show raw input");
        showRawInputCB.setToolTipText("Activates raw input panel to show camera output");
        showRawInputCB.setHorizontalTextPosition(javax.swing.SwingConstants.RIGHT);
        showRawInputCB.setMaximumSize(null);
        showRawInputCB.setMinimumSize(new java.awt.Dimension(320, 50));
        showRawInputCB.setPreferredSize(new java.awt.Dimension(320, 50));
        showRawInputCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                showRawInputCBActionPerformed(evt);
            }
        });
        add(showRawInputCB, java.awt.BorderLayout.PAGE_START);

        jPanel1.setMaximumSize(new java.awt.Dimension(640, 480));
        jPanel1.setMinimumSize(new java.awt.Dimension(640, 480));
        jPanel1.setPreferredSize(new java.awt.Dimension(640, 480));
        jPanel1.setLayout(new java.awt.BorderLayout());
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
