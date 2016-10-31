function b = jt_squeeze(a)
% Copy of Matlab's squeeze.m but also on 2-D matrices!

if nargin==0 
  error(message('MATLAB:squeeze:NotEnoughInputs')); 
end

siz = size(a);
siz(siz==1) = []; % Remove singleton dimensions.
siz = [siz ones(1,2-length(siz))]; % Make sure siz is at least 2-D
b = reshape(a,siz);