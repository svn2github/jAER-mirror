<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML>
<HEAD>
<TITLE>jAER</TITLE>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css">
<!--
.style1 {font-family: "Courier New", Courier, mono}
-->
</style>
<style type="text/css">
<!--
.style2 {
	font-size: xx-small;
	color: #6633FF;
}
-->
</style>

<link href="../../CSS/Level1_Arial.css" rel="stylesheet" type="text/css">
<style type="text/css">
<!--
.bold {
	font-size: medium;
	font-weight: bold;
}
.style1 {font-family: Verdana, Arial, Helvetica, sans-serif}
-->
</style>
</HEAD>

<BODY>
 <!-- SiteSearch Google -->
<a href="http://sourceforge.net"><img src="http://sflogo.sourceforge.net/sflogo.php?group_id=181834&amp;type=1" width="88" height="31" border="0" alt="SourceForge.net Logo" /></a>
<h1>jAER - Java AER Open Source Project on SourceForge </h1>
<h2>Capturing, sequencing, viewing, processing address-event representation (AER) data </h2>
<p><strong>This is the home page of the <a href="https://sourceforge.net/projects/jaer">jAER project</a>, hosted at SourceForge.</strong></p>
<p><img src="images/boards.jpg" width="800" height="270"></p>
<p>This page  describes how to set up and use software for AER systems like the<a href="http://siliconretina.ini.uzh.ch"> temporal contrast silicon retina </a> and the monitor/sequencer board developed in  the <a href="http://caviar.ini.uzh.ch">EU CAVIAR project</a>. </p>
<p>The <a href="http://www.ini.unizh.ch/%7Etobi/caviar/SimpleMonitorUSBXPress/">original SimpleMonitorUSBXPress boards</a> (these are boards in top right image; green one has &quot;aemon&quot; printed on board) are also supported by the jAER software described here..</p>
<p><strong>See below <a href="#matlab">for using matlab</a>. </strong></p>
<h2>Software setup</h2>
<h3>Requirements:</h3>
<ul>
  <li>Windows XP</li>
  <li>Matlab 7.1 (if you want to use matlab)</li>
  <li>USB2.0 hardware interface (if you want to capture or sequence events). (A USB1 interface will also work with the tmpdiff128 retina boards but not with the USB2 monitor/sequencer boards and  will severely limit performance)</li>
  <li>Monitor-Sequencer or Monitor device, e.g. USB2 Monitor-Sequencer board or <a href="http://siliconretina.ini.uzh.ch">Tmpdiff128 silicon retina</a></li>
</ul>
<h3>Get code resources</h3>
<ol>
  <li> Installl a decent Subversion shell. A good Windows shell extension is <a href="http://tortoisesvn.tigris.org">TortoiseSVN</a>.</li>
  <li>Check out the code base from subversion. URL is <tt><a href="https://jaer.svn.sourceforge.net/svnroot/jaer">https://jaer.svn.sourceforge.net/svnroot/jaer</a></tt>.</li>
  <li><strong>If you are user who does not plan immediate code development</strong> and just want to use the existing code in matlab or to view the recorded data, you just need the JRE 1.6 (Java Runtime Environment 1.6, also called Java 6 JRE) from <a href="http://java.sun.com">java.sun.com</a>. This is a big download, so be patient. Install the JRE with all default options.</li>
</ol>
<p>If you plan to develop code, see <a href="#developer">Developer Setup</a> below </p>
<h3><a name="driver"></a>Driver installation</h3>
<h4>Boards based on CypressFX2 or CypressFX2LP </h4>
<p>The basic installation can use our customized .inf driver installation, following these steps.</p>
<p>After you plug in your CypressFX2 or CypressFX2LP based board follow these steps:</p>
<ol>
  <li>You will get the Found New Hardware dialog <br>
    <img src="images/driver1.png" width="503" height="392"></li>
  <li>Tell it to install from a specific location: <br>
    <img src="images/driver2.png" width="503" height="392"></li>
  <li>Navigate to the folder <em>host/driverUSBIO</em>, select <em>OK</em>, and click <em>Next</em>: <br>
    <img src="images/driver3.png" width="959" height="414"></li>
  <li>The installation should complete appropriately. Here is what happens for a Tmpdiff128 retina: <br>
    <img src="images/driver4.png" width="503" height="392"> </li>
  <li>Now the Device Manager should show the device: <br>
    <img src="images/driver5.png" width="588" height="598"></li>
