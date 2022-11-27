% Driver Program
% ALONZO & SOLIS | CEDISP3 S11 | GROUP 3

clear all;
clc;

%% Reshape Audio into 2D Matrix
% Host Audio
[A_host,~] = audioread ('cover.wav');
[A_ahost,Ad] = dwt(A_host,'db3');
lt = length (A_host);
d = sqrt (lt);
d = round(d);
A_hostR = reshape(A_host,d,d);

% Watermark Audios
[A_wat1,~] = audioread ('watermark1.wav');
lt = length (A_wat1);
d = sqrt (lt);
d = round(d);
A_wat1R = reshape(A_wat1,d,d);

[A_wat2,~] = audioread ('watermark2.wav');
lt = length (A_wat2);
d = sqrt (lt);
d = round(d);
A_wat2R = reshape(A_wat2,d,d);

%% Host Audio Manipulation
% 2-level Haar Wavelet Transform on Host Audio (not sure??)
[LLhost, ~, ~, ~] = dwt2(im2double(A_hostR), 'haar');
[LLhost, LHhost, HLhost, HHhost] = dwt2(im2double(LLhost), 'haar');

% SVD on HL and LH bands
[U_HLhost,S_HLhost,V_HLhost] = svd(HLhost);
[U_LHhost,S_LHhost,V_LHhost] = svd(LHhost);

%% Watermark Audio Manipulation
[LLwat1, LHwat1, HLwat1, HHwat1] = dwt2(im2double(A_wat1R), 'haar');
[LLwat2, LHwat2, HLwat2, HHwat2] = dwt2(im2double(A_wat2R), 'haar');

[U_wat1,S_wat1,V_wat1] = svd(HLwat1);
[U_wat2,S_wat2,V_wat2] = svd(LHwat2);

%% Modify singular values of host image

S_hostHL = S_HLhost + (0.01*S_wat1);
S_hostLH = S_LHhost + (0.01*S_wat2);

S_host = (S_hostHL + S_hostLH)/2;

%% Obtain modified audio
U_host = (U_HLhost + U_LHhost)/2;
V_host = (V_HLhost + V_LHhost)/2;

M_host = U_host * S_host * V_host;
F_host = reshape (M_host,(d*d),1);

%% Apply IDWT to obatin watermarked audio
AWout = idwt (Aa,F_host,'db3');

audiowrite( 'AudioWatermarked.wav',AWout,fs);