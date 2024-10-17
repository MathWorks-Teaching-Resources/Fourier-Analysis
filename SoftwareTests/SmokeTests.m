classdef SmokeTests < matlab.unittest.TestCase

    properties
        RootFolder
        sparedEditors % Files already open when the test starts
    end % properties
    
    properties (ClassSetupParameter)
        Project = {currentProject()};
    end % ClassSetupParameter

    properties (TestParameter)
        File;
    end % TestParameter

    methods (TestParameterDefinition,Static)

        function File = RetrieveFile(Project) %#ok<INUSD>
            % Retrieve student template files:
            RootFolder = currentProject().RootFolder;
            File = dir(fullfile(RootFolder,"Scripts","*.mlx"));
            File = {File.name}; 
        end

    end % Static TestParameterDefinition

    methods (TestClassSetup)

        function SetUpSmokeTest(testCase,Project) %#ok<INUSD>
            % Navigate to project root folder:
            testCase.RootFolder = Project.RootFolder;
            cd(testCase.RootFolder)
            
            % Close the StartUp app if still open:
            delete(findall(groot,'Name','StartUp App'))

            % Log MATLAB version:
            testCase.log("Running in " + version)
        end

    end % TestClassSetup

    methods(TestMethodSetup)
        function recordEditorsToSpare(testCase)
            testCase.sparedEditors = matlab.desktop.editor.getAll;
            testCase.sparedEditors = {testCase.sparedEditors.Filename};
        end
    end % TestMethodSetup
    
    methods(TestMethodTeardown)
        function closeOpenedEditors_thenDeleteWorkingDir(testCase)
            openEditors = matlab.desktop.editor.getAll;
            for editor=openEditors(1:end)
                if any(strcmp(editor.Filename, testCase.sparedEditors))
                    continue;
                end
                % if not on our list, close the file
                editor.close();
            end
        end
    end % TestMethodTeardown

    methods(Test)

        function SmokeRun(testCase,File)

            % Navigate to project root folder:
            cd(testCase.RootFolder)
            FileToRun = string(File);

            % Pre-test:
            PreFiles = CheckPreFile(testCase,FileToRun);
            run(PreFiles);

            % Run SmokeTest
            disp(">> Running " + FileToRun);
            try
                run(fullfile("Scripts",FileToRun));
            catch ME 
                
            end

            % Post-test:
            PostFiles = CheckPostFile(testCase,FileToRun);
            run(PostFiles)

            % Log every figure created during run:
            Figures = findall(groot,'Type','figure');
            Figures = flipud(Figures);
            if ~isempty(Figures)
                for f = 1:size(Figures,1)
                    if ~isempty(Figures(f).Number)
                        FigDiag = matlab.unittest.diagnostics.FigureDiagnostic(Figures(f),'Formats','png');
                        log(testCase,1,FigDiag);
                    end
                end
            end

            % Close all figures and Simulink models
            close all force
            if any(matlab.addons.installedAddons().Name == "Simulink")
                bdclose all
            end

            % Rethrow error if any
            if exist("ME","var")
                if ~any(strcmp(ME.identifier,KnownIssuesID))
                    rethrow(ME)
                end
            end

        end
            
    end % Test Methods


    methods (Access = private)

       function Path = CheckPreFile(testCase,Filename)
            PreFile = "Pre"+replace(Filename,".mlx",".m");
            PreFilePath = fullfile(testCase.RootFolder,"SoftwareTests","PreFiles",PreFile);
            if ~isfolder(fullfile(testCase.RootFolder,"SoftwareTests/PreFiles"))
                mkdir(fullfile(testCase.RootFolder,"SoftwareTests/PreFiles"))
            end
            if ~isfile(PreFilePath)
                writelines("%  Pre-run script for "+Filename,PreFilePath)
                writelines("% ---- Known Issues     -----",PreFilePath,'WriteMode','append');
                writelines("KnownIssuesID = "+char(34)+char(34)+";",PreFilePath,'WriteMode','append');
                writelines("% ---- Pre-run commands -----",PreFilePath,'WriteMode','append');
                writelines(" ",PreFilePath,'WriteMode','append');
            end
            Path = PreFilePath;
        end

        function Path = CheckPostFile(testCase,Filename)
            PostFile = "Post"+replace(Filename,".mlx",".m");
            PostFilePath = fullfile(testCase.RootFolder,"SoftwareTests","PostFiles",PostFile);
            if ~isfolder(fullfile(testCase.RootFolder,"SoftwareTests/PostFiles"))
                mkdir(fullfile(testCase.RootFolder,"SoftwareTests/PostFiles"))
            end
            if ~isfile(PostFilePath)
                writelines("%  Post-run script for "+Filename,PostFilePath)
                writelines("% ---- Post-run commands -----",PostFilePath,'WriteMode','append');
                writelines(" ",PostFilePath,'WriteMode','append');
            end
            Path = PostFilePath;
        end

    end % Private Methods

end % Smoketests