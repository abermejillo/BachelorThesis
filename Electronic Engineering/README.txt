This folder contains the code necessary for characterizing magnetic fields 
with the system designed and constructed in the bachelor thesis. That is done 
through "Solenoid_characterization.ipynb". 

First it is necessary to upload to the arduino one of the codes in the Arduino folder. 
"mlx90395" is the original code provided by the company. 

"mlx_innermedia" is the file used in the project,it performs the mean of 100 measurements 
in order to not collapse the USB.

The measured magnetic fields are not corrected according to the characterization performed in this project. A post-procesing is needed. 
For the module simply perform this operation: (1/1.2411)*(B-0.01)

Dipole and magnetic_profile contain codes for plotting acquired data. And the corresponding data files.
