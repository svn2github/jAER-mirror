/*
 * DvsOrientationFilter.java
 *
 * Created on November 2, 2005, 8:24 PM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */
package net.sf.jaer.eventprocessing.label;
import net.sf.jaer.chip.*;
import net.sf.jaer.event.*;
import net.sf.jaer.Description;
import net.sf.jaer.DevelopmentStatus;

/** Computes simple-type orientation-tuned cells.
 * A switch allows WTA mode (only max 1 event generated) or many event 
 * (any orientation that passes coincidence threshold).
 * Another switch allows contour enhancement by using previous output 
 * orientation events to make it easier to make events along the same orientation.
 * Another switch decides whether to use max delay or average delay as the coincidence measure.
 * <p>
 * Orientation type output takes values 0-3; 
 * 0 is a horizontal edge (0 deg),  
 * 1 is an edge tilted up and to right (rotated CCW 45 deg),
 * 2 is a vertical edge (rotated 90 deg), 
 * 3 is tilted up and to left (rotated 135 deg from horizontal edge).
 * <p>
 * The filter takes either PolarityEvents or BinocularEvents to create 
 * DvsOrientationEvent or BinocularEvents.
 * @author tobi/phess */
@Description("Detects local orientation by spatio-temporal correlation for DVS sensors")
@DevelopmentStatus(DevelopmentStatus.Status.Experimental)
public class DvsOrientationFilter extends AbstractOrientationFilter{
    private boolean isBinocular;
    /** Creates a new instance of SimpleAbstractOrientationFilter
     * @param chip */
    public DvsOrientationFilter (AEChip chip){
        super(chip);
        chip.addObserver(this);
        
        //Tooltips and Properties are defined in the AbstractOrientationFilter.
    }

