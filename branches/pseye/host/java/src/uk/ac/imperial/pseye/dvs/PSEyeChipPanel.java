
package uk.ac.imperial.pseye.dvs;

import uk.ac.imperial.pseye.*;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Logger;
import javax.swing.DefaultComboBoxModel;
import javax.swing.SpinnerNumberModel;
import javax.swing.JPanel;
import java.util.Hashtable;
import javax.swing.JLabel;

/*
 * JPanel used to control PSEye settings.
 * Interacts through the PSEyeDriverInterface so can use a PSEyechip or camera 
 * itself. 
 * 
 * @author mlk
 */
public class PSEyeChipPanel extends JPanel implements Observer {

    private final static Logger log = Logger.getLogger("PSEyeChipPanel");
    public PSEyeModelDVS chip;

    /* Create a control panel 
     * 
     * @param driver: the interface to observer and use to control the camera
     */
    public PSEyeChipPanel(PSEyeModelDVS chip) {
        this.chip = chip;
        // create all panel components
        initComponents();
        
        // read current driver settings
        setComponents();
        
        // add this to the driver Observable
        chip.addObserver(this);
    }
    
    /*
    private void setFileModified() {
        if (driver != null && driver.getAeViewer() != null && driver.getAeViewer().getBiasgenFrame() != null) {
            driver.getAeViewer().getBiasgenFrame().setFileModified(true);
        }
    }
     */
    
    /* Read the driver settings and set components to these values 
     * 
     */
    private void setComponents() {
        /*
        Object[] modes = chip.getModes().toArray();
        modeCB.setModel(new DefaultComboBoxModel(modes));
        modeCB.setSelectedItem(chip.getMode());
        modeCB.setEnabled(modes.length > 1);
        
        Object[] resolutions = chip.getResolutions().toArray();
        resCB.setModel(new DefaultComboBoxModel(resolutions));
        resCB.setEnabled(resolutions.length > 1);
        resCB.setSelectedItem(chip.getResolution());
        
        Object[] frameRates = chip.getFrameRates().toArray();
        rateCB.setModel(new DefaultComboBoxModel(frameRates));
        rateCB.setEnabled(frameRates.length > 1);
        rateCB.setSelectedItem(chip.getFrameRate());
        
        agCB.setSelected(chip.getAutoGain());
        aeCB.setSelected(chip.getAutoExposure());
        abCB.setSelected(chip.getAutoBalance());
        */
        Hashtable labelTable = null;
        
        /*
        expSl.setMinimum(chip.getMinExposure());
        expSl.setMaximum(chip.getMaxExposure());
        expSl.setValue(chip.getExposure());
        labelTable = new Hashtable();
        labelTable.put(chip.getMinExposure(), new JLabel(Integer.toString(chip.getMinExposure())));
        labelTable.put(chip.getMaxExposure(), new JLabel(Integer.toString(chip.getMaxExposure())));
        expSl.setLabelTable(labelTable);
        expSl.setPaintLabels(true);
        expSl.setEnabled(!aeCB.isSelected());
        
        expSp.setModel(new SpinnerNumberModel(chip.getExposure(), 
                chip.getMinExposure(), chip.getMaxExposure(), 1));
        expSp.setValue(chip.getExposure());
        expSp.setEnabled(!aeCB.isSelected());
        
        gainSl.setMinimum(chip.getMinGain());
        gainSl.setMaximum(chip.getMaxGain());
        gainSl.setValue(chip.getGain());
        labelTable = new Hashtable();
        labelTable.put(chip.getMinGain(), new JLabel(Integer.toString(chip.getMinGain())));
        labelTable.put(chip.getMaxGain(), new JLabel(Integer.toString(chip.getMaxGain())));
        gainSl.setLabelTable(labelTable);
        gainSl.setPaintLabels(true);
        gainSl.setEnabled(!agCB.isSelected());
                
        gainSp.setModel(new SpinnerNumberModel(chip.getGain(), 
                chip.getMinGain(), chip.getMaxGain(), 1));
        gainSp.setValue(chip.getGain());
        gainSp.setEnabled(!agCB.isSelected());
        */
        
        onSl.setMinimum(1);
        onSl.setMaximum(255);
        onSl.setValue((int) Math.floor(chip.getSigmaOnThreshold() / chip.getMinSigmaOn()));
        onSl.setPaintLabels(false);
        onSl.setPaintTicks(false);
        /*
        labelTable = new Hashtable();
        labelTable.put(1, new JLabel("MIN"));
        labelTable.put(255, new JLabel("MAX"));
        onSl.setLabelTable(labelTable);
        */
        onSp.setModel(new SpinnerNumberModel(chip.getSigmaOnThreshold(), 
                chip.getMinSigmaOn(), chip.getMaxSigmaOn(), chip.getMinSigmaOn()));
        
        onstdSp.setModel(new SpinnerNumberModel(chip.getSigmaOnDeviation() * 100, 
                0, 100, 1));
                        
        offSl.setMinimum(1);
        offSl.setMaximum(255);
        offSl.setValue((int) Math.floor(chip.getSigmaOffThreshold() / chip.getMinSigmaOff()));
        /*
        labelTable = new Hashtable();
        labelTable.put(1, new JLabel("MIN"));
        labelTable.put(255, new JLabel("MAX"));
        offSl.setLabelTable(labelTable);
        */
        offSp.setModel(new SpinnerNumberModel(chip.getSigmaOffThreshold(), 
                chip.getMinSigmaOff(), chip.getMaxSigmaOff(), chip.getMinSigmaOff()));        
        
        offstdSp.setModel(new SpinnerNumberModel(chip.getSigmaOffDeviation() * 100, 
                0, 100, 1));
        
        ltSp.setModel(new SpinnerNumberModel(20, 
                0, 255, 1));
        
        expSp.setModel(new SpinnerNumberModel(1, 
                0, 255, 1));
        
        bgSp.setModel(new SpinnerNumberModel(10, 
                0, 255, 1));
                
        revalidate();
    }

