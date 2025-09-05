%% chunk days and select time 
selTime = 21:80; % save about 
[ani] = ani.chunkDaysByTrialType({'dffStim','wheelStim','behSel'},'selTime',selTime);
%%
ani.buildGLM;

%%
