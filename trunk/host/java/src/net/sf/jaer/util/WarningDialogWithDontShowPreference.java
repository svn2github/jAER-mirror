/*
 * WarningDialogWithDontShowPreference.java
 *
 * Created on October 2, 2008, 5:31 PM
 */
package net.sf.jaer.util;
import java.awt.Component;
import java.awt.HeadlessException;
import java.util.prefs.Preferences;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JOptionPane;
/**
 * A warning dialog with a check box to let users choose to not show the warning in the future.
 * 
 * @author  tobi
 */
public class WarningDialogWithDontShowPreference extends javax.swing.JDialog {
    Preferences prefs=Preferences.userNodeForPackage(WarningDialogWithDontShowPreference.class);
    /** A return status code - returned if Cancel button has been pressed */
    public static final int RET_CANCEL=0;
    /** A return status code - returned if OK button has been pressed */
    public static final int RET_OK=1;

    private String key="WarningDialogWithDontShowPreference";

    ImageIcon imageIcon;


    /** Creates new form WarningDialogWithDontShowPreference */
    public WarningDialogWithDontShowPreference(java.awt.Frame parent, boolean modal) {
        super(parent, modal);
        initComponents();
    }

    /** Creates new form WarningDialogWithDontShowPreference */
    public WarningDialogWithDontShowPreference(java.awt.Frame parent, boolean modal, String title, String text) {
        super(parent, modal);
        initComponents();
        optionPane.setMessage(text);
        key=title;
        setTitle(title);
        validate();
        pack();
   }

   /** @return the return status of this dialog - one of RET_OK or RET_CANCEL */
    public Object getValue (){
        dispose();
        return optionPane.getValue();
    }

    @Override
    public void setVisible(boolean b) {
        if(isWarningDisabled()) return;
        super.setVisible(b);
    }
    
    /** returns true if user has disabled this warning */
    public boolean isWarningDisabled(){
        if(prefs.get(prefsKey(),null)==null){
            return false;
        }else{
            return prefs.getBoolean(prefsKey(),false);
        }
    }
    
    private String prefsKey() {
        String s=key;
        if(s.length()>20) {
            s=s.substring(0, 20);
        }
        return "WarningDialogWithDontShowPreference."+s;
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        iconPanel = new javax.swing.JPanel();
        optionPane = new javax.swing.JOptionPane();
        dontShowAgainCheckBox = new javax.swing.JCheckBox();

        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                closeDialog(evt);
            }
        });

        iconPanel.setLayout(new java.awt.BorderLayout());
        iconPanel.add(optionPane, java.awt.BorderLayout.CENTER);

        dontShowAgainCheckBox.setText("Don't show again");
        dontShowAgainCheckBox.setToolTipText("Select to supress this warning");
        dontShowAgainCheckBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                dontShowAgainCheckBoxActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(dontShowAgainCheckBox)
                .addContainerGap(328, Short.MAX_VALUE))
            .addComponent(iconPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 435, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addComponent(iconPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 108, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(dontShowAgainCheckBox))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    /** Closes the dialog */
    private void closeDialog(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_closeDialog
        doClose(RET_CANCEL);
    }//GEN-LAST:event_closeDialog

private void dontShowAgainCheckBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_dontShowAgainCheckBoxActionPerformed
    prefs.putBoolean(prefsKey(),dontShowAgainCheckBox.isSelected());
}//GEN-LAST:event_dontShowAgainCheckBoxActionPerformed

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
                WarningDialogWithDontShowPreference dialog = new WarningDialogWithDontShowPreference(new javax.swing.JFrame(), true, "Test Warning", "<html>This is a <p>test warning message</html>");
                dialog.addWindowListener(new java.awt.event.WindowAdapter() {
                    public void windowClosing(java.awt.event.WindowEvent e) {
                        System.exit(0);
                    }
                });
                dialog.setVisible(true);
                if(dialog.isWarningDisabled()) System.exit(0);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JCheckBox dontShowAgainCheckBox;
    private javax.swing.JPanel iconPanel;
    private javax.swing.JOptionPane optionPane;
    // End of variables declaration//GEN-END:variables

    private int returnStatus = RET_CANCEL;
}
