classdef FelineFileFinder < Viewer
% =========================================================================
% FelineFileFinder (<a href="matlab:edit('FelineFileFinder')">Edit</a>) (<a href="matlab:FelineFileFinder.browse">Browse Cats</a>)
%
% To store, view, display, edit the library of experiments.  This class
% stores a list of <a href="matlab:help('FileCat')">FileCat</a> objects in the file "CatList.mat", and provides 
% an interface to load them.
% 
% Example Use:
% >>C=FelineFileFinder.go;    % Retrieve a FileCat Object
% >>FelineFileFinder.browse;  % Browse the list.
%
% =========================================================================
  
    
    properties (SetObservable, AbortSet)
        
       E=FileCat.empty;       
       
       approval;    % Array of "good" response sets (nExperiments,nCells).  
       
    end 
    
    properties (Transient)
       
        h;  % Handles from GUI
        
        autoload=true; % Automatically load the file
        
    end
        
    methods
        
        function A=FelineFileFinder
            
            A.startprompt=false;
            A.saveprompt=false;
                        
        end
        
        function StartUp(A)    
                        
            % Look for "CatList.mat" File in same directory
            defaultfile=[fileparts(mfilename('fullpath')) filesep 'CatList.mat'];
            
            if exist(defaultfile,'file') 
                if A.autoload
                    A.Load(defaultfile);
                else
                    res=questdlg(['Default file "' defaultfile ...
                        '" was found.  Load it, or start a new one?'],...
                        class(A),'Load It!','Gimme something fresh!','Load It!');
                    if isempty(res), return; end
                    switch res
                        case 'Load It!'
                            A.Load(defaultfile);
                        case 'Gimme something fresh!';
                            A.LoadUp; % Starts the GUI up;
                    end
                end
            end
                        
        end
        
        function LoadUp(A)     
                   
%             A.setBrowsing;
                        
        end
                
        function List(A)
            A.setBrowsing;
            
            set(A.h.pushRun,    'callback',@(s,e)delete(A.h.figure1),...
                                'string',  'Close');
        end
        
        function setBrowsing(A)
            
            A.h=listGUI;
            
            
            % Link Object to Graphics
            addlistener(A,'E','PostSet',@(e,s)A.update);
            addlistener(A,'saveloc','PostSet',@(e,s)A.updateName);
            
            set(A.h.pushLoad,   'callback',@(s,e)A.Load);
            set(A.h.pushSave,   'callback',@(s,e)A.Save);
            set(A.h.listFiles,  'callback',@(s,e)A.showSelected);
            set(A.h.pushAdd,    'callback',@(s,e)A.addOne);
            set(A.h.pushEdit,   'callback',@(s,e)A.editOne);
            set(A.h.pushDelete, 'callback',@(s,e)A.deleteCat);
            
            
            A.addFileMenu(A.h.figure1);
            
            set(A.h.pushRun,    'callback',@(s,e)delete(A.h.figure1));
            set(A.h.pushView,   'callback',@(s,e)A.chosenOne.View);
            set(A.h.pushSpikes, 'callback',@(s,e)A.chosenOne.View_Spikes);
            set(A.h.pushPSTH,   'callback',@(s,e)A.chosenOne.View_PSTH);
            set(A.h.pushComment,'callback',@(s,e)Comment);
            set(A.h.pushBadCells,'callback',@(s,e)badCells);
            
            set(A.h.pushRun,    'string','Close');
            
            function Comment                
                A.chosenOne.Edit_Comments;
                A.showSelected
            end
            
            function badCells
                A.chosenOne.Select_Bad_Cells;
                A.showSelected;
            end
            
            A.update;
            A.updateName;
        end
        
        function Cat=GrabCat(A,number)
            % Grab a FileCat.  If you input a number, it'll take the cat 
            % of that number, otherwise it'll go to the GUI.
            %
            % Pro-tip: to select multiple cats, enter 'multi' for number
            % argument.
                        
            if exist('number','var') && isnumeric(number)
                if number<1 || number >length(A.E);
                    fprintf('%g is not a valid index.  The Cats live in an array of length %g.\n',number,length(A.E));
                    Cat=0; 
                else
                    Cat=A.E(number);
                end
            else % GUI it up
                
                A.setBrowsing;
                
                % multiple select?
                if exist('number','var') && strcmp(number,'multi')
                    set(A.h.listFiles,'max',2);
                    set(A.h.pushRun,'string','Grab Cats');
                else
                    set(A.h.pushRun,'string','Grab Cat');
                end
                
                % Set resume function
                set(A.h.pushRun,'callback',@(s,e)uiresume(A.h.figure1));
                
                uiwait(A.h.figure1);
                
                if ~ishghandle(A.h.figure1) % Figure's been closed
                    Cat=0;
                else
                    Cat=A.chosenOne;
                    delete(A.h.figure1);
                end
                                        
            end
        end
        
        function C=GrabCats(A)
            
            C=A.GrabCat('multi');
                        
        end
        
        function addOne(A)
            
            F=FileCat;
            
            success=F.GetFiles;
            if success
                A.E(end+1)=F;
            end
            
        end
        
        function editOne(A)
            
            if ~isempty(A.E)
            	sel=get(A.h.listFiles,'Value');
                if length(sel)>1
                    errordlg('Select just ONE to edit');
                    return;
                end
                A.E(sel).Edit;
            end
            A.showSelected
        end
        
        function showSelected(A)
            if ~isempty(A.E)
                sel=get(A.h.listFiles,'Value');
                if length(sel)>1
                    set(A.h.textDisp,'string','< Multiple Files Selected >'); 

                else
                    name=A.getNames(sel); 
                    set(A.h.panelDisp,'title',name{1}); 
                    txt=A.E(sel).summary;
                    set(A.h.textDisp,'string',txt);
                    
                end
            end
            
        end
        
        function Cat=chosenOne(A)
            
            Cat=A.E(get(A.h.listFiles,'value'));
            
        end
        
        function update(A)              % Update the list  
            
            % Re-Sort list
            [names ix]=sort(A.getNames);
            A.E=A.E(ix);
            
            set(A.h.listFiles,'string',names);
            
            A.showSelected;
            
        end
        
        function updateName(A)
            
            if ~isempty(A.h) && ishghandle(A.h.figure1)
                set(A.h.figure1,'name',A.filename)
            end
            
        end
        
        function deleteCat(A)
            
            victim=get(A.h.listFiles,'value');
            A.E(victim)=[];
            
        end
        
        function names=getNames(A,ix)
            if ~exist('ix','var'), ix=1:length(A.E); end
        
            names=arrayfun(@catName,A.E(ix),'uniformoutput',false);

        end
        
        function classitup(A)
           
            for i=1:length(A.E)
                A.E(i).classitup;
            end
            
        end
        
        function goods=GetTheGoods(A,includeCell0)
            
            if isempty(A.goods)
                gods=A.goods;
            end
            
            
        end
        
    end
    
    methods (Static)
        
        function Cat=go(varargin)
            % The varagin is really just to select the cat number/'multi' argument;            
            
            A=FelineFileFinder;
            A.autoload=true;
            A.Start;
            Cat=A.GrabCat(varargin{:});
            
        end
        
        function A=browse
            A=FelineFileFinder;
            A.autoload=true;
            A.Start;
            A.setBrowsing;
        end
        
    end
    
