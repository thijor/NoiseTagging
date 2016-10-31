function [texels,srcRects,dstRects,imgs]=jt_mkTextureCircle(wPtr,symbols,varargin)
%[texels,srcRects,dstRects,imgs]=jt_mkTextureCircle(wPtr,symbols,varargin)
%
% INPUT
%   wPtr    = [int] window pointer
%   symbols = {t s} symbols to display in t circles of s characters
%
% OPTIONS
%   ViewPort         = [1 4] part of screen to use: left,down,right,up
%   BackGroundColor  = [1 3] color of screen background
%   TextSize         = [int] text size
%   TextFont         = [str] text font
%   TextStyle        = [int] text style
%   TextSize         = [int] text size
%   TextColor        = [1 3] text color
%   CircleColor      = [1 3] circle background color
%   CircleFrameColor = [1 3] circle frame color
%   CircleFrameSize  = [int] circle frame size
%
% OUTPUT
%   texels   = [1 w*h] set of handles to the created textures
%   srcRects = [4 w*h] source positions of the strings in the texture
%   dstRects = [4 w*h] position of the strings on the screen for grid layout

% Parameters
if ~iscell(symbols); symbols={symbols}; end
[ntexels,nsymbols] = size(symbols);
if ntexels==1 && nsymbols>1; ntexels=nsymbols; nsymbols=1; end
[ScreenWidth,ScreenHeight] = Screen('WindowSize', wPtr);
TexelWidth  = min([ScreenWidth ScreenHeight])/ntexels*(.9*sqrt(2));
TexelHeight = TexelWidth;

% Defaults
opts = struct(...
    'ViewPort',[0 0 ScreenWidth ScreenHeight],...
    'BackGroundColor',[0 0 0],...
    'TextSize',32,...
    'TextFont','Helvetica',...
    'TextStyle',1,...
    'TextColor',[255 255 255],...
    'CircleColor',[0 0 0],...
    'CircleFrameColor',[0 0 0],...
    'CircleFrameSize',2.5,...
    'AlphaBlend',1);
opts = parseOpts(opts,varargin);
if all(opts.ViewPort<=1 & opts.ViewPort>=0)
    opts.ViewPort = opts.ViewPort .* ...
        [ScreenWidth ScreenHeight ScreenWidth ScreenHeight];
end

% Setup the display font
Screen('TextSize' ,wPtr,opts.TextSize);
Screen('TextColor',wPtr,opts.TextColor);
Screen('TextStyle',wPtr,opts.TextStyle);
Screen('TextFont' ,wPtr,opts.TextFont);

% Get info on the text size, fixs bug in bounding box computation which
% means the heights don't include descenders
charwh = Screen('TextBounds',wPtr,'Hgpq|_^',0,0);
charwh = [round(charwh(3)./numel('Hgpq|_^')) charwh(4)];
width_chr = floor((floor(opts.ViewPort(3)./charwh(1)))./size(symbols,2));

% Convert strings to textures
Screen('FillRect',wPtr,opts.BackGroundColor);
texels = zeros(1,ntexels);
imgs = cell(1,ntexels);
for i = 1:ntexels
    
    if ischar(symbols{i})
        Screen('FillOval',wPtr,opts.CircleColor,...
            [0 0 TexelWidth TexelHeight])
        Screen('FrameOval',wPtr,opts.CircleFrameColor,...
            [0 0 TexelWidth TexelHeight],opts.CircleFrameSize)
        if nsymbols==1
            DrawFormattedText(wPtr,symbols{i},...
                TexelWidth/2-.5*charwh(1),TexelHeight/2-.5*charwh(2),...
                opts.TextColor,width_chr);
        else
            dstRects = get_circular_positions(...
                [0 0 TexelWidth TexelHeight],charwh,nsymbols);
            for j = 1:nsymbols
                DrawFormattedText(wPtr,symbols{i,j},...
                    dstRects(1,j),dstRects(2,j),...
                    opts.TextColor,width_chr);
            end
        end
        texel = Screen('GetImage',wPtr,...
            [0 0 TexelWidth TexelHeight],'backBuffer');
    elseif isnumeric(symbols{i})
        texel = symbols{i};
    end
    
    % Save texel
    imgs{i} = texel;
    if opts.AlphaBlend && ( size(texel,3)==3 || size(texel,3)==1 )
        texel = cat(3,texel,max(texel,[],3));
    end
    texels(i) = Screen('MakeTexture',wPtr,texel);
    
    % Clear screen for next texel
    Screen('FillRect',wPtr,opts.BackGroundColor);
end

% Compute source rectangles
srcRects = repmat([0;0;TexelWidth;TexelHeight],[1,ntexels]);

% Compute destiny rectangles
dstRects = get_circular_positions(...
    opts.ViewPort,[TexelWidth TexelHeight],ntexels);


%--------------------------------------------------------------------------
function positions = get_circular_positions(ViewPort,TexelSize,N)
positions = zeros(4,N);
angles = linspace(-.5*pi,1.5*pi-(2*pi/N),N);
dxy = min([diff(ViewPort([1 3])) diff(ViewPort([2 4]))]);
centers = [1/3*dxy*cos(angles)+mean(ViewPort([1 3]));...
    1/3*dxy*sin(angles)+mean(ViewPort([2 4]))];
positions(1:2,:) = centers - repmat(TexelSize'./2,[1,N]);
positions(3:4,:) = centers + repmat(TexelSize'./2,[1,N]);