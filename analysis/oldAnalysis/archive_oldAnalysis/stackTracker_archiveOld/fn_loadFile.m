function handles = fn_loadFile(handles,setVar, textButtonStr)
if ~isfield(handles,'datapath')
    selDir = uigetfile(pwd);
else
    selDir = uigetfile(handles.datapath);
end

tempFilename = strsplit(selDir,filesep); 
set(handles.(textButtonStr),'String', tempFilename{end});

handles.(setVar) = selDir;

end 

