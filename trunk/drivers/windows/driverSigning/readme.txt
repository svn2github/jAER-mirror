Holds the driver signing tools for jAER windows drivers, primarily using Thesycon USBIO but not limited to these.
The certificate is issued to "iniLabs GmbH" from GlobalSign CA, a root authority. Tobi Delbruck has the certificate installed
on his machine at INI and holds the private signing key in his firefox certificate store. The password is "big...".

The script signDrivers.cmd shows how the signing is done.

Notes - 
finally fixed driver signing problem under windows 7 - the x64 drivers now install with no warning about unsigned driver.
was typo for wrong windows version in signing script and trying to catalog with existing catalog file. Catalog file should be rebuilt from scratch each time.
