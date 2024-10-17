import matlab.unittest.plugins.TestReportPlugin;

runner = matlab.unittest.TestRunner.withTextOutput;
runner.addPlugin(TestReportPlugin.producingHTML('Verbosity',3))

% Record current state:
currentOpenFiles = matlab.desktop.editor.getAll;

% Identify path:
myLoc = which("runMyTests");
myRoot = extractBefore(myLoc,"InternalFiles");

% Open the desired project:
proj = openProject(myRoot);
cd(proj.RootFolder)

results = runner.run(testsuite("SoftwareTests"));

addpath(fullfile(proj.RootFolder,"InternalFiles" + filesep + "Solutions"))
addpath(fullfile(proj.RootFolder,"InternalFiles" + filesep + "Tests"))

solnResults = runner.run(testsuite(fullfile(proj.RootFolder,...
    "InternalFiles" + filesep + "Tests"),IncludeSubfolders=true));

T = table(results);
TSoln = table(solnResults);

% Attempt to reset state
myLastList = matlab.desktop.editor.getAll;
if length(myLastList)>length(currentOpenFiles)
    closeNoPrompt(myLastList((length(currentOpenFiles)+1):end))
end

% Display results
disp(T)
disp(TSoln)

% Alternate Option using runtests() rather than testsuite()
% Because this one will not create the HTML output, it logs to a 
% diary file

% loc = pwd;
% pat = lettersPattern + textBoundary("end");
% fileName = extract(loc,pat);
% diaryName = strcat(fileName + "TestOutput");
% diary(diaryName)
% results1 = runtests("smokeTests")
% results2 = runtests("functionTests")
% diary("off")
% T = table([results1,results2])