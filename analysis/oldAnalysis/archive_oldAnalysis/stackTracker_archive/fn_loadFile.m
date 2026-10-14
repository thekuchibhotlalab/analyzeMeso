function handles = fn_loadFile(handles,setVar, textButtonStr)
if ~isfield(handles,'datapath')
    [selname, selDir] = uigetfile([pwd filesep '*.*']);
    selDir = [selDir filesep selname];
else
    [selname, selDir] = uigetfile([handles.datapath filesep '*.*']);
    selDir = [selDir filesep selname];
end

tempFilename = strsplit(selDir,filesep); 
set(handles.(textButtonStr),'String', tempFilename{end});

handles.(setVar) = selDir;

end 

