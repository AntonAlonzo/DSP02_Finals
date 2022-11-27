% Audio-in-audio watermark embedding program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== EMBEDDING PROCESS ==========

% Obtain audio data
[Cover,Fs_c] = audioread('cover.wav');
[Watermark,Fs_w] = audioread('watermark.wav');

% Match the length of watermark with cover by padding zeros
len_Cover = length(Cover);
len_WM = length(Watermark);
pad = zeros(len_Cover-len_WM, 1);
paddedWatermark = [Watermark; pad];

% Perform single-level DWT with db3 wavelet
[Cover_A,Cover_D] = dwt(Cover,'db3');
[WM_A, WM_D] = dwt(paddedWatermark, 'db3');

% Reshape detail coeffs to be square matrices
dim = round(sqrt(length(Cover_A)));
Cover_D = Cover_D(1:dim^2);
Cover_A = Cover_A(1:dim^2);

Cover_Asq = reshape(Cover_A,dim,dim);

dim = round(sqrt(length(WM_A)));
WM_D = WM_D(1:dim^2);
WM_A = WM_A(1:dim^2);

WM_Asq = reshape(WM_A,dim,dim);

% Perform SVD on the respective coeffs of the two audio data
[U_CA, S_CA, V_CA] = svd(Cover_Asq);
[U_WA, S_WA, V_WA] = svd(WM_Asq);

% Embedding watermark to cover via singular values
S_Watermarked = S_CA + (0.01*S_WA);

WatermarkedCover_A = U_CA * S_Watermarked * V_CA';

WatermarkedCover_A = reshape(WatermarkedCover_A, dim^2, 1);

% IDWT to produce final watermarked audio
WatermarkedCover = idwt(WatermarkedCover_A,Cover_D,'db3');
audiowrite('watermarked.wav',WatermarkedCover,Fs_c);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, ~] = audioread('watermarked.wav');

Extracted = extractWatermark(WatermarkedAudio, S_CA, U_WA, V_WA, WM_D, len_WM);

audiowrite('extracted.wav', Extracted, Fs_w);

%% ========== ATTACKING PROCESS ==========

[WatermarkedCover, Fs] = audioread('watermarked.wav');
len_WMC = length(WatermarkedCover);

% Reverb
reverb = reverberator('HighCutFrequency',5);
revAttack = reverb(WatermarkedCover);
revAttack = revAttack(:,1) + revAttack(:,2);
audiowrite('reverb.wav', revAttack, Fs);

% Gaussian white noise
gaussianAttack = awgn(WatermarkedCover,50,'measured');
audiowrite('gaussian.wav', gaussianAttack, Fs);

% Highpass filter
highAttack = highpass(WatermarkedCover,50,Fs);
audiowrite('highpass.wav', highAttack, Fs);

% Lowpass filter
lowAttack = lowpass(WatermarkedCover,15,Fs);
audiowrite('lowpass.wav', lowAttack, Fs);

%% ========== EXTRACTING FROM ATTACKS ==========

% Obtain watermarked audio data
[revAttack, revFs] = audioread('reverb.wav');
[gaussianAttack, gaussianFs] = audioread('gaussian.wav');
[highAttack, highFs] = audioread('highpass.wav');
[lowAttack, lowFs] = audioread('lowpass.wav');

% Extract watermarks
reverb_Extract = extractWatermark(revAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
gaussian_Extract = extractWatermark(gaussianAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
highpass_Extract = extractWatermark(highAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
lowpass_Extract = extractWatermark(lowAttack, S_CA, U_WA, V_WA, WM_A, len_WM);

% Write wav files
audiowrite('extractedReverb.wav', reverb_Extract, revFs);
audiowrite('extractedGaussian.wav', gaussian_Extract, gaussianFs);
audiowrite('extractedHighpass.wav', highpass_Extract, lowFs);
audiowrite('extractedLowpass.wav', lowpass_Extract, lowFs);

%% ========== PLOTTING ==========

figure
subplot(4,1,1), 
plot(1:len_Cover, Cover),
title('cover signal');

subplot(4,1,2), 
plot(1:len_WM, Watermark),
title('watermark signal');

subplot(4,1,3), 
plot(1:len_WMC, WatermarkedCover),
title('watermarked signal');

subplot(4,1,4), 
plot(1:len_WM, Extracted),
title('extracted watermark');

figure
subplot(5,1,1), 
plot(1:len_Cover, Cover),
title('cover signal');

subplot(5,1,2), 
plot(1:length(revAttack), revAttack),
title('reverb attack');

subplot(5,1,3), 
plot(1:length(gaussianAttack), gaussianAttack),
title('gaussian white noise attack');

subplot(5,1,4), 
plot(1:length(highAttack), highAttack),
title('highpass attack attack');

subplot(5,1,5), 
plot(1:length(lowAttack), lowAttack),
title('lowpass attack attack');


figure
subplot(5,1,1), 
plot(1:len_WM, Watermark),
title('watermark signal');

subplot(5,1,2), 
plot(1:len_WM, reverb_Extract),
title('watermark from reverb attack');

subplot(5,1,3), 
plot(1:len_WM, gaussian_Extract),
title('watermark from gaussian white noise attack');

subplot(5,1,4), 
plot(1:len_WM, highpass_Extract),
title('watermark from highpass attack attack');

subplot(5,1,5), 
plot(1:len_WM, lowpass_Extract),
title('watermark from lowpass attack attack');

%% ========== ERROR COMPUTATION ==========

% Calculate the ff:
% - Difference between original cover and the watermarked cover
% - Correlation between original and extracted watermark

% [coverDiff,wmDiff] = difference(Cover,Watermark,WatermarkedCover,Extracted);
% fprintf('PSNR of Cover vs Watermarked = %f\n', coverDiff);
% fprintf('NCC of Watermark vs Extract = %f\n\n', wmDiff);

% Calculating the ff:
% - PSNR between original watermarked and attacked watermarked audio
% - Correlation between original and attacked extracted watermark

[PSNR_r, NC_r] = difference(WatermarkedCover,Extracted,revAttack,reverb_Extract);
[PSNR_g, NC_g] = difference(WatermarkedCover,Extracted,gaussianAttack,gaussian_Extract);
[PSNR_h, NC_h] = difference(WatermarkedCover,Extracted,highAttack,highpass_Extract);
[PSNR_l, NC_l] = difference(WatermarkedCover,Extracted,lowAttack,lowpass_Extract);

disp('PSNR between Original and Attacked Watermarked Audio');
fprintf('Reverb = %f\n', PSNR_r);
fprintf('Gaussian white noise = %f\n', PSNR_g);
fprintf('Highpass filtering = %f\n', PSNR_h);
fprintf('Lowpass filtering = %f\n\n', PSNR_l);

disp('Correlation Coefficient between Original and Attacked Extracted Watermark')
fprintf('Reverb = %f\n', NC_r);
fprintf('Gaussian white noise = %f\n', NC_g);
fprintf('Highpass filtering = %f\n', NC_h);
fprintf('Lowpass filtering = %f\n', NC_l);


