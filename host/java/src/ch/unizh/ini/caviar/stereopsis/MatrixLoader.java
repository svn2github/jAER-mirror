/*
 * MatrixLoader.java
 *
 * Created on 5. Oktober 2006, 09:29
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package ch.unizh.ini.caviar.stereopsis;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

/**
 * A conveniance function which loads a matrix into a 2D array.
 * The data is row-wise loaded from a textfile with space-delimited numbers. The array will be automatically allocated to the size 
 * of the loaded matrix. If not all rows have the same size, the longest row will determine the row length and unspecified
 * values will be 0. If file loading should file, the returnd matrix will be of size 1x1 with value 0.
 * @author Peter Hess
 */
public class MatrixLoader {
    
    /** Creates a new instance of MatrixLoader */
    public MatrixLoader() {
    }
    
    /** Loads the values of the stored matrix as integers from the specified file. */
    public static int[][] loadInt(String file) {
        int[][] array;
        int nofColumns = 0;
        int nofRows = 0;
        
        try {
            FileReader fr = new FileReader(file);
            BufferedReader br = new BufferedReader(fr);
            String line;
            
            //first pass: determine matrix size
            while ((line = br.readLine()) != null) {
                String[] s = line.trim().split(" +");
                if (s.length > nofRows) nofRows = s.length;
                nofColumns++;
            }
            br.close();
            fr.close();
            
            //second pass: load values
            fr = new FileReader(file);
            br = new BufferedReader(fr);
            array = new int[nofColumns][nofRows];
            int i = 0;
            
            while ((line = br.readLine()) != null) {
                String[] s = line.trim().split(" +");
                for (int j = 0; j < s.length; j++) {
                    array[i][j] = Integer.valueOf(s[j]);
                }
                i++;
            }
            br.close();
            fr.close();
        } catch (IOException e) {
            System.err.println("Error while reading " + file);
            System.err.println(e);
            return array = new int[1][1];
        }
        return array;
    }
}
