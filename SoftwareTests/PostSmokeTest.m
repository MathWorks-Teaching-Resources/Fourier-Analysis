function PostSmokeTest(ShowReport)
arguments
    ShowReport (1,1) logical = false;
end

import matlab.unittest.plugins.TestRunnerPlugin;

% Create the runner:
Runner = matlab.unittest.TestRunner.withTextOutput;

% Create report folder:
Folder = fullfile(currentProject().RootFolder,"public");
if ~isfolder(Folder)
    mkdir(Folder)
end

% Add HTML plugin:
Plugin = matlab.unittest.plugins.TestReportPlugin.producingHTML(Folder,...
    "IncludingPassingDiagnostics",true,...
    "IncludingCommandWindowText",false,...
    "LoggingLevel",matlab.automation.Verbosity(1));
Runner.addPlugin(Plugin);


% Create Test Suite
Suite = testsuite("CheckTestResults");

% Run the test suite
Results = Runner.run(Suite);


% Format the results in a table and save them
Results = table(Results');
Version = extractBetween(string(Results.Name),"Version=",")");
Passed = Results.Passed;

% Add link to other report
File = fileread(fullfile("public","index.html"));
for iVer = 1:length(Version)
    File = replace(File,"Version="+Version(iVer),...
        sprintf('<a href="%s/index.html">%s</a>',Version(iVer),"Version="+Version(iVer)));
end
writelines(File,fullfile("public","index.html"),"WriteMode","overwrite");

% Format the JSON file
Badge = struct;
Badge.schemaVersion = 1;
Badge.label = "Test Status";
if all(Passed)
    Badge.color = "success";
    Badge.message = join("R"+Version," | ");
elseif any(Passed)
    Badge.color = "yellowgreen";
    Badge.message = join("R")
elseif all(~Passed)
    Badge.color = "critical";
    Badge.message = join("R"+Version," | ");
end
Badge = jsonencode(Badge);
writelines(Badge,fullfile("Images","TestedWith.json"));

if ShowReport
    web(fullfile(Folder,"index.html"))
end

end