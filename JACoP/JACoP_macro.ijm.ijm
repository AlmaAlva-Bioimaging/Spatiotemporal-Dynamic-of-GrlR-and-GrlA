// --- CONFIGURATION ---
inputDir = "16bit_merged_images";
roiDir = "5x_ROIs";
saveDir = "output";

File.makeDirectory(saveDir);
list = getFileList(inputDir);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) {
        // 1. Open the image stack
        open(inputDir + list[i]);
        
        // 2. Build the corresponding ROI filename
        baseName = replace(list[i], "_MERGED_16BIT.tif", "_roi_5x.zip");
        
        // 3. Open the ROI set (to keep it active in the current session)
        if (File.exists(roiDir + baseName)) {
            roiManager("Reset");
            open(roiDir + baseName);
        }
        
        // 4. Run BIOP JACoP (without 'crop_rois' to prevent selection errors)
        run("BIOP JACoP", "channel_a=1 channel_b=2 threshold_for_channel_a=Otsu threshold_for_channel_b=Otsu manual_threshold_a=0 manual_threshold_b=0 get_pearsons get_manders get_overlap costes_block_size=5 costes_number_of_shuffling=100 output_mode=[Save results] save_directory=[" + saveDir + "]");
        
        // 5. Clean up workspace
        run("Close All");
        roiManager("Reset");
    }
}
print("Colocalization batch processing completed.");