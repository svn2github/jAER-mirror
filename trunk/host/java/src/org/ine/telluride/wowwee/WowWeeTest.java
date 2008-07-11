/*
 * WowWeeTest.java
 *
 * Created on July 16, 2007, 4:26 PM
 */
package org.ine.telluride.wowwee;
import ch.unizh.ini.caviar.hardwareinterface.*;
import ch.unizh.ini.caviar.util.HexString;
import java.lang.reflect.Field;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.logging.Logger;
/**
 * Tests WowWeee codes by sending the 12 bit numbers to the WowWeeRSHardwareInterface.
Telluride 2007.
 * @author  tobi
 */
public class WowWeeTest extends javax.swing.JFrame {
    WowWeeRSHardwareInterface hw;
    short lastCode=0;
    static Logger log=Logger.getLogger("WowWeeTest");
    ArrayList<Integer> commands=new ArrayList<Integer>();

    /** Creates new form WowWeeTest */
    public WowWeeTest() {
        initComponents();
        setTitle("WowWee Test");
        try {
            Field[] commandFields=RoboQuadCommands.class.getFields();
            commandComboBox.removeAllItems();
            for(Field f : commandFields) {
                commandComboBox.addItem(f.getName());
                commands.add((Integer) f.getInt(f));
            }
            commandComboBox.setMaximumRowCount(30);
        } catch(Exception e) {
            log.warning(e.toString());
        }
    }

    void checkHardware() {
        if(hw==null) {
            hw=new WowWeeRSHardwareInterface();
        }
        try {
            if(!hw.isOpen()) {
                hw.open();
            }
            statusField.setText("communication OK");
        } catch(HardwareInterfaceException e) {
            e.printStackTrace();
            statusField.setText(e.getMessage());
        }
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jTextField2 = new javax.swing.JTextField();
        jPanel1 = new javax.swing.JPanel();
        jLabel1 = new javax.swing.JLabel();
        codeField = new javax.swing.JTextField();
        jPanel2 = new javax.swing.JPanel();
        statusField = new javax.swing.JTextField();
        sendCommandButton = new javax.swing.JButton();
        commandComboBox = new javax.swing.JComboBox();
        stopButton = new javax.swing.JButton();
        menuBar = new javax.swing.JMenuBar();
        fileMenu = new javax.swing.JMenu();
        exitMenuItem = new javax.swing.JMenuItem();

        jTextField2.setText("jTextField2");

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        jLabel1.setText("wowwee code");

        codeField.setColumns(10);
        codeField.setToolTipText("hex value sent out as 12 bit wowwee code when enter is pressed");
        codeField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                codeFieldActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jLabel1)
                .addGap(13, 13, 13)
                .addComponent(codeField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(codeField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel1))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(statusField, javax.swing.GroupLayout.DEFAULT_SIZE, 589, Short.MAX_VALUE)
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(statusField, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 31, Short.MAX_VALUE)
        );

        sendCommandButton.setText("Send");
        sendCommandButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendCommandButtonActionPerformed(evt);
            }
        });

        commandComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        commandComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                commandComboBoxActionPerformed(evt);
            }
        });

        stopButton.setText("Stop");
        stopButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                stopButtonActionPerformed(evt);
            }
        });

        fileMenu.setText("File");

        exitMenuItem.setText("Exit");
        exitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                exitMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(exitMenuItem);

        menuBar.add(fileMenu);

        setJMenuBar(menuBar);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 44, Short.MAX_VALUE)
                .addComponent(stopButton)
                .addGap(18, 18, 18)
                .addComponent(commandComboBox, javax.swing.GroupLayout.PREFERRED_SIZE, 183, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(35, 35, 35)
                .addComponent(sendCommandButton)
                .addContainerGap())
            .addComponent(jPanel2, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addGroup(layout.createSequentialGroup()
                        .addContainerGap()
                        .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                    .addGroup(layout.createSequentialGroup()
                        .addContainerGap()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(sendCommandButton)
                            .addComponent(commandComboBox, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(stopButton))
                        .addGap(18, 18, 18)))
                .addComponent(jPanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void codeFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_codeFieldActionPerformed
        try {
            lastCode=HexString.parseShort(codeField.getText());
        } catch(ParseException e) {
            codeField.selectAll();
            return;
        }
        sendCmd(lastCode);
        codeField.setText(HexString.toString(lastCode));
        codeField.selectAll();
    }//GEN-LAST:event_codeFieldActionPerformed

    private void sendCmd(int cmd) {
        try {
            checkHardware();
            if(hw!=null) {
                hw.sendWowWeeCmd((short) cmd);
            }
        } catch(Exception e) {
            statusField.setText(e.toString());
            log.warning(e.toString());
        }

    }
    private void exitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_exitMenuItemActionPerformed
        System.exit(0);
    }//GEN-LAST:event_exitMenuItemActionPerformed

private void sendCommandButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendCommandButtonActionPerformed
    sendCmd(commands.get(commandComboBox.getSelectedIndex()));
}//GEN-LAST:event_sendCommandButtonActionPerformed

private void commandComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_commandComboBoxActionPerformed
    sendCmd(commands.get(commandComboBox.getSelectedIndex()));
}//GEN-LAST:event_commandComboBoxActionPerformed

private void stopButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_stopButtonActionPerformed
    sendCmd(RoboQuadCommands.Stop);
}//GEN-LAST:event_stopButtonActionPerformed
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new WowWeeTest().setVisible(true);
            }
        });
    }
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JTextField codeField;
    private javax.swing.JComboBox commandComboBox;
    private javax.swing.JMenuItem exitMenuItem;
    private javax.swing.JMenu fileMenu;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JTextField jTextField2;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JButton sendCommandButton;
    private javax.swing.JTextField statusField;
    private javax.swing.JButton stopButton;
    // End of variables declaration//GEN-END:variables
    
}
