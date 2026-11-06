function CreateStudentApp(projectRoot)
% CreateStudentApp Configure the startup app for student-only access.
%
%   CreateStudentApp(PROJECTROOT) enables HideInstructorResources in
%   Utilities/ProjectStartupApp.m in the exported project.

arguments
    projectRoot (1,1) string {mustBeFolder}
end

appFile = fullfile(projectRoot,"Utilities","ProjectStartupApp.m");
if ~isfile(appFile)
    error("CreateStudentApp:MissingSource", ...
        "The startup app must exist in Utilities.")
end
appText = fileread(appFile);
pattern = '(?m)^(\s*HideInstructorResources\s*=\s*)(?:false|true)(\s*;)';
if isempty(regexp(appText,pattern,"once"))
    error("CreateStudentApp:MissingConfiguredProperties", ...
        "Could not find the HideInstructorResources flag.")
end
appText = regexprep(appText,pattern,'$1true$2',"once");
writelines(appText,appFile)
end
