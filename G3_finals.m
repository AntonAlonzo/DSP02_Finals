% Audio-in-audio watermark main program
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

% Perform single-level DWT with db4 wavelet
[Cover_A,Cover_D] = dwt(Cover,'db4');
[WM_A, WM_D] = dwt(paddedWatermark, 'db4');

% Reshape approx coeffs to be square matrices
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
WatermarkedCover = idwt(WatermarkedCover_A,Cover_D,'db4');
audiowrite('watermarked.wav',WatermarkedCover,Fs_c);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs_wc] = audioread('watermarked.wav');

Extracted = extractWatermark(WatermarkedAudio, S_CA, U_WA, V_WA, WM_D, len_WM);

audiowrite('extracted.wav', Extracted, Fs_w);

%% ========== ATTACKING PROCESS ==========

len_WMA = length(WatermarkedAudio);

% Reverb
reverb = reverberator('HighCutFrequency',500,'SampleRate',1000);
revAttack = reverb(WatermarkedAudio);
revAttack = revAttack(:,1) + revAttack(:,2);
audiowrite('reverb.wav', revAttack, Fs_wc);

% Gaussian white noise
gaussianAttack = awgn(WatermarkedAudio,50,'measured');
audiowrite('gaussian.wav', gaussianAttack, Fs_wc);

% Highpass filter
highAttack = highpass(WatermarkedAudio,50,Fs_wc);
audiowrite('highpass.wav', highAttack, Fs_wc);

% Lowpass filter
lowAttack = lowpass(WatermarkedAudio,15,Fs_wc);
audiowrite('lowpass.wav', lowAttack, Fs_wc);

%% ========== EXTRACTING FROM ATTACKED ==========

% Obtain attacked watermarked audio data
[revAttack, ~] = audioread('reverb.wav');
[gaussianAttack, ~] = audioread('gaussian.wav');
[highAttack, ~] = audioread('highpass.wav');
[lowAttack, ~] = audioread('lowpass.wav');

% Extract watermarks
reverb_Extract = extractWatermark(revAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
gaussian_Extract = extractWatermark(gaussianAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
highpass_Extract = extractWatermark(highAttack, S_CA, U_WA, V_WA, WM_A, len_WM);
lowpass_Extract = extractWatermark(lowAttack, S_CA, U_WA, V_WA, WM_A, len_WM);

% Adjust amplitudes
reverb_Extract = reverb_Extract./100;
lowpass_Extract = lowpass_Extract./20;

% Write wav files
audiowrite('extractedReverb.wav', reverb_Extract, Fs_w);
audiowrite('extractedGaussian.wav', gaussian_Extract, Fs_w);
audiowrite('extractedHighpass.wav', highpass_Extract, Fs_w);
audiowrite('extractedLowpass.wav', lowpass_Extract, Fs_w);

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
subplot(5,1,1), 
plot(1:len_WMA, WatermarkedCover),
title('Original Watermarked Cover');

subplot(5,1,2), 
plot(1:length(revAttack), revAttack),
title('Reverb Attack');

subplot(5,1,3), 
plot(1:length(gaussianAttack), gaussianAttack),
title('Gaussian White Noise Attack');

subplot(5,1,4), 
plot(1:length(highAttack), highAttack),
title('Highpass Filter Attack');

subplot(5,1,5), 
plot(1:length(lowAttack), lowAttack),
title('Lowpass Filter Attack');

% FIGURE 3: Original extracted watermark  vs. attacked extracted watermarks
figure
subplot(5,1,1), 
plot(1:len_WM, Watermark),
title('Original Extracted Watermark');

subplot(5,1,2), 
plot(1:len_WM, reverb_Extract),
title('Extracted from Reverb Attack');

subplot(5,1,3), 
plot(1:len_WM, gaussian_Extract),
title('Extracted from Gaussian White Noise attack');

subplot(5,1,4), 
plot(1:len_WM, highpass_Extract),
title('Extracted from Highpass Filter Attack');

subplot(5,1,5), 
plot(1:len_WM, lowpass_Extract),
title('Extracted from Lowpass Filter Attack');

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
[RMSE_h, PSNR_h, NC_h] = difference(WatermarkedCover,Watermark,highAttack,highpass_Extract);
[RMSE_l, PSNR_l, NC_l] = difference(WatermarkedCover,Watermark,lowAttack,lowpass_Extract);

disp('RMSE between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', RMSE_r);
fprintf('Gaussian white noise = %f\n', RMSE_g);
fprintf('Highpass filtering   = %f\n', RMSE_h);
fprintf('Lowpass filtering    = %f\n\n', RMSE_l);

disp('PSNR between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', PSNR_r);
fprintf('Gaussian white noise = %f\n', PSNR_g);
fprintf('Highpass filtering   = %f\n', PSNR_h);
fprintf('Lowpass filtering    = %f\n\n', PSNR_l);

disp('Correlation Coefficient between Original and Attacked Extracted Watermark')
fprintf('Reverb               = %f\n', NC_r);
fprintf('Gaussian white noise = %f\n', NC_g);
fprintf('Highpass filtering   = %f\n', NC_h);
fprintf('Lowpass filtering    = %f\n', NC_l);