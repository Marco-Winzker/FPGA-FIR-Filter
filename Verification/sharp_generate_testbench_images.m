% sharp_generate_testbench_images
%
% Edge enhancement with vertical and horizontal FIR-filter
%
% FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
% (c) Marco Winzker, Hochschule Bonn-Rhein-Sieg, 14.01.2020

fprintf('Edge enhancement with vertical and horizontal FIR-filter\n')

pkg load image;
img_in = imread("Lindau_Harbour_720p.jpg"); % change name for your test image
% 1280 * 720 pixel (720p) recommended for use with remote lab

f_hor = [1, 0, -9, 48, -9, 0, 1]/32;
f_ver = f_hor'; % transpose filter matrix

img_tmp = imfilter(img_in, f_ver);
img_out = imfilter(img_tmp,f_hor);

write_ascii_ppm(img_in, "Lindau_Harbour_720p.ppm");     % change name for your test image
write_ascii_ppm(img_out,"Lindau_Harbour_expected.ppm"); % change name for your test image



