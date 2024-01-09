function ProjectShutdown
% Reset module to original state that is expected when loading in a new
% MATLAB version.
proj = currentProject;
if isMATLABReleaseOlderThan("R2023b")
    cd(proj.RootFolder)
    try
        if exist(fullfile("Utilities","OldVersions","MainMenuNew.mlx"),"file")
            movefile("MainMenu.mlx", fullfile("Utilities","OldVersions","MainMenuOld.mlx"))
            movefile(fullfile("Utilities","OldVersions","MainMenuNew.mlx"),fullfile(proj.RootFolder,"MainMenu.mlx"))
        end
    catch 
        disp("Failed to move MainMenu.mlx.")
    end
    try
        if exist(fullfile("Utilities","OldVersions","READMENew.mlx"),"file")
            movefile("README.mlx", fullfile("Utilities","OldVersions","READMEOld.mlx"))
            movefile(fullfile("Utilities","OldVersions","READMENew.mlx"),fullfile(proj.RootFolder,"README.mlx"))
        end
    catch
        disp("Failed to move README.mlx.")
    end
end
end