   /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        jPanel1 = new javax.swing.JPanel();
        onSl = new javax.swing.JSlider();
        offSl = new javax.swing.JSlider();
        jLabel7 = new javax.swing.JLabel();
        jLabel8 = new javax.swing.JLabel();
        offSp = new javax.swing.JSpinner();
        onSp = new javax.swing.JSpinner();
        onstdSp = new javax.swing.JSpinner();
        offstdSp = new javax.swing.JSpinner();
        jLabel9 = new javax.swing.JLabel();
        jLabel14 = new javax.swing.JLabel();
        jPanel2 = new javax.swing.JPanel();
        gcCB = new javax.swing.JCheckBox();
        jLabel15 = new javax.swing.JLabel();
        jLabel16 = new javax.swing.JLabel();
        lcCB = new javax.swing.JCheckBox();
        jLabel18 = new javax.swing.JLabel();
        itCB = new javax.swing.JCheckBox();
        jPanel3 = new javax.swing.JPanel();
        jLabel19 = new javax.swing.JLabel();
        bgSp = new javax.swing.JSpinner();
        jPanel5 = new javax.swing.JPanel();
        ltSp = new javax.swing.JSpinner();
        expSp = new javax.swing.JSpinner();
        jLabel20 = new javax.swing.JLabel();
        jLabel21 = new javax.swing.JLabel();

        setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Model"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        setMinimumSize(new java.awt.Dimension(300, 400));
        setPreferredSize(new java.awt.Dimension(300, 400));
        setLayout(new javax.swing.BoxLayout(this, javax.swing.BoxLayout.Y_AXIS));

        jPanel1.setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Thresholds"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        jPanel1.setMinimumSize(new java.awt.Dimension(300, 150));
        jPanel1.setPreferredSize(new java.awt.Dimension(300, 150));
        jPanel1.setLayout(new java.awt.GridBagLayout());

        onSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                onSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel1.add(onSl, gridBagConstraints);

        offSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                offSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel1.add(offSl, gridBagConstraints);

        jLabel7.setText("ON std (%)");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        jPanel1.add(jLabel7, gridBagConstraints);

        jLabel8.setText("OFF");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        jPanel1.add(jLabel8, gridBagConstraints);

