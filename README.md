# Quantitative Spatiotemporal Analysis Pipeline for Bacterial Microscopy

This repository contains a comprehensive suite of Python scripts and ImageJ/Fiji macros designed to quantify the subcellular localization, spatiotemporal dynamics, and colocalization of protein complexes (such as GrlR and GrlA) in enteropathogenic *Escherichia coli* (EPEC).

The computational workflow integrates Mean Shift Super Resolution (MSSR), Euclidean Distance Transform calculations, Single-Molecule Tracking (SMT), automated colocalization, and advanced spatial metrics (NICD and Proximity AUC) to process high-resolution fluorescence microscopy datasets recursively.

---

## Pipeline Architecture & Modules

The repository is organized into four sequential analytical modules. Each folder contains its own detailed `README.md` with specific execution instructions, metadata parsing rules, and expected directory structures.

### 📁 [01_MSSR_and_Distance_Transform](./01_MSSR_and_Distance_Transform)
**Function:** Image resolution enhancement with MSSR and Distance Transform analysis.
- Pre-processes diffraction-limited images to be cropped to have 1 cell per field of view, ideally.
- Automates the batch processing of cropped raw diffraction-limited images using the Mean Shift Super Resolution (MSSR) algorithm.
- Utilizes Python to perform Euclidean Distance Transform calculations directly on the MSSR outputs.
- Extracts 1D spatial intensity profiles and evaluates relative intensity differences along the bacterial cell.

### 📁 [02_SMT_Distance_Transform](./02_SMT_Distance_Transform)
**Function:** Distance Transform analysis applied to SMT datasets.
- Processes single-molecule tracking data based on MATLAB to classify each trajectory into 'Static', 'Transient ', or 'Mobile'.
- Generates confinement maps.
- Performs targeted Euclidean Distance Transform analysis.
- Generates comprehensive KDE plots to identify the location of each track within the cell.

### 📁 [03_JACoP_Colocalization](./03_JACoP_Colocalization)
**Function:** Format normalization and automated colocalization.
- **Python Script:** Converts 32-bit floating-point MSSR outputs into quantitative 16-bit multi-channel stacks without distorting absolute fluorescence distributions.
- **Fiji Macro:** Automates batch colocalization analysis utilizing the BIOP JACoP plugin, applying ROI-restricted Otsu thresholding to extract Pearson's and Manders' overlap coefficients.

### 📁 [04_NICD_Recursive_Analysis](./04_NICD_Recursive_Analysis)
**Function:** Advanced recursive spatial metrics.
- Recursively traverses hierarchical experimental directories (`Strain/Medium/Time`) to analyze the spatial behavior of non-overlapping protein fractions.
- Calculates the directed **Nearest Inter-Channel Distance (NICD)** and computes the non-parametric **Proximity Area Under the Curve (AUC)** using 32-bit Euclidean Distance Maps.
- Outputs a consolidated, experiment-wide CSV report with full hierarchy metadata.

---

## Prerequisites & System Requirements

To ensure full reproducibility, the following software environment is required:

**Image Processing & Macros:**
- [Fiji / ImageJ](https://imagej.net/software/fiji/) (v1.53 or higher).
- **Plugins:** BIOP JACoP (https://github.com/BIOP/ijp-jacop-b)).

**Python Environment:**
- Python 3.9+
- Required libraries: `numpy`, `pandas`, `scipy`, `tifffile`, `opencv-python`.
- Recommended: Jupyter Notebook or Google Colab for interactive visualization of the Distance Transform outputs.

---

## Data Availability
Representative datasets, including raw microscopy images and corresponding ROI sets needed to test this pipeline, are publicly available on Zenodo (DOI: [Insert Zenodo DOI Here]). 

---

## Citation
If you utilize any of these pipelines or modified portions of this code in your research, please cite the corresponding manuscript:

> **Alma Alva, Rogelio Hernández-Tamayo, Carmen Guadarrama, Paúl Hernández-Herrera, Martin Thanbichler, Peter L. Graumann, Christopher Wood, Adán Guerrero, José Luis Puente1.** (2026). *Spatiotemporal organization and stoichiometry of GrlR and GrlA dictate virulence gene expression in enteropathogenic Escherichia coli. Under Review.
