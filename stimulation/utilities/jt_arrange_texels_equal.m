function [loc] = jt_arrange_texels_equal(cfg)
%[locations] = jt_arrange_texels_equal(cfg)
%Evenly distributes texels, so that maximum size is used.
%
% INPUT
%   cfg = [struct]
%       .N         = [int] number of texels vertical (6)
%       .M         = [int] number of texels horizontal (6)
%       .viewport  = [1 4] viewport of texels ([0 0 1 1])
%       .texelsize = [1 2] texel's spacing ([])
%       .spacesize = [1 2] texel's spacing ([])
%       .edgesize  = [flt] texel's edge size ([])
%
% OUTPUT
%   loc = [4 M*N] locations of all M*N texels

% Defaults
if nargin<1||isempty(cfg); cfg=[]; end
N = jt_parse_cfg(cfg,'N',6);
M = jt_parse_cfg(cfg,'M',6);
viewport = jt_parse_cfg(cfg,'viewport',[0 0 1 1]);
texelsize = jt_parse_cfg(cfg,'texelsize',[]);
spacesize = jt_parse_cfg(cfg,'spacesize',[]);
edgesize  = jt_parse_cfg(cfg,'edgesize',[]);

% Frame sizes
max_width  = viewport(3) - viewport(1);
max_height = viewport(4) - viewport(2);

% Compute edge size
if isempty(edgesize)
    if isempty(texelsize) && isempty(spacesize)
        edge_size = min(...
            max_width  / (M+2) / (2*M),...
            max_height / (N+2) / (2*N));
    elseif isempty(texelsize)
        edge_size = min(...
            (max_width  - M*spacesize(1)) / (M+1) / (2*M),...
            (max_height - N*spacesize(2)) / (N+1) / (2*N));
    elseif isempty(spacesize)
        edge_size = min(...
            (max_width  - M*texelsize(1)) / (M+2) / (2*M),...
            (max_height - N*texelsize(2)) / (N+2) / (2*N));
    else
        edge_size = min(...
            (max_width  - M*(texelsize(1) + 2*spacesize(1))) / (2*M),...
            (max_height - N*(texelsize(2) + 2*spacesize(2))) / (2*N));
    end
else
    edge_size = edgesize;
end

% Compute space size
if isempty(spacesize)
    if isempty(texelsize)
        space_width  = (max_width  - 2*M*edge_size) / (M+1) / (M+1);
        space_height = (max_height - 2*N*edge_size) / (N+1) / (N+1);
    else
        space_width  = (max_width  - M*texelsize(1) - 2*M*edge_size) / (M+1);
        space_height = (max_height - N*texelsize(2) - 2*N*edge_size) / (N+1);
    end
else
    space_width  = spacesize(1);
    space_height = spacesize(2);
end

% Compute texel size
if isempty(texelsize)
    texel_width  = ( max_width  - 2*M*edge_size - (M+1)*space_width  ) / M;
    texel_height = ( max_height - 2*N*edge_size - (N+1)*space_height ) / N;
else
    texel_width  = texelsize(1);
    texel_height = texelsize(2);
end

% Distributed texels
loc = zeros(4,M*N);
for x = 1:M
    for y = 1:N
        idx = (x-1)*N+y;
        loc(1,idx) = viewport(1) + (x-1)*texel_width  + (2*x-1)*edge_size + x*space_width;
        loc(2,idx) = viewport(2) + (y-1)*texel_height + (2*y-1)*edge_size + y*space_height;
        loc(3,idx) = loc(1,idx) + texel_width;
        loc(4,idx) = loc(2,idx) + texel_height;
    end
end