end



%% Viewer Code Here:

function varargout = listGUI(varargin)
% LISTGUI MATLAB code for listGUI.fig
%      LISTGUI, by itself, creates a new LISTGUI or raises the existing
%      singleton*.
%
%      H = LISTGUI returns the handle to a new LISTGUI or the handle to
%      the existing singleton*.
%
%      LISTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LISTGUI.M with the given input arguments.
%
%      LISTGUI('Property','Value',...) creates a new LISTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before listGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to listGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help listGUI

% Last Modified by GUIDE v2.5 14-Nov-2011 18:18:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @listGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @listGUI_OutputFcn, ...
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
end

% --- Executes just before listGUI is made visible.
function listGUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to listGUI (see VARARGIN)

% Choose default command line output for listGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes listGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = listGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles;
end

% --- Executes on selection change in listFiles.
function listFiles_Callback(~, ~, ~)
% hObject    handle to listFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listFiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listFiles
end

% --- Executes during object creation, after setting all properties.
function listFiles_CreateFcn(hObject, ~, ~)
% hObject    handle to listFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in pushLoad.
function pushLoad_Callback(~, ~, ~)
% hObject    handle to pushLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


end

% --- Executes on button press in pushAdd.
function pushAdd_Callback(~, ~, ~)
% hObject    handle to pushAdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in pushEdit.
function pushEdit_Callback(~, ~, ~)
% hObject    handle to pushEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in pushDelete.
function pushDelete_Callback(~, ~, ~)
% hObject    handle to pushDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handleends    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in pushRun.
function pushRun_Callback(~, ~, ~)
% hObject    handle to pushRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in pushSave.
function pushSave_Callback(~, ~, ~)
% hObject    handle to pushSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushView.
function pushView_Callback(~, ~, ~)
% hObject    handle to pushView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in pushSpikes.
function pushSpikes_Callback(~, ~, ~)
% hObject    handle to pushSpikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushPSTH.
function pushPSTH_Callback(hObject, eventdata, handles)
% hObject    handle to pushPSTH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushComment.
function pushComment_Callback(hObject, eventdata, handles)
% hObject    handle to pushComment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in pushBadCells.
function pushBadCells_Callback(hObject, eventdata, handles)
% hObject    handle to pushBadCells (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end