/*
 * EventFilter2D.java
 *
 * Created on November 9, 2005, 8:49 AM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */
package net.sf.jaer.eventprocessing;

import java.awt.BorderLayout;
import java.awt.Component;
import java.util.ArrayList;
import javax.swing.JPanel;
import net.sf.jaer.aemonitor.AEConstants;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.event.EventPacket;

/**
 * A filter that filters or otherwise processes a packet of events. <code>EventFilter2D</code> is the base class
 * for all processing methods in jAER. 
 * 
 * <p>
 * The method <code>filterPacket</code> is called when data is available to be processed.
 * A subclass implements <code>filterPacket</code> along with <code>resetFilter</code>.
 * 
 * <p>
 * 
 * @author tobi
 */
abstract public class EventFilter2D extends EventFilter {

    /** The built-in reference to the output packet */
    protected EventPacket out = null;
    
    /** Returns reference to the built-in output packet.
     * 
     * @return the out packet. 
     */
    protected EventPacket getOutputPacket(){
        return out;
    }


    protected float currentUpdateIntervalMs;

    /** Resets the output packet to be a new packet if none has been constructed or clears the packet
    if it exists
     */
    protected void resetOut() {
        if (out == null) {
            out = new EventPacket();
        } else {
            out.clear();
        }
    }

    /** Checks <code>out</code> packet to make sure it holds the same type as the 
    input packet. This method is used for filters that must pass output
    that has same event type as input. Unlike the other checkOutputPacketEventType method, this also ensures that 
    * the output EventPacket is of the correct class, e.g. if it is a subclass of EventPacket, but only if EventPacket.setNextPacket() has been
    * called. I.e., the user must set EventPacket.nextPacket. 
     * <p>
     * This method also copies fields from the input packet to the output packet, e.g. <code>systemModificationTimeNs</code>.
    @param in the input packet
    @see #out
     */
    protected void checkOutputPacketEventType(EventPacket in) {
        in.setNextPacket(out);
        if (out != null && out.getEventClass() == in.getEventClass() && out.getClass() == in.getClass()) {
            out.systemModificationTimeNs=in.systemModificationTimeNs;
            return;
        }
        out = in.getNextPacket();
    }
    
    /** Checks <code>out</code>  packet to make sure it holds the same type of events as the given class. 
     * This method is used for filters that must pass output
    that has a particular output type.  This method does not ensure that the output packet is of the correct subtype of EventPacket.
    @param outClass the output packet event type class.
     @see #out
     * @see EventPacket#getNextPacket
     * @see #checkOutputPacketEventType(java.lang.Class) 
    */
    protected void checkOutputPacketEventType(Class<? extends BasicEvent> outClass) {
        if (out == null || out.getEventClass() == null || out.getEventClass() != outClass) {
//            Class oldClass=out.getEventClass();
            out = new EventPacket(outClass);
//           log.info("oldClass="+oldClass+" outClass="+outClass+"; allocated new "+out);
        }
    }
    
    /** Subclasses implement this method to define custom processing.
    @param in the input packet
    @return the output packet
     */
    public abstract EventPacket<?> filterPacket(EventPacket<?> in);

    /** Subclasses should call this super initializer */
    public EventFilter2D(AEChip chip) {
        super(chip);
        this.chip = chip;
    }
    /** overrides EventFilter type in EventFilter */
    protected EventFilter2D enclosedFilter;

    /** A filter can enclose another filter and can access and process this filter. Note that this
    processing is not automatic. Enclosing a filter inside another filter means that it will
    be built into the GUI as such
    @return the enclosed filter
     */
    @Override
    public EventFilter2D getEnclosedFilter() {
        return this.enclosedFilter;
    }

    /** A filter can enclose another filter and can access and process this filter. Note that this
    processing is not automatic. Enclosing a filter inside another filter means that it will
    be built into the GUI as such.
    @param enclosedFilter the enclosed filter
     */
    public void setEnclosedFilter(final EventFilter2D enclosedFilter) {
        if(this.enclosedFilter!=null){
            log.warning("replacing existing enclosedFilter= "+this.enclosedFilter+" with new enclosedFilter= "+enclosedFilter);
        }
        super.setEnclosedFilter(enclosedFilter, this);
        this.enclosedFilter = enclosedFilter;
    }

    /** Resets the filter
    @param yes true to reset
     */
    @Override
    synchronized public void setFilterEnabled(boolean yes) {
        super.setFilterEnabled(yes);
        if (yes) {
            resetOut();
        } else {
            out = null; // garbage collect
        }
    }

 
    private int nextUpdateTimeUs = 0; // next timestamp we should update cluster list
    private boolean updateTimeInitialized = false;// to initialize time for cluster list update
    private int lastUpdateTimeUs=0;

