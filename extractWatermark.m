% function for extractracting watermark from audio
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

function Extracted = extractWatermark(WatermarkedAudio, S_CA, U_WA, V_WA, WM_D)
    
    % Perform single-level DWT with db3 wavelet
    [A,~] = dwt(WatermarkedAudio, 'db3');
    
    % Reshape detail coeffs to be square matrices
    dim = round(sqrt(length(A)));
    A = A(1:dim^2);
    
    Asq = reshape(A,dim,dim);
    
    % Perform SVD on the coeffs
    [~,S,~] = svd (Asq);
    
    % Extract and reshape
    S_Extract = (S - S_CA)/0.01;
    
    Extract_A = U_WA * S_Extract * V_WA'; 
    
    Extract_A = reshape (Extract_A,dim^2,1);
    
    % IDWT to produce extracted watermark file
    Extracted = idwt (Extract_A, WM_D,'db3');