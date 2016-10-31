function v = jt_bin2pol(v)
%v = jt_bin2pol(v)
%Converts a binary (0,1) variable to a polair (-1,1) one
%
% INPUT
%   v = [N-D] binairy variable
%
% OUTPUT
%   v = [N-D] polair variable

uniques = unique(double(v(:)));
if numel(uniques)==2 && (uniques(1)==0 || uniques(1)==-1) && uniques(2)==1
    v=double(v);
    v(v==0)=-1;
else
    error('Input is not binary')
end