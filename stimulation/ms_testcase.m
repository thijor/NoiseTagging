function [] = ms_testcase(cfg)
%[] = ms_testcase(cfg)

if nargin==1&&isnumeric(cfg)&&~isempty(cfg);
    do_example(cfg);
    return;
end

if nargin<1||isempty(cfg); cfg=[]; end
stage           = jt_parse_cfg(cfg,'stage','test');
sentence        = jt_parse_cfg(cfg,'sentence','TESTCASE MATRIXSPELLER');
codesfile       = jt_parse_cfg(cfg,'codes','mgold_61_6521.mat');
maxtime         = jt_parse_cfg(cfg,'maxtime',4.2);
framerate       = jt_parse_cfg(cfg,'framerate',60);
targetcolor     = jt_parse_cfg(cfg,'targetcolor'    ,[0.0 1.0 0.0]')*255;
outputcolor     = jt_parse_cfg(cfg,'outputcolor'    ,[0.0 0.3 1.0]')*255;
symbolcolor     = jt_parse_cfg(cfg,'symbolcolor'    ,[1.0 1.0 1.0]')*255;
rsymbolcolor    = jt_parse_cfg(cfg,'rsymbolcolor'   ,[0.0 0.0 0.0]')*255;
backgroundcolor = jt_parse_cfg(cfg,'backgroundcolor',[0.5 0.5 0.5]')*255;
symbols         = jt_parse_cfg(cfg,'symbols',{...
    'A','B','C','D','E','F'; ...
    'G','H','I','J','K','L'; ...
    'M','N','O','P','Q','R'; ...
    'S','T','U','V','W','X'; ...
    'Y','Z','@','$','%','&'; ...
    '#','<','_','!','?','>'});

% Variables
info.top                = '';
info.bottom             = '';
info.completion         = '';
cfg.color_background    = backgroundcolor;
cfg.color_symbol        = symbolcolor;
cfg.color_rsymbol       = rsymbolcolor;
marker                  = [];
target                  = [];
edges                   = [];
save2mp4                = [];
LOOP                    = [];
ncharacters             = numel(sentence);
nsymbols                = numel(symbols);

% Generate codes
codes = [];
load(codesfile);
codes = repmat(codes(:,1:nsymbols),[ceil(maxtime*framerate/size(codes,1)) 1]);
codes = codes(1:maxtime*framerate,:)';

% Generate labels
if strcmp(stage,'train')
    labels = repmat(1:nsymbols,[1 ceil(ncharacters/nsymbols)]);
    labels = labels(1:ncharacters);
    labels = labels(randperm(ncharacters));
else
    labels = 1:ncharacters;
end

% Loop
stimuli.symbols = true(nsymbols,1);
ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
for i = 1:ncharacters
    
    % Pre-trial
    info.bottom = 'Wait a second.';
    stimuli.symbols = true(nsymbols,1);
    if strcmp(stage,'train')
        target = struct('index',labels(i),'color',targetcolor);
    else
        target = [];
    end
    ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
    
    pause(1);
    
    % Trial
    info.bottom = '';
    stimuli.symbols = codes;
    target = [];
    ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
    
    % Post-trial
    stimuli.symbols = true(nsymbols,1);
    if strcmp(stage,'train')
        info.top = '';
        target = struct('index',labels(i),'color',outputcolor);
    else
        info.top = sentence(1:i);
        target = struct('index',find(strcmp(symbols,sentence(i))),'color',outputcolor);
    end
    ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
    
    pause(1);
    
end

% Finish
info.bottom = 'End, thank you.';
stimuli.symbols = true(nsymbols,1);
target = [];
ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);

%--------------------------------------------------------------------------
function [] = do_example(example)
    cfg = [];
    switch example
        case 0
            % Defaults
        case 1
            % Most contrast
            cfg.stage = 'train';
            cfg.codes = 'mgold_61_6521.mat';
            cfg.symbolcolor  = [1 1 1]';
            cfg.rsymbolcolor = [0 0 0]';
        case 2
            % least contrast
            cfg.stage = 'train';
            cfg.codes = 'mgold_61_6521.mat';
            cfg.symbolcolor  = [.5 .5 .5]' + .5^8;
            cfg.rsymbolcolor = [.5 .5 .5]' - .5^8;
        otherwise
            % Defaults
    end
    ms_testcase(cfg);