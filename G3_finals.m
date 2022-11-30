% Audio-in-audio watermark main program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== DATA INITIALIZATION ==========

% Obtain audio data
[Cover,Fs_c] = audioread('cover.wav');
[Watermark1,Fs_w1] = audioread('watermark1.wav');
[Watermark2,Fs_w2] = audioread('watermark2.wav');

% Match the length of watermark with cover by padding zeros
len_Cover = length(Cover);
len_WM1 = length(Watermark1);
pad = zeros(len_Cover-len_WM1, 1);
paddedWatermark1 = [Watermark1; pad];

len_WM2 = length(Watermark2);
pad = zeros(len_Cover-len_WM2, 1);
paddedWatermark2 = [Watermark2; pad];

% Perform single-level DWT with db4 wavelet
[Cover_A,Cover_D] = dwt(Cover,'db4');
[WM1_A, WM1_D] = dwt(paddedWatermark1, 'db4');
[WM2_A, WM2_D] = dwt(paddedWatermark2, 'db4');

%% ========== EMBEDDING PROCESS ==========

% Reshape coeffs to be square matrices
dim = round(sqrt(length(Cover_A)));
Cover_A = Cover_A(1:dim^2);
Cover_Asq = reshape(Cover_A,dim,dim);

dim = round(sqrt(length(Cover_D)));
Cover_D = Cover_D(1:dim^2);
Cover_Dsq = reshape(Cover_D,dim,dim);

dim = round(sqrt(length(WM1_A)));
WM1_A = WM1_A(1:dim^2);
WM1_D = WM1_D(1:dim^2);
WM1_Asq = reshape(WM1_A,dim,dim);

dim = round(sqrt(length(WM2_D)));
WM2_A = WM2_A(1:dim^2);
WM2_D = WM2_D(1:dim^2);
WM2_Dsq = reshape(WM2_D,dim,dim);

% Perform SVD on the coeffs of the audio data
[U_CA, S_CA, V_CA] = svd(Cover_Asq);
[U_WA, S_WA, V_WA] = svd(WM1_Asq);
[U_CD, S_CD, V_CD] = svd(Cover_Dsq);
[U_WD, S_WD, V_WD] = svd(WM2_Dsq);

% Embedding watermark to cover via singular values

% Watermark 1 to approx coeffs
S_Watermarked = S_CA + (0.01*S_WA);
WatermarkedCover_A = U_CA * S_Watermarked * V_CA';
WatermarkedCover_A = reshape(WatermarkedCover_A, dim^2, 1);

% Watermark 2 to detail coeffs
S_Watermarked = S_CD + (0.01*S_WD);
WatermarkedCover_D = U_CD * S_Watermarked * V_CD';
WatermarkedCover_D = reshape(WatermarkedCover_D, dim^2, 1);

% IDWT to produce final watermarked audio
WatermarkedCover = idwt(WatermarkedCover_A,WatermarkedCover_D,'db4');
audiowrite('watermarked.wav',WatermarkedCover,Fs_c);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs_wc] = audioread('watermarked.wav');

% Call extraction function
[Extracted1,Extracted2] = extractWatermark(WatermarkedAudio,S_CA,S_CD,U_WA,V_WA,U_WD,V_WD,WM1_D,WM2_A,len_WM1,len_WM2);

% Write extracted watermark files
audiowrite('extracted1.wav', Extracted1, Fs_w1);
audiowrite('extracted2.wav', Extracted2, Fs_w2);

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

%% ========== EXTRACTING FROM ATTACKED ==========

% Obtain attacked watermarked audio data
[revAttack, ~] = audioread('reverb.wav');
[gaussianAttack, ~] = audioread('gaussian.wav');

% Extract watermarks
[r_Ex1,r_Ex2] = extractWatermark(revAttack,S_CA,S_CD,U_WA,V_WA,U_WD,V_WD,WM1_D,WM2_A,len_WM1,len_WM2);
[g_Ex1,g_Ex2] = extractWatermark(gaussianAttack,S_CA,S_CD,U_WA,V_WA,U_WD,V_WD,WM1_D,WM2_A,len_WM1,len_WM2);

