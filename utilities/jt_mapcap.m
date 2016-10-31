function [indices] = jt_mapcap(capin,capout,verbosity)
%[indices] = jt_mapcap(capin,capout,verbosity)
%Maps capin to capout by finding the indices of the electrodes in capout
%that relate to capin.
%
% INPUT
%   capin  = [str] file with electrodes to select subset from
%   capout = [str] file with electrodes to be mapped
%
% OUTPUT
%   indices = [n 1] array with indices such that capin(indices)=capout

if nargin<3||isempty(verbosity); verbosity=0; end

% Open files
fidin = fopen(capin);
fidout = fopen(capout);

% Read files
Cin = textscan(fidin, '%s%d%d');
Cout = textscan(fidout, '%s%d%d');

% Select electrodes
Ein = Cin(1);
Ein = lower(Ein{:});
Eout = Cout(1);
Eout = lower(Eout{:});

% Search indices of Eout in Ein
[~,indices] = ismember(Eout,Ein);

% Close files
fclose(fidin);
fclose(fidout);

% Test correctness
if verbosity>0 
    for i = 1:numel(indices)
        fprintf('\t%s\tmatched with %s\n',...
            Eout{i},Ein{indices(i)})
    end
end