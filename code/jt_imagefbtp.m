function image = jt_imagefbtp(fbtp)
%image = jt_imagefbtp(fbtp)
%
% For every set [L,k,...,p] Feedback Tap Positions, there exists an image
% set (reversed set) of Feedback Tap Positions [L,L-k,...,L-p] that
% generates an identical sequence reversed in time.
%
% INPUT
%   fbtp = [1 m] m feedback tap positions
%
% OUTPUT
%   image = [1 m] m imaged feedback tap positions

L = fbtp(1);
image = sort([L,L-fbtp(2:end)],'descend');