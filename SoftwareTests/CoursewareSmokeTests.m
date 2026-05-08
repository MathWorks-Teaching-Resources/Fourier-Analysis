classdef CoursewareSmokeTests < matlab.unittest.TestCase
    % CoursewareSmokeTests
    %
    % Purpose:
    %   Runs blind smoke tests for learner scripts in Scripts/ and their
    %   corresponding solution scripts in InstructorResources/Solutions.
    %
    % Design:
    %   1) Discovers .m and .mlx script files in Scripts/ as test parameters.
    %   2) Executes each learner script and matching solution script.
    %   3) Runs optional per-script pre/post hooks in SoftwareTests/PreFiles
    %      and SoftwareTests/PostFiles.
    %   4) Captures figure diagnostics, then force-closes figures and models
    %      so each test starts from a clean state.

    properties
        openEditorSnapshot % Files that were already open before each test
    end

    properties (ClassSetupParameter)
        % Tests rely on a loaded MATLAB project for path and root resolution.
        Project = {currentProject()};
    end

    properties (TestParameter)
        ScriptFile;
    end

    methods (TestParameterDefinition, Static)

        function ScriptFile = listCoursewareScriptFiles(Project)
            import matlab.buildtool.io.FileCollection

            rootFolder = Project.RootFolder;
            filePaths = FileCollection.fromPaths(fullfile(rootFolder, "Scripts", ["*.m" "*.mlx"])).paths;
            [~, fileName, fileExt] = fileparts(filePaths);
            ScriptFile = cellstr(fileName + fileExt);
        end

    end

    methods (TestClassSetup)

        function setUpCoursewareTestEnvironment(testCase, Project)
            testCase.assertClass(Project, "matlab.project.Project", ...
                "Project must be a matlab.project.Project object.");
            cd(Project.RootFolder)

            % StartUp App can block script execution in headless CI sessions.
            delete(findall(groot, 'Name', 'StartUp App'))

            testCase.log("Running in " + version)
        end

    end

    methods (TestMethodSetup)

        function snapshotOpenEditors(testCase)
            openEditors = matlab.desktop.editor.getAll;
            testCase.openEditorSnapshot = {openEditors.Filename};
        end

    end

    methods (Test)

        function runLearnerScriptSmokeTest(testCase, ScriptFile)
            import matlab.unittest.fixtures.CurrentFolderFixture

            fixture = CurrentFolderFixture(testCase.Project{1}.RootFolder);
            testCase.applyFixture(fixture);

            fileToRun = string(ScriptFile);
            testCase.runScriptWithPrePostHooks(fileToRun);
        end

        function verifySolutionScriptExists(testCase, ScriptFile)
            import matlab.unittest.fixtures.PathFixture

            fixture = PathFixture(fullfile(testCase.Project{1}.RootFolder, "InstructorResources"), ...
                "IncludeSubfolders", true);
            testCase.applyFixture(fixture);

            [~, fileName, fileExt] = fileparts(string(ScriptFile));
            solutionName = fileName + "Soln" + fileExt;
            testCase.assertTrue(isfile(which(solutionName)), "Missing solutions for " + ScriptFile);
        end

        function runSolutionScriptSmokeTest(testCase, ScriptFile)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.CurrentFolderFixture

            solutionPathFixture = PathFixture(fullfile(testCase.Project{1}.RootFolder, "InstructorResources"), ...
                "IncludeSubfolders", true);
            testCase.applyFixture(solutionPathFixture);

            rootFolderFixture = CurrentFolderFixture(testCase.Project{1}.RootFolder);
            testCase.applyFixture(rootFolderFixture);

            [~, fileName, fileExt] = fileparts(string(ScriptFile));
            fileToRun = fileName + "Soln" + fileExt;
            testCase.runScriptWithPrePostHooks(fileToRun);
        end

    end

    methods (Access = protected)

        function runScriptWithPrePostHooks(testCase, fileToRun)
            knownIssueIds = "";

            preHookPath = testCase.ensurePreRunHookFile(fileToRun);
            run(preHookPath);

            disp(">> Running " + fileToRun);
            try
                run(fileToRun);
            catch ME
            end

            postHookPath = testCase.ensurePostRunHookFile(fileToRun);
            run(postHookPath)

            figures = findall(groot, 'Type', 'figure');
            figures = flipud(figures);
            if ~isempty(figures)
                for iFigure = 1:size(figures, 1)
                    if ~isempty(figures(iFigure).Number)
                        figDiag = matlab.unittest.diagnostics.FigureDiagnostic(figures(iFigure), 'Formats', 'png');
                        log(testCase, 1, figDiag);
                    end
                end
            end

            % Cleanup avoids cross-test contamination in desktop and CI runs.
            close all force
            if any(matlab.addons.installedAddons().Name == "Simulink")
                bdclose all
            end

            if exist("ME", "var")
                if exist("KnownIssuesID", "var")
                    knownIssueIds = KnownIssuesID;
                end
                if ~any(strcmp(ME.identifier, knownIssueIds))
                    rethrow(ME)
                end
            end
        end

        function path = ensurePreRunHookFile(testCase, filename)
            [~, scriptName, ~] = fileparts(string(filename));
            preFile = "Pre" + scriptName + ".m";
            preFilePath = fullfile(testCase.Project{1}.RootFolder, "SoftwareTests", "PreFiles", preFile);

            preFolder = fullfile(testCase.Project{1}.RootFolder, "SoftwareTests", "PreFiles");
            if ~isfolder(preFolder)
                mkdir(preFolder)
            end

            if ~isfile(preFilePath)
                writelines("% Pre-run script for " + filename, preFilePath)
                writelines("% ---- Known Issues -----", preFilePath, 'WriteMode', 'append');
                writelines("KnownIssuesID = """";", preFilePath, 'WriteMode', 'append');
                writelines("% ---- Pre-run commands -----", preFilePath, 'WriteMode', 'append');
                writelines(" ", preFilePath, 'WriteMode', 'append');
            end
            path = preFilePath;
        end

        function path = ensurePostRunHookFile(testCase, filename)
            [~, scriptName, ~] = fileparts(string(filename));
            postFile = "Post" + scriptName + ".m";
            postFilePath = fullfile(testCase.Project{1}.RootFolder, "SoftwareTests", "PostFiles", postFile);

            postFolder = fullfile(testCase.Project{1}.RootFolder, "SoftwareTests", "PostFiles");
            if ~isfolder(postFolder)
                mkdir(postFolder)
            end

            if ~isfile(postFilePath)
                writelines("% Post-run script for " + filename, postFilePath)
                writelines("% ---- Post-run commands -----", postFilePath, 'WriteMode', 'append');
                writelines(" ", postFilePath, 'WriteMode', 'append');
            end
            path = postFilePath;
        end

    end

end
