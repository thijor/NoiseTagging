function [avg,cov,count] = pm_running_cov(x,avg,cov,count,maxcount)
%[avg,cov,count] = pm_running_cov(x,avg,cov,count,maxcount)
% Running covariance estimation
% 
% INPUT
%   x        = [m n] m new observations of n variables
%   avg      = [1 n] previous mean on n variables
%   cov      = [n n] previous covariance of n variables
%   count    = [int] observation count
%   maxcount = [int] maximum number of observations (i.e. weight new
%                    observations with 1/maxcount instead of 1/count)
% 
% OUTPUT
%   avg      = [1 n] new mean of n variables
%   cov      = [n n] new covariance of n varianbles
%   count    = [int] new observation count

if nargin<4||isempty(count); count=0; end
if nargin<5||isempty(maxcount); maxcount=inf; end

m = size(x,1);
avg_x = mean(x,1);
avg_x(isnan(avg_x)) = 0;

% If this is the first observation
if count==0 
    avg         = avg_x;
    x1          = bsxfun(@minus,x,avg);
    cov         = x1' * x1 ./ (m - 1);
% If there were previous observations
else 
    % New mean
    avg_new    = avg + (avg_x - avg) .* m ./ (count + m);
    x1         = bsxfun(@minus, x, avg);
    x2         = bsxfun(@minus, x, avg_new);
    avg        = avg_new;
    
    % New covariance
    weight_old = min(count, maxcount);
    weight_new = weight_old + m - 1;
    cov_old    = cov .* ((weight_old - 1) / weight_new);
    cov_x      = x1' * x2 .* (1 / weight_new);
    cov        = cov_old + cov_x;                            
end

% New count
count = count + m;