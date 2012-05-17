
package uk.ac.imperial.pseye;

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
public class PSEyeControlPanel extends JPanel implements Observer {

    private final static Logger log = Logger.getLogger("PSEyeControlPanel");
    public PSEyeDriverInterface driver;

    /* Create a control panel 
     * 
     * @param driver: the interface to observer and use to control the camera
     */
    public PSEyeControlPanel(PSEyeDriverInterface driver) {
        this.driver = driver;
        // create all panel components
        initComponents();
        
        // read current driver settings
        setComponents();
        
        // add this to the driver Observable
        driver.getObservable().addObserver(this);
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
        Object[] modes = driver.getModes().toArray();
        modeCB.setModel(new DefaultComboBoxModel(modes));
        modeCB.setSelectedItem(driver.getMode());
        modeCB.setEnabled(modes.length > 1);
        
        Object[] resolutions = driver.getResolutions().toArray();
        resCB.setModel(new DefaultComboBoxModel(resolutions));
        resCB.setEnabled(resolutions.length > 1);
        resCB.setSelectedItem(driver.getResolution());
        
        Object[] frameRates = driver.getFrameRates().toArray();
        rateCB.setModel(new DefaultComboBoxModel(frameRates));
        rateCB.setEnabled(frameRates.length > 1);
        rateCB.setSelectedItem(driver.getFrameRate());
        
        agCB.setSelected(driver.getAutoGain());
        aeCB.setSelected(driver.getAutoExposure());
        abCB.setSelected(driver.getAutoBalance());
        
        Hashtable labelTable = null;
        
        expSl.setMinimum(driver.getMinExposure());
        expSl.setMaximum(driver.getMaxExposure());
        expSl.setValue(driver.getExposure());
        labelTable = new Hashtable();
        labelTable.put(driver.getMinExposure(), new JLabel(Integer.toString(driver.getMinExposure())));
        labelTable.put(driver.getMaxExposure(), new JLabel(Integer.toString(driver.getMaxExposure())));
        expSl.setLabelTable(labelTable);
        expSl.setPaintLabels(true);
        expSl.setEnabled(!aeCB.isSelected());
        
        expSp.setModel(new SpinnerNumberModel(driver.getExposure(), 
                driver.getMinExposure(), driver.getMaxExposure(), 1));
        expSp.setValue(driver.getExposure());
        expSp.setEnabled(!aeCB.isSelected());
        
        gainSl.setMinimum(driver.getMinGain());
        gainSl.setMaximum(driver.getMaxGain());
        gainSl.setValue(driver.getGain());
        labelTable = new Hashtable();
        labelTable.put(driver.getMinGain(), new JLabel(Integer.toString(driver.getMinGain())));
        labelTable.put(driver.getMaxGain(), new JLabel(Integer.toString(driver.getMaxGain())));
        gainSl.setLabelTable(labelTable);
        gainSl.setPaintLabels(true);
        gainSl.setEnabled(!agCB.isSelected());
                
        gainSp.setModel(new SpinnerNumberModel(driver.getGain(), 
                driver.getMinGain(), driver.getMaxGain(), 1));
        gainSp.setValue(driver.getGain());
        gainSp.setEnabled(!agCB.isSelected());
        
        rbSl.setMinimum(driver.getMinBalance());
        rbSl.setMaximum(driver.getMaxBalance());
        rbSl.setValue(driver.getRedBalance());
        labelTable = new Hashtable();
        labelTable.put(driver.getMinBalance(), new JLabel(Integer.toString(driver.getMinBalance())));
        labelTable.put(driver.getMaxBalance(), new JLabel(Integer.toString(driver.getMaxBalance())));
        rbSl.setLabelTable(labelTable);
        rbSl.setPaintLabels(true);
        rbSl.setEnabled(!abCB.isSelected());
                
        rbSp.setModel(new SpinnerNumberModel(driver.getRedBalance(), 
                driver.getMinBalance(), driver.getMaxBalance(), 1));
        rbSp.setValue(driver.getRedBalance());
        rbSp.setEnabled(!abCB.isSelected());
        
        gbSl.setMinimum(driver.getMinBalance());
        gbSl.setMaximum(driver.getMaxBalance());
        gbSl.setValue(driver.getGreenBalance());
        labelTable = new Hashtable();
        labelTable.put(driver.getMinBalance(), new JLabel(Integer.toString(driver.getMinBalance())));
        labelTable.put(driver.getMaxBalance(), new JLabel(Integer.toString(driver.getMaxBalance())));
        gbSl.setLabelTable(labelTable);
        gbSl.setPaintLabels(true);
        gbSl.setEnabled(!abCB.isSelected());
                
        gbSp.setModel(new SpinnerNumberModel(driver.getGreenBalance(), 
                driver.getMinBalance(), driver.getMaxBalance(), 1));
        gbSp.setValue(driver.getGreenBalance());
        gbSp.setEnabled(!abCB.isSelected());
        
        bbSl.setMinimum(driver.getMinBalance());
        bbSl.setMaximum(driver.getMaxBalance());
        bbSl.setValue(driver.getBlueBalance());
        labelTable = new Hashtable();
        labelTable.put(driver.getMinBalance(), new JLabel(Integer.toString(driver.getMinBalance())));
        labelTable.put(driver.getMaxBalance(), new JLabel(Integer.toString(driver.getMaxBalance())));
        bbSl.setLabelTable(labelTable);
        bbSl.setPaintLabels(true);
        bbSl.setEnabled(!abCB.isSelected());
                
        bbSp.setModel(new SpinnerNumberModel(driver.getBlueBalance(), 
                driver.getMinBalance(), driver.getMaxBalance(), 1));
        bbSp.setValue(driver.getBlueBalance());
        bbSp.setEnabled(!abCB.isSelected());
        
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
        rbSl = new javax.swing.JSlider();
        gbSl = new javax.swing.JSlider();
        bbSl = new javax.swing.JSlider();
        jLabel7 = new javax.swing.JLabel();
        jLabel8 = new javax.swing.JLabel();
        jLabel9 = new javax.swing.JLabel();
        rbSp = new javax.swing.JSpinner();
        abCB = new javax.swing.JCheckBox();
        gbSp = new javax.swing.JSpinner();
        bbSp = new javax.swing.JSpinner();
        jPanel2 = new javax.swing.JPanel();
        gainSl = new javax.swing.JSlider();
        gainSp = new javax.swing.JSpinner();
        agCB = new javax.swing.JCheckBox();
        jLabel10 = new javax.swing.JLabel();
        jPanel3 = new javax.swing.JPanel();
        expSl = new javax.swing.JSlider();
        expSp = new javax.swing.JSpinner();
        aeCB = new javax.swing.JCheckBox();
        jLabel12 = new javax.swing.JLabel();
        jPanel4 = new javax.swing.JPanel();
        modeCB = new javax.swing.JComboBox();
        jLabel6 = new javax.swing.JLabel();
        jLabel11 = new javax.swing.JLabel();
        jLabel13 = new javax.swing.JLabel();
        rateCB = new javax.swing.JComboBox();
        resCB = new javax.swing.JComboBox();

        setBorder(javax.swing.BorderFactory.createTitledBorder("PS Eye Control"));
        setLayout(new java.awt.GridBagLayout());

        jPanel1.setBorder(javax.swing.BorderFactory.createTitledBorder("Colour Balance"));
        jPanel1.setLayout(new java.awt.GridBagLayout());

        rbSl.setPaintTicks(true);
        rbSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                rbSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel1.add(rbSl, gridBagConstraints);

        gbSl.setPaintTicks(true);
        gbSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                gbSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel1.add(gbSl, gridBagConstraints);

        bbSl.setPaintTicks(true);
        bbSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                bbSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel1.add(bbSl, gridBagConstraints);

        jLabel7.setText("R");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel1.add(jLabel7, gridBagConstraints);

        jLabel8.setText("G");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel1.add(jLabel8, gridBagConstraints);

        jLabel9.setText("B");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel1.add(jLabel9, gridBagConstraints);

        rbSp.setToolTipText("CL eye exposure value (0-511)");
        rbSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                rbSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new java.awt.Insets(0, 10, 0, 10);
        jPanel1.add(rbSp, gridBagConstraints);

        abCB.setText("Auto");
        abCB.setToolTipText("Enables automatic exposure control");
        abCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                abCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 1;
        jPanel1.add(abCB, gridBagConstraints);

        gbSp.setToolTipText("CL eye exposure value (0-511)");
        gbSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                gbSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.insets = new java.awt.Insets(0, 10, 0, 10);
        jPanel1.add(gbSp, gridBagConstraints);

        bbSp.setToolTipText("CL eye exposure value (0-511)");
        bbSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                bbSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.insets = new java.awt.Insets(0, 10, 0, 10);
        jPanel1.add(bbSp, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 3;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.ipadx = 5;
        gridBagConstraints.ipady = 5;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        add(jPanel1, gridBagConstraints);

        jPanel2.setBorder(javax.swing.BorderFactory.createTitledBorder("Gain"));
        jPanel2.setLayout(new java.awt.GridBagLayout());

        gainSl.setPaintTicks(true);
        gainSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                gainSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel2.add(gainSl, gridBagConstraints);

        gainSp.setToolTipText("CL eye gain (0-79)");
        gainSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                gainSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new java.awt.Insets(0, 10, 0, 10);
        jPanel2.add(gainSp, gridBagConstraints);

        agCB.setText("Auto");
        agCB.setToolTipText("Enables AGC");
        agCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                agCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 0;
        jPanel2.add(agCB, gridBagConstraints);

        jLabel10.setText(" ");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel2.add(jLabel10, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.ipadx = 5;
        gridBagConstraints.ipady = 5;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        add(jPanel2, gridBagConstraints);

        jPanel3.setBorder(javax.swing.BorderFactory.createTitledBorder("Exposure"));
        jPanel3.setLayout(new java.awt.GridBagLayout());

        expSl.setPaintTicks(true);
        expSl.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                expSlStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        jPanel3.add(expSl, gridBagConstraints);

        expSp.setToolTipText("CL eye exposure value (0-511)");
        expSp.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                expSpStateChanged(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new java.awt.Insets(0, 10, 0, 10);
        jPanel3.add(expSp, gridBagConstraints);

        aeCB.setText("Auto");
        aeCB.setToolTipText("Enables automatic exposure control");
        aeCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                aeCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 0;
        jPanel3.add(aeCB, gridBagConstraints);

        jLabel12.setText(" ");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.LINE_END;
        jPanel3.add(jLabel12, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.ipadx = 5;
        gridBagConstraints.ipady = 5;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        add(jPanel3, gridBagConstraints);

        jPanel4.setBorder(javax.swing.BorderFactory.createTitledBorder(""));
        jPanel4.setLayout(new java.awt.GridBagLayout());

        modeCB.setMaximumRowCount(30);
        modeCB.setMaximumSize(null);
        modeCB.setPreferredSize(null);
        modeCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                modeCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.WEST;
        gridBagConstraints.weightx = 1.0;
        jPanel4.add(modeCB, gridBagConstraints);

        jLabel6.setText("Mode");
        jLabel6.setMaximumSize(null);
        jLabel6.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        jPanel4.add(jLabel6, gridBagConstraints);

        jLabel11.setText("Resolution");
        jLabel11.setMaximumSize(null);
        jLabel11.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        jPanel4.add(jLabel11, gridBagConstraints);

        jLabel13.setText("Framerate");
        jLabel13.setMaximumSize(null);
        jLabel13.setPreferredSize(null);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipadx = 10;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        jPanel4.add(jLabel13, gridBagConstraints);

        rateCB.setMaximumRowCount(30);
        rateCB.setMaximumSize(null);
        rateCB.setPreferredSize(null);
        rateCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                rateCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.WEST;
        gridBagConstraints.weightx = 1.0;
        jPanel4.add(rateCB, gridBagConstraints);

        resCB.setMaximumRowCount(30);
        resCB.setMaximumSize(null);
        resCB.setPreferredSize(null);
        resCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                resCBActionPerformed(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.WEST;
        gridBagConstraints.weightx = 1.0;
        jPanel4.add(resCB, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.ipadx = 5;
        gridBagConstraints.ipady = 5;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        add(jPanel4, gridBagConstraints);
    }// </editor-fold>//GEN-END:initComponents

    private void aeCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aeCBActionPerformed
        driver.setAutoExposure(aeCB.isSelected());
        expSp.setEnabled(!aeCB.isSelected());
        expSl.setEnabled(!aeCB.isSelected());
    }//GEN-LAST:event_aeCBActionPerformed

    private void expSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_expSpStateChanged
        driver.setExposure((Integer) expSp.getValue());
    }//GEN-LAST:event_expSpStateChanged

    private void agCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_agCBActionPerformed
        driver.setAutoGain(agCB.isSelected());
        gainSp.setEnabled(!agCB.isSelected());
        gainSl.setEnabled(!agCB.isSelected());
    }//GEN-LAST:event_agCBActionPerformed

    private void gainSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_gainSpStateChanged
        driver.setGain((Integer) gainSp.getValue());
    }//GEN-LAST:event_gainSpStateChanged

    private void gainSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_gainSlStateChanged
        driver.setGain((Integer) gainSl.getValue());
    }//GEN-LAST:event_gainSlStateChanged

    private void bbSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_bbSpStateChanged
        driver.setBlueBalance((Integer) bbSp.getValue());
    }//GEN-LAST:event_bbSpStateChanged

