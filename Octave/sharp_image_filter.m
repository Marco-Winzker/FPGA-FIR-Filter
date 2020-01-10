% sharp_image_filter
%
% Edge enhancement with vertical and horizontal FIR-filter
%
% FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
% (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 10.01.2020

fprintf('Edge enhancement with vertical and horizontal FIR-filter\n')

pkg load image;
img_in = imread("Lindau_Harbour_720p.jpg"); % change name for your test image

f_hor = [1, 0, -9, 48, -9, 0, 1]/32;
f_ver = f_hor'; % transpose filter matrix

img_tmp = imfilter(img_in, f_ver);
img_out = imfilter(img_tmp,f_hor);

imwrite(img_out,"Lindau_Harbour_sharp.jpg"); % change name for your test image




