function [T] = jt_make_taper(type,len,amp,perc)
%[T] = jt_make_taper(type,len,amp,perc)
%
% INPUT
%   type  = [str] type of taper ('revtukey')
%   len   = [1 n] lengths of n tapers (100)
%   amp   = [1 n] amplifier for each taper (1)
%   perc  = [flt] part of window to control (.2)
%
% OUTPUT
%   T = [sum(L) 1]

% Defaults
if nargin<1||isempty(type); type='tukey'; end
if nargin<2||isempty(len); len=100; end
if nargin<3||isempty(type); amp=1; end
if nargin<4||isempty(perc); perc = .2; end

% Check input
if numel(amp)~=numel(len); amp=amp*ones(1,numel(len)); end

% Make taper
switch type
    case 'hanning'
        T = [];
        for i = 1:numel(len)
            T = cat(1,T,amp(i)*(hanning(len(i))));
        end
    case 'tukey'
        T = [];
        for i = 1:numel(len)
            T = cat(1,T,amp(i)*(tukeywin(len(i),perc)));
        end
    case 'revhanning'
        T = [];
        for i = 1:numel(len)
            T = cat(1,T,amp(i)*(1-hanning(len(i))));
        end
    case 'revtukey'
        T = [];
        for i = 1:numel(len)
            T = cat(1,T,amp(i)*(1-tukeywin(len(i),perc)));
        end
    otherwise
        error('Unknown taper: %s.',type);
end