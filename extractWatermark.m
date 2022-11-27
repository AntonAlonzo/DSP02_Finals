% function for extractracting watermark from audio
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

function Extracted = extractWatermark(WatermarkedAudio, S_CD, U_WD, V_WD, WM_A)
    
    % Perform single-level DWT with db3 wavelet
    [~,D] = dwt(WatermarkedAudio, 'db3');
    
    % Reshape detail coeffs to be square matrices
    
    dim = round(sqrt(length(D)));
    D = D(1:dim^2);
    
    Dsq = reshape(D,dim,dim);
    
    % Perform SVD on the coeffs
    [~,S,~] = svd (Dsq);
    
    % Extract and reshape
    S_Extract = (S - S_CD)/0.01;
    
    Extract_D = U_WD * S_Extract * V_WD'; 
    
    Extract_D = reshape (Extract_D,dim^2,1);
    
    % IDWT to produce extracted watermark file
    Extracted = idwt (WM_A, Extract_D,'db3');