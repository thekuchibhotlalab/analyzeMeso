%% List of AC animals
animals = {'zz151_AC1','zz151_AC2','zz153_AC','zz159_AC',...
           'zz170_AC1','zz170_AC2','zz177_AC','zz180_AC'};


%% List of PPC animals
animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
%% Save animal Data
for i = 1:length(animals)
    try
        ani = Animal(animals{i});
        save(['B:\animal' filesep animals{i} '_animal.mat'],'ani');
    catch
        disp([animals{i} ' not saved'])
    end 
end 