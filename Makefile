All: Stream ERT CloverLeaf_Serial CloverLeaf_OpenMP Plotting

Stream: STREAM/stream_c.exe

STREAM/stream_c.exe: 
	cd STREAM; cp Makefile Makefile.orig;\
	   sed -e 's/CFLAGS = -O2 -fopenmp/CFLAGS = -O3 -march=native -fstrict-aliasing -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20/' \
	       -e 's/gcc-4.9/${CC}/' Makefile.orig > Makefile && ls && make stream_c.exe && ./stream_c.exe

ERT: cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/MacLaptop2017

cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/MacLaptop2017:
	cd cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0; \
	   cp ../../roofline_toolkit/MacLaptop2017 Config

CloverLeaf_Serial: CloverLeaf/CloverLeaf_Serial/clover_leaf

CloverLeaf/CloverLeaf_Serial/clover_leaf:
	cd CloverLeaf/CloverLeaf_Serial; \
	     make COMPILER=GNU C_MPI_COMPILER_GNU=${CC} IEEE=1 C_OPTIONS='-g -fno-tree-vectorize' OPTIONS='-g -fno-tree-vectorize' && \
	     cp InputDecks/clover_bm256_short.in clover.in; #./clover_leaf

CloverLeaf_OpenMP: CloverLeaf/CloverLeaf_OpenMP/clover_leaf

CloverLeaf/CloverLeaf_OpenMP/clover_leaf:
	cd CloverLeaf/CloverLeaf_OpenMP; \
	     make COMPILER=GNU C_MPI_COMPILER_GNU=${CC} IEEE=1 C_OPTIONS='-g -march=native' OPTIONS='-g -march=native' && \
	     cp InputDecks/clover_bm256_short.in clover.in;  #./clover_leaf

Plotting: nersc-roofline/Plotting/plot_roofline.py.orig

nersc-roofline/Plotting/plot_roofline.py.orig:
	cd nersc-roofline/Plotting && cp data.txt data.txt.orig && \
 	   sed -e '/memroofs/s/828.758/21000.0/' -e '/mem_roof_names/s/HBM/L1/' data.txt.orig > data.txt && \
	   cp plot_roofline.py plot_roofline.py.orig && sed -e '/plt.show/s/^/#/' plot_roofline.py.orig > plot_roofline.py

clean:
	cd STREAM && git clean -fd && git checkout Makefile
	cd cs-roofline-toolkit && git clean -fd
	cd CloverLeaf/CloverLeaf_Serial && git clean -fd && git checkout clover.in
	cd CloverLeaf/CloverLeaf_OpenMP && git clean -fd && git checkout clover.in
	cd nersc-roofline && git clean -fd && git checkout Plotting/data.txt Plotting/plot_roofline.py
