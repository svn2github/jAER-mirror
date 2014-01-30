/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sf.jaer.eventprocessing.label;

import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.DvsOrientationEvent;
import net.sf.jaer.event.EventPacket;
import net.sf.jaer.event.MotionOrientationEvent;
import net.sf.jaer.event.OrientationEventInterface;
import net.sf.jaer.event.OutputEventIterator;
import net.sf.jaer.event.PolarityEvent;

/**
 * Outputs local motion events derived from time of flight of orientation events from DVS sensors. 
 * @author tobi
 */
public class DvsDirectionSelectiveFilter extends AbstractDirectionSelectiveFilter {

    public DvsDirectionSelectiveFilter(AEChip chip) {
        super(chip);
    }

    synchronized public EventPacket filterPacket(EventPacket in) {
        // we use two additional packets: oriPacket which holds the orientation events, and dirPacket that holds the dir vector events
        oriPacket = oriFilter.filterPacket(in);  // compute orientation events.  oriFilter automatically sends bypassed events to oriPacket
        if (dirPacket == null) {
            dirPacket = new EventPacket(MotionOrientationEvent.class);
        }
        oriPacket.setOutputPacket(dirPacket); // so when we iterate over oriPacket we send the bypassed APS events to dirPacket
        checkMap();
        // filter
        lastNumInputCellTypes = in.getNumCellTypes();

        int n = oriPacket.getSize();

        // if the input is ON/OFF type, then motion detection doesn't make much sense because you are likely to detect
        // the nearest event from along the same edge, not from where the edge moved from.
        // therefore, this filter only really makes sense to use with an oriented input.
        //
        // when the input is oriented (e.g. the events have an orientation type) then motion estimation consists
        // of just checking in a direction *perpindicular to the edge* for the nearest event of the same input orientation type.
        // for each event write out an event of type according to the direction of the most recent previous event in neighbors
        // only write the event if the delta time is within two-sided threshold
//        hist.reset();
        try {
//            long stime=System.nanoTime();
//            if(timeLimitEnabled) timeLimiter.start(getTimeLimitMs()); // ns from us by *1024
            OutputEventIterator outItr = dirPacket.outputIterator(); // this initializes the output iterator of dirPacket
            for (Object ein : oriPacket) { // as we iterate using the built-in next() method we will bypass APS events to the dirPacket outputPacket of oriPacket using its output iterator

                OrientationEventInterface e = (OrientationEventInterface) ein;
                int x = ((e.getX() >>> subSampleShift) + P); // x and y are offset inside our timestamp storage array to avoid array access violations
                int y = ((e.getY() >>> subSampleShift) + P);
                int polValue = ((e.getPolarity() == PolarityEvent.Polarity.On ? 1 : 2));
                byte ori=e.getOrientation();
                byte type = (byte) (ori * polValue); // type information here is mixture of input orientation and polarity, in order to match both characteristics
                int ts = e.getTimestamp();  // getString event x,y,type,timestamp of *this* event
                // update the map here - this is ok because we never refer to ourselves anyhow in computing motion
                lastTimesMap[x][y][type] = ts;

                // for each output cell type (which codes a direction of motion), find the dt
                // between the orientation cell type perdindicular
                // to this direction in this pixel and in the neighbor - but only find the dt in that single direction.
                // also, only find time to events of the same *polarity* and orientation. otherwise we will falsely match opposite polarity
                // orientation events which arise from two sides of edges
                // find the time of the most recent event in a neighbor of the same type as the present input event
                // but only in the two directions perpindiclar to this orientation. Each of these codes for motion but in opposite directions.
                // ori input has type 0 for horizontal (red), 1 for 45 deg (blue), 2 for vertical (cyan), 3 for 135 deg (green)
                // for each input type, check in the perpindicular directions, ie, (dir+2)%numInputCellTypes and (dir+4)%numInputCellTypes
                // this computation only makes sense for ori type input
                // neighbors are of same type
                // they are in direction given by unitDirs in lastTimesMap
                // the input type tells us which offset to use, e.g. for type 0 (0 deg horiz ori), we offset first in neg vert direction, then in positive vert direction
                // thus the unitDirs used here *depend* on orientation assignments in AbstractDirectionSelectiveFilter
                int dt1 = 0, dt2 = 0;
                int mindt1 = Integer.MAX_VALUE, mindt2 = Integer.MAX_VALUE;
                MotionOrientationEvent.Dir d;
                byte outType = ori; // set potential output type to be same as type to start

                d = MotionOrientationEvent.unitDirs[ori];

                int dist = 1, dist1 = 1, dist2 = 1, dt = 0, mindt = Integer.MAX_VALUE;

                if (!useAvgDtEnabled) {
                    // now iterate over search distance to find minimum delay between this input orientation event and previous orientiation input events in
                    // offset direction
                    for (int s = 1; s <= searchDistance; s++) {
                        dt = ts - lastTimesMap[x + s * d.x][y + s * d.y][type]; // this is time between this event and previous
                        if (dt < mindt1) {
                            dist1 = s; // dist is distance we found min dt
                            mindt1 = dt;
                        }
                    }
                    d = MotionOrientationEvent.unitDirs[ori + 4];
                    for (int s = 1; s <= searchDistance; s++) {
                        dt = ts - lastTimesMap[x + s * d.x][y + s * d.y][type];
                        if (dt < mindt2) {
                            dist2 = s; // dist is still the distance we have the global mindt
                            mindt2 = dt;
                        }
                    }
                    if (mindt1 < mindt2) { // if summed dt1 < summed dt2 the average delay in this direction is smaller
                        dt = mindt1;
                        outType = ori;
                        dist = dist1;
                    } else {
                        dt = mindt2;
                        outType = (byte) (ori + 4);
                        dist = dist2;
                    }
                    // if the time between us and the most recent neighbor event lies within the interval, write an output event
                    if (dt < maxDtThreshold && dt > minDtThreshold) {
                        float speed = 1e6f * (float) dist / dt;
                        avgSpeed = (1 - speedMixingFactor) * avgSpeed + speedMixingFactor * speed;
                        if (speedControlEnabled && speed > avgSpeed * excessSpeedRejectFactor) {
                            continue;
                        } // don't store event if speed too high compared to average
                        MotionOrientationEvent eout = (MotionOrientationEvent) outItr.nextOutput();
                        eout.copyFrom((DvsOrientationEvent) ein);
                        eout.direction = outType;
                        eout.delay = (short) dt; // this is a actually the average dt for this direction
//                    eout.delay=(short)mindt; // this is the mindt found
                        eout.distance = (byte) dist;
                        eout.speed = speed;
                        eout.dir = MotionOrientationEvent.unitDirs[outType];
                        eout.velocity.x = -speed * eout.dir.x; // these have minus sign because dir vector points towards direction that previous event occurred
                        eout.velocity.y = -speed * eout.dir.y;
//                    avgSpeed=speedFilter.filter(MotionOrientationEvent.computeSpeedPPS(eout),eout.timestamp);
                        motionVectors.addEvent(eout);
//                    hist.add(outType);
                    }
                } else {
                    // use average time to previous ori events
                    // iterate over search distance to find average delay between this input orientation event and previous orientiation input events in
                    // offset direction. only count event if it falls in acceptable delay bounds
                    int n1 = 0, n2 = 0; // counts of passing matches, each direction
                    float speed1 = 0, speed2 = 0; // summed speeds
                    for (int s = 1; s <= searchDistance; s++) {
                        dt = ts - lastTimesMap[x + s * d.x][y + s * d.y][type]; // this is time between this event and previous
                        if (pass(dt)) {
                            n1++;
                            speed1 += (float) s / dt; // sum speed in pixels/us
                        }
                    }

                    d = MotionOrientationEvent.unitDirs[ori + 4];
                    for (int s = 1; s <= searchDistance; s++) {
                        dt = ts - lastTimesMap[x + s * d.x][y + s * d.y][type];
                        if (pass(dt)) {
                            n2++;
                            speed2 += (float) s / dt;
                        }
                    }

                    if (n1 == 0 && n2 == 0) {
                        continue; // no pass
                    }
                    float speed = 0;
                    dist = searchDistance / 2;
                    if (n1 > n2) {
                        speed = speed1 / n1;
                        outType = ori;
                    } else if (n2 > n1) {
                        speed = speed2 / n2;
                        outType = (byte) (ori + 4);
                    } else {
                        if (speed1 / n1 < speed2 / n2) {
                            speed = speed1 / n1;
                            outType = ori;
                        } else {
                            speed = speed2 / n2;
                            outType = (byte) (ori + 4);
                        }
                    }
//                    dt/= (searchDistance); // dt is normalized by search disance because we summed over the whole search distance

                    // if the time between us and the most recent neighbor event lies within the interval, write an output event
                    if (n1 > 0 || n2 > 0) {
                        speed = 1e6f * speed;
                        avgSpeed = (1 - speedMixingFactor) * avgSpeed + speedMixingFactor * speed;
                        if (speedControlEnabled && speed > avgSpeed * excessSpeedRejectFactor) {
                            continue;
                        } // don't output event if speed too high compared to average
                        MotionOrientationEvent eout = (MotionOrientationEvent) outItr.nextOutput();
                        eout.copyFrom((DvsOrientationEvent) ein);
                        eout.direction = outType;
                        eout.delay = (short) (dist * speed);
                        eout.distance = (byte) dist;
                        eout.speed = speed;
                        eout.dir = MotionOrientationEvent.unitDirs[outType];
                        eout.velocity.x = -speed * eout.dir.x; // these have minus sign because dir vector points towards direction that previous event occurred
                        eout.velocity.y = -speed * eout.dir.y;
                        motionVectors.addEvent(eout);
                    }
                }
            }
        } catch (ArrayIndexOutOfBoundsException e) {
            e.printStackTrace();
//            System.err.println("AbstractDirectionSelectiveFilter caught exception "+e+" probably caused by change of input cell type, reallocating lastTimesMap");
            checkMap();
        }

        if (isShowRawInputEnabled()) {
            return in;
        }
        return dirPacket; // returns the output packet containing both MotionOrientationEvent and the bypassed APS samples
    }

}
