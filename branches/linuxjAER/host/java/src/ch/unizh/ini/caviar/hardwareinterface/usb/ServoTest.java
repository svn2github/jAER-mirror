/*
 * ServoTest.java
 *
 * Created on July 4, 2006, 3:47 PM
 */

package ch.unizh.ini.caviar.hardwareinterface.usb;

import ch.unizh.ini.caviar.hardwareinterface.*;
import ch.unizh.ini.caviar.hardwareinterface.HardwareInterfaceException;
import ch.unizh.ini.tobi.rccar.SiLabsC8051F320_USBIO_CarServoController;
import de.thesycon.usbio.*;
import de.thesycon.usbio.PnPNotify;
import de.thesycon.usbio.PnPNotifyInterface;
import java.util.*;
import java.util.logging.*;
import javax.swing.*;
import javax.swing.event.*;

/**
 * Tests the hardware USB  servo interface.
 * @author  tobi
 */
public class ServoTest extends javax.swing.JFrame implements PnPNotifyInterface {
    final int MAX_SLIDER=1000;
    static Logger log=Logger.getLogger("ServoTest");
    
    ServoInterface hwInterface=null;
    float[] servoValues;
    PnPNotify pnp=null;
    
    /** Creates new form ServoTest */
    public ServoTest() {
        initComponents();
        try{
            System.loadLibrary("USBIOJAVA");
            pnp=new PnPNotify(this);
            pnp.enablePnPNotification(SiLabsC8051F320_USBIO_ServoController.GUID);
            pnp.enablePnPNotification(SiLabsC8051F320_USBIO_ServoController.GUID);
        }catch(java.lang.UnsatisfiedLinkError e){
            log.warning("USBIOJAVA library not available, probably because you are not running under Windows, continuing anyhow");
        }
        
//        int navailable=SiLabsC8051F320Factory.instance().getNumInterfacesAvailable();
//        if(navailable==0){
//            System.err.println("no interfaces available");
//            System.exit(1);
//        }
    }
    
