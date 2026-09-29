# Distance Transform Analysis Pipeline

This repository module contains the complete analytical pipeline to evaluate the spatial dynamics and subcellular localization of GrlR and GrlA in enteropathogenic *Escherichia coli* (EPEC). The workflow is divided into three sequential steps: image pre-processing from diffraction-limited crops, Mean Shift Super Resolution (MSSR) enhancement, and Euclidean distance transform analysis.

## Step 1: Raw Image Pre-processing

This Jupyter Notebook automates the extraction and pre-processing of individual bacterial cells from full-field-of-view (FOV) diffraction-limited images. It utilizes Fiji/ImageJ ROI zip files to generate single-cell crops, separating fluorescence channels for downstream Mean Shift Super Resolution (MSSR) and distance transform analysis.

### Features
- **Automated Cropping:** Extracts individual cells based on polygon/freehand ROIs with a defined 10-pixel padding.
- **Channel Separation:** Splits the multi-channel `.tif` images into individual 16-bit single-channel files (C1_Clover and C2_Ruby).
- **ROI Scaling:** Translates original ROI coordinates to the new crop dimensions and generates a 5x scaled ROI set, preparing the data for MSSR spatial amplification.
- **Overlap Detection:** Creates a spatial label map to detect if a cropped bounding box includes segments of neighboring cells, exporting this registry to `overlapping_cells.txt`.

### Dependencies
Ensure the following Python libraries are installed (tested on Python 3.9.25):
- `numpy`
- `tifffile`
- `scikit-image`
- `read-roi`
- `roifile`

### Input Requirements
The script expects an input directory containing:
1. Multi-channel `.tif` or `.tiff` images (e.g., `image_01_merged.tif`).
2. Corresponding Fiji ROI zip files named with the `_rois_rois.zip` suffix (e.g., `image_01_rois_rois.zip`).

### Output Structure
The script generates a new analysis directory containing the following subfolders:
- `Merged_Crops/`: Cropped multi-channel TIFFs.
- `C1_Clover/`: Cropped single-channel TIFFs (e.g., GrlA).
- `C2_Ruby/`: Cropped single-channel TIFFs (e.g., GrlR).
- `ROIs/Original/`: Shifted ROI zip files matching the new cropped dimensions.
- `ROIs/5x_Scaled/`: ROI zip files scaled by a factor of 5 for MSSR compatibility.

---

## Step 2: Mean Shift Super Resolution (MSSR) Batch Processing

This step applies the Mean Shift Super Resolution (MSSR) algorithm to the individual, diffraction-limited single-channel crops generated in Step 1. Due to the memory-intensive nature of the MSSR mathematical transformations, this process is executed via a standalone Python script rather than a Jupyter Notebook to ensure stability and prevent kernel crashes.
Download MSSR from: https://github.com/adanog/MSSR
### Features
- **Batch Execution:** Automatically processes all `.tif` files within the designated input directory.
- **Optimized for Fluorescence:** Implements active intensity normalization (`INT_NORM = True`) and bicubic interpolation (`FTI = False`) to preserve quantitative fluorescence properties.
- **Fiji Compatibility:** Outputs super-resolved images as 32-bit float TIFFs (`_MSSR.tif`), ensuring metadata and dimensional integrity for downstream ImageJ/Fiji inspection.

### MSSR Parameters
The script applies the following spatial amplification settings optimized for EPEC subcellular structures:
- `AMP` (Amplification factor) = 5
- `FWHM` (Full Width at Half Maximum) = Adjust accordingly to each fluorophore
- `ORDER` (Derivative order) = 0
- `MESH` = True

### Execution Instructions
Run this script directly from the Conda terminal to manage memory effectively.

1. Open the Anaconda Prompt.
2. Activate the corresponding environment:
   ```bash
   conda activate your_env_name
3. Navigate to the directory containing the script:
   ```bash
   cd "path\to\your\script"
4. Execute the Python file:
   ```bash
   python 02_run_mssr_batch.py
### Note: Ensure you update the input_dir and output_dir variables within the script before execution

## Step 3: Distance Transform Analysis & Subcellular Localization

This Jupyter Notebook performs the final spatial analysis on the enhanced-resolution images. It computes the Euclidean Distance Transform (EDT) for each cell to map the fluorescence intensity gradient from the cell periphery to its geometric center, allowing for the classification of GrlR and GrlA subcellular localization.

## Features
- **Spatial Masking:** Converts scaled Fiji ROIs into integer label masks for accurate single-cell isolation.
- **Euclidean Distance Transform:** Utilizes OpenCV (`cv2.distanceTransform`) to assign a relative distance value to every pixel within the cell boundary.
- **Intensity Normalization & Regression:** Applies min-max normalization (0 to 1) to the fluorescence signal and calculates the linear regression of the intensity profile.
- **Automated Classification:** Evaluates the relative intensity difference across the cell. A negative slope indicates **Membrane** localization, a positive slope indicates **Cytoplasm**, and values within the `DISPERSED_THRESHOLD` (± 0.10) are classified as **Dispersed**.
- **Publication-Ready Figures:** Automatically generates localized scatter plots with linear fit lines in vector format (`.svg`) using the Okabe-Ito color palette for specific cells designated in the `CELLS_FOR_FIGURE` list.

### Dependencies
Ensure the following libraries are installed in your Python environment:
- `pandas`
- `numpy`
- `opencv-python` (`cv2`)
- `tifffile`
- `scipy`
- `scikit-image`
- `read-roi`
- `matplotlib`

### Parameters
Before running the notebook, verify the following variables match your experimental setup:
- `PIXEL_SIZE_NM = 23.4`: Defines the spatial resolution.
- `DISPERSED_THRESHOLD = 0.10`: Threshold for classifying a uniform (dispersed) distribution.
- `FIXED_THRESHOLD = 10`: Background intensity cutoff to exclude background noise.

### Output Structure
The script exports the results to your defined output directory:
- `Summary.xlsx`: A cell-by-cell summary detailing origin classification, normalized slopes, R² values, and relative differences.
- `Raw_Data.csv`: Pixel-level raw and normalized intensities paired with their respective distance values for custom downstream plotting.
- `SVG_Figures/`: Directory containing the isolated `.svg` plots for the chosen representative cells.

  ## Citation

If you use these scripts in your research, please cite our manuscript:

Alma Alva, Rogelio Hernández-Tamayo, Carmen Guadarrama, Paúl Hernández-Herrera, Martin Thanbichler, Peter L. Graumann, Christopher Wood, Adán Guerrero, José Luis Puente. *Spatiotemporal organization and stoichiometry of GrlR and GrlA dictate virulence gene expression in enteropathogenic Escherichia coli.* (Submitted)

## **Authors**

* **[Alma Alva]** - *Biological Concept & Data Analysis*
* **[Paúl Hernández-Herrera]** - *Python Implementation & Optimization* -(https://github.com/paul-hernandez-herrera)
