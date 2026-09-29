/*
 NICD_recursive_dataset_v0_7_3.ijm

 Recursive production macro for two-channel MSSR spatial analysis.

 PURPOSE
   Analyse an entire experiment from a top-level folder in one run.

 EXPECTED DATASET HIERARCHY
   <top level>/
     <Strain>/
       <Medium>/
         <Time>/
           C1_Clover/
           C2_Ruby/
           ROI_5x/

   A folder is treated as an analysable condition only when it contains
   ALL THREE required subfolders:
       C1_Clover
       C2_Ruby
       ROI_5x

   Other files and folders are ignored. The macro recurses through the
   directory tree until it finds analysable condition folders.

 EXPECTED FILE NAMING
   C1_Clover/<Cell_ID>_c1_MSSR.tif
   C2_Ruby/<Cell_ID>_c2_MSSR.tif
   ROI_5x/<Cell_ID>_roi_5x.zip

 FILENAME METADATA
   The part before the first underscore is interpreted as Acquisition_ID.

   For the current dataset:
       516_19_c1_MSSR.tif

       Acquisition_ID       = 516
       Biological_replicate = 5
       FOV                   = 16
       Cell_ID               = 516_19

   Current naming convention:
       first digit = biological replicate (1-6)
       following two digits = FOV within that biological replicate

 ANALYSES RETAINED
   1. ROI-restricted Otsu thresholding independently for C1 and C2.
   2. Binary positive-signal masks restricted to the supplied cell ROI.
   3. Binary overlap fractions:
        C1_overlap_fraction = overlap pixels / C1-positive pixels
        C2_overlap_fraction = overlap pixels / C2-positive pixels
   4. Directed nearest inter-channel distance (NICD), restricted to
      NON-OVERLAPPING source-positive pixels:
        C1 -> nearest C2-positive pixel
        C2 -> nearest C1-positive pixel
      Per-cell output = median distance in 5x MSSR pixels.
   5. Conditional non-overlap proximity AUC:
        Source = source-positive pixels that do NOT overlap target.
        Background = ROI pixels containing neither C1 nor C2.
        Both groups are sampled on the same Euclidean distance-to-target map.

        AUC = P(D_source < D_background)
              + 0.5 * P(D_source = D_background)

        AUC = 0.5 : source-only pixels are no closer to target than background
        AUC > 0.5 : source-only pixels tend to occupy positions nearer target
        AUC < 0.5 : source-only pixels tend to occupy positions farther from target

 IMPORTANT INTERPRETATION
   - Overlap is not synonymous with molecular binding.
   - Non-overlap is not synonymous with unbound protein.
   - NICD/AUC describe image-derived spatial behaviour of the non-overlapping fraction.
   - MSSR pixels are spatially oversampled and are not independent biological observations.
   - AUC is a per-cell effect-size/spatial index, not a pixel-level significance test.
   - No between-condition statistics are performed by this macro.

 CHANGES FROM v0.7.0
   - v0.7.3 fixes ImageJ's "Numeric return value expected" error caused by
     File.isDirectory(), which returns the string "1"/"0" rather than a number.
   - Recurses from one selected top-level experiment folder.
   - Automatically detects condition folders from C1_Clover/C2_Ruby/ROI_5x.
   - Reads C1, C2 and ROI files from their separate subfolders.
   - Writes one combined experiment-wide CSV.
   - Adds Strain, Medium, Time and Condition_path metadata.
   - Correctly separates Biological_replicate and FOV from the three-digit
     Acquisition_ID used in the current dataset.
   - QC output is optional and limited to the first N successful cells
     per biological replicate within each condition.
*/

requires("1.53");
saveSettings();
setOption("BlackBackground", true);
run("Set Measurements...", "area mean standard min max median redirect=None decimal=6");

if (nImages>0)
    exit("Please close all open image windows before running NICD recursive v0.7.3.");

// ============================================================================
// User inputs
// ============================================================================

rootDir = getDirectory("Choose TOP-LEVEL experiment folder");
outDir  = getDirectory("Choose output folder");

Dialog.create("NICD recursive dataset analysis v0.7.3");
Dialog.addString("Output dataset label:", "SpatialMetrics", 30);
Dialog.addCheckbox("Save limited QC masks and distance maps", false);
Dialog.addNumber("Successful QC cells to save per biological replicate and condition:", 3);
Dialog.show();

