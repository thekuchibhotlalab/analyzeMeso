function handles = fn_loadDir(handles,setVar, textButtonStr)
if ~isfield(handles,'datapath')
    selDir = uigetdir(pwd);
else
    selDir = uigetdir(handles.datapath);
end

set(handles.(textButtonStr),'String', selDir);

handles.(setVar) = selDir;

end 