    private void gbSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_gbSpStateChanged
        driver.setGreenBalance((Integer) gbSp.getValue());
    }//GEN-LAST:event_gbSpStateChanged

    private void abCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_abCBActionPerformed
        driver.setAutoBalance(abCB.isSelected());
        rbSp.setEnabled(!abCB.isSelected());
        gbSp.setEnabled(!abCB.isSelected());
        bbSp.setEnabled(!abCB.isSelected());
        rbSl.setEnabled(!abCB.isSelected());
        gbSl.setEnabled(!abCB.isSelected());
        bbSl.setEnabled(!abCB.isSelected());
    }//GEN-LAST:event_abCBActionPerformed

    private void rbSpStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_rbSpStateChanged
        driver.setRedBalance((Integer) rbSp.getValue());
    }//GEN-LAST:event_rbSpStateChanged

    private void resCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_resCBActionPerformed
        try {
            PSEyeDriverInterface.Resolution resolution = (PSEyeDriverInterface.Resolution) resCB.getSelectedItem();
            driver.setResolution(resolution);
        } catch (Exception e) {
            log.warning(e.toString());
        }
    }//GEN-LAST:event_resCBActionPerformed

    private void rateCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_rateCBActionPerformed
        try {
            int frameRate = (Integer) rateCB.getSelectedItem();
            driver.setFrameRate(frameRate);
        } catch (Exception e) {
            log.warning(e.toString());
        }   
    }//GEN-LAST:event_rateCBActionPerformed

    private void modeCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_modeCBActionPerformed
        try {
            PSEyeDriverInterface.Mode mode = (PSEyeDriverInterface.Mode) modeCB.getSelectedItem();
            driver.setMode(mode);
        } catch (Exception e) {
            log.warning(e.toString());
        }
    }//GEN-LAST:event_modeCBActionPerformed

    private void expSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_expSlStateChanged
        driver.setExposure((Integer) expSl.getValue());
    }//GEN-LAST:event_expSlStateChanged

    private void rbSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_rbSlStateChanged
        driver.setRedBalance((Integer) rbSl.getValue());
    }//GEN-LAST:event_rbSlStateChanged

    private void gbSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_gbSlStateChanged
        driver.setGreenBalance((Integer) gbSl.getValue());
    }//GEN-LAST:event_gbSlStateChanged

    private void bbSlStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_bbSlStateChanged
        driver.setBlueBalance((Integer) bbSl.getValue());
    }//GEN-LAST:event_bbSlStateChanged

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JCheckBox abCB;
    private javax.swing.JCheckBox aeCB;
    private javax.swing.JCheckBox agCB;
    private javax.swing.JSlider bbSl;
    private javax.swing.JSpinner bbSp;
    private javax.swing.JSlider expSl;
    private javax.swing.JSpinner expSp;
    private javax.swing.JSlider gainSl;
    private javax.swing.JSpinner gainSp;
    private javax.swing.JSlider gbSl;
    private javax.swing.JSpinner gbSp;
    private javax.swing.JLabel jLabel10;
    private javax.swing.JLabel jLabel11;
    private javax.swing.JLabel jLabel12;
    private javax.swing.JLabel jLabel13;
    private javax.swing.JLabel jLabel6;
    private javax.swing.JLabel jLabel7;
    private javax.swing.JLabel jLabel8;
    private javax.swing.JLabel jLabel9;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel4;
    private javax.swing.JComboBox modeCB;
    private javax.swing.JComboBox rateCB;
    private javax.swing.JSlider rbSl;
    private javax.swing.JSpinner rbSp;
    private javax.swing.JComboBox resCB;
    // End of variables declaration//GEN-END:variables

    /**
     * @return the driver
     */
    public PSEyeDriverInterface getDriver() {
        return driver;
    }

    /**
     * @param driver the driver to set
     */
    public void setDriver(PSEyeDriverInterface driver) {
        this.driver = driver;
    }

    @Override
    public void update(Observable o, Object arg) {
        if (o != null && o == driver && arg instanceof PSEyeDriverInterface.EVENT_CAMERA) {
            // update all components and models just in case
            setComponents();
        }
    }
}
