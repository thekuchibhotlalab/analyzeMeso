function sessionInfo = dealExceptions(sessionInfo,animalName)
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
        sessionInfo.TC{tempIdx} = [];
        tempIdx = find(sessionInfo.date == 20240613 & sessionInfo.session == 6);
        sessionInfo.TC{tempIdx} = [];

        % this session only has one trial, discard it
        tempIdx = find(sessionInfo.date == 20240526 & sessionInfo.session == 5);
        sessionInfo.TC{tempIdx} = [];

    case 'zz159'
        tempIdx = find(sessionInfo.date == 20240624 & sessionInfo.session == 1);
        sessionInfo.session(tempIdx) = 3;
        sessionInfo.sessionName(tempIdx) = {[sessionInfo.sessionType{tempIdx} '3']};

        tempIdx = find(sessionInfo.date == 20240629 & sessionInfo.session == 2);
        sessionInfo.TC{tempIdx} = cat(1,sessionInfo.TC{tempIdx},nan(3000,size(sessionInfo.TC{tempIdx},2)));

        tempIdx = find(sessionInfo.date == 20240716 & sessionInfo.session == 1);
        sessionInfo.session(tempIdx) = 2;
        sessionInfo.sessionName(tempIdx) = {[sessionInfo.sessionType{tempIdx} '2']};

        tempIdx = find(sessionInfo.date == 20240716 & sessionInfo.session == 2);
        sessionInfo.session(tempIdx) = 3;
        sessionInfo.sessionName(tempIdx) = {[sessionInfo.sessionType{tempIdx} '3']};



end 