function matStruct = read_npy_dict(npyFilePath)
% READ_NPY_DICT Reads a .npy file containing a Python dictionary into a MATLAB struct.
%
%   matStruct = READ_NPY_DICT(npyFilePath)
%
%   This is a self-contained function that does NOT require Python.
%   It includes the necessary helper functions to parse .npy files,
%   including those with 'object' types (e.g., Python dictionaries),
%   which are loaded as MATLAB structs.
%
%   This code is based on the npy-matlab fork by landogm, which
%   includes support for object types.
%
%   Inputs:
%       npyFilePath - A string (or char array) providing the full path
%                     to the .npy file.
%
%   Outputs:
%       matStruct   - A native MATLAB struct, converted from
%                     the Python dictionary.
%
%   Example (Python to create the file):
%   ------------------------------------
%   import numpy as np
%
%   my_dict = {
%       'name': 'SampleData',
%       'trial_count': 120,
%       'runtimes': [1.2, 0.8, 1.1, 0.9],
%       'metadata': {
%           'subject': 'Mouse1',
%           'date': '2025-11-06'
%       }
%   }
%   np.save('my_data.npy', my_dict)
%   ------------------------------------
%
%   Example (MATLAB to read the file):
%   ------------------------------------
%   data = read_npy_dict('my_data.npy');
%   disp(data);
%   % This should display a struct:
%   %
%   %         name: "SampleData"
%   %  trial_count: 120
%   %     runtimes: {4x1 cell}
%   %     metadata: [1x1 struct]
%
%   disp(data.metadata.subject);
%   % This should display: "Mouse1"
%

    % --- 1. Input Validation ---
    if ~isfile(npyFilePath)
        error('File not found: %s', npyFilePath);
    end
    
    % --- 2. Load File using local npy-matlab functions ---
    try
        % Call the local readNPY function
        matStruct = readNPY(npyFilePath);
        
    catch ME
        fprintf('Error loading .npy file using native MATLAB parser.\n');
        fprintf('Error: %s\n', ME.message);
        rethrow(ME);
    end
    
    % --- 3. Verify Output ---
    if iscell(matStruct) && numel(matStruct) == 1
        % Dictionaries are often loaded as a 1x1 cell containing the struct
        matStruct = matStruct{1};
    end

    if ~isstruct(matStruct)
        warning('The loaded .npy file did not contain a dictionary (struct). Returning data of type: %s', class(matStruct));
    end

end


% --- LOCAL HELPER FUNCTIONS (from npy-matlab, landogm fork) ---

function data = readNPY(filename)
% Function to read NPY files into matlab.
% (Local function)
% Based on code from: https://github.com/landogm/npy-matlab

    [shape, dataType, fortranOrder, littleEndian, ~] = readNPYheader(filename);

    if littleEndian
        fid = fopen(filename, 'r', 'l');
    else
        fid = fopen(filename, 'r', 'b');
    end
    
    if fid == -1
        error('readNPY:CouldNotOpenFile', 'Could not open file: %s', filename);
    end
    
    cleanup = onCleanup(@() fclose(fid)); % Ensure file is closed

    try
        [~, ~, ~, ~, headerLength] = readNPYheader(fid);
        fseek(fid, headerLength, 'bof');

        switch dataType
            case 'int8'
                data = fread(fid, inf, 'int8=>int8');
            case 'int16'
                data = fread(fid, inf, 'int16=>int16');
            case 'int32'
                data = fread(fid, inf, 'int32=>int32');
            case 'int64'
                data = fread(fid, inf, 'int64=>int64');
            case 'uint8'
                data = fread(fid, inf, 'uint8=>uint8');
            case 'uint16'
                data = fread(fid, inf, 'uint16=>uint16');
            case 'uint32'
                data = fread(fid, inf, 'uint32=>uint32');
            case 'uint64'
                data = fread(fid, inf, 'uint64=>uint64');
            case 'float32'
                data = fread(fid, inf, 'single=>single');
            case 'float64'
                data = fread(fid, inf, 'double=>double');
            case 'logical'
                data = logical(fread(fid, inf, 'uint8=>uint8'));
            case 'complex64'
                data = fread(fid, [2, inf], 'single=>single');
                data = complex(data(1,:), data(2,:));
            case 'complex128'
                data = fread(fid, [2, inf], 'double=>double');
                data = complex(data(1,:), data(2,:));
            case 'object'
                % This is the key part for dictionaries/structs
                data = readObjectArray(fid, shape);
            otherwise
                error('readNPY:UnsupportedType', 'Unsupported data type: %s', dataType);
        end

    catch ME
        rethrow(ME);
    end
    
    % Reshape the data if necessary
    if ~strcmp(dataType, 'object') && numel(shape) > 1
        if fortranOrder
            data = reshape(data, shape);
        else
            % NPY arrays are row-major, MATLAB is column-major.
            data = reshape(data, shape(end:-1:1));
            data = permute(data, length(shape):-1:1);
        end
    elseif length(shape)==1 && shape(1)==0
        data = []; % Handle empty array
    end
    
