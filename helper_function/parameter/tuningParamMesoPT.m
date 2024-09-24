global nPlanes

% -------------- Label of Sounds in the Protocol ---------------------
% ONLY toneLabel and toneindex matters here in this function
% Toneindex sort the tones according to whatever way you want
% E.g here, the 9th tone is placed at position 1 in the new matrix
%     and the 4th tone is placed at position 2, etc.
% ToneLabel is the label that is displayed on graphs.
% Tone does not matter, here I use the tones to create the labels
%     of toneLabel of a cell array of strings
tone = [45254.834 8000 13454.34264 4756.82846 5656.854249,...
    22627.417 64000 53817.37058 4000 9513.65692,...
    16000 6727.171322 19027.31384 26908.6852 32000,...
    11313.7085 38054.62768];

toneLabel = strsplit(int2str(round(tone)));
toneindex = [9;4;5;12;2;10;16;3;11;13;6;14;15;17;1;8;7];

% ----------------- Tone Presentation Protocol ---------------------
nTones = length(tone);
nTrials = 10;
nFramesPerTone = 40/nPlanes; % 50
nFramesPerTrial = nFramesPerTone * nTones; % 850
startTrial = 1; % the first tone is on frame 0
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 15.03/nPlanes; % in the future, do not hard code this.
% ----------------- Tone Presentation Protocol ---------------------
pretoneFrames = 10;
baselineFrames = 5;

toneOnset = 8/nPlanes;
peakFrameBin = ceil(0.66 * frameRate);

% --------------- Method of Calculating Dff and Smoothing Data-----------------------
% If smoothArg NOT DECLARED, TC will NOT be smoothed (e.g. DECONNVOLVED SPIKE DATA)
smoothWindow = 5; smoothArg = {'gaussian',smoothWindow};
% If dffArg is NOT DECLARED, Dff will NOT be calculated (e.g. DECONNVOLVED SPIKE DATA)
% IF dffArg = {}, then the default method of dff is used (rolling median of 1000)
dffArg = {'method', 'movMean','dffWindow',2000,'baselineCorrectionPostDff',...
    false,'baselineCorrectionWindow',2000};

% --------------- Method for Determing Tone-evoked Act-----------------------
toneActSel  = 'peak';
toneActSumBin = 1:ceil(0.33 * frameRate);

% -------------------------- Selection of Analysis-----------------------
% Note that the FIRST item in significant test will be used to determine
% reponsiveness of the neuron
significanceTestList = {'signrank','ttest'};
significanceTestAlpha = {0.05/nTones,0.01/nTones};
snrAnalysisList = {'roc'};
otherAnalysisList = {'suppression'};
% ---------------------------- Selection of Figure-----------------------
saveSingleNeuronFlag = true;