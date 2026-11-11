function tests=testPlotTCAComponents
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath'))); repo=fileparts(fileparts(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'helper_function')));
end
function testDifferentModelsAndPreferenceAlignment(t)
[ppc,ac,o]=fixture(); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
o.savePath=folder.Folder;
[r,f]=fn_plotTCAComponents(ppc,ac,o);
verifyEmpty(t,f.matched); verifyEqual(t,r.regions{1}.modelIndex,2); verifyEqual(t,r.regions{2}.modelIndex,1);
verifyEqual(t,r.regions{1}.selected,[2 1]); verifyEqual(t,r.regions{2}.selected,[1 3]);
R=r.regions{1}; G=r.groups.PPC{1};
verifyEqual(t,G.meanFactors{1},mean(R.factors{2}(:,[1 2]),2),'AbsTol',1e-12);
verifyEqual(t,G.individualFactors{3},sort(R.factors{4}(:,[1 2]),1,'descend'));
verifyEqual(t,G.preferredAction,[1 2]);
verifyEqual(t,G.meanFactors{3},[.85;.15],'AbsTol',1e-12);
verifyTrue(t,isnan(G.preferredTask(1))); % Equal task weights have no preferred task.
for g=1:2
    R=r.regions{g};
    for mode=1:5, verifyEqual(t,sum(R.factors{mode},1),ones(1,numel(R.lambda)),'AbsTol',1e-12); end
end
for key=fieldnames(r.plotFiles)'
    verifyTrue(t,isfile(r.plotFiles.(key{1}).png)); verifyTrue(t,isfile(r.plotFiles.(key{1}).fig));
end
h=openfig(r.plotFiles.matched.fig,'new','invisible'); cleanup=onCleanup(@()close(h)); %#ok<NASGU>
verifyEqual(t,numel(findobj(h,'Type','axes')),14); % Two weights, two temporal segments, three other factors per row.
ax=findobj(h,'Tag','temporal_stim');
verifyEqual(t,ax(1).UserData.sourceFrames,1:12);
verifyEqual(t,char(ax(1).XAxis.Visible),'on');
verifyEqual(t,char(ax(1).YAxis.Visible),'off');
ax=findobj(h,'Tag','temporal_choice');
verifyEqual(t,ax(1).UserData.sourceFrames,13:30);
verifyEqual(t,ax(1).UserData.eventFrame,16);
verifyEqual(t,ax(1).UserData.timeSeconds,(-3:14)/15,'AbsTol',1e-12);
drawnow;
stim=findobj(h,'Tag','temporal_stim'); choice=findobj(h,'Tag','temporal_choice');
ps=getpixelposition(stim(1)); pc=getpixelposition(choice(1));
verifyEqual(t,ps(3)/diff(stim(1).XLim),pc(3)/diff(choice(1).XLim),'RelTol',.01);
end
function testScalingInvarianceAndValidation(t)
[p,~,o]=fixture(); o.ppcComponents=[]; o.ppcGroups={};
r=fn_plotTCAComponents(p,[],o);
p.M{2}.U{2}=p.M{2}.U{2}*7; p.M{2}.U{3}=p.M{2}.U{3}/7;
q=fn_plotTCAComponents(p,[],o);
verifyEqual(t,q.regions{1}.lambda,r.regions{1}.lambda,'AbsTol',1e-10);
for mode=1:5, verifyEqual(t,q.regions{1}.factors{mode},r.regions{1}.factors{mode},'AbsTol',1e-12); end
p.M{2}.U{4}=ones(4,2);
verifyError(t,@()fn_plotTCAComponents(p,[],o),'TCAPlot:Modes');
end
function [ppc,ac,o]=fixture()
stream=RandStream('mt19937ar','Seed',42);
m=struct('lambda',[2;1],'U',{{rand(stream,5,2),rand(stream,30,2),rand(stream,4,2),[8 1;2 9],[1 3;1 1]}});
a=struct('lambda',[1;2;3],'U',{{rand(stream,4,3),rand(stream,30,3),rand(stream,4,3),rand(stream,2,3),rand(stream,2,3)}});
ppc=struct('M',{{m,m}}); ac=struct('M',{{a,m}});
o=struct('visible',false,'showDiagnostics',false,'ppcModel',2,'acModel',1, ...
    'ppcComponents',[2 1],'acComponents',[1 3],'ppcGroups',{{[1 2]}},'acGroups',{{[1 2 3]}});
end
