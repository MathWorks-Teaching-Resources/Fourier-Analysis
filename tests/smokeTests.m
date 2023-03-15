% Run these tests with runMyTests
% All tests so far are on code expected to run without errors
% If/when we end up with a version that _should_ error, 
% please add it to this set of examples
classdef smokeTests < matlab.unittest.TestCase

    properties
        fc
        origProj
    end

    methods (TestClassSetup)
        function setUpPath(testCase)
            testCase.origProj = matlab.project.rootProject;

            testCase.fc = fullfile(pwd);
            rootDirName = extractBefore(testCase.fc,"tests");
            openProject(rootDirName);
        end % function setUpPathgit a
    end % methods (TestClassSetup)

    methods(Test)
        
        % This test attempt to open the mlx files
        function testMLX(testCase)
            files = dir(testCase.origProj.RootFolder+filesep+"**"+filesep+"*.mlx");
            for i = 1:size(files)
                f = string(files(i).folder)+filesep+string(files(i).name);
                f = matlab.desktop.editor.openDocument(f);
                f.closeNoPrompt;
            end
        end
        
        % This function test load all the MAT files
        function testMAT(testCase)
            files = dir(testCase.origProj.RootFolder+filesep+"**"+filesep+"*.mat");
            for i = 1:size(files)
                d = string(files(i).folder)+filesep+string(files(i).name);
                d = open(d);
                clear d
            end
        end

        % This function test load all the slx files
        function testSLX(testCase)
           % Place holde
        end

        function runLab1_FourierSeries(testCase)
            testCase.log("Running Lab1_FourierSeries.mlx")
            Lab1_FourierSeries
        end

        function runLab2_ComplexFourierSeries(testCase)
            testCase.log("Running Lab2_ComplexFourierSeries.mlx")
            Lab2_ComplexFourierSeries
        end

        function runLab3_FourierTransform(testCase)
            testCase.log("Running Lab3_FourierTransform.mlx")
            Lab3_FourierTransform
        end

        function runLab4_DFT(testCase)
            testCase.log("Running Lab4_DFT.mlx")
            Lab4_DFT
        end

    end

    methods (TestClassTeardown)
        function resetPath(testCase)

            if isempty(testCase.origProj)
                close(currentProject)
            else
                openProject(testCase.origProj.RootFolder)
            end

            cd(testCase.fc)
        end

    end % methods (TestClassTeardown)

end