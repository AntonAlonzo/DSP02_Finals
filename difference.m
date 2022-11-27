% Calculate the PSNR between two signals
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

function [PSNR, NC] = difference(orig1,orig2,exp1,exp2)

% calculating PSNR between two signals

R = max(orig1); % max value
T = length(orig1); 
N = length(orig2);

RMSE = sqrt((1/T)*sum((orig1-exp1).^2)); % root mean square error
PSNR = 20*log10(R/RMSE);

% calculating (normalized) correlation coefficient

NC = ((1/N)*sum(orig2.*exp2))/((1/N)*sqrt(sum(orig2.^2)*sum(exp2.^2)));

end