datasetLabel = Dialog.getString();
saveQC = Dialog.getCheckbox();
qcPerRep = round(Dialog.getNumber());

if (lengthOf(datasetLabel)==0)
    exit("Dataset label cannot be empty.");
if (qcPerRep < 0)
    exit("QC cells per biological replicate cannot be negative.");
if (!saveQC)
    qcPerRep = 0;

// Sanitize only for output filenames.
safeDataset = datasetLabel;
safeDataset = replace(safeDataset, " ", "_");
safeDataset = replace(safeDataset, "/", "_");
safeDataset = replace(safeDataset, "\\", "_");
safeDataset = replace(safeDataset, ":", "_");
safeDataset = replace(safeDataset, "*", "_");
safeDataset = replace(safeDataset, "?", "_");
safeDataset = replace(safeDataset, "\"", "_");
safeDataset = replace(safeDataset, "<", "_");
safeDataset = replace(safeDataset, ">", "_");
safeDataset = replace(safeDataset, "|", "_");
safeDataset = replace(safeDataset, ",", "_");

csvPath = outDir + "NICD_" + safeDataset + "_v0_7_3.csv";
logPath = outDir + "NICD_" + safeDataset + "_v0_7_3_log.txt";
qcRoot  = outDir + "QC_" + safeDataset + File.separator;

if (saveQC)
    File.makeDirectory(qcRoot);

header = "Strain,Medium,Time,Condition_path,"+
         "Biological_replicate,FOV,Acquisition_ID,Cell_ID,"+
         "C1_file,C2_file,ROI_file,Status,Error,"+
         "ROI_pixels,C1_Otsu_threshold,C2_Otsu_threshold,"+
         "C1_positive_px,C2_positive_px,Overlap_px,"+
         "C1_overlap_fraction,C2_overlap_fraction,"+
         "C1_nonoverlap_px,C2_nonoverlap_px,Background_px,"+
         "C1toC2_median_nonoverlap_px,C2toC1_median_nonoverlap_px,"+
         "C1toC2_proximity_AUC_nonoverlap,C2toC1_proximity_AUC_nonoverlap,"+
         "Macro_version\n";

File.saveString(header, csvPath);
File.saveString("NICD recursive dataset analysis v0.7.3\n", logPath);

print("=== NICD recursive dataset analysis v0.7.3 ===");
print("Dataset: " + datasetLabel);
print("Root folder: " + rootDir);
print("Output CSV: " + csvPath);

File.append("Dataset: "+datasetLabel+"\n", logPath);
File.append("Root folder: "+rootDir+"\n", logPath);
File.append("Output CSV: "+csvPath+"\n\n", logPath);

run("Clear Results");
setBatchMode(true);

// depth=0 at the selected top-level folder.
// strain/medium/time and condition path are filled during recursion.
totalOK = scanFolder(rootDir, 0, "", "", "", "",
                     qcRoot, saveQC, qcPerRep, csvPath, logPath);

setBatchMode(false);
roiManager("Reset");
run("Clear Results");
restoreSettings();

summary = "\nComplete. Total successful cells: "+totalOK+".\n"+
          "CSV: "+csvPath+"\n"+
          "Log: "+logPath+"\n";

print(summary);
File.append(summary, logPath);

showMessage("NICD recursive v0.7.3 complete",
    "Dataset: "+datasetLabel+
    "\nSuccessful cells: "+totalOK+
    "\n\nResults:\n"+csvPath);


// ============================================================================
// Recursive dataset traversal
// ============================================================================

