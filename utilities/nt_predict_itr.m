function nt_predict_itr(t, n, a)

pts = 200;
ts = linspace(0.1, 15, pts);
ns = 2:65;
[ts, ns] = ndgrid(ts, ns);

correction = log2(n ./ ns) - log2(t ./ ts);
as = max(1 - (1-a).^(2.^correction), 0);

spms = arrayfun(@(N, P, T) jt_itr(N, P, T, 'spm*'), ns, as, ts);
spm = jt_itr(n, a, t, 'spm*');
spms = min(spms, 4*spm);

subplot(121); hold on;
surf(ts, ns, as);
scatter3(t, n, a, 'LineWidth', 10);

subplot(122); hold on;
surf(ts, ns, spms);
scatter3(t, n, spm, 'LineWidth', 10);

xlabel('Time');
ylabel('Classes');
zlabel('Accuracy');