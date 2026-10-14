function varargout = stackTrackerGUI(varargin)
% STACKTRACKERGUI MATLAB code for stackTrackerGUI.fig
%      STACKTRACKERGUI, by itself, creates a new STACKTRACKERGUI or raises the existing
%      singleton*.
%
%      H = STACKTRACKERGUI returns the handle to a new STACKTRACKERGUI or the handle to
%      the existing singleton*.
%
%      STACKTRACKERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STACKTRACKERGUI.M with the given input arguments.
%
%      STACKTRACKERGUI('Property','Value',...) creates a new STACKTRACKERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before stackTrackerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to stackTrackerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help stackTrackerGUI

% Last Modified by GUIDE v2.5 10-Apr-2024 18:27:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @stackTrackerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @stackTrackerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before stackTrackerGUI is made visible.
function stackTrackerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to stackTrackerGUI (see VARARGIN)

% Choose default command line output for stackTrackerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes stackTrackerGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = stackTrackerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in refButton.
function refButton_Callback(hObject, eventdata, handles)
% hObject    handle to refButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadFile(handles,'refName', 'refText');
guidata(hObject,handles);

% --- Executes on button press in currButton.
function currButton_Callback(hObject, eventdata, handles)
% hObject    handle to currButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadFile(handles,'currName', 'currText');
guidata(hObject,handles);



% --- Executes on button press in MLbutton1.
function MLbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to MLbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadFile(handles,'MLname1', 'MLtext1');
guidata(hObject,handles);


function MLedit1_Callback(hObject, eventdata, handles)
% hObject    handle to MLedit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MLedit1 as text
%        str2double(get(hObject,'String')) returns contents of MLedit1 as a double


% --- Executes during object creation, after setting all properties.
function MLedit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MLedit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MLbutton2.
function MLbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to MLbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadFile(handles,'MLname2', 'MLtext2');
guidata(hObject,handles);



function MLedit2_Callback(hObject, eventdata, handles)
% hObject    handle to MLedit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MLedit2 as text
%        str2double(get(hObject,'String')) returns contents of MLedit2 as a double


% --- Executes during object creation, after setting all properties.
function MLedit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MLedit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in APbutton1.
function APbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to APbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function APedit1_Callback(hObject, eventdata, handles)
% hObject    handle to APedit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of APedit1 as text
%        str2double(get(hObject,'String')) returns contents of APedit1 as a double
handles = fn_loadFile(handles,'APname1', 'APtext1');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function APedit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to APedit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in APbutton2.
function APbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to APbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadFile(handles,'APname2', 'APtext2');
guidata(hObject,handles);


function APedit2_Callback(hObject, eventdata, handles)
% hObject    handle to APedit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of APedit2 as text
%        str2double(get(hObject,'String')) returns contents of APedit2 as a double


% --- Executes during object creation, after setting all properties.
function APedit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to APedit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runStack.
function runStack_Callback(hObject, eventdata, handles)
% hObject    handle to runStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nROI = get(handles.nROIedit,'String');
handles.roi1 = get(handles.roiEdit1,'String');
handles.roi2 = get(handles.roiEdit2,'String');
guidata(hObject,handles);
fn_runStackAlign(handles);


% --- Executes on button press in runML.
function runML_Callback(hObject, eventdata, handles)
% hObject    handle to runML (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nROI = get(handles.nROIedit,'String');
handles.roi1 = get(handles.roiEdit1,'String');
handles.roi2 = get(handles.roiEdit2,'String');
MLlabel1 = get(handles.MLedit1,'String');
MLlabel2 = get(handles.editAnimal,'String');
guidata(hObject,handles);
fn_runStackMLAP(handles);

% --- Executes on button press in runAP.
function runAP_Callback(hObject, eventdata, handles)
% hObject    handle to runAP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nROI = get(handles.nROIedit,'String');
handles.roi1 = get(handles.roiEdit1,'String');
handles.roi2 = get(handles.roiEdit2,'String');
MLlabel1 = get(handles.MLedit1,'String');
MLlabel2 = get(handles.editAnimal,'String');
guidata(hObject,handles);
fn_runStackMLAP(handles);


% --- Executes on button press in pathButton.
function pathButton_Callback(hObject, eventdata, handles)
% hObject    handle to pathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = fn_loadDir(handles,'datapath', 'pathText');
guidata(hObject,handles);



function nROIedit_Callback(hObject, eventdata, handles)
% hObject    handle to nROIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nROIedit as text
%        str2double(get(hObject,'String')) returns contents of nROIedit as a double


% --- Executes during object creation, after setting all properties.
function nROIedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nROIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function roiEdit1_Callback(hObject, eventdata, handles)
% hObject    handle to roiEdit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roiEdit1 as text
%        str2double(get(hObject,'String')) returns contents of roiEdit1 as a double


% --- Executes during object creation, after setting all properties.
function roiEdit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiEdit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function roiEdit2_Callback(hObject, eventdata, handles)
% hObject    handle to roiEdit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roiEdit2 as text
%        str2double(get(hObject,'String')) returns contents of roiEdit2 as a double


% --- Executes during object creation, after setting all properties.
function roiEdit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiEdit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
