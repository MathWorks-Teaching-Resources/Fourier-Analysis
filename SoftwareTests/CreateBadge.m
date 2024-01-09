% Create the test suite with SmokeTest and Function test if they exist
Suite = testsuite("CheckTestResults");

% Create a runner with no plugins
Runner = matlab.unittest.TestRunner.withNoPlugins;

% Run the test suite
Results = Runner.run(Suite);

% Format the results in a table and save them
Results = table(Results');
Results = Results(Results.Passed,:);
Version = extractBetween(string(Results.Name),"Version=",")");


% Format the JSON file
Badge = struct;
Badge.schemaVersion = 1;
Badge.label = "Tested with";
if size(Results,1) >= 1
    Badge.color = "success"
    Badge.message = join(Version," | ");
else
    Badge.color = "failure";
    Badge.message = "Pipeline fails";
end
Badge = jsonencode(Badge);
writelines(Badge,fullfile("Images","TestedWith.json"));