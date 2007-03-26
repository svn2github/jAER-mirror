/*
 * Histogram3dDisplayMethod.java
 *
 * Created on May 5, 2006, 8:53 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright May 5, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */

package ch.unizh.ini.caviar.graphics;

import com.sun.opengl.util.GLUT;
import javax.media.opengl.GL;
import javax.media.opengl.GLAutoDrawable;

/**
 * Displays histogrammed AEs from ChipRenderer as 3-d histogram that can be rotated and moved about.
 *
 * @author tobi
 */
public class Histogram3dDisplayMethod extends DisplayMethod implements DisplayMethod3D {
    
    /** Creates a new instance of Histogram3dDisplayMethod */
    public Histogram3dDisplayMethod(ChipCanvas c) {
        super(c);
    }
    
    
    /** the 3-d histogram display.
     *Draws a 3-d histogram, where each bin corresponds to one element of collected rendered frame data from ChipRenderer.
     *This data is float[][][] array. First dimension is y, 2nd is x, 3rd is RGB 3 vector.
     *Each element is rendered as a box of height corresponding to element value.
     *
     */
    public void display(GLAutoDrawable drawable){
        GL gl=setupGL(drawable);
        float[][][] fr = renderer.getFr();
        if (fr == null){
            return;
        }
        float gray = renderer.getGrayValue();
        
        gl.glClearColor(gray,gray,gray,0f);
        gl.glClear(GL.GL_COLOR_BUFFER_BIT);
//        gl.glClear(GL.GL_COLOR_BUFFER_BIT);
//        gl.glEnable(GL.GL_DEPTH_TEST);
        gl.glDisable(GL.GL_DEPTH_TEST);
        
        gl.glPushMatrix();
        {
            
            // rotate viewpoint
            
            gl.glRotatef(chipCanvas.getAngley(),0,1,0); // rotate viewpoint by angle deg around the upvector
            gl.glRotatef(chipCanvas.getAnglex(),1,0,0); // rotate viewpoint by angle deg around the upvector
            
            gl.glTranslatef(chipCanvas.getOrigin3dx(), chipCanvas.getOrigin3dy(), 0);
            
            // draw 3d axes
            gl.glColor3f(0,0,1);
            gl.glLineWidth(1f);
            
            gl.glBegin(GL.GL_LINES);
            {
                gl.glVertex3f(0,0,0);
                gl.glVertex3f(chip.getSizeX(),0,0);
                gl.glVertex3f(0,0,0);
                gl.glVertex3f(0,chip.getSizeY(),0);
                gl.glVertex3f(0,0,0);
                gl.glVertex3f(0,0,chip.getMaxSize());
            }
            gl.glEnd();
            
            // draw axes labels x,y,#. See tutorial at http://jerome.jouvie.free.fr/OpenGl/Tutorials/Tutorial18.php
            int font = GLUT.BITMAP_HELVETICA_18;
            gl.glPushMatrix();
            final int FS = 1; // distance in pixels of text from endZoom of axis
            gl.glRasterPos3f(chip.getSizeX() + FS, 0 , 0);
            glut.glutBitmapCharacter(font, 'X');
            gl.glRasterPos3f(0, chip.getSizeY() + FS , 0);
            glut.glutBitmapCharacter(font, 'Y');
            gl.glRasterPos3f(0, 0 , chip.getMaxSize() + FS);
            glut.glutBitmapCharacter(font, '#');
            gl.glPopMatrix();
            
            try{
                //        for(int i=0;i<fr.length;i++){
                //            for(int j=0;j<fr[i].length;j++){
                
                // now iterate over the frame (fr)
                for (int x = zoom.getStartPoint().x; x < zoom.getEndPoint().x; x++){
                    for (int y = zoom.getStartPoint().y; y < zoom.getEndPoint().y; y++){
                        float[] f = fr[y][x];
                        if(f[0]==gray && f[1]==gray && f[2]==gray) continue;
//                    int x = i,  y = j; // dont flip y direction because retina coordinates are from botton to top (in user space, after lens) are the same as default OpenGL coordinates
                        drawHistogramBoxes(gl,x,y,f);
                    }
                }
            }catch(ArrayIndexOutOfBoundsException e){
                log.warning("while drawing frame buffer");
                e.printStackTrace();
                chipCanvas.unzoom(); // in case it was some other chip had set the zoom
                gl.glPopMatrix();
            }
        }
        gl.glPopMatrix();
        
    }
    
    void drawHistogramBoxes(GL gl, int x, int y, float[] rgbValues){
        float[] rgb=new float[3];
        int histScale=chip.getMaxSize();
        float g=renderer.getGrayValue();
        gl.glPushMatrix();
        {
            gl.glTranslatef(x,y,0f); // centered on pixel
            AEChipRenderer.ColorMode colorMode=((AEChipRenderer)renderer).getColorMode();
            if(colorMode==AEChipRenderer.ColorMode.RedGreen){
                for(int i=0;i<3;i++){ // rgb components of hist
                    float c=rgbValues[i];
                    if(c==g) continue;
                    c*=histScale;
                    for(int j=0;j<3;j++){ rgb[j]=0;}
                    rgb[i]=1;
                    gl.glBegin(GL.GL_QUADS);
                    gl.glColor3fv(rgb,0);
                    // draw squares for each RGB component offset in y direction
                    float y0=i/3f, y1=y0+0.3333f;
                    //top
                    gl.glVertex3f(0,y0,c);
                    gl.glVertex3f(1,y0,c);
                    gl.glVertex3f(1,y1,c);
                    gl.glVertex3f(0,y1,c);
                    
                    gl.glEnd();
                }
            }else{
                float h=rgbValues[0]*histScale;
                for(int j=0;j<3;j++){ rgb[j]=1;}
                gl.glBegin(GL.GL_QUADS);
                // draw squares for each RGB component offset in y direction
                
                //CCW winding for all faces
                //top
                gl.glColor3fv(rgb,0);
                gl.glVertex3f(0,0,h);
                gl.glVertex3f(1,0,h);
                gl.glVertex3f(1,1,h);
                gl.glVertex3f(0,1,h);
                
//                for(int j=0;j<3;j++){ rgb[j]=.5f;}
//                gl.glColor3fv(rgb,0);
//
//                //front
//                gl.glVertex3f(0,0,0);
//                gl.glVertex3f(1,0,0);
//                gl.glVertex3f(1,0,h);
//                gl.glVertex3f(0,0,h);
//
//                //right
//                gl.glVertex3f(1,0,0);
//                gl.glVertex3f(1,1,0);
//                gl.glVertex3f(1,1,h);
//                gl.glVertex3f(1,0,h);
//
//                //left
//                gl.glVertex3f(0,0,0);
//                gl.glVertex3f(0,0,h);
//                gl.glVertex3f(0,1,h);
//                gl.glVertex3f(0,1,0);
//
//                //back
//                gl.glVertex3f(0,1,0);
//                gl.glVertex3f(0,1,h);
//                gl.glVertex3f(1,1,h);
//                gl.glVertex3f(1,1,0);
//
                
                gl.glEnd();
            }
        }
        gl.glPopMatrix();
    }
    
}
