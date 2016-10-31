function [fbtp] = jt_getfbtp(m,print)
%[fbtp] = jt_getfbtp(m,print)
%Generates the entire set of Feedback Tap Positions belonging to the degree
%(m) of the primitive polynomial.
%
% The Feedback Tap Positions should be connected according to a primitive 
% polynomial (it cannot be factored (i.e. it is prime), and it is a factor 
% of (i.e. can evenly divide) x^(N)+1, where N=2^(M)+1 (the length of the 
% m-sequence). 
% All primitive polynomials that have a degree equal to M are considered to 
% be fine for m-sequence generation.
%
% INPUT
%   m     = [int] degree of polynomial
%   print = [str] verbosity level (0)
%
% OUTPUT
%   fbtp = [cell] cell array of all posible primitive polynomials for m.

if nargin<2||isempty(print); print=0; end

% Check if toolbox is available
if isempty(which('primpoly.m')); error('Communications System Toolbox needed!'); end

% Find all primitive polynomials
poly = gfprimfd(m,'all');
numpoly = size(poly,1);

% Convert to Feedback Tap Positions
set = repmat((m:-1:1),[numpoly 1]).*poly(:,1:end-1);

% Re-arrange small to large
[~,idx] = sort(sum(set,2),'ascend');
set = set(idx,:);

% Convert to cell structure
fbtp = cell(numpoly,1);
for i = 1:numpoly
    [~,~,fbtp{i}] = find(set(i,:));
end

% Print
if print>0
    for i=1:numel(fbtp)
        fprintf('[')
        for j=1:numel(fbtp{i})
            fprintf([num2str(fbtp{i}(j)) ' '])
        end
        fprintf('\b] ');
    end
end
    fprintf('\n')