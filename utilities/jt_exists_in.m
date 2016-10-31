function bool = jt_exists_in(classifier,fields)

if ~iscell(fields); fields={fields}; end
if isempty(classifier)
    bool = false;
else
    bool = true;
    for i = 1:numel(fields)
        if ~isfield(classifier,fields{i}) || isempty(classifier.(fields{i}))
            bool = false;
            return;
        end
    end
end