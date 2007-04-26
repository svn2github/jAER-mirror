<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML><!-- InstanceBegin template="/Templates/layout.dwt" codeOutsideHTMLIsLocked="false" -->
<HEAD>
<!-- InstanceBeginEditable name="doctitle" -->
<TITLE>INI-AE-Biasgen quick start</TITLE>
<!-- InstanceEndEditable --><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<!-- InstanceBeginEditable name="head" -->
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
<!-- InstanceEndEditable -->
<link href="../../CSS/Level1_Arial.css" rel="stylesheet" type="text/css">
<style type="text/css">
<!--
.bold {
	font-size: medium;
	font-weight: bold;
}
-->
</style>
</HEAD>

<BODY>
 <table width="548" bgcolor="#FFFFFF">
  <!--DWLayoutTable-->
  <tr bgcolor="#FFFF00">
    <td colspan="3" class="bold">Tobi Delbruck</td>
	<td colspan="8"><FORM method=GET action="http://www.google.com/search">
<TABLE>
  <tr>
<td>
<INPUT TYPE=text name=q size=20 maxlength=255 value="">
<INPUT type=submit name=btnG VALUE="Search">
<font size=-1>
<input 
type=hidden 
name=domains 
value="http://www.ini.unizh.ch">
<input type=radio name=sitesearch value="http://www.ini.unizh.ch" checked> INI
<input type=radio name=sitesearch value=""> WWW 
</font>
</td></tr></TABLE>
</FORM>
<!-- SiteSearch Google --></td>
  </tr>
  <tr bgcolor="#FFFFCC">
    <td width="42"><a href="http://www.ini.unizh.ch/%7Etobi">Home</a></td>
    <td width="71"><a href="/~tobi/motivation.php">Motivation</a></td>
    <td width="48"><a href="/~tobi/workHistory.php">History</a></td>
    <td width="50"><a href="/~tobi/people.php">People</a></td>
    <td width="57"><a href="/~tobi/projects.php">Projects</a></td>
    <td width="85"><a href="/~tobi/publications.php">Publications</a></td>
    <td width="75"><a href="/~tobi/resources/index.php">Resources</a></td>
    <td width="26"><a href="/~tobi/fun/index.php">Fun</a></td>
    <td width="54"><a href="/~tobi/contact.php">Contact</a></td>
  </tr>
</table>
 <!-- SiteSearch Google -->

<!-- InstanceBeginEditable name="Body" -->
<h1>Capturing, sequencing, viewing AE data using USB interfaces </h1>
<p><img src="images/boards.jpg" width="800" height="270"></p>
<p>This page describes how to set up and use the monitor capabilties of the<a href="../../tmpdiff/index.php"> transient silicon retina boards </a>developed by Tobi Delbruck and Patrick Lichtsteiner  and the <a href="../../studentProjectReports/bernerUSB2AER2006.pdf">monitor/sequencer board</a> developed by Raphael Berner, Anton Civit, and Tobi Delbruck as part of the <a href="../index.php">CAVIAR project</a>. </p>
<p>The <a href="../SimpleMonitorUSBXPress/">original SimpleMonitorUSBXPress boards</a> (these are boards in top right image; green one has &quot;aemon&quot; printed on board) are also supported by the INI-AE-Biasgen software described here..</p>
<p><strong>Update your <a href="https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen">subversion working directory</a> periodically to obtain the latest fixes and enhancements. See below <a href="#matlab">for using matlab</a>. </strong></p>
<h2>Software setup</h2>
<h3>Requirements:</h3>
<ul>
  <li>Windows XP</li>
  <li>Matlab 7.1 (if you want to use matlab)</li>
  <li>USB2.0 hardware interface (if you want to capture or sequence events). (A USB1 interface will also work with the tmpdiff128 retina boards but not with the USB2 monitor/sequencer boards and  will severely limit performance)</li>
  <li>Monitor-Sequencer or Monitor device, e.g. USB2 Monitor-Sequencer board or Tmpdiff128 retina board </li>
</ul>
<h3>Get code resources</h3>
<ol>
  <li> Installl a decent Subversion shell. A good Windows shell extension is <a href="http://tortoisesvn.tigris.org">TortoiseSVN</a>.</li>
  <li>Check out the code base from subversion. URL is <a href="https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/">https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/</a>.</li>
  <li><strong>If you are user who does not plan immediate code development</strong> and just want to use the existing code in matlab or to view the recorded data, you just need the JRE 1.5 (Java Runtime Environment 1.5, also called Java 5) from <a href="http://javashoplm.sun.com/ECom/docs/Welcome.jsp?StoreId=22&amp;PartDetailId=jre-1.5.0_06-oth-JPR&amp;SiteId=JSC&amp;TransactionId=noreg">Download JRE 5.0 Update 6</a>. This is a big download, so be patient. Install the JRE with all default options.</li>
