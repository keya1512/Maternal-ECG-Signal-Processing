basePath = "C:\Users\keyas\OneDrive\Desktop\Biorithm\Tasks";
fname = "fecgsyn01_snr06dB_l3_c0.mat";

S = load(fullfile(basePath, fname));
out = S.out;

fs = out.param.fs;
X = out.mecg;
X = X.';
Xabd = X(:,1:32);
t_disp = 10;
N = t_disp*fs;
t = (0:N-1)/fs;

Xplot = Xabd(1:N,:);

% signal in time domain
ch = 1;
figure;
for i = 1:ch
    subplot(ch,1,i);
    plot(t,Xplot(:,i));
    title(['ECG Channel ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (A.U.)');
end

% signal in frequency domain

x = Xabd(:,ch);
x = x(1:N);
Nfft = length(x);
x = double(x(:));
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

% Bandpass filter 

bpfilt = designfilt('bandpassfir', ...
    FilterOrder = 50, CutOffFrequency1 = 0.5, ...
    CutOffFrequency2 = 50, SampleRate = fs);
x_filt = filtfilt(bpfilt,x);

% median filtering

x_filt_2 = medfilt1(x_filt,10);

% time domain after filter
figure;
plot(t, x(1:N));
hold on;
plot(t, x_filt(1:N));
plot(t, x_filt_2(1:N));
title("After Bandpass filter");
xlabel("Time (s)");
ylabel("Amplitude (A.U.)");
legend("Raw","BPF", "median");

% frequency domain after filter

N = length(x);
Nfft = 2^nextpow2(N);
f = (0:(Nfft/2))*(fs/Nfft);

Xmag = abs(fft(x,Nfft))/N;
Xmag = Xmag(1:Nfft/2+1);

Xfmag = abs(fft(x_filt_2,Nfft))/N;
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

[peaks, locs] = findpeaks(x_filt_2,"MinPeakDistance",round(0.55*fs));
figure;
plot(x_filt_2);
hold on;
plot(locs, x_filt_2(locs),'ro','MarkerSize',10);
xlabel('Samples');
ylabel('Amplitude');
title('ECG Signal with Detected R peaks');
legend('ECG signal','R peaks');
hold off;

% Band-power ratios

BW_p = bandpower(x,fs,[0 7]);
ECG_p = bandpower(x,fs,[7 50]);
HF_p = bandpower(x,fs,[50 100]);

BW_a = bandpower(x_filt_2,fs,[0 7]);
ECG_a = bandpower(x_filt_2, fs, [7 50]);
HF_a = bandpower(x_filt_2, fs, [50 100]);

ratio_before = ECG_p/(HF_p+BW_p);
ratio_after  = ECG_a/(HF_a+BW_a);

disp(ratio_before);
disp(ratio_after);