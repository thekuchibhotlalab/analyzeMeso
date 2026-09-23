function sessionInfo = dealExceptions(sessionInfo,animalName)
if ~ismember('excludeNeuralAnalysis',sessionInfo.Properties.VariableNames)
    sessionInfo.excludeNeuralAnalysis = false(height(sessionInfo),1);
end
if ~ismember('neuralPaddingFrames',sessionInfo.Properties.VariableNames)
    sessionInfo.neuralPaddingFrames = zeros(height(sessionInfo),1);
end
hasTC = ismember('TC',sessionInfo.Properties.VariableNames);

switch animalName

    case 'zz151'
        AFCflag = cellfun(@(x)(strcmp(x,'2AFC')),sessionInfo.sessionType);
        tempIdx = find( (sessionInfo.date == 20240416 & AFCflag) | (sessionInfo.date == 20240506 & AFCflag) );
        sessionInfo.session(tempIdx) = sessionInfo.session(tempIdx)+1;
        for i = 1:length(tempIdx)
            sessionInfo.sessionName(tempIdx(i)) = {strjoin({sessionInfo.sessionType{tempIdx(i)},int2str(sessionInfo.session(tempIdx(i)))},'')};
        end 
                
        tempIdx1 = find(sessionInfo.date == 20240514 & sessionInfo.session == 1 & strcmp(sessionInfo.sessionType,'2AFC'));
        tempIdx2 = find(sessionInfo.date == 20240514 & sessionInfo.session == 2 & strcmp(sessionInfo.sessionType,'2AFC'));
        sessionInfo.session(tempIdx1) = 2;
        sessionInfo.sessionName(tempIdx1) = {[sessionInfo.sessionType{tempIdx1} '2']};
        sessionInfo.session(tempIdx2) = 1;
        sessionInfo.sessionName(tempIdx2) = {[sessionInfo.sessionType{tempIdx2} '1']};
    case 'zz153'
        tempIdx = find(sessionInfo.date == 20240524 & sessionInfo.session == 2);
        sessionInfo.session(tempIdx) = 3;
        sessionInfo.sessionName(tempIdx) = {[sessionInfo.sessionType{tempIdx} '3']};

        % recording session 5 and 6 both correspond to behavior session 5. skip for now
        tempIdx = find(sessionInfo.date == 20240613 & sessionInfo.session == 5);
        if hasTC; sessionInfo.TC(tempIdx) = {[]}; end
        sessionInfo.excludeNeuralAnalysis(tempIdx) = true;
        tempIdx = find(sessionInfo.date == 20240613 & sessionInfo.session == 6);
        if hasTC; sessionInfo.TC(tempIdx) = {[]}; end
        sessionInfo.excludeNeuralAnalysis(tempIdx) = true;

        % this session only has one trial, discard it
        tempIdx = find(sessionInfo.date == 20240526 & sessionInfo.session == 5);
        if hasTC; sessionInfo.TC(tempIdx) = {[]}; end
        sessionInfo.excludeNeuralAnalysis(tempIdx) = true;

    case 'zz159'
        tempIdx = find(sessionInfo.date == 20240624 & sessionInfo.session == 1);
        sessionInfo.session(tempIdx) = 3;
        sessionInfo.sessionName(tempIdx) = {[sessionInfo.sessionType{tempIdx} '3']};

        tempIdx = find(sessionInfo.date == 20240629 & sessionInfo.session == 2);
        sessionInfo.neuralPaddingFrames(tempIdx) = 3000;
        if hasTC
            for idx = tempIdx(:)'
                sessionInfo.TC{idx} = cat(1,sessionInfo.TC{idx},nan(3000,size(sessionInfo.TC{idx},2)));
            end
        end

        % Capture both original indices before renaming (avoid mapping 1 to 3).
        tempIdx1 = find(sessionInfo.date == 20240716 & sessionInfo.session == 1);
        tempIdx2 = find(sessionInfo.date == 20240716 & sessionInfo.session == 2);
        for idx = tempIdx1(:)'
            sessionInfo.session(idx) = 2;
            sessionInfo.sessionName{idx} = [sessionInfo.sessionType{idx} '2'];
        end
        for idx = tempIdx2(:)'
            sessionInfo.session(idx) = 3;
            sessionInfo.sessionName{idx} = [sessionInfo.sessionType{idx} '3'];
        end



end 