</ol>
<p>If you plan to develop code, see <a href="#developer">Developer Setup</a> below </p>
<h3>Set up the Windows XP path</h3>
<p>If you are a user who is not developing Java classes, then you do not need to set up your PATH; the <a href="#viewer">cmd script to start CaviarViewer</a> does this for you. Skip to <a href="#driver">Driver installation</a> if you are using hardware.</p>
<p>&nbsp;</p>
<h3><a name="driver"></a>Driver installation</h3>
<h4>Boards based on CypressFX2 or CypressFX2LP </h4>
<p>The basic installation can use our customized .inf driver installation, following these steps.</p>
<p>After you plug in your CypressFX2 or CypressFX2LP follow these steps:</p>
<ol>
  <li>You will get the Found New Hardware dialog <br>
    <img src="images/driver1.png" width="503" height="392"></li>
  <li>Tell it to install from a specific location: <br>
    <img src="images/driver2.png" width="503" height="392"></li>
  <li>Navigate to the folder <em>wp5/USBAER/INI-AE-Biasgen/driverUSBIO</em>, select <em>OK</em>, and click <em>Next</em>: <br>
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
  <p>INI-AE-Biasgen\host\driverSiLabs\PreInstaller.exe</p>
</blockquote>
<p>Now when you plug in the SiLabs device the<em> New Hardware Found</em> dialog should be able to automagically install the correct USBXPress driver. </p>
<h2><a name="viewer"></a>Running the CaviarViewer application</h2>
<p>Now if everything has been done correctly, you should be able to run the Java class CaviarViewer to look at CAVIAR data. This application is started by the Windows CMD script located at the root of your checkout, i.e., at </p>
<blockquote>
  <p><em>	INI-AE-Biasgen\CaviarViewer.cmd</em></p>
</blockquote>
<p>Navigate to this folder and double-click the script to run the application. You should then see a window like the following (the initial image may be leftover OpenGL graphics card cruft) </p>
<p><img src="images/caviarViewer.png" width="427" height="436"> </p>
<p>You can now select a hardware interface from the <em>Interface</em> menu and a chip type from the <em>AEChip</em> menu and it should start rendering events from the device.</p>
<h3>Viewing data</h3>
<p>You can view either single data files (<em>.dat</em>) or synchronized sets of files (<em>.index</em>). You can drag and drop either type of file onto a fresh <em>CaviarViewer</em> <em>AEViewer</em> window. Or you can select the file using menu item <em>File/Open... </em>(shortcut &quot;o&quot;). If you want to select an .index file, then you need to change the file type in the file chooser; a bug in the graphics only shows you one choice and doesn't show the <em>Open</em> button until you hover over it. (This is a byproduct of using a fast native &quot;heavyweight&quot; Canvas to render the events). </p>
<p>Examine the menu's for help; almost all menu items have single-key shortcuts. (e.g. r=rewind, f=faster, s=slower, etc). </p>
<p>Below shows an example of viewing synchronized recorded data from 3 monitor/sequencer boards during the Sevilla CAVIAR workshop in Feb 2006. The retina (left) and WTA/object chip (right) are viewed using color-time representation, while the convolution chips (middle) are rendered with excitatory=green and inhibatory=red.</p>
<p><img src="images/3chips.png" width="900" height="326"> </p>
<h2>Hints for graphics performance</h2>
<p>Tobi can get 60 FPS on both desktop and laptop machines by using OpenGL rendering (see View/Enable OpenGL rendering checkbox). But it is also important that your graphics card is set to the proper OpenGL mode. For instance, on Tobi's Thinkpad T43p, with ATI Mobility FireGL V3200 card, it is much faster to be in 32 bit mode rather than 16 bit mode. </p>

