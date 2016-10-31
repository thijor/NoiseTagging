function [jnd] = just_noticeable_difference(lux)
% [jnd] = just_noticeable_difference(lux)

% a = -1.3011877;
% b = -2.5840191e-2;
% c = 8.0242636e-2;
% d = -1.0320229e-1;
% e = 1.3646699e-1;
% f = 2.8745620e-2;
% g = -2.5468404e-2;
% h = -3.1978977e-3;
% k = 1.2992634e-4;
% m = 1.3635334e-3;
% 
% j = jnd; 
% 
% lux = 10.^((a + c .* log(j) + e .* log(j).^2 + g .* log(j)^3 + m .* log(j).^4) ./ ...
%     (1 + b .* log(j) + d .* log(j).^2 + f .* log(j).^3 + h .* log(j).^4 + k .* log(j).^5));

a = 71.498068;
b = 94.593053;
c = 41.912053;
d = 9.8247004;
e = 0.28175407;
f = -1.1878455;
g = -0.18014349;
h = 0.14710899;
k = -0.017046845;

jnd = a + b .* log10(lux) + c .* log10(lux).^2 + d .* log10(lux).^3 ...
    + e .* log10(lux).^4 + f .* log10(lux).^5 + g .* log10(lux).^6 ...
    + h .* log10(lux).^7 + k .* log10(lux).^8;