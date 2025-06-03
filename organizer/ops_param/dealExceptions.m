function sessionInfo = dealExceptions(sessionInfo,animalName)
switch animalName

    case 'zz151'
        AFCflag = cellfun(@(x)(strcmp(x,'2AFC')),sessionInfo.SessionType);
        tempIdx = find( (sessionInfo.SessionDate == 20240416 & AFCflag) | (sessionInfo.SessionDate == 20240506 & AFCflag) );
        sessionInfo.SessionNumber(tempIdx) = sessionInfo.SessionNumber(tempIdx)+1;
        for i = 1:length(tempIdx)
            sessionInfo.SessionName(tempIdx(i)) = {strjoin({sessionInfo.SessionType{tempIdx(i)},int2str(sessionInfo.SessionNumber(tempIdx(i)))},'')};
        end 
                
        tempIdx1 = find(sessionInfo.SessionDate == 20240514 | sessionInfo.SessionNumber == 1);
        tempIdx2 = find(sessionInfo.SessionDate == 20240514 | sessionInfo.SessionNumber == 2);
        sessionInfo.SessionNumber(tempIdx1) = 2;
        sessionInfo.SessionName(tempIdx1) = {[sessionInfo.SessionType{tempIdx1} '2']};
        sessionInfo.SessionNumber(tempIdx2) = 1;
        sessionInfo.SessionName(tempIdx2) = {[sessionInfo.SessionType{tempIdx2} '1']};
    case 'zz153'
        tempIdx = find(sessionInfo.SessionDate == 20240524 & sessionInfo.SessionNumber == 2);
        sessionInfo.SessionNumber(tempIdx) = 3;
        sessionInfo.SessionName(tempIdx) = {[sessionInfo.SessionType{tempIdx} '3']};

        % recording session 5 and 6 both correspond to behavior session 5. skip for now
        tempIdx = find(sessionInfo.SessionDate == 20240613 & sessionInfo.SessionNumber == 5);
        sessionInfo.TC{tempIdx} = [];
        tempIdx = find(sessionInfo.SessionDate == 20240613 & sessionInfo.SessionNumber == 6);
        sessionInfo.TC{tempIdx} = [];

        % this session only has one trial, discard it
        tempIdx = find(sessionInfo.SessionDate == 20240526 & sessionInfo.SessionNumber == 5);
        sessionInfo.TC{tempIdx} = [];

    case 'zz159'
        tempIdx = find(sessionInfo.SessionDate == 20240624 & sessionInfo.SessionNumber == 1);
        sessionInfo.SessionNumber(tempIdx) = 3;
        sessionInfo.SessionName(tempIdx) = {[sessionInfo.SessionType{tempIdx} '3']};

        tempIdx = find(sessionInfo.SessionDate == 20240629 & sessionInfo.SessionNumber == 2);
        sessionInfo.TC{tempIdx} = cat(1,sessionInfo.TC{tempIdx},nan(3000,size(sessionInfo.TC{tempIdx},2)));

        tempIdx = find(sessionInfo.SessionDate == 20240716 & sessionInfo.SessionNumber == 1);
        sessionInfo.SessionNumber(tempIdx) = 2;
        sessionInfo.SessionName(tempIdx) = {[sessionInfo.SessionType{tempIdx} '2']};

        tempIdx = find(sessionInfo.SessionDate == 20240716 & sessionInfo.SessionNumber == 2);
        sessionInfo.SessionNumber(tempIdx) = 3;
        sessionInfo.SessionName(tempIdx) = {[sessionInfo.SessionType{tempIdx} '3']};



end 