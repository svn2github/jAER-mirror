
package ch.unizh.ini.jaer.projects.bjoernbeyer.stimulusdisplay;

import java.awt.Dimension;

/**
 *
 * @author Bjoern */
public class ScreenActionCanvas extends javax.swing.JFrame {
    public ScreenActionCanvas() {
        initComponents();
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        addComponentListener(new java.awt.event.ComponentAdapter() {
            public void componentResized(java.awt.event.ComponentEvent evt) {
                formComponentResized(evt);
            }
        });
        addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyPressed(java.awt.event.KeyEvent evt) {
                formKeyPressed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 400, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 298, Short.MAX_VALUE)
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void formKeyPressed(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_formKeyPressed
        int oldValue = 0; // THIS IS A COMPLETE AND UTTER HACK... couldnt think of something better though
        // we are missusing the 'oldvalue' as a check for shift. As propertychange only takes integeres we cant send the whole keyevent
        if(evt.isShiftDown()) oldValue = 1;
        firePropertyChange("key",oldValue,evt.getKeyCode());
    }//GEN-LAST:event_formKeyPressed

    private void formComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_formComponentResized
        //We want the Panel to have odd dimension such that the calibration 
        // points are centered around the true middlepoint.
        if((getWidth() % 2) == 0){
            setSize(new Dimension(getWidth()-1,getHeight()));
        }
        if((getHeight() % 2) == 0){
            setSize(new Dimension(getWidth(),getHeight()-1));
        }
        firePropertyChange("size", null, new float[] {getWidth(),getHeight()});
    }//GEN-LAST:event_formComponentResized

    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables
}