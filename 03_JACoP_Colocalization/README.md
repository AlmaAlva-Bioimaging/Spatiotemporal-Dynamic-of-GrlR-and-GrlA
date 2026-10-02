# Module 3: JACoP Colocalization

This repository module contains the complete analytical workflow for preparing enhanced-resolution images and executing automated batch colocalization analysis using the [BIOP JACoP plugin](https://github.com/BIOP/ijp-jacop-b) in ImageJ/Fiji.

---

## Step 1: Preprocessing (Format Conversion Script)
This Python script converts 32-bit floating-point Mean Shift Super Resolution (MSSR) output images into 16-bit integer multi-channel stacks, preparing them for robust colocalization analysis without distorting absolute fluorescence distributions.

### Detailed Functionality:
- **Quantitative Preservation:** Avoids wrap-around aberrations and intensity distortion by utilizing strict clipping (`np.clip`) and integer rounding (`np.uint16`) instead of relative Min-Max scaling.
- **Automated Channel Pairing:** Dynamically scans the designated `C1_Clover/MSSR` directory and matches corresponding `C2_Ruby/MSSR` files by substituting specific filename suffixes (e.g., `_c1_MSSR.tif` to `_c2_MSSR.tif`).
- **Fiji/ImageJ Compatibility:** Stacks both channels into a unified multi-page TIFF file ordered under standard `CYX` dimensions, embedding explicit ImageJ metadata (`imagej=True`) for seamless downstream import.

---

## Step 2: JACoP Batch Analysis (Automated Colocalization Macro)
This ImageJ macro automates batch colocalization processing for multi-channel merged stacks using the BIOP JACoP plugin.

### Detailed Functionality:
- **Batch Processing Loop:** Automatically iterates through all merged 16-bit `.tif` files within the input directory.
- **Dynamic ROI Management:** Automatically loads corresponding scaled ROI sets (`_roi_5x.zip`) for single-cell boundary handling.
- **Automated Thresholding & Metrics:** Applies Otsu thresholding independently to Channel 1 (Clover) and Channel 2 (Ruby), computing Pearson's coefficient, Manders' overlap coefficients, and intensity correlation parameters.
- **Headless Result Export:** Saves tabular results directly to the designated output directory and clears memory sequentially using `run("Close All")` to prevent RAM overflow during large dataset evaluations.

---

## Expected Input Directory Structure
```text
analysis/
├── C1_Clover/
│   └── MSSR/
│       ├── sample_01_c1_MSSR.tif
│       └── ...
├── C2_Ruby/
│   └── MSSR/
│       ├── sample_01_c2_MSSR.tif
│       └── ...
└── ROIs/
    └── 5x_Scaled/
        ├── sample_01_roi_5x.zip
        └── ...