    /** Checks for passage of interval of at least updateIntervalMs since the last update and 
     * notifies Observers if time has passed.
     * Observers are called with an UpdateMessage formed from the current packet and the current timestamp.
     * @param packet the current data
     * @param timestamp the timestamp to be checked. If this timestamp is greater than the nextUpdateTime (or has gone backwards, to handle rewinds), then the UpdateMessage is sent.
     * @return true if Observers were notified.
     */
    public boolean maybeCallUpdateObservers(EventPacket packet, int timestamp) {
        if (!updateTimeInitialized || currentUpdateIntervalMs != chip.getFilterChain().getUpdateIntervalMs()) {
            nextUpdateTimeUs = (int) (timestamp + chip.getFilterChain().getUpdateIntervalMs() * 1000 / AEConstants.TICK_DEFAULT_US);
            updateTimeInitialized = true; // TODO may not be handled correctly after rewind of filter
            currentUpdateIntervalMs = chip.getFilterChain().getUpdateIntervalMs();
        }
        // ensure observers are called by next event after upateIntervalUs
        if (timestamp >= nextUpdateTimeUs || timestamp<lastUpdateTimeUs /* handle rewind of time */) {
            nextUpdateTimeUs = (int) (timestamp + chip.getFilterChain().getUpdateIntervalMs() * 1000 / AEConstants.TICK_DEFAULT_US);
//            log.info("notifying update observers after "+(timestamp-lastUpdateTimeUs)+"us");
            setChanged();
            notifyObservers(new UpdateMessage(this, packet, timestamp));
            lastUpdateTimeUs=timestamp;
            return true;
        }
        return false;
    }

    /** Observers are called with the update message as the argument of the update; the observable is the EventFilter that calls the update.
     * @param packet the event packet concerned with this update.
     * @param timestamp the time of the update in timestamp ticks (typically us).
     */
    public void callUpdateObservers(EventPacket packet, int timestamp) {
        updateTimeInitialized = false;
        setChanged();
        notifyObservers(new UpdateMessage(this, packet, timestamp));
    }

    /** Supplied as object for update. 
     @see #maybeCallUpdateObservers
     */
    public class UpdateMessage{
        /** The packet that needs the update. */
        public EventPacket packet;
        /** The timestamp of this update.*/
        public int timestamp;
        /** The source EventFilter2D. */
        EventFilter2D source;

        /** When a filter calls for an update of listeners it supplies this object.
         * 
         * @param source - the source of the update
         * @param packet - the EventPacket
         * @param timestamp - the timestamp in us (typically) of the update 
         */
        public UpdateMessage(EventFilter2D source, EventPacket packet, int timestamp ) {
            this.packet = packet;
            this.timestamp = timestamp;
            this.source = source;
        }

        public String toString(){
            return "UpdateMessage source="+source+" packet="+packet+" timestamp="+timestamp;
        }
    }
    
    // <editor-fold defaultstate="collapsed" desc=" Peter's Bells & Whistles " >
    
    ArrayList<JPanel> customControls; // List of added controls
    
    ArrayList<Component> customDisplays=new ArrayList(); // List of added displays
    
    /** Add your own display to the display area */
    public void addDisplay(Component disp)
    {
        customDisplays.add(disp);
        
        if (this.getChip().getAeViewer().globalized) 
            this.getChip().getAeViewer().getJaerViewer().globalViewer.addDisplayWriter(disp);
        else
            this.getChip().getAeViewer().getImagePanel().add(disp,BorderLayout.EAST);
    }
    
    /** Remove all displays that you added */
    public void removeDisplays()
    {
        if (this.getChip().getAeViewer()==null)
            return;
        
        if (this.getChip().getAeViewer().globalized) 
            for (Component c:customDisplays)
                this.getChip().getAeViewer().getJaerViewer().globalViewer.removeDisplay(c);
        else 
            for (Component c:customDisplays)
              this.getChip().getAeViewer().getImagePanel().remove(c);
    }
        
    /** Add a panel to the filter controls */
    public void addControls(JPanel controls)
    {
//        this.getChip().getAeViewer().getJaerViewer().globalViewer.addControlsToFilter(controls, this);
        
        getControlPanel().addCustomControls(controls);
        
    }
    
    /** Remove all added controls */
    public void removeControls()
    {   FilterPanel p=getControlPanel();
        if (p!=null)
            p.removeCustomControls();
    }
    
    /** Retrieves the control panel for this filter, allowing you to customize it */
    private FilterPanel getControlPanel()
    {
        if((this.getChip().getAeViewer())==null)
            return null;
        
        if (this.getChip().getAeViewer().globalized) //
            return this.getChip().getAeViewer().getJaerViewer().globalViewer.procNet.getControlPanelFromFilter(this);
        else // Backwards compatibility
        {
            if (this.getChip().getAeViewer().getFilterFrame()==null)
                return null;
            else
                return this.getChip().getAeViewer().getFilterFrame().getFilterPanelForFilter(this);
            
        }
    }
    
    // </editor-fold>
}
