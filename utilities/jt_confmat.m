function [X] = jt_confmat(labels,predictions,classnames)

if nargin<3||isempty(classnames); classnames=1:numel(unique(labels)); end
labels = classnames(labels);
predictions = classnames(predictions);

% Compute confusion matrix
[X,classnames] = confusionmat(labels,predictions);
X = bsxfun(@rdivide, X, sum(X,2))*100;

% plot
image(X);
axis equal tight;
colormap(1-gray);
set(gca, 'XTick', 1:length(classnames), 'XTickLabel', classnames);
set(gca, 'YTick', 1:length(classnames), 'YTickLabel', classnames);
set(gca, 'TickLength', [0 0]);
xlabel('Predicted class label');
ylabel('Class label');
title('Confusion matrix (percentages)')

% Add labels
for i = 1:size(X,1)   
    for j = 1:size(X,2)
        text(j, i, num2str(X(i,j)),'Color','r','HorizontalAlignment','center');        
    end
end