</ol>
<p>&nbsp;</p>
<h4>Boards based on SiLabs C8051F320</h4>
<p>Run the SiLabs driver preinstaller to prepare Windows to sucessfully search for the SiLabs USBXPress driver. </p>
<blockquote>
  <p>driverSiLabs\PreInstaller.exe</p>
</blockquote>
<p>Now when you plug in the SiLabs device the<em> New Hardware Found</em> dialog should be able to automagically install the correct USBXPress driver. </p>
<h2><a name="viewer"></a>Running the AEViewer application</h2>
<p>Now if everything has been done correctly, you should be able to run the Java class jAERViewer to look at AER data. This application is started by the Windows CMD script located at the root of your checkout, i.e., at </p>
<blockquote>
  <p><em>	jAERViewer.cmd</em></p>
</blockquote>
<p>Navigate to this folder and double-click the script to run the application. You should then see a window like the following (the initial image may be leftover OpenGL graphics card cruft) </p>
<p><img src="images/caviarViewer.png" width="427" height="436"> </p>
<p>You can now select a hardware interface from the <em>Interface</em> menu and a chip type from the <em>AEChip</em> menu and it should start rendering events from the device. </p>
<h3>Viewing data</h3>
<p>You can view either single data files (<em>.dat</em>) or synchronized sets of files (<em>.index</em>). You can drag and drop either type of file onto a fresh <em>AEViewer</em> window. Or you can select the file using menu item <em>File/Open... </em>(shortcut &quot;o&quot;). If you want to select an .index file, then you need to change the file type in the file chooser; a bug in the graphics only shows you one choice and doesn't show the <em>Open</em> button until you hover over it. (This is a byproduct of using a fast native &quot;heavyweight&quot; Canvas to render the events). </p>
<p>Examine the menu's for help; almost all menu items have single-key shortcuts. (e.g. r=rewind, f=faster, s=slower, etc). </p>
<p>Below shows an example of viewing synchronized recorded data from 3 monitor/sequencer boards during the Sevilla CAVIAR workshop in Feb 2006. The retina (left) and WTA/object chip (right) are viewed using color-time representation, while the convolution chips (middle) are rendered with excitatory=green and inhibatory=red.</p>
<p><img src="images/3chips.png" width="900" height="326"> </p>
<h2>Data file location</h2>
<p>Newly logged data files are stored in the <em>host\java</em> folder.</p>
<h2>Hints for graphics performance</h2>
<p>You can get 60 FPS on both desktop and laptop machines by using OpenGL rendering (see View/Enable OpenGL rendering checkbox). But it is also important that your graphics card is set to the proper OpenGL mode. For instance, on a Thinkpad T43p, with ATI Mobility FireGL V3200 card, it is much faster to be in 32 bit mode rather than 16 bit mode. </p>
<p>If you doesn't use 32 bit mode the frame rate slows from 60 FPS to as little as 15 FPS with lots of events, suggesting that some hardware acceleration is not functioning.</p>
<p>The use of a decent contemporary graphics card is also important. After replacing the Matrox P650 in the desktop machine with a recent ATI low end gaming card, rendering performance increased dramatically. Some built in graphics cards  do not provide hardware OpenGL support and are much slower.</p>
<p>Hintscan be gotten from the diagnositics printed on startup of jAERViewer. In the Thinkpad case, I see the following that indicates hardware OpenGL version 2.0 is running:</p>
<pre class="style2">Apr 17, 2006 9:55:47 AM ch.unizh.ini.caviar.graphics.OpenGLRetinaCanvas init<br>INFO: INIT GL IS: com.sun.opengl.impl.GLImpl<br>GL_VENDOR: ATI Technologies Inc.<br>GL_RENDERER: MOBILITY FireGL V3200 Pentium 4 (SSE2)<br>GL_VERSION: 2.0.5285GL_EXTENSTIONS: GL_ARB_multitexture GL_EXT_texture_env_add GL_EXT_compiled_vertex_array GL_S3_s3tc G<br>L_ARB_depth_texture GL_ARB_fragment_program GL_ARB_fragment_program_shadow GL_ARB_fragment_shader GL_ARB_imaging GL_ARB_<br>multisample GL_ARB_occlusion_query GL_ARB_point_parameters GL_ARB_point_sprite GL_ARB_shader_objects GL_ARB_shading_lang<br>uage_100 GL_ARB_shadow GL_ARB_shadow_ambient GL_ARB_texture_border_clamp GL_ARB_texture_compression GL_ARB_texture_cube_<br>map GL_ARB_texture_env_add GL_ARB_texture_env_combine GL_ARB_texture_env_crossbar GL_ARB_texture_env_dot3 GL_ARB_texture<br>_mirrored_repeat GL_ARB_transpose_matrix GL_ARB_vertex_blend GL_ARB_vertex_buffer_object GL_ARB_vertex_program GL_ARB_ve<br>rtex_shader GL_ARB_window_pos GL_ATI_draw_buffers GL_ATI_element_array GL_ATI_envmap_bumpmap GL_ATI_fragment_shader GL_A<br>TI_map_object_buffer GL_ATI_separate_stencil GL_ATI_texture_env_combine3 GL_ATI_texture_float GL_ATI_texture_mirror_once<br> GL_ATI_vertex_array_object GL_ATI_vertex_attrib_array_object GL_ATI_vertex_streams GL_ATIX_texture_env_combine3 GL_ATIX<br>_texture_env_route GL_ATIX_vertex_shader_output_point_size GL_EXT_abgr GL_EXT_bgra GL_EXT_blend_color GL_EXT_blend_func_<br>separate GL_EXT_blend_minmax GL_EXT_blend_subtract GL_EXT_clip_volume_hint GL_EXT_draw_range_elements GL_EXT_fog_coord G<br>L_EXT_framebuffer_object GL_EXT_multi_draw_arrays GL_EXT_packed_pixels GL_EXT_point_parameters GL_EXT_polygon_offset GL_<br>EXT_rescale_normal GL_EXT_secondary_color GL_EXT_separate_specular_color GL_EXT_shadow_funcs GL_EXT_stencil_wrap GL_EXT_<br>texgen_reflection GL_EXT_texture3D GL_EXT_texture_compression_s3tc GL_EXT_texture_cube_map GL_EXT_texture_edge_clamp GL_<br>EXT_texture_env_combine GL_EXT_texture_env_dot3 GL_EXT_texture_filter_anisotropic GL_EXT_texture_lod_bias GL_EXT_texture<br>_mirror_clamp GL_EXT_texture_object GL_EXT_texture_rectangle GL_EXT_vertex_array GL_EXT_vertex_shader GL_HP_occlusion_te<br>st GL_KTX_buffer_region GL_NV_blend_square GL_NV_occlusion_query GL_NV_texgen_reflection GL_SGI_color_matrix GL_SGIS_gen<br>erate_mipmap GL_SGIS_multitexture GL_SGIS_texture_border_clamp GL_SGIS_texture_edge_clamp GL_SGIS_texture_lod GL_SUN_mul<br>ti_draw_arrays GL_WIN_swap_hint WGL_EXT_extensions_string WGL_EXT_swap_control<br>glViewport reshape 
 </pre>
