function [newFstim,newFchoice,newFreward] = fn_parseTrialTC(F,behData)
nNeuron = size(F,1);
nTrials = size(behData,1);
newF_stimAligned = cell(1,nTrials);
newF_choiceAligned = cell(1,nTrials);
newF_rewardAligned = cell(1,nTrials);
rewardFrameShift = 3;

preFrameStim = 30; tempFrameStim = 0;
preFrameChoice = 30; tempFrameChoice = 0; tempFrameReward = 0;
for i = 1:nTrials
    if i<nTrials; endFrame = behData(i+1,7)-1;
    else; endFrame = size(F,2); end 
    stimFrameStart = behData(i,7)-preFrameStim;
    choiceFrame = behData(i,8)-preFrameChoice;
    rewardFrame = choiceFrame+rewardFrameShift;
    newF_stimAligned{i} = F(:,stimFrameStart:endFrame);
    tempFrameStim = max([tempFrameStim size(newF_stimAligned{i},2)]);
    newF_choiceAligned{i} = F(:,choiceFrame:endFrame);
    newF_rewardAligned{i} = F(:,rewardFrame:endFrame);
    tempFrameChoice = max([tempFrameChoice size(newF_choiceAligned{i},2)]);
    tempFrameReward = max([tempFrameReward size(newF_rewardAligned{i},2)]);
end

newFstim = nan(nNeuron,tempFrameStim ,nTrials);
newFchoice = nan(nNeuron,tempFrameChoice ,nTrials);
newFreward = nan(nNeuron,tempFrameReward ,nTrials);

for i = 1:nTrials
    newFstim(:,1:size(newF_stimAligned{i},2),i) = newF_stimAligned{i};
    newFchoice(:,1:size(newF_choiceAligned{i},2),i) = newF_choiceAligned{i};
    newFreward(:,1:size(newF_rewardAligned{i},2),i) = newF_rewardAligned{i};
end
newFstim = single(newFstim);
newFchoice = single(newFchoice);
newFreward = single(newFreward);
end