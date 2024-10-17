classdef CheckTestResults < matlab.unittest.TestCase

    properties (SetAccess = protected)
    end

    properties (ClassSetupParameter)
        Project = {currentProject()};
    end

    properties (TestParameter)
        Version
    end


    methods (TestParameterDefinition,Static)

        function Version = GetResults(Project)
            RootFolder = Project.RootFolder;
            Version = dir(fullfile(RootFolder,"public","TestResults*.txt"));
            Version = extractBetween([Version.name],"TestResults_",".txt");
        end

    end

    methods (TestClassSetup)

        function SetUpSmokeTest(testCase,Project)
            try
               currentProject;   
            catch
                error("Project is not loaded.")
            end
        end

    end

    methods(Test)

        function CheckResults(testCase,Version)
            File = fullfile("public","TestResults_"+Version+".txt");
            Results = readtable(File,TextType="string");
            if ~all(Results.Passed)
                error("Some of the tests did not pass.")
            end
        end

    end

end