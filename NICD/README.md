# NICD Recursive Spatial Analysis Pipeline

This module contains the advanced ImageJ/Fiji recursive macro (`NICD`) designed to process hierarchical experimental directories and execute automated two-channel spatial distribution and proximity analyses on enhanced-resolution images.

---

## Purpose & Overview
The workflow recursively traverses top-level experimental directory trees to analyse an entire experiment in a single automated run. It identifies analysable condition folders, performs ROI-restricted Otsu thresholding, extracts non-overlapping signal fractions, and calculates directed **Nearest Inter-Channel Distance (NICD)** alongside **Proximity Area Under the Curve (AUC)** metrics using 32-bit Euclidean Distance Maps (EDMs).

---

## Expected Dataset Hierarchy
An analysable condition folder must contain **ALL THREE** required subfolders:
```text
<Top-Level Experiment>/
  └── <Strain>/
      └── <Medium>/
          └── <Time>/
              ├── C1_Clover/
              ├── C2_Ruby/
              └── ROI_5x/
```
---

## Expected File Naming & Metadata Parsing
- **C1 Clover:** `C1_Clover/<Cell_ID>_c1_MSSR.tif`
- **C2 Ruby:** `C2_Ruby/<Cell_ID>_c2_MSSR.tif`
- **ROI Set:** `ROI_5x/<Cell_ID>_roi_5x.zip`

### Filename Metadata Convention:
The prefix before the first underscore is interpreted as the `Acquisition_ID` (e.g., `516_19_c1_MSSR.tif`):
- `Acquisition_ID = 516`
- `Biological_replicate = 5` (First digit, ranging 1–6)
- `FOV = 16` (Remaining digits)
- `Cell_ID = 516_19`

---

## Analyses Retained & Mathematical Definitions

1. **ROI-Restricted Otsu Thresholding:** Computed independently for C1 and C2 channels within the supplied cell boundary.
2. **Binary Positive-Signal Masks:** Restricted strictly to the cell ROI.
3. **Binary Overlap Fractions:**
   - `C1_overlap_fraction` = overlap pixels / C1-positive pixels
   - `C2_overlap_fraction` = overlap pixels / C2-positive pixels
4. **Directed Nearest Inter-Channel Distance (NICD):** Restricted to **non-overlapping** source-positive pixels (C1 → nearest C2-positive pixel, C2 → nearest C1-positive pixel). Output per cell is the median distance in 5x MSSR pixels.
5. **Conditional Non-Overlap Proximity AUC:**
   - **Source:** Source-positive pixels that do NOT overlap the target.
   - **Background:** ROI pixels containing neither C1 nor C2 signal.
   - Both groups are sampled on the same Euclidean distance-to-target map.
   - `AUC` = P(D_source < D_background) + 0.5 × P(D_source = D_background)
   - **Interpretation:**
     - `AUC = 0.5`: Source-only pixels are no closer to the target than background.
     - `AUC > 0.5`: Source-only pixels tend to occupy positions nearer to the target.
     - `AUC < 0.5`: Source-only pixels tend to occupy positions farther from the target.

---

## Important Interpretation Guidelines
- Overlap is **not** synonymous with molecular binding.
- Non-overlap is **not** synonymous with unbound protein.
- NICD/AUC describe the image-derived spatial behavior of the non-overlapping fraction.
- MSSR pixels are spatially oversampled and represent **not** independent biological observations.
- AUC is a per-cell effect-size/spatial index, **not** a pixel-level significance test.
- No between-condition statistics are performed by this macro.
