function n = pm_kb_neighbours(layout)
% n = pm_kb_neighbours(layout)
%
% INPUT
%   layout      = [1 n] n booleans representing black (0) and white (1) keys
%
% OUTPUT
%   n           = [k 2] neighbouring pairs

nkeys = numel(layout);
wkeys = sum(layout);
bkeys = nkeys - wkeys;

% White keys
widx                        = find(layout);
conn                        = [1:wkeys-1; 2:wkeys]';
wn                          = sort(widx(conn), 2);

% Black keys
bidx                        = find(~layout);
bn                          = [[bidx, bidx]', [bidx-1, bidx+1]'];
bn(bn(:, 2) <= 0, :)        = [];
bn(bn(:, 2) > nkeys, :)     = [];

% All keys
n = sort(sort([wn; bn], 2));