function selectedIdx = fn_selSession(sessionInfo, method, param)
% selectSessions - Select session indices based on date range, exact date, or session type
%
% Inputs:
%   sessionInfo - table with fields: SessionDate, SessionType, etc.
%   method      - 'dayRange', 'date', or 'type'
%   param       - depends on method:
%                   - 'dayRange': [startDate endDate] (numeric)
%                   - 'date': exact numeric date (single number or array)
%                   - 'type': session type string (e.g. 'hab', 'train')
%
% Output:
%   selectedIdx - indices of matching sessions

switch method
    case 'dayRange'
        if ~isnumeric(param) || numel(param) ~= 2
            error('For ''dayRange'', param must be [startDate endDate]');
        end
        startDate = param(1);
        endDate = param(2);
        selectedIdx = find(sessionInfo.SessionDate >= startDate & sessionInfo.SessionDate <= endDate);

    case 'date'
        if ~isnumeric(param)
            error('For ''date'', param must be numeric date or array of dates');
        end
        selectedIdx = find(ismember(sessionInfo.SessionDate, param));

    case 'type'
        if ~ischar(param) && ~isstring(param)
            error('For ''type'', param must be a string');
        end
        selectedIdx = find(strcmp(sessionInfo.SessionType, param));

    otherwise
        error('Unsupported selection method: %s', method);
end
end
