git clone --recursive git@github.com:UK-MAC/CloverLeaf.git
cd CloverLeaf/CloverLeaf_Serial
make COMPILER=GNU IEEE=1 C_OPTIONS='-g -fno-tree-vectorize' OPTIONS=' -g -fno-tree-vectorize'
sed -e "/87/s/87/10/" InputDecks/clover_bm256_short.in > clover.in
valgrind --tool=callgrind -v ./clover_leaf

