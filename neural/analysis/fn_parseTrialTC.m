function [newFstim,newFchoice] = fn_parseTrialTC(F,behData)
nNeuron = size(F,1);
nTrials = size(behData,1);
newF_stimAligned = cell(1,nTrials);
newF_choiceAligned = cell(1,nTrials);
preFrameStim = 30; tempFrameStim = 0;
preFrameChoice = 30; tempFrameChoice = 0;
for i = 1:nTrials
    if i<nTrials; endFrame = behData(i+1,10)-1;
    else; endFrame = size(F,2); end 
    stimFrameStart = behData(i,10)-preFrameStim;
    choiceFrame = behData(i,11)-preFrameChoice;
    newF_stimAligned{i} = F(:,stimFrameStart:endFrame);
    tempFrameStim = max([tempFrameStim size(newF_stimAligned{i},2)]);
    newF_choiceAligned{i} = F(:,choiceFrame:endFrame);
    tempFrameChoice = max([tempFrameStim size(newF_choiceAligned{i},2)]);
end

newFstim = nan(nNeuron,tempFrameStim ,nTrials);
newFchoice = nan(nNeuron,tempFrameChoice ,nTrials);

for i = 1:nTrials
    newFstim(:,1:size(newF_stimAligned{i},2),i) = newF_stimAligned{i};
    newFchoice(:,1:size(newF_choiceAligned{i},2),i) = newF_choiceAligned{i};
end

end