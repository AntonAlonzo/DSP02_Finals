% Audio-in-audio watermark embedding program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== EMBEDDING PROCESS ==========

% Obtain audio data

[Cover,Fs] = audioread('cover.wav');
[Watermark,~] = audioread('watermark.wav');

% Match the length of watermark with cover by padding zeros

len_Cover = length(Cover);
len_WM = length(Watermark);
pad = zeros(len_Cover-len_WM, 1);
Watermark = [Watermark; pad];

% Perform single-level DWT with db3 wavelet

[Cover_A,Cover_D] = dwt(Cover,'db3');
[WM_A, WM_D] = dwt(Watermark, 'db3');

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

[U_CA, S_CA, V_CA] = svd (Cover_Asq);
[U_WA, S_WA, V_WA] = svd (WM_Asq);

% Embedding watermark to cover via singular values

S_Watermarked = S_CA + (0.01*S_WA);

WatermarkedCover_A = U_CA * S_Watermarked * V_CA';

WatermarkedCover_A = reshape (WatermarkedCover_A,dim^2,1);

% IDWT to produce final watermarked audio

WatermarkedCover_A = idwt (WatermarkedCover_A, Cover_D,'db3');
audiowrite('watermarked.wav', WatermarkedCover_A, Fs);

disp('embedding done')

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs] = audioread('watermarked.wav');

% Perform single-level DWT with db3 wavelet

[WMA_A,WMA_D] = dwt(WatermarkedAudio, 'db3');

% Reshape detail coeffs to be square matrices

dim = round(sqrt(length(WMA_A)));
WMA_A = WMA_A(1:dim^2);
WMA_D = WMA_D(1:dim^2);

WMA_Asq = reshape(WMA_A,dim,dim);

% Perform SVD on the coeffs

[U_WMAA,S_WMAA,V_WMAA] = svd (WMA_Asq);

% Extract and reshape

S_Extract = (S_WMAA - S_CA)/0.01;

Extract = U_WA * S_Extract * V_WA'; 

Extract = reshape (Extract,dim^2,1);

% IDWT to produce extracted watermark file

Extract =  idwt (Extract, WM_D, 'db3');
audiowrite('extracted.wav', Extract(1:len_WM), Fs);

disp('extracting done')

%% ========== ATTACKING PROCESS ==========

[WatermarkedCover, Fs] = audioread('watermarked.wav');
len_WMC = length(WatermarkedCover);

disp('reverb attack')
% Reverb
reverb = reverberator;
revAttack = reverb(WatermarkedCover);
audiowrite('reverb.wav', revAttack, Fs);

disp('gaussian attack')
% Gaussian white noise
gaussianAttack = awgn(WatermarkedCover,10);
audiowrite('gaussian.wav', gaussianAttack, Fs);

disp('highpass attack')
% Highpass filter
highAttack = highpass(WatermarkedCover,3,Fs);
audiowrite('highpass.wav', highAttack, Fs);

disp('lowpass attack')
%lowpass filter
lowAttack = lowpass(WatermarkedCover,15,Fs);
audiowrite('lowpass.wav', lowAttack, Fs);

%% ========== EXTRACTING FROM ATTACKS ==========

disp('obtain watermark')
% Obtain watermarked audio data
[revAttack, Fs] = audioread('reverb.wav');
[gaussianAttack, ~] = audioread('gaussian.wav');
[highAttack, ~] = audioread('highpass.wav');
[lowAttack, ~] = audioread('lowpass.wav');

disp('dwt')
% Perform single-level DWT with db3 wavelet
[reverb_A,reverb_D] = dwt(revAttack(:,1), 'db3');
[gaussian_A,gaussian_D] = dwt(gaussianAttack, 'db3');
[highpass_A,highpass_D] = dwt(highAttack, 'db3');
[lowpass_A,lowpass_D] = dwt(lowAttack, 'db3');

disp('reshape')
% Reshape detail coeffs to be square matrices
dim = round(sqrt(length(reverb_A)));
reverb_A = reverb_A(1:dim^2);
reverb_D = reverb_D(1:dim^2);
reverb_Asq = reshape(reverb_A,dim,dim);

