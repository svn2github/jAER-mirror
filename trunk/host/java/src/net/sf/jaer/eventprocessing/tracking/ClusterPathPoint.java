package net.sf.jaer.eventprocessing.tracking;

import java.awt.geom.Point2D;

/**
 * One point on a Cluster's path, including other statistics of the cluster history.
 *
 */
public class ClusterPathPoint extends Point2D.Float {

    /** timestamp of this point. */
    public int t;
    /** Number of events that contributed to this point. */
    private int nEvents;
    /** Velocity of cluster (filtered) at this point in pixels per timestamp tick (e.g. us).
     * This field is initially null and is initialized by the velocityPPT estimation, if used. */
    public Point2D.Float velocityPPT=null;

    public ClusterPathPoint(float x, float y, int t, int numEvents) {
        super();
        this.x = x;
        this.y = y;
        this.t = t;
        this.nEvents = numEvents;
    }

    public int getT() {
        return t;
    }

    public int getNEvents() {
        return nEvents;
    }

    public String toString() {
        return String.format("%d, %f, %f, %d", t, x, y, nEvents);
    }
}
