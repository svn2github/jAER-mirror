/*
 * EngineeringFormat.java
 *
 * Created on October 1, 2005, 8:34 PM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */

package ch.unizh.ini.caviar.util;


/**
 * Formats and parses engineering fmt, e.g. 3n 4u 8.2M
 *
 * @author tobi
 */
public class EngineeringFormat {
    
    public int precision=1;
    
    protected char[] suffixes={'a','f','p','n','u','m',' ','k','M','G','T'};
    int smallestDecade=-18, largestDecade=15;
    String formatterString=null;
    
    /** Creates a new instance of EngineeringFormat */
    public EngineeringFormat() {
        setPrecision(precision);
    }
    
    public boolean fillSignEnabled=false;
    
    public String format(double x){
        boolean isNeg=x<0;
        x=Math.abs(x);
        double dec=Math.floor(Math.log10(x)); // e.g. 2.3e-7 -> -7
        if(dec<smallestDecade) return "0";
        if(dec>largestDecade) return "inf";
        StringBuilder s=new StringBuilder();
        if(isNeg) s.append("-"); else if(fillSignEnabled) s.append("");
        double k=Math.floor(dec/3);
        double div=Math.pow(10, k*3);
        double mant=x/div;
        s.append(String.format(formatterString,mant));
        if(k==0) return s.toString();
        if(k<0) s.append(suffixes[(int)k+6]); else s.append(suffixes[(int)k+6]);
        return s.toString();
    }
    
    public String format(float x){
        return format((double)x);
    }
    
    public double parseDouble(String s){
        if(s==null) return 0;
        try{
            return Double.parseDouble(s);
        }catch(NumberFormatException e){
//            System.out.println("couldn't parseDouble "+s);
            char[] ca=new char[1];
            s.getChars(s.length()-1,s.length(), ca, 0);
            char c=ca[0]; // e.g. f, p, u
//            System.out.println("suffix is "+c);
            int i;
            boolean foundSuffix=false;
            for(i=0;i<suffixes.length;i++){
                if(suffixes[i]==c) {
                    foundSuffix=true;
                    break;
                }
            }
            if(!foundSuffix) throw new NumberFormatException("can't parse "+s);
            double mult=Math.pow(10,(i-6)*3);
//            System.out.println("mult is "+mult);
            char[] c2=new char[s.length()-1];
            s.getChars(0, s.length()-1, c2,0);
            String s2=new String(c2);
//            System.out.println("now parsing string "+s2);
            double y;
            try{
                y=Double.parseDouble(s2);
            }catch(NumberFormatException e2){
                throw new NumberFormatException("can't parse "+s);
            }
            double ret=y*mult;
//            System.out.println("returning "+ret);
            return ret;
        }
    }
    
    public float parseFloat(String s){
        return (float)parseDouble(s);
    }
    
    
    void setPrecision(int p){
        precision=p;
        formatterString="%."+precision+"f";
    }
    
//    public static final void main(String[] args){
//        EngineeringFormat f=new EngineeringFormat();
//        double[] x={1e-19, 2e-14, 9.9e-7, 2, 3e4, 9e14, 1e20};
//        for(int i=0;i<x.length;i++){
//            System.out.println("x="+x[i]+"   : "+f.format(x[i]));
//        }
//    }

    public int getPrecision() {
        return this.precision;
    }
}
