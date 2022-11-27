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

Extract =  idwt (WM_A, Extract, 'db3');
audiowrite('extracted.wav', Extract, Fs);
