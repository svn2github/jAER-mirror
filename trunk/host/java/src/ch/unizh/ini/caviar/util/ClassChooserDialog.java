/*
 * NewOkCancelDialog.java
 *
 * Created on May 13, 2007, 3:52 PM - From netbeans template
 */

package ch.unizh.ini.caviar.util;

import ch.unizh.ini.caviar.chip.AEChip;
import java.awt.BorderLayout;
import java.awt.Frame;
import java.awt.Window;
import java.util.ArrayList;
import java.util.Arrays;

/**
 * A modal dialog that shows a list of source classes (found from the classpath) and a list of String names of classes and lets
 the user shuffle them from one side to the other and reorder the chosen class names. 
 Use it by contructing a new instance, making it visible, and then calling <code>getReturnValue()</code>; this call will magically block until
 the user presses OK or Cancel.
 
 * @author  tobi
 */
public class ClassChooserDialog extends javax.swing.JDialog {
    /** A return status code - returned if Cancel button has been pressed */
    public static final int RET_CANCEL = 0;
    /** A return status code - returned if OK button has been pressed */
    public static final int RET_OK = 1;
      
    private ClassChooserPanel chooserPanel;
    
    /** Creates new form NewOkCancelDialog
     @param subclassOf a Class that will be used to search the classpath for leaf nodes of this type.
     @param classNames a list of names
     */
    public ClassChooserDialog(Frame parent, Class subclassOf, ArrayList<String> classNames) {
        super(parent, true);
        initComponents();
        chooserPanel=new ClassChooserPanel(AEChip.class,classNames);
        businessPanel.add(chooserPanel,BorderLayout.CENTER);
        pack();
    }
    
    /** @return the return status of this dialog - one of RET_OK or RET_CANCEL */
    public int getReturnStatus() {
        return returnStatus;
    }
    
    public ArrayList<String> getList(){
        if(returnStatus==RET_CANCEL) return null;
        Object[] oa=chooserPanel.listModel.toArray();
        ArrayList<String> ret=new ArrayList(Arrays.asList(oa));
        return ret;
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc=" Generated Code ">//GEN-BEGIN:initComponents
    private void initComponents() {
        okButton = new javax.swing.JButton();
        cancelButton = new javax.swing.JButton();
        businessPanel = new javax.swing.JPanel();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setTitle("ClassChooser");
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                closeDialog(evt);
            }
        });

        okButton.setText("OK");
        okButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                okButtonActionPerformed(evt);
            }
        });

        cancelButton.setText("Cancel");
        cancelButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cancelButtonActionPerformed(evt);
            }
        });

        businessPanel.setLayout(new java.awt.BorderLayout());

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                        .addComponent(okButton, javax.swing.GroupLayout.PREFERRED_SIZE, 67, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(cancelButton))
                    .addComponent(businessPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 380, Short.MAX_VALUE))
                .addContainerGap())
        );

        layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {cancelButton, okButton});

        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(businessPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 249, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(cancelButton)
                    .addComponent(okButton))
                .addContainerGap())
        );
        pack();
    }// </editor-fold>//GEN-END:initComponents
    
    private void okButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_okButtonActionPerformed
        doClose(RET_OK);
    }//GEN-LAST:event_okButtonActionPerformed
    
    private void cancelButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cancelButtonActionPerformed
        doClose(RET_CANCEL);
    }//GEN-LAST:event_cancelButtonActionPerformed
    
    /** Closes the dialog */
    private void closeDialog(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_closeDialog
        doClose(RET_CANCEL);
    }//GEN-LAST:event_closeDialog
    
    private void doClose(int retStatus) {
        returnStatus = retStatus;
        setVisible(false);
        dispose();
    }
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                ArrayList<String> classNames=new ArrayList<String>();
                for(Class c:AEChip.CHIP_CLASSSES){
                    classNames.add(c.getName());
                }
                ClassChooserDialog dlg=new ClassChooserDialog(new javax.swing.JFrame(), AEChip.class,classNames);
                int ret;
                do{
                    dlg.setVisible(true);
                    ret=dlg.getReturnStatus();
                    System.out.println("ret="+ret);
                }while(ret!=ClassChooserDialog.RET_CANCEL);
                System.exit(0);
            }
        });
    }
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel businessPanel;
    private javax.swing.JButton cancelButton;
    private javax.swing.JButton okButton;
    // End of variables declaration//GEN-END:variables
    
    private int returnStatus = RET_CANCEL;
}
