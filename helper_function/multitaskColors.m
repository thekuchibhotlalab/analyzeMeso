function [value,lineStyle,marker] = multitaskColors(label,property)
%MULTITASKCOLORS Shared task, action, area colors and plotting styles.
%   C = multitaskColors('T1') returns a 1-by-3 RGB color in [0,1].
%   [C,LS,M] = multitaskColors('T1_R') also returns line style and marker.
%   multitaskColors('R','LineStyle') returns '--'.
%   S = multitaskColors('T2_R','style') returns MATLAB line properties.
%   args = multitaskColors('T2_R','plotargs'); plot(x,y,args{:});
%   P = multitaskColors() returns the complete palette.
%
%   Labels (case insensitive):
%     T1/task1, T2/task2; T1E/T1M/T1L, T2E/T2M/T2L (learning stages).
%     S1/S2 (task-1 blue shades), S3/S4 (task-2 orange shades).
%     L/left, R/right; T1_L/T1_R/T2_L/T2_R (task x action).
%     Stage x action is also supported, e.g. T1E_R or T2L_L.
%     Int_L/Int_R or interleaved_left/interleaved_right use the interleaved
%     color with L/R line styles and filled-circle/open-triangle markers.
%     task/taskContribution, action/actionContribution, Int/interleaved,
%     E/early/earlyLearning (pooled early-learning phase, not a task identity),
%     AC, PPC. Use 'schematicColor' for pastel area fills.
%   IMPORTANT: bare T1L means task 1 LATE; T1_L means task 1 LEFT.
%   Legacy labels s1a1/s2a2/s3a1/s4a2 and numeric 1:4 map to the four
%   task/action conditions. Within each task they now share a color;
%   request styles as well to distinguish actions in old color-only plots.
%
%   Properties: color (default), linestyle/line, marker, markerfacecolor,
%   markeredgecolor, filled, style, plotargs, schematicColor (AC/PPC only).
%   L = black, solid + filled; R = red, dashed + open. Task colors override actions
%   in joint plots. T1 markers: circle/triangle; T2: square/diamond.
%   Unknown labels/properties raise an error instead of silently using black.

P.task.T1=[84 135 186]/255;
P.task.T2=[222 153 84]/255;
% Stimulus identity: task hue, with a lighter shade for the second stimulus.
P.stimulus=struct('S1',P.task.T1,'S2',.55*P.task.T1+.45, ...
    'S3',P.task.T2,'S4',.55*P.task.T2+.45);
P.stage=struct('T1E',[141 179 212]/255,'T1M',P.task.T1, ...
    'T1L',[53 95 143]/255,'T2E',[234 185 128]/255, ...
    'T2M',P.task.T2,'T2L',[177 109 48]/255);
P.action.L=[0 0 0];
P.action.R=[195 63 67]/255; % #C33F43 muted red
P.factor.action=[111 111 111]/255; % Whole-action contribution remains neutral gray.
P.factor.task=[146 156 70]/255; % #929C46 olive; shared with interleaved.
P.context=struct('T1',P.task.T1,'T2',P.task.T2, ...
    'T2E',P.stage.T2E,'Int',P.factor.task);
P.learning=struct('E',[173 100 143]/255,'E_firstDay',[203 130 173]/255,'Int',P.context.Int);
P.area=struct('AC',[196 123 66]/255,'PPC',[146 112 168]/255); % AC #C47B42 orange
P.areaFill=struct('AC',.3*P.area.AC+.7,'PPC',.3*P.area.PPC+.7);
P.line=struct('L','-','R','--');
P.marker=struct('L','o','R','o');
P.filled=struct('L',true,'R',false);
P.taskMarker=struct('T1','o','T2','s');
P.jointMarker.T1=struct('L','o','R','^');
P.jointMarker.T2=struct('L','s','R','d');
lineStyle=[]; marker=[];
if nargin==0, value=P; return; end
if nargin<2, property='color'; end
if isnumeric(label)
    validateattributes(label,{'numeric'},{'scalar','integer','>=',1,'<=',4});
    labels={'T1_L','T1_R','T2_L','T2_R'}; label=labels{label};
end
key=lower(textScalar(label,'label'));
prop=lower(textScalar(property,'property'));
if strcmp(key,'all'), value=P; return; end
switch key
    case {'1','s1a1'}, key='t1_l';
    case {'2','s2a2'}, key='t1_r';
    case {'3','s3a1'}, key='t2_l';
    case {'4','s4a2'}, key='t2_r';
    case 'task1', key='t1';
    case 'task2', key='t2';
    case 'left', key='l';
    case 'right', key='r';
end
% Preserve separators to disambiguate late-stage L from left-action L.
parts=regexp(key,'^(t[12][eml]?|int|interleaved)[_ -](l|r|left|right)$','tokens','once');
action=''; task=''; base=key;
if ~isempty(parts), base=parts{1}; action=upper(parts{2}(1)); end
lineStyle='-'; marker='o'; filled=true;
if ismember(base,{'t1','t2'})
    task=upper(base); color=P.task.(task); marker=P.taskMarker.(task);
elseif ismember(base,{'t1e','t1m','t1l','t2e','t2m','t2l'})
    task=upper(base(1:2)); color=P.stage.(upper(base)); marker=P.taskMarker.(task);
else
    switch base
        case {'s1','s2','s3','s4'}, color=P.stimulus.(upper(base));
        case {'l','r'}
            action=upper(base); color=P.action.(action);
        case {'task','taskcontribution'}, color=P.factor.task;
        case {'action','actioncontribution'}, color=P.factor.action;
        case {'int','interleaved'}, color=P.context.Int; marker='d';
        case {'e','early','earlylearning'}, color=P.learning.E;
        case {'e_firstday'}, color=P.learning.E_firstDay;
        case 'ac', color=P.area.AC;
        case 'ppc', color=P.area.PPC; marker='s';
        otherwise, error('multitaskColors:UnknownLabel','Unknown label: %s',key);
    end
end
if ~isempty(action)
    lineStyle=P.line.(action); filled=P.filled.(action);
    if ~isempty(task), marker=P.jointMarker.(task).(action);
    else, marker=P.marker.(action); end
end
face=color; if ~filled, face='none'; end
S=struct('Color',color,'LineStyle',lineStyle,'Marker',marker, ...
    'MarkerFaceColor',face,'MarkerEdgeColor',color);
switch prop
    case 'color', value=color;
    case {'line','linestyle'}, value=lineStyle;
    case 'marker', value=marker;
    case 'markerfacecolor', value=face;
    case 'markeredgecolor', value=color;
    case 'filled', value=filled;
    case 'style', value=S;
    case 'plotargs'
        pairs=[fieldnames(S) struct2cell(S)]'; value=pairs(:)';
    case 'schematiccolor'
        if ~ismember(base,{'ac','ppc'})
            error('multitaskColors:NotArea','schematicColor requires AC or PPC.');
        end
        value=P.areaFill.(upper(base));
    otherwise, error('multitaskColors:UnknownProperty','Unknown property: %s',prop);
end
end

function out=textScalar(in,name)
if isstring(in) && isscalar(in) && ~ismissing(in)
    out=char(in);
elseif ischar(in) && isrow(in)
    out=in;
else
    error('multitaskColors:InvalidInput','%s must be a text scalar.',name);
end
out=strtrim(out);
end
