function data = jf2ft(z)
%data = jf2ft(z)
%Converts a z structure to fieldtrip structure
%
% INPUT
%   z = [struct] z structure
%
% OUTPUT
%   data = [struct] fieldtrip data structure

data.trial = shiftdim(num2cell(z.X(:,:,:), [1 2]))';

data.label = z.di(1).vals';

ntrial = prod(msize(z.X, 3:numel(size(z.X))));
data.time = cell(1,ntrial);
[data.time{:}] = deal(z.di(2).vals*.001);

[temp{1:numel(z.di(1).vals)}] = deal(z.di(1).extra.pos2d);

data.elec.chanpos = cell2mat(temp)';
data.elec.label = z.di(1).vals';

data.fsample = z.di(2).info.fs;

