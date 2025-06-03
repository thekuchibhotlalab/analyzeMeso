function sessionTable = fn_organizeTxt(filePath)

filenames = dir([filePath filesep '*.txt']);

% Assume inputTable is your structure/table with a field called 'date' and filenames
nFiles = height(filenames);

% Initialize output variables
SessionDate = zeros(nFiles,1);
SessionType = strings(nFiles,1);
SessionNumber = nan(nFiles,1);
CoreFilename = strings(nFiles,1);
Year = nan(nFiles,1);
Month = nan(nFiles,1);
Day = nan(nFiles,1);
Hour = nan(nFiles,1);
Minute = nan(nFiles,1);
Second = nan(nFiles,1);

for i = 1:nFiles
    % --- Parse filename ---
    % Example filename: 'ch_20240510_2AFCsession3_frame.txt'
    name = filenames(i).name;  % Assuming 'ch' is the filename column
    parts = split(name, '_');
    
    if numel(parts) >= 3
        % Extract session date (as number)
        dateStr = parts{2};  % '20240510'
        SessionDate(i) = str2double(dateStr);

        % Extract session type (e.g., '2AFC')
        rawSession = parts{3};  % e.g., '2AFCsession3'
        sessionParts = regexp(rawSession, '(?<type>.*)session(?<num>\d+)', 'names');
        if ~isempty(sessionParts)
            SessionType(i) = sessionParts.type;
            SessionNumber(i) = str2double(sessionParts.num);
        end

        % Build core filename up to third component
        CoreFilename(i) = [filePath filesep strjoin(parts(1:3), '_')];
        
    end

    % --- Parse date info from input table ---
    if ~isempty(filenames(i).date)
        dt = datetime(filenames(i).date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
        Year(i) = year(dt);
        Month(i) = month(dt);
        Day(i) = day(dt);
        Hour(i) = hour(dt);
        Minute(i) = minute(dt);
        Second(i) = second(dt);
    end
end

% Find unique CoreFilenames and keep only the first occurrence
[uniqueCoreFilenames, ia] = unique(CoreFilename, 'stable');

% Construct output table using only unique indices
sessionTable = table(...
    SessionDate(ia), ...
    SessionType(ia), ...
    SessionNumber(ia), ...
    CoreFilename(ia), ...
    Year(ia), Month(ia), Day(ia), ...
    Hour(ia), Minute(ia), Second(ia), ...
    'VariableNames', { ...
        'SessionDate', 'SessionType', 'SessionNumber', 'CoreFilename', ...
        'Year', 'Month', 'Day', 'Hour', 'Minute', 'Second' ...
    });

end 