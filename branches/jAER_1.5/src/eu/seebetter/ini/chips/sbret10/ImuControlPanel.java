/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.seebetter.ini.chips.sbret10;

import eu.seebetter.ini.chips.ApsDvsChip;
import eu.seebetter.ini.chips.sbret10.SBret10config.ImuAccelScale;
import eu.seebetter.ini.chips.sbret10.SBret10config.ImuControl;
import eu.seebetter.ini.chips.sbret10.SBret10config.ImuGyroScale;
import java.awt.Color;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.util.logging.Logger;
import net.sf.jaer.config.ApsDvsConfig;

/**
 *
 * @author tobi
 */
public class ImuControlPanel extends javax.swing.JPanel implements PropertyChangeListener {

    private static final Logger log = Logger.getLogger("ImuControlPanel");
    private ImuControl imuControl;
    private boolean dontProcess = false;

    /**
     * Creates new form ImuControlPanel
     */
    public ImuControlPanel(SBret10config config) {
        imuControl = config.imuControl;
        initComponents();
        gyroFullScaleComboBox.removeAllItems();
        for (ImuGyroScale scale : ImuGyroScale.values()) {
            gyroFullScaleComboBox.addItem(scale.toString());
        }
        accelFullScaleComboBox.removeAllItems();
        for (ImuAccelScale scale : ImuAccelScale.values()) {
            accelFullScaleComboBox.addItem(scale.toString());
        }
        dontProcess = true;
        imuEnabledCB.setSelected(imuControl.isImuEnabled());
        imuVisibleCB.setSelected(imuControl.isDisplayImu());

        gyroFullScaleComboBox.setSelectedItem(imuControl.getGyroScale());
        accelFullScaleComboBox.setSelectedItem(imuControl.getAccelScale());
        dontProcess = false;
        dlpfTF.setText(Integer.toString(imuControl.getDLPF()));
        sampleRateDividerTF.setText(Integer.toString(imuControl.getSampleRateDivider()));
        config.getChip().getSupport().addPropertyChangeListener(this);
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        imuEnabledCB = new javax.swing.JCheckBox();
        imuVisibleCB = new javax.swing.JCheckBox();
        jLabel1 = new javax.swing.JLabel();
        gyroFullScaleComboBox = new javax.swing.JComboBox();
        jLabel2 = new javax.swing.JLabel();
        jLabel3 = new javax.swing.JLabel();
        accelFullScaleComboBox = new javax.swing.JComboBox();
        sampleRateDividerTF = new javax.swing.JTextField();
        jLabel4 = new javax.swing.JLabel();
        dlpfTF = new javax.swing.JTextField();

        imuEnabledCB.setText("Enable");
        imuEnabledCB.setToolTipText("show the IMU output if it is available");
        imuEnabledCB.setHorizontalTextPosition(javax.swing.SwingConstants.LEADING);
        imuEnabledCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                imuEnabledCBActionPerformed(evt);
            }
        });

        imuVisibleCB.setText("Display");
        imuVisibleCB.setToolTipText("show the IMU output if it is available");
        imuVisibleCB.setHorizontalTextPosition(javax.swing.SwingConstants.LEADING);
        imuVisibleCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                imuVisibleCBActionPerformed(evt);
            }
        });

        jLabel1.setText("Gyro full scale range (deg/s)");

        gyroFullScaleComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        gyroFullScaleComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                gyroFullScaleComboBoxActionPerformed(evt);
            }
        });

        jLabel2.setText("Accelerometer full scale range (g)");

        jLabel3.setText("Sample rate divider (0-255)");

        accelFullScaleComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        accelFullScaleComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                accelFullScaleComboBoxActionPerformed(evt);
            }
        });

        sampleRateDividerTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        sampleRateDividerTF.setText("jTextField1");
        sampleRateDividerTF.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sampleRateDividerTFActionPerformed(evt);
            }
        });

        jLabel4.setText("Digital Low Pass Filter Setting (0-6)");

        dlpfTF.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        dlpfTF.setText("jTextField2");
        dlpfTF.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                dlpfTFActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jLabel2)
                            .addComponent(jLabel3)
                            .addComponent(jLabel1))
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addGroup(layout.createSequentialGroup()
                                .addGap(24, 24, 24)
                                .addComponent(sampleRateDividerTF, javax.swing.GroupLayout.DEFAULT_SIZE, 195, Short.MAX_VALUE))
                            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                                .addComponent(accelFullScaleComboBox, 0, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                                .addComponent(gyroFullScaleComboBox, 0, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))))
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(imuEnabledCB)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(imuVisibleCB)
                        .addGap(0, 0, Short.MAX_VALUE))
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel4)
                        .addGap(18, 18, 18)
                        .addComponent(dlpfTF)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(imuEnabledCB, javax.swing.GroupLayout.PREFERRED_SIZE, 23, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(imuVisibleCB, javax.swing.GroupLayout.PREFERRED_SIZE, 23, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(gyroFullScaleComboBox, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel2)
                    .addComponent(accelFullScaleComboBox, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel3)
                    .addComponent(sampleRateDividerTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel4)
                    .addComponent(dlpfTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(165, Short.MAX_VALUE))
        );
    }// </editor-fold>//GEN-END:initComponents

    private void imuVisibleCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_imuVisibleCBActionPerformed
        if (dontProcess) {
            return;
        }
        imuControl.setDisplayImu(imuVisibleCB.isSelected());
    }//GEN-LAST:event_imuVisibleCBActionPerformed

    private void imuEnabledCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_imuEnabledCBActionPerformed
        if (dontProcess) {
            return;
        }
        imuControl.setImuEnabled(imuEnabledCB.isSelected());
    }//GEN-LAST:event_imuEnabledCBActionPerformed

    private void gyroFullScaleComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_gyroFullScaleComboBoxActionPerformed
        if (dontProcess) {
            return;
        }
        Object o = gyroFullScaleComboBox.getSelectedItem();
        if (o == null) {
            return;
        }
        ImuGyroScale scale = ImuGyroScale.valueOf((String) o);
        imuControl.setGyroScale(scale);
    }//GEN-LAST:event_gyroFullScaleComboBoxActionPerformed

    private void accelFullScaleComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_accelFullScaleComboBoxActionPerformed
        if (dontProcess) {
            return;
        }
        Object o = accelFullScaleComboBox.getSelectedItem();
        if (o == null) {
            return;
        }
        ImuAccelScale scale = ImuAccelScale.valueOf((String) o);
        imuControl.setAccelScale(scale);
    }//GEN-LAST:event_accelFullScaleComboBoxActionPerformed

    private void dlpfTFActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_dlpfTFActionPerformed
        try {
            int v = Integer.parseInt(dlpfTF.getText());
            imuControl.setDLPF(v);
            dlpfTF.setBackground(Color.white);
        } catch (Exception e) {
            log.warning(e.toString());
            dlpfTF.setBackground(Color.red);
        }
    }//GEN-LAST:event_dlpfTFActionPerformed

    private void sampleRateDividerTFActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sampleRateDividerTFActionPerformed
        try {
            int v = Integer.parseInt(sampleRateDividerTF.getText());
            imuControl.setSampleRateDivider(v);
            sampleRateDividerTF.setBackground(Color.white);
        } catch (Exception e) {
            log.warning(e.toString());
            sampleRateDividerTF.setBackground(Color.red);
        }
    }//GEN-LAST:event_sampleRateDividerTFActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JComboBox accelFullScaleComboBox;
    private javax.swing.JTextField dlpfTF;
    private javax.swing.JComboBox gyroFullScaleComboBox;
    private javax.swing.JCheckBox imuEnabledCB;
    private javax.swing.JCheckBox imuVisibleCB;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JTextField sampleRateDividerTF;
    // End of variables declaration//GEN-END:variables

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        switch (evt.getPropertyName()) {
            case ApsDvsConfig.IMU_ENABLED:
                imuEnabledCB.setSelected((boolean) evt.getNewValue());
                break;
            case ApsDvsConfig.IMU_DISPLAY_ENABLED:
                imuVisibleCB.setSelected((boolean) evt.getNewValue());
                break;
            case ApsDvsConfig.IMU_ACCEL_SCALE_CHANGED:
                dontProcess = true;
                accelFullScaleComboBox.setSelectedItem(evt.getNewValue());
                dontProcess = false;
                break;
            case ApsDvsConfig.IMU_GYRO_SCALE_CHANGED:
                dontProcess = true;
                gyroFullScaleComboBox.setSelectedItem(evt.getNewValue());
                dontProcess = false;
                break;
            default:
                log.warning("unhandled event " + evt);
        }
    }
}