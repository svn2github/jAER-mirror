/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package net.sf.jaer.util;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;

/**
 *
 * @author Bjoern
 */
public final class DrawGL {
    
    /**
     * Don't let anyone instantiate this class.
     */
    private DrawGL() {}
    
    public static void drawVector(GL2 gl, float headX, float headY) { drawVector(gl,0,0,headX,headY,1,1); }
    public static void drawVector(GL2 gl, float origX, float origY, float headX, float headY) { drawVector(gl,origX,origY,headX,headY,1,1); }
    public static void drawVector(GL2 gl, float origX, float origY, float headX, float headY, float headlength, float Scale) {
        float endx = headX*Scale, endy = headY*Scale;
        float arx  = -endx+endy,  ary  = -endx-endy;   // halfway between pointing back to origin
        float l = (float)Math.sqrt((arx*arx)+(ary*ary)); // length
        arx = (arx/l)*headlength;   ary  = (ary/l)*headlength; // normalize to headlength
        
        gl.glTranslatef(origX, origY, 0);
        
        gl.glBegin(GL2.GL_LINES);
        {
            gl.glVertex2f(0,0);
            gl.glVertex2f(endx,endy);
            // draw arrow (half)
            gl.glVertex2f(endx,endy);
            gl.glVertex2f(endx+arx, endy+ary);
            // other half, 90 degrees
            gl.glVertex2f(endx,endy);
            gl.glVertex2f(endx+ary, endy-arx);
        }
        gl.glEnd();
    }
    
    public static void drawBox(GL2 gl, float centerX, float centerY, float width, float height, float angle) {
        final float r2d = (float) (180 / Math.PI);
        final float w = width/2, h = height/2;
        
        gl.glTranslatef(centerX, centerY, 0);
        if(angle!=0) gl.glRotatef(angle * r2d, 0, 0, 1);

        gl.glBegin(GL.GL_LINE_LOOP);
        {
            gl.glVertex2f(-w, -h);
            gl.glVertex2f(+w, -h);
            gl.glVertex2f(+w, +h);
            gl.glVertex2f(-w, +h);
        }
        gl.glEnd();
    }
    
    public static void drawEllipse(GL2 gl, float centerX, float centerY, float radiusX, float radiusY, float angle, int N) {
        final float r2d = (float) (180 / Math.PI);
        
        gl.glTranslatef(centerX, centerY, 0);
        if(angle!=0) gl.glRotatef(angle * r2d, 0, 0, 1);
        
        gl.glBegin(GL.GL_LINE_LOOP);
        {
            for (int i = 0; i < N; i++) {
                double a = ((float) i / N) * 2 * Math.PI;
                double cosA = Math.cos(a);
                double sinA = Math.sin(a);

                gl.glVertex2d(radiusX * cosA, radiusY * sinA);
            }
        }
        gl.glEnd();
    }
    
    public static void drawCircle(GL2 gl, float centerX, float centerY, float radius, int N) {
        drawEllipse(gl,centerX,centerY,radius,radius,0,N);
    }
    
    public static void drawLine(GL2 gl, float centerX, float centerY, float x, float y, float scale) {
        gl.glTranslatef(centerX, centerY, 0);
        
        gl.glBegin(GL.GL_LINES);
            gl.glVertex2f(0,0);
            gl.glVertex2f(x*scale,y*scale);
        gl.glEnd();
    }
}
