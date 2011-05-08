/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * PcaTrackingFilter.java
 *
 * @author David Mascarenas
 * Created on July 11, 2010
 *
 * "This is meant to identify a playing card moving quickly across the field of
 *view of the retina.  It uses PCA tracking, and should be precedded by a
 *medianTrackingFilter"
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */

package telluride2010.dlm.fastcardID;
import net.sf.jaer.chip.AEChip;
import net.sf.jaer.event.*;
import net.sf.jaer.eventprocessing.EventFilter2D;
import net.sf.jaer.graphics.FrameAnnotater;
import java.awt.geom.*;
import javax.media.opengl.*;
import javax.media.opengl.GLAutoDrawable;
import net.sf.jaer.graphics.MultilineAnnotationTextRenderer;
//package org.ine.telluride.jaer.tell2010.cardplayer;
import org.ine.telluride.jaer.tell2010.cardplayer.CardHistogram;
import org.ine.telluride.jaer.tell2010.cardplayer.CardStatsMessageSender;
import java.util.Arrays;

import org.ine.telluride.jaer.tell2010.spinningcardclassifier.CardNamePlayer;

//DLM additions
import java.io.*;
import net.sf.jaer.Description;



@Description("Tracks a single object pose by Principle Components Analysis")
public class FastCardID extends EventFilter2D implements FrameAnnotater {

    //This is just a thing that only lets the UDP send data if at least this number of events is observed.  
    
    int min_number_events=getPrefs().getInt("FastCardID.min_number_events",6000);
    {setPropertyTooltip("min_number_events","minimum number of events needed to send UDP message");}


    int card_event_index = 0;
    
    //Required variables for this class.
    float xsum = 0f;
    float ysum = 0f;
    float xxsum = 0f;
    float yysum = 0f;
    float xysum = 0f;

    float xmean = 0f;
    float ymean = 0f;
    float xxvar = 0f;
    float yyvar = 0f;
    float xycovar = 0f;

    int n = 4096;
    //int n = 2048;
    //int n = 1024;                    //This is the length of the ring buffer
    //int n = 512;
    //int n = 256;
    //int n = 128;          //This worked well for alot of the card data
    //int n = 64;

    //int scale_stddev = 1;


    //protected int dt=getPrefs().getInt("BackgroundActivityFilter.dt",30000);
    //{setPropertyTooltip("dt","Events with less than this delta time in us to neighbors pass through");}
    private CardNamePlayer[] namePlayers = new CardNamePlayer[13];  //This is used to call out the names of the cards
    private int minSayCardIntervalMs = prefs().getInt("ClusterBasedPipCounter.minSayCardIntervalMs", 400);
    private long lastTimeSaidCar = 0;


    double stddev_inc = .1;     //I need this so I can exert fine control over the size of the bounding box.
    int scale_stddev=getPrefs().getInt("FastCardID.scale_stddev",10);
    {setPropertyTooltip("scale_stddev","Scale of bounding box relative to the standard deviation (.1 * standard dev)");}

     int ring_buffer_length=getPrefs().getInt("FastCardID.ring_buffer_length",1024);
    {setPropertyTooltip("ring_buffer_length","Length of the ring buffer.  Max 4092");}


    float[] ring_bufferX = new float[n];      //This is the array for the the ring buffer.  I need to make sure this is initialized to zeros
    float[] ring_bufferY = new float[n];
    int rb_index = 0;       //This is the ring buffer index

    //aspect ratio values
    double aspect_ratio = 0;    //This is the aspect ratio of the std deviations.
    double aspect_ratio_error = 0;
    double aspect_ratio_card = 1.4 ;// (3.5 in/2.5 in);

    double aspect_ratio_allowable_error_inc = .01;

    int aspect_ratio_allowable_error_pts=getPrefs().getInt("FastCardID.aspect_ratio_allowable_error_pts",10);
    {setPropertyTooltip("aspect_ratio_allowable_error_pts","Aspect ratio allowable error in pts");}

     int pip_bin_hist_threshold=getPrefs().getInt("FastCardID.pip_bin_hist_threshold",10);
    {setPropertyTooltip("pip_bin_hist_threshold","number of events needed in a bin to 'see' a pip");}

     //Tobi's UDP message sender
     CardStatsMessageSender msgSender = new CardStatsMessageSender();
     

