# Chapter 3 Performance limits and profiling
This is from Chapter 3 of Parallel and High Performance Computing, Robey and Zamora,
Manning Publications, available at http://manning.com

The book may be obtained at
   http://www.manning.com/?a_aid=ParallelComputingRobey

Copyright 2019-2020 Robert Robey, Yuliana Zamora, and Manning Publications
Emails: brobey@earthlink.net, yzamora215@gmail.com

See License.txt for licensing information.

Requirements for Performance limits and profiling: 
      cachegrind and valgrind
      Intel Advisor (free versions for students, and under the oneAPI distribution from Intel)
      OpenMP - already in most compilers
      OpenMPI or MPICH
      likwid

#  Stream (Book: Measuring bandwidth using the Stream Benchmark)
      1. Stream repoo is from "git clone https://github.com/jeffhammond/STREAM.git"
      2. Edit Makefile and change compile line to -O3 -march=native -fstrict-aliasing 
             -ftree-vectorize -fopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20
      3. Build with make
      4. Run ./stream_c.exe

#  Empirical Roofline Toolkit (Book: Measuring bandwidth using the Empirical Roofline Toolkit)
      1. Get the roofline toolkit 
         “git clone https://bitbucket.org/berkeleylab/cs-roofline-toolkit.git”
      2. cd cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0
      3. cp Config/config.madonna.lbl.gov.01 Config/MacLaptop2017
      4. edit Config/MacLaptop2017. Below is the file for the 2017 Mac laptop
      5. Run tests ./ert Config/MacLaptop2017
      6. View Results.MacLaptop2017/Run.001/roofline.ps

#  Call-graph (Book: Call-graph using Cachegrind)
      1. Download the CloverLeaf miniapp from https://github.com/UK-MAC/CloverLeaf
         a. git clone --recursive https://github.com/UK-MAC/CloverLeaf.git
      2. Build the serial version of CloverLeaf
         a. cd CloverLeaf/CloverLeaf_Serial
         b. make COMPILER=GNU IEEE=1 C_OPTIONS=”-g -fno-tree-vectorize” \
            OPTIONS=”-g -fno-tree-vectorize”
      3. Run valgrind with the callgrind tool
         a. cp InputDecks/clover_bm256_short.in clover.in
         b. edit clover.in and change cycles from 87 to 10
         c. valgrind --tool=callgrind -v ./clover_leaf
      4. Start qcachegrind up
         a. qcachegrind
         b. load a specific callgrind.out.XXX file into the qcachegrind graphical user interface (GUI).
      5. Right click on Call Graph and change settings for image

#  Intel Advisor (Book: Intel Advisor)
      1. Build the OpenMP version of CloverLeaf.
         a. git clone --recursive https://github.com/UK-MAC/CloverLeaf.git
         b. cd CloverLeaf/CloverLeaf_OpenMP
         c. make COMPILER=INTEL IEEE=1 C_OPTIONS="-g -xHost" OPTIONS="-g -xHost"
               or
         d. make COMPILER=GNU IEEE=1 C_OPTIONS=”-g -march=native” OPTIONS=”-g
              -march=native”
      2. Run the application in the Intel Advisor tool
         a. cp InputDecks/clover_bm256_short.in clover.in
         b. advixe-gui
            i. set the executable to clover_leaf in the CloverLeaf_OpenMP directory
            ii. the working directory can be set to the application directory or CloverLeaf_OpenMP
         c. GUI operation:
            Select the Start Survey Analysis pulldown and choose Start Roofline Analysis
         d. Command line:
            i. advixe-cl --collect roofline --project-dir ./advixe_proj -- ./clover_leaf
            ii. startup the gui and click on the folder icon to load the run data
         e. Click on Survey and Roofline to view results
         f. Click on far left side of top panel of performance results where it says roofline in vertical text

      
#  Likwid (Book: Likwid perfctr)
      1. Install likwid from package manager or with
         a. git clone https://github.com/RRZE-HPC/likwid.git
         b. cd likwid
         c. edit config.mk
              set PREFIX to your install director
              change ACCESSMODE from accessdaemon to perf_event for containers (no MSR access)
              change BUILDFREQ from true to false for user space installs
         d. make
         e. make install
      2. Enable MSR with ‘sudo modprobe msr’
      3. likwid-perfctr -C 0-87 -g MEM_DP ./clover_leaf


#  Plotting (Book: Custom roofline plot using python and matplotlib)
      1. git clone https://github.com/cyanguwa/nersc-roofline.git
      2. cd nersc-roofline/Plotting
      3. modify data.txt
      4. python plot_roofline.py data.txt

   Jupyter notebook (Book: Jupyter notebook)
      1. brew install python3
      2. pip install numpy scipy matplotlib jupyter
	
	Run the jupyter notebook

      1. Download Jupyter notebook <https://github.com/EssentialsofParallelComputing/Chapter3>
      2. Start up the notebook with
         jupyter notebook HardwarePlatformCharacterization.ipynb
      3. You can change settings for the hardware in the first section for your platform of interest.
