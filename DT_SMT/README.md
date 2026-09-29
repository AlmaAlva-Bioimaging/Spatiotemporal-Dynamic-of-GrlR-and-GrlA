# SMT Distance Transform Analysis Pipeline

This repository module contains the pipeline designed to integrate single-molecule tracking (SMT) data with Euclidean Distance Transform (EDT) analysis in *Escherichia coli*. 

## General Description
The workflow processes molecular localizations obtained from SMT experiments—acquired following the **SMTracker 2.0** pipeline ([https://academic.oup.com/nar/article/49/19/e112/6355882](https://academic.oup.com/nar/article/49/19/e112/6355882))—and links them spatially with cell geometry defined by Oufti meshes (https://oufti.org/) and u-track (https://github.com/DanuserLab/u-track) results. This allows for rigorous quantification of radial distribution and proximity to the cell membrane across distinct dynamical states.

---

## Script Breakdown

### 1. Trajectory classification and DT Analysis
This script bridges cell mesh geometries with single-molecule trajectories.
- **Trajectory Loading & Filtering:** Parses MATLAB `.mat` files from u-track (`tracksFinal`) and filters trajectories based on temporal length and confinement criteria.
- **Dynamic State Classification:** Categorizes individual molecule trajectories into **Static**, **Transient**, or **Mobile** states using sliding-window displacement analysis and binding radii (`Adjust accordingly to the localization error`).
- **Cell-Boundary Association:** Uses vectorized point-in-polygon tests (`matplotlib.path.Path`) combined with Oufti cell contours to isolate tracks strictly residing inside individual cells (`MIN_INSIDE_RATIO`).
- **Normalized Distance Mapping:** Computes distance transforms from the cell perimeter to the center, scaling positions uniformly for population-level overlays and exporting metrics into structured Excel summaries and JSON metadata logs.

### 2. Statistical & Population Comparison Script
Performs robust statistical analyses across multiple experimental timepoints (e.g., 4h, 6h, 8h).
- **Proportion Analysis:** Evaluates shifts in dynamic state distributions using contingency tables and Chi-square tests.
- **Distribution Modeling:** Computes Kernel Density Estimations (KDE) for membrane-distance profiles using a synchronized global Y-axis scale for direct visual comparison.
- **Rigorous Hypothesis Testing & Effect Sizes:** Executes non-parametric and parametric evaluations combining Kolmogorov-Smirnov tests, Mann-Whitney U tests, Wasserstein distances, Cohen's d, and Cliff's Delta to quantify population differences.
- **Multi-Format Exports:** Generates publication-grade SVG comparison plots and a consolidated `Statistical_Comparisons_Summary.xlsx` report.

---

## Expected Input Directory Structure
```text
Strain/
├── Media/
│   ├── cell_meshes/
│   │   ├── series_01.mat
│   │   └── ...
│   └── tif/
│       ├── series_01/
│       │   └── TrackingPackage/
│       │       └── tracks/
│       │           └── Channel_1_tracking_result.mat
│       └── ...
