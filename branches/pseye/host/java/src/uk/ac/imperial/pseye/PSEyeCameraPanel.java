/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * PSEyeCameraPanel.java
 *
 * Created on 11-May-2012, 12:54:58
 */
package uk.ac.imperial.pseye;

import java.awt.BorderLayout;
import uk.ac.imperial.vsbe.CameraFramePanel;

/**
 *
 * @author mlk11
 */
public class PSEyeCameraPanel extends javax.swing.JPanel {
    PSEyeModelAEChip chip = null;
    PSEyeControlPanel controlPanel = null;
    CameraFramePanel framePanel = null;
    
    /** Creates new form PSEyeCameraPanel */
    public PSEyeCameraPanel(PSEyeModelAEChip chip) {
        this.chip = chip;
        initComponents(); 
        controlPanel = new PSEyeControlPanel(chip);
        add(controlPanel, BorderLayout.LINE_START);
        framePanel = new CameraFramePanel(chip.camera);
        add(framePanel, BorderLayout.LINE_END);
        revalidate();
    }
    
    public void reload() {
        remove(framePanel);
        framePanel = new CameraFramePanel(chip.camera);
        add(framePanel);
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

        setLayout(new java.awt.BorderLayout());
    }// </editor-fold>//GEN-END:initComponents
    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables
}