        offSp.setToolTipText("CL eye exposure value (0-511)");
        offSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                offSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 2;
        jPanel1.add(offSp, gridBagConstraints);

        onSp.setToolTipText("CL eye exposure value (0-511)");
        onSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                onSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        jPanel1.add(onSp, gridBagConstraints);

        onstdSp.setToolTipText("CL eye exposure value (0-511)");
        onstdSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                onstdSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel1.add(onstdSp, gridBagConstraints);

        offstdSp.setToolTipText("CL eye exposure value (0-511)");
        offstdSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                offstdSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 3;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel1.add(offstdSp, gridBagConstraints);

        jLabel9.setText("ON");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        jPanel1.add(jLabel9, gridBagConstraints);

        jLabel14.setText("OFF std (%)");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 3;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        jPanel1.add(jLabel14, gridBagConstraints);

        add(jPanel1);

        jPanel2.setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Transforms"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        jPanel2.setMinimumSize(new java.awt.Dimension(300, 100));
        jPanel2.setPreferredSize(new java.awt.Dimension(300, 100));
        jPanel2.setLayout(new java.awt.GridBagLayout());

        gcCB.setText("Auto");
        gcCB.setToolTipText("Enables AGC");
        gcCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                gcCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel2.add(gcCB, gridBagConstraints);

        jLabel15.setText("Gamma Correction");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        gridBagConstraints.weightx = 1.0;
        jPanel2.add(jLabel15, gridBagConstraints);

        jLabel16.setText("Lens Correction");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        gridBagConstraints.weightx = 1.0;
        jPanel2.add(jLabel16, gridBagConstraints);

        lcCB.setText("Auto");
        lcCB.setToolTipText("Enables AGC");
        lcCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                lcCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel2.add(lcCB, gridBagConstraints);

        jLabel18.setText("Interpolate Timestamps");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        gridBagConstraints.weightx = 1.0;
        jPanel2.add(jLabel18, gridBagConstraints);

        itCB.setText("Auto");
        itCB.setToolTipText("Enables AGC");
        itCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                itCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel2.add(itCB, gridBagConstraints);

        add(jPanel2);

        jPanel3.setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Noise"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        jPanel3.setMinimumSize(new java.awt.Dimension(300, 50));
        jPanel3.setPreferredSize(new java.awt.Dimension(300, 50));
        jPanel3.setLayout(new java.awt.GridBagLayout());

        jLabel19.setHorizontalAlignment(javax.swing.SwingConstants.RIGHT);
        jLabel19.setText("Background Rate (Hz)");
        jLabel19.setAlignmentY(0.0F);
        jLabel19.setMaximumSize(null);
        jLabel19.setMinimumSize(null);
        jLabel19.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        gridBagConstraints.weightx = 1.0;
        jPanel3.add(jLabel19, gridBagConstraints);

        bgSp.setToolTipText("CL eye exposure value (0-511)");
        bgSp.setMaximumSize(null);
        bgSp.setMinimumSize(null);
        bgSp.setPreferredSize(null);
        bgSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                bgSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        jPanel3.add(bgSp, gridBagConstraints);

        add(jPanel3);

        jPanel5.setBorder(javax.swing.BorderFactory.createCompoundBorder(javax.swing.BorderFactory.createTitledBorder("Log-Linear Settings"), javax.swing.BorderFactory.createEmptyBorder(5, 5, 5, 5)));
        jPanel5.setMaximumSize(null);
        jPanel5.setMinimumSize(new java.awt.Dimension(300, 100));
        jPanel5.setPreferredSize(new java.awt.Dimension(300, 100));
        jPanel5.setLayout(new java.awt.GridBagLayout());

        ltSp.setToolTipText("CL eye exposure value (0-511)");
        ltSp.setMaximumSize(null);
        ltSp.setMinimumSize(null);
        ltSp.setPreferredSize(null);
        ltSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                ltSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        jPanel5.add(ltSp, gridBagConstraints);

        expSp.setToolTipText("CL eye exposure value (0-511)");
        expSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                expSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        jPanel5.add(expSp, gridBagConstraints);

        jLabel20.setText("Threshold");
        jLabel20.setMaximumSize(null);
        jLabel20.setMinimumSize(null);
        jLabel20.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        gridBagConstraints.weightx = 1.0;
        jPanel5.add(jLabel20, gridBagConstraints);

