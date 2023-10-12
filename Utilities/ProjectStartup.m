function ProjectStartup
% Set up check for version number
proj = currentProject;
if isMATLABReleaseOlderThan("R2023b")
    cd(proj.RootFolder)
    try
        if exist(fullfile("Utilities","OldVersions","MainMenuOld.mlx"),"file")
            movefile("MainMenu.mlx", fullfile("Utilities","OldVersions","MainMenuNew.mlx"))
            movefile(fullfile("Utilities","OldVersions","MainMenuOld.mlx"),fullfile(proj.RootFolder,"MainMenu.mlx"))
        end
    catch 
        disp("Failed to move MainMenu.mlx.")
    end
    try
        if exist(fullfile("Utilities","OldVersions","READMEOld.mlx"),"file")
            movefile("README.mlx", fullfile("Utilities","OldVersions","READMENew.mlx"))
            movefile(fullfile("Utilities","OldVersions","READMEOld.mlx"),fullfile(proj.RootFolder,"README.mlx"))
        end
    catch
        disp("Failed to move README.mlx.")
    end
end
ProjectStartupApp
end