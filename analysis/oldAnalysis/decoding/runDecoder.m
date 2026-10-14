function [neuronW,neuronAcc,tempAccShuf] = runDecoder(data1,data2,subSample)

decodingLim = 100;
tempAcc = zeros(length(data1),decodingLim); 
tempAccShuf = zeros(length(data1),decodingLim,100); 

neuronAcc = zeros(size(data1{1},1),length(data1),decodingLim);
neuronW = zeros(size(data1{1},1),length(data1),decodingLim);
for i = 1:length(data1)
    tic;
    tempS1a1 = smoothdata(data1{i},2,'movmean',1); 
    tempS2a2 = smoothdata(data2{i},2,'movmean',1); 

    for j = 1:decodingLim
        % weights of all neurons
        tempIdx1 = floor(linspace(1,size(tempS1a1,3),subSample));
        tempIdx2 = floor(linspace(1,size(tempS2a2,3),subSample));

        temp1 = squeeze(tempS1a1(:,j,tempIdx1)); temp2 = squeeze(tempS2a2(:,j,tempIdx2));
        decoder = fn_runDecoder(temp1',temp2', 0.8);
        neuronAcc(:,i,j) = decoder.cellAcc(:,2);
        neuronW(:,i,j) = decoder.cellW;
        
    end 
    t = toc; disp(t)
end