<p>Another thing with ATI cards on laptops: ATI has a thing called Powerplay. It should be set to Maximum Performance. The ATI display control panel then looks like this</p>
<p><img src="images/ATIPowerplay.png" width="518" height="588"> </p>
<h2><a name="matlab"></a>Using matlab with the code</h2>
<p>To use the java classes in matlab is  possible, once things are set up correctly and you understand the process. You need to tell matlab where the java classes are, and this is accomplished by running the script <em>host\matlab\startup.m</em>.</p>
<p>To use the code that uses the native DLLs, you need to set up matlab's search path, which is (as of Matlab 7.x) different than the Windows PATH. To set this up you need to add the same native code folders to matlab's path, which is specified by the matlab file <em>librarypath.txt</em>. The easiest way to edit this file is the type &quot;<em>edit librarypath.txt</em>&quot;; this will open the correct file. </p>
<p>On Tobi's machine, this file has the contents</p>
<p><span class="style1">##<br>
  ## FILE: librarypath.txt<br>
  ##<br>
  ## Entries:<br>
  ## o path_to_jnifile<br>
  ## o [alpha,glnx86,sol2,unix,win32,mac]=path_to_jnifile<br>
  ## o $matlabroot/path_to_jnifile<br>
  ## o $jre_home/path_to_jnifile<br>
  ##<br>
  $matlabroot/bin/$arch<br>
  C:\Documents and Settings\tobi\My Documents\jAER\host\java\JNI<br>
