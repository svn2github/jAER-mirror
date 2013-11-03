/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package ch.unizh.ini.jaer.projects.laser3d;

import com.sun.opengl.util.j2d.TextRenderer;
import java.awt.Font;
import java.util.ArrayList;
import java.util.Arrays;
import javax.media.opengl.GL;
import javax.media.opengl.GLException;

/**
 * PxlScoreMap holds a score for each pixel.
 *
 * @author Thomas
 */
public class PxlScoreMap {

    private int mapSizeX;
    private int mapSizeY;
    // pxlScore is moving average over historySize scores
    private float[][] pxlScore;
    private float[][][] pxlScoreHistory; // past score(s), 1 for IIR, historySize for FIR
    private float[] colSums, weightedColSums; // holds column-wise statistics
    private FilterLaserline filter;
    private int historySize;
    private boolean firFilterEnabled = false; // true to use old (inefficient) FIR box filter, false to use IIR lowpass score map
    private TextRenderer textRenderer = new TextRenderer(new Font("SansSerif", Font.PLAIN, 36));
    private boolean rollingAverageScoreMapUpdate; // true to update average score map during each event, using a rolling cursor
    private int xCursor = 0, yCursor = 0;
    float updateFactor, updateFactor1;  // update constant

    /**
     * Creates a new instance of PxlMap
     *
     * @param sx width of the map in pixels
     * @param sy height of the map in pixels
     * @param filter invoking EventFilter2D for loging
     */
    public PxlScoreMap(int sx, int sy, FilterLaserline filter) {
        this.filter = filter;
        this.mapSizeX = sx;
        this.mapSizeY = sy;
        rollingAverageScoreMapUpdate = filter.getBoolean("rollingAverageScoreMapUpdate", false);
        this.historySize = filter.getPxlScoreHistorySize();
        updateFactor = 1f / historySize;
        updateFactor1 = 1 - updateFactor;  // update constant
    }

    public void draw(GL gl) {
        if (pxlScore == null) {
            return;
        }
        try {
            gl.glEnable(GL.GL_BLEND);
            gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
            gl.glBlendEquation(GL.GL_FUNC_ADD);
        } catch (GLException e) {
            e.printStackTrace();
        }
        float max = Float.NEGATIVE_INFINITY, min = Float.POSITIVE_INFINITY;
        for (int x = 0; x < mapSizeX; x++) {
            for (int y = 0; y < mapSizeY; y++) {
                float v = pxlScore[x][y];
                if (v > max) {
                    max = v;
                } else if (v < min) {
                    min = v;
                }
            }
        }
        if (max - min <= 0) {
            max = 1;
            min = 0;
        } // avoid div by zero
        final float diff = max - min;
        final float displayTransparency = .9f;
        for (int x = 0; x < mapSizeX; x++) {
            for (int y = 0; y < mapSizeY; y++) {
                float v = (pxlScore[x][y] - min) / diff;
                gl.glColor4f(v, v, 0, displayTransparency);
                gl.glRectf(x, y, x + 1, y + 1);
            }
        }
        final float textScale = .2f;
        textRenderer.begin3DRendering();
        textRenderer.setColor(1, 1, 0, 1);
        textRenderer.draw3D(String.format("max score=%.2f, min score=%.2f", max, min), 5, 5, 0, textScale); // x,y,z, scale factor
        textRenderer.end3DRendering();
    }

    /**
     * sets the score of each pixel to 0
     */
    public final void resetMap() {
      if (pxlScore != null) {
          Arrays.fill(colSums,0f);
          Arrays.fill(weightedColSums, 0f);
            for (int x = 0; x < mapSizeX; x++) {
                Arrays.fill(pxlScore[x], 0f);
                for (int y = 0; y < mapSizeY; y++) {
                    Arrays.fill(pxlScoreHistory[x][y], 0f);
                }
            }
        }
    }

    /**
     * initializes PxlScoreMap (allocates memory)
     */
    public void initMap() {
        allocateMaps();
        resetMap();
    }

    private void allocateMaps() {
        if (mapSizeX > 0 & mapSizeY > 0) {
            pxlScore = new float[mapSizeX][mapSizeY];
            pxlScoreHistory = new float[mapSizeX][mapSizeY][historySize + 1];
            colSums=new float[mapSizeX];
            weightedColSums=new float[mapSizeX];
        }
    }

    /**
     * Get score of specific pixel
     *
     * @param x
     * @param y
     * @return score of pixel (x,y)
     */
    public float getScore(int x, int y) {
        if (x >= 0 & x <= mapSizeX & y >= 0 & y <= mapSizeY) {
            return pxlScore[x][y];
        } else {
            filter.log.warning("PxlScoreMap.getScore(): pixel not on chip!");
        }
        return 0;
    }

    /**
     * set score of pixel (x,y).
     *
     * probably #addToSCore is better choice
     *
     * @param x
     * @param y
     * @param score
     */
    public void setScore(int x, int y, float score) {
        if (x >= 0 & x <= mapSizeX & y >= 0 & y <= mapSizeY) {
            pxlScoreHistory[x][y][0] = score;
        } else {
            filter.log.warning("PxlScoreMap.setScore(): pixel not on chip!");
        }
    }

