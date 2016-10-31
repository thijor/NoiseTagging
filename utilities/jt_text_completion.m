function [completion,prediction,err] = jt_text_completion(sentence)
%[completion] = jt_text_completion(sentence)
%
% INPUT
%   sentence = [str] sentence to be auto-completed, may contain any
%                    character or token. Tokens are replaced by white-space
%   
% OUTPUT
%   completion = [str]   the part of prediction to complete sentence
%   prediction = [str]   the prediction
%   err        = [error] whether or not an error occured

% Clean up sentence (remove tokens)
sentence(~isstrprop(sentence,'alpha')) = ' ';

% Predict word
[prediction,~,err] = soothsayer(sentence);

% Catch error while predicting
if ~isempty(err) || isempty(prediction) || strcmpi(prediction,'i give up')
    fprintf('\tjt_text_completion: \tprediction failed.\n'); 
    if ~isempty(err); fprintf('\tjt_text_completion: '); disp(err); end
    completion = '';
    prediction = '';
    err = 1;
    return;
end

% Extract completion
words = strtokall(sentence,' ');
completion = [prediction(numel(words{end})+1:end) ' '];
err = 0;