function data = fn_getMeanImgBin(filename, x, y, dataType)
    % READSKIPBIN Reads x amount of data, skips y amount from a .bin file
    %
    % Inputs:
    %   filename - The name of the .bin file to read
    %   x - The number of elements to read in each step
    %   y - The number of elements to skip after each read
    %   dataType - The data type of the elements to read (e.g., 'int16', 'double')
    %
    % Output:
    %   data - A vector containing the read data

    % Open the binary file for reading
    fileID = fopen(filename, 'rb');
    if fileID == -1
        error('Cannot open the file: %s', filename);
    end

    % Initialize the output data array
    data = [];

    % Loop until the end of the file
    while ~feof(fileID)
        % Read x elements
        tempData = fread(fileID, x, dataType);
        
        % Append the read data to the output array
        data = [data; tempData];
        
        % If the number of elements read is less than x, break the loop
        if length(tempData) < x
            break;
        end
        
        % Skip y elements
        fseek(fileID, y * getSizeOfDataType(dataType), 'cof');
    end

    % Close the file
    fclose(fileID);
end

function size = getSizeOfDataType(dataType)
    % GETSIZEOFDATATYPE Returns the size of the data type in bytes
    switch dataType
        case {'int8', 'uint8'}
            size = 1;
        case {'int16', 'uint16'}
            size = 2;
        case {'int32', 'uint32', 'single'}
            size = 4;
        case {'int64', 'uint64', 'double'}
            size = 8;
        otherwise
            error('Unsupported data type: %s', dataType);
    end
end