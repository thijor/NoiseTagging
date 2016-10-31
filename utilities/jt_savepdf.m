function jt_savepdf(fig,name)

if nargin<1||isempty(fig); fig=gcf; end
if nargin<2||isempty(name); name='jt_savepdf'; end

set(fig,'Units','Centimeters','PaperUnits', 'Centimeters')
pos = get(fig,'position');
set(fig,'PaperSize',pos(3:4),'PaperPositionMode','manual',...
    'PaperPosition',[0 0 pos(3:4)],'renderer', 'painters');
print(gcf,'-dpdf',sprintf('%s.pdf',name));