function scanFolder(folder, depth, strain, medium, time, relPath,
                    qcRoot, saveQC, qcPerRep, csvPath, logPath) {

    // If this folder contains the three required data subfolders,
    // it is an analysable condition. Do not recurse into its channel folders.
    if (isConditionFolder(folder)) {

        // If the selected root itself is already a condition folder, the
        // hierarchy metadata cannot be inferred from descendants. Preserve a
        // clear condition label rather than inventing strain/medium/time.
        if (relPath=="")
            relPath = "(selected condition root)";

        return processConditionFolder(folder, strain, medium, time, relPath,
                                      qcRoot, saveQC, qcPerRep, csvPath, logPath);
    }

    list = getFileList(folder);
    list = Array.sort(list);
    total = 0;

    for (i=0; i<list.length; i++) {
        name = list[i];
        childPath = folder + name;

        if (File.isDirectory(childPath)!="1")
            continue;

        childName = stripTrailingSeparator(name);

        // These names are data-bearing channel/ROI folders and should only
        // occur under an analysable condition folder. Ignore them if found
        // unexpectedly elsewhere.
        if (childName=="C1_Clover" || childName=="C2_Ruby" || childName=="ROI_5x")
            continue;

        newStrain = strain;
        newMedium = medium;
        newTime = time;

        if (depth==0)
            newStrain = childName;
        else if (depth==1)
            newMedium = childName;
        else if (depth==2)
            newTime = childName;

        if (relPath=="")
            newRel = childName;
        else
            newRel = relPath + " / " + childName;

        // IJM can reject a compound += assignment when the right-hand side
        // is a recursive user-defined function call. Store the return value first.
        childTotal = scanFolder(childPath, depth+1,
                                newStrain, newMedium, newTime, newRel,
                                qcRoot, saveQC, qcPerRep, csvPath, logPath);
        total = total + childTotal;
    }

    return total;
}


function isConditionFolder(folder) {
    c1Dir  = folder + "C1_Clover" + File.separator;
    c2Dir  = folder + "C2_Ruby" + File.separator;
    roiDir = folder + "ROI_5x" + File.separator;

    // ImageJ's File.isDirectory() returns the STRING "1" or "0".
    // Convert the three tests explicitly to a numeric 0/1 before returning
    // from this user-defined function. Returning File.isDirectory() directly
    // causes "Numeric return value expected" when this function is used in if().
    isCond = 0;
    if (File.isDirectory(c1Dir)=="1" &&
        File.isDirectory(c2Dir)=="1" &&
        File.isDirectory(roiDir)=="1")
        isCond = 1;

    return isCond;
}


// ============================================================================
// Process one strain / medium / time condition
// ============================================================================

