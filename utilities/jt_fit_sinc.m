function yh = jt_fit_sinc(y)
y = y(:);
m = numel(y);
[~,i] = max(y);
y = circshift(y,floor(m/2 - i));

x = linspace(-pi,pi,m)';
p = fminsearch(@sincfit,[1 1 0],[],x,y);
yh = sincfun(x,p(1),p(2),p(3));

%plot(x,y,'-r',x,yh,'-k');

function sse = sincfit(coeff,x,y)
    amp = coeff(1);
    frq = coeff(2);
    sft = coeff(3);
    yh = sincfun(x,amp,frq,sft);
    sse = sum((yh - y).^2);

function y = sincfun(x,amp,frq,sft)
    y = amp .* sinc(frq.*pi.*x + sft.*pi);
         