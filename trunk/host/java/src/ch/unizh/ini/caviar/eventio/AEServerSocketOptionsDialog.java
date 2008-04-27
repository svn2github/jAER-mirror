/*
 * AEServerSocketOkCancelDialog.java
 *
 * Created on July 22, 2007, 1:17 PM
 */

package ch.unizh.ini.caviar.eventio;

import java.util.logging.Logger;

/**
A dialog for opening AEServerSocket connections. Includes buffer sizes.
@author  tobi
 */
public class AEServerSocketOptionsDialog extends javax.swing.JDialog {
    static Logger log=Logger.getLogger("AEServerSocketOptionsDialog");
    /** A return status code - returned if Cancel button has been pressed */
    public static final int RET_CANCEL = 0;
    /** A return status code - returned if OK button has been pressed */
    public static final int RET_OK = 1;

    AEServerSocket aeServerSocket;

    /** Creates new form AESocketOkCancelDialog */
    public AEServerSocketOptionsDialog(java.awt.Frame parent, boolean modal, AEServerSocket aeServerSocket) {
        super(parent,"AESocket Server Options", modal);
        initComponents();
        if(aeServerSocket==null){
            log.warning("null aeServerSocket");
        }
        this.aeServerSocket = aeServerSocket;
        bufferSizeTextField.setText(Integer.toString(aeServerSocket.getBufferedStreamSize()));
        sendBufferSizeTextField.setText(Integer.toString(aeServerSocket.getSendBufferSize()));
        portTextField.setText(Integer.toString(aeServerSocket.getPort()));
        flushPacketsCheckBox.setSelected(aeServerSocket.isFlushPackets());
        getRootPane().setDefaultButton(okButton); // allows enter to just accept values
    }

    /** @return the return status of this dialog - one of RET_OK or RET_CANCEL */
    public int getReturnStatus() {
        return returnStatus;
    }

    /** This method is called from within the constructor to
    initialize the form.
    WARNING: Do NOT modify this code. The content of this method is
    always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        okButton = new javax.swing.JButton();
        cancelButton = new javax.swing.JButton();
        jLabel2 = new javax.swing.JLabel();
        bufferSizeTextField = new javax.swing.JTextField();
        jLabel3 = new javax.swing.JLabel();
        sendBufferSizeTextField = new javax.swing.JTextField();
        defaultsButton = new javax.swing.JButton();
        jLabel5 = new javax.swing.JLabel();
        portTextField = new javax.swing.JTextField();
        flushPacketsCheckBox = new javax.swing.JCheckBox();

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
        cancelButton.setToolTipText("Cancels changes");
        cancelButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cancelButtonActionPerformed(evt);
            }
        });

        jLabel2.setText("Buffered stream  size (bytes)");

        bufferSizeTextField.setToolTipText("size of buffered stream enclosing writes to socket (increasing reduces pauses on sender but increases latency)");

        jLabel3.setText("Send buffer size (bytes)");

        sendBufferSizeTextField.setToolTipText("size of underlying buffer for socket writes (has maximum defined by underlying layer)");

        defaultsButton.setText("Defaults");
        defaultsButton.setToolTipText("Reset to default values");
        defaultsButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                defaultsButtonActionPerformed(evt);
            }
        });

        jLabel5.setText("Port (default "+AENetworkInterface.STREAM_PORT+")");

        portTextField.setToolTipText("port number for incoming socket connections");
        portTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                portTextFieldActionPerformed(evt);
            }
        });

        flushPacketsCheckBox.setText("Flush packets");
        flushPacketsCheckBox.setToolTipText("Enable to flush on each writePacket");
        flushPacketsCheckBox.setBorder(javax.swing.BorderFactory.createEmptyBorder(0, 0, 0, 0));
        flushPacketsCheckBox.setMargin(new java.awt.Insets(0, 0, 0, 0));

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                        .addComponent(defaultsButton)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 55, Short.MAX_VALUE)
                        .addComponent(okButton, javax.swing.GroupLayout.PREFERRED_SIZE, 67, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(cancelButton))
                    .addComponent(jLabel3)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jLabel2)
                            .addComponent(jLabel5))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                            .addComponent(portTextField)
                            .addComponent(sendBufferSizeTextField)
                            .addComponent(bufferSizeTextField, javax.swing.GroupLayout.DEFAULT_SIZE, 104, Short.MAX_VALUE)))
                    .addComponent(flushPacketsCheckBox))
                .addContainerGap())
        );

        layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {cancelButton, okButton});

        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(portTextField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jLabel5))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel2)
                    .addComponent(bufferSizeTextField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel3)
                    .addComponent(sendBufferSizeTextField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(flushPacketsCheckBox)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 14, Short.MAX_VALUE)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(cancelButton)
                    .addComponent(okButton)
                    .addComponent(defaultsButton))
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

private void defaultsButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_defaultsButtonActionPerformed
      portTextField.setText(Integer.toString(AENetworkInterface.STREAM_PORT));
      bufferSizeTextField.setText(Integer.toString(AEServerSocket.DEFAULT_BUFFERED_STREAM_SIZE_BYTES));
      sendBufferSizeTextField.setText(Integer.toString(AEServerSocket.DEFAULT_SEND_BUFFER_SIZE_BYTES));
//      receiveBufferSizeTextField.setText(Integer.toString(AEServerSocket.DEFAULT_RECEIVE_BUFFER_SIZE_BYTES));
}//GEN-LAST:event_defaultsButtonActionPerformed

    private void portTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_portTextFieldActionPerformed
        // TODO add your handling code here:
}//GEN-LAST:event_portTextFieldActionPerformed

    private void okButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_okButtonActionPerformed
        int sendBufferSize=AEServerSocket.DEFAULT_SEND_BUFFER_SIZE_BYTES;
        int receiveBufferSize=AEServerSocket.DEFAULT_RECIEVE_BUFFER_SIZE_BYTES;
        int bufferedStreamSize=AEServerSocket.DEFAULT_BUFFERED_STREAM_SIZE_BYTES;
        int port=aeServerSocket.getPort();
        try {
            port = Integer.parseInt(portTextField.getText());
        } catch (NumberFormatException e) {
            portTextField.selectAll();
            return;
        }
        try {
            sendBufferSize = Integer.parseInt(sendBufferSizeTextField.getText());
        } catch (NumberFormatException e) {
            sendBufferSizeTextField.selectAll();
            return;
        }
//        try {
//            receiveBufferSize = Integer.parseInt(receiveBufferSizeTextField.getText());
//        } catch (NumberFormatException e) {
//            receiveBufferSizeTextField.selectAll();
//            return;
//        }
        try {
            bufferedStreamSize = Integer.parseInt(bufferSizeTextField.getText());
        } catch (NumberFormatException e) {
            bufferSizeTextField.selectAll();
            return;
        }
        aeServerSocket.setPort(port);
        aeServerSocket.setBufferedStreamSize(bufferedStreamSize);
        aeServerSocket.setReceiveBufferSize(receiveBufferSize);
        aeServerSocket.setSendBufferSize(sendBufferSize);
        aeServerSocket.setFlushPackets(flushPacketsCheckBox.isSelected());

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


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JTextField bufferSizeTextField;
    private javax.swing.JButton cancelButton;
    private javax.swing.JButton defaultsButton;
    private javax.swing.JCheckBox flushPacketsCheckBox;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JButton okButton;
    private javax.swing.JTextField portTextField;
    private javax.swing.JTextField sendBufferSizeTextField;
    // End of variables declaration//GEN-END:variables
    private int returnStatus = RET_CANCEL;
}
