function d=fn_trialCondition(label,dayLabels,taskLabels,stimulus,action,responseTypes)
%FN_TRIALCONDITION One named behavioral condition for a selection preset.
% responseTypes: [] = any, 1 = rewarded, 2 = unrewarded probe.
if nargin<6, responseTypes=[]; end
dayLabels=string(dayLabels); taskLabels=string(taskLabels);
d=struct('name',string(label),'dayLabels',dayLabels(:), ...
    'taskLabels',taskLabels(:),'stimulus',stimulus,'action',action, ...
    'responseTypes',responseTypes);
end