    //histogram variables
    //int[] card_value_hist = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};    //This is a histogram for the number of the card
    double[] pip_bin_hist = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};             //This is the count of events in a given sector of the card
    int[] pip_bin_active = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    int pip_count = 0;

    //flags
    boolean card_present_flag = false;

    double relx = 0;
    double rely = 0;
    double cardx = 0;
    double cardy = 0;


    double theta = 0f;      //The angle the data is decorrelated at

    double R1 = 0f;
    double R2 = 0f;
    double R3 = 0f;
    double R4 = 0f;

    /////////////////////////////////////////


    Point2D medianPoint=new Point2D.Float(), stdPoint=new Point2D.Float(), meanPoint=new Point2D.Float(), eigvec1Point = new Point2D.Float(), eigvec2Point = new Point2D.Float();
    Point2D square1Point=new Point2D.Float(), square2Point=new Point2D.Float(), square3Point=new Point2D.Float(), square4Point=new Point2D.Float() ;
    Point2D eventPoint = new Point2D.Float();
    Point2D stddev1Point=new Point2D.Float();
    Point2D stddev2Point=new Point2D.Float();

    //pipbin points
    Point2D pipbiny1trPoint= new Point2D.Float(), pipbiny1brPoint= new Point2D.Float(), pipbiny1tlPoint= new Point2D.Float(), pipbiny1blPoint= new Point2D.Float();
    Point2D pipbiny2tlPoint= new Point2D.Float(), pipbiny2blPoint= new Point2D.Float(), pipbiny3tlPoint= new Point2D.Float(), pipbiny3blPoint= new Point2D.Float(); 
    Point2D pipbiny2trPoint= new Point2D.Float(), pipbiny2brPoint= new Point2D.Float(), pipbiny3trPoint= new Point2D.Float(), pipbiny3brPoint= new Point2D.Float();
    Point2D pipbinx4trPoint= new Point2D.Float(), pipbinx4tlPoint= new Point2D.Float(), pipbinx4brPoint= new Point2D.Float(), pipbinx4blPoint= new Point2D.Float();
    Point2D pipbinx3trPoint= new Point2D.Float(), pipbinx3tlPoint= new Point2D.Float(), pipbinx3brPoint= new Point2D.Float(), pipbinx3blPoint= new Point2D.Float();
    Point2D pipbinx2trPoint= new Point2D.Float(), pipbinx2tlPoint= new Point2D.Float(), pipbinx2brPoint= new Point2D.Float(), pipbinx2blPoint= new Point2D.Float();
    Point2D pipbinx1trPoint= new Point2D.Float(), pipbinx1tlPoint= new Point2D.Float(), pipbinx1brPoint= new Point2D.Float(), pipbinx1blPoint= new Point2D.Float();
    Point2D pipbinx5trPoint= new Point2D.Float(), pipbinx5tlPoint= new Point2D.Float(), pipbinx5brPoint= new Point2D.Float(), pipbinx5blPoint= new Point2D.Float();
    Point2D pipbinx6trPoint= new Point2D.Float(), pipbinx6tlPoint= new Point2D.Float(), pipbinx6brPoint= new Point2D.Float(), pipbinx6blPoint= new Point2D.Float();
    Point2D pipbinx7trPoint= new Point2D.Float(), pipbinx7tlPoint= new Point2D.Float(), pipbinx7brPoint= new Point2D.Float(), pipbinx7blPoint= new Point2D.Float();

    //pipbin display  points
    Point2D pipbinPoint0= new Point2D.Float();
    Point2D pipbinPoint1= new Point2D.Float();
    Point2D pipbinPoint2= new Point2D.Float();
    Point2D pipbinPoint3= new Point2D.Float();
    Point2D pipbinPoint4= new Point2D.Float();
    Point2D pipbinPoint5= new Point2D.Float();
    Point2D pipbinPoint6= new Point2D.Float();
    Point2D pipbinPoint7= new Point2D.Float();
    Point2D pipbinPoint8= new Point2D.Float();
    Point2D pipbinPoint9= new Point2D.Float();
    Point2D pipbinPoint10= new Point2D.Float();
   
    double pipdisplayscale = 5;


    float xmedian=0f;
    float ymedian=0f;
    float xstd=0f;
    float ystd=0f;
    //float xmean=0, ymean=0;
    int lastts=0, dt=0;
    int prevlastts=0;

    //This is kind of the heart of the card ID

    //three vertical columns
    double biny1 = .2;
    double biny2 = .3;
    double biny3 = .7;

    //Left and right x columns
    double binx1 = .0362;
    double binx2 = .374;
    double binx3 = .446;
    double binx4 = .784;

    //middle column
    double binx5 = .143;
    double binx6 = .3571;
    double binx7 = .643;


    //Tobi's card histogram classes
    CardHistogram cardHist = new CardHistogram();

    //mle
    int max_bin_mle = 0;

    //FIle IO
    boolean first_event = true;
    

    //==========================================================================
    //This is the Dictionary of pip hist values used to identify the cards

    int num_cards_considered = 10;

    /*
    double[][] pip_hist_dictionary = {
        {446, 8, 40, 396, 127, 136, 32, 608, 26, 24, 176},          //A
        {38, 56, 86, 34, 194, 186, 146, 28, 46, 22, 54},            //2
        {52, 157, 147, 129, 620, 1044, 744, 323, 240, 142, 200},    //3
        {520, 69, 19, 147, 90, 9, 30, 556, 77, 36, 175},            //4
        {632, 43, 165, 1280, 39, 1705, 105, 587, 177, 33, 1673},    //5
        {289, 204, 347, 284, 18, 77, 58, 356, 383, 197, 464},       //6
        {524, 161, 339, 381, 67, 69, 369, 222, 578, 170, 391},      //7
        {261, 451, 314, 259, 370, 82, 296, 339, 284, 372, 329},     //8
        {510, 654, 624, 457, 127, 531, 88, 407, 462, 677, 682},     //9
        {572, 561, 584, 579, 616, 121, 423, 580, 618, 603, 585},    //10
        {527, 501, 614, 856, 370, 1350, 264, 972, 474, 572, 579},   //J
        {746, 1022, 605, 1163, 693, 207, 568, 921, 701, 928, 830},  //Q
        {38, 23, 16, 57, 23, 26, 22, 70, 3, 35, 24},                //K
    };
     */

    double[][] pip_hist_dictionary = {
        {0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0},          			//A
        //{0, 0, 0, 0, 100, 0, 100, 0, 0, 0, 0},            			//2
        //{0, 0, 0, 0, 100, 100, 100, 0, 0, 0, 0},    				//3
        
        //{446, 8, 40, 396, 127, 136, 32, 608, 26, 24, 176},                      //A
        //{38, 56, 86, 34, 194, 186, 146, 28, 46, 22, 54},                        //2
        {1432, 22, 9, 106, 412, 10, 473, 842, 12, 45, 812},        //Tobi settings for 2
        //{52, 157, 147, 129, 620, 1044, 744, 323, 240, 142, 200},                //3
        {1643, 66, 415, 77, 1120, 2270, 562, 273, 131, 194, 676},  //Tobi settings for 3
        {1830, 438, 158, 1048, 354, 62, 84, 1967, 1179, 385, 774},		//4
        {100, 0, 0, 100, 0, 100, 0, 100, 0, 0, 100},				//5
	{289, 204, 347, 284, 18, 77, 58, 356, 383, 197, 464},                   //6
        //{289, 204, 347, 284, 18, 300, 58, 356, 383, 197, 464},                  //7 (This is the same as 6.  I just took out the middle element and replaced it with 300 to indicate a middle pip)
	{371, 2296, 1823, 1180, 232, 405, 2492, 206, 2194, 1780, 1278  }, //Tobi settings for 7
        //{289, 204, 347, 284, 300, 77, 300, 356, 383, 197, 464},                 //8  (This is the same as 6.  I just took out the outer two middle element and replaced them with 300 to indicate a outer middle pip)
        {1139, 1763, 1695, 952, 1940, 862, 1984, 995, 1140, 1752, 1118},    // Tobi settings for 8

        {100, 100, 100, 100, 0, 100, 0, 100, 100, 100, 100},                    //9
        {100, 100, 100, 100, 100, 0, 100, 100, 100, 100, 100},                  //10
        {527, 501, 614, 856, 370, 1350, 264, 972, 474, 572, 579},               //J
        {746, 1022, 605, 1163, 693, 207, 568, 921, 701, 928, 830},              //Q
        {38, 23, 16, 57, 23, 26, 22, 70, 3, 35, 24},                            //K
    };


    //now the pip_hist_dictionary needs to be normalized across the rows.
    //This normalization is taken care of in the metric functions.  
    
    //This is a version of the pip_hist_dictionary I determined by eye.
    //I left six alone since it seems to work so well.
    //I just putString values of 100 where I think pips should be and 0 otherwise
 
    

    
    //==========================================================================





    /** Creates a new instance of FastCardID */
    public FastCardID(AEChip chip) {
        super(chip);

        //This initializes the ring_buffers to all zeros.
        //These must start as all zeros for my algorithm to work.
        for (int k = 0 ; k < n; k++) {
            ring_bufferX[k] = 0;
            ring_bufferY[k] = 0;
        }

        //Get the name player ready
        // during tracking
        for (int i = 0; i < 13; i++) {
            try {
                namePlayers[i] = new CardNamePlayer(i);
            } catch (Exception ex) {
                log.warning(ex.toString());
            }
        }

        //open up the message sender

        try {
            msgSender.open();
        } catch (IOException ex) {
            log.warning("couldn't open the UDPMesssgeSender to send messages about card stats: " + ex);
        }

        //Normalize the Pip_Bin_Hist_Dictionary across the rows to sum to 1;
        normalizePipBinHistDictionary();

       



    }

    public void resetFilter() {
        medianPoint.setLocation(chip.getSizeX()/2,chip.getSizeY()/2);
        meanPoint.setLocation(chip.getSizeX()/2,chip.getSizeY()/2);
        stdPoint.setLocation(1,1);
    }

    public Point2D getMedianPoint() {
        return this.medianPoint;
    }

    public Point2D getStdPoint() {
        return this.stdPoint;
    }

    public Point2D getMeanPoint() {
        return this.meanPoint;
    }

    public int getScale_stddev() {
        return this.scale_stddev;
    }

    /**
     * sets the scale of the bounding box relative to stddev
     <p>
     Fires a PropertyChangeEvent "scale_stddev"

     * @see #getDt
     * @param dt delay in us
     */
    public void setScale_stddev(final int scale_stddev) {
        getPrefs().putInt("FastCardID.scale_stddev",scale_stddev);
        getSupport().firePropertyChange("scale_std",this.scale_stddev,scale_stddev);
        this.scale_stddev = scale_stddev;
    }

    public int getAspect_ratio_allowable_error_pts() {
        return this.aspect_ratio_allowable_error_pts;
    }

    public void setAspect_ratio_allowable_error_pts(final int aspect_ratio_allowable_error_pts) {
         getPrefs().putInt("FastCardID.aspect_ratio_allowable_error_pts",aspect_ratio_allowable_error_pts);
        getSupport().firePropertyChange("aspect_ratio_allowable_error_pts",this.aspect_ratio_allowable_error_pts,aspect_ratio_allowable_error_pts);
        this.aspect_ratio_allowable_error_pts = aspect_ratio_allowable_error_pts;
     }

    public void normalizePipBinHistDictionary(){
        //This method is used to make the pip bin hist dictionary normalized in the sense that it sums to one across the rows.

        //int width = pip_bin_hist.length;  //(11)This is the number of pip hist bins
        int width = 11;
        int height = num_cards_considered; //This is the number of cards.

        //Go through row by row to find the sums

        for (int ii = 0; ii < height; ii++){

            //First sum all the elements of the ii row
            double row_sum = 0;
            for (int jj = 0; jj < width; jj++ ){
                row_sum = row_sum + pip_hist_dictionary[ii][jj];
            }

            //Now divide each element in the ii row by the row sum
            for (int jj = 0; jj < width; jj++ ){
                pip_hist_dictionary[ii][jj] = pip_hist_dictionary[ii][jj]/row_sum;
            }

        }


    }

    public double getMaxPipBinHist() {
        double pip_bin_hist_max = 0;
        for (int jj = 0; jj < pip_bin_hist.length; jj++ ){
                 if (pip_bin_hist[jj] > pip_bin_hist_max) {
                     pip_bin_hist_max = pip_bin_hist[jj];
                 }
        }
        return pip_bin_hist_max;
    }

    public void normalizePipBinHist(){
        //This method is used to make the pip bin hist dictionary normalized in the sense that it sums to one across the rows.

        int width = pip_bin_hist.length;  //(11)This is the number of pip hist bins

            //First sum all the elements of the pip_bin_hist
            double row_sum = 0;
            for (int jj = 0; jj < width; jj++ ){
                row_sum = row_sum + pip_bin_hist[jj];
            }

            //Now divide each element in the ii row by the row sum
            for (int jj = 0; jj < width; jj++ ){
                pip_bin_hist[jj] = pip_bin_hist[jj]/row_sum;
            }
    }

    public void euclideanMetric(){
        //Just initilize to 10

        int width = pip_bin_hist.length;  //(11)This is the number of pip hist bins
        int height = num_cards_considered; //This is the number of cards.

        //Normalize the pip bin hist
        normalizePipBinHist();

        double[] euclidean_metric = {10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10};
        //pip_hist_dictionary[ii][jj]        

        //Go through row by row to find euclidean distance
        for (int ii = 0; ii < height; ii++){

            //First sum all the elements of the ii row
            double row_sum = 0;
            for (int jj = 0; jj < width; jj++ ){
                row_sum = row_sum + java.lang.Math.pow((pip_bin_hist[jj] - pip_hist_dictionary[ii][jj]),2);
            }
            //Now take the square root of the sum of the squares
            //Multiply by 1000 for scaling purposes
            euclidean_metric[ii] = java.lang.Math.sqrt(row_sum) * 1000;
        }

        //set cardhist appropriately
        //This is going to require some gymnastics since the CardHistogram class is
        //Implemented using ints and the metric values are doubles
        
        //First find the max value of the euclidean metric and do maxeuclidean - each bin
        double euclidean_max = 0;
        for (int jj = 0; jj < num_cards_considered; jj++ ){
                 if (euclidean_metric[jj] > euclidean_max) {
                     euclidean_max = euclidean_metric[jj];
                 }
        }

        //Now set the cardHist matrix
        cardHist.reset();
        for (int jj = 0; jj < num_cards_considered; jj++ ){
             cardHist.setValue(jj + 1,(int) (euclidean_max - euclidean_metric[jj]) );   //The jj+1 reflects the fact that toby reserves the 0 bin for unknown.  
        }

    }

    public void hellingerMetric(){
        


        int width = pip_bin_hist.length;  //(11)This is the number of pip hist bins
        int height = num_cards_considered; //This is the number of cards.

        //Normalize the pip bin hist
        normalizePipBinHist();

        //Just initilize to 10
        double[] hellinger_metric = {10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10};
        

        //Go through row by row to find hellinger distance
        for (int ii = 0; ii < height; ii++){

            //First sum all the elements of the ii row
            double row_sum = 0;
            for (int jj = 0; jj < width; jj++ ){
                row_sum = row_sum + java.lang.Math.pow((java.lang.Math.sqrt(pip_bin_hist[jj]) - java.lang.Math.sqrt(pip_hist_dictionary[ii][jj])),2);
            }
            //Now take the square root of the sum of the squares
            //Multiply by 1000 for scaling purposes
            hellinger_metric[ii] = java.lang.Math.sqrt(row_sum) * 1000;
        }

        //set cardhist appropriately
        //This is going to require some gymnastics since the CardHistogram class is
        //Implemented using ints and the metric values are doubles

        //First find the max value of the euclidean metric and do maxeuclidean - each bin
        double hellinger_max = 0;
        for (int jj = 0; jj < num_cards_considered; jj++ ){
                 if (hellinger_metric[jj] > hellinger_max) {
                     hellinger_max = hellinger_metric[jj];
                 }
        }

        //Now set the cardHist matrix
        cardHist.reset();
        for (int jj = 0; jj < num_cards_considered; jj++ ){
             cardHist.setValue(jj + 1,(int) (hellinger_max - hellinger_metric[jj]) );   //The jj+1 reflects the fact that toby reserves the 0 bin for unknown.
        }
          
        
    }
    
    


    public int getPip_bin_hist_threshold() {
        return this.pip_bin_hist_threshold;
    }

    /**@param tauUs the time constant of the 1st order lowpass filter on median location */
    public void setPip_bin_hist_threshold(final int pip_bin_hist_threshold) {
        this.pip_bin_hist_threshold = pip_bin_hist_threshold;
        getPrefs().putInt("FastCardID.pip_bin_hist_threshold", pip_bin_hist_threshold);
    }



    public int getRing_buffer_length() {
        return this.ring_buffer_length;
    }

    /**
     * sets the scale of the bounding box relative to stddev
     <p>
     Fires a PropertyChangeEvent "scale_stddev"

     * @see #getDt
     * @param dt delay in us
     */
    public void setRing_buffer_length(final int ring_buffer_length) {

        if (ring_buffer_length < 16) {
            getPrefs().putInt("FastCardID.ring_buffer_length",16);
            getSupport().firePropertyChange("ring_buffer_length",this.ring_buffer_length,16);
            this.ring_buffer_length = 16;
        } else if (ring_buffer_length > 4096) {
            getPrefs().putInt("FastCardID.ring_buffer_length",4096);
            getSupport().firePropertyChange("ring_buffer_length",this.ring_buffer_length,4096);
            this.ring_buffer_length = 4096;
        } else {
            getPrefs().putInt("FastCardID.ring_buffer_length",ring_buffer_length);
            getSupport().firePropertyChange("ring_buffer_length",this.ring_buffer_length,ring_buffer_length);
            this.ring_buffer_length = ring_buffer_length;
        }
    //At this point I think I need to reinitialize the filter

    //This initializes the ring_buffers to all zeros.
    //These must start as all zeros for my algorithm to work.
    for (int k = 0 ; k < n; k++) {
        ring_bufferX[k] = 0;
        ring_bufferY[k] = 0;
    }

    xsum = 0f;
    ysum = 0f;
    xxsum = 0f;
    yysum = 0f;
    xysum = 0f;

    xmean = 0f;
    ymean = 0f;
    xxvar = 0f;
    yyvar = 0f;
    xycovar = 0f;

    rb_index = 0;

    }



    public void initFilter() {
    }


    public EventPacket filterPacket(EventPacket in) {

        checkOutputPacketEventType(in); //This is what actually initiates the out EventPacket of the correct type.
        OutputEventIterator outItr=out.outputIterator();


        
       
        
        


       


            for(Object o:in){
                BasicEvent e=(BasicEvent)o;

                //This is to correctly increment the ring buffer.
                if (rb_index >= ring_buffer_length ){
                    rb_index = 0;
                }

                //System.out.println("=============================================");
                //System.out.println("x=" + e.x + " y=" + e.y);



                //Now calculate the mean information


                xsum = xsum + e.x - ring_bufferX[rb_index];
                ysum = ysum + e.y - ring_bufferY[rb_index];

                //System.out.println("x sum=" + xsum + " y sum=" + ysum + " rb index = " + rb_index);

                xmean = xsum/ring_buffer_length;
                ymean = ysum/ring_buffer_length;


                //System.out.println("x mean=" + xmean + " y mean=" + ymean);

                //Now calculate the variance information
                xxsum = xxsum + e.x*e.x - ring_bufferX[rb_index]*ring_bufferX[rb_index];
                yysum = yysum + e.y*e.y - ring_bufferY[rb_index]*ring_bufferY[rb_index];
                xysum = xysum + e.x*e.y - ring_bufferX[rb_index]*ring_bufferY[rb_index];

                //System.out.println("xx sum=" + xxsum + " yy sum=" + yysum + " xysum" + xysum);

                xxvar = (xxsum - ((xsum*xsum)/ring_buffer_length))/(ring_buffer_length-1);
                yyvar = (yysum - ((ysum*ysum)/ring_buffer_length))/(ring_buffer_length-1);
                xycovar = (xysum - ((xsum*ysum)/ring_buffer_length))/(ring_buffer_length);

                //System.out.println("xxvar=" + xxvar + " yyvar=" + yyvar + " xycovar=" + xycovar);

                //Now calculate the eigenvalues directly

                double a = 1;
                double b = -1 * (xxvar + yyvar);
                double c = xxvar * yyvar - xycovar * xycovar;

                double eig1presort = (-1 * b + java.lang.Math.sqrt(b*b - 4*a*c))/(2 * a);
                double eig2presort = (-1 * b - java.lang.Math.sqrt(b*b - 4*a*c))/(2 * a);

                //use the larger eigenvalue for stddev1 and the smaller eigenvalue for stddev2
                double eig1, eig2;
                if (eig1presort < eig2presort) {
                    eig1 = eig2presort;
                    eig2 = eig1presort;
                } else {
                    eig1 = eig1presort;
                    eig2 = eig2presort;
                }

                double stddev1 = java.lang.Math.sqrt(eig1);
                double stddev2 = java.lang.Math.sqrt(eig2);

                //System.out.println("Eig1=" + eig1 + " Eig2=" + eig2);

                //now calculate the eigenvectors

                double eigvec1x = eig1 - yyvar;
                double eigvec2x = eig2 - yyvar;

                double eigvec1y = xycovar;
                double eigvec2y = xycovar;

                //Now normalize the eignvectors

               double eig1norm = java.lang.Math.sqrt(eigvec1x*eigvec1x + eigvec1y*eigvec1y);
               double eig2norm = java.lang.Math.sqrt(eigvec2x*eigvec2x + eigvec2y*eigvec2y);

               eigvec1x = eigvec1x/eig1norm;
               eigvec1y = eigvec1y/eig1norm;

               eigvec2x = eigvec2x/eig2norm;
               eigvec2y = eigvec2y/eig2norm;


                //Set the points for drawing (I am not sure if this should be outside or inside the for loop)
                meanPoint.setLocation(xmean,ymean);

                eigvec1Point.setLocation(xmean + eigvec1x * stddev1, ymean + eigvec1y * stddev1);
                eigvec2Point.setLocation(xmean + eigvec2x * stddev2, ymean + eigvec2y * stddev2);      //The length of this vector is scaled by the eigenvalues.

                /*
                //This stuff really slowed everything down, but it seems to work fine without it.
                scale_stddev = getScale_stddev();
                setScale_stddev(scale_stddev);
                 */

                square1Point.setLocation(xmean + scale_stddev * stddev_inc *(     (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                square2Point.setLocation(xmean + scale_stddev * stddev_inc *(-1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                square3Point.setLocation(xmean + scale_stddev * stddev_inc *(-1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));
                square4Point.setLocation(xmean + scale_stddev * stddev_inc *(     (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //eventPoint.setLocation(e.x,e.y);        //Just a point to show where the latest event occurs


                stddev1Point.setLocation(10, 10 + stddev1);
                stddev2Point.setLocation(20, 10 + stddev2);


                /*
                //These are points representing the pip_hist bins
                //middle vertical bars
                pipbiny1tlPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) + (biny1 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) + (biny1 * eigvec2y * stddev2)));
                pipbiny1blPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) + (biny1 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) + (biny1 * eigvec2y * stddev2)));

                pipbiny1trPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) - (biny1 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) - (biny1 * eigvec2y * stddev2)));
                pipbiny1brPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) - (biny1 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) - (biny1 * eigvec2y * stddev2)));

                //left vertical bars
                pipbiny2tlPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) + (biny2 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) + (biny2 * eigvec2y * stddev2)));
                pipbiny2blPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) + (biny2 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) + (biny2 * eigvec2y * stddev2)));

                pipbiny3tlPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) + (biny3 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) + (biny3 * eigvec2y * stddev2)));
                pipbiny3blPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) + (biny3 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) + (biny3 * eigvec2y * stddev2)));

                //Right vertical bars
                pipbiny2trPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) - (biny2 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) - (biny2 * eigvec2y * stddev2)));
                pipbiny2brPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) - (biny2 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) - (biny2 * eigvec2y * stddev2)));

                pipbiny3trPoint.setLocation(xmean + scale_stddev * stddev_inc *(      (eigvec1x * stddev1) - (biny3 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(      (eigvec1y * stddev1) - (biny3 * eigvec2y * stddev2)));
                pipbiny3brPoint.setLocation(xmean + scale_stddev * stddev_inc *( -1 * (eigvec1x * stddev1) - (biny3 * eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *( -1 * (eigvec1y * stddev1) - (biny3 * eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx4trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx4 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx4 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx4tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx4 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx4 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx4brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx4 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx4 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx4blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx4 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx4 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx3trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx3 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx3 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx3tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx3 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx3 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx3brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx3 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx3 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx3blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx3 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx3 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx2trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx2 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx2 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx2tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx2 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx2 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx2brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx2 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx2 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx2blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx2 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx2 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx1trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx1tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx1brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx1 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx1 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx1blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx1 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx1 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx5trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx5 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx5 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx5tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx5 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx5 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx5brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx5 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx5 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx5blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx5 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx5 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                 //Top Horizontal bar
                pipbinx6trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx6 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx6 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx6tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx6 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx6 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx6brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx6 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx6 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx6blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx6 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx6 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Top Horizontal bar
                pipbinx7trPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx7 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx7 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx7tlPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx7 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx7 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));

                //Bottom Horizontal bar
                pipbinx7brPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx7 * -1 * (eigvec1x * stddev1) - (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx7 * -1 * (eigvec1y * stddev1) - (eigvec2y * stddev2)));
                pipbinx7blPoint.setLocation(xmean + scale_stddev * stddev_inc * (binx7 * -1 * (eigvec1x * stddev1) + (eigvec2x * stddev2)), ymean + scale_stddev * stddev_inc *(binx7 * -1 * (eigvec1y * stddev1) + (eigvec2y * stddev2)));
                */

                //Put the event data in the ring buffer
                if (rb_index < ring_buffer_length ) {
                ring_bufferX[rb_index] = e.x;
                ring_bufferY[rb_index] = e.y;

                } else {
                    rb_index = 0;
                    ring_bufferX[rb_index] = e.x;
                    ring_bufferY[rb_index] = e.y;
                }

                //Now begin checking whether or not a card is present
                //First check the aspect ratio;

                aspect_ratio  = stddev1/stddev2;

                aspect_ratio_error = java.lang.Math.abs(aspect_ratio -aspect_ratio_card)/aspect_ratio_card;

                //Aspect ratio may not be a good way to identify whether or not a card is there.  

               
                if (aspect_ratio_error < (aspect_ratio_allowable_error_inc * aspect_ratio_allowable_error_pts)) {  
                    //check for a change in the flag to reset the histogram buffers
                    //System.out.println("Card Present");
                    if (card_present_flag == false ) {
                        //Indicate card has entered the screen
                        //System.out.println("Card Present");
                        //Here reinitialize the card value matrix to 0s

                        cardHist.reset();
                        card_event_index = 0;       //Resent the number of events for this instance of the card

                        //Reset the active pip bins and the pip bin hist
                        Arrays.fill(pip_bin_active, 0);
                        Arrays.fill(pip_bin_hist, 0);
                        /*
                        for (int ii = 0; ii < card_value_hist.length; ii++){
                            card_value_hist[ii] = 0;            
                        }
                        */
                        /*
                        for (int ii = 0; ii < pip_bin_hist.length; ii++){
                            pip_bin_hist[ii] = 0;
                        }
                        */

                    }
                    card_present_flag = true;
                } else {
                    //System.out.println("Card Not Present");
                    if (card_present_flag == true ) {
                        //Output the card_value_hist
                        //Indicate card is gone
                        //System.out.println("Card Not Present");

                        if (getMin_number_events() < card_event_index) {
                            //Now send out the data over UDP
                            try {
                                //Put metric check here
                                euclideanMetric();
                                //hellingerMetric();
                                msgSender.sendMessage(cardHist.toString());
                            } catch (IOException ex) {
                                log.warning("couldn't send CardHistogram: " + ex);
                            }

                            if (cardHist.getMaxValueBin() != 0 && System.currentTimeMillis() - lastTimeSaidCar > minSayCardIntervalMs) {
                                int val = cardHist.getMaxValueBin();
                                    if (val > 0 && val <= 13 && namePlayers[val-1] != null) {
                                        lastTimeSaidCar = System.currentTimeMillis();
                                        //lastCardValue=val;
                                        namePlayers[val - 1].play(); // 0=ace, 12=king
                                        }
                            }


                        //Send the max card out on the console
                        System.out.println("The MLE of the card is: " + cardHist.getMaxValueBin());
                        System.out.println(cardHist.toString());
                        
                        //Print the pip bin hist to file
  
                        }

                    }
                   card_present_flag = false;
                }

                if (card_present_flag == true ) {
                    
                    //If it has been determined that a card is present in the view of the camera
                    //Figure out if the event falls in a pip bin.  

                    //First transform the event to the scaled card coordinate frame.
                    //First subtract out the mean
                    relx = e.x - xmean;
                    rely = e.y - ymean;

                    //Now project this relative vector onto the card coordinate frame
                    //Then scale by the std dev in the two directions.  

                    cardx = (eigvec1x * relx + eigvec1y * rely)/(stddev1 * scale_stddev * stddev_inc);
                    cardy = (eigvec2x * relx + eigvec2y * rely)/(stddev2 * scale_stddev * stddev_inc);

                    //Now determine whether the event falls into one of the pip bins
                    //This is kind of the heart of the card ID
                    //Only pass forward events falling in a pip bin

                    if ((cardy >= -1 * biny3) && (cardy <= -1 * biny2)) {

                        if ((cardx <= binx4) && (cardx >= binx3)){
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[0]++;
                        } else if ((cardx <= binx2) && (cardx >= binx1 )) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[1]++;
                        } else if ((cardx <= -1*binx1) && (cardx >= -1*binx2)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[2]++;
                        } else if ((cardx <= -1 * binx3 ) && (cardx >= -1 * binx4)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[3]++;
                        }

                    } else if ( (cardy >= -1 * biny1 ) && (cardy <= biny1 )  ) {

                        if ((cardx <= binx7) && ( cardx >= binx6)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[4]++;
                        } else if ((cardx <= binx5) && (cardx >= -1 * binx5)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[5]++;
                        } else if ((cardx <= -1 * binx6) && ( cardx >= -1 * binx7)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[6]++;
                        }

                    } else if ((cardy <= biny3 ) && (cardy >= biny2)) {

                        if ((cardx <= binx4) && (cardx >= binx3)){
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[7]++;
                        } else if ((cardx <= binx2) && (cardx >= binx1 )) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[8]++;
                        } else if ((cardx <= -1*binx1) && (cardx >= -1*binx2)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[9]++;
                        } else if ((cardx <= -1 * binx3 ) && (cardx >= -1 * binx4)) {
                            BasicEvent i=(BasicEvent)outItr.nextOutput();
                            i.copyFrom(e);
                            pip_bin_hist[10]++;
                        }
                    }

                    //Now run thru the pip_bin hist to check if the bins have
                    //passed the threshold for recognizing a pip.
                    // keep a count of the number of recognizing bins
                    //One oddity of how I do this, is that there is the possibilty of
                    //counting 11 pips when at most there can only be 10
                    //This case should probably be dealt with.
                    
                    if (card_present_flag == true ) {

                        //pip_count = 0;
                        //This for statement can be removed it is not used anymore

                        /*
                        for (int ii = 0; ii<pip_bin_hist.length; ii++) {

                            if (pip_bin_hist[ii] >= pip_bin_hist_threshold) {
                                pip_bin_active[ii] = 1;         //The idea here is if the pip bin ever goes above threshold it is considered active.  
                                //pip_count++;
                            }
                        }
                        */
                        
                    }

                    //At this point we have card recognition.
                    //Histogram the card value the system thinks it sees in
                    //card_value_hist
                    //For now assume the pip count equals the card value.
                    //Deal with the odd case of counting a value of 11 later.  

                    //Remove this line and replace it with Tobi's Card Hist method
                    //card_value_hist[pip_count - 1]++;

                    //determine the number of the card by summing the number of active pip bins

                    //ignore
                    /*
                    pip_count = 0;
                    for (int ii = 0; ii<pip_bin_active.length; ii++) {
                        pip_count =  pip_count + pip_bin_active[ii];
                    }
                    */
                    //cardHist.incValue(pip_count);

                    /*
                    //Now send out the data over UDP
                    try {
                           msgSender.sendMessage(cardHist.toString());
                    } catch (IOException ex) {
                            log.warning("couldn't send CardHistogram: " + ex);
                    }
                    */
                }
                //max_bin_mle = cardHist.getMaxValueBin();

                //Here putString code to display the pip_hist
                double max_pip_bin_hist = getMaxPipBinHist();
                
                
                pipbinPoint0.setLocation( pipdisplayscale * 3,(pipdisplayscale + 1)*4 + pipdisplayscale*pip_bin_hist[0]/max_pip_bin_hist );
                pipbinPoint1.setLocation( pipdisplayscale * 3,(pipdisplayscale + 1)*3 + pipdisplayscale*pip_bin_hist[1]/max_pip_bin_hist );
                pipbinPoint2.setLocation( pipdisplayscale * 3,(pipdisplayscale + 1)*2 + pipdisplayscale*pip_bin_hist[2]/max_pip_bin_hist );
                pipbinPoint3.setLocation( pipdisplayscale * 3,(pipdisplayscale + 1)*1 + pipdisplayscale*pip_bin_hist[3]/max_pip_bin_hist );

                pipbinPoint4.setLocation( pipdisplayscale * 2,(pipdisplayscale + 2)*3 + pipdisplayscale*pip_bin_hist[4]/max_pip_bin_hist );
                pipbinPoint5.setLocation( pipdisplayscale * 2,(pipdisplayscale + 2)*2 + pipdisplayscale*pip_bin_hist[5]/max_pip_bin_hist );
                pipbinPoint6.setLocation( pipdisplayscale * 2,(pipdisplayscale + 2)*1 + pipdisplayscale*pip_bin_hist[6]/max_pip_bin_hist );

                pipbinPoint7.setLocation( pipdisplayscale * 1,(pipdisplayscale + 1)*4 + pipdisplayscale*pip_bin_hist[7]/max_pip_bin_hist );
                pipbinPoint8.setLocation( pipdisplayscale * 1,(pipdisplayscale + 1)*3 + pipdisplayscale*pip_bin_hist[8]/max_pip_bin_hist );
                pipbinPoint9.setLocation( pipdisplayscale * 1,(pipdisplayscale + 1)*2 + pipdisplayscale*pip_bin_hist[9]/max_pip_bin_hist );
                pipbinPoint10.setLocation( pipdisplayscale * 1,(pipdisplayscale + 1)*1 + pipdisplayscale*pip_bin_hist[10]/max_pip_bin_hist );



                rb_index++;
                card_event_index++;
            }


            

        return in; //I just putString this there since it seems necessary and Tobi said to do it.
    }


    //This is code to allow a multiline annotate
    /*
    @Override
    public void annotate(GLAutoDrawable drawable) {
        MultilineAnnotationTextRenderer.resetToYPositionPixels(chip.getSizeY() - 2);
        String s="ClusterBasedPipCounter\n" + cardHist.toString().substring(0, 50);
        if(lastCardValue>1 && lastCardValue<14) s+="\nCard value: "+cardNameFromValue(lastCardValue);
        MultilineAnnotationTextRenderer.renderMultilineString(s);
    }
    */




    /** JOGL annotation */
    public void annotate(GLAutoDrawable drawable) {
        if(!isFilterEnabled()) return;

        
        MultilineAnnotationTextRenderer.resetToYPositionPixels(chip.getSizeY() - 2);
        String ss="FastCardID, David Mascarenas and Tobi Delbruck, Telluride, CO, July,2010 \n";// + cardHist.toString().substring(0, 50);
        ss += "\nPip bin histogram\n";
        if (card_present_flag == true) {
            ss += "Card Present\n";
        } else {
            ss += "Card Not Present\n";
        }
        ss += "pip_count = " + pip_count + "\n";
        ss += "card_event_index = " + card_event_index +"\n";
        //ss += "MLE count = " + max_bin_mle + "\n";
        ss += "pip bin  0 =" + pip_bin_hist[0] + "\n";
        ss += "pip bin  1 =" + pip_bin_hist[1] + "\n";
        ss += "pip bin  2 =" + pip_bin_hist[2] + "\n";
        ss += "pip bin  3 =" + pip_bin_hist[3] + "\n";
        ss += "pip bin  4 =" + pip_bin_hist[4] + "\n";
        ss += "pip bin  5 =" + pip_bin_hist[5] + "\n";
        ss += "pip bin  6 =" + pip_bin_hist[6] + "\n";
        ss += "pip bin  7 =" + pip_bin_hist[7] + "\n";
        ss += "pip bin  8 =" + pip_bin_hist[8] + "\n";
        ss += "pip bin  9 =" + pip_bin_hist[9] + "\n";
        ss += "pip bin 10 =" + pip_bin_hist[10] + "\n";
        

        //ss += "card x = " + cardx + " cardy = " + cardy + "\n";
        MultilineAnnotationTextRenderer.renderMultilineString(ss);
        
        
        Point2D p=meanPoint;
        Point2D s=eventPoint;
        //Point2D o=orthoPoint;
        Point2D q=eigvec1Point;
        Point2D r=eigvec2Point;

        Point2D t = square1Point;
        Point2D u = square2Point;
        Point2D v = square3Point;
        Point2D w = square4Point;

        Point2D sxx = stddev1Point;
        Point2D syy = stddev2Point;

        //These are points to make the pip_hist_bins

        GL gl=drawable.getGL();
        // already in chip pixel context with LL corner =0,0
        gl.glPushMatrix();

        gl.glColor3f(0,1,0);
        gl.glLineWidth(4);
        gl.glBegin(GL.GL_LINES);

        //Draw the eigenvectors
        gl.glVertex2d(p.getX(), p.getY());      //Origen
        gl.glVertex2d(q.getX(), q.getY());      //End point

        gl.glVertex2d(p.getX(), p.getY());      //Origen
        gl.glVertex2d(r.getX(), r.getY());      //End point

        //Draw the current point
        //gl.glVertex2d(p.getX(), p.getY());      //Origen
        //gl.glVertex2d(s.getX(), s.getY());     //Origen

        gl.glEnd();

//==============================================================================
        // Draw the lines corresponding to the std deviation
        /*
        gl.glColor3f(0,1,1);
        gl.glLineWidth(2);
        gl.glBegin(GL.GL_LINES);
        //Draw the current point
        gl.glVertex2d(10, 10);      //Origen
        gl.glVertex2d(sxx.getX(), sxx.getY());      //Origen

        gl.glVertex2d(20, 10);      //Origen
        gl.glVertex2d(syy.getX(), syy.getY());      //Origen

        gl.glEnd();
        */

        gl.glColor3f(1,0,0);
        gl.glLineWidth(4);
        gl.glBegin(GL.GL_LINES);

        //Draw the bounding square
        gl.glVertex2d(t.getX(), t.getY());      //Origen
        gl.glVertex2d(u.getX(), u.getY());      //End point

        gl.glVertex2d(u.getX(), u.getY());      //Origen
        gl.glVertex2d(v.getX(), v.getY());      //End point

        gl.glVertex2d(v.getX(), v.getY());      //Origen
        gl.glVertex2d(w.getX(), w.getY());      //End point

        gl.glVertex2d(w.getX(), w.getY());      //Origen
        gl.glVertex2d(t.getX(), t.getY());      //return to beginning

        gl.glEnd();

        //======================================================================

        //Draw the pip_bin_hist display

        gl.glColor3f(1,0,0);
        gl.glLineWidth(4);
        gl.glBegin(GL.GL_LINES);

        //bin0
        gl.glVertex2d(pipdisplayscale * 3,(pipdisplayscale + 1)*4);
        gl.glVertex2d(pipbinPoint0.getX(),pipbinPoint0.getY());

        //bin1
        gl.glVertex2d(pipdisplayscale * 3,(pipdisplayscale + 1)*3);
        gl.glVertex2d(pipbinPoint1.getX(),pipbinPoint1.getY());

        //bin2
        gl.glVertex2d( pipdisplayscale * 3,(pipdisplayscale + 1)*2);
        gl.glVertex2d(pipbinPoint2.getX(),pipbinPoint2.getY());

        //bin3
        gl.glVertex2d(pipdisplayscale * 3,(pipdisplayscale + 1)*1);
        gl.glVertex2d(pipbinPoint3.getX(),pipbinPoint3.getY());


        //bin4
        gl.glVertex2d(pipdisplayscale * 2,(pipdisplayscale + 2)*3);
        gl.glVertex2d(pipbinPoint4.getX(),pipbinPoint4.getY());

        //bin5
        gl.glVertex2d(pipdisplayscale * 2,(pipdisplayscale + 2)*2);
        gl.glVertex2d(pipbinPoint5.getX(),pipbinPoint5.getY());

        //bin6
        gl.glVertex2d(pipdisplayscale * 2,(pipdisplayscale + 2)*1);
        gl.glVertex2d(pipbinPoint6.getX(),pipbinPoint6.getY());

        //bin7
        gl.glVertex2d(pipdisplayscale * 1,(pipdisplayscale + 1)*4);
        gl.glVertex2d(pipbinPoint7.getX(),pipbinPoint7.getY());

        //bin8
        gl.glVertex2d( pipdisplayscale * 1,(pipdisplayscale + 1)*3);
        gl.glVertex2d(pipbinPoint8.getX(),pipbinPoint8.getY());

        //bin9
        gl.glVertex2d(pipdisplayscale * 1,(pipdisplayscale + 1)*2);
        gl.glVertex2d(pipbinPoint9.getX(),pipbinPoint9.getY());

        //bin
        gl.glVertex2d(pipdisplayscale * 1,(pipdisplayscale + 1)*1);
        gl.glVertex2d(pipbinPoint10.getX(),pipbinPoint10.getY());

        gl.glEnd();
                 


        /*
        gl.glColor3f(1,0,0);
        gl.glLineWidth(1);
        gl.glBegin(GL.GL_LINES);

        //Draw the pip bin hist
        
        //Middle verticle bars
        gl.glVertex2d(pipbiny1tlPoint.getX(), pipbiny1tlPoint.getY());
        gl.glVertex2d(pipbiny1blPoint.getX(), pipbiny1blPoint.getY());

        gl.glVertex2d(pipbiny1trPoint.getX(), pipbiny1trPoint.getY());
        gl.glVertex2d(pipbiny1brPoint.getX(), pipbiny1brPoint.getY());

        //Left Vertical Bars
        gl.glVertex2d(pipbiny2blPoint.getX(), pipbiny2blPoint.getY());
        gl.glVertex2d(pipbiny2tlPoint.getX(), pipbiny2tlPoint.getY());

        gl.glVertex2d(pipbiny3blPoint.getX(), pipbiny3blPoint.getY());
        gl.glVertex2d(pipbiny3tlPoint.getX(), pipbiny3tlPoint.getY());

        //right vertical bars
        gl.glVertex2d(pipbiny2brPoint.getX(), pipbiny2brPoint.getY());
        gl.glVertex2d(pipbiny2trPoint.getX(), pipbiny2trPoint.getY());

        gl.glVertex2d(pipbiny3brPoint.getX(), pipbiny3brPoint.getY());
        gl.glVertex2d(pipbiny3trPoint.getX(), pipbiny3trPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx4tlPoint.getX(), pipbinx4tlPoint.getY());
        gl.glVertex2d(pipbinx4trPoint.getX(), pipbinx4trPoint.getY());
        
        gl.glVertex2d(pipbinx4brPoint.getX(), pipbinx4brPoint.getY());
        gl.glVertex2d(pipbinx4blPoint.getX(), pipbinx4blPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx3tlPoint.getX(), pipbinx3tlPoint.getY());
        gl.glVertex2d(pipbinx3trPoint.getX(), pipbinx3trPoint.getY());

        gl.glVertex2d(pipbinx3brPoint.getX(), pipbinx3brPoint.getY());
        gl.glVertex2d(pipbinx3blPoint.getX(), pipbinx3blPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx2tlPoint.getX(), pipbinx2tlPoint.getY());
        gl.glVertex2d(pipbinx2trPoint.getX(), pipbinx2trPoint.getY());

        gl.glVertex2d(pipbinx2brPoint.getX(), pipbinx2brPoint.getY());
        gl.glVertex2d(pipbinx2blPoint.getX(), pipbinx2blPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx1tlPoint.getX(), pipbinx1tlPoint.getY());
        gl.glVertex2d(pipbinx1trPoint.getX(), pipbinx1trPoint.getY());

        gl.glVertex2d(pipbinx1brPoint.getX(), pipbinx1brPoint.getY());
        gl.glVertex2d(pipbinx1blPoint.getX(), pipbinx1blPoint.getY());


        gl.glEnd();


        gl.glColor3f(0,0,1);
        gl.glLineWidth(2);
        gl.glBegin(GL.GL_LINES);

        //Top horizontal bar
        gl.glVertex2d(pipbinx5tlPoint.getX(), pipbinx5tlPoint.getY());
        gl.glVertex2d(pipbinx5trPoint.getX(), pipbinx5trPoint.getY());

        gl.glVertex2d(pipbinx5brPoint.getX(), pipbinx5brPoint.getY());
        gl.glVertex2d(pipbinx5blPoint.getX(), pipbinx5blPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx6tlPoint.getX(), pipbinx6tlPoint.getY());
        gl.glVertex2d(pipbinx6trPoint.getX(), pipbinx6trPoint.getY());

        gl.glVertex2d(pipbinx6brPoint.getX(), pipbinx6brPoint.getY());
        gl.glVertex2d(pipbinx6blPoint.getX(), pipbinx6blPoint.getY());

        //Top horizontal bar
        gl.glVertex2d(pipbinx7tlPoint.getX(), pipbinx7tlPoint.getY());
        gl.glVertex2d(pipbinx7trPoint.getX(), pipbinx7trPoint.getY());

        gl.glVertex2d(pipbinx7brPoint.getX(), pipbinx7brPoint.getY());
        gl.glVertex2d(pipbinx7blPoint.getX(), pipbinx7blPoint.getY());


        gl.glEnd();
        */
        //======================================================================


        /*
        gl.glColor3f(1,1,0);
        gl.glLineWidth(4);
        gl.glBegin(GL.GL_POINTS);
        gl.glVertex2d(s.getX(), s.getY());
        gl.glEnd( );
         *
         */


        gl.glPopMatrix();
    }

    /**
     * @return the min_number_events
     */
    public int getMin_number_events() {
        return min_number_events;
    }

    /**
     * @param min_number_events the min_number_events to set
     */
    public void setMin_number_events(int min_number_events) {
        this.min_number_events = min_number_events;
    }

}