dim = round(sqrt(length(gaussian_A)));
gaussian_A = gaussian_A(1:dim^2);
gaussian_D = gaussian_D(1:dim^2);
gaussian_Asq = reshape(gaussian_A,dim,dim);

dim = round(sqrt(length(highpass_A)));
highpass_A = highpass_A(1:dim^2);
highpass_D = highpass_D(1:dim^2);
highpass_Asq = reshape(highpass_A,dim,dim);

dim = round(sqrt(length(lowpass_A)));
lowpass_A = lowpass_A(1:dim^2);
lowpass_D = lowpass_D(1:dim^2);
lowpass_Asq = reshape(lowpass_A,dim,dim);

disp('svd')
% Perform SVD on the coeffs
[U_reverb,S_reverb,V_reverb] = svd (reverb_Asq);
[U_gaussian,S_gaussian,V_gaussian] = svd (gaussian_Asq);
[U_highpass,S_highpass,V_highpass] = svd (highpass_Asq);
[U_lowpass,S_lowpass,V_lowpass] = svd (lowpass_Asq);

disp('reshape 2')
% Extract and reshape
S_Extract = (S_reverb - S_CA)/0.01;
reverb_Extract = U_WA * S_Extract * V_WA'; 
reverb_Extract = reshape (reverb_Extract,dim^2,1);

S_Extract = (S_gaussian - S_CA)/0.01;
gaussian_Extract = U_WA * S_Extract * V_WA'; 
gaussian_Extract = reshape (gaussian_Extract,dim^2,1);

S_Extract = (S_highpass - S_CA)/0.01;
highpass_Extract = U_WA * S_Extract * V_WA'; 
highpass_Extract = reshape (highpass_Extract,dim^2,1);

S_Extract = (S_lowpass - S_CA)/0.01;
lowpass_Extract = U_WA * S_Extract * V_WA'; 
lowpass_Extract = reshape (lowpass_Extract,dim^2,1);

disp('idwt')
% IDWT to produce extracted watermark file
reverb_Extract =  idwt (reverb_Extract, WM_D, 'db3');
audiowrite('extractedReverb.wav', reverb_Extract(1:len_WM), Fs);

gaussian_Extract =  idwt (gaussian_Extract, WM_D, 'db3');
audiowrite('extractedGaussian.wav', gaussian_Extract(1:len_WM), Fs);

highpass_Extract =  idwt (highpass_Extract, WM_D, 'db3');
audiowrite('extractedHighpass.wav', highpass_Extract(1:len_WM), Fs);

lowpass_Extract =  idwt (lowpass_Extract, WM_D, 'db3');
audiowrite('extractedLowpass.wav', lowpass_Extract(1:len_WM), Fs);

%% ========== PLOTTING ==========

figure
subplot(4,1,1), 
plot(1:len_Cover, Cover),
title('cover signal');

subplot(4,1,2), 
plot(1:length(Watermark), Watermark),
title('watermark signal');

subplot(4,1,3), 
plot(1:length(WatermarkedCover_A), WatermarkedCover_A),
title('/s/ magnitude spectrum');

subplot(4,1,4), 
plot(1:length(Extract), Extract),
title('extracted watermark');


figure
subplot(5,1,1), 
plot(1:len_Cover, Cover),
title('cover signal');

subplot(5,1,2), 
plot(1:length(revAttack(:,1)), revAttack(:,1)),
title('reverb attack');

subplot(5,1,3), 
plot(1:length(gaussianAttack), gaussianAttack),
title('gaussian white noise attack');

subplot(5,1,4), 
plot(1:length(highAttack), highAttack),
title('highpass filter attack');

subplot(5,1,5), 
plot(1:length(lowAttack), lowAttack),
title('lowpass attack attack');


figure
subplot(5,1,1), 
plot(1:length(Watermark), Watermark),
title('watermark signal');

subplot(5,1,2), 
plot(1:length(reverb_Extract), reverb_Extract),
title('watermark from reverb attack');

subplot(5,1,3), 
plot(1:length(gaussian_Extract), gaussian_Extract),
title('watermark from gaussian white noise attack');

subplot(5,1,4), 
plot(1:length(highpass_Extract), highpass_Extract),
title('watermark from highpass filter attack');

subplot(5,1,5), 
plot(1:length(lowpass_Extract), lowpass_Extract),
title('watermark from lowpass attack attack');