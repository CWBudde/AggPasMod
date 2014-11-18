Modernized Pascal Anti-Grain Geometry
=====================================


Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod') 
-  Maintained by Christian-W. Budde (Christian@savioursofsoul.de)          
-  Copyright (c) 2012  
-  http://www.savioursofsoul.de/Christian/delphi/aggpasmod/
-  http://sourceforge.net/projects/aggpasmod/
  
Based on:                                                                 
-  AggPas / TAgg2D ver 2.4 RM3
-  Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        
-  Copyright (c) 2005-2006 
-  http://www.aggpas.org
-  http://www.crossgl.com/aggpas/

Based on:
-  Anti-Grain Geometry (AGG) ver 2.4 
-  by Maxim Shemanarev 
-  High Fidelity 2D Graphics,  High Quality Rendering Engine for C++
-  Copyright © 2002-2006 
-  http://www.antigrain.com





AggPasMod
---------
> Based on AggPas, which is itself based on the Anti-Grain Geometry, this project offers support for the latest Delphi Versions (XE & XE2) and contains some helper classes (VCL components and FireMonkey interface).
> Initially I started the port only to see how it compares performance wise. However, it took more than 3 weeks to update the project into the current form. Since I also added several improvments (assembler optimizations,  better code readability, some helper classes), I decided to release my fork of the AggPas port.
> The project is hosted on sourceforge. 
> If you like, what I did here, please consider a [donation](http://www.savioursofsoul.de/Christian/donations), since the project itself is only of little use to me personally. 
> Note that due to this reason I can only offer extended support if it is paid.
> Please also visit http://www.antigrain.com and http://www.aggpas.org for further information about the base projects

AggPas
------
> AggPas is an Object Pascal native port of the Anti-Grain Geometry library - AGG, originally written by Maxim Shemanarev in industrially standard C++. AGG as well as AggPas is Open Source and free of charge 2D vector graphics library.
> AGG (and AggPas too) doesn't depend on any graphic API or technology. Basically, you can think of AGG as of a rendering engine that produces pixel images in memory from some vectorial data. But of course, AGG can do much more than that. The ideas and the philosophy of AGG are ...
> Read more at: http://www.antigrain.com/about
> Updated version (D2009 & D2010) of AggPas library is available [here](http://www.crossgl.com/aggpas/AggPas24-rm3-D2009.zip).

AGG
---
> Anti-Grain Geometry (AGG) is an Open Source, free of charge graphic library, written in industrially standard C++. The terms and conditions of use AGG are described on The License page. 
AGG doesn't depend on any graphic API or technology. Basically, you can think of AGG as of a rendering engine that produces pixel images in memory from some vectorial data. But of course, AGG can do much more than that. 
The ideas and the philosophy of AGG are:
* **Anti-Aliasing**.
* **Subpixel Accuracy**.
* The highest possible quality.
* High performance.
* Platform independence and compatibility.
* Flexibility and extensibility.
* Lightweight design.
* Reliability and stability (including numerical stability).

> Below there are some key features (but not all of them):
* Rendering of arbitrary polygons with Anti-Aliasing and Subpixel Accuracy.
* Gradients and Gouraud Shading.
* Fast filtered image affine transformations, including many interpolation filters (bilinear, bicubic, spline16, spline36, sinc, Blackman).
* Strokes with different types of line joins and line caps.
* Dashed line generator.
* Markers, such as arrowheads/arrowtails.
* Fast vectorial polygon clipping to a rectangle.
* Low-level clipping to multiple rectangular regions.
* Alpha-Masking.
* A new, fast Anti-Alias line algorithm.
* Using arbitrary images as line patterns.
* Rendering in separate color channels.
* Perspective and bilinear transformations of vector and image data.
* Boolean polygon operations (and, or, xor, sub) based on Alan Murta's 
* General Polygon Clipper.

> Anti-Grain Geometry contains many interactive Demo exemples that are platform independent too, and use a simple platform_support class that currently has two implementations, for Win32 API and X11 (no Motiff, no other dependencies, just basic X11). One of the examples is an SVG Viewer.

> For more information look at News, Screenshots, Demo, Frequently Asked Questions, and Documentation. Here is the Download page.

> The collage on the Main Page is composed of real AGG examples with Xara X. There is a fragment that wasn't rendered with AGG, it's a piece of Boris Valejo' artwork, but I really used it when I worked on the image transformation algorithms.
