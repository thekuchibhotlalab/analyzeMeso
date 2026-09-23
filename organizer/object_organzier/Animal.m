classdef Animal
    properties
        ID
        ops
        trialInfo
        sessionInfo
        sessionInfoBeh
        dayInfo
        chunkedDayInfo
        alignmentOps
        analysis
    end

    methods
        function obj = Animal(id,varargin)
            p = inputParser;
            addParameter(p, 'loadNeural', true);
            addParameter(p, 'actType', 'spk');
            addParameter(p, 'parseTrial', true);
            addParameter(p, 'saveParseTrial', true);
            addParameter(p, 'parseDay', false);
            addParameter(p, 'tracking', false);
            parse(p, varargin{:});
            obj.ID = id;
            % Attempt to load options file: [ID '_param.m']
            myOps = struct();
            run([obj.ID '_param.m']);
            obj.ops = myOps;
            actType = p.Results.actType; 

            disp(['Step1 -- Loading recording parameter file: ' obj.ID '_param.m'])
            disp('Step2 -- Loading behavior and neural TC files')

            % STEP1 -- CONSTRUCT SESSION INFO
            if exist(obj.ops.sessionInfoName )
                if (p.Results.loadNeural)
                    load(obj.ops.sessionInfoName,'sessionInfo','trialInfo','sessionInfoBeh');
                    obj.sessionInfo = sessionInfo;
                else
                    load(obj.ops.sessionInfoName,'trialInfo','sessionInfoBeh');
                end 
                load([obj.ops.alignOpsPath filesep obj.ops.ID '_alignmentOps.mat'],'alignmentOps');
                obj.trialInfo = trialInfo;
                obj.sessionInfoBeh = sessionInfoBeh;
                obj.alignmentOps = alignmentOps;
                disp('Saved data detected -- directly loading sessionInfo')
            else
                disp('Saved data not detected -- creating sessionInfo')
                constructSessionInfo();                
            end

            if ~iscell(obj.sessionInfo) && istable(obj.sessionInfo) && ...
                    ismember('behSel',obj.sessionInfo.Properties.VariableNames)
                obj.sessionInfo = fn_encodeTrainingLabels(obj.sessionInfo);
            end

            % STEP2 -- LOAD NEURAL DATA AND PARSE TRIAL IF NEEDED
            if p.Results.loadNeural
                if ~ismember('diffStim', obj.sessionInfo.Properties.VariableNames) ...
                        && ismember('TC', obj.sessionInfo.Properties.VariableNames) && ...
                        p.Results.parseTrial
                    obj = obj.parseTrial();
                    if p.Results.saveParseTrial
                        sessionInfo = obj.sessionInfo;
                        [sessionInfoBeh,trialInfo] = fn_getBehTrialInfo(sessionInfo);
                        save(obj.ops.sessionInfoName,'sessionInfo','trialInfo','sessionInfoBeh','-v7.3');
                    end 
                end 
                
                % SINGLE AREA -- DO TRACKING NORMALLY
                if ~iscell(obj.ops.ID)
                    if p.Results.parseDay && isempty(obj.dayInfo)
                        if p.Results.tracking
                            obj = obj.parseDay('tracking'); 
                        else
                            obj = obj.parseDay(); 
                        end 
                    end 
                % MULTI AREA -- USE SPECIAL TRACKING METHODS
                else


                end
            end

            function constructSessionInfo
                if ~p.Results.loadNeural
                    actCell = {};
                else
                % LOAD TC
                switch actType
                    case 'dff'
                        actCell = loadTC(obj.ops.TCname,'dff');
                    case 'spk'
                        actCell = loadTC(obj.ops.spkname,'spk');
                end 
                end

                 % SPK NORMALIZATION
                 disp('Doing spike normalization using norm') ;tic;
                 if obj.ops.normSpk && p.Results.loadNeural && strcmp(actType,'spk')
                     if iscell(obj.ops.ID)
                         for i = 1:length(actCell)
                             actCell{i} = spkNorm(actCell{i});
                         end
                     else
                         actCell = spkNorm(actCell);
                     end 
                 end 
                 toc; disp('Spk normalization done!')
                 
                 % LOAD SESSION INFORMATION
                 if iscell(obj.ops.ID)
                     for i = 1:length(obj.ops.ID)
                        [obj.sessionInfo{i}, obj.alignmentOps{i}] = getSessionInfo(obj.ops.infoName{i},actCell{i},...
                            obj.ops.trackingName{i},obj.ops.alignOpsPath{i},obj);
                     end 
                 else
                    [obj.sessionInfo, obj.alignmentOps] = getSessionInfo(obj.ops.infoName,actCell,...
                        obj.ops.trackingName,obj.ops.alignOpsPath,obj);
                 end 
                 obj = obj.getBehav;
            end 
        end

        function obj = getBehav(obj)
            matDir = [obj.ops.behavPath filesep 'matlab']; 
            filelist = dir([matDir filesep obj.ops.mouse '_*_2AFCsession*.mat']);
            disp(['Loading ' matDir ' for behavioral matlab files'])
            filename = {filelist.name};

            obj.sessionInfo.sessionRec(:) = 1:size(obj.sessionInfo,1);
            % Process the raw behavioral data into a table. Record both raw data and processed table
            obj.sessionInfo.behSel = cell(height(obj.sessionInfo), 1);
            
            warning off;
            for i = 1:length(filename)
                tempFilename = strsplit(filename{i},'_');
                day = str2double(tempFilename{2}); 
                temp = strsplit(tempFilename{3},'session');
                tempType = temp{1}; tempNumber = temp{2};
                tempName = strjoin(strsplit(tempFilename{3},'session'),'');

                load([matDir filesep filename{i}],'allData');

                allData(all(isnan(allData), 2),:) = [];
                
                tempIndex = find(obj.sessionInfo.date == day & strcmp(obj.sessionInfo.sessionName, tempName));

                beh = allData; behTable = table();
                behTable.stimuli = beh(:,2);
                behTable.action = beh(:,3);
                behTable.responseType = beh(:,4);
                behTable.correct = beh(:,4)==1;
                behTable.miss = beh(:,3)==0;   
                behTable.stimulusTime = beh(:,5);
                behTable.responseTime = beh(:,6);
                behTable.RT = beh(:,6)-beh(:,5);
                behTable.stimulusFrame = beh(:,7);  
                behTable.responseFrame = beh(:,8); 
                behTable.rewardFrame = beh(:,9); 
                % Find the corresponding 
                if length(tempIndex) == 1 % Behavioral session exists as a recording session
                    obj.sessionInfo.beh(tempIndex) = {allData};
                    obj.sessionInfo.behSel(tempIndex) = {behTable};
                elseif isempty(tempIndex) % Behavioral session did not have recording
                    tempIndex = size(obj.sessionInfo,1)+1;
                    obj.sessionInfo.beh(tempIndex) = {allData};
                    obj.sessionInfo.behSel(tempIndex) = {behTable};
                    obj.sessionInfo.sessionName(tempIndex) = {tempName};
                    obj.sessionInfo.date(tempIndex) = day;
                    obj.sessionInfo.session(tempIndex) = str2double(tempNumber);
                    obj.sessionInfo.sessionType(tempIndex) = {tempType};
                else
                    disp(['Critical error of session ' int2str(i) ', multiple match found'])
                end
            end
            warning on;
            days = unique(obj.sessionInfo.date);
            for i = 1:length(days)
                selDay = find(obj.sessionInfo.date == days(i));
                obj.sessionInfo.day(selDay) = i;
            end 
            obj.sessionInfo = sortrows(obj.sessionInfo, {'date', 'sessionName'});

            % match the wheel data with the correct session
            animalName = strsplit(obj.ID,'_'); animalName = animalName{1};
            try
                temp = load([obj.ops.behavPath filesep animalName '_wheelData.mat']);
                wheelData = temp.sessionTable; clear temp; 
                for i = 1:size(wheelData,1)
                    matchIdx = wheelData.SessionDate(i) == obj.sessionInfo.date;
                    matchNumIdx = wheelData.SessionNumber(i) == obj.sessionInfo.session;
                    matchTypeIdx = cellfun(@(x)(strcmp(x,wheelData.SessionType(i))), obj.sessionInfo.sessionType, 'UniformOutput',true);
                    idx = find(matchIdx & matchTypeIdx & matchNumIdx);
                    if ~isempty(idx)
                        obj.sessionInfo.wheelFrame(idx) = wheelData.wheelFrame(i);
                        obj.sessionInfo.wheelTime(idx) = wheelData.wheelTime(i);
                    end 
                end 
            catch
                disp('no wheel data detected')
            end 
            obj.sessionInfo = fn_encodeTrainingLabels(obj.sessionInfo);
        end

        function data = selData(obj,method, param)
            switch method
                case 'T1'
                    selectedIdx = fn_selSession(obj.sessionInfo, 'dayRange', obj.ops.dayT1);
                case 'T2'
                    selectedIdx = fn_selSession(obj.sessionInfo, 'dayRange', obj.ops.dayT2);
                case 'Interleave'
                    selectedIdx = fn_selSession(obj.sessionInfo, 'dayRange', obj.ops.dayInterleave);
                otherwise
                    selectedIdx = fn_selSession(obj.sessionInfo, method, param);
            end 
            
            data.sessionInfo = obj.sessionInfo(selectedIdx,:);
            %data.TC = data.sessionInfo.TC{selectedIdx};


            [data.dffStimList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim');
            [data.dffChoiceList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'choice');


        end 

        function obj = parseTrial(obj)
            trimFrame = 100; trialStart = 30; 
            for j= 1:size(obj.sessionInfo,1)
                if ~isempty(obj.sessionInfo.TC{j}) & ~isempty(obj.sessionInfo.beh{j})
                    %F = fn_getDff(obj.sessionInfo.TC{j},'method', 'mean','baselineCorrectionPostDff', true, 'baselineCorrectionWindow',2000)';
                    F = obj.sessionInfo.TC{j}'; 
                    beh = obj.sessionInfo.beh{j};
                    try
                        [dffStim,dffChoice,dffReward] = fn_parseTrialTC(F,beh);
                    catch ME
                        nFrames = size(F,2);
                        [behTrim,keepTrial] = trimBehToRecording(beh,nFrames);
                        if length(keepTrial) == size(beh,1)
                            rethrow(ME)
                        end
                        fprintf(['Frames exceed recording in session row %d. ' ...
                            'Parsing %d/%d behavior trials within %d imaging frames.\n'], ...
                            j,length(keepTrial),size(beh,1),nFrames);
                        beh = behTrim;
                        obj.sessionInfo.beh{j} = behTrim;
                        if ismember('behSel',obj.sessionInfo.Properties.VariableNames) && ...
                                ~isempty(obj.sessionInfo.behSel{j})
                            obj.sessionInfo.behSel{j} = trimBehSel(obj.sessionInfo.behSel{j},keepTrial);
                        end
                        [dffStim,dffChoice,dffReward] = fn_parseTrialTC(F,beh);

                    end 

                    dffStim = trimTC(dffStim,trimFrame);
                    dffChoice = trimTC(dffChoice,trimFrame);
                    dffReward = trimTC(dffReward,trimFrame);

                    
                    obj.sessionInfo.dffStim{j} = dffStim;
                    obj.sessionInfo.dffChoice{j} = dffChoice;
                    obj.sessionInfo.dffReward{j} = dffReward;
                    

                    if  ~isempty(beh) && ismember('wheelFrame',obj.sessionInfo.Properties.VariableNames)
                    wheel = obj.sessionInfo.wheelFrame{j};
                    [wheelStim,wheelChoice,wheelReward] = fn_parseTrialTC(wheel,beh);

                    wheelStim = squeeze(trimTC(wheelStim,trimFrame));
                    wheelChoice = squeeze(trimTC(wheelChoice,trimFrame));
                    wheelReward = squeeze(trimTC(wheelReward,trimFrame));

                    obj.sessionInfo.wheelStim{j} = wheelStim - repmat(wheelStim(trialStart,:),[size(wheelStim,1) 1]);
                    obj.sessionInfo.wheelChoice{j} = wheelChoice - repmat(wheelChoice(trialStart,:),[size(wheelChoice,1) 1]);
                    obj.sessionInfo.wheelReward{j} = wheelReward - repmat(wheelReward(trialStart,:),[size(wheelReward,1) 1]);
                    end 
                end 
                % lastly, keep the tuning sessions that are not parsed by behavior
                if any(strcmp(obj.sessionInfo.sessionType{j},{'PT','puretone','pureTone','PureTone','expTone','ExpTone'}))
                    obj.sessionInfo.tuning{j} = obj.sessionInfo.TC{j}';
                end 
            end 
            if ismember('behSel',obj.sessionInfo.Properties.VariableNames)
                obj.sessionInfo = fn_encodeTrainingLabels(obj.sessionInfo);
            end
            obj.sessionInfo.TC = [];
            function mat = trimTC(mat,trimFrame)
                if size(mat,2) > trimFrame ; mat = mat(:,1:trimFrame,:); end 

            end 
            function [behTrim,keepTrial] = trimBehToRecording(beh,nFrames)
                preFrameStim = 30;
                preFrameChoice = 30;
                rewardFrameShift = 3;
                stimFrame = beh(:,7);
                choiceFrame = beh(:,8);
                rewardFrame = choiceFrame + rewardFrameShift;
                validTrial = isfinite(stimFrame) & isfinite(choiceFrame) & ...
                    stimFrame - preFrameStim >= 1 & ...
                    choiceFrame - preFrameChoice >= 1 & ...
                    stimFrame <= nFrames & ...
                    choiceFrame <= nFrames & ...
                    rewardFrame <= nFrames;
                keepTrial = find(validTrial);
                behTrim = beh(keepTrial,:);
            end
            function behSelTrim = trimBehSel(behSel,keepTrial)
                behSelTrim = behSel(keepTrial,:);
            end
        end 

        function obj = parseDay(obj,trackingStr,varargin)
            if ~exist('trackingStr','var'); trackingStr = ''; end
            if ~isempty(varargin) && isnumeric(varargin{1})
                varargin = [{'minSessionsPerLearningPeriod'}, varargin];
            elseif ~isempty(varargin) && isTextScalar(varargin{1}) && ~isParseDayParameter(varargin{1})
                varargin = [{'trackingMode'}, varargin];
            end
            p = inputParser;
            addParameter(p,'trackingMode','stageBalanced');
            addParameter(p,'minSessionsPerLearningPeriod',8);
            parse(p,varargin{:});
            trackingMode = p.Results.trackingMode;
            minSessionsPerLearningPeriod = p.Results.minSessionsPerLearningPeriod;
            sessionInfoAll = obj.sessionInfo;
            tempSessionInfo = filterNeuralSessions(sessionInfoAll);
            if strcmpi(trackingStr,'tracking')
                % selTracking reads obj.sessionInfo, so temporarily give it
                % only sessions that contain aligned neural/behavior trials.
                % Restore the full table afterward so raw behavior is retained.
                obj.sessionInfo = tempSessionInfo;
                noRecordingFlag = cellfun(@isempty,obj.sessionInfo.ishere);
                obj.sessionInfo = obj.sessionInfo(~noRecordingFlag,:);
                [ishereAllSession,ishereCount,sessionSel] = obj.selTracking(trackingMode,...
                    'minSessionsPerLearningPeriod',minSessionsPerLearningPeriod);
                if strcmpi(trackingMode,'unrestrainedDays')
                    nSel = min(obj.ops.trackingSessionSel,length(sessionSel));
                else
                    nSel = length(sessionSel);
                end
                sessionSel = sessionSel{nSel};
                sessionSel = sort(sessionSel);
                tempSessionInfo = obj.sessionInfo(sessionSel,:);
                ishereAllSession = ishereAllSession{nSel};
                obj.sessionInfo = sessionInfoAll;
            end
            dayInfo = table();
            days = unique(tempSessionInfo.date);
            dayInfo.date = days;
            dayInfo.dayLabel = repmat({''},length(days),1);
            for i = 1:length(days)
                selDay = find(tempSessionInfo.date == days(i));
                dayInfo.dayLabel{i} = getDayLabel(tempSessionInfo,selDay);
                %tempIshere = cellfun(@nansum,obj.sessionInfo.ishere(selDay));
                %selDay(tempIshere<(0.65*length(obj.sessionInfo.ishere{1}))) = [];
                dayInfo = catData(tempSessionInfo,dayInfo, 'dffStim',selDay, i,3);
                dayInfo = catData(tempSessionInfo,dayInfo, 'dffChoice',selDay, i,3);
                dayInfo = catData(tempSessionInfo,dayInfo, 'dffReward',selDay, i,3);
                dayInfo = catData(tempSessionInfo,dayInfo, 'behSel',selDay, i,1);
                try
                    dayInfo = catData(tempSessionInfo,dayInfo, 'wheelStim',selDay, i,2);
                    dayInfo = catData(tempSessionInfo,dayInfo, 'wheelChoice',selDay, i,2);
                    dayInfo = catData(tempSessionInfo,dayInfo, 'wheelReward',selDay, i,2);
                catch
                    disp('no wheel data')
                end
                if ~isempty(dayInfo.behSel{i})
                    [T1, T2] = fn_getAccBiasTwoTask(dayInfo.behSel{i}.stimuli,...
                        dayInfo.behSel{i}.responseType==1, dayInfo.behSel{i}.action==0);
                    dayInfo.T1acc{i} = T1.acc; dayInfo.T1ar{i} = T1.ar; 
                    dayInfo.T2acc{i} = T2.acc; dayInfo.T2ar{i} = T2.ar; 
                    dayInfo.T1{i} = T1; dayInfo.T2{i} = T2;
                end 
                tempHere = tempSessionInfo.ishere(selDay);
                tempHere = cat(1, tempHere{:});
                tempHere = all(tempHere==1,1);
                dayInfo.ishere{i} = tempHere;
                dayInfo.isheresum{i} = sum(tempHere);
                dayInfo.roi{i} = tempSessionInfo.roi{selDay(1)};
            end 
            if strcmpi(trackingStr,'tracking')
                obj.ops.ishereAll = ishereAllSession; 
            end 
            emptyFlag = cellfun(@isempty,dayInfo.dffStim); 
            dayInfo(emptyFlag,:) = [];
            if strcmpi(trackingStr,'tracking') && strcmpi(trackingMode,'unrestrainedDays')
                dayInfo = applyManualChunkLabels(dayInfo);
            end
            obj.dayInfo = dayInfo;

            function dayInfo = catData(sessionInfo,dayInfo, fieldStr,selDay, idx,catDim)
                temp = sessionInfo.(fieldStr)(selDay);
                if catDim == 3
                    temp = reshapeEmptyTrialArrays(temp);
                end
                try
                    dayInfo.(fieldStr){idx} = cat(catDim, temp{:});
                catch
                    disp('dimension wrong')
                end
            end 
            function filteredSessionInfo = filterNeuralSessions(sessionInfo)
                nSession = height(sessionInfo);
                excludeFlag = false(nSession,1);
                if ismember('excludeNeuralAnalysis',sessionInfo.Properties.VariableNames)
                    explicitExclude = logical(sessionInfo.excludeNeuralAnalysis);
                    explicitExclude(~isfinite(double(explicitExclude))) = false;
                    excludeFlag = excludeFlag | explicitExclude;
                    if any(explicitExclude)
                        fprintf('parseDay: excluding %d session(s) marked excludeNeuralAnalysis.\n', ...
                            sum(explicitExclude));
                    end
                end

                hasBehavior = ismember('behSel',sessionInfo.Properties.VariableNames);
                neuralFields = {'dffStim','dffChoice'};
                for iField = 1:numel(neuralFields)
                    fieldName = neuralFields{iField};
                    if ~ismember(fieldName,sessionInfo.Properties.VariableNames)
                        continue
                    end
                    neuralData = sessionInfo.(fieldName);
                    excludeFlag = excludeFlag | cellfun(@isempty,neuralData);
                    if ~hasBehavior
                        continue
                    end
                    for iSession = 1:nSession
                        nBehaviorTrial = getBehaviorTrialCount(sessionInfo.behSel{iSession});
                        nNeuralTrial = getNeuralTrialCount(neuralData{iSession});
                        if nBehaviorTrial ~= nNeuralTrial
                            excludeFlag(iSession) = true;
                            warning('Animal:TrialCountMismatch', ...
                                ['Excluding session row %d (date %g, session %g): ' ...
                                'behSel has %d trials but %s has %d.'], ...
                                iSession,getNumericTableValue(sessionInfo,'date',iSession), ...
                                getNumericTableValue(sessionInfo,'session',iSession), ...
                                nBehaviorTrial,fieldName,nNeuralTrial);
                        end
                    end
                end

                if any(excludeFlag)
                    fprintf('parseDay: using %d/%d sessions after neural/behavior validation.\n', ...
                        sum(~excludeFlag),nSession);
                end
                filteredSessionInfo = sessionInfo(~excludeFlag,:);
            end
            function nTrial = getBehaviorTrialCount(behaviorData)
                if isempty(behaviorData)
                    nTrial = 0;
                elseif istable(behaviorData)
                    nTrial = height(behaviorData);
                else
                    nTrial = size(behaviorData,1);
                end
            end
            function nTrial = getNeuralTrialCount(neuralData)
                if isempty(neuralData)
                    nTrial = 0;
                else
                    nTrial = size(neuralData,3);
                end
            end
            function value = getNumericTableValue(inputTable,fieldName,rowIdx)
                value = nan;
                if ismember(fieldName,inputTable.Properties.VariableNames)
                    tempValue = inputTable.(fieldName)(rowIdx);
                    if iscell(tempValue)
                        tempValue = tempValue{1};
                    end
                    if isnumeric(tempValue) && isscalar(tempValue)
                        value = tempValue;
                    end
                end
            end
            function label = getDayLabel(sessionInfo,selDay)
                label = '';
                if ~ismember('dayLabel',sessionInfo.Properties.VariableNames)
                    return
                end
                tempLabel = sessionInfo.dayLabel(selDay);
                if ~iscell(tempLabel)
                    tempLabel = cellstr(string(tempLabel));
                end
                tempLabel = tempLabel(~cellfun(@isempty,tempLabel));
                if isempty(tempLabel)
                    return
                end
                uniqueLabel = unique(tempLabel,'stable');
                taskPart = regexprep(uniqueLabel,'[EML]$','');
                if any(strcmp(uniqueLabel,'Int')) || ...
                        (any(strcmp(taskPart,'T1')) && any(strcmp(taskPart,'T2')))
                    label = 'Int';
                else
                    label = uniqueLabel{1};
                end
            end
            function temp = reshapeEmptyTrialArrays(temp)
                nonEmptyIdx = find(cellfun(@(x)(~isempty(x) && size(x,3) > 0),temp),1,'first');
                if isempty(nonEmptyIdx)
                    nonEmptyIdx = find(cellfun(@(x)(~isempty(x)),temp),1,'first');
                end
                if isempty(nonEmptyIdx)
                    return
                end
                templateSize = size(temp{nonEmptyIdx});
                if numel(templateSize) < 3
                    templateSize(3) = 1;
                end
                for ii = 1:length(temp)
                    if isempty(temp{ii}) || size(temp{ii},3) == 0
                        temp{ii} = nan(templateSize(1),templateSize(2),0,'single');
                    end
                end
            end 
            function dayInfo = applyManualChunkLabels(dayInfo)
                if ~isfield(obj.ops,'chunkDays') || isempty(obj.ops.chunkDays)
                    warning('trackingMode unrestrainedDays was used, but obj.ops.chunkDays is empty. Keeping existing dayInfo.dayLabel.')
                    return
                end
                labelOrder = {'T1E','T1M','T1L','T2E','T2M','T2L','Int'};
                manualChunks = obj.ops.chunkDays;
                if length(manualChunks) > length(labelOrder)
                    warning('obj.ops.chunkDays has %d chunks; only the first %d will be labeled as T1E..Int.', ...
                        length(manualChunks),length(labelOrder))
                end

                dayInfo.dayLabel = repmat({''},height(dayInfo),1);
                nLabelChunk = min(length(manualChunks),length(labelOrder));
                for ii = 1:nLabelChunk
                    selDay = manualChunks{ii};
                    selDay = selDay(selDay >= 1 & selDay <= height(dayInfo));
                    if isempty(selDay)
                        fprintf('parseDay unrestrainedDays: manual %s chunk has no valid day rows.\n',labelOrder{ii});
                        continue
                    end
                    dayInfo.dayLabel(selDay) = labelOrder(ii);
                    fprintf('parseDay unrestrainedDays: labeling day rows [%s] as %s.\n', ...
                        num2str(selDay(:)'),labelOrder{ii});
                end
            end
            function tf = isTextScalar(value)
                tf = ischar(value) || (isstring(value) && isscalar(value));
            end
            function tf = isParseDayParameter(value)
                value = lower(char(value));
                tf = any(strcmp(value,{'trackingmode','minsessionsperlearningperiod'}));
            end
        end 

        function [ishereSession,sessionCount,sessionSel] = selTracking(obj,trackingMode,varargin)
            if ~exist('trackingMode','var') || isempty(trackingMode); trackingMode = 'stageBalanced'; end
            p = inputParser;
            addParameter(p,'minSessionsPerLearningPeriod',8);
            parse(p,varargin{:});
            minSessionsPerLearningPeriod = p.Results.minSessionsPerLearningPeriod;
            if ~isnumeric(minSessionsPerLearningPeriod)
                error('minSessionsPerLearningPeriod must be numeric.')
            end
            if isempty(minSessionsPerLearningPeriod)
                minSessionsPerLearningPeriod = 8;
            else
                minSessionsPerLearningPeriod = minSessionsPerLearningPeriod(1);
            end
            if isnan(minSessionsPerLearningPeriod)
                minSessionsPerLearningPeriod = 8;
            end
            minSessionsPerLearningPeriod = max(1,ceil(minSessionsPerLearningPeriod));
            tempTrackingSession = fn_cell2mat(obj.sessionInfo.ishere,1); 
            offsetMap = fn_cell2mat(obj.sessionInfo.offsetMap,3);

            avgOffset = squeeze(nanmean(nanmean(offsetMap,1),2))...
                - obj.alignmentOps.refStackSelLoc(4); 
            ishereMat = tempTrackingSession == 1;
            nSession = size(ishereMat,1);
            nNeuron = size(ishereMat,2);
            singleSessionCount = sum(ishereMat,2);

            switch lower(trackingMode)
                case {'unrestraineddays','unrestrained'}
                    [ishereSession,sessionCount,sessionSel] = selectUnrestrainedDays();
                case {'stagebalanced','stages','stage'}
                    [ishereSession,sessionCount,sessionSel] = selectStageBalanced();
                otherwise
                    error('Unknown tracking mode: %s',trackingMode)
            end

            function [ishereSession,sessionCount,sessionSel] = selectUnrestrainedDays()
            selectedIdx = [];
            availableIdx = true(nSession,1);
            currentHere = true(1,nNeuron);
            ishereSession = {};
            sessionCount = [];
            sessionSel = {};

            for k = 1:nSession
                candidateIdx = find(availableIdx);
                bestIdx = chooseBestCandidate(candidateIdx,currentHere);

                selectedIdx = [selectedIdx; bestIdx];
                availableIdx(bestIdx) = false;
                currentHere = currentHere & ishereMat(bestIdx,:);

                ishereSession{k} = currentHere;
                sessionCount(k) = sum(currentHere);
                sessionSel{k} = selectedIdx;
            end 
            fprintf('selTracking unrestrainedDays: selected %d sessions; %d common neurons.\n', ...
                length(selectedIdx),sessionCount(end));
            end

            function [ishereSession,sessionCount,sessionSel] = selectStageBalanced()
            stageLabels = {'T1E','T1M','T1L','T2E','T2M','T2L','Int'};
            if ~ismember('dayLabel',obj.sessionInfo.Properties.VariableNames)
                warning('dayLabel not found in sessionInfo. Falling back to unrestrainedDays tracking.')
                [ishereSession,sessionCount,sessionSel] = selectUnrestrainedDays();
                return
            end

            dayLabel = obj.sessionInfo.dayLabel;
            if ~iscell(dayLabel)
                dayLabel = cellstr(string(dayLabel));
            end
            nPerStage = minSessionsPerLearningPeriod;
            stageAvailable = zeros(length(stageLabels),1);
            activeStageFlag = true(length(stageLabels),1);
            for stageIdx = 1:length(stageLabels)
                stageAvailable(stageIdx) = sum(strcmp(dayLabel,stageLabels{stageIdx}));
                if stageAvailable(stageIdx) == 0
                    activeStageFlag(stageIdx) = false;
                    fprintf('selTracking stageBalanced: skipping %s, no sessions found.\n',stageLabels{stageIdx});
                end
            end
            activeStageLabels = stageLabels(activeStageFlag);
            if isempty(activeStageLabels)
                warning('No learning period has enough sessions for stageBalanced tracking. Falling back to unrestrainedDays tracking.')
                [ishereSession,sessionCount,sessionSel] = selectUnrestrainedDays();
                return
            end

            selectedIdx = [];
            availableIdx = true(nSession,1);
            currentHere = true(1,nNeuron);
            ishereSession = {};
            sessionCount = [];
            sessionSel = {};
            k = 0;

            for roundIdx = 1:nPerStage
                for stageIdx = 1:length(activeStageLabels)
                    candidateIdx = find(availableIdx & strcmp(dayLabel,activeStageLabels{stageIdx}));
                    if isempty(candidateIdx)
                        continue
                    end
                    bestIdx = chooseBestCandidate(candidateIdx,currentHere);
                    selectedIdx = [selectedIdx; bestIdx];
                    availableIdx(bestIdx) = false;
                    currentHere = currentHere & ishereMat(bestIdx,:);

                    k = k + 1;
                    ishereSession{k} = currentHere;
                    sessionCount(k) = sum(currentHere);
                    sessionSel{k} = selectedIdx;
                end
            end

            if isempty(selectedIdx)
                warning('No sessions matched T1E/T1M/T1L/T2E/T2M/T2L/Int labels. Falling back to unrestrainedDays tracking.')
                [ishereSession,sessionCount,sessionSel] = selectUnrestrainedDays();
                return
            end

            fprintf('selTracking stageBalanced: selected %d sessions; %d common neurons.\n', ...
                length(selectedIdx),sessionCount(end));
            fprintf('  target per learning period: %d sessions\n',nPerStage);
            for stageIdx = 1:length(stageLabels)
                nAvailable = stageAvailable(stageIdx);
                nSelected = sum(strcmp(dayLabel(selectedIdx),stageLabels{stageIdx}));
                fprintf('  %s: selected %d/%d sessions\n',stageLabels{stageIdx},nSelected,nAvailable);
            end
            end

            function bestIdx = chooseBestCandidate(candidateIdx,currentHere)
            candidateCount = nan(length(candidateIdx),1);
            for c = 1:length(candidateIdx)
                candidateCount(c) = sum(currentHere & ishereMat(candidateIdx(c),:));
            end

            candidateOffset = abs(avgOffset(candidateIdx));
            if numel(candidateOffset) ~= numel(candidateCount)
                candidateOffset = nan(size(candidateCount));
            end
            candidateOffset(isnan(candidateOffset)) = inf;
            candidateSingleCount = singleSessionCount(candidateIdx);
            [~,sortOrder] = sortrows([-candidateCount(:), -candidateSingleCount(:), candidateOffset(:)]);
            bestIdx = candidateIdx(sortOrder(1));
            end
        end 

        function [obj,selTable] = selNeuronTime(obj,varargin)
            % selectVar: e.g. {'choice','behSel'}
            % varargin:selProp, selTime, selNeuron
            p = inputParser;
            addParameter(p, 'selProp', 'chunkedDayInfo');
            addParameter(p, 'selNeuron', []);
            addParameter(p, 'selTime', []);
            addParameter(p, 'replace', false);
            parse(p, varargin{:});

            selTable = obj.(p.Results.selProp);
            dffNames = {'dffStim','dffChoice'};
            for i = 1:length(dffNames)
                temp = [];
                if any(strcmp(dffNames{i}, selTable.Properties.VariableNames))
                    if ~isempty(p.Results.selNeuron) && ~isempty(p.Results.selTime)
                        temp = cellfun(@(x)(x(p.Results.selNeuron,p.Results.selTime,:)),selTable.(dffNames{i}) ,'UniformOutput',false);
                    elseif ~isempty(p.Results.selNeuron) && isempty(p.Results.selTime)
                        temp = cellfun(@(x)(x(p.Results.selNeuron,:,:)),selTable.(dffNames{i}) ,'UniformOutput',false);
                    elseif isempty(p.Results.selNeuron) && ~isempty(p.Results.selTime)
                        temp = cellfun(@(x)(x(:,p.Results.selTime,:)),selTable.(dffNames{i}) ,'UniformOutput',false);
                    end 
                    selTable.(dffNames{i}) = temp;       
                end 
            end 
            if p.Results.replace; obj.(p.Results.selProp) = selTable; end



        end 
      
        function obj = chunkDays(obj,selectedVar,chunks)
            dataTable = obj.dayInfo;
            if nargin < 2 || isempty(selectedVar)
                error('selectedVar is required. Use obj.chunkDays(selectedVar) or obj.chunkDays(selectedVar,chunks).')
            end
            if nargin < 3 || isempty(chunks)
                [chunks,chunkLabels] = getLabelChunks(dataTable);
            else
                chunkLabels = repmat({''},numel(chunks),1);
            end
            % Chunk a per-day table into larger aggregated table based on day groups
            % Inputs:
            %   - dataTable: (ndays × m) table
            %   - chunks: cell array of vectors of day indices, e.g. {[1 2 3], [4], [5 6 7]}
            %   - selectedVar (optional): string, name of a variable in the table to return only
            % Output:
            %   - outTable: table where each row corresponds to a chunk
            if ischar(selectedVar) || isstring(selectedVar)
                selectedVar = cellstr(string(selectedVar));
            end
            if all(ismember(selectedVar, dataTable.Properties.VariableNames))
                varNames = selectedVar;
            else
                missingVar = selectedVar(~ismember(selectedVar, dataTable.Properties.VariableNames));
                error('Selected variable(s) not found in dayInfo: %s',strjoin(missingVar,', '))
            end        
            nChunks = numel(chunks);
            outTable = table();      
            for v = 1:numel(varNames)                 
                for i = 1:nChunks
                    days = chunks{i};
                    if isempty(days)
                        outTable.(varNames{v}){i} = [];
                        continue
                    end
                    val = dataTable{days, varNames{v}};         
                    if istable(val)
                        combined = vertcat(val{:});  
                        outTable.(varNames{v}){i} = combined;
                    elseif iscell(val)

                        innerVal = val{1};
                        if ischar(innerVal) || isstring(innerVal)
                            combined = {string(val)};
                        elseif isnumeric(innerVal) && ndims(innerVal) == 3
                            combined = cat(3, val{:});
                        elseif isnumeric(innerVal) && ismatrix(innerVal)
                            combined = cat(2, val{:});
                        elseif isnumeric(innerVal) && isscalar(innerVal) 
                            combined = cat(1, val{:});
                        elseif istable(innerVal)
                            combined = cat(1, val{:});
                        elseif isstruct(innerVal)
                            disp(['Variable ' varNames{v} ' -- structures are not considered in the code!'])
                        end
                        outTable.(varNames{v}){i} = combined;
                    elseif isnumeric(val)
                        outTable.(varNames{v}){i} = val;
                    elseif isstruct(val)
                        disp(['Variable ' varNames{v} ' -- structures are not considered in the code!'])
                    end            
                end
            end
            obj.chunkedDayInfo = outTable; 
            obj.ops.chunkDays = chunks; 
            obj.ops.chunkDaysLabel = chunkLabels;
            function [chunks,chunkLabels] = getLabelChunks(dayInfo)
                if ~ismember('dayLabel',dayInfo.Properties.VariableNames)
                    error('dayInfo.dayLabel is required for label-based chunking. Pass chunks as the third input to use manual chunks.')
                end
                labelOrder = {'T1E','T1M','T1L','T2E','T2M','T2L','Int'};
                dayLabel = dayInfo.dayLabel;
                if ~iscell(dayLabel)
                    dayLabel = cellstr(string(dayLabel));
                end
                chunks = {};
                chunkLabels = {};
                for ii = 1:length(labelOrder)
                    selDay = find(strcmp(dayLabel,labelOrder{ii}));
                    if isempty(selDay)
                        fprintf('chunkDays: no days found for %s; skipping this chunk.\n',labelOrder{ii});
                        continue
                    end
                    chunks{end+1} = selDay;
                    chunkLabels{end+1} = labelOrder{ii};
                    fprintf('chunkDays: %s uses day rows [%s].\n',labelOrder{ii},num2str(selDay(:)'));
                end
                if isempty(chunks)
                    error('No labeled day chunks found. Check dayInfo.dayLabel.')
                end
            end
        end 
        
        function [obj,trialTypeInfo] = selTrialType(obj,varargin)
            p = inputParser;
            addParameter(p, 'selProp', 'dayInfo');
            addParameter(p, 'stim', []);
            addParameter(p, 'choice', []);
            addParameter(p, 'selectedVar', []);
            addParameter(p, 'trialSelCriteria', 'none');
            addParameter(p, 'trialStart', 30);
            parse(p, varargin{:});

            outmat = obj.(p.Results.selProp); selFlag= {};
            if isempty(p.Results.selectedVar)
                varNames = outmat.Properties.VariableNames;
            else
                if ismember(p.Results.selectedVar, outmat.Properties.VariableNames)
                    varNames = p.Results.selectedVar;
                else
                    warning('Variable "%s" not found in table. Returning full table.', selectedVar);
                    varNames = outmat.Properties.VariableNames;
                end
            end 
            stim = p.Results.stim; choice = p.Results.choice; trialStart = p.Results.trialStart;
            for i = 1:length(stim)
                switch p.Results.trialSelCriteria
    
                    case 'none'
                        selFlag{i} = cellfun(@(x)(x.stimuli==stim(i) & x.action==choice(i)), outmat.behSel,'UniformOutput',false);
                    case 'RTfast'
                        selFlag{i} = cellfun(@(x)(x.stimuli==stim(i) & x.action==choice(i) & x.RT>=0.17...
                            & x.RT<=0.3), outmat.behSel,'UniformOutput',false);
                    case 'RTslow'
                        selFlag{i} = cellfun(@(x)(x.stimuli==stim(i) & x.action==choice(i) & x.RT>=0.5...
                            & x.RT<=2.5), outmat.behSel,'UniformOutput',false);
                    case 'stim'
                        if isempty(p.Results.choice)
                            selFlag{i} = cellfun(@(x)(x.stimuli==stim(i)), outmat.behSel,'UniformOutput',false);
                        else
                            selFlag{i} = cellfun(@(x)(x.stimuli==stim(i) & x.action==choice(i)), outmat.behSel,'UniformOutput',false);
                        end 
                        for k = 1:size(outmat.behSel,1)
                            wheelPos = cat(1,diff(outmat.wheelStim{k},1,1),zeros(1,size(outmat.wheelStim{k},2)));
                            wheelSum = nansum(abs(wheelPos(trialStart+1:trialStart+5,:)),1);
                            noWheelTrialSel = wheelSum <= 5;
                            selFlag{i}{k} = selFlag{i}{k} & noWheelTrialSel';
                        end 
                        

                    
    
                    case 'choice'

    
                end
            end 


            for j = 1:length(varNames)
                tempVar = outmat.(varNames{j});
                if iscell(tempVar)
                    newVar = cell(1,length(stim));
                    for i = 1:length(stim)
                          
                        tempContent = tempVar{1}; 
                        validateTrialMaskLengths(tempVar,selFlag{i},varNames{j},i,tempContent);
                        if isnumeric(tempContent)
                            if ~isscalar(tempContent) && ndims(tempContent)==3
                                newVar{i}= cellfun(@(x,y)(x(:,:,y)),tempVar,selFlag{i},'UniformOutput',false);
                            elseif ~isscalar(tempContent) && ismatrix(tempContent)
                                newVar{i}= cellfun(@(x,y)(x(:,y)),tempVar,selFlag{i},'UniformOutput',false);
                            end 
                        elseif islogical(tempContent)
                        elseif istable(tempContent)
                            newVar{i}= cellfun(@(x,y)(x(y,:)),tempVar,selFlag{i},'UniformOutput',false);
                        elseif isstruct(tempContent)                       
                        end 
                    end 
                    reshapeVar = {}; 
                    for m = 1:length(newVar{1}); for n = 1:length(newVar); reshapeVar{m}{n} = newVar{n}{m}; end ;end
                    if ~isempty(reshapeVar)
                        if strcmp(varNames{j},'behSel'); outmat.('behSelTrialType') = reshapeVar';
                        else; outmat.(varNames{j}) = reshapeVar'; end 
                    end 
                end 
            end   
            obj.trialTypeInfo = outmat;
            trialTypeInfo = outmat;

            function validateTrialMaskLengths(dataCell,flagCell,varName,trialTypeIdx,tempContent)
                if numel(dataCell) ~= numel(flagCell)
                    error('Animal:ChunkCountMismatch', ...
                        ['Variable %s contains %d chunks, but trial-type mask %d ' ...
                        'contains %d chunks.'], ...
                        varName,numel(dataCell),trialTypeIdx,numel(flagCell));
                end
                for iChunk = 1:numel(dataCell)
                    dataValue = dataCell{iChunk};
                    expectedTrial = numel(flagCell{iChunk});
                    if isempty(dataValue)
                        actualTrial = 0;
                    elseif istable(dataValue)
                        actualTrial = height(dataValue);
                    elseif isnumeric(dataValue) || islogical(dataValue)
                        if startsWith(lower(varName),'dff') || ndims(tempContent)==3
                            actualTrial = size(dataValue,3);
                        else
                            actualTrial = size(dataValue,2);
                        end
                    else
                        continue
                    end
                    if expectedTrial ~= actualTrial
                        error('Animal:TrialCountMismatch', ...
                            ['Cannot select trial type %d from variable %s, chunk %d: ' ...
                            'behavior mask has %d trials but the data contain %d. ' ...
                            'Check session-level exclusions before chunking.'], ...
                            trialTypeIdx,varName,iChunk,expectedTrial,actualTrial);
                    end
                end
            end
        end   

        function [obj,chunkedDayInfo,trialTypeInfo] = chunkDaysByTrialType(obj,selVar,varargin)
            % selectVar: e.g. {'choice','behSel'}
            % varargin: selTime, chunkDays,selProp,stim,choice
            p = inputParser;
            addParameter(p, 'chunkDays', []);
            addParameter(p, 'selProp', 'chunkedDayInfo');
            addParameter(p, 'stim', [1,1,2,2,3,3,4,4]);
            addParameter(p, 'choice', [1,2,1,2,1,2,1,2]);
            addParameter(p, 'selTime', []);
            addParameter(p, 'trialSelCriteria', 'none');
            parse(p, varargin{:});

            trialStart = 30; if ~isempty(p.Results.selTime); trialStart = trialStart-p.Results.selTime(1)+1; end 
            obj = obj.chunkDays(selVar,p.Results.chunkDays);
            obj = obj.selNeuronTime('selProp',p.Results.selProp,'selNeuron',obj.ops.ishereAll,'selTime',p.Results.selTime,'replace',true);
            % also parse wheel time
            if ismember('wheelStim',obj.chunkedDayInfo.Properties.VariableNames)
                wheelStim = obj.chunkedDayInfo.wheelStim;
                wheelStim = cellfun(@(x)(x(p.Results.selTime,:)),wheelStim,'UniformOutput',false);
                obj.chunkedDayInfo.wheelStim = wheelStim;
            end

            if ismember('wheelChoice',obj.chunkedDayInfo.Properties.VariableNames)
                wheelChoice = obj.chunkedDayInfo.wheelChoice;
                wheelChoice = cellfun(@(x)(x(p.Results.selTime,:)),wheelChoice,'UniformOutput',false);
                obj.chunkedDayInfo.wheelChoice = wheelChoice;
            end

            chunkedDayInfo = obj.chunkedDayInfo; 
            [obj,trialTypeInfo] = obj.selTrialType('selProp',p.Results.selProp,'stim',p.Results.stim,'choice',p.Results.choice,...
                'trialSelCriteria',p.Results.trialSelCriteria,'trialStart',trialStart);
        end 
    
        function obj = buildGLM(obj)
            nNeuron = size( obj.chunkedDayInfo.dffStim{1},1);
            preTone = 10; 
            % all use the choice-aligned dffbehSel
            for day = 1:size(obj.chunkedDayInfo,1)
                regParam = cell(nNeuron,1);
                regRvalue = zeros(nNeuron,1);

                behSel =  obj.chunkedDayInfo.behSel{day};
                missFlag = behSel.choice==0;

                behSel = behSel(~missFlag,:);
                dff = obj.chunkedDayInfo.dffStim{day}(:,:,~missFlag); 
                wheelStim = obj.chunkedDayInfo.wheelStim{day}(:,~missFlag); 

                stim1Reg = zeros(size(wheelStim));
                stim2Reg = zeros(size(wheelStim));
                rewReg = zeros(size(wheelStim));
                platformReg = zeros(size(wheelStim));
                choice1ProgressReg = zeros(size(wheelStim));
                choice2ProgressReg = zeros(size(wheelStim));
                wheelReg = cat(1,diff(wheelStim,1,1),zeros(1,size(behSel,1)));

                stim1Flag = behSel.stimuli==1; stim1Reg (preTone+1,stim1Flag) = 1;
                stim2Flag = behSel.stimuli==2; stim2Reg (preTone+1,stim2Flag) = 1;
             
            
                rewardFlag = find(~isnan(behSel.rewardFrame)); rewardFrame = behSel.rewardFrame - behSel.stimFrame+preTone+1;
                for i = 1:length(rewardFlag)
                    rewReg(rewardFrame(rewardFlag(i)),rewardFlag(i)) = 1;
                    platformEndFrame = rewardFrame(rewardFlag(i))+30;
                    platformEndFrame(platformEndFrame>size(platformReg,1)) = size(platformReg,1);
                    platformReg(rewardFrame(rewardFlag(i)):platformEndFrame,rewardFlag(i)) = 1; 
                end 

                wheelRegL = wheelReg; wheelRegL(wheelReg<0) = 0; 
                wheelRegR = wheelReg; wheelRegR(wheelReg>0) = 0; wheelRegR = abs(wheelRegR);
                wheelRegChoiceL = wheelReg; wheelRegChoiceR = wheelReg;
                for i = 1:size(wheelReg,2)
                    choiceFrames = (preTone+1):(behSel.choiceThreFrame(i)-behSel.stimFrame(i)+preTone+2);
                    if behSel.choice(i)==1
                        wheelRegChoiceL(choiceFrames,i) = wheelRegL(choiceFrames,i);
                    else
                        wheelRegChoiceR(choiceFrames,i) = wheelRegR(choiceFrames,i);
                    end 

                end

                stim1Reg = shiftReg(stim1Reg,0,4);
                stim2Reg = shiftReg(stim2Reg,0,4);
                wheelRegChoiceLShift = shiftReg(wheelRegChoiceL,-2,2);
                wheelRegChoiceRShift = shiftReg(wheelRegChoiceR,-2,2);
                wheelRegLShift = shiftReg(wheelRegL,-2,2);
                wheelRegRShift = shiftReg(wheelRegR,-2,2);
                rewRegShift = shiftReg(rewReg,-1,5);

                regressorSet = cat(3,stim1Reg,stim2Reg,wheelRegChoiceLShift,wheelRegChoiceRShift,wheelRegLShift,wheelRegRShift,rewRegShift,platformReg);
                regressorSetZ = reshape(regressorSet,size(regressorSet,1)*size(regressorSet,2),[]); 
                regressorSetZ = zscore(regressorSetZ,0,1);regressorSetZ = reshape(regressorSetZ,size(regressorSet,1),size(regressorSet,2),[]); 
                X = reshape(regressorSetZ, [], size(regressorSet,3)); 
                intercepts = zeros(nNeuron,1);


                for neuron = 1:nNeuron
                    tic; disp(['Neuron ' int2str(neuron)]); 
                    try
                        Y = squeeze(double(dff(neuron,:,:)))*100; Y = Y + 1e-06; 
                        % Choose distribution and link function:
                        distribution = 'normal';   % 'normal', 'poisson', 'gamma'
                        link = 'log';             % good for positive data
                        
                        opts = statset('MaxIter', 200); % or lower, e.g., 1e3
                        % Regularization: use lassoglm
                        [beta, fitinfo] = lassoglm(X, Y(:), distribution, ...
                            'Link', link, ...
                            'Alpha', 1, ...      % 1 = Lasso (L1), 0 = Ridge (L2), between = Elastic Net
                            'Lambda', 1e-02, ...  % Regularization path
                            'CV', 10,'Options', opts);           % 10-fold cross-validation
                        toc;
                        % Get the best model:
                        idxLambdaMinDeviance = fitinfo.IndexMinDeviance;
                        bestBeta = beta(:, idxLambdaMinDeviance);
                        intercepts(neuron) = fitinfo.Intercept(idxLambdaMinDeviance);                        
                        % Prediction:
                        try
                            yhat = glmval([intercepts(neuron); bestBeta], X, link);
                            yhat = reshape(yhat,size(dff,2),size(dff,3));
                        catch
                            disp(['Neuron fit not great' int2str(neuron)])
    
                        end
                        regParam{neuron} = bestBeta;
                        regRvalue(neuron) = corr(Y(:),yhat(:));
                    catch
                        disp(['Neuron fit failed' int2str(neuron)])
                    end
                end 
                save(['GLMFit_day' int2str(day) '.mat'],'regParam','intercepts','regRvalue');
            end 
            
            function newReg = shiftReg(reg,shiftStart,shiftEnd)
                nReg = shiftStart:shiftEnd;
                newReg = nan(size(reg,1),size(reg,2),length(nReg));
                for k = 1:length(nReg)
                    newReg(:,:,k) = circshift(reg,nReg(k),1);
                end 

            end 
        end 

        function visualizePSTHcluster(obj)
            clusterFlag = obj.analysis.initialClustering.label(obj.ops.ishereAll);
            clusterFlag2 = obj.analysis.secondClustering.label(obj.ops.ishereAll);
            tempData = obj.trialTypeInfo.dffStim;

            plotIdx = [1 4 5 8];
            figure; 
            for k =1:4
                for i = 1:length(plotIdx)
                    subplot(4,length(plotIdx),i+(k-1)*4); 
                    for j = 1:length(tempData)
                        plot(nanmean(nanmean(tempData{j}{plotIdx(i)}(clusterFlag2==k,:,:),1),3)); hold on; 
                    end 
                    legend({'T1-1','T1-2','T1-3','T2-2','T2-3','T1T2'})
                end
            end 
            


        end 

        function visualizePSTH(obj, stim,choice, varargin)
            p = inputParser; addParameter(p,'missFlag',false); addParameter(p,'closeupFlag',false); parse(p,varargin{:});

            % this is the old day-by day code to look at the PSTH
            computePSTH(obj,'stim',stim,choice,p.Results.missFlag,p.Results.closeupFlag);
            computePSTH(obj,'choice',stim,choice,p.Results.missFlag,p.Results.closeupFlag);    
        end

        
    end
end

function selAct = computePSTH(obj,alignStr,missFlag,closeupFlag)
% plot PSTH function
    probeFlag = false; 
    selDay = find(cell2mat(obj.dayInfo.isheresum)>(0.65*length(obj.dayInfo.ishere{1})));
    selDayIshere = fn_cell2mat(obj.dayInfo.ishere(selDay),1);
    ishereAllDay = all(selDayIshere,1);

    switch alignStr
        case 'stim'
            selAct = obj.dayInfo.dffStim;
        case 'choice'
            selAct = obj.dayInfo.dffChoice;
        case 'reward'
            selAct = obj.dayInfo.dffReward;
    end 
    
    selBeh = obj.dayInfo.behSel;
    selAct = cellfun(@(x)((x(ishereAllDay,:,:))),selAct,'UniformOutput',false);
    selAct = selAct(selDay); selBeh = selBeh(selDay);

    tempMeanColorAxis = cellfun(@(x)(nanmean(x,3)),selAct,'UniformOutput',false);
    tempMeanColorAxis = max(cellfun(@(x)(prctile(x(:),99)),tempMeanColorAxis));

    [~,sortIdx] = sort(nanmean(nanmean(selAct{19}(:,31:40,:),3),2),'descend');

    f1 = figure; climmm = [-tempMeanColorAxis tempMeanColorAxis];
    xAxLabel = (1:100)/15-2; sortFrames = 31:40;tempMax = [];tempMin = [];
    for i = 1:length(selAct)
        tempBehav = selBeh{i};tempMean = {};tempRT = {};
        if ~probeFlag & ~missFlag & ~strcmp(alignStr,'reward')
            tempFlag =  {tempBehav.stimuli==1 & tempBehav.choice==1,...
                tempBehav.stimuli==1 & tempBehav.choice==2,...
                tempBehav.stimuli==1 & tempBehav.choice==0,...
                tempBehav.stimuli==2 & tempBehav.choice==2,...
                tempBehav.stimuli==2 & tempBehav.choice==1,...
                tempBehav.stimuli==2 & tempBehav.choice==0,...
                tempBehav.stimuli==3 & tempBehav.choice==1,...
                tempBehav.stimuli==3 & tempBehav.choice==2,...
                tempBehav.stimuli==3 & tempBehav.choice==0,...
                tempBehav.stimuli==4 & tempBehav.choice==2,...
                tempBehav.stimuli==4 & tempBehav.choice==1,...
                tempBehav.stimuli==4 & tempBehav.choice==0}; 
            subplotNum = length(tempFlag)+2; 
        elseif ~probeFlag & missFlag & ~strcmp(alignStr,'reward')
            tempFlag =  {tempBehav.stimuli==1 & tempBehav.choice==1,...
                tempBehav.stimuli==1 & tempBehav.choice==2,...
                tempBehav.stimuli==2 & tempBehav.choice==2,...
                tempBehav.stimuli==2 & tempBehav.choice==1,...
                tempBehav.stimuli==3 & tempBehav.choice==1,...
                tempBehav.stimuli==3 & tempBehav.choice==2,...
                tempBehav.stimuli==4 & tempBehav.choice==2,...
                tempBehav.stimuli==4 & tempBehav.choice==1}; 
            subplotNum = length(tempFlag)+2; 
        elseif strcmp(alignStr,'reward')
            tempFlag =  {tempBehav.stimuli==1 & tempBehav.choice==1 & tempBehav.outcome~=2,...
                tempBehav.stimuli==1 & tempBehav.choice==1 & tempBehav.outcome==2,...
                tempBehav.stimuli==2 & tempBehav.choice==2 & tempBehav.outcome~=2,...
                tempBehav.stimuli==2 & tempBehav.choice==2 & tempBehav.outcome==2,...
                tempBehav.stimuli==3 & tempBehav.choice==1 & tempBehav.outcome~=2,...
                tempBehav.stimuli==3 & tempBehav.choice==1 & tempBehav.outcome==2,...
                tempBehav.stimuli==4 & tempBehav.choice==2 & tempBehav.outcome~=2,...
                tempBehav.stimuli==4 & tempBehav.choice==2 & tempBehav.outcome==2}; 
            subplotNum = length(tempFlag)+2; 
            
        else
            tempFlag =  {tempBehav.stimuli==stim & tempBehav.choice==choiceStim & tempBehav.outcome~=2,...
                tempBehav.stimuli==stim & tempBehav.choice==choiceStim & tempBehav.outcome==2,...
                tempBehav.stimuli==stim & tempBehav.choice==3-choiceStim & tempBehav.outcome~=2,...
                tempBehav.stimuli==stim & tempBehav.choice==3-choiceStim & tempBehav.outcome==2,...
                tempBehav.stimuli==stim & tempBehav.choice==0 & tempBehav.outcome~=2,...
                tempBehav.stimuli==stim & tempBehav.choice==0 & tempBehav.outcome==2}; 
            subplotNum = 8; 
        end 


        for j = 1:length(tempFlag)
            subplot_tight(subplotNum,length(selAct),i+length(selAct)*(j),[0.002 0.002]); 
            %if j==1
            %    [sortIdx] = fn_plotPSTH(selAct{i},'sortIdx','descend','sortSelIdx',sortFrames,...
            %        'selFlag',tempFlag{j},'xaxis',xAxLabel); hold on; clim(climmm);
            %else
            %    fn_plotPSTH(selAct{i},'sortIdx',sortIdx,...
            %        'selFlag',tempFlag{j},'xaxis',xAxLabel); hold on; clim(climmm);
            %end 
            fn_plotPSTH(selAct{i},'sortIdx',sortIdx,...
                'selFlag',tempFlag{j},'xaxis',xAxLabel); hold on; clim(climmm);
            tempRT = nanmean(tempBehav.RT(tempFlag{j}));
            switch alignStr
                case 'stim'
                    xline(tempRT, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1.5);
                case 'choice'
                    xline(-tempRT, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1.5);
                case 'reward'
                    xline(-tempRT-0.2, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1.5);
            end 
            xline(0, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1.5);
            if i~=1; yticks([]); end
            if j~=length(tempFlag); xticks([]); end 
            [~,tempAcc,~,~,~,~] = fn_getAccBias(tempBehav.stimuli, tempBehav.outcome==1,tempBehav.choice==0);
            if j==1; title(['acc=' num2str(tempAcc,'%.2f')]); end 
            if closeupFlag; xlim([-1.2 1.2]); end 

            if probeFlag
                if j==2 
                    tempAct = tempBehav(tempBehav.stimuli==stim & tempBehav.outcome==2,6); 
                    tempProbeAcc = sum(tempAct==choiceStim) / sum(tempAct~=0); 
                    title(['Probe s' int2str(stim), ', acc=' num2str(tempProbeAcc)])
                elseif j==4
                    title('Probe incorrect')
                elseif j==6
                    title('Probe miss')
                end 

            end 
        end 
        %tempMax(i) = max(fn_cell2mat(tempMean,2)); tempMin(i) = min(fn_cell2mat(tempMean,2)); 
        
    end 
    
     
    subplot_tight(subplotNum+5,1,1,[0.002 0.002]);
    if ~closeupFlag; tempStr = [strrep(obj.ID, '_', '__') ', aligned to ' alignStr ];
    else; tempStr = [strrep(obj.ID, '_', '__')  ', aligned to ' alignStr ', closeup']; end 
    fn_textOnPlot(tempStr, gca, 12);
    set(f1, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1])


    if closeupFlag; timeSel = 31:35; else; timeSel = 31:70; end 
    selAct_mean = {};
    for i = 1:length(selAct)
        tempBehav = selBeh{i};
        tempFlag =  {tempBehav.stimuli==1 & tempBehav.choice==1,...              
                tempBehav.stimuli==2 & tempBehav.choice==2}; 
        tempAct = cellfun(@(x)(nanmean(selAct{i}(:,timeSel,x),3)),tempFlag,'UniformOutput',false);
        selAct_mean{i} = fn_cell2mat(tempAct,2);
    end 
    selAct_mean = fn_cell2mat(selAct_mean,3); 
    if closeupFlag; selAct_mean = nanmean(selAct_mean,2); else; selAct_mean = smoothdata(selAct_mean,2,'movmean',3);end 
    selAct_corr1 = reshape(selAct_mean,size(selAct_mean,1)*size(selAct_mean,2),[]);
    corrValueT1 = corr(selAct_corr1,'rows','complete');


    selAct_mean = {};
    for i = 1:length(selAct)
        tempBehav = selBeh{i};
        tempFlag =  {tempBehav.stimuli==3 & tempBehav.choice==1,...
                tempBehav.stimuli==4 & tempBehav.choice==2}; 
        tempAct = cellfun(@(x)(nanmean(selAct{i}(:,timeSel,x),3)),tempFlag,'UniformOutput',false);
        selAct_mean{i} = fn_cell2mat(tempAct,2);
    end 
    selAct_mean = fn_cell2mat(selAct_mean,3);
    if closeupFlag; selAct_mean = nanmean(selAct_mean,2); else; selAct_mean = smoothdata(selAct_mean,2,'movmean',3);end 
    selAct_corr2 = reshape(selAct_mean,size(selAct_mean,1)*size(selAct_mean,2),[]);
    corrValueT2 = corr(selAct_corr2);
    figure; subplot(1,2,1); imagesc(corrValueT1);colorbar; subplot(1,2,2);imagesc(corrValueT2); colorbar

    tempCorr = [];
    for i = 1:size(selAct_corr2,2)
        temp = corrcoef(selAct_corr1(:,i),selAct_corr2(:,i));
        tempCorr(i) = temp(1,2); 
    end 
    figure; plot(tempCorr)

    saveas(f1,'C:\Users\zzhu34\Documents\tempdata\mesoFig\PSTH.png')
    %fn_figureSizePDF(f1,'C:\Users\zzhu34\Documents\tempdata\mesoFig', 'PSTH.pdf')


end 

% HELPER FUNCTIONS -- LOAD TC, ONE AREA OR MULTIPLE AREA
function actCell = loadTC(TCname,keyField)
     disp('Loading TC file') ;tic;
     if iscell(TCname) && length(TCname)>1
         actCell = cell(length(TCname));
         for l = 1:length(TCname)
            temp = load(TCname{l},keyField);
            actCell{l} = temp.(keyField);
            actCell{l} = cellfun(@single, actCell{l},'UniformOutput',false);
         end 
         clear temp;
     else
         temp = load(TCname,keyField);
         actCell = temp.(keyField); clear temp;
         actCell = cellfun(@single,actCell,'UniformOutput',false);
     end 
     reportActCellNan(actCell,keyField,'after load');
     toc; disp('Loading data done!')
end 

% HELPER FUNCTIONS -- LOAD TC
function actCell = spkNorm(actCell)
    reportActCellNan(actCell,'spk','before normalization');
    spkVarBef = fn_cell2mat(cellfun(@(x)(var(x,0,1)),actCell,'UniformOutput',false),1);   
    spkMeanBef = fn_cell2mat(cellfun(@(x)(nanmean(x,1)),actCell,'UniformOutput',false),1);    
    spkNorm = zeros(length(actCell),size(actCell{1},2)); 
    for i = 1:length(actCell)
        for j =1:size(actCell{i},2)
            tempTrace = actCell{i}(:,j);
            tempTrace = tempTrace(isfinite(tempTrace));
            temp = norm(tempTrace); 
            spkNorm(i,j) = temp;
        end 
    end 
    
    b = fn_cell2mat(cellfun(@(x)(size(x,1)),actCell,'UniformOutput',false),1);
    b = b./ sum(b);
    meanA = b' * spkNorm;
    badNorm = ~isfinite(meanA) | meanA == 0;
    if any(badNorm)
        fprintf('spkNorm: %d neurons had zero/invalid normalization; leaving those neurons unscaled.\n',sum(badNorm));
        meanA(badNorm) = 1;
    end
    
    for i = 1:length(actCell)
        actCell{i} = actCell{i} ./ repmat(meanA,[size(actCell{i},1) 1]);
    end 
    reportActCellNan(actCell,'spk','after normalization');
    spkVarAft = fn_cell2mat(cellfun(@(x)(var(x,0,1)),actCell,'UniformOutput',false),1);
    spkMeanAft = fn_cell2mat(cellfun(@(x)(nanmean(x,1)),actCell,'UniformOutput',false),1);
end 

function reportActCellNan(actCell,keyField,stageName)
    if isempty(actCell)
        fprintf('%s %s: empty cell array.\n',keyField,stageName);
        return
    end
    nCell = numel(actCell);
    nAll = 0;
    nNan = 0;
    nAllNanCell = 0;
    for i = 1:nCell
        if isempty(actCell{i})
            continue
        end
        nAll = nAll + numel(actCell{i});
        nNan = nNan + sum(isnan(actCell{i}(:)));
        nAllNanCell = nAllNanCell + all(isnan(actCell{i}(:)));
    end
    if nAll > 0
        fprintf('%s %s: %.3f%% NaN values across %d cells; %d all-NaN cells.\n', ...
            keyField,stageName,100*nNan/nAll,nCell,nAllNanCell);
    end
end

% HELPER FUNCTIONS -- LOAD sessionInf, rename the table variables
function [sessionInfo, alignmentOps] =getSessionInfo(infoName,actCell,trackingName,alignOpsPath,obj)
    % load sessionInfo
    load(infoName,'sessionInfo','animalID'); 

    sessionInfo = normalizeSessionInfo(sessionInfo);

    if isempty(actCell)
        sessionInfo.TC(:) = nan; 
    else
        sessionInfo.TC = actCell';
        sessionInfo = dealExceptions(sessionInfo,obj.ops.mouse);
    end

    load(trackingName,'ishereFinal','roiFinal');
    alignmentOps = load([alignOpsPath filesep 'ops.mat'],'ops');
    alignmentOps = alignmentOps.ops; 

    % construct tracking
    if size(sessionInfo,1) == size(ishereFinal,1)
    for i = 1:size(sessionInfo,1)
        sessionInfo.ishere{i} = ishereFinal(i,:);
        sessionInfo.roi{i} = roiFinal(i,:);
        sessionInfo.offsetMap{i} = alignmentOps.offsetMap(:,:,i);
    end
    else
        allDay = unique(sessionInfo.date);
        for i = 1:length(allDay)
            selDay = sessionInfo.date == allDay(i);
            sessionInfo.ishere(selDay) = {ishereFinal(i,:)};
            sessionInfo.roi(selDay) = {roiFinal(i,:)};
            sessionInfo.offsetMap(selDay) = {alignmentOps.offsetMap(:,:,i)};
        end 
    end             
    cellFlag = cellfun(@(x)(nanmean(x,2)) > 0.4,sessionInfo.ishere,'UniformOutput',true);
    sessionInfo.goodTracking = cellFlag;
    % sessionInfo.TC(~cellFlag) = {[]};
end 

function sessionInfo = normalizeSessionInfo(sessionInfo)
    if isstruct(sessionInfo)
        sessionInfo = struct2table(sessionInfo);
    end

    sessionInfo = renameSessionInfoVar(sessionInfo,'SessionName','sessionName');
    sessionInfo = renameSessionInfoVar(sessionInfo,'SessionDate','date');
    sessionInfo = renameSessionInfoVar(sessionInfo,'SessionType','sessionType');
    sessionInfo = renameSessionInfoVar(sessionInfo,'SessionNumber','session');
    sessionInfo = renameSessionInfoVar(sessionInfo,'SessionFrames','frames');
end

function sessionInfo = renameSessionInfoVar(sessionInfo,oldName,newName)
    varNames = sessionInfo.Properties.VariableNames;
    if ismember(oldName,varNames) && ~ismember(newName,varNames)
        sessionInfo.Properties.VariableNames{strcmp(varNames,oldName)} = newName;
    end
end


% HELPTER FUNCTION -- MATCH RT IN TRIALTYPEINFO


