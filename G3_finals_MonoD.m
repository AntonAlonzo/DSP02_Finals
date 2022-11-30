% Audio-in-audio watermark main program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== EMBEDDING PROCESS ==========

% Obtain audio data
[Cover,Fs_c] = audioread('cover.wav');
[Watermark,Fs_w] = audioread('watermark2.wav');

% Match the length of watermark with cover by padding zeros
len_Cover = length(Cover);
len_WM = length(Watermark);
pad = zeros(len_Cover-len_WM, 1);
paddedWatermark = [Watermark; pad];

% Perform single-level DWT with db4 wavelet
[Cover_A,Cover_D] = dwt(Cover,'db4');
[WM_A, WM_D] = dwt(paddedWatermark, 'db4');

% Reshape approx coeffs to be square matrices
dim = round(sqrt(length(Cover_D)));
Cover_D = Cover_D(1:dim^2);
Cover_A = Cover_A(1:dim^2);

Cover_Dsq = reshape(Cover_D,dim,dim);

dim = round(sqrt(length(WM_A)));
WM_D = WM_D(1:dim^2);
WM_A = WM_A(1:dim^2);

WM_Dsq = reshape(WM_A,dim,dim);

% Perform SVD on the respective coeffs of the two audio data
[U_CD, S_CD, V_CD] = svd(Cover_Dsq);
[U_WD, S_WD, V_WD] = svd(WM_Dsq);

% Embedding watermark to cover via singular values
S_Watermarked = S_CD + (0.01*S_WD);

WatermarkedCover_D = U_CD * S_Watermarked * V_CD';

WatermarkedCover_D = reshape(WatermarkedCover_D, dim^2, 1);

% IDWT to produce final watermarked audio
WatermarkedCover = idwt(Cover_A,WatermarkedCover_D,'db4');
audiowrite('watermarkedD.wav',WatermarkedCover,Fs_c);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs_wc] = audioread('watermarkedD.wav');

Extracted = extractWatermarkD(WatermarkedAudio, S_CD, U_WD, V_WD, WM_A, len_WM);

audiowrite('extractedD.wav', Extracted, Fs_w);

%% ========== ATTACKING PROCESS ==========

len_WMA = length(WatermarkedAudio);

% Reverb
reverb = reverberator('HighCutFrequency',500,'SampleRate',1000);
revAttack = reverb(WatermarkedAudio);
revAttack = revAttack(:,1) + revAttack(:,2);
audiowrite('reverbD.wav', revAttack, Fs_wc);

% Gaussian white noise
gaussianAttack = awgn(WatermarkedAudio,50,'measured');
audiowrite('gaussianD.wav', gaussianAttack, Fs_wc);

%% ========== EXTRACTING FROM ATTACKED ==========

% Obtain attacked watermarked audio data
[revAttack, ~] = audioread('reverbD.wav');
[gaussianAttack, ~] = audioread('gaussianD.wav');

% Extract watermarks
reverb_Extract = extractWatermarkD(revAttack, S_CD, U_WD, V_WD, WM_A, len_WM);
gaussian_Extract = extractWatermarkD(gaussianAttack, S_CD, U_WD, V_WD, WM_A, len_WM);

% Write wav files
audiowrite('extractedReverbD.wav', reverb_Extract, Fs_w);
audiowrite('extractedGaussianD.wav', gaussian_Extract, Fs_w);

%% ========== PLOTTING ==========

% FIGURE 1: Cover and watermark signals through watermarking process
figure
subplot(4,1,1), 
plot(1:len_Cover, Cover),
title('Cover Signal');

subplot(4,1,2), 
plot(1:len_WM, Watermark),
title('Watermark Signal');

subplot(4,1,3), 
plot(1:len_WMA, WatermarkedCover),
title('Watermarked Cover Signal');

subplot(4,1,4), 
plot(1:len_WM, Extracted),
title('Extracted Watermark');

% FIGURE 2: Original watermarked signals vs. attacked watermarked signals
figure
subplot(3,1,1), 
plot(1:len_WMA, WatermarkedCover),
title('Original Watermarked Cover');

subplot(3,1,2), 
plot(1:length(revAttack), revAttack),
title('Reverb Attack');

subplot(3,1,3), 
plot(1:length(gaussianAttack), gaussianAttack),
title('Gaussian White Noise Attack');

% FIGURE 3: Original extracted watermark  vs. attacked extracted watermarks
figure
subplot(3,1,1), 
plot(1:len_WM, Watermark),
title('Original Extracted Watermark');

subplot(3,1,2), 
plot(1:len_WM, reverb_Extract),
title('Extracted from Reverb Attack');

subplot(3,1,3), 
plot(1:len_WM, gaussian_Extract),
title('Extracted from Gaussian White Noise attack');

%% ========== ERROR COMPUTATION ==========

% Calculate the ff:
% - Difference between original cover and the watermarked cover
% - Correlation between original and extracted watermark

[coverDiff1, coverDiff2, wmDiff] = difference(Cover,Watermark,WatermarkedCover,Extracted);
fprintf('RMSE of Cover vs Watermarked = %f\n', coverDiff1);
fprintf('PSNR of Cover vs Watermarked = %f\n', coverDiff2);
fprintf('NCC of Watermark vs Extract = %f\n\n', wmDiff);

% Calculating the ff:
% - PSNR between original watermarked and attacked watermarked audio
% - Correlation between original and attacked extracted watermark

[RMSE_r, PSNR_r, NC_r] = difference(WatermarkedCover,Watermark,revAttack,reverb_Extract);
[RMSE_g, PSNR_g, NC_g] = difference(WatermarkedCover,Watermark,gaussianAttack,gaussian_Extract);

disp('RMSE between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', RMSE_r);
fprintf('Gaussian white noise = %f\n', RMSE_g);

disp('PSNR between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', PSNR_r);
fprintf('Gaussian white noise = %f\n', PSNR_g);

disp('Correlation Coefficient between Original and Attacked Extracted Watermark')
fprintf('Reverb               = %f\n', NC_r);
fprintf('Gaussian white noise = %f\n', NC_g);