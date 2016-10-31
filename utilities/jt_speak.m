function time = jt_speak(text,method,speaker)
%vs_speak(text,method,speaker)
%
% INPUT
%   text    = [str] Message to speak ('')
%   method  = [str] Method to use: google|acapela ('acapela')
%   speaker = [str] Speaker to use ('Heather')
%
% OUTPUT
%   time = [flt] time needed to pronounce text approximately

if nargin<1||isempty(text); text=''; end
if nargin<2||isempty(method); method='acapela'; end
if nargin<3||isempty(speaker); speaker='Heather'; end

switch lower(method)
    case 'google'
        warning('Might not work yet!')
        fn = 'audio.mp3';
        command = ['!curl -A "Mozilla" "http://translate.google.com/translate_tts?tl=nl&q=' text ' " > ' fn];
        eval(command);
        [data,fs] = audioread(fn);
        sound(data,fs)
        
    case 'acapela'
        eval(sprintf('!say -v %s ''%s''', speaker, text));
        
    otherwise
        error('Unknown speak method: %s.',method)
end

time = 0.1*numel(text);

% List of speakers
%   Dutch
%       Claire (general)
%       Daan (infovox)
%       Jasmijn (infovox)
%
%   English
%       Alex (general)
%       Victoria (general)
%       Heather (infovox)