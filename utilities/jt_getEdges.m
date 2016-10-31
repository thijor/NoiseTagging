function [edges] = jt_getEdges(X)
%[edges] = jt_getEdges(X)
%Extracts the edges of matrix X. Edges are defined as transitions like 01
%and 10 over the columns.
%
% INPUT
%   X = [m n] matrix containing m variables with n samples
%
% OUTPUT
%   edges = [m 2 n] matrix containing n samples for both positive and
%                   negative edges for all n variables
%
% Adapted from function get_edges.m, prof. dr. ir. P. Desain.

% Inout has to be binary
X = jt_x2bin(X);

% Shift X ones in time
shiftX = circshift(X, [1 0]);

% Last bit became first bit, redo
shiftX(1,:) = 0;

% Find edges
edges = permute(cat(3, ...
                     X & ~shiftX,... % On:  01
                    ~X &  shiftX ... % Off: 10
               ), [1 3 2]);