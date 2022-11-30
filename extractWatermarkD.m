% Function for extractracting watermark from audio
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

function Extracted = extractWatermarkD(WatermarkedAudio, S_CD, U_WD, V_WD, WM_A, len_WM)
    
    % Perform single-level DWT with db3 wavelet
    [~,D] = dwt(WatermarkedAudio, 'db4');
    
    % Reshape approx coeffs to be square matrices
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
    Extracted = idwt (WM_A, Extract_D,'db4');
    Extracted = Extracted(1:len_WM);