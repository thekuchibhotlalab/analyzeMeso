function [F, beh, Fops,behOps] = fn_loadData(behOps)
% 0.1 -- load F data
%area = 'PPC';
%datapath = ['D:\zz142\committee\110423_111223\green_' area '\suite2p_110623_111223\plane0'];
data = struct();

data = load([behOps.Fpath filesep 'Fall.mat']);

%data.ops = readNPY([Fpath filesep 'ops.npy']); % apparently this does not work for dictionaries. need to load the ops for AC when it does not work for PPC

if ~isfield(data,'F'); data.F = readNPY([behOps.Fpath filesep 'F.npy']); end 
%data.stat = readNPY([Fpath filesep 'stat.npy']);
if ~isfield(data,'iscell');data.iscell = readNPY([behOps.Fpath filesep 'iscell.npy']); end 

% 0.2 -- get the list of sessions and frames
Fops = struct(); 
nFrames = data.ops.nframes_per_folder;
Fops.stat = data.stat;
Fops.ops = data.ops;

Fops.nFramesSum = double([0 cumsum(nFrames)]);
Fops.dayList = []; Fops.sessionList = {}; Fops.sessionListNum = [];
for i= 1:size(data.ops.filelist,1)
    tempStr = strsplit(data.ops.filelist(i,:),'\'); tempStr = tempStr{2};
    tempStr = strsplit(tempStr,'_'); 
    tempDay = tempStr{2}; 
    if str2num(tempDay)>1000000; Fops.dayList(i) = str2num(tempDay); 
    else Fops.dayList(i) = fn_mmddyy2yyyymmdd(str2num(tempDay));  end 

    tempSession = tempStr{3}; tempSessionNum = str2num(tempSession(end));
    if ~isempty(tempSessionNum); Fops.sessionList{i}= tempSession(1:end-1); Fops.sessionListNum(i) = tempSessionNum;
    else; Fops.sessionList{i} = tempSession; Fops.sessionListNum(i) = nan; end 
end 
% 0.2.1 --- Correct for high-movement frames
F = data.F(data.iscell(:,1)==1,:);
%notNanFlag = ~(sum(isnan(F),2)>0);F = F(notNanFlag,:);
%notZeroFlag = ~(sum((F==0),2)==size(F,2));F = F(notZeroFlag,:);
%moveX = double(data.ops.xoff);  moveY = double(data.ops.yoff); 
%Fnew = F;
%[Fnew,motionMetric] = fn_correctForMotionFrames(F,moveX,moveY,Fops.nFramesSum);
%figure; i = 10; plot(F(i,:)); hold on; plot(Fnew(i,:))

% 0.3 --- get behavioral data
%behOps = struct(); 
%behOps.mouse = mouse; %'zz142'; 
%behOps.datapath = behavPath; %['G:\ziyi\mesoData\' behOps.mouse '_behavior\matlab\']; 
if isfield (behOps,'date')
    behOps.dateNum = cellfun(@(x)(str2num(x)),behOps.date);
elseif isfield( behOps,'dayRange')
    behOps.dayRange = cellfun(@(x)(str2num(x)),behOps.dayRange);
    behOps.dateNum = behOps.dayRange(1):behOps.dayRange(2);
    behOps.dateNum(mod(behOps.dateNum,100)>31) = [];  behOps.dateNum(mod(behOps.dateNum,100)==0) = []; 
    behOps.date = strsplit(num2str(behOps.dateNum));
end 
%{'20231106','20231107','20231108','20231109','20231112'};
behOps.plot = true; 
beh = fn_getBehav(behOps);

% 1 -- Get all sessions
if any(112123==Fops.dayList); Fops.sessionListNum(17:21) = [1 2 3 4 5]; Fops.sessionList(17:21) = {1,2,3,4,5}; end % correct for 112123, zz142


end