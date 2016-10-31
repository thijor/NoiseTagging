function [pfbtp] = jt_getpfbtp(m,print,check)
%[pfbtp] = jt_getpfbtp(m, check)
%Generates the entire set of Preferred-Pair of Feedback Tap Positions.
%
% INPUT
%   m = [int] degree of polynomial
%
% OPTIONS
%   print = [str] whether or not to print the taps (0)
%   check = [str] whether or not to double-check for 3-valued correlation (0)
%
% OUTPUT
%   pfbtp = [cell] cell array of all combinations of preferred pair of 
%                  primitive polynomials of degree m.

if nargin<2||isempty(print); print=0; end
if nargin<3||isempty(check); check=0; end

% Initialize cell array of preferred Feedback Tap Positions
pfbtp = {};

% Find all Feedback Tap Positions for degree m
fbtp = jt_getfbtp(m);

% Find all combinations of fbtp
cmb = combnk(1:numel(fbtp),2);
if isempty(cmb); return; end

% Find all combinations that form a preferred pair
for i = 1:size(cmb,1)
    if jt_isprefpair(m,fbtp{cmb(i,1)},fbtp{cmb(i,2)})
        pfbtp{end+1,1} = fbtp{cmb(i,1)};
        pfbtp{end  ,2} = fbtp{cmb(i,2)};
    end
end

% Check 3-valued cross-correlations also
numpfbtp = size(pfbtp,1);
if check>0 && numpfbtp>0
    flags = zeros(1,numpfbtp);
    for i = 1:numpfbtp
        golds = jt_make_gold_code(m,pfbtp{i,1},pfbtp{i,2});
        flags(i) = jt_checkxcor(m,golds,golds);
    end
    if any(~flags)
        fprintf('Warning: deleted %d pfbtp!!',sum(~flags))
        pfbtp=pfbtp(flags==1,:);
    end
end

% Print
if print>0
    for i=1:size(pfbtp,1)
        for k=1:2
            fprintf('[')
            for j=1:numel(pfbtp{i,k})
                fprintf([num2str(pfbtp{i,k}(j)) ' '])
            end
            fprintf('\b] ');
        end
        fprintf('\n')
    end
    fprintf('\n')
end