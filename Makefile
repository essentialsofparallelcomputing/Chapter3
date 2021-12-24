All: Stream ERT CloverLeaf_Serial CloverLeaf_OpenMP Plotting Jupyter
.PHONY: Stream ERT CloverLeaf_Serial CloverLeaf_OpenMP Plotting Jupyter

Stream: STREAM/stream_c.exe

STREAM/stream_c.exe: 
	cd STREAM && cp Makefile Makefile.orig && \
	   sed -e 's/CFLAGS = -O2 -fopenmp/CFLAGS = -O3 -march=native -fstrict-aliasing -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=10000000 -DNTIMES=20/' \
	       -e 's/gcc-4.9/${CC}/' Makefile.orig > Makefile && ls && make stream_c.exe && ./stream_c.exe

ERT: cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/Quick

# Roofline was updated upstream to python 3. Make sure your default python is python3
# Sed command modifies script to skip over extraneous text before regular output. If
#   you get different text in the files in the run directory (something like
#   ./Results.Ubuntu.01/Run.002/FLOPS.001/MPI.0001/OpenMP.0001/try.001) modify the 
#   preprocess.py file to strip that text instead
cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/Quick:
	cd cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0 && \
	   cp ../../roofline_toolkit/Quick Config && \
	   sed -i -e '/for l in os.sys.stdin:/a\ \ l=l.replace("Invalid MIT-MAGIC-COOKIE-1 key","")' Scripts/preprocess.py && \
	   ./ert Config/Quick  && ps2pdf Results.Quick/Run.001/roofline.ps && evince roofline.pdf


CloverLeaf_Serial: CloverLeaf/CloverLeaf_Serial/clover_leaf

CloverLeaf/CloverLeaf_Serial/clover_leaf:
	cd CloverLeaf/CloverLeaf_Serial && \
	     make COMPILER=GNU C_MPI_COMPILER_GNU=${CC} IEEE=1 C_OPTIONS='-g -O3 -fno-tree-vectorize' OPTIONS='-g -O3 -fno-tree-vectorize' && \
	     cp InputDecks/clover_bm4_short.in clover.in && sed -i -e '/end_step/s/87/4/' clover.in && \
	     valgrind --tool=callgrind -v ./clover_leaf && kcachegrind

CloverLeaf_OpenMP: CloverLeaf/CloverLeaf_OpenMP/clover_leaf

CloverLeaf/CloverLeaf_OpenMP/clover_leaf:
	cd CloverLeaf/CloverLeaf_OpenMP && \
	     make COMPILER=INTEL IEEE=1  OMP_INTEL="-qopenmp" FLAGS_INTEL="-g -O3 -no-prec-div -xhost" && \
	     cp InputDecks/clover_bm4_short.in clover.in && sed -i -e '/end_step/s/87/10/' clover.in && ./clover_leaf && \
	     likwid-perfctr -C 0-4 -g MEM_DP ./clover_leaf && \
	     advixe-cl --collect roofline --project-dir ./advixe_proj -- ./clover_leaf && \
	     advixe-gui ./advixe_proj

Plotting: nersc-roofline/Plotting/plot_roofline.py.orig

nersc-roofline/Plotting/plot_roofline.py.orig:
	cd nersc-roofline/Plotting && \
	   2to3 -w plot_roofline.py && \
	   sed -i -e '/plt.show/s/^#//' plot_roofline.py && \
	   python plot_roofline.py data.txt


Jupyter:
	cd JupyterNotebook && jupyter notebook --ip=0.0.0.0 --port=8080 HardwarePlatformCharaterization.ipynb

clean:
	cd STREAM && git clean -fd && git checkout Makefile
	cd cs-roofline-toolkit && rm -f Empirical_Roofline_Tool-1.1.0/Config/Quick && rm -f Empirical_Roofline_Tool-1.1.0/roofline.pdf && \
	  git checkout Empirical_Roofline_Tool-1.1.0/Scripts/preprocess.py
	cd CloverLeaf/CloverLeaf_Serial && git clean -fd && git checkout clover.in
	cd CloverLeaf/CloverLeaf_OpenMP && git clean -fd && git checkout clover.in
	cd nersc-roofline && git clean -fd && git checkout Plotting/data.txt Plotting/plot_roofline.py
