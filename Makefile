All: Stream ERT CloverLeaf_Serial CloverLeaf_OpenMP Plotting Jupyter
.PHONY: Stream ERT CloverLeaf_Serial CloverLeaf_OpenMP Plotting Jupyter

Stream: STREAM/stream_c.exe

STREAM/stream_c.exe: 
	cd STREAM && cp Makefile Makefile.orig && \
	   sed -e 's/CFLAGS = -O2 -fopenmp/CFLAGS = -O3 -march=native -fstrict-aliasing -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=10000000 -DNTIMES=20/' \
	       -e 's/gcc-4.9/${CC}/' Makefile.orig > Makefile && ls && make stream_c.exe && ./stream_c.exe

ERT: cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/Quick

cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Config/Quick:
	cd cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0 && \
	   cp ../../roofline_toolkit/Quick Config && \
	   2to3 -w ert Python Scripts ; \
	   sed -i -e 's!len(msec_med)/2!len(msec_med)//2!' Scripts/preprocess.py && \
	   sed -i -e "s!subprocess.PIPE!subprocess.PIPE, encoding='utf8'!" Python/ert_utils.py && \
	   sed -i -e "/META_DATA/s!\] ==!\].strip() ==!" -e '/len(lines.i/s!\]) ==!\].strip()) ==!' Python/ert_core.py && \
	   ./ert Config/Quick  && ps2pdf Results.Quick/Run.001/roofline.ps && xpdf roofline.pdf

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
	     advixe-cl --collect roofline --project-dir ./advixe_proj -- ./clover_leaf && \
	     advixe-gui ./advixe_proj
	     # hardware counters not available in docker container
	     #likwid-perfctr -C 0-4 -g MEM_DP ./clover_leaf && \

Plotting: nersc-roofline/Plotting/plot_roofline.py.orig

nersc-roofline/Plotting/plot_roofline.py.orig:
	cd nersc-roofline/Plotting && cp data.txt data.txt.orig && \
 	   sed -e '/memroofs/s/828.758/21000.0/' -e '/mem_roof_names/s/HBM/L1/' data.txt.orig > data.txt && \
	   2to3 -w plot_roofline.py ; \
	   sed -i -e '/plt.show/s/^/#/' plot_roofline.py && \
	   python plot_roofline.py

Jupyter:
	cd JupyterNotebook && jupyter notebook --ip=0.0.0.0 --port=8080 HardwarePlatformCharaterization.ipynb

clean:
	cd STREAM && git clean -fd && git checkout Makefile
	cd cs-roofline-toolkit && rm -f Empirical_Roofline_Tool-1.1.0/Config/Quick && \
	   git checkout Empirical_Roofline_Tool-1.1.0/*/*.py Empirical_Roofline_Tool-1.1.0/ert
	cd CloverLeaf/CloverLeaf_Serial && git clean -fd && git checkout clover.in
	cd CloverLeaf/CloverLeaf_OpenMP && git clean -fd && git checkout clover.in
	cd nersc-roofline && git clean -fd && git checkout Plotting/data.txt Plotting/plot_roofline.py
