% Audio-in-audio watermark embedding program
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

clear; clc;

%% ========== EMBEDDING PROCESS ==========

% Obtain audio data

[Cover,Fs] = audioread('cover.wav');
[Watermark,Fs] = audioread('watermark.wav');

% Match the length of watermark with cover by padding zeros

len_Cover = length(Cover);
len_WM = length(Watermark);
pad = zeros(len_Cover-len_WM, 1);
Watermark = [Watermark; pad];

% Perform single-level DWT with db3 wavelet

[Cover_A,Cover_D] = dwt(Cover,'db3');
[WM_A, WM_D] = dwt(Watermark, 'db3');

% Reshape detail coeffs to be square matrices

dim = round(sqrt(length(Cover_D)));
Cover_D = Cover_D(1:dim^2);
Cover_A = Cover_A(1:dim^2);

Cover_Dsq = reshape(Cover_D,dim,dim);

dim = round(sqrt(length(WM_D)));
WM_D = WM_D(1:dim^2);
WM_A = WM_A(1:dim^2);

WM_Dsq = reshape(WM_D,dim,dim);

% Perform SVD on the respective coeffs of the two audio data

[U_CD, S_CD, V_CD] = svd (Cover_Dsq);
[U_WD, S_WD, V_WD] = svd (WM_Dsq);

% Embedding watermark to cover via singular values

S_Watermarked = S_CD + (0.01*S_WD);

WatermarkedCover_D = U_CD * S_Watermarked * V_CD';

WatermarkedCover_D = reshape (WatermarkedCover_D,dim^2,1);

% IDWT to produce final watermarked audio

WatermarkedCover_D = idwt (Cover_A, WatermarkedCover_D,'db3');
audiowrite('watermarked.wav', WatermarkedCover_D, Fs);

%% ========== EXTRACTING PROCESS ==========

% Obtain watermarked audio data
[WatermarkedAudio, Fs] = audioread('watermarked.wav');

% Perform single-level DWT with db3 wavelet

[WMA_A,WMA_D] = dwt(WatermarkedAudio, 'db3');

% Reshape detail coeffs to be square matrices

dim = round(sqrt(length(WMA_D)));
WMA_A = WMA_A(1:dim^2);
WMA_D = WMA_D(1:dim^2);

WMA_Dsq = reshape(WMA_D,dim,dim);

% Perform SVD on the coeffs

[U_WMAD,S_WMAD,V_WMAD] = svd (WMA_Dsq);

% Extract and reshape

S_Extract = (S_WMAD - S_CD)/0.01;

Extract = U_WD * S_Extract * V_WD'; 

Extract = reshape (Extract,dim^2,1);

% IDWT to produce extracted watermark file

Extract =  idwt (WM_A, Extract, 'db3');
audiowrite('extracted.wav', Extract(1:len_WM), Fs);