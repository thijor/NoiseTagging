function [VBLTimestamp, missed] = draw_texture(w,tex,verb,tstart,I,marker,varargin)
% 		% frame flip interval time
% 		I = 1/59.8834;
% marker.name       : name of marker to send
% marker.source     : name of marker destination source

if nargin<6; marker=[]; end

persistent Missed;
persistent prevFrame; % previous frame number
persistent tijd;

if isempty(Missed) || nargin==0
    Missed.idxs    = [];
    Missed.number  = 0;
    Missed.idx     = 0;
    prevFrame      = [];
    tijd           = GetSecs();
    missed         = Missed;
    return
end

% update counter
Missed.idx = Missed.idx + 1;

when      = 0;	% draw at first possible flip (0)
dontclear = 0;	% 1: do not clear buffer, 0: clear buffer
dontsync  = 0;	% sync to vertical retrace and pause script execution until flip has happened (0)

Screen('DrawTextures'   , w, tex, varargin{:});
Screen('DrawingFinished', w, dontclear, 0);

% Send screen
[VBLTimestamp,~,~,mis] = Screen('Flip',w,when,dontclear,dontsync);

% Send marker
if ~isempty(marker)
    if strcmp(marker.type, 'hardware')
        bs_send_hardware_marker(marker.name,marker.source);
    elseif strcmp(marker.type, 'software')
        bs_send_buffer_marker([], marker.name, marker.source, 0, 'now');
    else
        error('Marker type should be either "hardware" or "software"');
    end
end

% Check timing
frame=(GetSecs-tijd)/I;
if mis>0
    if ~isempty(prevFrame)
        number_missed = round(frame)-(prevFrame+1);
        Missed.number = Missed.number + number_missed;
        Missed.idxs = [Missed.idxs Missed.idx:(Missed.idx+number_missed-1)];
    else
        Missed.number = Missed.number+1;
        Missed.idxs = [Missed.idxs Missed.idx];
    end
end
prevFrame = round(frame);
missed = Missed;

% Print check
if verb
    if Missed.number>0
        out = 2;
    else
        out = 1;
    end
    fprintf(out,'tframes=%f, nframes=%d, nmissed=%d, rate=%fs,%fhz\n',frame,prevFrame,Missed.number,VBLTimestamp-tstart,1/(VBLTimestamp-tstart)); 
end