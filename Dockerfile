FROM ubuntu:18.04 AS builder
WORKDIR /project
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
    apt-get -qq install -y cmake git vim gcc g++ gfortran software-properties-common wget gnupg-agent \
            python2 python3 gnuplot-qt valgrind kcachegrind graphviz likwid ghostscript \
            mpich libmpich-dev \
            openmpi-bin openmpi-doc libopenmpi-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installing latest GCC compiler (version 10)
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get -qq update && \
    apt-get -qq install -y gcc-10 g++-10 gfortran-10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 30
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 20

#RUN update-alternatives --set python /usr/bin/python2

# We are installing both OpenMPI and MPICH. We could use the update alternatives to switch between them
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 90\
                        --slave /usr/bin/g++ g++ /usr/bin/g++-10\
                        --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-10\
                        --slave /usr/bin/gcov gcov /usr/bin/gcov-10

# Installing Intel compilers since they give the best vectorization among compiler vendors
# Also installing Intel Advisor to look at vectorization performance
RUN wget -q https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
RUN apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
RUN rm -f GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
RUN echo "deb https://apt.repos.intel.com/oneapi all main" >> /etc/apt/sources.list.d/oneAPI.list
RUN echo "deb [trusted=yes arch=amd64] https://repositories.intel.com/graphics/ubuntu bionic main" >> /etc/apt/sources.list.d/intel-graphics.list
RUN apt-get -qq update && \
    apt-get -qq install -y \
             intel-hpckit-getting-started \
             intel-oneapi-common-vars \
             intel-oneapi-common-licensing \
             intel-oneapi-dev-utilities \
             intel-oneapi-icc \
             intel-oneapi-ifort \
             intel-oneapi-advisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Needed libraries for Intel Advisor graphics user interface
RUN apt-get -qq update && \
    apt-get -qq install -y libgtk2.0-0 libxxf86vm1 libsm6 libnss3 libnss3 libx11-xcb1 libxtst6 \
            libasound2 libatk-bridge2.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

RUN groupadd chapter3 && useradd -m -s /bin/bash -g chapter3 chapter3

WORKDIR /home/chapter3
RUN chown -R chapter3:chapter3 /home/chapter3
USER chapter3

RUN git clone --recursive https://github.com/essentialsofparallelcomputing/Chapter3.git

WORKDIR /home/chapter3

WORKDIR /home/chapter3/Chapter3
#RUN make

ENTRYPOINT ["bash"]
