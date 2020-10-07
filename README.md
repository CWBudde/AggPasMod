Modernized Pascal Anti-Grain Geometry
=====================================

Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod') 
-  Maintained by Christian-W. Budde (Christian@savioursofsoul.de)          
-  Copyright (c) 2012-2015  
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
Based on AggPas, which is itself based on the Anti-Grain Geometry, this project offers support for the latest Delphi Versions (XE and above) and contains some helper classes (VCL components and FireMonkey interface).

Initially, the AggPas port had been modernized only to see how it compares performance wise. However, after many weeks of work and several improvments (assembler optimizations, better code readability, some helper classes), it was decided to release this modernized version of the AggPas port independently.

The project was hosted on SourceForge and has been moved to GitHub. 


Installation
------------
Once the project has been checked out or downloaded, it can be installed in the IDE by installing the runtime and the design-time packages for the given Delphi/Lazarus version. However, before that some directories must be known by the IDE. Please specify these manually until the packages compile. 

Alternatively the packages can be obtained and installed via GetIt (XE8). 

Recently Delphinus-Support has also been added to support older Delphi versions (see https://github.com/Memnarch/Delphinus for more information).


License
-------

The (modernized) port is licensed under the same terms as the original library:

  Anti-Grain Geometry - Version 2.4 (Public License)
  Copyright (C) 2002-2005 Maxim Shemanarev (http:www.antigrain.com)
  Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com

  Permission to copy, use, modify, sell and distribute this software
  is granted provided this copyright notice appears in all copies.
  This software is provided "as is" without express or implied
  warranty, and with no claim as to its suitability for any purpose.
