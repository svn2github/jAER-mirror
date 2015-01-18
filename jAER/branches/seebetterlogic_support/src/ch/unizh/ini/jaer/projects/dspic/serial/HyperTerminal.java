/*
 * simple serial port terminal emulator that let's write 0x0a terminated
 * strings to the port and displays received bytes
 *
 *   - RTS can be set manually, status of CTS displayed
 *   - output can be displayed as characters or in hex
 *   - baud rate can be set via GUI
 * 
 * this class is intended for low-level debugging of the dsPIC firmware
 * 
 */
package ch.unizh.ini.jaer.projects.dspic.serial;

import gnu.io.CommPortIdentifier;
import gnu.io.SerialPort;
import gnu.io.SerialPortEvent;
import gnu.io.SerialPortEventListener;
import gnu.io.UnsupportedCommOperationException;

import java.awt.Rectangle;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.prefs.Preferences;

/**
 * Talks to serial port, e.g. for FTDI USB interfaces.
 * 
 * @author andstein
 */
public class HyperTerminal extends javax.swing.JFrame
        implements SerialPortEventListener {

    final static String PORT_NAME_DEFAULT = "COM5";
    Preferences prefs = Preferences.userNodeForPackage(HyperTerminal.class);
    static final Logger log = Logger.getLogger("HyperTerminal");
    //public final static String portName= "/dev/ttyUSB0";
    public String portName = prefs.get("portName", PORT_NAME_DEFAULT);
    public int baudRate = prefs.getInt("baudRate", 618964); // 460800 for J. Conradt's FTDI on robot head controller
    private SerialPort port = null;
    private InputStreamReader isr = null;
    private OutputStream os = null;
    private int hexi = -1;

    /** Creates new form HyperTerminal */
    public HyperTerminal() {
        initComponents();

        addWindowListener(new WindowAdapter() {

            @Override
            public void windowClosing(WindowEvent e) {
                super.windowClosing(e);
                HyperTerminal.this.close();
            }
        });
        openPort();
    }

    private void openPort() {
        appendString("opening " + portName + "...");
        try {

            CommPortIdentifier cpi = CommPortIdentifier.getPortIdentifier(portName);
            port = (SerialPort) cpi.open(portName, 1000);

            port.setSerialPortParams(
                    Integer.parseInt(baudText.getText()),
                    SerialPort.DATABITS_8,
                    SerialPort.STOPBITS_1,
                    SerialPort.PARITY_NONE);
//            port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
            port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN
                    | SerialPort.FLOWCONTROL_RTSCTS_OUT);
            port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
            port.addEventListener(this);
            port.notifyOnDataAvailable(true);
            port.notifyOnCTS(true);

            isr = new InputStreamReader(port.getInputStream());
            os = port.getOutputStream();

        } catch (Exception e) {
            log.warning(e.toString());
            appendString(e.toString());
        } finally {

            updateFlags();
            appendString("done.\n");
        }
    }

    public void serialEvent(SerialPortEvent spe) {
        if (spe.getEventType() == SerialPortEvent.DATA_AVAILABLE) {
            StringBuilder line = new StringBuilder();
            try {
                while (isr.ready()) {
                    if (hexi < 0) {
                        line.append((char) isr.read());
                    } else {
                        int value = isr.read();
                        if (value >= 0) {
                            line.append(String.format("%02X ", (value & 0xFF)));
                            if (++hexi % 0x10 == 0) {
                                line.append("\n");
                            }
                        }
                    }
                }

                appendString(line.toString());
            } catch (IOException ex) {
                Logger.getLogger(HyperTerminal.class.getName()).log(Level.WARNING, null, ex);
            }
        }

        updateFlags();
    }

    public void close() {
        try {
            if (isr != null) {
                isr.close();
            }
            if (os != null) {
                os.close();
            }
        } catch (IOException ex) {
            Logger.getLogger(HyperTerminal.class.getName()).log(Level.SEVERE, null, ex);
        }
        if (port != null) {
            port.close();
        }
        isr = null;
        os = null;
        port = null;
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        textField = new javax.swing.JTextField();
        jScrollPane1 = new javax.swing.JScrollPane();
        textPane = new javax.swing.JTextArea();
        jPanel1 = new javax.swing.JPanel();
        RTScb = new javax.swing.JCheckBox();
        hexCB = new javax.swing.JCheckBox();
        jLabel1 = new javax.swing.JLabel();
        baudText = new javax.swing.JTextField();
        statusText = new javax.swing.JTextField();
        CTScb = new javax.swing.JCheckBox();
        clearButton = new javax.swing.JButton();
        jLabel2 = new javax.swing.JLabel();
        comportTF = new javax.swing.JTextField();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        textField.setFont(new java.awt.Font("Courier New", 1, 11));
        textField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                textFieldActionPerformed(evt);
            }
        });

        textPane.setColumns(20);
        textPane.setEditable(false);
        textPane.setFont(new java.awt.Font("Courier New", 0, 11));
        textPane.setRows(5);
        jScrollPane1.setViewportView(textPane);

        RTScb.setText("RTS");
        RTScb.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                RTScbActionPerformed(evt);
            }
        });

        hexCB.setText("hex");
        hexCB.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                hexCBActionPerformed(evt);
            }
        });

        jLabel1.setText("bauds");

        baudText.setFont(new java.awt.Font("Monospaced", 0, 11)); // NOI18N
        baudText.setText(Integer.toString(prefs.getInt("baudRate", 618964)));
        baudText.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                baudTextActionPerformed(evt);
            }
        });

        statusText.setEditable(false);
        statusText.setFont(new java.awt.Font("Courier New", 0, 11)); // NOI18N

        CTScb.setText("CTS");
        CTScb.setEnabled(false);

        clearButton.setText("clear");
        clearButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                clearButtonActionPerformed(evt);
            }
        });

        jLabel2.setText("port");

        comportTF.setText(prefs.get("comPort",PORT_NAME_DEFAULT));
        comportTF.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                comportTFActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(RTScb)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addComponent(CTScb)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(clearButton)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(statusText, javax.swing.GroupLayout.DEFAULT_SIZE, 233, Short.MAX_VALUE))
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
                        .addComponent(comportTF, javax.swing.GroupLayout.DEFAULT_SIZE, 74, Short.MAX_VALUE)
                        .addGap(18, 18, 18)
                        .addComponent(jLabel2)
                        .addGap(18, 18, 18)
                        .addComponent(hexCB)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(baudText, javax.swing.GroupLayout.PREFERRED_SIZE, 133, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jLabel1)))
                .addContainerGap())
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(RTScb)
                    .addComponent(CTScb)
                    .addComponent(clearButton)
                    .addComponent(statusText, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(baudText, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(hexCB)
                    .addComponent(jLabel2)
                    .addComponent(comportTF, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
        );

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(jScrollPane1, javax.swing.GroupLayout.Alignment.LEADING, javax.swing.GroupLayout.DEFAULT_SIZE, 408, Short.MAX_VALUE)
                    .addComponent(textField, javax.swing.GroupLayout.Alignment.LEADING, javax.swing.GroupLayout.DEFAULT_SIZE, 408, Short.MAX_VALUE)
                    .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(textField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 200, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jPanel1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void textFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_textFieldActionPerformed

        if(port==null){
            appendString("null port\n");
            return;
        }
        boolean buffered = true;

        if (buffered) {
            PrintWriter pw = new PrintWriter(os);
            pw.print(textField.getText());
            pw.print("\n");
            pw.flush(); // <=== this is crucial !!
        } else {
            String x = textField.getText() + "\n";
            for (int i = 0; i < x.length(); i++) {
                try {
                    os.write((byte) x.charAt(i));
                    Logger.getLogger(HyperTerminal.class.getName()).log(Level.INFO,
                            "wrote character : " + x.substring(i, i + 1));
                } catch (IOException e) {
                    Logger.getLogger(HyperTerminal.class.getName()).log(Level.WARNING,
                            "could not write character : e=" + e);
                }
            }
        }

        Logger.getLogger(HyperTerminal.class.getName()).log(Level.INFO,
                "sent : " + textField.getText());
        textField.setText("");
    }//GEN-LAST:event_textFieldActionPerformed

    private void RTScbActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_RTScbActionPerformed
        if (port == null) {
            appendString("null port\n");
            return;
        }
        port.setRTS(RTScb.isSelected());
    }//GEN-LAST:event_RTScbActionPerformed

    private void clearButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_clearButtonActionPerformed
        textPane.setText("");
    }//GEN-LAST:event_clearButtonActionPerformed

    private void baudTextActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_baudTextActionPerformed
        try {
            int rate;
            port.setSerialPortParams(
                    rate = Integer.parseInt(baudText.getText()),
                    port.getDataBits(),
                    port.getStopBits(),
                    port.getParity());

            textPane.append("\nset baud rate to " + baudText.getText() + "\n\n");
            baudRate = rate;
            prefs.putInt("baudRate", baudRate);
        } catch (UnsupportedCommOperationException ex) {
            log.warning(ex.toString());
            textPane.append("\n*** could not set baud rate : " + ex + "\n\n");
        }
    }//GEN-LAST:event_baudTextActionPerformed

    private void hexCBActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_hexCBActionPerformed
        if (hexCB.isSelected()) {
            hexi = 0;
        } else {
            hexi = -1;
        }
        appendString("\n\n");
    }//GEN-LAST:event_hexCBActionPerformed

    private void comportTFActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_comportTFActionPerformed
        portName = comportTF.getText();
        close();
        openPort();
        prefs.put("portName", portName);
    }//GEN-LAST:event_comportTFActionPerformed

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {

            public void run() {
                new HyperTerminal().setVisible(true);
            }
        });
    }

    void appendString(String str) {
        textPane.setText(textPane.getText() + str);
        textPane.scrollRectToVisible(new Rectangle(0, textPane.getHeight() - 2, 1, 1));
    }

    void updateFlags() {
        if (port == null) {
            return;
        }
        CTScb.setSelected(port.isCTS());
        RTScb.setSelected(port.isRTS());
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JCheckBox CTScb;
    private javax.swing.JCheckBox RTScb;
    private javax.swing.JTextField baudText;
    private javax.swing.JButton clearButton;
    private javax.swing.JTextField comportTF;
    private javax.swing.JCheckBox hexCB;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextField statusText;
    private javax.swing.JTextField textField;
    private javax.swing.JTextArea textPane;
    // End of variables declaration//GEN-END:variables
}
