clear; 

load('D:\labData\2pData_meso\meso_config\zz131_052223_AC_PPC_pt_00001_Tuning\population\tuning.mat');

AC_cell = [1020, 850];
PPC_cell = [715, 515];
figure; errorbar(1:17,tuning.mean(:,AC_cell(1)),tuning.meanSEM(:,AC_cell(1)))
hold on; errorbar(1:17,tuning.mean(:,AC_cell(2)),tuning.meanSEM(:,AC_cell(2))); xlim([1 17])

figure; imagesc(refImg{1}(570:end,:)); colormap gray; clim([0 1000])


figure; errorbar(1:17,tuning.mean(:,PPC_cell(1)),tuning.meanSEM(:,PPC_cell(1)));
hold on; errorbar(1:17,tuning.mean(:,PPC_cell(2)),tuning.meanSEM(:,PPC_cell(2)));  xlim([1 17])