function processConditionFolder(folder, strain, medium, time, conditionPath,
                                qcRoot, saveQC, qcPerRep, csvPath, logPath) {

    c1Dir  = folder + "C1_Clover" + File.separator;
    c2Dir  = folder + "C2_Ruby" + File.separator;
    roiDir = folder + "ROI_5x" + File.separator;

    // CSV-safe hierarchy metadata.
    strainCSV = replace(strain, ",", ";");
    mediumCSV = replace(medium, ",", ";");
    timeCSV = replace(time, ",", ";");
    conditionCSV = replace(conditionPath, ",", ";");

    print("\n--- Condition: " + conditionPath + " ---");
    File.append("\n--- Condition: "+conditionPath+" ---\n", logPath);

    list = getFileList(c1Dir);
    list = Array.sort(list);

    success = 0;
    candidates = 0;

    // Sorted acquisition IDs group biological replicates together because
    // the first digit encodes replicate in this dataset.
    lastRep = "__NONE__";
    qcSavedThisRep = 0;
    repCandidates = 0;
    repSuccess = 0;

    // Flat, filesystem-safe QC directory for this condition.
    qcConditionDir = qcRoot;
    if (saveQC) {
        qcLabel = conditionPath;
        qcLabel = replace(qcLabel, " / ", "__");
        qcLabel = replace(qcLabel, " ", "_");
        qcLabel = replace(qcLabel, "/", "_");
        qcLabel = replace(qcLabel, "\\", "_");
        qcLabel = replace(qcLabel, ":", "_");
        qcLabel = replace(qcLabel, "*", "_");
        qcLabel = replace(qcLabel, "?", "_");
        qcLabel = replace(qcLabel, "\"", "_");
        qcLabel = replace(qcLabel, "<", "_");
        qcLabel = replace(qcLabel, ">", "_");
        qcLabel = replace(qcLabel, "|", "_");
        qcLabel = replace(qcLabel, ",", "_");

        qcConditionDir = qcRoot + qcLabel + File.separator;
        File.makeDirectory(qcConditionDir);
    }

    for (ii=0; ii<list.length; ii++) {
        fname = list[ii];

        if (!endsWith(toLowerCase(fname), "_c1_mssr.tif"))
            continue;

        candidates++;

        base = substring(fname, 0, lengthOf(fname)-lengthOf("_c1_MSSR.tif"));

        us = indexOf(base, "_");

        if (us>=0)
            acquisitionID = substring(base, 0, us);
        else
            acquisitionID = base;

        // Current naming convention: first digit = biological replicate,
        // remaining digits in Acquisition_ID = FOV.
        if (lengthOf(acquisitionID)>=2) {
            bioRep = substring(acquisitionID, 0, 1);
            fov = substring(acquisitionID, 1);
        } else {
            bioRep = acquisitionID;
            fov = "";
        }

        if (bioRep != lastRep) {
            if (lastRep != "__NONE__") {
                rmsg = conditionPath+" | Biological replicate "+lastRep+
                       ": candidates="+repCandidates+
                       "; successful="+repSuccess+
                       "; QC_saved="+qcSavedThisRep+".\n";
                print(rmsg);
                File.append(rmsg, logPath);
            }

            lastRep = bioRep;
            qcSavedThisRep = 0;
            repCandidates = 0;
            repSuccess = 0;
        }

        repCandidates++;

        c1Path = c1Dir + fname;
        c2File = base + "_c2_MSSR.tif";
        roiFile = base + "_roi_5x.zip";
        c2Path = c2Dir + c2File;
        roiPath = roiDir + roiFile;

        if (!File.exists(c2Path) || !File.exists(roiPath)) {
            err = "Missing matching ";

            if (!File.exists(c2Path) && !File.exists(roiPath))
                err += "C2 and ROI";
            else if (!File.exists(c2Path))
                err += "C2";
            else
                err += "ROI";

            writeErrorRow(csvPath,
                          strainCSV, mediumCSV, timeCSV, conditionCSV,
                          bioRep, fov, acquisitionID, base,
                          fname, c2File, roiFile, err);

            msg = conditionPath+" | "+base+" | SKIP: "+err+"\n";
            print(msg);
            File.append(msg, logPath);
            continue;
        }

        saveThisQC = saveQC && qcSavedThisRep < qcPerRep;
        qcDir = qcConditionDir;

        if (saveThisQC) {
            qcDir = qcConditionDir + "Replicate_" + bioRep + File.separator;
            File.makeDirectory(qcDir);
        }

        ok = processOneCell(
            c1Path, c2Path, roiPath,
            fname, c2File, roiFile,
            base, bioRep, fov, acquisitionID,
            strainCSV, mediumCSV, timeCSV, conditionCSV,
            conditionPath,
            qcDir, saveThisQC,
            csvPath, logPath
        );

        if (ok) {
            success++;
            repSuccess++;

            if (saveThisQC)
                qcSavedThisRep++;
        }

        showProgress(ii+1, list.length);
    }

    if (lastRep != "__NONE__") {
        rmsg = conditionPath+" | Biological replicate "+lastRep+
               ": candidates="+repCandidates+
               "; successful="+repSuccess+
               "; QC_saved="+qcSavedThisRep+".\n";
        print(rmsg);
        File.append(rmsg, logPath);
    }

    msg = conditionPath+": found "+candidates+
          " C1 candidates; successfully processed "+success+".\n";
    print(msg);
    File.append(msg, logPath);

    return success;
}


// ============================================================================
// One-cell processing
// ============================================================================

