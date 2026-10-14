function T = fn_loadTrialTable(input,variableName)
%FN_LOADTRIALTABLE Accept a table, or load only the named MAT-file variable.
% Metadata calls never fall back to loading sessionInfo from a parsed file.
if istable(input)
    T=input;
else
    assert((ischar(input)||isstring(input))&&isfile(input), ...
        'trialCuration:File','Cannot access the %s file.',variableName);
    data=load(char(input),variableName);
    assert(isfield(data,variableName),'trialCuration:Variable', ...
        'File must contain the %s table. Use its separate metadata file.',variableName);
    T=data.(variableName);
end
assert(istable(T),'trialCuration:Table','%s must be a table.',variableName);
end
