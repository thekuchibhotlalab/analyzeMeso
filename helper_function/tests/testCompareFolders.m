function tests=testCompareFolders
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testIdenticalNestedTreesAndEmptyFolders(t)
[a,b]=folders(t);
for root={a,b}
    mkdir(fullfile(root{1},'nested','empty'));
    writeBytes(fullfile(root{1},'nested','data.bin'),uint8([0 1 255 4]));
    writeBytes(fullfile(root{1},'zero.bin'),uint8([]));
end
[s,d]=fn_compareFolders(a,b,'CompareContents',true,'Verbose',false);
verifyTrue(t,s.allMatch); verifyTrue(t,s.contentsVerified);
verifyEqual(t,s.nFilesA,2); verifyEqual(t,s.nFoldersA,2); verifyEqual(t,s.totalBytesA,4);
verifyEqual(t,s.nFilesComparedByContent,2); verifyTrue(t,all(d.files.status=="match"));
verifyEmpty(t,d.scanErrors);
end
function testPathSizeAndContentDifferences(t)
[a,b]=folders(t); mkdir(fullfile(a,'emptyOnlyA'));
writeBytes(fullfile(a,'onlyA.bin'),uint8(1)); writeBytes(fullfile(b,'onlyB.bin'),uint8(2));
writeBytes(fullfile(a,'size.bin'),uint8([1 2])); writeBytes(fullfile(b,'size.bin'),uint8(1));
writeBytes(fullfile(a,'sameSize.bin'),uint8([1 2])); writeBytes(fullfile(b,'sameSize.bin'),uint8([1 3]));
[s,d]=fn_compareFolders(a,b,'CompareContents',true,'Verbose',false);
verifyFalse(t,s.allMatch); verifyEqual(t,s.nSizeMismatches,1); verifyEqual(t,s.nContentMismatches,1);
verifyEqual(t,s.nFilesOnlyInA,1); verifyEqual(t,s.nFilesOnlyInB,1); verifyEqual(t,s.nFoldersOnlyInA,1);
verifyEqual(t,d.files.status(d.files.relativePath=="sameSize.bin"),"contentMismatch");
end
function testSizeOnlyIsExplicit(t)
[a,b]=folders(t);
writeBytes(fullfile(a,'data.bin'),uint8([1 2])); writeBytes(fullfile(b,'data.bin'),uint8([3 4]));
printed=evalc('[s,d]=fn_compareFolders(a,b);');
verifyTrue(t,s.allMatch); verifyFalse(t,s.contentsVerified); verifyEqual(t,s.nFilesComparedByContent,0);
verifyEqual(t,d.files.status,"sizeMatch"); verifyTrue(t,contains(printed,'File contents were NOT compared'));
end
function testLargeFileDifferenceAfterFirstReadChunk(t)
[a,b]=folders(t); x=zeros(8*1024*1024+3,1,'uint8');
writeBytes(fullfile(a,'large.bin'),x); x(end)=1; writeBytes(fullfile(b,'large.bin'),x);
s=fn_compareFolders(a,b,'CompareContents',true,'Verbose',false);
verifyEqual(t,s.nContentMismatches,1); verifyFalse(t,s.allMatch);
end
function [a,b]=folders(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
a=fullfile(f.Folder,'a'); b=fullfile(f.Folder,'b'); mkdir(a); mkdir(b);
end
function writeBytes(path,x)
fid=fopen(path,'wb'); cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fwrite(fid,x,'uint8');
end