<p>If Tobi doesn't use 32 bit mode the frame rate slows from 60 FPS to as little as 15 FPS with lots of events, suggesting that some hardware acceleration is not functioning.</p>
<p>The use of a decent contemporary graphics card is also important. After replacing the Matrox P650 in the desktop machine with a recent ATI low end gaming card, rendering performance increased dramatically. Built in graphics cards (e.g. the one that came on the motherboard of the Acer used in Sevilla) do not provide hardware OpenGL support and are much slower.</p>
<p>Hintscan be gotten from the diagnositics printed on startup of CaviarViewer. In the Thinkpad case, I see the following that indicates hardware OpenGL version 2.0 is running:</p>
<pre class="style2">Apr 17, 2006 9:55:47 AM ch.unizh.ini.caviar.graphics.OpenGLRetinaCanvas init<br>INFO: INIT GL IS: com.sun.opengl.impl.GLImpl<br>GL_VENDOR: ATI Technologies Inc.<br>GL_RENDERER: MOBILITY FireGL V3200 Pentium 4 (SSE2)<br>GL_VERSION: 2.0.5285GL_EXTENSTIONS: GL_ARB_multitexture GL_EXT_texture_env_add GL_EXT_compiled_vertex_array GL_S3_s3tc G<br>L_ARB_depth_texture GL_ARB_fragment_program GL_ARB_fragment_program_shadow GL_ARB_fragment_shader GL_ARB_imaging GL_ARB_<br>multisample GL_ARB_occlusion_query GL_ARB_point_parameters GL_ARB_point_sprite GL_ARB_shader_objects GL_ARB_shading_lang<br>uage_100 GL_ARB_shadow GL_ARB_shadow_ambient GL_ARB_texture_border_clamp GL_ARB_texture_compression GL_ARB_texture_cube_<br>map GL_ARB_texture_env_add GL_ARB_texture_env_combine GL_ARB_texture_env_crossbar GL_ARB_texture_env_dot3 GL_ARB_texture<br>_mirrored_repeat GL_ARB_transpose_matrix GL_ARB_vertex_blend GL_ARB_vertex_buffer_object GL_ARB_vertex_program GL_ARB_ve<br>rtex_shader GL_ARB_window_pos GL_ATI_draw_buffers GL_ATI_element_array GL_ATI_envmap_bumpmap GL_ATI_fragment_shader GL_A<br>TI_map_object_buffer GL_ATI_separate_stencil GL_ATI_texture_env_combine3 GL_ATI_texture_float GL_ATI_texture_mirror_once<br> GL_ATI_vertex_array_object GL_ATI_vertex_attrib_array_object GL_ATI_vertex_streams GL_ATIX_texture_env_combine3 GL_ATIX<br>_texture_env_route GL_ATIX_vertex_shader_output_point_size GL_EXT_abgr GL_EXT_bgra GL_EXT_blend_color GL_EXT_blend_func_<br>separate GL_EXT_blend_minmax GL_EXT_blend_subtract GL_EXT_clip_volume_hint GL_EXT_draw_range_elements GL_EXT_fog_coord G<br>L_EXT_framebuffer_object GL_EXT_multi_draw_arrays GL_EXT_packed_pixels GL_EXT_point_parameters GL_EXT_polygon_offset GL_<br>EXT_rescale_normal GL_EXT_secondary_color GL_EXT_separate_specular_color GL_EXT_shadow_funcs GL_EXT_stencil_wrap GL_EXT_<br>texgen_reflection GL_EXT_texture3D GL_EXT_texture_compression_s3tc GL_EXT_texture_cube_map GL_EXT_texture_edge_clamp GL_<br>EXT_texture_env_combine GL_EXT_texture_env_dot3 GL_EXT_texture_filter_anisotropic GL_EXT_texture_lod_bias GL_EXT_texture<br>_mirror_clamp GL_EXT_texture_object GL_EXT_texture_rectangle GL_EXT_vertex_array GL_EXT_vertex_shader GL_HP_occlusion_te<br>st GL_KTX_buffer_region GL_NV_blend_square GL_NV_occlusion_query GL_NV_texgen_reflection GL_SGI_color_matrix GL_SGIS_gen<br>erate_mipmap GL_SGIS_multitexture GL_SGIS_texture_border_clamp GL_SGIS_texture_edge_clamp GL_SGIS_texture_lod GL_SUN_mul<br>ti_draw_arrays GL_WIN_swap_hint WGL_EXT_extensions_string WGL_EXT_swap_control<br>glViewport reshape 
</pre>
<p>Another thing with ATI cards on laptops: ATI has a thing called Powerplay. It should be set to Maximum Performance. The ATI display control panel then looks like this</p>
<p><img src="images/ATIPowerplay.png" width="518" height="588"> </p>
<h2><a name="matlab"></a>Using matlab with the code</h2>
<p>To use the java classes in matlab is  straightforward, once things are set up correctly and you understand the process. You need to tell matlab where the java classes are, and this is accomplished by running the script <em>INI-AE-Biasgen\host\matlab\startup.m</em>.</p>
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
  C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI<br>
C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI\SiLabsNativeWindows</span></p>
<p>You may also find it helpful to look at <strong>the javadoc for the classes</strong>, which is accessible from the CaviarViewer Help menu. Or if you have a working copy, you can navigate to the javadoc folder <em>CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/java/dist/javadoc</em>and open the index.html file in your browser. </p>
<h3>Reading raw events into matlab</h3>
<p>Use the function <strong>loadaerdat.m</strong></p>
<ul>
  <li>In the repository at <a href="https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/matlab">https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/matlab</a></li>
  <li>Snapshot of <a href="loadaerdat.m">loadaerdat.m</a> for easy access</li>