        jLabel21.setText("Exp Weighting");
        jLabel21.setMaximumSize(null);
        jLabel21.setMinimumSize(null);
        jLabel21.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipady = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_START;
        jPanel5.add(jLabel21, gridBagConstraints);

        add(jPanel5);
    }// </editor-fold>//GEN-END:initComponents

    private void bgSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_bgSpStateChanged

    }//GEN-LAST:event_bgSpStateChanged

    private void onSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_onSlStateChanged
        if (onSl.getValue() != (int) Math.floor(chip.getSigmaOnThreshold() / chip.getMinSigmaOn())) {
            chip.setSigmaOnThreshold(onSl.getValue() * chip.getMinSigmaOn());
        }
    }//GEN-LAST:event_onSlStateChanged

    private void offSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_offSlStateChanged
        if (offSl.getValue() != (int) Math.floor(chip.getSigmaOffThreshold() / chip.getMinSigmaOff())) {
            chip.setSigmaOffThreshold(offSl.getValue() * chip.getMinSigmaOff());
        }
    }//GEN-LAST:event_offSlStateChanged

    private void offSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_offSpStateChanged
        chip.setSigmaOffThreshold((Double) offSp.getValue());
    }//GEN-LAST:event_offSpStateChanged

    private void onSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_onSpStateChanged
        chip.setSigmaOnThreshold((Double) onSp.getValue());
    }//GEN-LAST:event_onSpStateChanged

    private void onstdSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_onstdSpStateChanged
        chip.setSigmaOnDeviation((Double) onstdSp.getValue() / 100.0);
    }//GEN-LAST:event_onstdSpStateChanged

    private void offstdSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_offstdSpStateChanged
        chip.setSigmaOffDeviation((Double) offstdSp.getValue() / 100.0);
    }//GEN-LAST:event_offstdSpStateChanged

    private void gcCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_gcCBActionPerformed

    }//GEN-LAST:event_gcCBActionPerformed

    private void lcCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_lcCBActionPerformed
        // TODO add your handling code here:
    }//GEN-LAST:event_lcCBActionPerformed

    private void ltSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_ltSpStateChanged
        // TODO add your handling code here:
    }//GEN-LAST:event_ltSpStateChanged

    private void itCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_itCBActionPerformed
        // TODO add your handling code here:
    }//GEN-LAST:event_itCBActionPerformed

    private void expSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_expSpStateChanged
        // TODO add your handling code here:
    }//GEN-LAST:event_expSpStateChanged

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JSpinner bgSp;
    private javax.swing.JSpinner expSp;
    private javax.swing.JCheckBox gcCB;
    private javax.swing.JCheckBox itCB;
    private javax.swing.JLabel jLabel14;
    private javax.swing.JLabel jLabel15;
    private javax.swing.JLabel jLabel16;
    private javax.swing.JLabel jLabel18;
    private javax.swing.JLabel jLabel19;
    private javax.swing.JLabel jLabel20;
    private javax.swing.JLabel jLabel21;
    private javax.swing.JLabel jLabel7;
    private javax.swing.JLabel jLabel8;
    private javax.swing.JLabel jLabel9;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel5;
    private javax.swing.JCheckBox lcCB;
    private javax.swing.JSpinner ltSp;
    private javax.swing.JSlider offSl;
    private javax.swing.JSpinner offSp;
    private javax.swing.JSpinner offstdSp;
    private javax.swing.JSlider onSl;
    private javax.swing.JSpinner onSp;
    private javax.swing.JSpinner onstdSp;
    // End of variables declaration//GEN-END:variables

    /**
     * @return the driver
     */
    public PSEyeModelDVS getChip() {
        return chip;
    }

    /**
     * @param driver the driver to set
     */
    public void setChip(PSEyeModelDVS chip) {
        this.chip = chip;
    }

    @Override
    public void update(Observable o, Object arg) {
        if (o != null && o == chip && arg instanceof PSEyeModelDVS.EVENT_MODEL) {
            // update all components and models just in case
            setComponents();
        }
    }
}
