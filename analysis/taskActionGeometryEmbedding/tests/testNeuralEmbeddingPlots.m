function tests=testNeuralEmbeddingPlots
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'helper_function')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'analysis','taskActionGeometryEmbedding')));
end
function testCombinedCoordinatesColorsAndExports(t)
[r,p]=fixture(); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.savePath=folder.Folder; before=findall(groot,'Type','figure');
[figs,files]=fn_plotNeuralEmbedding(r,p);
verifyEmpty(t,figs.umap); verifyTrue(t,isfile(files.umap));
verifyEqual(t,findall(groot,'Type','figure'),before);
f=openfig([files.umap(1:end-4) '.fig'],'new','invisible'); cleanup=onCleanup(@()close(f)); %#ok<NASGU>
a=findobj(f,'Tag','learningTime'); b=findobj(f,'Tag','task'); d=findobj(f,'Tag','action');
verifyNumElements(t,a,1); verifyNumElements(t,b,1);
verifyNumElements(t,d,1);
verifyEqual(t,a.XLim,b.XLim); verifyEqual(t,a.YLim,b.YLim);
verifyEqual(t,a.ZLim,b.ZLim); verifyEqual(t,a.View,b.View);
verifyEqual(t,a.ZLabel.String,'UMAP 3');
verifyNumElements(t,findall(f,'Type','colorbar'),2);
for tag={'learningPoints','taskPoints','actionPoints'}
    h=findobj(f,'Tag',tag{1}); allRows=[];
    for k=1:numel(h)
        rows=h(k).UserData; allRows=[allRows;rows]; %#ok<AGROW>
        verifyEqual(t,h(k).XData(:),r.embedding(rows,1));
        verifyEqual(t,h(k).YData(:),r.embedding(rows,2));
        verifyEqual(t,h(k).ZData(:),r.embedding(rows,3));
        if strcmp(tag{1},'learningPoints')
            phase=r.conditions.learning(r.pointInfo.conditionIndex(rows(1)));
            base=multitaskColors(phase); times=r.pointInfo.time(rows);
            verifyEqual(t,h(k).CData(find(times==-1,1),:),.65*base,'AbsTol',1e-12);
            verifyEqual(t,h(k).CData(find(times==2,1),:),.45*base+.55,'AbsTol',1e-12);
        else
            c=r.pointInfo.conditionIndex(rows(1));
            if strcmp(tag{1},'taskPoints')
                s=multitaskColors(r.conditions.task(c),'style'); s.Marker='o';
            else
                s=multitaskColors(r.conditions.action(c),'style');
            end
            verifyEqual(t,h(k).CData,s.Color);
            verifyEqual(t,h(k).MarkerFaceColor,s.MarkerFaceColor);
            expected=s.Marker;
            verifyEqual(t,h(k).Marker,expected);
        end
    end
    expected=(1:height(r.pointInfo))';
    if ~strcmp(tag{1},'learningPoints')
        expected=expected(r.pointInfo.time>=-1&r.pointInfo.time<=1);
    end
    verifyEqual(t,sort(allRows),expected);
end
end
function testTwoDimensionalPlotAndCustomWindow(t)
[r,p]=fixture(); r.embedding=r.embedding(:,1:2); p.taskActionTimeWindow=[0 0];
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); p.savePath=folder.Folder;
[~,files]=fn_plotNeuralEmbedding(r,p);
f=openfig([files.umap(1:end-4) '.fig'],'new','invisible'); cleanup=onCleanup(@()close(f)); %#ok<NASGU>
for tag={'taskPoints','actionPoints'}
    h=findobj(f,'Tag',tag{1}); rows=[];
    for k=1:numel(h)
        verifyEmpty(t,h(k).ZData); rows=[rows;h(k).UserData]; %#ok<AGROW>
    end
    verifyEqual(t,sort(rows),find(r.pointInfo.time==0));
end
verifyEqual(t,multitaskColors('L'),[0 0 0]);
verifyEqual(t,multitaskColors('R'),[195 63 67]/255);
end
function testEmptyDisplayWindow(t)
[r,p]=fixture(); p.taskActionTimeWindow=[10 20];
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); p.savePath=folder.Folder;
[~,files]=fn_plotNeuralEmbedding(r,p);
f=openfig([files.umap(1:end-4) '.fig'],'new','invisible'); cleanup=onCleanup(@()close(f)); %#ok<NASGU>
verifyEmpty(t,findobj(f,'Tag','taskPoints')); verifyEmpty(t,findobj(f,'Tag','actionPoints'));
verifyNumElements(t,findobj(f,'Tag','learningPoints'),2);
end
function testSinglePhaseAndConstantTime(t)
[r,p]=fixture(); r.conditions.learning(:)="Int"; r.pointInfo.time(:)=0;
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); p.savePath=folder.Folder;
[~,files]=fn_plotNeuralEmbedding(r,p);
f=openfig([files.umap(1:end-4) '.fig'],'new','invisible'); cleanup=onCleanup(@()close(f)); %#ok<NASGU>
verifyNumElements(t,findall(f,'Type','colorbar'),1);
verifyTrue(t,all(isfinite(findobj(f,'Tag','learningPoints').CData),'all'));
end
function testMissingOrInvalidLearning(t)
[r,p]=fixture(); r.conditions.learning(:)="unknown";
verifyError(t,@()fn_plotNeuralEmbedding(r,p),'neuralEmbedding:Learning');
r.conditions.learning=[];
verifyError(t,@()fn_plotNeuralEmbedding(r,p),'neuralEmbedding:CombinedLabels');
p.layout='labels'; p.colorBy=["task","action"];
[figs,~]=fn_plotNeuralEmbedding(r,p); verifyEmpty(t,figs.umap);
end
function [r,p]=fixture()
[~,p]=fn_neuralEmbeddingConfig(); p.visible=false; p.connectTime=true;
r.conditions=table(["a";"b";"c";"d"],["T1";"T1";"T2";"T2"], ...
    ["L";"R";"L";"R"],["E";"E";"Int";"Int"], ...
    'VariableNames',{'conditionName','task','action','learning'});
r.pointInfo=table(repelem((1:4)',4),repmat((1:4)',4,1),repmat((-1:2)',4,1), ...
    'VariableNames',{'conditionIndex','timeIndex','time'});
r.embedding=[(1:16)' sin((1:16)') cos((1:16)')];
r.pointLabels=r.conditions(r.pointInfo.conditionIndex,:);
% Combined plot must read the authoritative condition table, not this cache.
r.pointLabels.learning(:)="unused";
r.variables=["task";"action"];
end
