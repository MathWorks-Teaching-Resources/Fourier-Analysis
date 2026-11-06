% Close the StartUp app if still open:
delete(findall(groot,'Name','StartUp App'))

% Remove instructor folders added by the startup app or toolkit.
removeInstructorPath();
% <matlab:ShareFeedback Share your feedback>

function removeInstructorPath()
instructorFolders = split(string(genpath( ...
    fullfile(currentProject().RootFolder,"InstructorResources"))),pathsep);
foldersToRemove = cellstr(intersect(instructorFolders,split(string(path),pathsep)));
if ~isempty(foldersToRemove)
    rmpath(foldersToRemove{:})
end
end
