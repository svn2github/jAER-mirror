/*

 * Created on September 15, 2002, 8:08 PM

 */
package net.sf.jaer.graphics;
import net.sf.jaer.util.browser.BrowserLauncher;
import java.awt.Cursor;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.Enumeration;
import java.util.Properties;
import java.util.logging.Logger;
import javax.swing.JOptionPane;
/**
 * The About dialog.  It displays About information and latest SVN commit and build dates.
 * The version information file is updated by the project build.xml.
 *
 * @author tobi
 */
public class AEViewerAboutDialog extends javax.swing.JDialog {
    public final static String VERSION_FILE="BUILDVERSION.txt";
    static Logger log=Logger.getLogger("About");

    /**
     * Creates new form AEViewerAboutDialog
     */
    public AEViewerAboutDialog(java.awt.Frame parent, boolean modal) {
        super(parent, modal);
        initComponents();
        Properties props=new Properties();
        // when running from webstart  we are not allowed to open a file on the local file system, but we can
        // get a the contents of a resource, which in this case is the echo'ed date stamp written by ant on the last build
        String dateModified=null;
        ClassLoader cl=this.getClass().getClassLoader(); // get this class'es class loader
//        System.out.println("cl="+cl);
        log.info("Loading version info from resource "+VERSION_FILE);
        URL versionURL=cl.getResource(VERSION_FILE); // get a URL to the time stamp file
        log.info("Version URL="+versionURL);
        if(versionURL!=null) {
            try {
                Object urlContents=versionURL.getContent();
//            System.out.println("contents="+urlContents);
//            JOptionPane.showMessageDialog(parent,"urlContents="+urlContents);
                BufferedReader in=null;
                if(urlContents instanceof InputStream) {
                    props.load((InputStream) urlContents);
//                in=new BufferedReader(new InputStreamReader((InputStream)urlContents));
//            }else if(urlContents instanceof ZipFile){
//                ZipFile zf=(ZipFile)urlContents;
////                JOptionPane.showMessageDialog(parent,"zf="+zf);
////                JOptionPane.showMessageDialog(parent,zf.size()+" entries");
//                Enumeration en=zf.entries();
//                in=new BufferedReader(new InputStreamReader(.getInputStream()));
                }
//            if(in!=null) dateModified=in.readLine();
//            JOptionPane.showMessageDialog(parent,"dateModifed="+dateModified);
            } catch(Exception e) {
                e.printStackTrace();
                JOptionPane.showMessageDialog(parent, e);
            }
        } else {
            props.setProperty("version", "missing file "+VERSION_FILE+" in jAER.jar");
        }
        Enumeration e=props.propertyNames();
//        int n=props.size();
//        Object[][] tableContents=new Object[n][2];
//        int i=0;
        while(e.hasMoreElements()) {
            Object o=e.nextElement();
            if(o instanceof String) {
                String key=(String) o;
                String value=props.getProperty(key);
//                tableContents[i][0]=key;
//                tableContents[i++][1]=value;
                versionLabel.setText(versionLabel.getText()+"<center>"+key+" = "+value+"</center>");
            }
        }
//        String[] titles={"",""};
//        JTable table=new JTable(tableContents,titles);
//        versionPanel.add(table);
//        aboutLabel.setText(aboutLabel.getText() + "<center>" + props + "</center>");
        versionLabel.setText(versionLabel.getText());
        pack();
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        aboutLabel = new javax.swing.JLabel();
        versionLabel = new javax.swing.JLabel();
        okButton = new javax.swing.JButton();
        jaerProjectLinkLabel = new javax.swing.JLabel();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                closeDialog(evt);
            }
        });

        aboutLabel.setFont(new java.awt.Font("Tahoma", 0, 24)); // NOI18N
        aboutLabel.setText("<html> <center> <h1> jAER - Java tools for AER </h1> </center></html>");

        versionLabel.setText("<html>");

        okButton.setText("OK");
        okButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                okButtonActionPerformed(evt);
            }
        });

        jaerProjectLinkLabel.setFont(new java.awt.Font("Tahoma", 0, 18)); // NOI18N
        jaerProjectLinkLabel.setText("<html> <em><a href=\"http://jaer.sourceforge.net\">jaer.sourceforge.net</a> </em></html>");
        jaerProjectLinkLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                jaerProjectLinkLabelMouseClicked(evt);
            }
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                jaerProjectLinkLabelMouseEntered(evt);
            }
            public void mouseExited(java.awt.event.MouseEvent evt) {
                jaerProjectLinkLabelMouseExited(evt);
            }
        });

        org.jdesktop.layout.GroupLayout layout = new org.jdesktop.layout.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(org.jdesktop.layout.GroupLayout.TRAILING, layout.createSequentialGroup()
                .add(77, 77, 77)
                .add(jaerProjectLinkLabel)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, 225, Short.MAX_VALUE)
                .add(okButton)
                .addContainerGap())
            .add(layout.createSequentialGroup()
                .addContainerGap()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(layout.createSequentialGroup()
                        .add(versionLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 501, Short.MAX_VALUE)
                        .addContainerGap())
                    .add(layout.createSequentialGroup()
                        .add(aboutLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 344, Short.MAX_VALUE)
                        .add(167, 167, 167))))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(layout.createSequentialGroup()
                .addContainerGap()
                .add(aboutLabel)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.UNRELATED)
                .add(versionLabel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 107, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, 49, Short.MAX_VALUE)
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                    .add(okButton)
                    .add(jaerProjectLinkLabel))
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void okButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_okButtonActionPerformed
        dispose();
    // Add your handling code here:
    }//GEN-LAST:event_okButtonActionPerformed

    /** Closes the dialog */
    private void closeDialog(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_closeDialog
        setVisible(false);
        dispose();
    }//GEN-LAST:event_closeDialog

private void jaerProjectLinkLabelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_jaerProjectLinkLabelMouseClicked
    try {
        BrowserLauncher.openURL(AEViewer.HELP_URL_USER_GUIDE);
        setCursor(Cursor.getDefaultCursor());
    } catch(IOException e) {
        log.warning(e.toString());
    }

}//GEN-LAST:event_jaerProjectLinkLabelMouseClicked

private void jaerProjectLinkLabelMouseEntered(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_jaerProjectLinkLabelMouseEntered
    setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
}//GEN-LAST:event_jaerProjectLinkLabelMouseEntered

private void jaerProjectLinkLabelMouseExited(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_jaerProjectLinkLabelMouseExited
    setCursor(Cursor.getDefaultCursor());
}//GEN-LAST:event_jaerProjectLinkLabelMouseExited
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        new AEViewerAboutDialog(new javax.swing.JFrame(), true).setVisible(true);
    }
    
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel aboutLabel;
    private javax.swing.JLabel jaerProjectLinkLabel;
    private javax.swing.JButton okButton;
    private javax.swing.JLabel versionLabel;
    // End of variables declaration//GEN-END:variables
    
}
