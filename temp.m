folder1 = 'G:\rockfish\ziyi\zz177_PPC\imagingSession';
folder2 = 'G:\rockfish\ziyi\zz177_AC\imagingSession';

d1 = dir(folder1);
d2 = dir(folder2);

sub1 = {d1([d1.isdir]).name};
sub2 = {d2([d2.isdir]).name};

sub1 = setdiff(sub1,{'.','..'});
sub2 = setdiff(sub2,{'.','..'});

onlyInFolder1 = setdiff(sub1,sub2);
onlyInFolder2 = setdiff(sub2,sub1);
inBoth = intersect(sub1,sub2);

fprintf('Subfolders only in folder1:\n');
disp(onlyInFolder1(:));

fprintf('Subfolders only in folder2:\n');
disp(onlyInFolder2(:));
