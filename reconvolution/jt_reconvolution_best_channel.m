function [val,idx] = jt_reconvolution_best_channel(X,T,y)

[nchannels,nsamples,ntrials] = size(X);
correlations = zeros(1,nchannels);
for i = 1:nchannels
    v = reshape(X(i,:,:),[nsamples*ntrials 1]);
    w = reshape(T(i,:,y),[nsamples*ntrials 1]);
    correlations(i) = jt_correlation(v,w);
end
[val,idx] = sort(correlations,'descend');