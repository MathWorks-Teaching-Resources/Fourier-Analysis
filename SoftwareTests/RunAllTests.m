function RunAllTests(ShowReport)
arguments
    ShowReport (1,1) logical = false;
end

import matlab.unittest.plugins.TestReportPlugin;

% Create a runner
Runner = matlab.unittest.TestRunner.withTextOutput;
Folder = fullfile(currentProject().RootFolder,"public",version("-release"));
if ~isfolder(Folder)
    mkdir(Folder)
else
    rmdir(Folder,'s')
    mkdir(Folder)
end
Plugin = TestReportPlugin.producingHTML(Folder,...
    "IncludingPassingDiagnostics",true,...
    "IncludingCommandWindowText",true,...
    "LoggingLevel",matlab.automation.Verbosity(1));
Runner.addPlugin(Plugin);


% Create the test suite with SmokeTest and Function test if they exist
Suite = testsuite("SmokeTests");
Suite = [Suite testsuite("FunctionTests")];
Suite = [Suite testsuite("SolnSmokeTests")];

% Run the test suite
Results = Runner.run(Suite);

if ShowReport
    web(fullfile(Folder,"index.html"))
end

% Format the results in a table and save them
ResultsTable = table(Results')
writetable(ResultsTable,fullfile(currentProject().RootFolder,...
    "public","TestResults_"+version("-release")+".txt"));

% Assert success of test
assertSuccess(Results);

end