    /** Constructs a new controller panel using existing hardware interface
     * @param hw the interface
     */
    public ServoTest(ServoInterface hw){
        this();
        hwInterface=hw;
        String s=hw.getClass().getSimpleName();
        setTitle(s);
        servoTypeComboBox.addItem(s);
        int n=servoTypeComboBox.getItemCount();
        for(int i=0;i<servoTypeComboBox.getItemCount();i++){
            if(s==servoTypeComboBox.getItemAt(i)){
                servoTypeComboBox.setSelectedItem(i);
            }
        }
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc=" Generated Code ">//GEN-BEGIN:initComponents
    private void initComponents() {
        jButton1 = new javax.swing.JButton();
        servo0Panel = new javax.swing.JPanel();
        servo0Slider = new javax.swing.JSlider();
        disableServo0Button = new javax.swing.JButton();
        servo1Panel = new javax.swing.JPanel();
        servo1Slider = new javax.swing.JSlider();
        disableServo1Button = new javax.swing.JButton();
        syncPanel = new javax.swing.JPanel();
        synchronizeCheckBox = new javax.swing.JCheckBox();
        sendValuesButton = new javax.swing.JButton();
        disableButton = new javax.swing.JButton();
        servo2Panel = new javax.swing.JPanel();
        servo2Slider = new javax.swing.JSlider();
        disableServo2Button = new javax.swing.JButton();
        servo3Panel = new javax.swing.JPanel();
        servo3Slider = new javax.swing.JSlider();
        disableServo3Button = new javax.swing.JButton();
        servoTypeComboBox = new javax.swing.JComboBox();
        menuBar = new javax.swing.JMenuBar();
        fileMenu = new javax.swing.JMenu();
        exitMenuItem = new javax.swing.JMenuItem();

        jButton1.setText("jButton1");

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("ServoTest");
        servo0Panel.setBorder(javax.swing.BorderFactory.createTitledBorder("Servo 0"));
        servo0Slider.setMaximum(1000);
        servo0Slider.setMinorTickSpacing(10);
        servo0Slider.setValue(500);
        servo0Slider.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                servo0SliderStateChanged(evt);
            }
        });

        disableServo0Button.setText("Disable");
        disableServo0Button.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                disableServo0ButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout servo0PanelLayout = new org.jdesktop.layout.GroupLayout(servo0Panel);
        servo0Panel.setLayout(servo0PanelLayout);
        servo0PanelLayout.setHorizontalGroup(
            servo0PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo0PanelLayout.createSequentialGroup()
                .add(servo0PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(servo0Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(servo0PanelLayout.createSequentialGroup()
                        .add(69, 69, 69)
                        .add(disableServo0Button)))
                .addContainerGap(20, Short.MAX_VALUE))
        );
        servo0PanelLayout.setVerticalGroup(
            servo0PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo0PanelLayout.createSequentialGroup()
                .add(servo0Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(disableServo0Button))
        );

        servo1Panel.setBorder(javax.swing.BorderFactory.createTitledBorder("Servo 1"));
        servo1Slider.setMaximum(1000);
        servo1Slider.setMinorTickSpacing(10);
        servo1Slider.setValue(500);
        servo1Slider.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                servo1SliderStateChanged(evt);
            }
        });

        disableServo1Button.setText("Disable");
        disableServo1Button.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                disableServo1ButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout servo1PanelLayout = new org.jdesktop.layout.GroupLayout(servo1Panel);
        servo1Panel.setLayout(servo1PanelLayout);
        servo1PanelLayout.setHorizontalGroup(
            servo1PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo1PanelLayout.createSequentialGroup()
                .add(servo1PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(servo1Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(servo1PanelLayout.createSequentialGroup()
                        .add(69, 69, 69)
                        .add(disableServo1Button)))
                .addContainerGap(20, Short.MAX_VALUE))
        );
        servo1PanelLayout.setVerticalGroup(
            servo1PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo1PanelLayout.createSequentialGroup()
                .add(servo1Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(disableServo1Button))
        );

        synchronizeCheckBox.setText("Synchronize");
        synchronizeCheckBox.setBorder(javax.swing.BorderFactory.createEmptyBorder(0, 0, 0, 0));
        synchronizeCheckBox.setMargin(new java.awt.Insets(0, 0, 0, 0));

        sendValuesButton.setText("Send all values");
        sendValuesButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                sendValuesButtonActionPerformed(evt);
            }
        });

        disableButton.setText("Disable all");
        disableButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                disableButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout syncPanelLayout = new org.jdesktop.layout.GroupLayout(syncPanel);
        syncPanel.setLayout(syncPanelLayout);
        syncPanelLayout.setHorizontalGroup(
            syncPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(syncPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(synchronizeCheckBox)
                .add(21, 21, 21)
                .add(sendValuesButton)
                .add(14, 14, 14)
                .add(disableButton)
                .addContainerGap(org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        syncPanelLayout.setVerticalGroup(
            syncPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(syncPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(syncPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                    .add(synchronizeCheckBox)
                    .add(sendValuesButton)
                    .add(disableButton))
                .addContainerGap(org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );

        servo2Panel.setBorder(javax.swing.BorderFactory.createTitledBorder("Servo 2"));
        servo2Slider.setMaximum(1000);
        servo2Slider.setMinorTickSpacing(10);
        servo2Slider.setValue(500);
        servo2Slider.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                servo2SliderStateChanged(evt);
            }
        });

        disableServo2Button.setText("Disable");
        disableServo2Button.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                disableServo2ButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout servo2PanelLayout = new org.jdesktop.layout.GroupLayout(servo2Panel);
        servo2Panel.setLayout(servo2PanelLayout);
        servo2PanelLayout.setHorizontalGroup(
            servo2PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo2PanelLayout.createSequentialGroup()
                .add(servo2PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(servo2Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(servo2PanelLayout.createSequentialGroup()
                        .add(69, 69, 69)
                        .add(disableServo2Button)))
                .addContainerGap(36, Short.MAX_VALUE))
        );
        servo2PanelLayout.setVerticalGroup(
            servo2PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo2PanelLayout.createSequentialGroup()
                .add(servo2Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(disableServo2Button))
        );

        servo3Panel.setBorder(javax.swing.BorderFactory.createTitledBorder("Servo 3"));
        servo3Slider.setMaximum(1000);
        servo3Slider.setMinorTickSpacing(10);
        servo3Slider.setValue(500);
        servo3Slider.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                servo3SliderStateChanged(evt);
            }
        });

        disableServo3Button.setText("Disable");
        disableServo3Button.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                disableServo3ButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout servo3PanelLayout = new org.jdesktop.layout.GroupLayout(servo3Panel);
        servo3Panel.setLayout(servo3PanelLayout);
        servo3PanelLayout.setHorizontalGroup(
            servo3PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo3PanelLayout.createSequentialGroup()
                .add(servo3PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(servo3Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(servo3PanelLayout.createSequentialGroup()
                        .add(69, 69, 69)
                        .add(disableServo3Button)))
                .addContainerGap(20, Short.MAX_VALUE))
        );
        servo3PanelLayout.setVerticalGroup(
            servo3PanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(servo3PanelLayout.createSequentialGroup()
                .add(servo3Slider, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(disableServo3Button))
        );

        servoTypeComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "None", "ServoController", "CarServoController" }));
        servoTypeComboBox.setToolTipText("Selects device type to be controlled");
        servoTypeComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                servoTypeComboBoxActionPerformed(evt);
            }
        });

        fileMenu.setMnemonic('F');
        fileMenu.setText("File");
        exitMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_X, 0));
        exitMenuItem.setMnemonic('x');
        exitMenuItem.setText("Exit");
        exitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                exitMenuItemActionPerformed(evt);
            }
        });

        fileMenu.add(exitMenuItem);

        menuBar.add(fileMenu);

        setJMenuBar(menuBar);

        org.jdesktop.layout.GroupLayout layout = new org.jdesktop.layout.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(layout.createSequentialGroup()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(layout.createSequentialGroup()
                        .add(servo0Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(servo1Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(servo2Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(servo3Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                    .add(layout.createSequentialGroup()
                        .addContainerGap()
                        .add(syncPanel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                    .add(layout.createSequentialGroup()
                        .addContainerGap()
                        .add(servoTypeComboBox, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 211, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap(org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(layout.createSequentialGroup()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(layout.createSequentialGroup()
                        .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                            .add(servo0Panel, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(servo1Panel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(syncPanel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                    .add(servo2Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(servo3Panel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(servoTypeComboBox, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .add(82, 82, 82))
        );
        pack();
    }// </editor-fold>//GEN-END:initComponents
    
    private void servoTypeComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_servoTypeComboBoxActionPerformed
        synchronized(this){
            switch(servoTypeComboBox.getSelectedIndex()){
                case 0:
                    if(hwInterface!=null){
                        hwInterface.close();
                    }
                    hwInterface=null;
                    break;
                case 1: // servo interface
                    try{
                        hwInterface=new SiLabsC8051F320_USBIO_ServoController();
                        hwInterface.open();
                        servoValues=new float[hwInterface.getNumServos()];
                        setTitle("ServoController");
                    }catch(HardwareInterfaceException e){
                        e.printStackTrace();
                    }
                    break;
                case 2: // car servo controller
                    try{
                        hwInterface=new SiLabsC8051F320_USBIO_CarServoController();
                        hwInterface.open();
                        servoValues=new float[hwInterface.getNumServos()];
                        setTitle("CarServoController");
                    }catch(HardwareInterfaceException e){
                        e.printStackTrace();
                    }
                    break;
                default:
                    log.warning("unknown selection");
            }
        }
    }//GEN-LAST:event_servoTypeComboBoxActionPerformed
    
    
    void disableServo(int i){
        try{
            hwInterface.disableServo(i);
        }catch(HardwareInterfaceException e){
            e.printStackTrace();
        }
    }
    
    
    void setAllServos(float f) throws HardwareInterfaceException{
        Arrays.fill(servoValues,f);
        hwInterface.setAllServoValues(servoValues);
    }
    
    void setServo(int servo, ChangeEvent evt){
        if(hwInterface==null){
            log.warning("null hardware interface");
            return;
        }
        float f= (float)((JSlider)evt.getSource()).getValue()/MAX_SLIDER;
        try{
            if(synchronizeCheckBox.isSelected()) {
                setAllServos(f);
            }else{
                hwInterface.setServoValue(servo,f);
            }
        }catch(HardwareInterfaceException e){
            e.printStackTrace();
        }
    }
    
    
    void delayMs(int ms){
        try{
            Thread.currentThread().sleep(ms);
        }catch(InterruptedException e){}
    }
    
    
    
    private void disableServo3ButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_disableServo3ButtonActionPerformed
        disableServo(3);
    }//GEN-LAST:event_disableServo3ButtonActionPerformed
    
    private void servo3SliderStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_servo3SliderStateChanged
        setServo(3,evt);
    }//GEN-LAST:event_servo3SliderStateChanged
    
    private void disableServo2ButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_disableServo2ButtonActionPerformed
        disableServo(2);
    }//GEN-LAST:event_disableServo2ButtonActionPerformed
    
    private void servo2SliderStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_servo2SliderStateChanged
        setServo(2,evt);
    }//GEN-LAST:event_servo2SliderStateChanged
    
    private void disableServo1ButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_disableServo1ButtonActionPerformed
        disableServo(1);
    }//GEN-LAST:event_disableServo1ButtonActionPerformed
    
    private void disableServo0ButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_disableServo0ButtonActionPerformed
        disableServo(0);
    }//GEN-LAST:event_disableServo0ButtonActionPerformed
    
    
    private void disableButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_disableButtonActionPerformed
        try{
            hwInterface.disableAllServos();
        }catch(HardwareInterfaceException e){
            e.printStackTrace();
        }
    }//GEN-LAST:event_disableButtonActionPerformed
    
    private void sendValuesButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_sendValuesButtonActionPerformed
        try{
            hwInterface.setServoValue(3,(float)servo3Slider.getValue()/MAX_SLIDER);
            hwInterface.setServoValue(2,(float)servo2Slider.getValue()/MAX_SLIDER);
            hwInterface.setServoValue(1,(float)servo1Slider.getValue()/MAX_SLIDER);
            hwInterface.setServoValue(0,(float)servo0Slider.getValue()/MAX_SLIDER);
        }catch(HardwareInterfaceException e){
            e.printStackTrace();
        }
    }//GEN-LAST:event_sendValuesButtonActionPerformed
    
    
    
    private void servo1SliderStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_servo1SliderStateChanged
        setServo(1,evt);
    }//GEN-LAST:event_servo1SliderStateChanged
    
    private void servo0SliderStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_servo0SliderStateChanged
        setServo(0,evt);
    }//GEN-LAST:event_servo0SliderStateChanged
    
    private void exitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_exitMenuItemActionPerformed
        if(hwInterface!=null) {
            try{
                hwInterface.disableAllServos();
                hwInterface.close();
            }catch(HardwareInterfaceException e){
                e.printStackTrace();
            }
        }
        System.exit(0);
    }//GEN-LAST:event_exitMenuItemActionPerformed
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new ServoTest().setVisible(true);
            }
        });
    }
    
    /** called when device added */
    public void onAdd() {
        log.info("device added, opening it");
        try{
            hwInterface.open();
        }catch(HardwareInterfaceException e){
            log.warning(e.getMessage());
        }
    }
    
    public void onRemove() {
        log.info("device removed, closing it");
        if(hwInterface!=null && hwInterface.isOpen())
            hwInterface.close();
    }
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton disableButton;
    private javax.swing.JButton disableServo0Button;
    private javax.swing.JButton disableServo1Button;
    private javax.swing.JButton disableServo2Button;
    private javax.swing.JButton disableServo3Button;
    private javax.swing.JMenuItem exitMenuItem;
    private javax.swing.JMenu fileMenu;
    private javax.swing.JButton jButton1;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JButton sendValuesButton;
    private javax.swing.JPanel servo0Panel;
    private javax.swing.JSlider servo0Slider;
    private javax.swing.JPanel servo1Panel;
    private javax.swing.JSlider servo1Slider;
    private javax.swing.JPanel servo2Panel;
    private javax.swing.JSlider servo2Slider;
    private javax.swing.JPanel servo3Panel;
    private javax.swing.JSlider servo3Slider;
    private javax.swing.JComboBox servoTypeComboBox;
    private javax.swing.JPanel syncPanel;
    private javax.swing.JCheckBox synchronizeCheckBox;
    // End of variables declaration//GEN-END:variables
    
}
