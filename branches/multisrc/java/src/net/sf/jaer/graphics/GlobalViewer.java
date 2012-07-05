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

import ch.unizh.ini.jaer.chip.projects.sensoryfusion.BasicMultiSensoryFilt;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.GridLayout;
import java.awt.Rectangle;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Stack;
import java.util.Vector;
import java.util.concurrent.Semaphore;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JToggleButton;
import javax.swing.JToolBar;
import javax.swing.SwingUtilities;
import javax.xml.stream.EventFilter;
import net.sf.jaer.JAERViewer;
import net.sf.jaer.event.BasicEvent;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.eventprocessing.FilterFrame;
import net.sf.jaer.eventprocessing.MultiInputFrame;
import net.sf.jaer.eventprocessing.ProcessingNetwork;
import net.sf.jaer.eventprocessing.MultiSourceProcessor;
import net.sf.jaer.eventprocessing.PacketStream;
import net.sf.jaer.eventprocessing.SourceSynchronizer;

/**
 *
 * @author Peter
 */
public class GlobalViewer extends javax.swing.JFrame {

        // <editor-fold defaultstate="collapsed" desc=" Properties " >
    
        // Properties ----------------------------------
        
        private final ViewLoop viewLoop=new ViewLoop();
        JAERViewer jaerView;
        public boolean enabled=true;
        
        ProcessingNetwork procNet=new ProcessingNetwork();
        
        // THIS IS JUST A TEST AND WILL BE DELETED!
        MultiSourceProcessor testFilter;
        
        public final ArrayList<AEViewer.Ambassador> aeviewers=new ArrayList();
        public final ArrayList<DisplayWriter> inputDisplays=new ArrayList();
        public final ArrayList<DisplayWriter> internalDisplays=new ArrayList();
        
        ArrayList<PacketStream> packetStreams=new ArrayList();
        int[] packetStreamIndeces;
        Semaphore waitFlag;
        
        boolean synchDisp=false;
        SourceSynchronizer srcSync;
        
        // </editor-fold>
        
        // <editor-fold defaultstate="collapsed" desc=" Builder/Startup Methods " >
        
                
        // Methods -----------------------------------------
        public void collectAllInputs(ArrayList<AEViewer> viewers){
            
            inputDisplays.clear();
            packetStreams.clear();
            
            
            waitFlag=new Semaphore(viewers.size());
            
            // Add all the viewers
            for (int i=0; i<viewers.size(); i++) 
            {   
                AEViewer.Ambassador v=viewers.get(i).getAmbassador();
                v.setID(i);
                aeviewers.add(v);
                addPacketStream(v);
                addDisplayWriter(v);
                v.setWatched(true);
            }
            
            // In (Hopefully) rapid succession, zero the time-stamps
            for (AEViewer v:viewers)
                v.getAmbassador().resetTimeStamps();
        }
        
        public ArrayList<PacketStream> getInputStreams()
        {
            ArrayList  arr=aeviewers;
                        
            return arr;
        }
        
        
        public void addDisplayWriter(DisplayWriter d){
            
//            try {
//                //
//                waitFlag.acquire(packetStreams.size());
//            } catch (InterruptedException ex) {
//                Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//            }
                
            synchronized(inputDisplays)
            {
                inputDisplays.add(d);
                
            }
        }
        
        public void start(){
            
            enabled=true;
            viewLoop.start();
                                    
            initComponents();
            
        }
        
        
//        public void addDisplayWriter(AEViewer v){
//            displayWriters.add(v);
//            v.setWatched(true);
//            v.setPanel(makePanel());
//        }
        
        
        /** Add a new packet source 
         * @TODO: semaphore concerns
         */
        public void addPacketStream(PacketStream v){
            packetStreams.add(v);
            v.setSemaphore(waitFlag);
            
        }
        
        // </editor-fold>
        
        // <editor-fold defaultstate="collapsed" desc=" Access Methods " >
                
