function OpenOverview
curFile = matlab.desktop.editor.getActive;
if isMATLABReleaseOlderThan("R2023b")
    open("Navigation2.mlx")
else
    open("Navigation.mlx")
end
navFile = matlab.desktop.editor.getActive;
if string(curFile.Filename) ~= string(navFile.Filename)
    close(curFile)
end
end
