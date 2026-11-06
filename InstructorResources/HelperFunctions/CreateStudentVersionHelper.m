function outputFolder = CreateStudentVersionHelper(mode,options)
% CreateStudentVersionHelper Create a learner-only project distribution.

arguments
    mode (1,1) string {mustBeMember(mode,["export" "branch"])} = "export"
    options.Destination (1,1) string = ""
    options.BranchName (1,1) string = "student"
    options.UseWorktree (1,1) {mustBeA(options.UseWorktree,"logical")} = true
end

project = currentProject();
sourceFolder = string(project.RootFolder);
localBranch = mode == "branch" && ~options.UseWorktree;
if localBranch && options.Destination ~= ""
    error("CreateStudentVersionHelper:LocalBranchDestination", ...
        "A local branch uses the source folder. Use a worktree to choose another folder.")
end
if strlength(options.Destination) == 0
    destination = sourceFolder + "-Student";
else
    destination = options.Destination;
end
if localBranch
    destination = sourceFolder;
end
if ~localBranch
    [parent,folderName,extension] = fileparts(destination);
    folderName = folderName + extension;
    if folderName == "" || folderName == "." || folderName == ".."
        error("CreateStudentVersionHelper:InvalidDestination","Enter a new destination folder name.")
    end
    if parent == ""
        parent = string(pwd);
    end
    previousFolder = pwd;
    folderCleanup = onCleanup(@() cd(previousFolder));
    cd(parent)
    destination = string(fullfile(pwd,folderName));
    clear folderCleanup
end
studentAppBuilder = @CreateStudentApp;
originalBranch = "";
backupFolder = "";