        public void setJaerViewer(JAERViewer v){
            this.jaerView=v;
        }
        
        
        public ArrayList<DisplayWriter> getAllDisplays()
        {
            ArrayList<DisplayWriter> displist=new ArrayList(inputDisplays);
            displist.addAll(internalDisplays);
            return displist;
        }
        
                            
//        public void setPaused(boolean desiredState)
//        {
//            viewLoop.paused=desiredState;
//            
//            if (desiredState)
//                // Wait for current thread to updause
//                synchronized(Thread.currentThread()){
//                {try {
//                    Thread.currentThread().wait();
//                } catch (InterruptedException ex) {
//                    Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//                }
//            }}
//        }
        
        // </editor-fold>
                
        // <editor-fold defaultstate="collapsed" desc=" ViewLoop Thread " >
        
        class ViewLoop extends Thread{
                        
            public volatile boolean paused;
            
            @Override
            public void start(){
                this.setName("GlobalViewer.ViewLoop");
                super.start();
            }
            
            @Override
            public void run() {
                // Update loop of the Merger object
                // 1) Wait for all other threads to finish their "run" commands
                // 2) Filter Packet & display
                // 3) Release other threads
                
                while (enabled) {
                    
//                    // Handle thread pausing
//                    synchronized (GlobalViewer.this) {
//                        if (this.paused) {
//                            GlobalViewer.this.notifyAll(); // Notify other threads that this loop is paused
//                            try {
//                                GlobalViewer.this.wait();
//                            } catch (InterruptedException ex) {
//                                Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//                            }
//                            GlobalViewer.this.notifyAll();   // Notify other threads that this loop is now unpaused
//                        }
//                    }
                    
                    int permits=aeviewers.size();


                    try {
                        // Wait for all AEViewers to finish
                        // The max is because some funny start condition caused extra permits
                        waitFlag.acquire(Math.max(waitFlag.availablePermits(),permits));
                    } catch (InterruptedException ex) {
                        Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
                        continue;
                    }
                    
                    // Synchronization display: 
                    if (synchDisp) //Update if window is open, otherwise turn off.
                    {   synchDisp=srcSync.update();
                    }


                    // 1) Process Packets
//                    procNet.crunch();
//                    for (PacketStream p:packetStreams){
//                        ...
//                    }

                    // 2) Display all displayables
                    synchronized(inputDisplays){
                        for (DisplayWriter s : inputDisplays) {
                            ((AEViewer.Ambassador)s).display();
                        }
                    }

//                    System.out.println("GlobalStream");
//                    synchronized(GlobalViewer.this)
//                    {
                        
//                    }
//                    waitFlag.release(3);
//                try {
//                    Thread.sleep(30);
//                } catch (InterruptedException ex) {
//                    Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//                }
                    waitFlag.release(permits);

                    synchronized (GlobalViewer.this) {   // Release the globalized AEViewers, which should ALL be hanging on this thread
                        GlobalViewer.this.notifyAll();
                        
//                        try {
//                            GlobalViewer.this.wait();
//                        } catch (InterruptedException ex) {
//                            Logger.getLogger(GlobalViewer.class.getName()).log(Level.SEVERE, null, ex);
//                        }
                    }
                    System.out.println("Global Loop end");
                }
                
                
                
            }
        }
        
        
        // </editor-fold>
        
        // <editor-fold defaultstate="collapsed" desc=" GUI Methods " >
        
        JToolBar bottomBar;
        JPanel viewPanel;
        JPanel filterPanel;
        MultiInputFrame multiInputControl;
        
