# **FECGSyn Toolbox Documentation**
### Global set up
|Function | Meaning | When is it used? |
|---------| --------- | ---------------- |
|function FECGSYNDB(path, debug) | setting path and debug | path --> where to save .mat outputs <br><br> debug --> how many plots generated|
|paramorig|global simulation parameter|used for the master template|
|.fs|sampling frequency|setting sampling frequency|
|.n|number of samples|setting number of samples|

### Setting up electrode geometry and channel set up
|Function | Example code | Meaning |
|---------| --------- | ---------------- |
|angular layout|x = pi/12*[3 4 5 6 7 8 9 10]' - pi/2;|This code is setting up 8 equally spaced electrodes around the abdomen (15 deg apart). The subtraction by pi/2 rotates the whole ring so that the first electrode starts at the side of the body instead of the front|
|fixed vertical position|y = 0.5 * ones(8,1);|All 8 electrodes sit at the same height on the torso|
|replicating rings vertically|xy = repmat([x y], 4, 1);|4 horizontal rings and 8 electrodes per ring|
|Adding depth(z)|z = repmat([-.1 -.2 -.3 -.4], 8, 1); <br><br>z = reshape(z,32,1);|assigned four different z values, creates variation in mixing weights|
|Final abdominal electrode matrix|abdmleads = [xy z];|32x3 matrix, each row = [angle, height, depth]|
|Reference leads|refs = [<br>-pi/4        0.5  0.4;</br><br>(5/6-.5)*pi  0.5  0.4</br>];|2 extra electrodes placed at fixed angles, same height as abdonimal leads, act as reference electrodes, stabilizers for potential differences|
|Full electrode position matrix|paramorig.elpos = [abdmleads; refs];|34x3, first 32 rows are abdominal channels and last 2 rows are references|

### Setting up base subjects
First set up a for loop for the number of subjects
|Function | Example code | Meaning |
|---------| --------- | ---------------- |
|close all|close all|debug point, prevents MATLAB from accumulating multiple open figure windows|
|paramst|paramst = paramorig|start each subject from the same global setup, then modify subject-specific knobs|
|paramst.fhr|paramst.fhr = 135 + 25*randn|samples the fetal heart rate from a normal dist, where mean = 135, s.d. = 25. randn gives the standard normal. This is because a dataset with identical fetal HR is too "clean" and algorithsm might overfit one rhythm. Varying fetal HR creates inter-subject variability.|
|paramst.mhr|paramst.mhr = 80 + 20*randn|same normal dist, maternal ECG is usually stronger and dominates abdominal mixture. If maternal HR changes between subjects, it makes extraction harder in a more realistic way.|

Used to run lots of scenarios (noise levels, movement, twins, contractions) around that same subject. 

### Stationary baseline generation (no accelerations)
No acceleration is no heart rate modulation over time
<br>This means that the RR intervals are approx constant</br>
Beat times occur at regular spacing
|Function | Example code | Meaning |
|---------| --------- | ---------------- |
|paramst.mtypeacc|paramst.mtypeacc = "nsr"|mtypeacc = maternal type of acceleration, nsr means no acceleration profile is applied. |
|paramst.ftypeacc|paramst.ftypeacc = {"nsr}|This is in a cell array because it can support multiple fetuses|
|paramst.SNRfm|paramst.SNRfm = -9 + 2*randn;|chooses the fetal vs maternal signal strength ratio. Negative values means that the fetal is weaker than maternal|
|Generate the simulated mixture|out = run_ecg_generator(paramst, debug)|generates a maternal and fetal ECG source (VCG), elpos to compute how each source projects into each electrode channel, mixes them into abdominal channels|
|Plotting|plotmix(out)|To plot random channels|
|Compress/clean output|out = clean_compress(out)|removes redundant fields, cast arrays to smaller types, strip debug-only intermediate signals, standardize formatting|
|Freeze the generator's resolved parameters|paramst = out.param|keep internal defaults made by run_ecg_generator|
|clean up memory|clear out|prevents MATLAB from holding onto a huge struct|

### Noise sweep loop
Varying noise, repeat a few times at each SNR level, because noise isn't deterministic
Set up loop for choosing noise levels (e.g. for SNRmn = 0:3:12)
|Function | Example code | Meaning |
|---------| --------- | ---------------- |
|Subject's frozen baseline parameters|param = paramst;|includes the resolved parameters the generator used|
|Set maternal-to-noise SNR|param.SNRmn = SNRmn|assigns the current noise level|
|param.ntype|param.ntype = {'MA', 'MA'}|list of noise sources, number of artifacts (i.e. here its 2 muscular artifacts)|
|Muscular Artifact|MA|EMG activity from abdominal muscles, movement, uterine activity|
|Baseline Wander|BW|Slow drift due to respiration, electrode impedance changes, posture shifts|
|Electrode Motion|EM|Sudden electrode shifts, cable tugging, skin-electrode interface changes|
|Time-modulation/Scaling function applied to noise source|param.noise_fct = {1 + 0.5*randn, 1 + 0.5*randn};|how the noise evolves in time|

# General MATLAB Documentation

|Function | Example code | Meaning |
|---------| --------- | ---------------- |
|nargin|nargin < 3|number of arguments in (a function)|

## Conceptual information
### Electrode orientation
FECGSYN assumes:
<br>--> mother's torso = a cylinder</br>
<br>--> electrodes are placed around the abdomen</br>
<br>--> ECG sources are dipoles inside the torso</br>
<br>--> each electrode measures a linear mixture of those sources, with weights determined by distance</br>
<br> They assume 32 abdominal channels and 2 reference leads (34 channels in total)</br>

### Signal characteristics for noise:

### Graph outputs and their meanings:
<figure>
    <img src = "VCG.png" width = "800" height = "500">
    <figcaption> Mother VCG and fetus VCG </figcaption>
</figure>

VCG (vectorcardiograms) are the internal dipole signals before projection to electrodes

Channel 1 --> X component
<br>Channel 2 --> Y component</br>
Channel 3 --> Z component

The coloured waveform is the continuous dipole signal
<br>The black dots labeled MQRS and FQRS are the QRS locations for both mom and fetus</br>
This is the idealised maternal heart generator. Units are in normalised units (NU). The signals never tough electrodes directly, they get projected later.

<figure>
<img src = "MECG_vs_FECG.png" width = "800" height = "500">
<figcaption>MECG vs FECG abdominal projects</figcaption>
</figure>

Blue - Maternal ECG after projection from the maternal VCG to electrodes
<br>Green - Fetal ECG projection, same electrodes</br>
Maternal dipole is much stronger --> dominates amplitude
<br>Separate projected components, no noise added yet</br>

<figure>
<img src = "cylinder plot.png" width = "600" height = "600">
<figcaption> Cylinder plot </figcaption>
</figure>

Cylinder = maternal torso volume conductor

Yellow sphere = maternal heart dipole

Blue sphere = fetal heart dipole

Blue numbered squares = abdominal electrodes (1–32)

Two extra electrodes (33, 34) = reference electrodes

Red/blue arrows = dipole orientation axes

<figure>
<img src = "FHR_and_MHR.png" width = "800", height = "500">
<figcaption> Heart rate trajectory plot </figcaption>
</figure>

Derived from QRS timings.

Provides the FHR and MHR

FECGSYN computes RR intervals and those intervals get converted into instantaneous HR


