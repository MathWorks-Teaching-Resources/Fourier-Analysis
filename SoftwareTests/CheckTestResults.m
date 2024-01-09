classdef CheckTestResults < matlab.unittest.TestCase

    properties (SetAccess = protected)
    end

    properties (ClassSetupParameter)
        Project = {''};
    end

    properties (TestParameter)
        Version
    end


    methods (TestParameterDefinition,Static)

        function Version = GetResults(Project)
            RootFolder = currentProject().RootFolder;
            Version = dir(fullfile(RootFolder,"SoftwareTests","TestResults*.txt"));
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
            File = fullfile("SoftwareTests","TestResults_"+Version+".txt");
            Results = readtable(File,TextType="string");
            testCase.verifyTrue(all(Results.Passed));
        end

    end

end