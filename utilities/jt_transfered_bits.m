function [time,bits] = jt_transfered_bits(nclasses,correct,duration,maxtime,deltatime)

time = 0:deltatime:maxtime-deltatime;
bits = zeros(1,numel(time));
duration = cumsum(duration);
for i = 1:numel(correct)
    idx = find(time>=duration(i),1);
    if isempty(idx); idx = numel(time); end
	bits(idx) = (2*correct(i)-1)*log2(nclasses);
end
bits = cumsum(bits);