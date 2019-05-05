FROM ubuntu AS builder
WORKDIR /project
RUN apt-get update && \
    apt-get install -y bash cmake git vim gcc gfortran python3 gnuplot-qt valgrind kcachegrind graphviz likwid
RUN git clone --recursive https://github.com/essentialsofparallelcomputing/Chapter3.git
RUN cd Chapter3/STREAM && cp Makefile Makefile.orig && \
  sed -e '1,$s/CFLAGS = -O2 -fopenmp/CFLAGS = -O3 -march=native -fstrict-aliasing -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20/' \
  -e '1,$s/gcc-4.9/gcc/' Makefile.orig > Makefile && make stream_c.exe && cd ../..

RUN alias python=python3
RUN cd Chapter3/cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0 && cp ../../MacLaptop2017 Config && cd ../../..

RUN cd Chapter3/CloverLeaf/CloverLeaf_Serial && \
    make CC=gcc COMPILER=GNU IEEE=1 C_OPTIONS='-g -fno-tree-vectorize' OPTIONS='-g -fno-tree-vectorize' && \
    cp InputDecks/clover_bm256_short.in clover.in && cd ../../..
RUN cd Chapter3/CloverLeaf/CloverLeaf_OpenMP && \
    make CC=gcc COMPILER=GNU IEEE=1 C_OPTIONS='-g -march=native' OPTIONS='-g -march=native' && \
    cp InputDecks/clover_bm256_short.in clover.in && cd ../../..

RUN bash

ENTRYPOINT ["bash"]
