function meanImg = fn_playMeanImg(imgpath,varargin)



    p = inputParser;
    p.KeepUnmatched = true;
    p.addParameter('saveflag', false);
    p.addParameter('alignMethod', 'rigid');
    p.parse(varargin{:})

    filename = dir([imgpath filesep '*meanImg.mat']);
    meanImg = {}; tempMedian = []; 
    for i = 1:length(filename)
        tic;
        temp = load([imgpath filesep filename(i).name]);
        meanImg{i} = temp.meanImg./ prctile(temp.meanImg(:),99.5);
        tempMedian(i) = median(meanImg{i}(:)); 
        toc
    end 
    normFactor = min(tempMedian) ./ tempMedian;
    for i = 1:length(filename); meanImg{i}  = meanImg{i} .* normFactor(i); end 
    

    if strcmp(p.Results.alignMethod,'consecutive')
        for i = 1:length(filename)
            if i>1
                patchwarp_results = patchwarp_across_sessions(meanImg{i-1},...
                    meanImg{i},'euclidean','affine', 12, 0.3, 0);   
                meanImg{i} = patchwarp_results.image2_warp2;
            end 
        end 
    elseif strcmp(p.Results.alignMethod,'midImg')
        refImg = meanImg{floor(length(filename)/2)};
        for i = 1:length(filename)
            patchwarp_results = patchwarp_across_sessions(refImg,...
                meanImg{i},'euclidean','affine', 12, 0.3, 0);   
            meanImg{i} = patchwarp_results.image2_warp2;
        end
    elseif strcmp(p.Results.alignMethod,'consecutiveMidImg')
        midIdx = ceil(length(filename)/2);
        for i = (midIdx+1):length(filename)
            patchwarp_results = patchwarp_across_sessions(meanImg{i-1},...
                meanImg{i},'euclidean','affine', 12, 0.3, 0);   
            meanImg{i} = patchwarp_results.image2_warp2;
        end
        for i = midIdx-1:-1:1
            patchwarp_results = patchwarp_across_sessions(meanImg{i+1},...
                meanImg{i},'euclidean','affine', 12, 0.3, 0);   
            meanImg{i} = patchwarp_results.image2_warp2;
        end
    end 
    meanImg = fn_cell2mat(meanImg,3);
    if strcmp(p.Results.alignMethod,'rigid')
        meanImg = fn_fastAlign(meanImg);
    end 

    implay(meanImg);

    if p.Results.saveflag
        save([imgpath filesep 'meanImgAligned_' p.Results.alignMethod '.mat'],'meanImg');

    end 
end 