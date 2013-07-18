/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.ine.telluride.jaer.tell2013.spinnakeraudrobot;

import ch.unizh.ini.jaer.projects.cochsoundloc.ISIFilter;
import ch.unizh.ini.jaer.projects.cochsoundloc.ITDFilter;
import java.io.IOException;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.SocketException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.channels.DatagramChannel;
import java.util.logging.Level;
import java.util.logging.Logger;
import net.sf.jaer.Description;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.eventprocessing.FilterChain;
import net.sf.jaer.graphics.AePlayerAdvancedControlsPanel;
import org.ine.telluride.jaer.tell2009.CochleaGenderClassifier;
import org.ine.telluride.jaer.tell2013.spinnakeraudrobot.OmniRobotControl.MotorCommand;

/**
 * Uses ITDFilter and ISIFilter to to control OmniRobot to steer towards sound sound for Telluride 2013 UNS project
 *
 * @author tobi
 */
@Description("Uses ITDFilter and ISIFilter to to control OmniRobot to steer towards sound sound for Telluride 2013 UNS project")
public class CochleaOmnRobotiSexChaser extends EventFilter2D {

    private ITDFilter itdFilter;
    private ISIFilter isiFilter;
    private OmniRobotControl omniRobotControl;
    private CochleaGenderClassifier genderClassifier;
    private int bestItdBin = -1;
    

    public CochleaOmnRobotiSexChaser(AEChip chip) {
        super(chip);
        FilterChain filterChain = new FilterChain(chip);
        filterChain.add(omniRobotControl=new OmniRobotControl(chip));
        filterChain.add(itdFilter = new ITDFilter(chip));
//        filterChain.add(isiFilter = new ISIFilter(chip));
        filterChain.add(genderClassifier=new CochleaGenderClassifier(chip));
        setEnclosedFilterChain(filterChain);
    }

    @Override
    synchronized public EventPacket<?> filterPacket(EventPacket<?> in) {
        getEnclosedFilterChain().filterPacket(in);
        int currentBestItdBin = itdFilter.getBestITD();
        if (currentBestItdBin != bestItdBin) { // only do something if bestItdBin changes
            bestItdBin = currentBestItdBin;
            // here is the business logic
            if (bestItdBin > itdFilter.getNumOfBins() / 2) {
                omniRobotControl.sendMotorCommand(MotorCommand.cw);
            } else if (bestItdBin < itdFilter.getNumOfBins() / 2) {
                omniRobotControl.sendMotorCommand(MotorCommand.ccw);
            }
        }
        return in;
    }


    @Override
    public void initFilter() {
    }

    @Override
    public void resetFilter() {
    }

}
