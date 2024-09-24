function [flagList, titleList,flagListReshape,titleListReshape] = fn_selectStim(selectedBeh,task)
if task == 1; stimL = selectedBeh(:,5)==1; stimR = selectedBeh(:,5)==2;
elseif task==2; stimL = selectedBeh(:,5)==3; stimR = selectedBeh(:,5)==4; end 
choiceL = selectedBeh(:,6)==1; choiceR = selectedBeh(:,6)==2; miss = selectedBeh(:,6)==0;
flagList = {stimL & choiceL, stimR & choiceR, stimL & choiceR,...
     stimR & choiceL, stimL & miss,stimR & miss};
flagListReshape = reshape(flagList,2,3);
titleList = {'stimL & choiceL', 'stimR & choiceR', 'stimL & choiceR',...
    'stimR & choiceL', 'stimL & miss', 'stimR & miss'};
titleListReshape = reshape(titleList,2,3);
end 