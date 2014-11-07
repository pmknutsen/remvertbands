##remvertvands
remvertvands.m is a Matlab function for removing vertical sawtooth patterns in images
scanned by digital slide scanners such as the Hamamatsu NanoZoomer series.

##Usage
  `removebands(F, A, S, W, O)`

where `F` is the filename of the image to process, `A` is the normalization amplitude
(pixel intensity), `S` the detection limit (standard deviations), `W` a manual offset of
automatically detected band intervals (pixels), `O` is a manual horizontal offset of the
normalization vector (pixels).

Example:
  `removebands('myimg.jpeg', 25, 3, -3, -1)`

###Requirements
Should work with any version of Matlab.

###Install
Copy the remvertvands.m file to your Matlab search path.

