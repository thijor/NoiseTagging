function [corrs,state] = jt_correlation(v,w,state,n)
%[corrs,state] = jt_correlation(v,w,state,n)
%
% INPUT
%   v     = [m p]    new segment of m samples and p variables
%   w     = [m q]    new segment of m samples and q variables
%   state = [struct] structure with statistics, empty for first call ([])
%   n     = [int]    maximum number of segments (1)
%
% OUTPUT
%   corrs = [p q n]  correlations values starting with short segments
%   state = [struct] structure with statistics, updated with newest segment
%       .c     = [int]     number of segments, counter
%       .n     = [int]     maximum number of segments
%       .m     = [int]     number of samples in a segment
%       .p     = [int]     number of variables in v
%       .q     = [int]     number variables in q
%       .stats = [n p q 5] summed statistics

% Defaults
if nargin<3||isempty(state); state = []; end
if nargin<4||isempty(n); n = 1; end

% Convert to float
if ~isfloat(v); v = single(v); end
if ~isfloat(w); w = single(w); end

% Initialize state
if isempty(state)
    state = [];
    state.c = 0;            % Segment counter 
    state.n = n;            % Maximum number of segments
    state.m = size(v,1);    % Number of samples in segment
    state.p = size(v,2);    % Number of variables in v
    state.q = size(w,2);    % Number of variables in w
    state.stats = zeros(state.p,state.q,n,5); % statistics
end

% Update stats
state = update_stats(state,v,w);

% Update corrs
corrs = update_corrs(state);

%--------------------------------------------------------------------------
function state = update_stats(state,v,w)

% Stats of new segment
stats = cat(3,...
    repmat(sum(v,1)',   [1 state.q]), ... % sum of v 
    repmat(sum(w,1),    [state.p 1]), ... % sum of w
    repmat(sum(v.^2,1)',[1 state.q]), ... % sum of v squared
    repmat(sum(w.^2,1), [state.p 1]), ... % sum of w squared
    v'*w);                                % cross-products v and w
   
% Move stats up in duration
state.stats = circshift(state.stats,[0 0 1 0]);
state.stats(:,:,1,:) = 0;

% Push new stats
state.c = min(state.c+1,state.n);
state.stats(:,:,1:state.c,:) = state.stats(:,:,1:state.c,:) + permute(repmat(stats,[1 1 1 state.c]),[1 2 4 3]);

%--------------------------------------------------------------------------
function corrs = update_corrs(state)

k  = state.m*repmat(permute(1:state.n,[1 3 2]),[state.p state.q 1]);

v  = state.stats(:,:,:,1); % v
w  = state.stats(:,:,:,2); % w
v2 = state.stats(:,:,:,3); % v squared
w2 = state.stats(:,:,:,4); % w squared
vw = state.stats(:,:,:,5); % cross products

corrs = (k.*vw - v.*w) ./ ( (k.*v2-v.^2) .* (k.*w2-w.^2) ).^.5;

corrs(:,:,state.c+1:end) = nan;

%--------------------------------------------------------------------------
function testcase()

% Parameters
N = 60;     % Number of segments data
n = 60;     % Number of segments maximum
m = 180;    % Segment length
p = 36;     % Number of classes
q = 36;     % Number of trials

% Data
v = rand(N*m,p);
w = rand(N*m,q);

% Full
t_outer = tic;
t1 = zeros(1,N);
cs1 = nan(p,q,n,n);
for t = 1:N
    t_inner = tic;
    for d = 1:min(t,n)
        tend   = t*m;
        tstart = 1+tend-d*m;
        tv = v(tstart:tend,:);
        tw = w(tstart:tend,:);
        tv = bsxfun(@minus,tv,mean(tv));
        tw = bsxfun(@minus,tw,mean(tw));
        cs1(:,:,d,t) = tv'*tw ./ sqrt(sum(tv.^2)'*sum(tw.^2));
    end
    t1(t) = toc(t_inner);
end
toc(t_outer)

% Segmented
t_outer = tic;
t2 = zeros(1,N);
cs2 = nan(p,q,n,n);
state = [];
for t = 1:N  
    t_inner = tic;
    tend   = t*m;
    tstart = 1+tend-m;    
    [corrs,state] = jt_correlation(v(tstart:tend,:),w(tstart:tend,:),state,n);
    cs2(:,:,:,t) = corrs;
    t2(t) = toc(t_inner);
end
toc(t_outer)

% Max error
disp(max(abs(cs2(:)-cs1(:))));

% Inner times
figure;
hold on;
plot(1:N,t1,'-');
plot(1:N,t2,'--');
legend({'1','2'});
xlabel('segment');
ylabel('time');