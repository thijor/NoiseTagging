%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The BrainStream software is free but copyrighted software, distributed  %
% under the terms of the GNU General Public Licence as published by       %
% the Free Software Foundation (either version 2, or at your option       %
% any later version). See the file COPYING.txt in the main BrainStream    %
% folder for more details.                                                %
%                                                                         %
% Copyright (C) 2009, Philip van den Broek                                %
% Donders Institute for Brain, Cognition and Behaviour                    %
% Radboud University Nijmegen, The Netherlands                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function splittedentry = strtokall(entry,token)
if iscell(entry), entry = char(entry); end
splittedentry = {};
while ~isempty(entry)
	if isempty(token)
		[splittedentry{end+1}, entry] = strtok(entry);
	else
		[splittedentry{end+1}, entry] = strtok(entry,token);
	end
end
% remove leading and trailing space
splittedentry = strtrim(splittedentry);
