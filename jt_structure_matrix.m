function [M] = jt_structure_matrix(E,L,sym)
%[M] = jt_structure_matrix(E,L,sym)
%Creates a structure matrix listing for each event whether the response to
%that event (still) occurs/lasts at a particular point in time.
%
% INPUT
%   E = [s e n] event matrix of [samples events instances]
%   L = [1 e]   length of each event
%
% OPTION
%   sym = [str] whether or not to make symmetric ('off')
%
% OUTPUT
%   M = [s sum(L) n] structure matrix of [samples events instances]

if nargin<3||isempty(sym); sym='off'; end
[m,e,n] = size(E);
if numel(L)==1; L=L*ones(1,e); end

M = zeros(m,sum(L),n);
for i = 1:n
    for j = 1:e
        Mt = toeplitz(E(:,j,i),[E(1,j,i) zeros(1,L(j)-1)]);
        if strcmpi(sym,'on')
            Mt = double(Mt | Mt(:,end:-1:1));
            Mt(:,ceil(L(j)/2)+1:end) = 0;
            M(:,sum(L(1:j-1))+1:sum(L(1:j)),i) = Mt;
        else
            M(:,sum(L(1:j-1))+1:sum(L(1:j)),i) = Mt;
        end
    end      
end
