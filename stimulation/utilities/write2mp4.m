function write2mp4( vimgs,save2mp4 )
%write2mp4( vimgs,save2mp4 )
%Writes images to an file
% 
% INPUT
%   vimgs       = [n 1] cell array with images
%   save2mp4    = [struct] saving info
%       .filename   = [str] where to save video
%       .format     = [str] format of video, also see VideoWriter()
%       .framerate  = [int] frames per second

if isempty(save2mp4) || isempty(vimgs)
    return;
end

% add date-time timestamp to filename
timestamp=datestr(now,30);
[p,f,~] = fileparts(save2mp4.filename);
filename = fullfile(p,[f '_' timestamp]);

% Prepare the new file.
vidObj = VideoWriter(filename,save2mp4.format);
vidObj.FrameRate = save2mp4.framerate;
open(vidObj);

% writing video frames to file
fprintf('writing video frames to file....\n');

% Create an animation.
frame = struct('cdata',[],'colormap',[]);
for i = 1:numel(vimgs)
    frame.cdata=vimgs{i};
    % Write each frame to the file.
    writeVideo(vidObj,frame);
end

% Close the file.
close(vidObj);
fprintf('Video file: ''%s'' created\n',filename);

end

