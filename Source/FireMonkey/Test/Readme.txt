In order to use the freetype font renderer on windows, you need to download and install the freetype dll from https://www.freetype.org. Rename it to freetype.dll and put it in either in the windows system folder or the exe folder. 

In probably is installed on OsX by default.

The freetype dll is 32 bit so you can only use it in applications compiled as 32 bit.

Then set the AGG2D_USE_FREETYPE conditional define in FMX.Canvas.AggPas and Agg2D.