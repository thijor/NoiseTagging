function [events,switches] = jt_getSwitches(X,state)
%[events,switches] = jt_getSwitches(X,state)
%Extracts the separate events of specific durations in X. The events are
%ordered on increasing duration.
%
% INPUT
%   X = [s n] n variables with s samples
%
% OPTIONS
%   state = [int] 0 if offs, 1 if ons, 2 if both separate, 3 if both
%                 combined
%
% OUTPUT
%   events = [s d n]  matrix containing all d events for all n
%                     variables of m samples. A 1 represents a start of 
%                     that duration.
%   durations = [1 d] array containing the respective switches

if nargin<2 || isempty(state); state=2; end;

% Compute edges
edges = jt_getEdges(X);

switch(state)
    case 0
        events = edges(:,2,:);
        switches = 0;
    case 1
        events = edges(:,1,:);
        switches = 1;
    case 2
        events = edges;
        switches = [1 0];
    case 3
        events = edges(:,1,:)|edges(:,2,:);
        switches = 2;
    otherwise
        error('Unspecified state: %d',state)
end
    