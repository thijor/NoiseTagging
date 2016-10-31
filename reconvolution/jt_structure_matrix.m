function [M,E,ev] = jt_structure_matrix(V,cfg)
%[M,E,ev] = jt_structure_matrix(V,cfg)
%Creates a structure matrix listing for each event whether the response to
%that event (still) occurs/lasts at a particular point in time.
%
% INPUT
%   V    = [m n]    n sequence of m samples
%   cfg  = [struct] configuration structure
%       .L          = [1 r] length of each event (100)
%       .delay      = [1 r] positive delay of each event start (0)
%       .event      = [str] type of event ('duration')
%       .modelonset = [int] whether or not to model onsets (false)
%       .symmetric  = [int] whether or not to make symmetric (false)
%       .wraparound = [int] whether or not to wrap around (false)
%
% OUTPUT
%   M  = [e m n] structure matrix of e=sum(L) events by samples by classes
%   E  = [m k n] event matrix of samples by event-types by classes
%   ev = [N-D]   event description

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
L           = jt_parse_cfg(cfg,'L',100);
delay       = jt_parse_cfg(cfg,'delay',0);
event       = jt_parse_cfg(cfg,'event','duration');
modelonset  = jt_parse_cfg(cfg,'modelonset',false);
symmetric   = jt_parse_cfg(cfg,'symmetric',false);
wraparound  = jt_parse_cfg(cfg,'wraparound',false);

% Add delay in front
V = cat(1, zeros(delay, size(V, 2)), V);

% Construct event matrices
[E,ev] = jt_event_matrix(V,event);

% Add onset event
if modelonset
    Eo = jt_event_matrix([1;zeros(size(V,1)-1,1)],event);
    E = cat(2,E,repmat(Eo,[1 1 size(V,2)]));
end
[m,e,n] = size(E);

% Check number of events and corresponding lengths
if numel(L)==1
    L = L*ones(1,e); 
end

% Zero-pad
if wraparound
    maxL = max(L);
    E = cat(1,E,zeros(maxL,e,n));
    m = m + maxL;
end

% Create matrix
M = zeros(m,sum(L),n);
for i = 1:n
    for j = 1:e
        Mt = diagonalize(E(:,j,i),L(e));
        if symmetric
            Mt = double(Mt | Mt(:,end:-1:1));
            Mt(:,ceil(L(j)/2)+1:end) = 0;
            M(:,sum(L(1:j-1))+1:sum(L(1:j)),i) = Mt;
        else
            M(:,sum(L(1:j-1))+1:sum(L(1:j)),i) = Mt;
        end
    end      
end

% Wrap around
if wraparound
    M(1:maxL,:,:) = M(1:maxL,:,:) | M(end-maxL+1:end,:,:);
    M = M(1:end-maxL,:,:);
end

% Events and structure should be same size as input
M = M(1:end-delay, :, :);
E = E(1:end-delay, :, :);

% Permute
M = permute(M,[2 1 3]);

%--------------------------------------------------------------------------
    function [D] = diagonalize(V,l)
        % Size V
        m = size(V,1);

        % Find events
        events = find(V);
        e = numel(events);

        % Repeat events diagonally
        rows = repmat(events(:),[1 l]);
        cols = repmat(1:l,[e 1]);
        rows = rows + cols - 1;

        % Reshape
        rows = reshape(rows,[e*l 1]);
        cols = reshape(cols,[e*l 1]);

        % Remove values outside the range
        idx = rows>m;
        rows(idx) = [];
        cols(idx) = [];

        % Indices
        idx = sub2ind([m l],rows,cols);

        % Create matrix
        D = zeros(m,l);
        D(idx) = 1;