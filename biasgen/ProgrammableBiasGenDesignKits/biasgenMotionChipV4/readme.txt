This programmable bias generator is generation 4 for programmable bias generators. 
It was built by Luis Camunas, Rico Moeckel, Shih-Chii Liu and Tobi Delbruck.
This layout was fabricated on Rico Moeckel's chip as part of a visual motion sensor for autonomous microfliers.
It functions correctly but has not been carefully characterized yet.

See http://www.ini.uzh.ch/~tobi/biasgen

Features

This bias generator has two new features:

1. The bias buffer current is globally programmable to an 8-bit fraction of the masterbias current,
allowing better tuning of the buffer drive to allow the buffers to drive closer to the rails
for the small bias current biases.

2. It includes below-off-currrent (sub-pA) mirrors for and shifted rail voltage supplies for 
generating very small currents.

As usual, Caveat Emptor - use at your own risk.

-Tobi, Telluride July 2007