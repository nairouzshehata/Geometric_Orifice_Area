# Geometric_Orifice_Area
MATLAB code to detect the geometric orifice area, record it over time for videos captured using high speed cameras.
Please refer to [this document]([https://github.com/nairouzshehata/Geometric_Orifice_Area/edit/main/README.md](https://github.com/nairouzshehata/Geometric_Orifice_Area/blob/main/GOA%20Matlab%20user%20protocol.pdf) to setup the camera and for detailed steps on running the code and tuning the hyperparameters.


# Step 1) Run HCCV_GOA_Code1.m #
converts RGB to grayscale and prompts user to: 
* Select mp4 video to be processed
* Crop background by dragging crop box, double click then hit Enter
Video will be saved as <original video name>_crop2.avi    

# Step 2) Run HCCV_GOA_Code2.m #
This does all the analyses, prompts user to:
* Select the xxx_crop2.avi video saved from step 1 
* Adjust circle around valve, double click then hit Enter
* Sketch cusp1, double click then hit Enter (same for cusp2 and cusp3).   

Please note: the video needs to start when the valve is closed. There are hyper-parameters at the beginning default values are commented preceded by "def".

# Dependencies:
* 'MATLAB'	'9.11'
* 'Image Processing Toolbox'	'11.4'

# Cite
If using this code please cite our paper 



