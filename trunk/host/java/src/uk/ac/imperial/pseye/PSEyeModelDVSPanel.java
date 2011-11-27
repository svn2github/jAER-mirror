/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * CLCameraControlPanel.java
 *
 * Created on May 26, 2011, 1:08:46 PM
 */
package cl.eye;

//import cl.eye.CLCamera.CameraMode;
import uk.ac.imperial.pseye.PSEyeRawFramePanel;
import uk.ac.imperial.pseye.PSEyeHardwareInterface;
import cl.eye.OldPSEyeCLModelRetina.RetinaModel;
import java.awt.BorderLayout;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Logger;
import javax.swing.DefaultComboBoxModel;

/**
 * Controls camera and event generation parameters.
 * 
 * @author tobi
 */
public class PSEyeModelDVSPanel extends javax.swing.JPanel implements Observer {

    private final static Logger log = Logger.getLogger("CLCamera");
    private OldPSEyeCLModelRetina chip;
    private PSEyeHardwareInterface hardware;
    private PSEyeRawFramePanel rawCameraPanel;

    /** Creates new form CLCameraControlPanel */
    public PSEyeModelDVSPanel(OldPSEyeCLModelRetina chip) {
        this.chip = chip;
        hardware = (PSEyeHardwareInterface) chip.getHardwareInterface();
        initComponents();
        camModeCB.setModel(new DefaultComboBoxModel(CLCamera.CameraMode.values()));
        modelCB.setModel(new DefaultComboBoxModel(RetinaModel.values()));
        handleUpdate(null);
        chip.addObserver(this);
    }

    private boolean checkHardware() {
        hardware = (PSEyeHardwareInterface) chip.getHardwareInterface();
        return hardware!=null;
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        bindingGroup = new org.jdesktop.beansbinding.BindingGroup();

        rawInputPanel = new javax.swing.JPanel();
        showRawInputCB = new javax.swing.JCheckBox();
        jPanel1 = new javax.swing.JPanel();
        camModeCB = new javax.swing.JComboBox();
        jLabel6 = new javax.swing.JLabel();
        jPanel3 = new javax.swing.JPanel();
        jLabel1 = new javax.swing.JLabel();
        gainSp = new javax.swing.JSpinner();
        agCB = new javax.swing.JCheckBox();
        aeCB = new javax.swing.JCheckBox();
        jLabel2 = new javax.swing.JLabel();
        expSp = new javax.swing.JSpinner();
        jPanel2 = new javax.swing.JPanel();
        bThSp = new javax.swing.JSpinner();
        jLabel4 = new javax.swing.JLabel();
        itsCB = new javax.swing.JCheckBox();
        jLabel3 = new javax.swing.JLabel();
        jLabel5 = new javax.swing.JLabel();
        hThSp = new javax.swing.JSpinner();
        logCB = new javax.swing.JCheckBox();
        modelCB = new javax.swing.JComboBox();
        jLabel7 = new javax.swing.JLabel();
        jLabel8 = new javax.swing.JLabel();
        linlogSp = new javax.swing.JSpinner();
        jPanel4 = new javax.swing.JPanel();
        jLabel9 = new javax.swing.JLabel();
        jLabel10 = new javax.swing.JLabel();
        thSigmaTF = new javax.swing.JTextField();
        bgRateTF = new javax.swing.JTextField();
        statusLabel = new javax.swing.JLabel();

        rawInputPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("Raw camera input (when enabled)"));
        rawInputPanel.setLayout(new java.awt.BorderLayout());

