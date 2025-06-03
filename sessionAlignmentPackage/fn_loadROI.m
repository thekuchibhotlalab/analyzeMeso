function [roisCoord] = fn_loadROI(varargin)
% Usage: [roisCoord] = fn_loadROI(varargin)
% if loading suite2p ROI, fn_loadROI('roiMethod','suite2p','roiPath',suite2ppath, 'nPlanes', 2)
% if loading imageJ ROI, fn_loadROI('roiMethod','imageJ','roiPath',imageJpath,'roiFile', 'roi.zip')

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('roiMethod', 'imageJ')
p.addParameter('nPlanes', 1)
p.addParameter('roiPath', pwd)
p.addParameter('roiFile', [])
p.addParameter('ylim', [])
p.addParameter('xlim', [])

p.parse(varargin{:});


disp('----Loading ROI----')
tic;
switch p.Results.roiMethod
    case 'suite2p' % suite2p 
        nPlanes = str2double(p.Results.nPlanes);
        tempRoi = cell(1,nPlanes);
        for i=1:nPlanes
            cd([p.Results.roiPath '\plane' num2str(i-1)]);
            data = load('Fall.mat'); 
            
            switch roiType
            case 'axon'
                iscellFlag = ~data.iscell(:,1);
            case 'cell'
                iscellFlag = data.iscell(:,1);
            end
            
            % if the target file is part of the TC, only extract that part
            neuronEachPlane(i) = sum(iscellFlag);
            tempRoi{i} = data.stat(logical(iscellFlag))';
        end 

        roisCoord = cell(1,nPlanes); % only 1 functional channel for suite2p
        for j = 1:nPlanes % number of planes
            roisCoord{j} = cell(1,length(tempRoi{j}));
            for k = 1:length(tempRoi{j}) % neuron in each plane 
                bound = boundary(double(tempRoi{j}{k}.xpix)', double(tempRoi{j}{k}.ypix)',1); % restricted bound
                tempCoord = [tempRoi{j}{k}.xpix(bound)' tempRoi{j}{k}.ypix(bound)'];
                roisCoord{j}{k}.Contour = tempCoord;
                if ~isempty(p.Results.xlim)
                    roisCoord{j}{k}.Mask = poly2mask(tempCoord(:,1), tempCoord(:,2),...
                        p.Results.xlim, p.Results.ylim);
                    tempProp = regionprops(roisCoord{j}{k}.Mask, 'Centroid');
                    roisCoord{j}{k}.Centroid = tempProp.Centroid;
                end
            end
        end
    case 'imageJ'
        roiFile = p.Results.roiFile;
        roisCoord = cell(1,length(roiFile));
        for j = 1:length(roiFile)
            roiName = [p.Results.roiPath filesep roiFile{j}];
            tempRoi = ReadImageJROI(roiName);
            roisCoord{j} = cell(1,length(tempRoi));
            for k = 1:length(tempRoi) % number of neurons in this plane
                % flip coord 1 and 2 here since roi mask flips x and y
                roisCoord{j}{k}.Contour = tempRoi{k}.mnCoordinates;
                if ~isempty(p.Results.xlim)
                    roisCoord{j}{k}.Mask = poly2mask(tempRoi{k}.mnCoordinates(:,1), tempRoi{k}.mnCoordinates(:,2),...
                        p.Results.xlim, p.Results.ylim);
                    tempProp = regionprops(roisCoord{j}{k}.Mask, 'Centroid');
                    roisCoord{j}{k}.Centroid = tempProp.Centroid;
                end
            end
        end

end
toc; 
end