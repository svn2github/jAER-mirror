/*
 */
package sf.net.jaer.util;
       
/** 
 * The interface for an ExceptionListener
 *@see sf.net.jaer.hardwareinterface.HardwareInterfaceException
 */
public interface ExceptionListener {
    public void exceptionOccurred(Exception x, Object source);
}