        void initComponents()
        {
            this.setTitle("Global Viewer");
            
            this.setBackground(Color.DARK_GRAY);
            this.setLayout(new BorderLayout());
            
            
            filterPanel=new JPanel();
            this.add(filterPanel,BorderLayout.WEST);
//            filterPanel.setBackground(Color.GRAY);
//            filterPanel.setLayout(new BorderLayout());
            
            
            bottomBar=new JToolBar();
            this.add(bottomBar,BorderLayout.SOUTH);
//            bottomBar.setBackground(Color.GRAY);
            
            JButton button;
            
            button=new JButton("Old View");
            
            button.addActionListener(new ActionListener(){

                @Override
                public void actionPerformed(ActionEvent e) {
                    
                    for (DisplayWriter v:inputDisplays)
                    {   
                        
                        ((AEViewer) v).getContentPane().add(v.getPanel());
                        v.getPanel().removeAll();
                        
                        
                        GlobalViewer.this.enabled=false;
//                        GlobalViewer.this.dispose();                        
//                        v.getContentPane().add
                        ((AEViewer) v).setVisible(true);
                        ((AEViewer) v).globalized=false;
                    }
                    
//                    GlobalViewer.this.inputDisplays.clear();
                    
                }

            
            });
            bottomBar.add(button);
            
            button=new JButton("Do Something");
            bottomBar.add(button);
            
            final JToggleButton but=new JToggleButton("Show Filters");
            but.addActionListener(new ActionListener(){
                @Override
                public void actionPerformed(ActionEvent e) {
                    
                    if (but.isSelected())
                    {
                        
                        procNet.setInputStreams(getInputStreams());

                        if (multiInputControl == null) {
                            
                            multiInputControl = new MultiInputFrame(jaerView.getViewers().get(0).getChip(), procNet,filterPanel);
//                            MultiInputFrame mif = new MultiInputFrame(jaerView.getViewers().get(0).getChip(), procNet,filterPanel);

//                            mif.setVisible(true);
//                            
//                            mif.getComponents();
//                            
////                            multiInputControl = mif.getContentPane();
//                            multiInputControl = mif.getRootPane();
//                            
//                            mif.dispose();
                        }
                        else
                            multiInputControl.setHidden(false);
//                            filterPanel.add(multiInputControl,BorderLayout.CENTER);
//                        GlobalViewer.this.add(mifp,BorderLayout.WEST);

                        but.setText("Hide Filters");
                        GlobalViewer.this.pack();
                    }
                    else
                    {   multiInputControl.setHidden(true);
//                        filterPanel.remove(multiInputControl);
                        but.setText("Show Filters");
                        GlobalViewer.this.pack();
                        
                    }
                
                
                    
                }
            });
            bottomBar.add(but);
            
            button=new JButton("Synchronization");
            button.addActionListener(new ActionListener(){
                @Override
                public void actionPerformed(ActionEvent e) {
                    ArrayList arr=getInputStreams();
                    srcSync=new SourceSynchronizer(arr);
                    synchDisp=true;
                }
            });
            bottomBar.add(button);
            
            
            viewPanel=new JPanel();
            this.add(viewPanel,BorderLayout.CENTER);
            viewPanel.setBackground(Color.DARK_GRAY);            
            
            buildDisplay();

//            this.setPreferredSize(new Dimension(1000,800));
            
//            this.setExtendedState(JFrame.MAXIMIZED_BOTH); 
            
            this.setState(JFrame.NORMAL);
            Toolkit toolkit = Toolkit.getDefaultToolkit();
            Dimension dimension = toolkit.getScreenSize();
            dimension.height*=.8;
            this.setPreferredSize(dimension);
            
            pack();
            setVisible(true);
            
            // Hide the Viewers
            for (AEViewer v:jaerView.getViewers())
                v.setVisible(false);
            
        }
        
        
        public void buildDisplay()
        {   viewPanel.removeAll();
        
            viewPanel.setLayout(new FlowLayout());
        
            viewPanel.setLayout(new GridBagLayout());
            GridBagConstraints c=new GridBagConstraints();
            
            c.weightx=c.weighty=1;
            
            int i=0;
            for (DisplayWriter d:inputDisplays)
            {
                c.gridx=i++;
                c.gridy=1;
                c.weightx=c.weighty=1;
                
//                viewPanel.add(d.getPanel(),c);
                
                JPanel imagePanel=new JPanel();
//            
                imagePanel.setLayout(new GridLayout());
                
                
                imagePanel.setPreferredSize(new Dimension(400,400));
//            Dimension dims=this.getSize();
//            int dx=dims.width/numPanels;
////            
//            imagePanel.setBounds(new Rectangle(panelNumber*dx,0,dx,dims.height));
//            
//                imagePanel.setBounds(getPanelLoc(1,1));
                imagePanel.setBackground(Color.DARK_GRAY);

                viewPanel.add(imagePanel,c);
               
                
                imagePanel.setVisible(true);
                
                
                d.setPanel(imagePanel);
            }
        }
        // </editor-fold>       
}
