function fn_plotPSTH(dffStim,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('sortIdx', 1:size(dffStim,1));
p.addParameter('selFlag', true(1,size(dffStim,3)));
p.addParameter('xaxis', 1:size(dffStim,2));
p.addParameter('yaxis', 1:size(dffStim,1));
p.addParameter('xlim', []);
p.addParameter('title', []);
p.parse(varargin{:});

if ~ischar(p.Results.sortIdx) && strcmp(p.Results.sortIdx,'descend')
    temp = nanmean(nanmean(dffStim(:,:,p.Results.selFlag),3),2); 
    [~,p.Results.sortIdx] = sort(temp,'descend');
end


tempPSTH = nanmean(dffStim(p.Results.sortIdx,:,p.Results.selFlag),3); 
imagesc(p.Results.xaxis, p.Results.yaxis, tempPSTH); 
try
    clim([-prctile(tempPSTH(:),98.5), prctile(tempPSTH(:),98.5)]); 
catch 
    disp('Check number of trials selected, might have been all nans')
end 
if ~isempty(p.Results.xlim); xlim([p.Results.xlim]); end 
title(p.Results.title)

end