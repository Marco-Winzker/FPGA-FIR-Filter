% sharp_frequency_response
%
% frequency response of sharpness filter
%
% FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
% (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020


pkg load signal

filter = [1, 0, -9, 48, -9, 0, 1]/32    

freqz(filter)
