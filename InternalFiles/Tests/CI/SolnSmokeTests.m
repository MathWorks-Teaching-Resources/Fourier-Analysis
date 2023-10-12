classdef SolnSmokeTests < matlab.unittest.TestCase

    properties
        rootProject
    end

    methods (TestClassSetup)

        function setUpPath(testCase)

            try
                project = currentProject;
                testCase.rootProject = project.RootFolder;
                cd(testCase.rootProject)
                addpath(fullfile(testCase.rootProject,"InternalFiles","Solutions"))
            catch ME
                warning("Load project prior to run tests")
                rethrow(ME)
            end

            testCase.log("Running in " + version)

        end % function setUpPath

    end % methods (TestClassSetup)

    methods(Test)

        % Test that all the Script files have solution versions
        function ExistSolns(testCase)
            files = dir(fullfile(testCase.rootProject,"Scripts","*.mlx"));
            for iTestSoln = 1:size(files)
                SolnFileName = extractBefore(files(iTestSoln).name,".mlx") + "Soln.mlx";
                SolnFilePath = fullfile(testCase.rootProject,...
                    "InternalFiles"+filesep+"Solutions",SolnFileName);
                assert(exist(SolnFilePath,"file"), "SolnTest:FileNotFound", SolnFileName + " doesn't exist");
            end
        end  

        function RunMLXSolns(testCase)
            files = dir(fullfile(testCase.rootProject,"InternalFiles","Solutions","*.mlx"));
            for iTestSoln = 1:size(files)
                disp("Running " + files(iTestSoln).name + "...")
                run(files(iTestSoln).name)
                disp("Finished "+ files(iTestSoln).name)
            end
        end

        function RunSLXSolns(testCase)
            files = dir(fullfile(testCase.rootProject,"InternalFiles","Solutions","*.slx"));
            for iTestSoln = 1:size(files)
                disp("Running " + files(iTestSoln).name + "...")
                run(files(iTestSoln).name)
                disp("Finished "+ files(iTestSoln).name)
            end
        end

    end

    methods (TestClassTeardown)

        function closeAllFigure(testCase)
            close all % Close all figure
            bdclose all % Close all simulink
        end

        function RemovePath(testCase)
            rmpath(fullfile(testCase.rootProject,"InternalFiles","Solutions"))
        end

    end % methods (TestClassTeardown)

end
