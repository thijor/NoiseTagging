function jt_plotxcor(v,w)
%jt_plotxcor(v,w)
%
% INPUT
%   v = [m p] matrix of samples by variables
%   w = [m q] matrix of samples by variables

if nargin==1; w=v; end

% Compute correlation
correlation = jt_correlation_loop(v,w,'shift');
[r,c,z] = size(correlation);

% Make sure t=0 is in the middle
correlation = circshift(correlation,[0 0 floor(z/2)]);

% Plot the correlation
x = (1:z)-floor(z/2)-1;
for i = 1:r
    for j = 1:c
        subplot(r,c,(i-1)*r+j);
        plot(x,squeeze(correlation(i,j,:)));
        set(gca,'xlim',[-floor(z/2) ceil(z/2)+1],'ylim',[-1 1]);
        if i~=r || j~=1
            set(gca,'xtick',[],'xticklabel',[],...
                    'ytick',[],'yticklabel',[]); 
        end
    end
end