    /**
     * update score
     *
     * @param x
     * @param y
     * @param score
     */
    public void addToScore(int x, int y, float score) {
        if (rollingAverageScoreMapUpdate) {
            // here we update the target pixel of score map, and at same time we update the next cursor pixel average
            final float oldScore=pxlScore[x][y];
            pxlScore[x][y] = updateFactor1*oldScore+updateFactor*score; // mix old score and contribution of this score, to maintain same scaling as non-rolling approach
            pxlScore[xCursor][yCursor] *= updateFactor1; // decay cursor pixel
            xCursor++;
            if (xCursor >= mapSizeX) {
                xCursor = 0;
                yCursor++;
                if (yCursor >= mapSizeY) {
                    yCursor = 0;
                }
            }
            // update column statistics
            final float diff=pxlScore[x][y]-oldScore;
            colSums[x]+=diff;
            weightedColSums[x]+=y*diff;
        } else {
            pxlScoreHistory[x][y][0] += score;
        }
    }

    /**
     * Updates the score map average
     */
    public void updatePxlScoreAverageMap() {
        historySize = filter.getPxlScoreHistorySize();
        updateFactor = 1f / historySize;
        updateFactor1 = 1 - updateFactor;  // update constant, update for rolling update use

        if (rollingAverageScoreMapUpdate) {
            return; // do the update there
        }        
        // apply moving average on score history
        if (firFilterEnabled) {
            for (int x = 0; x < mapSizeX; x++) {
                for (int y = 0; y < mapSizeY; y++) {
                    if (historySize > 0) {
                        pxlScore[x][y] -= pxlScoreHistory[x][y][historySize] / historySize;
                        pxlScore[x][y] += pxlScoreHistory[x][y][0] / historySize;
                        /* shift history */
                        for (int i = historySize; i > 0; i--) {
                            pxlScoreHistory[x][y][i] = pxlScoreHistory[x][y][i - 1];
                        }
                    } else {
                        pxlScore[x][y] = pxlScoreHistory[x][y][0];
                    }
                    // dump small scores
                    if (Math.abs(pxlScore[x][y]) < 1e-3) {
                        pxlScore[x][y] = 0;
                    }
                    /* reset pxlScore */
                    pxlScoreHistory[x][y][0] = 0;
//                if (Double.isNaN(pxlScore[x][y])) {
//                    filter.log.info("NaN!");
//                }
                }
            }
        } else { // use IIR low pass on score map
            for (int x = 0; x < mapSizeX; x++) {
                for (int y = 0; y < mapSizeY; y++) {
                    pxlScore[x][y] = updateFactor1 * pxlScore[x][y] + updateFactor * pxlScoreHistory[x][y][0]; // take (1-a) of the old score plus a times the new score, e.g. if historySize=5, then take 4/5 of the old score and 1/5 of the new one
                    pxlScoreHistory[x][y][0] = 0; // start accumulating new score here
                }
            }
        }
    }


    /*
     * Update laserline
     * rewrites the arraylist with updated pixels classified as on laser line
     * 
     * @param laserline
     * 
     * @return laserline
     */
    ArrayList updateLaserline(ArrayList laserline) {
        laserline.clear();
        float threshold = findThreshold();
        for (int x = 0; x < mapSizeX; x++) {
            for (int y = 0; y < mapSizeY; y++) {
                float[] pxl;
                float sumScores = 0;
                float sumWeightedCoord = 0;
                while (pxlScore[x][y] > threshold) {
                    sumWeightedCoord += (y * pxlScore[x][y]);
                    sumScores += pxlScore[x][y];
                    y++;
                    if (y >= mapSizeY) {
                        break;
                    }
                }
                if (sumScores > 0) {
                    pxl = new float[2];
                    pxl[0] = x;
                    pxl[1] = sumWeightedCoord / sumScores;
                    laserline.add(pxl);
                }
            }
        }
        return laserline;
    }

    /**
     *
     * @return
     */
    public int getMapSizeX() {
        return mapSizeX;
    }

    /**
     *
     * @return
     */
    public int getMapSizeY() {
        return mapSizeY;
    }

    /**
     *
     * @return
     */
    public float findThreshold() {
        float threshold = filter.getPxlScoreThreshold();

//        float[] allScores = new float[mapSizeX*mapSizeY];
//        int i = 0;
//        for (int x = 0; x < mapSizeX; x++) {
//            for (int y = 0; y < mapSizeY; y++) {
//                allScores[i] = pxlScore[x][y];
//                i++;
//            }
//        }
//        Arrays.sort(allScores);

        return threshold;
    }

    /**
     * @return the firFilterEnabled
     */
    public boolean isFirFilterEnabled() {
        return firFilterEnabled;
    }

    /**
     * @param firFilterEnabled the firFilterEnabled to set
     */
    public void setFirFilterEnabled(boolean firFilterEnabled) {
        this.firFilterEnabled = firFilterEnabled;
    }

    /**
     * @return the pxlScore
     */
    public float[][] getPxlScore() {
        return pxlScore;
    }

    /**
     * @return the rollingAverageScoreMapUpdate
     */
    public boolean isRollingAverageScoreMapUpdate() {
        return rollingAverageScoreMapUpdate;
    }

    /**
     * @param rollingAverageScoreMapUpdate the rollingAverageScoreMapUpdate to
     * set
     */
    public void setRollingAverageScoreMapUpdate(boolean rollingAverageScoreMapUpdate) {
        this.rollingAverageScoreMapUpdate = rollingAverageScoreMapUpdate;
        filter.putBoolean("rollingAverageScoreMapUpdate", rollingAverageScoreMapUpdate);
    }

    /**
     * @return the colSums
     */
    public float[] getColSums() {
        return colSums;
    }

    /**
     * @return the weightedColSums
     */
    public float[] getWeightedColSums() {
        return weightedColSums;
    }
}
