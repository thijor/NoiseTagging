function [E,e] = jt_event_matrix(V,event)
%[E,ret] = jt_event_matrix(V,event)
%Creates a event matrix listing for each event whether it occurs at a 
%particular point in time. 
%
% INPUT
%   V     = [s n] bit-sequence of [samples instances]
%   event = [str] type of event ('sequence')
%                   sequence : Each 1-bit is an event
%                   duration : Each 1-run-length is an event
%                   alldurations : Each 1-run-length of each bit-value is an event
%                   interval : Each length of a 1-bit to a subsequent 1-bit is an event
%                   rise     : Each 0-bit to 1-bit transition is an event
%                   fall     : Each 1-bit to 0-bit transition is an event
%                   risefall : Include both rise and fall as separate events
%                   switch   : Include both rise and fall as same events
%
% OUTPUT
%   E = [s e n] event matrix of [samples events instances]
%   e = [e 1]   length of events

if nargin<2||isempty(event); event='sequence'; end

switch(lower(event))
    case 'sequence'
        % Each 1-bit is an event
        E = permute(V,[1 3 2]);
        e = 1;
    case 'duration'
        % Each 1-run-length is an event
        [E,e] = get_durations(V);
    case 'alldurations'
        % Each 1-run-length of each bit-value is an event
        [E1,e1] = get_durations(V);
        [E2,e2] = get_durations(~V);
        E = [E1, E2];
        e = [e1; e2];
    case 'interval'
        % Each length of a 1-bit to a subsequent 1-bit is an event
        shiftV = circshift(V,[1 0]);
        shiftV(1,:) = 0;
        rise = V & ~shiftV;
        V = ones(size(V));
        V(circshift(rise,[-1 0])) = 0;
        [E,e] = get_durations(V);
        e = e + 1;
    case 'rise'
        % Each 0-bit to 1-bit transition is an event
        E = get_edges(V);
        E = E(:,1,:);
        e = 1;
    case 'fall'
        % Each 1-bit to 0-bit transition is an event
        E = get_edges(V);
        E = E(:,2,:);
        e = 1;
    case 'risefall'
        % Include both rise and fall as separate events
        E = get_edges(V);
        e = [1 1];
    case 'switch'
        % Include both rise and fall as same events
        E = get_edges(V);
        E = E(:,1,:) | E(:,2,:);
        e = 1;
    otherwise
        error('Unknown cfg.event: %s',event)
end

E = double(E);
e = e(:);

%--------------------------------------------------------------------------
function [E] = get_edges(V)
    % Shift 1 bit
    shiftV = circshift(V,[1 0]);
    shiftV(1,:) = 0;
    
    % Find edges
    E = permute(cat(3,V & ~shiftV,~V & shiftV),[1 3 2]);

%--------------------------------------------------------------------------
function [D,ret] = get_durations(V)
    [r,c] = size(V);

    % Get relevant edges
    E = get_edges(V);
    [upr,upc]     = find(E(:,1,:)); %On:  01
    [downr,downc] = find(E(:,2,:)); %Off: 10

    % For each variable in V
    for i = 1:c

        % Get relevant features
        up   = upr(upc==i);
        down = downr(downc==i);

        % Take minimum number of features (should be equal on and off)
        N = min(length(up), length(down));

        % Separate different features
        [d,~,n] = unique(down(1:N)-up(1:N));

        % If first time, pre-allocate space for events
        if ~exist('D','var')
            D = zeros(r, length(d), c);
            ret = d;
            for j = 1:length(d)  
                D(up(n==j),j,i) = 1;
            end
        % If events differ, re-allocate space and add previous events
        elseif numel(ret)~=numel(d) || any(ret~=d)
            %fprintf('Warning: Different durations among variables!\n')
            prev = ret;
            ret = unique([prev;d]);
            tmp = D;
            D = zeros(r,length(ret),c);
            D(:,ismember(ret,prev),:) = tmp;
        end

        % Add the new events
        for j = 1:length(d)  
            D(up(n==j),ret==d(j),i) = 1;
        end
    end