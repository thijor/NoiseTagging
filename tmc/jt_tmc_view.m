function [classifier] = jt_tmc_view(classifier)
%[classifier] = jt_tmc_view(classifier)
%
% INPUT
%   classifier = [struct] classifier structure
%
% OUTPUT
%   classifier = [struct] classifier with (updated) handle

% Initialize figure
classifier.view = figure(8392);
set(classifier.view,...
    'name'          ,sprintf('jt_tmc_view | %s',classifier.cfg.user),...
    'numbertitle'   ,'off',...
    'toolbar'       ,'none',...
    'menubar'       ,'none',...
    'units'         ,'normalized',...
    'position'      ,[.2 .2 .6 .6],...
    'color'         ,[0.5 0.5 0.5],...
    'visible'       ,'off');

% Transients
subplot(2,3,1:2);
cla(gca);
if jt_exists_in(classifier,'transients')
    L     = floor(classifier.cfg.L*classifier.cfg.fs);
    nL = numel(L);
    colors = hsv(nL);
    labels = cell(1,nL);
    hold on;
    for i = 1:nL
        labels{i} = num2str(i);
        ts = 0:1/classifier.cfg.fs:(L(i)-1)/classifier.cfg.fs;
        ys = mean(classifier.transients(sum(L(1:i-1))+1:sum(L(1:i)),:),2)';
        es = std(classifier.transients(sum(L(1:i-1))+1:sum(L(1:i)),:),[],2)';
        errorbar(ts,ys,es,'color',colors(i,:),'linewidth',1.5);
    end
    set(gca,'xlim',[0 max(classifier.cfg.L)]);
    legend(labels,'location','NorthEast');
end
xlabel('Time [sec]');
ylabel('Amplitude [a.u.] \pm std');
set(gca,'color',[.75 .75 .75],'xgrid','on','ygrid','on');
title('Transient responses');

% Filter
subplot(2,3,3);
cla(gca);
if jt_exists_in(classifier,'filter')
    jt_topoplot(mean(classifier.filter, 2),struct('capfile',classifier.cfg.capfile,'electrodes','numbers'));
else
    set(gca,'xtick',[],'ytick',[],'box','on');
end
set(gca,'color',[.75 .75 .75]);
title('Spatial Filter');

% Margins
subplot(2,3,4:5);
cla(gca);
if jt_exists_in(classifier,'margins')
    xaxis = (1:numel(classifier.margins))*classifier.cfg.segmenttime;
    plot(xaxis,classifier.margins,'-b','linewidth',1.5);
    set(gca,'xlim',[0 max(xaxis)],'ylim',[0 1]);
end
xlabel('Segment length [sec]');
ylabel('Margin');
set(gca,'color',[.75 .75 .75],'xgrid','on','ygrid','on');
title('Stopping Margins');

% Accuracy
subplot(2,3,6);
cla(gca);
if jt_exists_in(classifier,'accuracy') && jt_exists_in(classifier.accuracy,'p')
    text(.2,.7,sprintf('p: %3.2f %% \nt: %3.2f s \nd: %3.2f s',...
        classifier.accuracy.p*100,classifier.accuracy.t,classifier.accuracy.d),'fontsize',16);
end
set(gca,'color',[.75 .75 .75],'xtick',[],'ytick',[],'box','on');
title('Performance Estimate');

% Visualize figure
set(classifier.view,'visible','on');
drawnow;