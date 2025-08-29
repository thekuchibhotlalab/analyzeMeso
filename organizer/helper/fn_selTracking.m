function [ishereSession,sessionCount,sessionSel] = fn_selTracking(offsetMap,ishere, refLocation)


    avgOffset = squeeze(nanmean(nanmean(offsetMap,1),2))...
                - refLocation; 
    [~,sortIdx] = sort(abs(avgOffset),'ascend');
    for k = 1:size(ishere,1)
        temp = ishere(sortIdx(1:k),:);
        ishereSession{k} = all(temp,1);
        sessionCount(k) = sum(ishereSession{k});
        sessionSel{k} = sortIdx(1:k);
        % add day number on the original matrix 
    end 





end 
