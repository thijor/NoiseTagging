function [occurence,runlengths] = jt_checkrunlength(var,trg)
%[occurence,runlengths] = jt_checkrunlength(var)
%Computes the number of occurence for each runlength within all variables
%
% INPUT
%   var = [m n] matrix of n variables of m samples
%   trg = [int] all runs, only ones, or only zeros (2)
%
% OUTPUT
%   occurence  = [r n] for all n variables the number of occurence of r runs
%   runlengths = [r 1] the length of all r runs

if nargin<2||isempty(trg); trg = 2; end

% Input has to be binary
var = jt_x2bin(var);

% Shift var
shiftvar = circshift(var, [1 0]);
shiftvar(1,:) = 0;

% Find switches
[upr   ,upc]   = find( var & ~shiftvar);
[downr ,downc] = find(~var &  shiftvar);

% Find runlengths and occurences
runlengths = [];
[r,c] = size(var);
for i=1:c
    
    % Get all variations listed, including first and last bit
    switches = sort([upr(upc==i) ; downr(downc==i)]);
    switches = unique([1;switches;r+1]);
    contrast = diff(switches);
    
    % Select target runs
    if trg<2
        if (trg==1 && var(1,i)==1) || (trg==0 && var(1,i)==0)
            contrast = contrast(1:2:end);
        else
            contrast = contrast(2:2:end);
        end
    end
    
    % Count different variations
    if isempty(runlengths)
        runlengths = unique(contrast);
        occurence = zeros(length(runlengths), c);
    elseif ~isequal(runlengths,unique(contrast))
        prev = runlengths;
        runlengths = unique([prev; contrast]);
        tmp = occurence;
        occurence = zeros(length(runlengths), c);
        occurence(ismember(runlengths,prev),:) = tmp;
    end 
    
    % Count variations per run
    for j=1:length(runlengths)
        occurence(j,i) = sum(contrast==runlengths(j));
    end
    
end