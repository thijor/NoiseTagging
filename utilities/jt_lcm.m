function [lcm] = jt_lcm(varargin)
%[lcm] = jt_lcm(varargin)
%Computes the least common multiple
% 
% INPUT
%   varargin = [1 n] cell-array of all n numbers
%            = [1 n] vector of all n numbers
%
% OUTPUT
%   lcm = [int] the least common multiple of all n inputed integers

% Check input
set = cell2mat(varargin);
if any(round(set)~=set | set<1)
    error('Invalid input, should be round and positive');
end
set(end+1) = 1;
n = numel(set);

% Calculate prime factorizations
t = cell(n, 1);
for i = 1:n
    t{i} = factor(set(i));
end

% Calculate max prime
p = zeros(n, 1);
for i = 1:n
    p(i) = max(t{i});
end

% Create a list of primes
pr = primes(max(p));

% Calculate occurences
o = zeros(n, numel(pr));
for i = 1:n
    s = t{i};
    for j = 1:numel(s)
        o(i, pr==s(j)) = o(i, pr==s(j)) + 1;
    end    
end

% Calculate lcm
lcm = prod(nonzeros(pr.^max(o)));