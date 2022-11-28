% Function for calculating the PSNR and NCC between two signals
% ALONZO & SOLIS | CEDISP2 S11 | Group 3

function [PSNR, NCC] = difference(orig1,orig2,exp1,exp2)

% match lengths only if uneven
if length(orig1) > length(exp1)
    orig1 = orig1(1:length(exp1));
end

% calculating PSNR between two signals

R = max(orig1); % max value
T = length(orig1); 
N = length(orig2);

RMSE = sqrt((1/T)*sum((orig1-exp1).^2)); % root mean square error
PSNR = 20*log10(R/RMSE);

% calculating (normalized) correlation coefficient

NCC = ((1/N)*sum(orig2.*exp2))/((1/N)*sqrt(sum(orig2.^2)*sum(exp2.^2)));

end