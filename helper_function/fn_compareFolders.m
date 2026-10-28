function [summary,details]=fn_compareFolders(folderA,folderB,varargin)
%FN_COMPAREFOLDERS Compare all files/subfolders, including empty directories.
% [summary,details]=fn_compareFolders(folderA,folderB)
% ...,'CompareContents',true reads matching-size files in 8 MB chunks.
% Default compares exact relative paths and file sizes, NOT file contents.
% Other options: 'Verbose',true; 'MaxDetails',20 (Inf prints every difference).
% Read-only: never copies, deletes, or changes either folder.
p=inputParser;
addParameter(p,'CompareContents',false,@(x)islogical(x)&&isscalar(x));
addParameter(p,'Verbose',true,@(x)islogical(x)&&isscalar(x));
addParameter(p,'MaxDetails',20,@(x)isnumeric(x)&&isscalar(x)&&x>=0&&(isinf(x)||fix(x)==x));
parse(p,varargin{:}); opt=p.Results;
folderA=resolveFolder(folderA); folderB=resolveFolder(folderB);
[A,dirsA,errorsA]=inventory(folderA); [B,dirsB,errorsB]=inventory(folderB);
paths=union(A.relativePath,B.relativePath); n=numel(paths);
[inA,ia]=ismember(paths,A.relativePath); [inB,ib]=ismember(paths,B.relativePath);
bytesA=nan(n,1); bytesB=bytesA;
bytesA(inA)=A.bytes(ia(inA)); bytesB(inB)=B.bytes(ib(inB));
status=strings(n,1); message=strings(n,1); compared=0;
status(inA&~inB)="onlyInA"; status(inB&~inA)="onlyInB";
for k=find(inA&inB)'
    if bytesA(k)~=bytesB(k)
        status(k)="sizeMismatch";
    elseif opt.CompareContents
        [status(k),message(k)]=compareBytes(fullfile(folderA,paths(k)), ...
            fullfile(folderB,paths(k)),bytesA(k));
        if status(k)~="readError", compared=compared+1; end
    else
        status(k)="sizeMatch";
    end
end
details.files=table(paths,status,bytesA,bytesB,message, ...
    'VariableNames',{'relativePath','status','bytesA','bytesB','message'});
folderPaths=union(dirsA,dirsB);
hasA=ismember(folderPaths,dirsA); hasB=ismember(folderPaths,dirsB);
folderStatus=repmat("match",numel(folderPaths),1);
folderStatus(hasA&~hasB)="onlyInA"; folderStatus(hasB&~hasA)="onlyInB";
details.folders=table(folderPaths,folderStatus,'VariableNames',{'relativePath','status'});
details.scanErrors=[errorsA;errorsB];
summary=struct('folderA',string(folderA),'folderB',string(folderB), ...
    'comparison',"relative paths and file sizes",'compareContents',opt.CompareContents, ...
    'nFilesA',height(A),'nFilesB',height(B),'nFoldersA',numel(dirsA),'nFoldersB',numel(dirsB), ...
    'totalBytesA',sum(A.bytes),'totalBytesB',sum(B.bytes), ...
    'nCommonFiles',sum(inA&inB),'nMatchingFiles',sum(ismember(status,["match","sizeMatch"])), ...
    'nFilesOnlyInA',sum(status=="onlyInA"),'nFilesOnlyInB',sum(status=="onlyInB"), ...
    'nSizeMismatches',sum(status=="sizeMismatch"),'nContentMismatches',sum(status=="contentMismatch"), ...
    'nFilesComparedByContent',compared,'nReadErrors',sum(status=="readError"), ...
    'nMatchingFolders',sum(folderStatus=="match"), ...
    'nFoldersOnlyInA',sum(folderStatus=="onlyInA"),'nFoldersOnlyInB',sum(folderStatus=="onlyInB"), ...
    'nScanErrors',height(details.scanErrors));
if opt.CompareContents, summary.comparison="relative paths, file sizes, and byte-for-byte contents"; end
summary.allMatch=all(ismember(status,["match","sizeMatch"]))&& ...
    all(folderStatus=="match")&&summary.nScanErrors==0;