C:\Documents and Settings\tobi\My Documents\jAER\java\JNI\SiLabsNativeWindows</span></p>
<p>Note that Matlab 7.1 handling of Java-allocated heap memory (objects) is poor. Large memory leaks will rapidly use up your matlab memory.</p>
<h3>Reading raw events into matlab</h3>
<p>Use the function <strong>loadaerdat.m</strong></p>
<ul>
  <li>In the repository at <a href="https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/matlab"><tt><a href="https://jaer.svn.sourceforge.net/svnroot/jaer">https://jaer.svn.sourceforge.net/svnroot/jaer</a></tt>/trunk/host/matlab</a></li>
  <li>Snapshot of <a href="loadaerdat.m">loadaerdat.m</a> for easy access</li>
</ul>
<h3>Writing a .dat file from matlab that can be sequenced or viewed</h3>
<p>Use the function <strong>saveaerdat.m</strong></p>
<ul>
  <li>Also in the repository at <a href="http://jaer.svn.sourceforge.net/viewvc/jaer/trunk/host/matlab/loadaerdat.m">http://jaer.svn.sourceforge.net/viewvc/jaer/trunk/host/matlab/loadaerdat.m</a></li>
</ul>
<h3>Extracting raw events to x,y,type</h3>
<p>You need to bitand and bitshift if you want to do this in matlab, or you can use the EventCellExtractor that goes with each chip class. Using the java class is faster but may fragment matlab memory. </p>
<ul>
  <li>For matlab example, see the function<br> 
    <a href="http://jaer.svn.sourceforge.net/viewvc/jaer/trunk/host/matlab/retina/extractRetina128EventsFromAddr.m">http://jaer.svn.sourceforge.net/viewvc/jaer/trunk/host/matlab/retina/extractRetina128EventsFromAddr.m</a></li>
  <li>For java class usage, examine the following example</li>
</ul>
<blockquote>
  <p class="style1">chip=ch.unizh.ini.caviar.chip.retina.Tmpdiff128;<br>
  extractor=chip.getEventExtractor; % get the extractor object from this chip. <br>
  % now you can use the extractor to extract a packet of events or you can use the methods directly<br>
  x=extractor.getXFromAddress(raw); % raw is a raw AE address<br>
  y=extractor.getYFromAddress(raw)<br>
  type=extractor.getTypeFromAddress(raw)</p>
</blockquote>
<h3>Translating x,y,type to raw address to filter specific cells in matlab </h3>
<p>You can use a function like this one, which is correct for tmpdiff128. Note how the x address is flipped because that is how it is rendered in java to make it rightside up (Java puts the origin at UL corner and increases x rightwards and y downwards.) </p>
<blockquote>
  <p><span class="style1">function raw=getraw(x,y,pol)<br>
  raw=(y)*256+(127-x)*2+pol; %extractor.getAddressFromCell(x,y,pol);</span></p>
</blockquote>
<h1><a name="developer"></a>Developer setup</h1>
<p>If you plan to develop Java classes you will need a development environment and the java development kit </p>
<p>Install Java Development Kit (JDK) and Netbeans. These come bundled together as a <a href="http://www.netbeans.org/downloads/index.html">Netbeans bundle</a>. If you are not a Java developer already, you will need to get both the JDK and a development environment. You can try to use another development environment, e.g. Eclipse, but then you will need to build the project. You may be confused by the plethora of Java versions: What you need is plain old J2SE (Java 2 Standard Edition), not J2EE or any other Java bundle. Specifically, you need:
</p>
<ol>
  <ol>
    <li>Java 2 SE Development Kit (JDK) 1.5.x</li>
    <li>Netbeans (5.x)</li>
  </ol>
