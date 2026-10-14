function M=fn_taskActionMarginals(C)
%FN_TASKACTIONMARGINALS Balanced contrasts; columns retain the time bins.
M.task=(C(:,:,3)+C(:,:,4)-C(:,:,1)-C(:,:,2))/2;
M.action=(C(:,:,2)+C(:,:,4)-C(:,:,1)-C(:,:,3))/2;
M.interaction=(C(:,:,1)+C(:,:,4)-C(:,:,2)-C(:,:,3))/2;
grand=mean(C,3);
M.time=2*(grand-mean(grand,2)); % Scaling makes sum of energies equal total SS.
end
