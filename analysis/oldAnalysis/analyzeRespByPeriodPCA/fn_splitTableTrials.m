function [T] = fn_splitTableTrials(T)
% Project a parsed table T onto given PC weights.
% T: {nPeriods x 1}, each {1x8}, inner: [N x Time x nTrials]
% W: PC weights either as [P*K x R] OR [P x K x R] (P=periods, K=#trialTypes)
%
trialBin = 30; 
for i = 1:length(T)
    tempT = T{i};
    for j = 1:length(tempT)
        temp = T{i}{j}; 
        nTime = size(temp,2); nTrials = size(temp,3);nNeuron = size(temp,1);

        nBins = floor(nTrials/trialBin); if nBins==0 && nTrials>=1; nBins = 1; end
        if ~nBins==0
            



        end 


        temp = reshape(temp,nNeuron,nTime*nTrials);
        if ~isempty(temp)
            tempProj = W' * temp; 
            tempProj = reshape(tempProj,size(tempProj,1),nTime,nTrials);
            T{i}{j}=tempProj;
        end 
    end 


end 

end
