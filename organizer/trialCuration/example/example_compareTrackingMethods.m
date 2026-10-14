%% Compare greedy and lookahead using an existing Animal's metadata.
% First create ani, e.g. ani=Animal('zz153_AC'). No neural data is loaded here.
assert(exist('ani','var')==1 && isa(ani,'Animal'),'Create ani before running this example.');
cfg=fn_defaultTrialSelectionConfig(); % Or an expert/early-learning preset.
cfg.minSessionsPerStage=3;
cfg.matchRemaining=false; % Both methods release matching after the minimums.
cfg.makePlots=false;
cfg.loadNeural=false;
cfg.numSessions=Inf;
cfg.trackingMethod='greedy';
greedyCurated=ani.fn_prepareTrialData(cfg);
cfg.trackingMethod='lookahead';
cfg.lookaheadWeight=0.75;
cfg.lookaheadSessions=5;
lookaheadCurated=ani.fn_prepareTrialData(cfg);

figure('Color','w','Name','Greedy vs lookahead');
tiledlayout(1,2,'TileSpacing','compact');
g=greedyCurated.tracking.curve; h=lookaheadCurated.tracking.curve;
nexttile;
plot(g.nSessions,g.nTrackedNeurons,'-o',h.nSessions,h.nTrackedNeurons,'-o');
xlabel('Sessions selected'); ylabel('Common tracked neurons'); grid on;
legend('Greedy','Lookahead','Location','best');
nexttile;
plot(g.nTrials,g.nTrackedNeurons,'-o',h.nTrials,h.nTrackedNeurons,'-o');
xlabel('Selected trials'); ylabel('Common tracked neurons'); grid on;
legend('Greedy','Lookahead','Location','best');

% Inspect how each session scored when it was selected.
disp(lookaheadCurated.tracking.sessions(:,{'rank','sessionRec','phase', ...
    'nTrackedAfterSelection','lookaheadMeanShared','selectionScore','lookaheadSessionRec'}));
% Choose a session prefix afterward with fn_chooseTrackedSessions, as usual.
