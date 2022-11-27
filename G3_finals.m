% Audio-in-audio watermark embedding program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== EMBEDDING PROCESS ==========

% Obtain audio data
[Cover,~] = audioread('cover.wav');
[Watermark,Fs] = audioread('watermark.wav');

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
audiowrite('watermarked.wav',WatermarkedCover,Fs);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs] = audioread('watermarked.wav');

Extracted = extractWatermark(WatermarkedAudio, S_CA, U_WA, V_WA, WM_D);

audiowrite('extracted.wav', Extracted(1:len_WM), Fs);

%% ========== ATTACKING PROCESS ==========

[WatermarkedCover, Fs] = audioread('watermarked.wav');
len_WMC = length(WatermarkedCover);

% Reverb
reverb = reverberator;
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
reverb_Extract = extractWatermark(revAttack, S_CA, U_WA, V_WA, WM_A);
gaussian_Extract = extractWatermark(gaussianAttack, S_CA, U_WA, V_WA, WM_A);
highpass_Extract = extractWatermark(highAttack, S_CA, U_WA, V_WA, WM_A);
lowpass_Extract = extractWatermark(lowAttack, S_CA, U_WA, V_WA, WM_A);

% Write wav files
audiowrite('extractedReverb.wav', reverb_Extract(1:len_WM), revFs);
audiowrite('extractedGaussian.wav', gaussian_Extract(1:len_WM), gaussianFs);
audiowrite('extractedHighpass.wav', highpass_Extract(1:len_WM), lowFs);
audiowrite('extractedLowpass.wav', lowpass_Extract(1:len_WM), lowFs);

%% ========== PLOTTING ==========

figure
subplot(4,1,1), 
plot(1:len_Cover, Cover),
title('cover signal');

subplot(4,1,2), 
plot(1:len_WM, Watermark(1:len_WM)),
title('watermark signal');

subplot(4,1,3), 
plot(1:len_WMC, WatermarkedCover),
title('watermarked signal');

subplot(4,1,4), 
plot(1:len_WM, Extracted(1:len_WM)),
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
plot(1:len_WM, Watermark(1:len_WM)),
title('watermark signal');

subplot(5,1,2), 
plot(1:len_WM, reverb_Extract(1:len_WM)),
title('watermark from reverb attack');

subplot(5,1,3), 
plot(1:len_WM, gaussian_Extract(1:len_WM)),
title('watermark from gaussian white noise attack');

subplot(5,1,4), 
plot(1:len_WM, highpass_Extract(1:len_WM)),
title('watermark from highpass attack attack');

subplot(5,1,5), 
plot(1:len_WM, lowpass_Extract(1:len_WM)),
title('watermark from lowpass attack attack');