function SK = fn_plotLabelFlow(labels1, labels2, varargin)
% Plot flow from labels1 -> labels2 using the SSankey package.
%
% labels1, labels2 : vectors (numeric / char / string / categorical), same length.
%
% Name-Value:
%   'LeftPrefix'   : prefix for left node names (default 'L: ')
%   'RightPrefix'  : prefix for right node names (default 'R: ')
%   'LabelOrderL'  : explicit top→bottom order for left labels (default: first-seen)
%   'LabelOrderR'  : explicit top→bottom order for right labels (default: first-seen)
%   'MissingPolicy': 'drop' (default) or 'keepAs'
%   'MissingLabel' : used if keepAs (default 'NA')
%   'MinCount'     : hide flows with count < MinCount (default 0)
%   'Normalize'    : 'none'(default) | 'row' | 'col' | 'global'
%   'Title'        : figure title (default '')
%
% Returns:
%   SK             : SSankey object

p = inputParser;
addParameter(p,'LeftPrefix','L: ');
addParameter(p,'RightPrefix','R: ');
addParameter(p,'LabelOrderL',[]);
addParameter(p,'LabelOrderR',[]);
addParameter(p,'MissingPolicy','drop');
addParameter(p,'MissingLabel','NA');
addParameter(p,'MinCount',0);
addParameter(p,'Normalize','none');
addParameter(p,'Title','');
parse(p,varargin{:});
opt = p.Results;

% --- prep
labels1 = labels1(:);
labels2 = labels2(:);
assert(numel(labels1)==numel(labels2), 'labels1 and labels2 must have same length');

L = string(labels1);
R = string(labels2);

% handle missing
miss = ismissing(L) | ismissing(R);
switch lower(opt.MissingPolicy)
    case 'drop'
        L = L(~miss); R = R(~miss);
    case 'keepas'
        rep = string(opt.MissingLabel);
        L(ismissing(L)) = rep;
        R(ismissing(R)) = rep;
    otherwise
        error('MissingPolicy must be ''drop'' or ''keepAs''');
end
if isempty(L)
    warning('Nothing to plot (all rows missing after policy).');
    SK = []; return;
end

% label orders
if isempty(opt.LabelOrderL), leftSet  = unique(L,'stable').'; else, leftSet  = string(opt.LabelOrderL(:)).'; end
if isempty(opt.LabelOrderR), rightSet = unique(R,'stable').'; else, rightSet = string(opt.LabelOrderR(:)).'; end
K1 = numel(leftSet); K2 = numel(rightSet);

% map to indices
[tfL, iL] = ismember(L, leftSet);
[tfR, iR] = ismember(R, rightSet);
keep = tfL & tfR;
iL = iL(keep); iR = iR(keep);
if isempty(iL)
    warning('No valid pairs after mapping to provided LabelOrder.'); SK=[]; return;
end

% contingency counts
C = accumarray([iL iR], 1, [K1 K2], @sum, 0);

% optional normalization
switch lower(opt.Normalize)
    case 'none'
    case 'row'
        rowS = sum(C,2); rowS(rowS==0) = 1; C = C ./ rowS;
    case 'col'
        colS = sum(C,1); colS(colS==0) = 1; C = C ./ colS;
    case 'global'
        s = sum(C,'all'); if s>0, C = C ./ s; end
    otherwise
        error('Normalize must be none|row|col|global');
end

% build links cell array: {source, target, value}
links = {};
for i = 1:K1
    for j = 1:K2
        v = C(i,j);
        if v > opt.MinCount
            src = sprintf('%s%s', opt.LeftPrefix,  leftSet(i));
            dst = sprintf('%s%s', opt.RightPrefix, rightSet(j));
            links(end+1, :) = {src, dst, v}; %#ok<AGROW>
        end
    end
end
if isempty(links)
    warning('All flows below MinCount; nothing to draw.');
    SK = []; return;
end

% --- draw with SSankey (match the demo defaults)
figure('Name','sankey','Units','normalized','Position',[.05,.2,.5,.56]);
SK = SSankey(links(:,1), links(:,2), links(:,3));
SK.RenderingMethod = 'interp';     % 'left'/'right'/'interp'/'map'/'simple'
SK.Align           = 'center';     % 'up'/'down'/'center'
SK.LabelLocation   = 'top';        % 'left'/'right'/'top'/'center'/'bottom'
SK.Sep             = .2;
SK.draw();

% hover text
SK.dataTipFormat = {1, 'Source:', 'Target:', 'Value:', 'auto'};

% title
if ~isempty(opt.Title), title(opt.Title); end
end