function processOneCell(c1Path, c2Path, roiPath,
                        c1File, c2File, roiFile,
                        base, bioRep, fov, acquisitionID,
                        strainCSV, mediumCSV, timeCSV, conditionCSV,
                        conditionPath,
                        qcDir, saveThisQC,
                        csvPath, logPath) {

    cleanupAll();
    roiManager("Reset");
    run("Clear Results");

    // ---- Open C1/C2 ----

    open(c1Path);
    c1Title = getTitle();
    getDimensions(w1, h1, ch1, z1, t1);

    open(c2Path);
    c2Title = getTitle();
    getDimensions(w2, h2, ch2, z2, t2);

    if (w1!=w2 || h1!=h2) {
        err = "C1/C2 dimension mismatch";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    // ---- Load supplied 5x ROI ----

    roiManager("Open", roiPath);
    nroi = roiManager("count");

    if (nroi!=1) {
        err = "ROI ZIP contains "+nroi+" ROIs; expected exactly 1";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    selectWindow(c1Title);
    roiManager("Select", 0);
    getRawStatistics(roiPixels, tmpMean, tmpMin, tmpMax);

    if (roiPixels<=0) {
        err = "ROI has zero pixels";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    // ---- ROI-restricted Otsu thresholds ----

    selectWindow(c1Title);
    roiManager("Select", 0);
    c1Thr = roiOtsu256();

    selectWindow(c2Title);
    roiManager("Select", 0);
    c2Thr = roiOtsu256();

    if (c1Thr!=c1Thr || c2Thr!=c2Thr) {
        err = "Cannot calculate Otsu threshold (ROI has no intensity range)";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    // ---- Binary channel masks restricted to the cell ROI ----

    c1Mask = base + "_C1_mask";
    c2Mask = base + "_C2_mask";

    makeROIMask(c1Title, c1Mask, c1Thr);
    makeROIMask(c2Title, c2Mask, c2Thr);

    selectWindow(c1Mask);
    getDimensions(mw1, mh1, mc1, mz1, mt1);

    selectWindow(c2Mask);
    getDimensions(mw2, mh2, mc2, mz2, mt2);

    if (mw1!=w1 || mh1!=h1 || mw2!=w2 || mh2!=h2) {
        err = "Mask geometry mismatch";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    nC1 = countWhite(c1Mask);
    nC2 = countWhite(c2Mask);

    if (nC1==0 || nC2==0) {
        err = "Empty threshold mask: C1="+nC1+"; C2="+nC2;

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    // Force 32-bit Euclidean Distance Map output.
    selectWindow(c1Mask);
    run("Options...", "iterations=1 count=1 black edm=32-bit do=Nothing");

    // ---- Overlap and non-overlap masks ----

    overlapTitle = base + "_overlap";
    imageCalculator("AND create", c1Mask, c2Mask);
    rename(overlapTitle);
    nOverlap = countWhite(overlapTitle);

    c1NonTitle = base + "_C1_nonoverlap";
    imageCalculator("Subtract create", c1Mask, c2Mask);
    rename(c1NonTitle);
    nC1Non = countWhite(c1NonTitle);

    c2NonTitle = base + "_C2_nonoverlap";
    imageCalculator("Subtract create", c2Mask, c1Mask);
    rename(c2NonTitle);
    nC2Non = countWhite(c2NonTitle);

    c1OverlapFrac = nOverlap/nC1;
    c2OverlapFrac = nOverlap/nC2;

    // ---- ROI background = neither C1 nor C2 ----

    roiMaskTitle = base + "_ROI_mask";
    makeCellROIMask(roiMaskTitle, w1, h1);

    unionTitle = base + "_union";
    imageCalculator("OR create", c1Mask, c2Mask);
    rename(unionTitle);

    bgTitle = base + "_background";
    imageCalculator("Subtract create", roiMaskTitle, unionTitle);
    rename(bgTitle);
    nBg = countWhite(bgTitle);

    // ---- Directed Euclidean distance maps ----

    d12Title = base + "_D_C1_to_C2_px";
    d21Title = base + "_D_C2_to_C1_px";

    makeDistanceToTarget(c2Mask, d12Title);
    makeDistanceToTarget(c1Mask, d21Title);

    if (!isOpen(d12Title) || !isOpen(d21Title)) {
        err = "32-bit EDM image was not created; check Process > Binary > Options";

        writeErrorRow(csvPath,
                      strainCSV, mediumCSV, timeCSV, conditionCSV,
                      bioRep, fov, acquisitionID, base,
                      c1File, c2File, roiFile, err);

        logCell(logPath, conditionPath, base, "FAIL", err);
        cleanupAll();
        return 0;
    }

    // ---- Median NICD of NON-OVERLAPPING source-positive pixels ----

    if (nC1Non>0) {
        c1NonStats = measureOnMask(d12Title, c1NonTitle);
        c1NonMedian = c1NonStats[1];
    } else {
        c1NonMedian = NaN;
    }

    if (nC2Non>0) {
        c2NonStats = measureOnMask(d21Title, c2NonTitle);
        c2NonMedian = c2NonStats[1];
    } else {
        c2NonMedian = NaN;
    }

    // ---- Conditional non-overlap proximity AUC ----

    if (nC1Non>0 && nBg>0) {
        maxD12 = maxWithinCellROI(d12Title);
        auc12 = proximityAUCFromMasks(d12Title, c1NonTitle, bgTitle, maxD12);
    } else {
        auc12 = NaN;
    }

    if (nC2Non>0 && nBg>0) {
        maxD21 = maxWithinCellROI(d21Title);
        auc21 = proximityAUCFromMasks(d21Title, c2NonTitle, bgTitle, maxD21);
    } else {
        auc21 = NaN;
    }

    // ---- Optional QC output ----

    if (saveThisQC) {
        selectWindow(c1Mask);
        saveAs("Tiff", qcDir + base + "_C1_mask.tif");

        selectWindow(c2Mask);
        saveAs("Tiff", qcDir + base + "_C2_mask.tif");

        selectWindow(overlapTitle);
        saveAs("Tiff", qcDir + base + "_overlap.tif");

        selectWindow(bgTitle);
        saveAs("Tiff", qcDir + base + "_background.tif");

        selectWindow(d12Title);
        saveAs("Tiff", qcDir + base + "_D_C1_to_C2_px.tif");

        selectWindow(d21Title);
        saveAs("Tiff", qcDir + base + "_D_C2_to_C1_px.tif");
    }

    // ---- Per-cell CSV row ----

    row = strainCSV+","+mediumCSV+","+timeCSV+","+conditionCSV+","+
          bioRep+","+fov+","+acquisitionID+","+base+","+
          c1File+","+c2File+","+roiFile+",OK,,"+
          d2s(roiPixels,6)+","+d2s(c1Thr,6)+","+d2s(c2Thr,6)+","+
          d2s(nC1,0)+","+d2s(nC2,0)+","+d2s(nOverlap,0)+","+
          d2s(c1OverlapFrac,6)+","+d2s(c2OverlapFrac,6)+","+
          d2s(nC1Non,0)+","+d2s(nC2Non,0)+","+d2s(nBg,0)+","+
          d2s(c1NonMedian,6)+","+d2s(c2NonMedian,6)+","+
          d2s(auc12,6)+","+d2s(auc21,6)+",0.7.3\n";

    File.append(row, csvPath);

    msg = "OK | overlap C1="+d2s(c1OverlapFrac,3)+
          " C2="+d2s(c2OverlapFrac,3)+
          " | C1->C2 medNon="+d2s(c1NonMedian,3)+
          " AUC="+d2s(auc12,3)+
          " | C2->C1 medNon="+d2s(c2NonMedian,3)+
          " AUC="+d2s(auc21,3);

    logCell(logPath, conditionPath, base, "OK", msg);

    cleanupAll();
    return 1;
}


// ============================================================================
// Helper functions
// ============================================================================

function stripTrailingSeparator(name) {
    while (endsWith(name, "/") || endsWith(name, "\\"))
        name = substring(name, 0, lengthOf(name)-1);

    return name;
}


function roiOtsu256() {
    getStatistics(a, m, vmin, vmax, sd, hist);

    if (vmax<=vmin)
        return NaN;

    total = 0;
    sumAll = 0;

    for (i=0; i<256; i++) {
        total += hist[i];
        sumAll += i*hist[i];
    }

    weightB = 0;
    sumB = 0;
    maxBetween = -1;
    bestBin = 0;

    for (i=0; i<256; i++) {
        weightB += hist[i];

        if (weightB==0)
            continue;

        weightF = total-weightB;

        if (weightF==0)
            break;

        sumB += i*hist[i];
        meanB = sumB/weightB;
        meanF = (sumAll-sumB)/weightF;

        between = weightB*weightF*(meanB-meanF)*(meanB-meanF);

        if (between>maxBetween) {
            maxBetween = between;
            bestBin = i;
        }
    }

    binWidth = (vmax-vmin)/256.0;
    return vmin+(bestBin+0.5)*binWidth;
}


function makeROIMask(sourceTitle, maskTitle, thr) {
    selectWindow(sourceTitle);
    run("Select None");
    run("Duplicate...", "title=["+maskTitle+"]");

    setThreshold(thr, 1e30, "raw");
    run("Convert to Mask");

    roiManager("Select", 0);
    setBackgroundColor(0,0,0);
    run("Clear Outside");

    resetThreshold();
}


function makeCellROIMask(maskTitle, w, h) {
    newImage(maskTitle, "8-bit black", w, h, 1);

    roiManager("Select", 0);
    setForegroundColor(255,255,255);
    run("Fill");
    run("Select None");
}


function countWhite(title) {
    selectWindow(title);
    getHistogram(v, c, 256);
    return c[255];
}


function makeDistanceToTarget(targetMaskTitle, distanceTitle) {
    tempTitle = distanceTitle + "_binaryTemp";

    selectWindow(targetMaskTitle);
    run("Select None");
    run("Duplicate...", "title=["+tempTitle+"]");
    run("Invert");
    run("Distance Map");

    edmTitle = getTitle();

    if (edmTitle==tempTitle) {
        rename(distanceTitle+"_ERROR_NOT_32BIT");
        return;
    }

    selectWindow(tempTitle);
    close();

    selectWindow(edmTitle);
    rename(distanceTitle);
}


// Returns [mean, median]; v0.7.3 uses only the median.
function measureOnMask(distanceTitle, samplingMaskTitle) {
    if (!isOpen(distanceTitle))
        return newArray(NaN, NaN);

    selectWindow(samplingMaskTitle);
    setThreshold(255,255,"raw");
    run("Create Selection");
    resetThreshold();

    if (selectionType()==-1)
        return newArray(NaN, NaN);

    roiManager("Add");
    idx = roiManager("count")-1;

    selectWindow(distanceTitle);
    roiManager("Select", idx);
    run("Measure");

    r = nResults-1;
    meanVal = getResult("Mean", r);
    medianVal = getResult("Median", r);

    run("Clear Results");

    roiManager("Select", idx);
    roiManager("Delete");

    return newArray(meanVal, medianVal);
}


function maxWithinCellROI(distanceTitle) {
    selectWindow(distanceTitle);
    roiManager("Select", 0);
    getStatistics(a, m, mn, mx);
    return mx;
}


function histogramOnMask(distanceTitle, samplingMaskTitle, nBins, hMin, hMax) {
    selectWindow(samplingMaskTitle);
    setThreshold(255,255,"raw");
    run("Create Selection");
    resetThreshold();

    roiManager("Add");
    idx = roiManager("count")-1;

    selectWindow(distanceTitle);
    roiManager("Select", idx);
    getHistogram(vals, counts, nBins, hMin, hMax);

    roiManager("Select", idx);
    roiManager("Delete");

    return counts;
}


function proximityAUCFromMasks(distanceTitle, sourceMaskTitle, backgroundMaskTitle, maxDist) {
    if (maxDist<=0)
        return NaN;

    // Retained unchanged from the validated v0.5/v0.6 implementation.
    nBins = 4096;
    hMax = maxDist + 0.000001;

    src = histogramOnMask(distanceTitle, sourceMaskTitle, nBins, 0, hMax);
    bg  = histogramOnMask(distanceTitle, backgroundMaskTitle, nBins, 0, hMax);

    nSrc = 0;
    nBg = 0;

    for (i=0; i<nBins; i++) {
        nSrc += src[i];
        nBg += bg[i];
    }

    if (nSrc<=0 || nBg<=0)
        return NaN;

    bgGreater = nBg;
    favorable = 0;

    for (i=0; i<nBins; i++) {
        bgGreater -= bg[i];
        favorable += src[i]*(bgGreater + 0.5*bg[i]);
    }

    return favorable/(nSrc*nBg);
}


function writeErrorRow(csvPath,
                       strainCSV, mediumCSV, timeCSV, conditionCSV,
                       bioRep, fov, acquisitionID, base,
                       c1File, c2File, roiFile, err) {

    err = replace(err, ",", ";");

    row = strainCSV+","+mediumCSV+","+timeCSV+","+conditionCSV+","+
          bioRep+","+fov+","+acquisitionID+","+base+","+
          c1File+","+c2File+","+roiFile+",FAIL,"+err;

    // 15 quantitative fields occur after Error and before Macro_version.
    // Sixteen commas are required: 15 blank fields plus separator before version.
    for (k=0; k<16; k++)
        row += ",";

    row += "0.7.3\n";
    File.append(row, csvPath);
}


function logCell(logPath, conditionPath, base, status, msg) {
    line = conditionPath+" | "+base+" | "+status+" | "+msg+"\n";
    print(line);
    File.append(line, logPath);
}


function cleanupAll() {
    if (nImages>0)
        close("*");

    roiManager("Reset");
    run("Clear Results");
}
