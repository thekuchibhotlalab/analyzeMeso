function [outDff,selected_flags,selected_counts,new_means] = fn_matchRT(trialTypeInfo)
    nPeriod = length(trialTypeInfo.behSelTrialType); 
    nTrialType = length(trialTypeInfo.behSelTrialType{1});
    RT = {}; outDff = {};  
    for i = 1:length(trialTypeInfo.behSelTrialType)
        RT(i,:) = cellfun((@(x)(x.RT)),trialTypeInfo.behSelTrialType{i},'UniformOutput',false);
        outDff(i,:) = cellfun((@(x)(x)),trialTypeInfo.dffChoice{i},'UniformOutput',false);
    end
    RT_T1 = RT([1:3 7],[1 4]); RT_T2 = RT([4:6 7],[5 8]);

    outDffSel1 = outDff([1:3 7],[1 4]); outDffSel2 = outDff([4:6 7],[5 8]);
    outDff = cat(2,outDffSel1,outDffSel2);

    RT_T = cat(2,RT_T1,RT_T2);
    options.min_trials_percentage = 0.2; 
    options.tolerance = 0.05; 
    [selected_flags, selected_counts, new_means] = fn_selectMatchedTrials(RT_T,options);

    outDff = cellfun((@(x,y)(x(:,:,y))),outDff,selected_flags,'UniformOutput',false);
    
end 

