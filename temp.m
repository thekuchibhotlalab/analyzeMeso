% Load all variables into a structure, then keep sessions 102–109.
%S = load('stackROI_final_tracked.mat');
Ssubset = fn_subsetSessions(S, 102:109, 203);

% Optional: save the subset as separate variables in a new MAT file.
% save('stackROI_subset.mat', '-struct', 'Ssubset');


function Sout = fn_subsetSessions(S, sessionIdx, nSessions)
    if nargin < 3
        nSessions = 203;
    end

    validateattributes(sessionIdx, {'numeric'}, ...
        {'vector','integer','positive','finite','<=',nSessions});

    Sout = S;
    names = fieldnames(S);

    for k = 1:numel(names)
        name = names{k};
        value = S.(name);
        sessionDims = find(size(value) == nSessions);

        if isempty(sessionDims)
            continue
        end

        indices = repmat({':'}, 1, ndims(value));
        for d = sessionDims
            indices{d} = sessionIdx;
        end

        Sout.(name) = value(indices{:});
        fprintf('%s: %s -> %s\n', name, ...
            mat2str(size(value)), mat2str(size(Sout.(name))));
    end
end