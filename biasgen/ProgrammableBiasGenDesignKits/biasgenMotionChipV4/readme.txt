This programmable bias generator is generation 4 for programmable bias generators. 
It was built by Luis Camunas, Rico Moeckel, Shih-Chii Liu and Tobi Delbruck.
This layout was fabricated on Rico Moeckel's chip as part of a visual motion sensor for autonomous microfliers.
It functions correctly but has not been carefully characterized yet.

See http://jaer.wiki.sourceforge.net/biasgen

As usual, Caveat Emptor - use at your own risk.

-Tobi, Telluride July 2007

Features

This bias generator has two new features:

1. The bias buffer current is globally programmable to an 8-bit fraction of the masterbias current,
allowing better tuning of the buffer drive to allow the buffers to drive closer to the rails
for the small bias current biases.

2. It includes below-off-currrent (sub-pA) mirrors for and shifted rail voltage supplies for 
generating very small currents.

Files

The biasgen layout is for AMS (austria microsystems) 0.35u CMOS with 4M-2P but the bias generator uses only single poly.

The design is for Tanner Tools v12.

biasgenMDC.tdb is the layout and the folder biasgenMDC has the biasgenMDC.tanner schematic startup file.

ams_C35.ext is the extractor definition file.

biasgen.vdb is the Tanner LVS command file.

sim contains model parameters for SPICE simulation and various TSPICE command decks, e.g. 0biasgen.sp, 0biasprogrammable.sp.

The rules are vendor rules (not scalable). 

The process parameters and design rules are available to Europractice members
and cannot be posted publically.

