#!/bin/sh
cd cs-roofline-toolkit && git checkout Empirical_Roofline_Tool-1.1.0/Python/ert_utils.py Empirical_Roofline_Tool-1.1.0/Python/ert_core.py Empirical_Roofline_Tool-1.1.0/ert && cd ..
sed -i -e '/print /s/$/)/' -e '/print /s/print /print(/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/ert
sed -i -e '/import/s/$/\nsys.path.insert(0, "Python")/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/ert
sed -i -e '/print /s/$/)/' -e '/print /s/print /print(/' -e '/xrange/s/xrange/range/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Python/ert_core.py
sed -i -e '/print /s/$/)/' -e '/print /s/print /print(/' -e '/xrange/s/xrange/range/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Python/ert_utils.py
sed -i -e '/import/s/$/\nfrom functools import reduce/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Python/ert_utils.py
sed -i -e '/print /s/$/)/' -e '/print /s/print /print(/' -e '/print /s/\\)$/\\/' -e '/            GFLOP_sec_max/s/$/)/' cs-roofline-toolkit/Empirical_Roofline_Tool-1.1.0/Scripts/preprocess.py