    /** filters in to getOutputPacket(). 
     * if filtering is enabled, the number of getOutputPacket() may be less
     * than the number putString in
     * @param in input events can be null or empty.
     * @return the processed events, may be fewer in number. */
    @Override
    synchronized public EventPacket<?> filterPacket (EventPacket<?> in){
        if ( enclosedFilter != null ) in = enclosedFilter.filterPacket(in);
        if ( in.getSize() == 0 ) return in;

        Class inputClass = in.getEventClass();
        if ( inputClass == PolarityEvent.class) {
            isBinocular = false;
            checkOutputPacketEventType(DvsOrientationEvent.class);
        } else if( inputClass == BinocularEvent.class ) {
            isBinocular = true;
            checkOutputPacketEventType(BinocularOrientationEvent.class);
        } else { //Neither Polarity nor Binocular Event --> Wrong class used!
            log.warning("wrong input event class "+inputClass+" in the input packet" + in + ", disabling filter");
            setFilterEnabled(false);
            return in;
        }

        EventPacket outputPacket = getOutputPacket();
        OutputEventIterator outItr = outputPacket.outputIterator();

        int sizex = chip.getSizeX() - 1;
        int sizey = chip.getSizeY() - 1;

        oriHist.reset();
        checkMaps(in);

        // for each event write out an event of an orientation type if 
        // there have also been events within past dt along this 
        // type's orientation of the same retina polarity
        for ( Object ein:in ){
            PolarityEvent e = (PolarityEvent)ein;
            int type = e.getType();
            if (type >= NUM_TYPES || e.x<0||e.y<0) {
                continue;  // tobi - some special type like IMU sample
            }
            int x = e.x >>> subSampleShift;
            int y = e.y >>> subSampleShift;

            /* (Peter Hess) monocular events use eye = 0 as standard. therefore some arrays will waste memory, because eye will never be 1 for monocular events
             * in terms of performance this may not be optimal. but as long as this filter is not final, it makes rewriting code much easier, because
             * monocular and binocular events may be handled the same way. */
            int eye = 0;
            if ( isBinocular ){
                if ( ( (BinocularEvent)ein ).eye == BinocularEvent.Eye.RIGHT ){
                    eye = 1;
                }
            }
            if ( eye == 1 ){
                type = type << 1;
            }
            lastTimesMap[x][y][type] = e.timestamp;

            // getString times to neighbors in all directions
            // check if search distance has been changed before iterating - for some reason the synchronized doesn't work
            int xx, yy;
            for ( int ori = 0 ; ori < NUM_TYPES ; ori++ ){
                // for each orienation, compute the dts to each previous event in RF of this cell
                int[] dtsThisOri = dts[ori]; // this is ref to array of delta times
                Dir[] d = offsets[ori]; // this is vector of spatial offsets for this orientation from lookup table
                for ( int i = 0 ; i < d.length ; i++ ){ //=-length;s<=length;s++){ // now we march along both sides of this pixel
                    xx = x + d[i].x;
                    if ( xx < 0 || xx > sizex ){
                        continue;
                    }
                    yy = y + d[i].y;
                    if ( yy < 0 || yy > sizey ){
                        continue; // indexing out of array
                    }
                    dtsThisOri[i] = e.timestamp - lastTimesMap[xx][yy][type]; // the offsets are multiplied by the search distance
                    // x and y are already offset so that the index into the padded map, avoding ArrayAccessViolations
                }
            }

            if ( useAverageDtEnabled ){
                // now getString sum of dts to neighbors in each direction
                for ( int j = 0 ; j < NUM_TYPES ; j++ ){
                    maxdts[j] = 0; // this is sum here despite name maxdts
                    int m = dts[j].length;
                    int count = 0;
                    for ( int k = 0 ; k < m ; k++ ){
                        int dt = dts[j][k];
                        if ( dt > dtRejectThreshold ){
                            continue; // we're averaging delta times; this rejects outliers
                        }
                        maxdts[j] += dt; // average dt
                        count++;
                    }
                    if ( count > 0 ){
                        maxdts[j] /= count; // normalize by RF size
                    }
                    if ( count == 0 ){
                        // no samples, all outside outlier rejection threshold
                        maxdts[j] = Integer.MAX_VALUE;
                    }
                }
            } else{ // use max dt
                // now get maxdt to neighbors in each direction
                for ( int j = 0 ; j < NUM_TYPES ; j++ ){
                    maxdts[j] = Integer.MIN_VALUE;
                    int m = dts[j].length;
                    for ( int k = 0 ; k < m ; k++ ){  
                        // iterate over RF and find maxdt to previous events, final orientation will be that orientation that has minimum maxdt
                        // this has problem that pixels that do NOT fire an event still contribute a large dt from previous edges
                        maxdts[j] = dts[j][k] > maxdts[j] ? dts[j][k] : maxdts[j]; // max dt to neighbor
                    }
                }
            }

            if ( !multiOriOutputEnabled ){
                // here we do a WTA, only 1 event max gets generated in optimal 
                // orienation IFF is also satisfies coincidence timing requirement

                // now find min of these, this is most likely orientation, iff this time is also less than minDtThreshold
                int mindt = minDtThreshold, dir = -1;
                for ( int k = 0 ; k < NUM_TYPES ; k++ ){
                    if ( maxdts[k] < mindt ){
                        mindt = maxdts[k];
                        dir = k;
                    }
                }

                if ( dir == -1 ){ // didn't find a good orientation
                    if ( passAllEvents ){
                        if ( !isBinocular ){
                            DvsOrientationEvent eout = (DvsOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.hasOrientation = false;
                        } else{
                            BinocularOrientationEvent eout = (BinocularOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.hasOrientation = false;
                        }
                    }
                    // no dt was < threshold
                    continue;
                }
                if ( oriHistoryEnabled ){
                    // update lowpass orientation map
                    float f = oriHistoryMap[x][y];
                    f = ( 1 - oriHistoryMixingFactor ) * f + oriHistoryMixingFactor * dir;
                    oriHistoryMap[x][y] = f;

                    float fd = f - dir;
                    final int halfTypes = NUM_TYPES / 2;
                    if ( fd > halfTypes ){
                        fd = fd - NUM_TYPES;
                    } else if ( fd < -halfTypes ){
                        fd = fd + NUM_TYPES;
                    }
                    if ( Math.abs(fd) > oriDiffThreshold ){
                        continue;
                    }
                }
                // now write output cell iff all events along dir occur within minDtThreshold
                if ( isBinocular ){
                    BinocularOrientationEvent eout = (BinocularOrientationEvent)outItr.nextOutput();
                    eout.copyFrom(e);
                    eout.orientation = (byte)dir;
                    eout.hasOrientation = true;
                } else{
                    DvsOrientationEvent eout = (DvsOrientationEvent)outItr.nextOutput();
                    eout.copyFrom(e);
                    eout.orientation = (byte)dir;
                    eout.hasOrientation = true;
                }
//                lastOutputTimesMap[e.x][e.y][dir][eye]=e.timestamp;
                oriHist.add(dir);
            } else{
                // here events are generated in oris that satisfy timing; there is no WTA
                for ( int k = 0 ; k < NUM_TYPES ; k++ ){
                    if ( maxdts[k] < minDtThreshold ){
                        if ( isBinocular ){
                            BinocularOrientationEvent eout = (BinocularOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.orientation = (byte)k;
                            eout.hasOrientation = true;
                        } else {
                            DvsOrientationEvent eout = (DvsOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.orientation = (byte)k;
                            eout.hasOrientation = true;
                        }
//                        lastOutputTimesMap[e.x][e.y][k][eye]=e.timestamp;
                        oriHist.add(k);
                    } else {
                        if ( isBinocular ){
                            BinocularOrientationEvent eout = (BinocularOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.hasOrientation = false;
                        } else {
                            DvsOrientationEvent eout = (DvsOrientationEvent)outItr.nextOutput();
                            eout.copyFrom(e);
                            eout.hasOrientation = false;
                        }
                    }
                }
            }
        }
        final int ORI_SHIFT = 16; // will shift our orientation value this many bits in raw address
        for (Object o : outputPacket) {
            DvsOrientationEvent e = (DvsOrientationEvent) o;
            e.address = e.address | (e.orientation << ORI_SHIFT);
        }
        
        //Show the events instead of the directions
        if(showRawInputEnabled) {
            return in;
        }
        return getOutputPacket();
    }
}