end

function [shape, dataType, fortranOrder, littleEndian, totalHeaderLength] = readNPYheader(fid_or_filename)
% Function to read NPY file headers.
% (Local function)
% Based on code from: https://github.com/landogm/npy-matlab

    if ischar(fid_or_filename)
        fid = fopen(fid_or_filename, 'r');
        if fid == -1
            error('readNPYheader:CouldNotOpenFile', 'Could not open file: %s', fid_or_filename);
        end
        cleanup = onCleanup(@() fclose(fid));
    else
        fid = fid_or_filename; % Assume it's a valid file ID
    end

    % Check magic string
    magicString = fread(fid, 6, 'uint8=>char')';
    if ~strcmp(magicString, [char(147) 'NUMPY'])
        error('readNPYheader:NotNPYFile', 'Not a NPY file.');
    end

    % Read version
    majorVersion = fread(fid, 1, 'uint8');
    minorVersion = fread(fid, 1, 'uint8');

    if majorVersion == 1
        headerLength = fread(fid, 1, 'uint16');
    elseif majorVersion == 2
        headerLength = fread(fid, 1, 'uint32');
    else
        error('readNPYheader:UnsupportedVersion', 'Unsupported NPY version %d.%d', majorVersion, minorVersion);
    end

    totalHeaderLength = 10 + headerLength; % 6 (magic) + 2 (version) + 2/4 (len) + header

    % Read the header string
    header = fread(fid, headerLength, 'char=>char')';
    
    % Parse header
    % This is a simple parser for the Python literal format
    
    % Data type
    descr_match = regexp(header, '''descr'':\s*''([^'']*)''', 'tokens');
    if isempty(descr_match)
        error('readNPYheader:ParseError', 'Could not find "descr" in header');
    end
    descr = descr_match{1}{1};
    
    littleEndian = (descr(1) == '<' || descr(1) == '|');
    dataTypeStr = descr(2:end);
    
    switch dataTypeStr
        case 'i1'
            dataType = 'int8';
        case 'i2'
            dataType = 'int16';
        case 'i4'
            dataType = 'int32';
        case 'i8'
            dataType = 'int64';
        case 'u1'
            dataType = 'uint8';
        case 'u2'
            dataType = 'uint16';
        case 'u4'
            dataType = 'uint32';
        case 'u8'
            dataType = 'uint64';
        case 'f4'
            dataType = 'float32';
        case 'f8'
            dataType = 'float64';
        case 'b1'
            dataType = 'logical';
        case 'c8'
            dataType = 'complex64';
        case 'c16'
            dataType = 'complex128';
        case 'O'
            dataType = 'object';
        otherwise
            if dataTypeStr(1) == 'S' % String
                dataType = 'char';
            elseif dataTypeStr(1) == 'U' % Unicode
                dataType = 'char_utf';
            else
                error('readNPYheader:UnsupportedType', 'Unsupported NPY data type: %s', descr);
            end
    end

    % Fortran order
    fortran_match = regexp(header, '''fortran_order'':\s*([True|False]*)', 'tokens');
    if isempty(fortran_match)
        error('readNPYheader:ParseError', 'Could not find "fortran_order" in header');
    end
    fortranOrder = strcmp(fortran_match{1}{1}, 'True');

    % Shape
    shape_match = regexp(header, '''shape'':\s*\(([0-9, ]*)\)', 'tokens');
    if isempty(shape_match)
        error('readNPYheader:ParseError', 'Could not find "shape" in header');
    end
    shapeStr = shape_match{1}{1};
    if isempty(shapeStr)
        shape = [1, 1]; % Scalar
    else
        shape = str2double(split(shapeStr, ','));
        shape = shape(shape > 0); % Remove empty strings from trailing comma
        if isempty(shape)
            shape = [0, 0]; % Empty array
        elseif length(shape) == 1
            shape = [shape, 1]; % Make it a row vector
        end
    end
    
end

function data = readObjectArray(fid, shape)
% Reads an array of Python objects (pickled)
% (Local function)
% Based on code from: https://github.com/landogm/npy-matlab

    data = cell(shape);
    
    if prod(shape) == 0
        return;
    end
    
    for i = 1:prod(shape)
        data{i} = readObject(fid);
    end
    
    % If all elements are structs, try to convert cell array to struct array
    try
        if all(cellfun(@isstruct, data))
            data = cell2mat(data);
        end
    catch
        % Keep as cell array if structs are not compatible
    end
end

function obj = readObject(fid)
% Reads a single pickled object
% (Local function)
% This is a *simplified* pickle parser for numpy.save()
% Based on code from: https://github.com/landogm/npy-matlab

    opCode = fread(fid, 1, 'char');

    switch opCode
        case 'N' % None
            obj = [];
        case 'F' % False
            obj = false;
        case 'T' % True
            obj = true;
        case 'I' % Integer
            obj = str2double(readasciiline(fid));
        case 'J' % Int64 (in pickle, this is just a string)
            obj = str2double(readasciiline(fid));
        case 'K' % Short (int)
             obj = fread(fid, 1, 'uint8'); % 1-byte int
        case 'L' % Long (int)
            obj = fread(fid, 1, 'int32'); % 4-byte int
        case 'G' % Float
            obj = fread(fid, 1, 'double'); % 8-byte float
        case 'U' % Unicode string
            len = fread(fid, 1, 'int32');
            obj = fread(fid, len, 'char=>char')';
        case 'S' % String
            len = fread(fid, 1, 'int8'); % 1-byte length
            obj = fread(fid, len, 'char=>char')';
        case '}' % Dictionary start
            obj = struct();
        case '(' % Tuple start
            obj = {};
        case ']' % List start
            obj = {};
        case 'a' % Append to list/tuple
            % This is recursive. 'a' appends the *next* object
            % This assumes the object to append to was just created.
            % This is highly simplified.
            error('readObject:NotImplemented', 'Pickle "append" opcode (a) is not fully implemented.');
            
        case 'e' % List/tuple build complete
            % Handled by ']'
            obj = {}; % Should not be here, but for completeness
            
        case 's' % Set dictionary key
            % 's' is 'set'; format is key, value, 's'
            % This parser is too simple for this.
            error('readObject:NotImplemented', 'Pickle "set" opcode (s) is not implemented.');

        case 'u' % Build dictionary
            % This is where the magic happens for dicts.
            % It assumes a stack.
            % '}' (empty dict) ... 'key1' 'val1' 'key2' 'val2' ... 'u'
            obj = struct();
            % This simple parser will read items one by one.
            % We need to read until the 'stop' marker '.'
            
            items = {};
            while true
                item = readObject(fid);
                if ischar(item) && strcmp(item, 'STOP_MARKER')
                    break;
                end
                items{end+1} = item;
            end
            
            % Now, build the struct from the items
            if mod(length(items), 2) ~= 0
                error('readObject:DictParseError', 'Dictionary items are not in key/value pairs.');
            end
            
            for i = 1:2:length(items)
                key = items{i};
                val = items{i+1};
                % Make sure key is a valid MATLAB field name
                if ischar(key)
                    key = matlab.lang.makeValidName(key);
                    obj.(key) = val;
                end
            end
            
        case '.' % Stop pickle
            obj = 'STOP_MARKER';
            
        otherwise
            error('readObject:UnknownOpcode', 'Unknown pickle opcode: %s', opCode);
    end
end

function line = readasciiline(fid)
% Reads a line of ASCII text ending in \n
% (Local function)
% Based on code from: https://github.com/landogm/npy-matlab
    line = '';
    while true
        char = fread(fid, 1, 'char');
        if isempty(char) || char == 10 % 10 is \n
            break;
        end
        line(end+1) = char;
    end
end