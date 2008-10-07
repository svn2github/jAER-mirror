/*
 * AEDataFile.java
 *
 * Created on March 13, 2006, 12:59 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 *
 *
 *Copyright March 13, 2006 Tobi Delbruck, Inst. of Neuroinformatics, UNI-ETH Zurich
 */
package ch.unizh.ini.caviar.eventio;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

/**
 * Defines file extensions for data and index files.
 * @author tobi
 */
public interface AEDataFile {

    /** file extension for data files, including ".", e.g. ".dat" */
    public static final String DATA_FILE_EXTENSION = ".dat";
    /** file extension for index files that contain information about a set of related data files, ".index" */
    public static final String INDEX_FILE_EXTENSION = ".index";
    /** The leading comment character for data files, "#" */
    public static final char COMMENT_CHAR = '#';
    /** The format header, in unix/shell style the first line of the data file reads, e.g. "#!AER-DAT2.0" where
    the "!AER-DAT" is defined here 
     */
    public static final String DATA_FILE_FORMAT_HEADER = "!AER-DAT";
    /** The most recent format version number string */
    public static final String DATA_FILE_VERSION_NUMBER = "2.0";
    /** Format used for log file names */
    public static DateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ssZ"); //e.g. Tmpdiff128-   2007-04-04T11-32-21-0700    -0 ants molting swarming.dat
}
