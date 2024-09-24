function [dffList, selectedBehList] = fn_parseTrial(F, beh, Fops, behOps,alignFlag)
% selDay = [111723, 111823];
trimFrame = 200; 
dffList = {};selectedBehList = {};
for i= 1:length(behOps.dateNum)
    selSession = Fops.sessionListNum(Fops.dayList==(behOps.dateNum(i)) & strcmp(Fops.sessionList,'2AFC'));
    selSession(isnan(selSession)) = [];
    tempdff = []; tempselectedBeh = []; 
    disp(['Date ' int2str(behOps.dateNum(i))])
    if behOps.dateNum(i) == 20231118; selSession(selSession==2) = []; end % the behavioral data for 2nd session on 1118 is corrupted. 
    for j= 1:length(selSession)
        [dffStim,dffChoice, selectedBeh] = fn_parseTrialSession(F, beh, Fops, behOps.dateNum(i),selSession(j),behOps);
        if size(dffStim,2) > trimFrame ; dffStim = dffStim(:,1:trimFrame,:); end 
        if size(dffChoice,2) > trimFrame; dffChoice = dffChoice(:,1:trimFrame,:); end 
        switch alignFlag
            case 'stim'      
                if isempty(tempdff); tempdff = cat(3, tempdff, dffStim);
                elseif ~isempty(dffStim); tempdff = fn_catFillNan(3, tempdff, dffStim, 2); end 
            case 'choice'
        
                if isempty(tempdff); tempdff = cat(3, tempdff, dffChoice);
                elseif ~isempty(dffChoice); tempdff = fn_catFillNan(3, tempdff, dffChoice, 2); end 
        end 
        tempselectedBeh = fn_catFillNan(1, tempselectedBeh, selectedBeh); 
    end 
    dffList{i} = tempdff; selectedBehList{i} = tempselectedBeh;
end 


end 

function [dffStim,dffChoice, selectedBeh] = fn_parseTrialSession(Fnew, beh, Fops, selDayBeh, selSession,behOps)
    %selDay = (selDayBeh);
    skipFlag = false;
    selFlag = find(selDayBeh == Fops.dayList & selSession == Fops.sessionListNum & strcmp(Fops.sessionList,'2AFC'));
    selFrames = Fops.nFramesSum(selFlag)+1: Fops.nFramesSum(selFlag+1);
    selectedF = Fnew(:,selFrames);  
    %selectedMotion = motionMetric(selFrames);
 
    selectedBeh = beh(beh(:,1) == selDayBeh & beh(:,3) == selSession,:); 
    selectedDff = fn_getDff(selectedF','method', 'mean','baselineCorrectionPostDff', true, 'baselineCorrectionWindow',2000)';
    %selectedDff = fn_getDff(selectedF','method', 'mov10perc','dffWindow',2000,'baselineCorrectionPostDff', false)';
    dealWithExceptions();
    
    if ~skipFlag
        try
            [dffStim,dffChoice] = fn_parseTrialTC(selectedDff,selectedBeh);
        catch
            disp('PAUSE here!'); error('Exception reached')
        end
    else
        dffStim = []; dffChoice = [];skipFlag = false;
    end 
    % USE THIS FUNCTION TO CAPTURE ALL EXCEPTIONS
    function dealWithExceptions()
        switch behOps.mouse
            case 'zz142'
                if selDayBeh == 20231104 || selDayBeh == 20231105
                    temp = nan(size(selectedDff,1),size(selectedDff,2)*2); 
                    temp(:,1:2:end) = selectedDff; temp = fillmissing(temp,'linear',2); selectedDff = temp;
                end
            case 'zz153'
                if selDayBeh == 20240524 && selSession == 2
                    selSession = 3; 
                    selectedBeh = beh(beh(:,1) == selDayBeh & beh(:,3) == selSession,:); 
                    selectedDff = fn_getDff(selectedF','method', 'mean','baselineCorrectionPostDff', true, 'baselineCorrectionWindow',5000)';
                    disp('Exception reached/solved -- zz153, 20240524, session 2')
                end 
                if selDayBeh == 20240613 && (selSession == 5 || selSession == 6) 
                    % recording session 5 and 6 both correspond to behavior session 5. skip for now
                    skipFlag = true;selectedBeh = []; 
                end 

        end 
        


    end 
end 