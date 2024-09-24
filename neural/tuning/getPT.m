clear;
%suite2ppath = 'C:\Users\zzhu34\Documents\tempdata\zz133\072623\tuning\suite2p';

suite2ppath = 'C:\Users\zzhu34\Documents\tempdata\zz159\060624\green_AC\suite2p';%'D:\zz159\suite2p';

load([suite2ppath filesep 'plane0\Fall.mat']);
dffArg = {'method', 'movMean','dffWindow',2000,'baselineCorrectionPostDff',...
    false,'baselineCorrectionWindow',2000};


%% get puretone parameters
global nPlanes
nPlanes = 1; 
%selFrames = 1:10200;
selFrames = 1:6800;
rawTC = F(:,selFrames)'; 
[roi,nNeuron,iscellFlag] = fn_processSuite2pROI(suite2ppath,nPlanes,'cell');
rawTC = rawTC(:,iscellFlag==1);
%% run getTuning
getTuning_oneChannel(rawTC,nNeuron,roi,[suite2ppath filesep 'tuning' filesep],suite2ppath,'tuningParamMesoPT');

%% get experimental tone parameters
global nPlanes
nPlanes = 1; 
selFrames = 39001:51000;
rawTC = F(:,selFrames)'; 
[roi,nNeuron,iscellFlag] = fn_processSuite2pROI(suite2ppath,nPlanes,'cell');
rawTC = rawTC(:,iscellFlag==1);
%% run getTuning for experimental tones
getTuning_oneChannel(rawTC,nNeuron,roi,[suite2ppath filesep 'tuningExpTone' filesep],suite2ppath,'tuningParamMesoExpTone',[]);
%% Part 2 -- decoding analysis
clear; 
datapath = 'C:\Users\zzhu34\Documents\tempdata\zz133\072623\tuning\suite2p\tuningExpTone\population';
datapathPT = 'C:\Users\zzhu34\Documents\tempdata\zz133\072623\tuning\suite2p\tuning\population';
load([datapath filesep  'tuning.mat']);
%%
selNeuron = tuning.responsiveCellFlag;
tempUp = squeeze(tuning.toneAct(1,:,selNeuron)-tuning.baseAct(1,:,selNeuron)); 
tempDown = squeeze(tuning.toneAct(2,:,selNeuron)-tuning.baseAct(2,:,selNeuron)); 
decoder = fn_runDecoder(tempUp,tempDown, 0.8);

%%
cellAcc = mean(decoder.cellAcc(:,:,2),2);
cellW = mean(decoder.cellW,2);
figure; histogram(cellAcc)
mean(decoder.popAcc(:,2),1)
selNeuronUp = cellAcc>0.6 & cellW>0;
selNeuronDown = cellAcc>0.6 & cellW<0;
PT = load([datapathPT filesep 'tuning.mat']);
tuningUp = mean(PT.tuning.mean(:,selNeuronUp),2);
tuningDown = mean(PT.tuning.mean(:,selNeuronDown),2);
figure; hold on; plot(tuningUp/sum(tuningUp)); plot(tuningDown/sum(tuningDown))