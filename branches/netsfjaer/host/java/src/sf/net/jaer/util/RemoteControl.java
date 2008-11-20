/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package sf.net.jaer.util;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.SocketException;
import java.util.HashMap;
import java.util.Observable;
import java.util.Observer;
import java.util.logging.Logger;

/**
 * Remote control via a datagram connection. Listeners add themselves with a command string and list of arguments.
 * Remote control builds a parser and returns calls the appropriate listener. The listener can access the arguments by name.
 * 
 * @author tobi
 */
public class RemoteControl {

    static Logger log = Logger.getLogger("RemoteControl");
    private int port = 8995;
    private HashMap<String, RemoteControlled> controlledMap = new HashMap<String, RemoteControlled>();
    private HashMap<String, RemoteControlled> cmdMap = new HashMap<String, RemoteControlled>();
    private HashMap<String, String> descriptionMap = new HashMap<String, String>();
    DatagramSocket datagramSocket;

    /** Creates a new instance. 
     * 
     * @param port the UDP port number this RemoteControl listens on.
     * 
     */
    public RemoteControl(int port) throws SocketException {
        this.port = port;
        datagramSocket = new DatagramSocket(port);
        new RemoteControlDatagramSocketThread().start();
    }

    public void addCommandListener(RemoteControlled remoteControlled, String cmd, String description) {
        if(cmd==null || cmd.length()==0) throw new Error("tried to add null or empty commad");
        String[] tokens=cmd.split("\\s");
        if(controlledMap.containsKey(tokens[0])){
            throw new Error("observers already contains key "+tokens[0]+" for command "+cmd+", existing command is "+controlledMap.get(cmd));
        }
        String cmdName=tokens[0];
        controlledMap.put(cmdName, remoteControlled);
        cmdMap.put(cmdName,cmd);
        descriptionMap.put(cmdName, description);
    }

    class RemoteControlDatagramSocketThread extends Thread {

        RemoteControlDatagramSocketThread() {
            setName("RemoteControlDatagramSocketThread");
        }

        @Override
        public void run() {
            while (true) {
                try {
                    DatagramPacket packet = new DatagramPacket(new byte[1024], 1024);
                    ByteArrayInputStream bis;
                    BufferedReader reader = new BufferedReader(new InputStreamReader((bis = new ByteArrayInputStream(packet.getData()))));
                    datagramSocket.receive(packet);
                    System.out.println(reader.readLine());
//                    DatagramPacket echogram=new DatagramPacket(packet.getData(),packet.getLength());
//                    echogram.setSocketAddress(new InetSocketAddress(packet.getAddress(), packet.getPort()));
//                    datagramSocket.send(echogram);
                } catch (IOException ex) {
                    log.warning(ex.toString());
                    break;
                }

            }
        }
    }

    public static void main(String[] args) throws SocketException {
        new RemoteControl(8995);
    }
}
