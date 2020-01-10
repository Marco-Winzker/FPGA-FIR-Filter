% sharp_filter_coefficients
%
% determine filter coefficients for sharpness filter
%
% FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
% (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020


pkg load signal

fir1(8,0.5, "high")

round(32*fir1(8,0.5, "high"))


