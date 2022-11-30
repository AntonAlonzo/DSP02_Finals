% Function for extractracting watermark from audio
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

% Input Parameters

%   WatermarkedAudio    :   watermarked audio data
%   S_CA, S_CD          :   S matrices of original cover signal
%   U_W1, V_W1          :   U and V (approx) matrices of watermark 1 
%   U_W2, V_W2          :   U and V (detail) matrices of watermark 2
%   WM1                 :   detail coefficients of watermark 1
%   WM2                 :   approx coefficients of watermark 2
%   len_W1, len_W2      :   lengths of watermarks

% Output Parameters

%   Ex1, Ex2            :   extracted watermarks

function [Ex1, Ex2] = extractWatermark(WatermarkedAudio, S_CA, S_CD, U_W1, V_W1, U_W2, V_W2, WM1, WM2, len_W1, len_W2)
    
    % Perform single-level DWT with db3 wavelet
    [WMC_A,WMC_D] = dwt(WatermarkedAudio, 'db4');
    
    % Reshape approx coeffs to be square matrices
    dim = round(sqrt(length(WMC_A)));
    WMC_A = WMC_A(1:dim^2);
    WMC_Asq = reshape(WMC_A,dim,dim);

    dim = round(sqrt(length(WMC_D)));
    WMC_D = WMC_D(1:dim^2);
    WMC_Dsq = reshape(WMC_D,dim,dim);
    
    % Perform SVD on the coeffs
    [~,S1_A,~] = svd (WMC_Asq);
    [~,S2_D,~] = svd (WMC_Dsq);
    
    % Extract and reshape
    S_Ex_A = (S1_A - S_CA)/0.01;
    S_Ex_D = (S2_D - S_CD)/0.01;
    
    Extract1_A = U_W1 * S_Ex_A * V_W1'; 
    Extract1_A = reshape (Extract1_A,dim^2,1);

    Extract2_D = U_W2 * S_Ex_D * V_W2';
    Extract2_D = reshape (Extract2_D,dim^2,1);
    
    % IDWT to produce extracted watermark file
    Extracted = idwt (Extract1_A, WM1,'db4');
    Ex1 = Extracted(1:len_W1);

    Extracted = idwt (WM2, Extract2_D, 'db4');
    Ex2 = Extracted(1:len_W2);