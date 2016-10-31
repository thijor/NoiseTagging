function [Obj] = jt_printmessage(Obj,message,cnfcls)
%[Obj] = jt_printmessage(Obj,message)
%Prints message in a automatically down-scrolling panel.
%
% INPUT
%   Obj     = [struct] .fig : figure ([])
%                      .pan : panel
%                      .list: list with text 
%   message = [str]    the message to put into the list ('')
%   cnfcls  = [str]    ask for confirmation if close window is pressed (off)
%
% OUTPUT
%   Obj = [struct] updated figure, panel and list

% Defaults
if nargin<1||isempty(Obj); Obj=[]; end
if nargin<2||isempty(message); message=''; end
if nargin<3||isempty(cnfcls); cnfcls='off'; end

% Initialize
if isempty(Obj)
    Obj.fig = figure(10);
    set(Obj.fig,...
        'name'              ,'',...             % Title in figure header
        'numbertitle'       ,'off',...          % No figure number in header
        'menubar'           ,'none',...         % No menu bar
        'toolbar'           ,'none',...         % No tool bar
        'units'             ,'normalized',...   % Normalize units
        'position'          ,[0 0 .25 1]);      % Set position and width of figure
    
    % If close figure is pressed, promt confirmation
    if strcmpi(cnfcls,'on')
        set(Obj.fig,'CloseRequestFcn',@confirmclose);
    end
    
    Obj.pan = uipanel(Obj.fig,...
        'Title'             ,'',...             % Title of panel
        'Units'             ,'normalized',...   % Normalize units
        'Position'          ,[.05 .05 .9 .9]);  % Set position and width of panel

    Obj.list = uicontrol(Obj.pan,...
        'Style'             ,'edit',...         % Text output with scroll bar
        'Units'             ,'normalized',...   % Normalize units
        'Position'          ,[0 0 1 1],...      % Set position and width of text area
        'HorizontalAlign'   ,'left',...         % Allign text left
        'Fontsize'          ,11,...             % Font size
        'Min'               ,0,...              % Number of text rules
        'Max'               ,2,...              % Number of text rules
        'enable'            ,'inactive');       % Disable editing text
    
    % Enable horizontal scrolling
    jlist = findjobj(Obj.list);
    jedit = jlist.getViewport().getComponent(0);
    jedit.setWrapping(false);                
    jedit.setEditable(false);                
    set(jlist,'HorizontalScrollBarPolicy',30);
    hjedit = handle(jlist,'CallbackProperties');
    set(hjedit,'ComponentResizedCallback',...
        'set(gcbo,''HorizontalScrollBarPolicy'',30)')
end

% Format message
if ~isempty(message)
    message = textscan(message,'%s',...
        'Delimiter','\n',...
        'Whitespace','');
    message = message{1};
end
if ~iscell(message)
    message = {message};
end
        
% Append message
set(Obj.list,'string',cat(1,get(Obj.list,'string'),message))

% Set automaticallt scroll down property
jlist = findjobj(Obj.list);
jedit = jlist.getComponent(0).getComponent(0);
jedit.setCaretPosition(jedit.getDocument.getLength);

end

% If close figure is pressed, promt confirmation
function confirmclose(src,evnt)
   selection = questdlg('Close This Figure?',...
      'Close Figure Confirmation',...
      'Yes','No','Yes'); 
   switch selection
      case 'Yes'; delete(gcf);
      case 'No' ; return;
   end
end