</ol>
<h2>Windows PATH setup</h2>
<p>The windows PATH is set up in the netbeans project for development. </p>
<p>If you are a developer, you need to set up the Windows PATH envirorment so that you can use the native code DLLs. You can do this by making a new enviroment variable and then referencing this in the Windows PATH. You need to add paths to the folders <em>JNI</em> and <em>JNI\SiLabsNativeWindows</em>, which are located in the <em>host\java</em> folder. </p>
<p>Open the Control Panel &quot;System&quot; and click on &quot;Advanced&quot; and then &quot;Environment variables&quot;. </p>
<p>Now make a new variable called &quot;<em>jaerjni</em>&quot;. Then open a Windows explorer window to the working copy directory of the code you checked out and copy the <strong>complete</strong> path to the two folders, separated by a &quot;;&quot; (semicolon) to this <em>usb2aemon</em> variable </p>
<p>On one machine it looks like this:</p>
<p class="style1"> C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI;C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI\SiLabsNativeWindows</p>
<p>Now add this new variable to the Windows PATH variable by including it surrounded by &quot;%&quot;, as in ...<em>;%jaerjni%</em>. </p>
<p>PATH (or &quot;path&quot;, case doesn't matter) is another environment variable that Windows uses to search for DLLs. Don't forget the semicolon &quot;;&quot; between the usb2aemon variable and the other PATH components. </p>
<h2>Netbeans development environment and opening the project</h2>
<p>The netbeans project is located at<em> host\java\. </em></p>
<p>You can open this project from the <em>File/Open project</em> menu. You may then need to fix some reference problems. </p>
<ol>
  <li>Open the Project properties by right-clicking the project and selecting Properties.<br>
    <br> 
  <img src="images/netbeansProjectProperties.png" width="401" height="574"></li>
  <li>Then select the Libraries tab and remove all libraries that are missing.</li>
  <li>Now add in the following jars:<br>
    <em>UsbIoJava.jar, jogl.jar, and jogl-natives-win32.jar</em> <br>
    These files are located in <em>INI-AE-Biasgen\host\java\jars. <br>
    <br>
    <img src="images/projectLibraries.png" width="772" height="542">  </em></li>
</ol>
<p>Now you should be able to build and run the project.<em>. </em></p>
<h3>Netbeans startup options to avoid OpenGL and DirectDraw conflicts.</h3>
<p>You may notice flashing in the netbeans IDE while you run the CaviarViewer. This probably is a result of simultaneous use of OpenGL resources by netbeans and CaviarViewer. To avoid this, use the following switches in the Netbeans configuration file, which is located at <em>C:\Program Files\netbeans-5.0\etc\netbeans.conf:</em></p>
<pre># options used by netbeans launcher by default, can be overridden by explicit
   # command line switches
   netbeans_default_options=&quot;-J-Xms32m ... <strong>-J-Dsun.java2d.opengl=false -J-Dsun.java2d.noddraw=true</strong>&quot;
  
 </pre>
<p>These switches turn off opengl rendering for the JVM running netbeans and prevent a conflict between windows direct draw and opengl. (I'm not sure about exactly what switches are necessary but these prevent the flashing.)<br>
</p>
<h4>Java JOGL openGL problems under java 1.5</h4>
<p>We recently ran into a problem with UnsatisifiedLinkError on WCanvasPeer.setBackgroundErase on a german localized laptop from HP with an Intel graphics chipset. This errror shows up as an exception &quot;javax.media.opengl.GLCanvas.disableBackgroundErase&quot; thrown as an InvocationTargetException in GLCanvas.java: 352).</p>
<p>This exception is fixed by updated the JRE to 1.6. </p>
<h2><strong>Thesycon USB driver</strong></h2>
<p>The (newer) USB drivers are built using the excellent USB driver development kit from Thesycon (<a href="http://www.thesycon.de">www.thesycon.de</a>).</p>
<p><br>
  <em>
  <!-- #BeginDate format:Am1 -->April 27, 2007<!-- #EndDate -->
  </em></p>
</BODY>
</HTML>
