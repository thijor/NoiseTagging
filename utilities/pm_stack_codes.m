function [M] = pm_stack_codes(Ms,Mw,from,to)
%[M] = pm_stack_codes(Ms,Mw,from,to)

ps = size(Ms,2);
pw = size(Mw,2);
is = from:min(ps,to);
iw = mod((max(from-ps,1):max(to-ps,0))-1,pw)+1;
M  = cat(2,Ms(:,is,:),Mw(:,iw,:));