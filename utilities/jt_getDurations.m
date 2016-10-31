function [events,durations] = jt_getDurations(X)
%[events,durations] = jt_getDurations(X)
%Extracts the separate events of specific durations in X. The events are
%ordered on increasing duration.
%
% INPUT
%   X = [s n] n variables with s samples
%
% OUTPUT
%   events = [s d n]  matrix containing all d events for all n
%                     variables of m samples. A 1 represents a start of 
%                     that duration.
%   durations = [1 d] array containing the respective durations
%
% Adapted from function get_durations.m, prof. dr. ir. P. Desain.

[r,c] = size(X);

% Get relevant edges
edges = jt_getEdges(X);
[upr,upc]     = find(edges(:,1,:)); %On:  01
[downr,downc] = find(edges(:,2,:)); %Off: 10

% For each variable in X
for i = 1:c
    
    % Get relevant features
    up   = upr(upc==i);
    down = downr(downc==i);
    
    % Take minimum number of features (should be equal on and off)
    numEvents = min(length(up), length(down));

    % Separate different features
    [duration, ~, n] = unique(down(1:numEvents)-up(1:numEvents));

    % If first time, pre-allocate space for events
    if ~exist('events','var')
        events = zeros(r, length(duration), c);
        durations = duration;
        for j = 1:length(duration)  
            events(up(n==j),j, i) = 1;
        end
    % If events differ, re-allocate space and add previous events
    elseif numel(durations)~=numel(duration) || any(durations~=duration)
        fprintf('Warning: Different durations among variables!\n')
        prev = durations;
        durations = unique([prev; duration]);
        tmp = events;
        events = zeros(r, length(durations), c);
        events(:,ismember(durations,prev),:) = tmp;
    end
    
    % Add the new events
    for j = 1:length(duration)  
        events(up(n==j),durations==duration(j), i) = 1;
    end
end

durations = durations';