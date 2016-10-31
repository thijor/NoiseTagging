function z = x2jf(X, fs, capfile, exp, subj, label)
%Converts input to jf-format
%
% INPUT
%   X       = [n-d] data array
%   fs      = [flt] samplerate
%
% OPTIONS
%   capfile = [str] cap to select (cap64.txt)
%   exp     = [str] experiment directory (experiment)
%   subj    = [str] subject name (subject)
%   label   = [str] block name (label)
% 
% OUTPUT
%   z = [struct] the z structure

% Defaults
if nargin<3 || isempty(capfile); capfile='cap64.txt'; end
if nargin<4 || isempty(exp); exp='experiment'; end
if nargin<5 || isempty(subj); subj='subject'; end
if nargin<6 || isempty(label); label='label'; end

% Settings
X  = single(X);
di = mkDimInfo(size(X),'ch',[],[],'time','ms',[],'epoch',[],[]);

% Import to z structure
[z] = jf_import(exp,subj,label,X,di,'fs',fs,'capFile',capfile,'verb',-1);

% All channels are eeg
iseeg(1:64)=true;
[z.di(n2d(z.di,'ch')).extra.iseeg]=num2csl(iseeg);