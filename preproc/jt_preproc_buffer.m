function [state,dat,hdr,evt] = jt_preproc_buffer(state,dat,hdr,evt)
%[state,dat,hdr,evt] = jt_preproc_buffer(state,dat,hdr,evt)
% Preprocessing pipeline directly on the buffer. Follows downsampling,  
% detrending, CAR and spectral filtering.

% Initalise filter states
if state.init
    state.flt = [];
end

% Spectral filter
[state.flt,dat(state.eegchans,:)] = rjv_filter(state.flt,...
    dat(state.eegchans,:),state.filter.family,hdr.Fs,state.filter.passband,...
    state.filter.order,state.filter.type,1,2);

% Detrend
[state,dat] = rjv_detrend(state,dat,hdr);

% Re-reference
[state,dat] = rjv_car(state,dat);

% Downsample
[state,dat,hdr,evt] = rjv_downsample(state,dat,hdr,evt);