        showRawInputCB.setText("Show raw input");
        showRawInputCB.setToolTipText("Activates raw input panel to show camera output");
        showRawInputCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                showRawInputCBActionPerformed(evt);
            }
        });
        rawInputPanel.add(showRawInputCB, java.awt.BorderLayout.PAGE_START);

        jPanel1.setBorder(javax.swing.BorderFactory.createTitledBorder("PS Eye control"));

        camModeCB.setMaximumRowCount(30);
        camModeCB.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        camModeCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                camModeCBActionPerformed(evt);
            }
        });

        jLabel6.setText("Camera mode");

        jLabel1.setText("Gain");

        gainSp.setToolTipText("CL eye gain (0-79)");

        org.jdesktop.beansbinding.Binding binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.gain}"), gainSp, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        agCB.setText("Auto gain");
        agCB.setToolTipText("Enables AGC");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.autoGainEnabled}"), agCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        agCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                agCBActionPerformed(evt);
            }
        });

        aeCB.setText("Auto exposure");
        aeCB.setToolTipText("Enables automatic exposure control");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.autoExposureEnabled}"), aeCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        aeCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                aeCBActionPerformed(evt);
            }
        });

        jLabel2.setText("Exposure");

        expSp.setToolTipText("CL eye exposure value (0-511)");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.exposure}"), expSp, org.jdesktop.beansbinding.BeanProperty.create("value"));
        bindingGroup.addBinding(binding);

        javax.swing.GroupLayout jPanel3Layout = new javax.swing.GroupLayout(jPanel3);
        jPanel3.setLayout(jPanel3Layout);
        jPanel3Layout.setHorizontalGroup(
            jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 227, Short.MAX_VALUE)
            .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                .addGroup(jPanel3Layout.createSequentialGroup()
                    .addContainerGap()
                    .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                        .addComponent(jLabel1, javax.swing.GroupLayout.Alignment.TRAILING)
                        .addComponent(jLabel2, javax.swing.GroupLayout.Alignment.TRAILING))
                    .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                    .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING, false)
                        .addComponent(expSp)
                        .addComponent(gainSp, javax.swing.GroupLayout.PREFERRED_SIZE, 55, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                    .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                        .addComponent(agCB)
                        .addGroup(jPanel3Layout.createSequentialGroup()
                            .addGap(2, 2, 2)
                            .addComponent(aeCB)))
                    .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)))
        );
        jPanel3Layout.setVerticalGroup(
            jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 73, Short.MAX_VALUE)
            .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                .addGroup(jPanel3Layout.createSequentialGroup()
                    .addContainerGap()
                    .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                        .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel3Layout.createSequentialGroup()
                            .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                                .addComponent(gainSp, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                                .addComponent(agCB))
                            .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                                .addGroup(jPanel3Layout.createSequentialGroup()
                                    .addGap(5, 5, 5)
                                    .addComponent(aeCB))
                                .addGroup(jPanel3Layout.createSequentialGroup()
                                    .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                                    .addGroup(jPanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                                        .addComponent(expSp, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                                        .addComponent(jLabel2)))))
                        .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel3Layout.createSequentialGroup()
                            .addComponent(jLabel1)
                            .addGap(31, 31, 31)))
                    .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)))
        );

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jLabel6)
                    .addComponent(camModeCB, javax.swing.GroupLayout.PREFERRED_SIZE, 194, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jPanel3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addContainerGap()
                        .addComponent(jLabel6)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(camModeCB, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addComponent(jPanel3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );

        jPanel2.setBorder(javax.swing.BorderFactory.createTitledBorder("Retina model control"));

        bThSp.setToolTipText("Sets threshold for temporal change events in ADC counts");
        bThSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                bThSpStateChanged(evt);
            }
        });

        jLabel4.setText("Brightness change threshold");

        itsCB.setText("Interpolate time stamp");
        itsCB.setToolTipText("Enables linear interpolation of timestamps between frames");

        binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, this, org.jdesktop.beansbinding.ELProperty.create("${chip.linearInterpolateTimeStamp}"), itsCB, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        itsCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                itsCBActionPerformed(evt);
            }
        });

        jLabel3.setText("<html>Controls the parameters for generating events. <br>The hue change threshold is only used for color camera modes.");

        jLabel5.setText("Hue change threshold");

        hThSp.setToolTipText("Sets threshold for temporal change events in ADC counts");
        hThSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                hThSpStateChanged(evt);
            }
        });

        logCB.setText("Log intensity mode");
        logCB.setToolTipText("Enables brightness change detection on log intensity change, rather than linear intensity change");
        logCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                logCBActionPerformed(evt);
            }
        });

        modelCB.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        modelCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                modelCBActionPerformed(evt);
            }
        });

        jLabel7.setText("Retina Model");

        jLabel8.setText("Lin-Log transition value");

        linlogSp.setToolTipText("mapping from sample to value is linear up to this value, then logarithmic afterwards");
        linlogSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                linlogSpStateChanged(evt);
            }
        });

        jLabel9.setHorizontalAlignment(javax.swing.SwingConstants.TRAILING);
        jLabel9.setText("Event threshold mismatch (Levels)");

        jLabel10.setHorizontalAlignment(javax.swing.SwingConstants.TRAILING);
        jLabel10.setText("Background event rate (Hz)");

        thSigmaTF.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                thSigmaTFActionPerformed(evt);
            }
        });

        bgRateTF.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                bgRateTFActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout jPanel4Layout = new javax.swing.GroupLayout(jPanel4);
        jPanel4.setLayout(jPanel4Layout);
        jPanel4Layout.setHorizontalGroup(
            jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel4Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(jLabel9)
                    .addComponent(jLabel10))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                    .addComponent(thSigmaTF)
                    .addComponent(bgRateTF, javax.swing.GroupLayout.PREFERRED_SIZE, 57, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        jPanel4Layout.setVerticalGroup(
            jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel4Layout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel9)
                    .addComponent(thSigmaTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(bgRateTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel10)))
        );

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel2Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jPanel4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addGroup(jPanel2Layout.createSequentialGroup()
                        .addComponent(jLabel7)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(modelCB, javax.swing.GroupLayout.PREFERRED_SIZE, 158, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addGap(18, 18, 18)
                        .addComponent(itsCB))
                    .addGroup(jPanel2Layout.createSequentialGroup()
                        .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                            .addComponent(jLabel5)
                            .addComponent(jLabel4))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(bThSp, javax.swing.GroupLayout.PREFERRED_SIZE, 62, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(hThSp, javax.swing.GroupLayout.PREFERRED_SIZE, 62, javax.swing.GroupLayout.PREFERRED_SIZE))
                        .addGap(18, 18, 18)
                        .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addGroup(jPanel2Layout.createSequentialGroup()
                                .addComponent(jLabel8)
                                .addGap(6, 6, 6)
                                .addComponent(linlogSp, javax.swing.GroupLayout.PREFERRED_SIZE, 50, javax.swing.GroupLayout.PREFERRED_SIZE))
                            .addComponent(logCB))))
                .addContainerGap(44, Short.MAX_VALUE))
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addComponent(jLabel3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(modelCB, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel7)
                    .addComponent(itsCB))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel4)
                    .addComponent(bThSp, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(logCB))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel5)
                    .addComponent(hThSp, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel8)
                    .addComponent(linlogSp, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jPanel4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
        );

        statusLabel.setToolTipText("status output");

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(rawInputPanel, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 453, Short.MAX_VALUE)
                    .addComponent(jPanel2, 0, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(statusLabel, javax.swing.GroupLayout.DEFAULT_SIZE, 453, Short.MAX_VALUE)
                    .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, 100, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(rawInputPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 256, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(statusLabel, javax.swing.GroupLayout.PREFERRED_SIZE, 15, javax.swing.GroupLayout.PREFERRED_SIZE))
        );

        bindingGroup.bind();
    }// </editor-fold>//GEN-END:initComponents

    private void itsCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_itsCBActionPerformed
        if (!checkHardware()) {
            return;
        }
        chip.setLinearInterpolateTimeStamp(itsCB.isSelected());
    }//GEN-LAST:event_itsCBActionPerformed

    private void agCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_agCBActionPerformed
        if (!checkHardware()) {
            return;
        }
        if (hardware != null) { //agCB.isSelected() && 
            gainSp.setValue(hardware.getGain());
        }
}//GEN-LAST:event_agCBActionPerformed

    private void aeCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aeCBActionPerformed
        if (!checkHardware()) {
            return;
        }
        if (hardware != null) { // aeCB.isSelected() && 
            expSp.setValue(hardware.getExposure());
        }
}//GEN-LAST:event_aeCBActionPerformed

    private void showRawInputCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_showRawInputCBActionPerformed
        if (rawCameraPanel == null) {
            rawCameraPanel = new PSEyeRawFramePanel(chip);
            rawInputPanel.add(rawCameraPanel, BorderLayout.CENTER);
            revalidate();
        }
        if (!checkHardware()) {
            return;
        }
        if (showRawInputCB.isSelected()) {
            ((PSEyeHardwareInterface) chip.getHardwareInterface()).addAEListener(rawCameraPanel);
        } else {
            ((PSEyeHardwareInterface) chip.getHardwareInterface()).removeAEListener(rawCameraPanel);
        }
}//GEN-LAST:event_showRawInputCBActionPerformed

    private void camModeCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_camModeCBActionPerformed
        try {
            CameraMode mode = (CameraMode) camModeCB.getSelectedItem();
            chip.setCameraMode(mode);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_camModeCBActionPerformed

    private void hThSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_hThSpStateChanged
        try {
            Integer i = (Integer) hThSp.getValue();
            chip.setHueChangeThreshold(i);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_hThSpStateChanged

    private void bThSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_bThSpStateChanged
        try {
            Integer i = (Integer) bThSp.getValue();
            chip.setBrightnessChangeThreshold(i);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_bThSpStateChanged

    private void logCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_logCBActionPerformed
        chip.setLogIntensityMode(logCB.isSelected());
    }//GEN-LAST:event_logCBActionPerformed

    private void modelCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_modelCBActionPerformed
        try {
            RetinaModel model = (RetinaModel) modelCB.getSelectedItem();
            chip.setRetinaModel(model);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_modelCBActionPerformed

    private void linlogSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_linlogSpStateChanged
        try {
            Integer i = (Integer) linlogSp.getValue();
            chip.setLinLogTransitionValue(i);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_linlogSpStateChanged

    private void thSigmaTFActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_thSigmaTFActionPerformed
        try {
            Float f = Float.parseFloat(thSigmaTF.getText());
            chip.setSigmaThreshold(f);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_thSigmaTFActionPerformed

    private void bgRateTFActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_bgRateTFActionPerformed
        try {
            Float f = Float.parseFloat(bgRateTF.getText());
            chip.setBackgroundEventRatePerPixelHz(f);
            statusLabel.setText("");
        } catch (Exception e) {
            log.warning(e.toString());
            statusLabel.setText(e.toString());
        }
    }//GEN-LAST:event_bgRateTFActionPerformed
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JCheckBox aeCB;
    private javax.swing.JCheckBox agCB;
    private javax.swing.JSpinner bThSp;
    private javax.swing.JTextField bgRateTF;
    private javax.swing.JComboBox camModeCB;
    private javax.swing.JSpinner expSp;
    private javax.swing.JSpinner gainSp;
    private javax.swing.JSpinner hThSp;
    private javax.swing.JCheckBox itsCB;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel10;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JLabel jLabel6;
    private javax.swing.JLabel jLabel7;
    private javax.swing.JLabel jLabel8;
    private javax.swing.JLabel jLabel9;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel4;
    private javax.swing.JSpinner linlogSp;
    private javax.swing.JCheckBox logCB;
    private javax.swing.JComboBox modelCB;
    private javax.swing.JPanel rawInputPanel;
    private javax.swing.JCheckBox showRawInputCB;
    private javax.swing.JLabel statusLabel;
    private javax.swing.JTextField thSigmaTF;
    private org.jdesktop.beansbinding.BindingGroup bindingGroup;
    // End of variables declaration//GEN-END:variables

    /**
     * @return the chip
     */
    public OldPSEyeCLModelRetina getChip() {
        return chip;
    }

    /**
     * @param chip the chip to set
     */
    public void setChip(OldPSEyeCLModelRetina chip) {
        this.chip = chip;
    }

    @Override
    public void update(Observable o, Object arg) {
        if (o != null && o == chip) {
            handleUpdate(arg);
        }
    }

    /** The update arg is the event
     * 
     * @param arg the event from the OldPSEyeCLModelRetina
     */
    private void handleUpdate(Object o) {
        String arg="";
        if (o == null) {
            agCB.setSelected(chip.isAutoGainEnabled());
            aeCB.setSelected(chip.isAutoExposureEnabled());
            gainSp.setValue(chip.getGain());
            expSp.setValue(chip.getExposure());
            bThSp.setValue(chip.getBrightnessChangeThreshold());
            hThSp.setValue(chip.getHueChangeThreshold());
            itsCB.setSelected(chip.isLinearInterpolateTimeStamp());
            logCB.setSelected(chip.isLogIntensityMode());
            camModeCB.setSelectedItem(chip.getCameraMode());
            modelCB.setSelectedItem(chip.getRetinaModel());
            modelCB.setToolTipText(chip.getRetinaModel().description);
            linlogSp.setValue(chip.getLinLogTransitionValue());
            thSigmaTF.setText(String.format("%.1f", chip.getSigmaThreshold()));
            bgRateTF.setText(String.format("%.3f", chip.getBackgroundEventRatePerPixelHz()));
            return;
        }
        if(o instanceof String)arg=(String)o;
        if (arg.equals(OldPSEyeCLModelRetina.EVENT_AUTOEXPOSURE)) {
            aeCB.setSelected(chip.isAutoExposureEnabled());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_AUTO_GAIN)) {
            agCB.setSelected(chip.isAutoGainEnabled());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_BRIGHTNESS_CHANGE_THRESHOLD)) {
            bThSp.setValue(chip.getBrightnessChangeThreshold());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_CAMERA_MODE)) {
            camModeCB.setSelectedItem(chip.getCameraMode());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_EXPOSURE)) {
            expSp.setValue(chip.getExposure());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_GAIN)) {
            gainSp.setValue(chip.getGain());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_HUE_CHANGE_THRESHOLD)) {
            hThSp.setValue(chip.getHueChangeThreshold());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_LINEAR_INTERPOLATE_TIMESTAMP)) {
            itsCB.setSelected(chip.isLinearInterpolateTimeStamp());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_LOG_INTENSITY_MODE)) {
            logCB.setSelected(chip.isLogIntensityMode());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_RETINA_MODEL)) {
            modelCB.setSelectedItem(chip.getRetinaModel());
            modelCB.setToolTipText(chip.getRetinaModel().description);
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_LINLOG_TRANSITION_VALUE)) {
            linlogSp.setValue(chip.getLinLogTransitionValue());
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_SIGMA_THRESHOLD)) {
            thSigmaTF.setText(String.format("%.1f", chip.getSigmaThreshold()));
        } else if (arg.equals(OldPSEyeCLModelRetina.EVENT_BACKGROUND_EVENT_RATE)) {
            bgRateTF.setText(String.format("%.3f", chip.getBackgroundEventRatePerPixelHz()));
        }
    }
}
