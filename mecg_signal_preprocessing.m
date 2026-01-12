thisFilePath = mfilename('fullpath');
thisFolder   = fileparts(thisFilePath);

dataDir = fullfile(thisFolder, '..', 'data');
fname = 'fecgsyn01_snr00dB_l1_c0.mat';
S = load(fullfile(dataDir, fname));

out = S.out;

fs = out.param.fs;
X = out.mecg;
X = X.';
Xabd = X(:,1:32);

t = (0:size(Xabd,1)-1)/fs;

% signal in time domain
ch = 1;
figure;
for i = 1:ch
    subplot(ch,1,i);
    plot(t,Xabd(:,i));
    title(['ECG Channel ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (A.U.');
end

% signal in frequency domain
x = Xabd(:,ch);
t = 10;
N = t*fs;
x = x(1:N);

Nfft = length(x);
x = double(x(:));   % force column + double
x = detrend(x);
Xf = fft(x);
f = (0:Nfft-1)*(fs/Nfft);

Xmag = abs(Xf)/Nfft;
Xmag = Xmag(1:floor(Nfft/2)+1);
f = f(1:floor(Nfft/2)+1);

figure;
plot(f,Xmag);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title(['FFT Magnitude Spectrum - ECG Channel ' num2str(ch)]);
xlim([0 100]);

% Adding a bandpass filter 
bpfilt = designfilt("bandpassfir", ...
    FilterOrder=50,CutoffFrequency1=0.5, ...
    CutoffFrequency2=50,SampleRate=fs);

x_filt = filtfilt(bpfilt, x);

% Time domain analysis (after filter)

t_disp = 10;
Ns = t_disp*fs;
t = (0:Ns-1)/fs;

figure;
plot(t, x(1:Ns)); hold on;
plot(t,x_filt(1:Ns));
xlabel('Time (s)');
ylabel('Amplitude (A.U.)');
title('ECG: Raw vs Bandpass Filtered');
legend('Raw','Filtered');

% Frequency domain

N = length(x);
Nfft = 2^nextpow2(N);
f = (0:(Nfft/2))*(fs/Nfft);

Xmag = abs(fft(x,Nfft))/N;
Xmag = Xmag(1:Nfft/2+1);

Xfmag = abs(fft(x_filt,Nfft))/N;
Xfmag = Xfmag(1:Nfft/2+1);

figure;
plot(f, Xmag); hold on;
plot(f, Xfmag);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('FFT: Raw vs Bandpass filtered');
xlim([0,100]);
legend('Raw','Filtered')

% Once noise is removed, we can use the findpeaks function to detect R
% peaks
[peaks, locs] = findpeaks(x_filt,"MinPeakDistance",round(0.5*fs));

figure;
plot(x_filt);
hold on;
plot(locs, x_filt(locs),'ro','MarkerSize',10);
xlabel('Samples');
ylabel('Amplitude');
title('ECG Signal with Detected R peaks');
legend('ECG signal','R peaks');
hold off;


% Band-power ratios

BW_p = bandpower(x,fs,[0 0.5]);
ECG_p = bandpower(x,fs,[0.5 50]);
HF_p = bandpower(x,fs,[50 100]);

BW_a = bandpower(x_filt,fs,[0 0.5]);
ECG_a = bandpower(x_filt, fs, [0.5 50]);
HF_a = bandpower(x_filt, fs, [50 100]);

ratio_before = ECG_p/(HF_p+BW_p);
ratio_after  = ECG_a/(HF_a+BW_a);

disp(ratio_before);

disp(ratio_after);