% Adjust amplitudes for better audibility
r_Ex1 = r_Ex1./80;

% Write wav files
audiowrite('extractedReverb_1.wav', r_Ex1, Fs_w1);
audiowrite('extractedReverb_2.wav', r_Ex2, Fs_w2);

audiowrite('extractedGaussian_1.wav', g_Ex1, Fs_w1);
audiowrite('extractedGaussian_2.wav', g_Ex2, Fs_w2);

%% ========== PLOTTING ==========

% FIGURE 1: Cover and watermark signals through watermarking process
figure
subplot(3,2,1), 
plot(1:len_Cover, Cover),
title('Cover Signal');

subplot(3,2,2), 
plot(1:len_WMA, WatermarkedCover),
title('Watermarked Cover Signal');

subplot(3,2,3), 
plot(1:len_WM1, Watermark1),
title('Watermark Signal 1');

subplot(3,2,4), 
plot(1:len_WM1, Extracted1),
title('Extracted Watermark 1');

subplot(3,2,5), 
plot(1:len_WM2, Watermark2),
title('Watermark Signal 2');

subplot(3,2,6), 
plot(1:len_WM2, Extracted2),
title('Extracted Watermark 2');

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

% FIGURE 3: Attacked extracted watermarks
figure
subplot(2,2,1), 
plot(1:len_WM1, r_Ex1),
title('Watermark 1 Extracted from Reverb');

subplot(2,2,2), 
plot(1:len_WM2, r_Ex2),
title('Watermark 2 Extracted from Reverb');

subplot(2,2,3), 
plot(1:len_WM1, g_Ex1),
title('Watermark 1 Extracted from Gaussian');

subplot(2,2,4), 
plot(1:len_WM2, g_Ex2),
title('Watermark 2 Extracted from Gaussian');

%% ========== ERROR COMPUTATION ==========

% Calculate the ff:
% - Difference between original cover and the watermarked cover
% - Correlation between original and extracted watermark

[coverDiff1, coverDiff2, wmDiff1] = difference(Cover,Watermark1,WatermarkedCover,Extracted1);
fprintf('RMSE of Cover vs Watermarked   = %f\n', coverDiff1);
fprintf('PSNR of Cover vs Watermarked   = %f\n', coverDiff2);
[~, ~, wmDiff2] = difference(Cover,Watermark2,WatermarkedCover,Extracted2);
fprintf('NCC of Watermarks vs Extracts  = %f    %f\n\n', wmDiff1, wmDiff2);

% Calculating the ff:
% - PSNR between original watermarked and attacked watermarked audio
% - Correlation between original and attacked extracted watermark

[RMSE_r, PSNR_r, NC_r1] = difference(WatermarkedCover,Watermark1,revAttack,r_Ex1);
[~, ~, NC_r2] = difference(WatermarkedCover,Watermark2,revAttack,r_Ex2);
[RMSE_g, PSNR_g, NC_g1] = difference(WatermarkedCover,Watermark1,gaussianAttack,g_Ex1);
[~, ~, NC_g2] = difference(WatermarkedCover,Watermark2,gaussianAttack,g_Ex2);

disp('RMSE between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', RMSE_r);
fprintf('Gaussian white noise = %f\n\n', RMSE_g);

disp('PSNR between Original and Attacked Watermarked Audio');
fprintf('Reverb               = %f\n', PSNR_r);
fprintf('Gaussian white noise = %f\n\n', PSNR_g);

disp('Correlation Coefficients between Original and Attacked Extracted Watermarks')
fprintf('                         WM1      WM2\n')
fprintf('Reverb               = %f       %f\n', NC_r1, NC_r2);
fprintf('Gaussian white noise = %f       %f\n', NC_g1, NC_g2);
