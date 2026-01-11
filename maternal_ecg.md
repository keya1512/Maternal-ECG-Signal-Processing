# Maternal ECG task

## Signal generation

To generate the ECG signals, I first set up the electrodes, ensuring there are 32 abdominal channels and 2 reference leads.  
I set up a base subject for the ECG generation, using normal distribution to assign a heart rate (still close to reasonable values). I set up noise types (Muscular artifacts, baseline wander and electrode motion) to simulate common noise that can appear in ECG readings. Furthermore, I set up a loop to include SNR to add further noise to the ECG. 

## Visualisation in time domain and frequency domain

Visualisation in the time domain was done to check the shapes of the P, QRS and T waves. 

Visualisation in the frequency domain was done to identify noise components so that the bandpass filter could be appropriately set to minimise noise without affecting the ECG signal. 

## Bandpass filter 

A bandpass filter is based to attenuate lower frequencies which typically account for electrode motion and baseline wander, and high frequencies which typically account for muscle artifacts. 

## Example 1: SNR = 0 dB and 1 MA
**Time domain representation of the signal**

<img src="image.png" alt="Time domain representation of the signal" width="450" />


**Frequency domain representation of the signal**

<img src="image-1.png" alt="Frequency domain representation of the signal" width="450" />

After seeing the frequency and time domain representation of the ECG signal, I decided to implement a bandpass filter ranging from 0.5Hz to 50Hz. Typically, 0-0.5 Hz accounts for baseline wander. Furthermore, frequencies higher than 50Hz are typically due to muscle artifacts. 

**Frequency domain representation of the signal after the bandpass filter**

<img src="image-3.png" alt="Frequency domain representation of the signal after the bandpass filter" width="450" />

**Time domain representation of raw and bandpassed filtered signal**

<img src="image-4.png" alt="Time domain representation of raw and bandpassed filtered signal" width="450" />

After the bandpass filter, the P and S peaks had distinct spikes. Furthermore, the amplitude of the R peaks also reduced. 

**R peaks identified**

<img src="image-5.png" alt="R peaks identified" width="450" />

To quantitatively measure the improvement of the strength of the ecg signal, the bandpower ratio of the lower frequencies (noise) to the ecg frequencies was calculated:

Bandpower ratio before filter: 25.65

Bandpower ratio after filter: 1.492*10^3

## Example 2: SNR = 6 dB and 1 EM

**Time domain representation of the signal**

<img src="image-14.png" alt="Time domain representation of the signal" width="450" />

**Frequency domain representation of the signal**

<img src="image-13.png" alt="Frequency domain representation of the signal" width="450" />

After seeing the frequency and time domain representation of the ECG signal, I decided to implement a bandpass filter ranging from 0.5Hz to 50Hz. Typically, lower frequencies account for baseline wander and electrode motion. 

However, the challenge with electrode motion is that its noise frequencies can also often overlap with the ECG signal frequencies. While I initially tried doing a bandpass filter between 10-50Hz, it changed the morphology of the P wave of the ECG which could have led to a misdiagnosis. Instead, I reverted to the 0.5-50Hz bandpass filter and added a median filter. 

The median filter serves to remove noise like baseline wander and electrode motion, while preserving key features of the ECG. 

**Frequency domain representation of the signal after bandpass and median filter**

<img src="image-11.png" alt="Frequency domain representation of the signal after the bandpass filter" width="450" />

**Time domain representation of raw and filtered signals**

<img src="image-12.png" alt="Time domain representation of raw and bandpassed filtered signal" width="450" />

After the bandpass and median filters, the P and S peaks had distinct spikes. Furthermore, the amplitude of the R peaks also reduced. 

**R peaks identified**

<img src="image-10.png" alt="R peaks identified" width="450" />

To quantitatively measure the improvement of the strength of the ecg signal, the bandpower ratio of the lower frequencies (noise) to the ecg frequencies was calculated:

Bandpower ratio before: 7.5002

Bandpower ratio after filter: 9.2926