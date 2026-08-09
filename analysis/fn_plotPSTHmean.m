function fn_plotPSTHmean(dffStim,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('sortIdx', 1:size(dffStim,1));
p.addParameter('selFlag', true(1,size(dffStim,3)));
p.addParameter('xaxis', 1:size(dffStim,2));
p.addParameter('yaxis', 1:size(dffStim,1));
p.addParameter('xlim', []);
p.parse(varargin{:});

tempPSTH = nanmean(dffStim(p.Results.sortIdx,:,p.Results.selFlag),3); 
fn_plotMeanErrorbar(p.Results.xaxis,tempPSTH,matlabColors(1),matlabColors(1),{},{'facealpha',0.2});
if ~isempty(p.Results.xlim); xlim([p.Results.xlim]); end 



end