switch mode
    case "export"
        copyfile(sourceFolder,destination)
        gitFolder = fullfile(destination,".git");
        if isfolder(gitFolder)
            rmdir(gitFolder,"s")
        elseif isfile(gitFolder)
            delete(gitFolder)
        end
    case "branch"
        validateGitBranch(sourceFolder,options.BranchName)
        if localBranch
            originalBranch = strtrim(runGit(sourceFolder,"symbolic-ref --quiet --short HEAD"));
            if isempty(regexp(originalBranch,'^[A-Za-z0-9][A-Za-z0-9._/-]*$','once'))
                error("CreateStudentVersionHelper:InvalidBranch", ...
                    "The current branch name contains unsupported characters.")
            end
            backupFolder = string(tempname);
            mkdir(backupFolder)
            backupCleanup = onCleanup(@() rmdir(backupFolder,"s"));
            copyProjectContents(sourceFolder,backupFolder)
            try
                close(project)
                runGit(sourceFolder,'switch -c "' + options.BranchName + '"');
            catch switchError
                openProject(sourceFolder);
                rethrow(switchError)
            end
        else
            if contains(destination,["""",newline,char(13),"%","!"])
                error("CreateStudentVersionHelper:InvalidGitPath", ...
                    "Unsupported characters in the worktree folder path.")
            end
            if isfolder(destination) || isfile(destination) || ...
                    strcmpi(destination,sourceFolder) || ...
                    startsWith(lower(destination),lower(sourceFolder + filesep))
                error("CreateStudentVersionHelper:InvalidDestination", ...
                    "Choose a new worktree folder outside the source project.")
            end
            runGit(sourceFolder,'worktree add -b "' + options.BranchName + ...
                '" "' + destination + '" HEAD');
        end
end

try
    configureStudentCopy(destination,studentAppBuilder)
catch ME
    if localBranch
        try
            copyProjectContents(backupFolder,sourceFolder)
            runGit(sourceFolder,'switch "' + originalBranch + '"');
            runGit(sourceFolder,'branch -d "' + options.BranchName + '"');
            openProject(sourceFolder);
        catch recoveryError
            ME = addCause(ME,recoveryError);
        end
    elseif mode == "branch"
        try
            runGit(sourceFolder,'worktree remove --force "' + destination + '"');
            runGit(sourceFolder,'branch -d "' + options.BranchName + '"');
        catch recoveryError
            ME = addCause(ME,recoveryError);
        end
    elseif isfolder(destination)
        rmdir(destination,"s")
    end
    rethrow(ME)
end

fprintf("Created student-only project at:\n%s\n",destination)
outputFolder = destination;
end

function validateGitBranch(sourceFolder,branchName)
if isempty(regexp(branchName,'^[A-Za-z0-9][A-Za-z0-9._/-]*$','once'))
    error("CreateStudentVersionHelper:InvalidBranch", ...
        "Enter a Git branch name starting with a letter or number.")
end
runGit(sourceFolder,'check-ref-format --branch "' + branchName + '"');
[status,~] = system(sprintf('git -C "%s" rev-parse --is-inside-work-tree',sourceFolder));
if status ~= 0
    error("CreateStudentVersionHelper:NotGitRepository", ...
        "Student branch mode requires a Git repository.")
end

[status,~] = system(sprintf('git -C "%s" show-ref --verify --quiet refs/heads/%s', ...
    sourceFolder,'"' + branchName + '"'));
if status == 0
    error("CreateStudentVersionHelper:BranchExists", ...
        "Local branch already exists: %s",branchName)
end

end

function copyProjectContents(source,destination)
entries = dir(source);
for index = 1:numel(entries)
    entry = entries(index);
    if ismember(string(entry.name),[".","..",".git"])
        continue
    end
    target = fullfile(destination,entry.name);
    if entry.isdir
        if ~isfolder(target)
            mkdir(target)
        end
        copyProjectContents(fullfile(source,entry.name),target)
    else
        copyfile(fullfile(source,entry.name),target)
    end
end
end

function result = runGit(sourceFolder,command)
if contains(sourceFolder,["""",newline,char(13),"%","!"])
    error("CreateStudentVersionHelper:InvalidGitPath","Unsupported characters in the Git folder path.")
end
[status,result] = system(sprintf('git -C "%s" %s',sourceFolder,command));
if status ~= 0
    error("CreateStudentVersionHelper:GitFailed","%s",strtrim(result))
end
result = string(result);
end

function configureStudentCopy(destination,studentAppBuilder)
studentAppBuilder(destination)

removePaths = [
    "InstructorResources"
    "InternalFiles"
    "SoftwareTests"
    ".github"
    "public"
    ];
removeFiles = [
    "buildfile.m"
    ".gitlab-ci.yml"
    "CONTRIBUTING.md"
    "InstructorToolkit-plan.md"
    fullfile("Utilities","ProjectStartupApp-plan.md")
    ];
removeStudentProjectEntries(destination,removePaths,removeFiles)

for path = removePaths'
    target = fullfile(destination,path);
    if isfolder(target)
        rmdir(target,"s")
    end
end

for file = removeFiles'
    target = fullfile(destination,file);
    if isfile(target)
        delete(target)
    end
end
end

function removeStudentProjectEntries(destination,folderEntries,fileEntries)
projectFile = fullfile(destination,"resources","project","Project.xml");
if ~isfile(projectFile)
    return
end

folderEntries = replace(folderEntries,filesep,"/");
fileEntries = replace(fileEntries,filesep,"/");
parser = matlab.io.xml.dom.Parser;
projectDocument = parseFile(parser,projectFile);
filesNode = projectDocument.getElementsByTagName("Files").item(0);
removeProjectFileNodes(filesNode,"",[folderEntries; fileEntries])
removeProjectPathEntries(projectDocument,folderEntries)
writer = matlab.io.xml.dom.DOMWriter;
writer.Configuration.FormatPrettyPrint = true;
writeToFile(writer,projectDocument,projectFile)
end

function removeProjectFileNodes(parentNode,parentPath,entries)
childNode = parentNode.getFirstChild;
while ~isempty(childNode)
    nextNode = childNode.getNextSibling;
    if string(childNode.getNodeName) == "File"
        location = string(childNode.getAttribute("Location"));
        if strlength(parentPath) == 0
            entryPath = location;
        else
            entryPath = parentPath + "/" + location;
        end
        if any(entryPath == entries)
            parentNode.removeChild(childNode);
        else
            removeProjectFileNodes(childNode,entryPath,entries)
        end
    else
        removeProjectFileNodes(childNode,parentPath,entries)
    end
    childNode = nextNode;
end
end

function removeProjectPathEntries(projectDocument,folderEntries)
infoNodes = projectDocument.getElementsByTagName("Info");
for index = infoNodes.getLength-1:-1:0
    infoNode = infoNodes.item(index);
    if string(infoNode.getAttribute("Ref")) == folderEntries
        referenceNode = infoNode.getParentNode;
        if string(referenceNode.getNodeName) == "Reference"
            referenceNode.getParentNode.removeChild(referenceNode);
        end
    end
end
end
