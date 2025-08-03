# Oscilloscope Scripts
The scripts in this folder are created to analyze the oscilloscope data obtained from the ETL/EOM-DUE circuit. Each script was designed for a specific section of the design process. Instead of trying to make a large script with user-prompts and UI, I divided the scripts into individual segments. The purpose of each segment is described below:

## OscopeMScanAnalysis.m
This script was designed to take recordings of waveforms that are sent directly from the MScan software. While the laser is 'on,' MScan sends signals to a 302RM ConOptics Amplifier. The waveform of these signals (specifically the magnitude) chnages as the laser intensity [%] increases. This script was designed to analyze multiple .CSV files within a single folder that come from the oscilloscope.
- **Inputs**: A single folder of .CSV files. No special naming convention needed, raw title from oscilloscope is preferable. Record one waveform to one .CSV and save to a folder. When run, the script will ask for this folder only.
- **Outputs**: Several graphs to describe the waveform and specifically its amplitidue. One tiledlayout() of histograms for each waveform to determine Low Voltage and High Voltage. A final graph that shows a concatenated histogram, aligned single peaks for each waveform, and a graph showing the ~linear voltage increase with respect to laser inpt intensity. Finally, a .txt file is created for the Low and High Voltages.

## OscopeTxtConcatentation.m
This script was a sanity check to confirm that multiple oscilloscope readings for the same range of laser input intensities produced a linear relationship. The goal was to concatenate the .txt results for multiple oscilloscope recording sessions into a single graph.
- **Inputs**: A single folder of the .txt files containing the Low Voltage and High Voltage.
- **Outputs**: Graphs depicting the linear relationship between voltage and laser input intensity.

## OscopeCircuitAnalysis_3CH.m
This script is designed to validate the values that the Arduino Due is outputing in response to a simulated MScan input signal. The Arduino circuit has three associated signals that are active: Input TTL pulse from simulated MScan software (0-5V), Output TTL pulse from Arduino Due to ETL (0-3.3V), Output analog pulse from Arduino Due to EOM (0-1.5V). The oscilloscpe can record each of these waveforms simultaneously and create a file continain a single .CSV file for each waveform and a snapshot of the oscilloscope's display. This script analyzes each of these files to determine the 'Time Lag' between signals and the magnitude of the steps for the analog pulse.
This script is specifically designed for three .CSV inputs {Input Signal, ETL Signal, EOM Signal}.
- **Inputs**: A single folder produced from the oscilloscope's 'Save All' function. When three waveforms are active.
- **Outputs**: Graphs depicting the raw signals, overlayed waveforms with an associated cross-correlation, graph of analog pulse with step heights identified. 

## OscopeCircuitAnalysis_4CH.m
This script is similar to 'OscopeCircuitAnalysis_3CH.m' but is designed to work for the circuit after being integrated with MScan rather than having simulated input signals. The Arduino circuit has four associated signals: Input analog pulse from MScan software (0-1.2V), thresholed analog signal via comparator (0 or 3.3V based on thresholed), Output TTL pulse from Arduino Giga to ETL (0-3.3V), Output analog pulse from Arduino Giga to EOM (0-1.5V). The oscilloscope records these four waveforms simultaneously to create a folder with a single .CSV for each waveform snapshot. This script determines the 'Time Lag' between signals and the magnitude of the steps for the analog pulse.
This script is specifically designed for four .CSV inputs {Input Signal, Comparator Modulated Signal, ETL Signal, EOM Signal}.
- **Inputs**: A single folder produced from the oscilloscope's 'Save All' function. When three waveforms are active.
- **Outputs**: Graphs depicting the raw signals, overlayed waveforms with an associated cross-correlation, graph of analog pulse with step heights identified. 

## UserDefined Peaks.m
This script is designed to be used for cross correlation analysis. The cross correlation method requires specific ROIs to determine the time lag between two pulses. This means that individual pulse regions have to be identified some of the oscilloscope analyses. Currently, this function works well with one notable exception. For larger data sets or data recorded over a longer time period, the function has a tendency to crash while adjusting x-limits for ROI. MatLab restart is necessary. 