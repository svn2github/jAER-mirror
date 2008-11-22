/*
 * HardwareInterfaceFactoryInterface.java
 *
 * Created on October 3, 2005, 11:45 AM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */

package sf.net.jaer.hardwareinterface;



/**
 * Defines the interface a hardware interface factory has to have to be included in the list in HardwareInterfaceFactory.
 *
 * @author tobi
 */
public interface HardwareInterfaceFactoryInterface  {
    
   /** Returns the number of available interfaces, i.e., the number of available hardware devices.
     * If the driver only supports one interface, then 1 will always be returned.
     * @return number of interfaces
     */
    public int getNumInterfacesAvailable();
        
    /** 
     * Gets the first available interface.
     * @return first available interface, or null if no interfaces are found.
     */
    public HardwareInterface getFirstAvailableInterface() throws HardwareInterfaceException ;
    
    /** Returns one of the interfaces 
     * 
     * @param n the number starting from 0
     * @return the HardwareInterface
     * @throws net.sf.jaer.hardwareinterface.HardwareInterfaceException if there is some error
     */
    public HardwareInterface getInterface(int n) throws HardwareInterfaceException ;
    
    
//    /** Returns the first available interface for a particular Chip. The factory can use the Chip to determine
//     * which class to manufacture for a particular HardwareInterface.
//     * @param chip a Chip object
//     * @return the matching HardwareInterface.
//     */
//    public HardwareInterface getFirstAvailableInterfaceForChip(Chip chip);
    
}