summary.contentsVerified=opt.CompareContents&&summary.allMatch;
if opt.Verbose
    fprintf('\nFolder A: %s\nFolder B: %s\nComparison: %s\n',folderA,folderB,summary.comparison);
    fprintf('A: %d files, %d subfolders, %.0f bytes\n',summary.nFilesA,summary.nFoldersA,summary.totalBytesA);
    fprintf('B: %d files, %d subfolders, %.0f bytes\n',summary.nFilesB,summary.nFoldersB,summary.totalBytesB);
    fprintf('Matching: %d files, %d subfolders\n',summary.nMatchingFiles,summary.nMatchingFolders);
    fprintf('Files only in A/B: %d / %d; folders only in A/B: %d / %d\n', ...
        summary.nFilesOnlyInA,summary.nFilesOnlyInB,summary.nFoldersOnlyInA,summary.nFoldersOnlyInB);
    fprintf('Size mismatches: %d; content mismatches: %d; read/scan errors: %d / %d\n', ...
        summary.nSizeMismatches,summary.nContentMismatches,summary.nReadErrors,summary.nScanErrors);
    if summary.allMatch, fprintf('ALL MATCH under the selected comparison.\n');
    else, fprintf('NOT ALL MATCH (differences or unreadable entries found).\n'); end
    if ~opt.CompareContents, fprintf('File contents were NOT compared. Use ''CompareContents'',true to verify them.\n'); end
    showRows(details.files(~ismember(status,["match","sizeMatch"]),:),'File differences',opt.MaxDetails);
    showRows(details.folders(folderStatus~="match",:),'Folder differences',opt.MaxDetails);
    showRows(details.scanErrors,'Scan errors',opt.MaxDetails);
end
end

function root=resolveFolder(root)
assert((ischar(root)&&isrow(root))||(isstring(root)&&isscalar(root)&&~ismissing(root)), ...
    'compareFolders:Path','Provide one folder path.');
assert(isfolder(root),'compareFolders:Path','Folder not found: %s',string(root));
[ok,attr]=fileattrib(char(root));
assert(ok,'compareFolders:Path','Cannot access folder: %s',string(root));
root=attr.Name;
end

function [files,folders,errors]=inventory(root)
paths=strings(0,1); bytes=zeros(0,1); folders=strings(0,1);
errors=table(strings(0,1),strings(0,1),'VariableNames',{'path','message'});
pending={''}; visited=containers.Map('KeyType','char','ValueType','logical');
[oldWarning,oldID]=lastwarn; restore=onCleanup(@()lastwarn(oldWarning,oldID)); %#ok<NASGU>
while ~isempty(pending)
    relative=pending{end}; pending(end)=[]; full=fullfile(root,relative);
    try
        % Resolve junctions/symlinks to prevent cycles. Repeated targets are
        % reported as incomplete scans rather than silently claimed to match.
        canonical=char(java.io.File(full).getCanonicalPath());
        if ispc, canonical=lower(canonical); end
        assert(~isKey(visited,canonical),'compareFolders:RepeatedDirectory', ...
            'Repeated directory target (junction/symlink); skipped to avoid repeated traversal.');
        visited(canonical)=true;
        lastwarn(''); listing=dir(full); [warn,~]=lastwarn;
        if ~isempty(warn), error('compareFolders:ScanWarning','%s',warn); end
        listing=listing(~ismember({listing.name},{'.','..'}));
        for k=1:numel(listing)
            rel=fullfile(relative,listing(k).name);
            if listing(k).isdir
                folders(end+1,1)=string(rel); pending{end+1}=rel; %#ok<AGROW>
            else
                paths(end+1,1)=string(rel); bytes(end+1,1)=listing(k).bytes; %#ok<AGROW>
            end
        end
    catch ex
        errors(end+1,:)={string(full),string(ex.message)}; %#ok<AGROW>
    end
end
files=table(paths,bytes,'VariableNames',{'relativePath','bytes'});
folders=sort(folders);
end

function [status,message]=compareBytes(pathA,pathB,expectedBytes)
status="readError"; message="";
try
    [a,msg]=fopen(pathA,'rb'); assert(a>=0,'compareFolders:Read','%s: %s',pathA,msg);
    closeA=onCleanup(@()fclose(a)); %#ok<NASGU>
    [b,msg]=fopen(pathB,'rb'); assert(b>=0,'compareFolders:Read','%s: %s',pathB,msg);
    closeB=onCleanup(@()fclose(b)); %#ok<NASGU>
    total=0;
    while true
        x=fread(a,8*1024*1024,'*uint8'); y=fread(b,8*1024*1024,'*uint8');
        [msgA,errA]=ferror(a); [msgB,errB]=ferror(b);
        % MATLAB reports normal end-of-file through ferror after a short read.
        % Accept EOF here; the final byte count still detects premature EOF.
        assert((errA==0||feof(a))&&(errB==0||feof(b)), ...
            'compareFolders:Read','Read failed: %s %s',msgA,msgB);
        if ~isequal(x,y), status="contentMismatch"; return; end
        total=total+numel(x);
        if isempty(x), break; end
    end
    assert(total==expectedBytes,'compareFolders:Changed','File size changed during comparison; rerun the check.');
    status="match";
catch ex
    message=string(ex.message);
end
end

function showRows(T,label,limit)
if isempty(T)||limit==0, return; end
n=min(height(T),limit); fprintf('\n%s (showing %d of %d):\n',label,n,height(T)); disp(T(1:n,:));
end
