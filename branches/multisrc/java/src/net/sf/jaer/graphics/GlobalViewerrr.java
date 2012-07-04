/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * MultiViewer.java
 *
 * Created on Apr 2, 2012, 2:16:00 PM
 */
package net.sf.jaer.graphics;

import ch.unizh.ini.jaer.chip.projects.sensoryfusion.FusionReactor;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Rectangle;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Stack;
import java.util.Vector;
import java.util.concurrent.Semaphore;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import javax.xml.stream.EventFilter;
import net.sf.jaer.JAERViewer;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.FilterFrame;
import net.sf.jaer.eventprocessing.MultiInputFrame;
import net.sf.jaer.eventprocessing.ProcessingNetwork;
import net.sf.jaer.eventprocessing.MultiSensoryFilter;
import net.sf.jaer.eventprocessing.PacketStream;

/**
 *
 * @author Peter
 */
public class GlobalViewerrr extends javax.swing.JFrame {

    
        // Properties ----------------------------------
        
        private final ViewLoop viewLoop=new ViewLoop();
        JAERViewer jaerView;
        public boolean enabled=true;
        
        ProcessingNetwork procNet=new ProcessingNetwork();
        
        // THIS IS JUST A TEST AND WILL BE DELETED!
        MultiSensoryFilter testFilter;
        
        public final ArrayList<DisplayWriter> displayWriters=new ArrayList();
        
                
        ArrayList<PacketStream> packetStreams=new ArrayList();
        int[] packetStreamIndeces;
        
        Semaphore waitFlag;
        
                
        // Methods -----------------------------------------
        public void collectAllInputs(ArrayList<AEViewer> viewers){
            
            
            
            displayWriters.clear();
            packetStreams.clear();
            
            
            waitFlag=new Semaphore(viewers.size());
            
            // Add all the viewers
            for (int i=0; i<viewers.size(); i++) 
            {   //Stream st=new Stream(viewers.get(i));
                
                AEViewer v=viewers.get(i);
                addPacketStream(v);
                addDisplayWriter(v);
                
            }
            
            resizePanels();
        }
        
        public ArrayList<PacketStream> getInputSources()
        {
            ArrayList arr=jaerView.getViewers();
                        
            return arr;
        }
        
        
        public void addDisplayWriter(DisplayWriter d){
            
            
//            try {
//                //
//                waitFlag.acquire(packetStreams.size());
//            } catch (InterruptedException ex) {
//                Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//            }
                
            synchronized(displayWriters)
            {
//                pauseViewLoop(true);

                displayWriters.add(d);
                d.setWatched(true);
                d.setPanel(makePanel());
                
            }
        }
        
//        public void addDisplayWriter(AEViewer v){
//            displayWriters.add(v);
//            v.setWatched(true);
//            v.setPanel(makePanel());
//        }
        
        
        public void addPacketStream(PacketStream v){
            packetStreams.add(v);
            v.setSemaphore(waitFlag);
            
        }

        void resizePanels() {
            for (int i = 0; i < displayWriters.size(); i++) {
                DisplayWriter dw = displayWriters.get(i);
               // dw.getPanel().setVisible(false);
                
                dw.getPanel().setBounds(getPanelLoc(i, displayWriters.size()));
                //dw.getPanel().setVisible(true);
                dw.setPanel(dw.getPanel());
                
                dw.getPanel().revalidate();
            }
            
        }
        
        JPanel makePanel(){
            
            JPanel imagePanel=new JPanel();
            
//            Dimension dims=this.getSize();
//            int dx=dims.width/numPanels;
            
            //imagePanel.setBounds(new Rectangle(panelNumber*dx,0,dx,dims.height));
            
            imagePanel.setBounds(getPanelLoc(1,1));
            imagePanel.setBackground(Color.DARK_GRAY);

            //imagePanel.setEnabled(false);
            //imagePanel.setFocusable(false);
            //imagePanel.setPreferredSize(new java.awt.Dimension(200, 200));
            //imagePanel.setLayout(new java.awt.BorderLayout());
            getContentPane().add(imagePanel, java.awt.BorderLayout.CENTER);
            //imagePanel.setEnabled(true);

            imagePanel.setVisible(true);
            return imagePanel;
        }
        
        Rectangle getPanelLoc(int panelNumber,int numPanels)
        {   Dimension dims=this.getSize();
                        
            int dx=dims.width/numPanels;
            
            int gap=(int)(dx*0.05);
            int wid=dx-2*gap;
                        
            return new Rectangle(panelNumber*dx+gap,(dims.height-wid)/2,wid,wid);            
        }
        
        
        
        public void start(){
            
            enabled=true;
            this.setVisible(true);
            viewLoop.start();
            
        }
                
        public void setJaerViewer(JAERViewer v){
            this.jaerView=v;
        }
            
        /** Creates new form MultiViewer */
        public GlobalViewerrr() {
            initComponents();
        }
                
        public void setPaused(boolean desiredState)
        {
            viewLoop.paused=desiredState;
            
            if (desiredState)
                // Wait for current thread to updause
                synchronized(Thread.currentThread()){
                {try {
                    Thread.currentThread().wait();
                } catch (InterruptedException ex) {
                    Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
                }
            }}
        }
        
        /**
         * Run input streams through the filter chain
         */
        void filterStreams(){
            
            
            
        }
        
        class ViewLoop extends Thread{
                        
            public volatile boolean paused;
            
            @Override
            public void start(){
                this.setName("GlobalViewer.ViewLoop");
                super.start();
            }
            
            @Override
            public void run() {
                // Updata loop of the Merger object
                // 1) Wait for all other threads to finish their "run" commands
                // 2) Filter Packet & display
                // 3) Release other threads
                
                while (enabled) {
                    
                    // Handle thread pausing
                    synchronized (GlobalViewerrr.this) {
                        if (this.paused) {
                            GlobalViewerrr.this.notifyAll(); // Notify other threads that this loop is paused
                            try {
                                GlobalViewerrr.this.wait();
                            } catch (InterruptedException ex) {
                                Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
                            }
                            GlobalViewerrr.this.notifyAll();   // Notify other threads that this loop is now unpaused
                        }
                    }


                    try {
                        // Wait for all AEViewers to finish
                        waitFlag.acquire(packetStreams.size());
                    } catch (InterruptedException ex) {
                        Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
                    }


                    // 1) Process Packets
//                    for (PacketStream p:packetStreams){
//                        ...
//                    }

                    // 2) Display all displayables
                    synchronized(displayWriters){
                        for (DisplayWriter s : displayWriters) {
                            s.display();
                        }
                    }

//                    System.out.println("GlobalStream");
                    waitFlag.release(packetStreams.size());


                    synchronized (GlobalViewerrr.this) {   // Release the globalized AEViewers, which should ALL be hanging on this thread
                        GlobalViewerrr.this.notifyAll();
                    }

                }
                
            }
        }
                
        
        
    //<editor-fold defaultstate="collapsed" desc="GUI code">

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setBackground(new java.awt.Color(51, 51, 51));

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 806, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 441, Short.MAX_VALUE)
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(GlobalViewer.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(GlobalViewer.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(GlobalViewer.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(GlobalViewer.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {

            @Override
            public void run() {
                new GlobalViewerrr().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables

    // </editor-fold>     
}