</ul>
<h3>Extracting raw events to x,y,type</h3>
<p>You need to bitand and bitshift if you want to do this in matlab, or you can use the EventCellExtractor that goes with each chip class. Using the java class is faster but may fragment matlab memory. </p>
<ul>
  <li>For matlab example, see the function<br> 
    <a href="https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/matlab/retina/extractRetina128EventsFromAddr.m">https://svn.ini.unizh.ch/repos/avlsi/CAVIAR/wp5/USBAER/INI-AE-Biasgen/host/matlab/retina/extractRetina128EventsFromAddr.m</a></li>
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
<p>Install Java Development Kit (JDK) 1.5.x and Netbeans. These come bundled together as a <a href="http://www.netbeans.org/downloads/index.html">Netbeans bundle</a>. If you are not a Java developer already, you will need to get both the JDK and a development environment. You can try to use another development environment, e.g. Eclipse, but then you will need to build the project. You may be confused by the plethora of Java versions: What you need is plain old J2SE (Java 2 Standard Edition), not J2EE or any other Java bundle. Specifically, you need:
</p>
<ol>
  <ol>
    <li>Java 2 SE Development Kit (JDK) 1.5.x</li>
    <li>Netbeans (5.x)</li>
  </ol>
</ol>
<h2>Windows PATH setup</h2>
<p>If you are a developer, you need to set up the Windows PATH envirorment so that you can use the native code DLLs. Tobi likes to do this by making a new enviroment variable and then referencing this in the Windows PATH. </p>
<p>Open the Control Panel &quot;System&quot; and click on &quot;Advanced&quot; and then &quot;Environment variables&quot;. </p>
<p>Now make a new variable called &quot;<em>usb2aemon</em>&quot;. Then open a Windows explorer window to the working copy directory of the code you checked out and copy the <strong>complete</strong> path to the two folders, separated by a &quot;;&quot; (semicolon) to this <em>usb2aemon</em> variable </p>
<blockquote>
  <p>wp5\USBAER\INI-AE-Biasgen\host\java\JNI<br>
    wp5\USBAER\INI-AE-Biasgen\host\java\JNI\SiLabsNativeWindows</p>
</blockquote>
<p>On Tobi's machine it looks like this:</p>
<p class="style1"> C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI;C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java\JNI\SiLabsNativeWindows</p>
<p>Now add this new variable to the Windows PATH variable by including it surrounded by &quot;%&quot;, as in ...<em>;%usb2aemon%</em>. </p>
<p>PATH (or &quot;path&quot;, case doesn't matter) is another environment variable that Windows uses to search for DLLs. Don't forget the semicolon &quot;;&quot; between the usb2aemon variable and the other PATH components. </p>
<h2>Netbeans development environment and opening the project</h2>
<p>The netbeans project is located at<em> INI-AE-Biasgen\host\java\. </em></p>
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
<h2><strong>Thesycon USB driver</strong></h2>
<p>You can install the complete Thesycon development kit, which provide extensive documentation including javadoc that can be integrated into netbeans for easy method and class lookup. CAVIAR (the INI partner) has bought a license for 20 users for CAVIAR non-commerical purposes from Thesycon. The installer is located at </p>
<blockquote>
  <p> INI-AE-Biasgen\host\driverUSBIO\usbio_full_2.31.exe</p>
</blockquote>
<p>The Thesycon driver can be installed on any USB device using the Thesycon driver installation wizard. Note that you can install it for your mouse, your disk drive, etc - although this is NOT recommended. Instead, for the USB2 AER boards that INI-AE-Biasgen supports just let Windows find the matching driver <a href="#driver">as indicated above</a>.</p>
<p><a href="../index.php">Go to CAVIAR project</a></p>
<p>&nbsp;</p>
<!-- InstanceEndEditable -->
<br>
<em>
<!-- #BeginDate format:Am1 -->August 30, 2006<!-- #EndDate -->
</em>
 <table width="427" bgcolor="#FFFFCC">
  <tr>
    <td><a href="http://www.ini.unizh.ch/~tobi">Home</a></td>
    <td><a href="/~tobi/motivation.php">Motivation</a></td>
    <td><a href="/~tobi/workHistory.php">History</a></td>
    <td><a href="/~tobi/people.php">People</a></td>
    <td><a href="/~tobi/projects.php">Projects</a></td>
    <td><a href="/~tobi/publications.php">Publications</a></td>
    <td><a href="/~tobi/resources/index.php">Resources</a></td>
    <td><a href="/~tobi/fun/index.php">Fun</a></td>
    <td><a href="/~tobi/contact.php">Contact</a></td>
  </tr>
</table>
</BODY>
<!-- InstanceEnd --></HTML>
