FROM ubuntu:18.04 AS builder
WORKDIR /project
RUN apt-get update && \
    apt-get install -y bash cmake git vim gcc gfortran python3 gnuplot-qt software-properties-common valgrind kcachegrind graphviz likwid apt-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update && \
    apt-get install -y gcc-9 g++-9 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 --slave /usr/bin/g++ g++ /usr/bin/g++-9 --slave /usr/bin/gcov gcov /usr/bin/gcov-9

SHELL ["/bin/bash", "-c"]

RUN groupadd chapter3 && useradd -m -s /bin/bash -g chapter3 chapter3

WORKDIR /home/chapter3
RUN chown -R chapter3:chapter3 /home/chapter3
USER chapter3

RUN git clone --recursive https://github.com/essentialsofparallelcomputing/Chapter3.git
WORKDIR /home/chapter3/Chapter3/STREAM
RUN cp Makefile Makefile.orig && \
  sed -e '1,$s/CFLAGS = -O2 -fopenmp/CFLAGS = -O3 -march=native -fstrict-aliasing -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20/' \
  -e '1,$s/gcc-4.9/gcc/' Makefile.orig > Makefile && make stream_c.exe

WORKDIR /home/chapter3

RUN alias python=python3

WORKDIR /home/chapter3/Chapter3/cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0
RUN cp ../../roofline_toolkit/MacLaptop2017 Config

WORKDIR /home/chapter3/Chapter3/CloverLeaf/CloverLeaf_Serial
RUN make CC=gcc COMPILER=GNU IEEE=1 C_OPTIONS='-g -fno-tree-vectorize' OPTIONS='-g -fno-tree-vectorize' && \
    cp InputDecks/clover_bm256_short.in clover.in

WORKDIR /home/chapter3/Chapter3/CloverLeaf/CloverLeaf_OpenMP
RUN make CC=gcc COMPILER=GNU IEEE=1 C_OPTIONS='-g -march=native' OPTIONS='-g -march=native' && \
    cp InputDecks/clover_bm256_short.in clover.in

WORKDIR /home/chapter3/Chapter3/nersc-roofline/Plotting
RUN cp data.txt data.txt.orig && sed -e '/memroofs/s/828.758/21000.0/' -e '/mem_roof_names/s/HBM/L1/' data.txt.orig > data.txt && \
    cp plot_roofline.py plot_roofline.py.orig && sed -e '/plt.show/s/^/#/'


ENTRYPOINT ["bash"]
