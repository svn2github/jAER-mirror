/*
 * USBAEMonitorException.java
 *
 * Created on February 17, 2005, 8:01 AM
 */

package ch.unizh.ini.caviar.hardwareinterface;

import java.util.*;
import ch.unizh.ini.caviar.util.ExceptionListener;

/**
 *  An exception in the USB interface is signaled with this exception.
 * @author  tobi
 */
public class HardwareInterfaceException extends java.lang.Exception {
    
    static private Set exceptionListeners = Collections.synchronizedSet(new HashSet<ExceptionListener>());
    
    /** Creates a new instance of USBAEMonException */
    public HardwareInterfaceException() {
        super();
        sendException(this);
    }
    
    public HardwareInterfaceException(String s){
        super(s);
        sendException(this);
    }
    
    private void sendException(Exception x) {
        if (exceptionListeners.size() == 0) {
//            System.out.println("HardwareInterfaceException caught in HardwareInterfaceException listeners, stack trace is");
//            x.printStackTrace();
            return;
        }
        
        synchronized (exceptionListeners) {
            Iterator iter = exceptionListeners.iterator();
            while (iter.hasNext()) {
                ExceptionListener l = (ExceptionListener) iter.next();
                
                l.exceptionOccurred(x, this);
            }
        }
    }
    
    @SuppressWarnings("unchecked")
    static public void addExceptionListener(ExceptionListener l) {
        if (l != null) {
            exceptionListeners.add(l);
        }
    }
    
    static public void removeExceptionListener(ExceptionListener l) {
        exceptionListeners.remove(l);
    }
    
    /** use this static method to send a null message to all ExceptionListener's to signify that the exception condition is gone */
    static public void clearException(){
        new HardwareInterfaceException();
    }
    
}
