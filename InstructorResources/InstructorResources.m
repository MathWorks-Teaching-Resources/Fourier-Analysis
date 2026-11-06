classdef InstructorResources < matlab.apps.AppBase
    %InstructorResources - Browse instructor Markdown documentation
    %   APP = InstructorResources opens the instructor README in an
    %   HTML reader with page navigation. Links to MATLAB scripts open in
    %   the editor without running them.
    %
    %   InstructorResources properties:
    %       UIFigure - Documentation window
    %       HTML     - HTML documentation reader
    %       CurrentPage - Repository-relative path of the rendered page
    %       LastError - Most recent reader or navigation error
    %
    %   See also uihtml, edit

    properties (SetAccess = private)
        UIFigure matlab.ui.Figure % Documentation window
        HTML matlab.ui.control.HTML % HTML documentation reader
        CurrentPage string = "" % Repository-relative rendered page path
        LastError string = "" % Most recent reader or navigation error
    end

    properties (Access = private)
        DocumentationRoot string
        RepositoryRoot string
        PageCache = struct('Filename',{},'Page',{})
        AssetCache = struct('Filename',{},'ID',{},'DataURI',{})
        SentAssets = false(1,0)
        StudentOutput string = ""
        StudentLocalBranch logical = false
    end

    methods
        function app = InstructorResources
            app.DocumentationRoot = string(fileparts(mfilename('fullpath')));
            app.RepositoryRoot = string(fileparts(app.DocumentationRoot));
            addpath(genpath(app.DocumentationRoot));
            screen = get(groot,'ScreenSize');
            windowSize = min([1320 760],max([1 1],screen(3:4)-80));
            windowPosition = [screen(1:2)+(screen(3:4)-windowSize)/2 windowSize];
            app.UIFigure = uifigure('Name','Instructor Resources', ...
                'Position',windowPosition,'Visible','off');
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);
            layout = uigridlayout(app.UIFigure,[1 1]);
            layout.Padding = [0 0 0 0];
            app.HTML = uihtml(layout);
            app.HTML.HTMLEventReceivedFcn = @(~,event) app.handleEvent(event);
            app.HTML.HTMLSource = app.htmlSource();
            registerApp(app,app.UIFigure);
            app.UIFigure.Visible = 'on';
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function handleEvent(app,event)
            %handleEvent - Dispatch reader requests and report errors
            try
                if app.StudentLocalBranch && ~ismember(string(event.HTMLEventName), ...
                        ["OpenStudentVersion","Rendered","ReaderError"])
                    error('InstructorResources:StudentBranchActive', ...
                        'The student branch is ready. Open the student version to continue.');
                end
                switch string(event.HTMLEventName)
                    case "Ready"
                        app.SentAssets(:) = false;
                        app.sendCatalog();
                    case "Open"
                        data = event.HTMLEventData;
                        requestedPath = app.textField(data,'Path');
                        filename = app.resolveDocument(requestedPath);
                        [~,~,extension] = fileparts(filename);
                        if strcmpi(extension,'.m')
                            addpath(app.DocumentationRoot, ...
                                fullfile(app.DocumentationRoot,'HelperFunctions'));
                            edit(char(filename));
                            app.LastError = "";
                            sendEventToHTMLSource(app.HTML,'Status', ...
                                struct('Message','Opened in the MATLAB editor.'));
                        else
                            page = app.readPage(filename);
                            app.LastError = "";
                            sendEventToHTMLSource(app.HTML,'Page',page);
                        end
                    case "Web"
                        url = app.textField(event.HTMLEventData,'URL');
                        if isempty(regexp(url,'^https?://[^\s]+$','once'))
                            error('InstructorResources:InvalidURL', ...
                                'This link is not an HTTP or HTTPS address.');
                        end
                        status = web(char(url),'-browser');
                        if status ~= 0
                            error('InstructorResources:Browser', ...
                                'The browser could not open this link.');
                        end
                    case "Feedback"
                        app.openFacultyFeedback();
                    case "StartUp"
                        previousPath = path;
                        pathCleanup = onCleanup(@() path(previousPath));
                        addpath(fullfile(app.RepositoryRoot,'Utilities'));
                        ProjectStartupApp;
                        delete(app);
                    case "StudentVersion"
                        [~,name] = fileparts(app.RepositoryRoot);
                        sendEventToHTMLSource(app.HTML,'StudentDefaults', ...
                            struct('Parent',char(fileparts(app.RepositoryRoot)), ...
                            'FolderName',char(name + "-Student"), ...
                            'Source',char(app.RepositoryRoot), ...
                            'WorktreeDestination',char(app.RepositoryRoot + "-student"), ...
                            'BranchAvailable',app.studentBranchAvailable(), ...
                            'Output',char(app.StudentOutput)));
                    case "BrowseStudentFolder"
                        parent = uigetdir(fileparts(app.RepositoryRoot), ...
                            'Choose parent folder for the student copy');
                        if ~isequal(parent,0)
                            sendEventToHTMLSource(app.HTML,'StudentFolder', ...
                                struct('Parent',parent));
                        end
                    case "BrowseStudentWorktree"
                        parent = uigetdir(fileparts(app.RepositoryRoot), ...
                            'Choose a parent folder for the new worktree');
                        if ~isequal(parent,0)
                            [~,name] = fileparts(app.RepositoryRoot);
                            sendEventToHTMLSource(app.HTML,'StudentWorktreeFolder', ...
                                struct('Destination',char(fullfile(parent,name + "-student"))));
                        end
                    case "CreateStudentVersion"
                        app.createStudentVersion(event.HTMLEventData);
                    case "DetectStudentVersion"
                        parent = strtrim(app.textField(event.HTMLEventData,'Parent'));
                        folderName = strtrim(app.textField(event.HTMLEventData,'FolderName'));
                        output = "";
                        if folderName ~= "." && folderName ~= ".." && ...
                                ~contains(folderName,["/","\",":"]) && isfolder(parent)
                            target = string(fullfile(parent,folderName));
                            if app.isStudentVersion(target)
                                output = target;
                            end
                        end
                        app.StudentOutput = output;
                        sendEventToHTMLSource(app.HTML,'StudentDetected', ...
                            struct('Parent',char(parent),'FolderName',char(folderName), ...
                            'Output',char(output)));
                    case "OpenStudentVersion"
                        if app.StudentOutput == "" || ~app.isStudentVersion(app.StudentOutput)
                            error('InstructorResources:MissingStudentCopy', ...
                                'Create a student version before opening it.');
                        end
                        openProject(app.StudentOutput);
                        delete(app);
                    case "Rendered"
                        app.CurrentPage = app.textField(event.HTMLEventData,'Path');
                        app.LastError = "";
                    case "ReaderError"
                        app.LastError = app.textField(event.HTMLEventData,'Message');
                end
            catch exception
                app.LastError = string(exception.message);
                sendEventToHTMLSource(app.HTML,'Error', ...
                    struct('Message',exception.message));
            end
        end

        function openFacultyFeedback(app)
            %openFacultyFeedback - Open the shared faculty form directly
            [~,projectName] = fileparts(app.RepositoryRoot);
            projectName = string(projectName);
            try
                project = currentProject();
                if string(project.RootFolder) == app.RepositoryRoot
                    projectName = string(project.Name);
                end
            catch
                % The documentation also works without an open project.
            end
            if isempty(which('ShareFeedback'))
                previousPath = path;
                pathCleanup = onCleanup(@() path(previousPath));
                addpath(fullfile(app.RepositoryRoot,'Utilities'));
            end
            ShareFeedback(Role="faculty",ProjectName=projectName,Parent=app.UIFigure);
            sendEventToHTMLSource(app.HTML,'Status', ...
                struct('Message','Faculty feedback opened in your browser.'));
        end

        function sendCatalog(app)
            %sendCatalog - Discover readable pages without exposing helpers
            files = dir(fullfile(app.DocumentationRoot,'Documentation','**','*.md'));
            pages = struct('Path',{},'Title',{});
            for index = 1:numel(files)
                filename = fullfile(files(index).folder,files(index).name);
                relative = app.relativePath(filename);
                if app.isExcluded(relative)
                    continue
                end
                markdown = string(fileread(filename));
                title = regexp(markdown,'(?m)^#\s+([^\r\n]+)', ...
                    'tokens','once');
                if isempty(title)
                    title = erase(string(files(index).name),'.md');
                else
                    title = string(title{1});
                end
                pages(end+1) = struct('Path',char(relative),'Title',char(title)); %#ok<AGROW>
            end
            sendEventToHTMLSource(app.HTML,'Catalog', ...
                struct('Pages',{pages}, ...
                'Home','InstructorResources/Documentation/README.md'));
        end

        function available = studentBranchAvailable(app)
            available = false;
            try
                project = currentProject();
                if string(project.RootFolder) ~= app.RepositoryRoot || ...
                        ~strcmpi(project.SourceControlIntegration,'Git')
                    return
                end
                [status,result] = system(sprintf( ...
                    'git -C "%s" rev-parse --is-inside-work-tree',app.RepositoryRoot));
                available = status == 0 && strtrim(string(result)) == "true";
            catch
                % No current project or source-control integration.
            end
        end

        function detected = isStudentVersion(~,folder)
            startup = fullfile(folder,'Utilities','ProjectStartupApp.m');
            detected = isfolder(folder) && ~isfolder(fullfile(folder,'InstructorResources')) && ...
                isfile(startup) && (isfile(fullfile(folder,'matlab.toml')) || ...
                ~isempty(dir(fullfile(folder,'*.prj'))));
            if detected
                detected = ~isempty(regexp(fileread(startup), ...
                    '(?m)^\s*HideInstructorResources\s*=\s*true\s*;','once'));
            end
        end

        function createStudentVersion(app,data)
            project = currentProject();
            if string(project.RootFolder) ~= app.RepositoryRoot
                error('InstructorResources:WrongProject', ...
                    'Open this courseware project before creating a student version.');
            end
            mode = app.textField(data,'Mode');
            if ~ismember(mode,["export","branch"])
                error('InstructorResources:InvalidMode', ...
                    'Choose another folder or another branch.');
            end
            branchName = "student";
            useWorktree = true;
            openAfterCreate = false;
            if mode == "branch"
                if ~app.studentBranchAvailable()
                    error('InstructorResources:BranchUnavailable', ...
                        'Branch mode is available only when the current project is tracked by Git and Git is installed.');
                end
                branchName = strtrim(app.textField(data,'BranchName'));
                if isempty(regexp(branchName,'^[A-Za-z0-9][A-Za-z0-9._/-]*$','once'))
                    error('InstructorResources:InvalidBranch', ...
                        'Start the branch name with a letter or number and use letters, numbers, dots, underscores, hyphens, or slashes.');
                end
                [status,~] = system(sprintf('git check-ref-format --branch "%s"',branchName));
                if status ~= 0
                    error('InstructorResources:InvalidBranch','Enter a valid new Git branch name.');
                end
                if ~isfield(data,'UseWorktree') || ~islogical(data.UseWorktree) || ~isscalar(data.UseWorktree)
                    error('InstructorResources:InvalidRequest','Choose whether to use a separate worktree.');
                end
                useWorktree = data.UseWorktree;
                if ~isfield(data,'OpenAfterCreate') || ~islogical(data.OpenAfterCreate) || ~isscalar(data.OpenAfterCreate)
                    error('InstructorResources:InvalidRequest','Choose whether to open the student project after creation.');
                end
                openAfterCreate = data.OpenAfterCreate;
                if useWorktree
                    destination = strtrim(app.textField(data,'Destination'));
                    [parent,folderName] = fileparts(destination);
                end
            else
                parent = strtrim(app.textField(data,'Parent'));
                folderName = strtrim(app.textField(data,'FolderName'));
            end
            localBranch = mode == "branch" && ~useWorktree;
            if localBranch
                target = app.RepositoryRoot;
            else
                if ~isfolder(parent) || ~(startsWith(parent,'/') || ...
                        startsWith(parent,'\\') || ...
                        ~isempty(regexp(parent,'^[A-Za-z]:[\\/]','once')))
                    error('InstructorResources:InvalidDestination', ...
                        'Choose an existing parent folder with an absolute path.');
                end
                if folderName == "" || folderName == "." || folderName == ".." || ...
                        contains(folderName,["/","\",":"]) || any(double(char(folderName)) < 32)
                    error('InstructorResources:InvalidDestination','Enter a single new folder name.');
                end
                previousFolder = pwd;
                folderCleanup = onCleanup(@() cd(previousFolder));
                cd(parent);
                parent = string(pwd);
                cd(app.RepositoryRoot);
                source = string(pwd);
                clear folderCleanup
                target = string(fullfile(parent,folderName));
                if isfolder(target) || isfile(target) || strcmpi(target,source) || ...
                        startsWith(lower(target),lower(source + filesep))
                    error('InstructorResources:InvalidDestination', ...
                        'Choose a new folder outside the source project.');
                end
            end
            progress = uiprogressdlg(app.UIFigure,'Title','Creating student version', ...
                'Message','Copying and configuring learner materials...','Indeterminate','on');
            progressCleanup = onCleanup(@() close(progress));
            previousPath = path;
            if ~localBranch
                pathCleanup = onCleanup(@() path(previousPath));
            end
            addpath(fullfile(app.DocumentationRoot,'HelperFunctions'));
            if localBranch
                app.StudentOutput = CreateStudentVersionHelper(mode, ...
                    BranchName=branchName,UseWorktree=false);
            else
                app.StudentOutput = CreateStudentVersionHelper(mode, ...
                    Destination=target,BranchName=branchName,UseWorktree=useWorktree);
            end
            app.StudentLocalBranch = localBranch;
            clear progressCleanup
            app.LastError = "";
            sendEventToHTMLSource(app.HTML,'StudentCreated', ...
                struct('Output',char(app.StudentOutput),'Mode',char(mode), ...
                'BranchName',char(branchName),'LocalBranch',localBranch));
            if openAfterCreate
                openProject(app.StudentOutput);
                delete(app);
            end
        end

        function filename = resolveDocument(app,relative)
            %resolveDocument - Limit navigation to courseware documents
            filename = app.resolvePath(relative);
            if app.isExcluded(app.relativePath(filename))
                error('InstructorResources:Excluded', ...
                    'This resource is outside the instructor documentation.');
            end
            [~,~,extension] = fileparts(filename);
            if ~any(strcmpi(extension,{'.md','.m'})) || ~isfile(filename)
                error('InstructorResources:MissingDocument', ...
                    'The requested document is unavailable: %s',relative);
            end
            if strcmpi(extension,'.m') && ...
                    ~startsWith(lower(filename),lower(app.DocumentationRoot + filesep))
                error('InstructorResources:ExcludedScript', ...
                    'Only instructor scripts can be opened from this reader.');
            end
        end

        function filename = resolvePath(app,relative)
            %resolvePath - Resolve local paths using MATLAB only
            relative = replace(string(relative),'\','/');
            if startsWith(relative,'/') || contains(relative,':') || ...
                    any(double(char(relative)) < 32)
                error('InstructorResources:InvalidPath','Invalid local document path.');
            end
            parts = split(relative,'/');
            resolved = strings(0,1);
            for index = 1:numel(parts)
                part = parts(index);
                if part == "" || part == "."
                    continue
                elseif part == ".."
                    if isempty(resolved)
                        error('InstructorResources:Excluded', ...
                            'This resource is outside the courseware folder.');
                    end
                    resolved(end) = [];
                else
                    resolved(end+1,1) = part; %#ok<AGROW>
                end
            end
            segments = cellstr(resolved);
            filename = string(fullfile(app.RepositoryRoot,segments{:}));
        end

        function page = readPage(app,filename)
            %readPage - Load Markdown and resolve its local image resources
            cacheIndex = find(strcmp({app.PageCache.Filename},char(filename)),1);
            if ~isempty(cacheIndex)
                page = app.withPendingAssets(app.PageCache(cacheIndex).Page);
                return
            end
            markdown = string(fileread(filename));
            patterns = {'src="([^"]+)"','!\[[^\]]*\]\(([^)]+)\)'};
            for patternIndex = 1:numel(patterns)
                matches = regexp(markdown,patterns{patternIndex},'tokens');
                for index = 1:numel(matches)
                    source = string(matches{index}{1});
                    if startsWith(source,["http:","https:","data:"])
                        continue
                    end
                    relativeFolder = string(fileparts(app.relativePath(filename)));
                    imageFile = app.resolvePath(relativeFolder + "/" + source);
                    if ~isfile(imageFile)
                        continue
                    end
                    if startsWith(lower(imageFile),lower(app.RepositoryRoot + filesep))
                        [~,~,extension] = fileparts(imageFile);
                        extensions = [".png",".gif",".jpg",".jpeg",".svg"];
                        types = ["image/png","image/gif","image/jpeg", ...
                            "image/jpeg","image/svg+xml"];
                        typeIndex = find(strcmpi(extension,extensions),1);
                        if isempty(typeIndex)
                            continue
                        end
                        assetIndex = find(strcmp({app.AssetCache.Filename},char(imageFile)),1);
                        if ~isempty(assetIndex)
                            markdown = replace(markdown,source,string(app.AssetCache(assetIndex).ID));
                            continue
                        end
                        fileID = fopen(imageFile,'rb');
                        if fileID < 0
                            continue
                        end
                        cleanup = onCleanup(@() fclose(fileID));
                        bytes = fread(fileID,Inf,'uint8=>uint8');
                        resolved = "data:" + types(typeIndex) + ";base64," + ...
                            string(app.encodeImage(bytes));
                        clear cleanup
                        assetID = sprintf('asset-%d',numel(app.AssetCache)+1);
                        app.AssetCache(end+1) = struct('Filename',char(imageFile), ...
                            'ID',assetID,'DataURI',char(resolved));
                        app.SentAssets(end+1) = false;
                        resolved = string(assetID);
                    else
                        continue
                    end
                    markdown = replace(markdown,source,resolved);
                end
            end
            page = struct('Path',char(app.relativePath(filename)), ...
                'Markdown',char(markdown));
            app.PageCache(end+1) = struct('Filename',char(filename),'Page',page);
            page = app.withPendingAssets(page);
        end

        function page = withPendingAssets(app,page)
            %withPendingAssets - Transfer each image only once per reader
            required = regexp(page.Markdown,'asset-\d+','match');
            indices = find(~app.SentAssets & ismember({app.AssetCache.ID},required));
            assets = struct('ID',{},'DataURI',{});
            for index = indices
                assets(end+1) = struct('ID',app.AssetCache(index).ID, ...
                    'DataURI',app.AssetCache(index).DataURI); %#ok<AGROW>
            end
            page.Assets = assets;
            app.SentAssets(indices) = true;
        end

        function relative = relativePath(app,filename)
            %relativePath - Produce repository-relative web paths
            relative = replace(extractAfter(string(filename), ...
                strlength(app.RepositoryRoot) + 1),filesep,'/');
        end
    end

    methods (Static, Access = private)
        function encoded = encodeImage(bytes)
            %encodeImage - Encode image bytes in vectorized Base64 groups
            padding = mod(-numel(bytes),3);
            triplets = reshape([bytes(:); zeros(padding,1,'uint8')],3,[]);
            indices = zeros(4,size(triplets,2),'uint8');
            indices(1,:) = bitshift(triplets(1,:),-2);
            indices(2,:) = bitor(bitshift(bitand(triplets(1,:),3),4), ...
                bitshift(triplets(2,:),-4));
            indices(3,:) = bitor(bitshift(bitand(triplets(2,:),15),2), ...
                bitshift(triplets(3,:),-6));
            indices(4,:) = bitand(triplets(3,:),63);
            alphabet = uint8('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/');
            encoded = reshape(char(alphabet(double(indices(:))+1)),1,[]);
            if padding > 0
                encoded(end-padding+1:end) = '=';
            end
        end

        function source = htmlSource()
            %htmlSource - Return the embedded documentation reader
            lines = {
                '<!doctype html>'
                '<html lang="en">'
                '<head>'
                '<meta charset="utf-8">'
                '<meta name="viewport" content="width=device-width,initial-scale=1">'
                '<title>Instructor Resources</title>'
                '<style>'
                '* { box-sizing: border-box; }'
                'html, body { height: 100%; margin: 0; }'
                'body { font: 13px/1.55 Arial, Helvetica, sans-serif; background: #fff; color: #333; }'
                '.app { display: grid; grid-template-rows: minmax(0, 1fr) auto; height: 100%; }'
                '.sidebar-actions { display: flex; align-items: center; justify-content: space-between; padding: 6px 12px; border-bottom: 1px solid #d6d6d6; }'
                '#startup { display: inline-flex; align-items: center; gap: 6px; }'
                '#startup svg { width: 18px; height: 18px; }'
                'button { font: inherit; }'
                'button { cursor: pointer; padding: 5px 10px; border: 1px solid #bcbcbc; border-radius: 3px; background: #fff; color: #333; }'
                'button:hover { background: #eaf4fb; }'
                '#home { display: inline-flex; align-items: center; justify-content: center; width: 34px; height: 32px; padding: 5px; }'
                '#home svg { width: 20px; height: 20px; }'
                ':focus-visible { outline: 2px solid #0076a8; outline-offset: 2px; }'
                '.main { --left-width: 270px; --right-width: 270px; --outline-height: 150px; display: grid; grid-template-columns: var(--left-width) 6px minmax(0, 1fr) 6px var(--right-width); min-height: 0; }'
                '.main.student-mode { grid-template-columns: var(--left-width) 6px minmax(0, 1fr); }'
                '.main.student-mode .reader { grid-column: 3 / -1; }'
                '.main.student-mode { grid-template-rows: minmax(0, 1fr); }'
                '.main.student-mode .page-sidebar { grid-row: 1; }'
                '.panel-divider { cursor: col-resize; touch-action: none; background: #d6d6d6; }'
                '.panel-divider:hover, .panel-divider:focus-visible, .panel-divider.dragging { background: #0076a8; }'
                '.resizing-panels, .resizing-panels * { cursor: col-resize !important; user-select: none !important; }'
                '.resizing-rows, .resizing-rows * { cursor: row-resize !important; }'
                'aside { min-height: 0; overflow: auto; background: #f5f5f5; }'
                '.page-sidebar { display: grid; grid-template-rows: auto auto minmax(0, 1fr) auto; border-right: 1px solid #d6d6d6; }'
                '#pages { overflow: auto; }'
                '.sidebar-sections { overflow: auto; min-height: 0; }'
                '#student-workflow { --form-background: #f5f5f5; --field-background: #fff; --field-border: #737373; --action-color: #0076a8; --action-hover: #005a80; --action-text: #fff; --action-highlight: #eaf4fb; --disabled-background: #e5e5e5; --disabled-text: #666; --disabled-border: #aaa; }'
                '.workflow-form { display: grid; gap: 10px; margin: 20px 0; padding: 20px; border: 1px solid var(--disabled-border); border-radius: 6px; background: var(--form-background); }'
                '.workflow-form label { font-weight: 700; font-size: 14px; }'
                '.workflow-mode { display: grid; gap: 10px; }'
                '.folder-picker { display: flex; gap: 8px; }'
                '.folder-picker input { flex: 1; min-width: 0; }'
                '.workflow-form input { font: inherit; font-size: 14px; min-height: 42px; min-width: 0; width: 100%; padding: 10px 12px; border: 2px solid var(--field-border); border-radius: 4px; background: var(--field-background); }'
                '.workflow-form input:hover:not(:disabled) { border-color: var(--action-color); }'
                '.workflow-form input:focus { border-color: var(--action-color); outline: 2px solid var(--action-color); outline-offset: 2px; }'
                '.workflow-form .worktree-option { display: flex; align-items: center; gap: 8px; font-weight: 400; }'
                '.branch-dialog { width: min(560px, calc(100% - 32px)); padding: 24px; border: 1px solid #aaa; border-radius: 6px; color: #333; }'
                '.branch-dialog::backdrop { background: rgba(0, 0, 0, .35); }'
                '.branch-dialog h2 { margin-top: 0; }'
                '.branch-dialog .workflow-actions { margin-top: 20px; }'
                '.workflow-form input[type="checkbox"] { width: 16px; height: 16px; min-height: 16px; padding: 0; accent-color: var(--action-color); }'
                '.workflow-form button { min-height: 42px; padding: 10px 16px; font-size: 14px; font-weight: 700; border: 2px solid var(--action-color); border-radius: 4px; color: var(--action-color); background: var(--field-background); }'
                '.workflow-form button:hover:not(:disabled) { background: var(--action-highlight); }'
                '.workflow-form button:active:not(:disabled) { border-color: var(--action-hover); background: var(--action-highlight); }'
                '#student-create { color: var(--action-text); background: var(--action-color); }'
                '#student-create:hover:not(:disabled), #student-create:active:not(:disabled) { background: var(--action-hover); border-color: var(--action-hover); }'
                '.workflow-form button:disabled, #student-create:disabled, .workflow-form input:disabled { cursor: default; color: var(--disabled-text); background: var(--disabled-background); border-color: var(--disabled-border); }'
                '.workflow-tabs { display: flex; flex-wrap: wrap; gap: 16px; border-bottom: 1px solid var(--disabled-border); }'
                '.workflow-form .workflow-tabs button { min-height: 32px; padding: 6px 2px; border: 0; border-bottom: 2px solid transparent; border-radius: 0; font-weight: 400; color: #666; background: transparent; }'
                '.workflow-form .workflow-tabs button[aria-selected="true"] { color: var(--action-color); border-bottom-color: var(--action-color); font-weight: 600; }'
                '.workflow-form .workflow-tabs button:hover:not(:disabled), .workflow-form .workflow-tabs button:active:not(:disabled) { color: var(--action-hover); background: transparent; }'
                '.workflow-form .workflow-tabs button:disabled { opacity: .5; }'
                '.workflow-actions { display: flex; flex-wrap: wrap; gap: 10px; }'
                '.workflow-form p { margin: 4px 0; }'
                '#student-result { overflow-wrap: anywhere; }'
                '[hidden] { display: none !important; }'
                '.feedback-section { padding: 14px 16px; border-top: 1px solid #d6d6d6; }'
                '.page-index-header { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid #d6d6d6; }'
                '.page-index-header .panel-title { padding: 0; border: 0; }'
                '.outline-sidebar { border-left: 1px solid #d6d6d6; }'
                '.panel-title { margin: 0; padding: 12px 16px 9px; border-bottom: 1px solid #d6d6d6; font-size: 13px; font-weight: 700; }'
                'nav { display: grid; align-content: start; padding: 8px 0; }'
                'nav button, nav a { display: block; width: 100%; border: 0; border-left: 4px solid transparent; border-radius: 0; padding: 7px 16px 7px 12px; color: #333; background: transparent; text-align: left; text-decoration: none; line-height: 1.35; }'
                '#pages button, #student { min-width: max-content; white-space: nowrap; }'
                '#outline a { min-width: 0; white-space: normal; overflow-wrap: anywhere; line-height: 1.45; padding-top: 8px; padding-bottom: 8px; }'
                '.page-sidebar, .outline-sidebar { min-width: 0; }'
                '#outline { min-width: 0; overflow: auto; }'
                'nav button:hover, nav a:hover { border-left-color: #0076a8; color: #000; background: #eaf4fb; }'
                'nav [aria-current] { border-left-color: #0076a8; color: #005a80; background: #d9edf7; font-weight: 600; box-shadow: inset 2px 0 0 #0076a8; }'
                'nav [aria-current]:hover { background: #cce5f2; }'
                '#outline .depth-3 { padding-left: 22px; }'
                '#outline .depth-4, #outline .depth-5, #outline .depth-6 { padding-left: 30px; }'
                '.reader { overflow: auto; padding: 28px 44px 36px; min-width: 0; }'
                'article { max-width: 820px; margin: 0 auto; overflow-wrap: anywhere; }'
                'h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 18px 0 8px; scroll-margin-top: 16px; }'
                'h1 { font-size: 26px; font-weight: 400; margin-top: 0; }'
                'h2 { font-size: 20px; font-weight: 400; border-bottom: 1px solid #d6d6d6; padding-bottom: 6px; }'
                'h3 { font-size: 16px; }'
                'h4, h5, h6 { font-size: 14px; }'
                '#content > h2 { border-bottom: 0; padding-bottom: 0; }'
                '#content > :is(h1, h2, h3, h4, h5, h6):not(:first-child) { border-top: 1px solid #d6d6d6; margin-top: 28px; padding-top: 20px; }'
                'p, ul, ol, blockquote, pre, .table-wrap { margin: 0 0 12px; }'
                'li > ul, li > ol { margin-bottom: 0; }'
                'li { margin: .25em 0; }'
                'a { color: #0076a8; text-decoration: none; }'
                'a:hover { text-decoration: underline; }'
                'img { max-width: 100%; height: auto; vertical-align: middle; }'
                '.expandable-gif { cursor: zoom-in; }'
                '.viewing-gif .app { visibility: hidden; }'
                '.gif-viewer { position: fixed; inset: 0; z-index: 100; display: grid; grid-template-rows: auto minmax(0, 1fr); background: #111; color: #fff; }'
                '.gif-viewer[hidden] { display: none; }'
                '.gif-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 10px 16px; }'
                '.gif-stage { display: flex; align-items: center; justify-content: center; min-height: 0; padding: 0 12px 12px; }'
                '.gif-stage img { width: 100%; height: 100%; object-fit: contain; }'
                '#closeGif { display: inline-flex; align-items: center; justify-content: center; width: 40px; height: 40px; padding: 0; font-size: 30px; line-height: 1; }'
                'pre { padding: 10px; border: 1px solid #d6d6d6; border-left-width: 4px; background: #f7f7f7; overflow: auto; overflow-wrap: normal; }'
                'code { font: .95em/1.5 Consolas, "Courier New", monospace; }'
                'p code, li code, td code { padding: 1px 4px; border: 1px solid #d6d6d6; background: #f7f7f7; }'
                'blockquote { border-left: 2px solid #0076a8; padding-left: 1.5em; color: #000; }'
                '.table-wrap { overflow-x: auto; }'
                'table { border-collapse: collapse; width: 100%; }'
                'th, td { border: 1px solid #d6d6d6; padding: 8px 10px; text-align: left; vertical-align: top; }'
                'th { background: #f2f2f2; }'
                'footer { padding: 6px 16px; border-top: 1px solid #d6d6d6; min-height: 32px; background: #f5f5f5; overflow-wrap: anywhere; }'
                '#path { font-size: 12px; color: #666; margin-bottom: 12px; }'
                '@media (max-width: 900px) {'
                '    .main { --left-width: 190px; --right-width: 180px; }'
                '    .reader { padding: 24px; }'
                '}'
                '@media (max-width: 640px) {'
                '    .main { --left-width: 150px; grid-template-columns: var(--left-width) 6px minmax(0, 1fr); grid-template-rows: minmax(0, 1fr) 6px var(--outline-height); }'
                '    .page-sidebar, #left-divider { grid-row: 1 / 4; }'
                '    .reader { grid-column: 3; grid-row: 1; }'
                '    #right-divider { grid-column: 3; grid-row: 2; cursor: row-resize; }'
                '    .outline-sidebar { grid-column: 3; grid-row: 3; border-left: 0; border-top: 1px solid #d6d6d6; }'
                '    .main.student-mode #left-divider { grid-row: 1; }'
                '    .reader { padding: 16px; }'
                '}'
                '</style>'
                '</head>'
                '<body>'
                '<div class="app">'
                '    <div class="main">'
                '        <aside id="navigation-panel" class="page-sidebar" aria-label="Instructor documentation navigation">'
                '            <div class="sidebar-actions" role="group" aria-label="Home and exit">'
                '        <button id="home" type="button" aria-label="Documentation home" title="Documentation home">'
                '            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M3 10.5 12 3l9 7.5M5 9v12h5v-7h4v7h5V9"/></svg>'
                '        </button>'
                '        <button id="startup" type="button" aria-label="Exit documentation and return to StartUp App" title="Exit documentation and return to StartUp App">'
                '            <span>Exit</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M9 4H4v16h5M9 12h12m-4-4 4 4-4 4"/></svg>'
                '        </button>'
                '            </div>'
                '            <div class="page-index-header">'
                '            <h2 class="panel-title">Documentation</h2>'
                '            </div>'
                '            <div class="sidebar-sections">'
                '                <nav id="pages" aria-label="Documentation pages"></nav>'
                '                <h2 class="panel-title">Tools</h2>'
                '                <nav aria-label="Student version workflow"><button id="student" type="button">Create Student Version</button></nav>'
                '            </div>'
                '            <section class="feedback-section" aria-label="Share feedback">'
                '                <a id="feedback" href="#">Share feedback</a>'
                '            </section>'
                '        </aside>'
                '        <div id="left-divider" class="panel-divider" role="separator" tabindex="0" aria-label="Resize navigation panel" aria-orientation="vertical" aria-controls="navigation-panel" title="Drag to resize navigation; use arrow keys when focused"></div>'
                '        <main class="reader" id="reader" aria-label="Document">'
                '            <div id="path"></div>'
                '            <article id="content" aria-busy="true"><p>Loading instructor documentation…</p></article>'
                '            <article id="student-workflow" hidden>'
                '                <h1>Create Student Version</h1>'
                '                <p>Create a learner-ready version for your students.</p>'
                '                <ul><li><strong>Includes:</strong> activities, data, runtime files, a student-only startup app, LICENSE.md, and SECURITY.md.</li><li><strong>Removes:</strong> instructor resources and solutions, authoring files, tests, and build/CI tooling.</li></ul>'
                '                <p>Source project: <span id="student-source"></span></p>'
                '                <form id="student-form" class="workflow-form">'
                '                    <div class="workflow-tabs" role="tablist" aria-label="Create student version in">'
                '                        <button id="student-export-tab" type="button" role="tab" aria-selected="true" aria-controls="student-export-panel">In another folder</button>'
                '                        <button id="student-branch-tab" type="button" role="tab" aria-selected="false" aria-controls="student-branch-panel" tabindex="-1" disabled>On another branch</button>'
                '                    </div>'
                '                    <p id="student-branch-unavailable" hidden>Branch mode is available when the current project is tracked by Git and Git is installed.</p>'
                '                    <div id="student-export-panel" class="workflow-mode" role="tabpanel" aria-labelledby="student-export-tab">'
                '                        <p>Create an independent copy without Git history. Choose an existing parent folder and a new folder name outside the source project.</p>'
                '                        <label for="student-parent">Parent folder</label>'
                '                        <div class="folder-picker"><input id="student-parent" type="text" required><button id="student-browse" type="button">Browse...</button></div>'
                '                        <label for="student-name">New folder name</label>'
                '                        <input id="student-name" type="text" required>'
                '                        <p>Destination: <span id="student-destination"></span></p>'
                '                    </div>'
                '                    <div id="student-branch-panel" class="workflow-mode" role="tabpanel" aria-labelledby="student-branch-tab" hidden>'
                '                        <label for="student-branch-name">New branch name</label>'
                '                        <input id="student-branch-name" type="text" value="student" disabled>'
                '                        <label class="worktree-option"><input id="student-use-worktree" type="checkbox" disabled>Use a separate worktree</label>'
                '                        <div id="student-worktree-fields" class="workflow-mode" hidden>'
                '                            <label for="student-worktree-destination">Worktree folder</label>'
                '                            <div class="folder-picker"><input id="student-worktree-destination" type="text" disabled><button id="student-worktree-browse" type="button" disabled>Browse...</button></div>'
                '                            <p>Choose a new folder outside the source project. Browse selects its parent folder.</p>'
                '                        </div>'
                '                        <p id="student-local-note">Creates and switches to the new branch in the current folder, carrying your current learner-file changes into the student version. Instructor materials are removed. A confirmation dialog explains the switch and lets you open the student project when creation finishes.</p>'
                '                        <p id="student-worktree-note" hidden>Creates a new branch in a separate folder from the latest commit (HEAD). The source checkout stays unchanged.</p>'
                '                        <p>Git history is retained. Review and commit the student-file changes before sharing the branch. To return to your instructor version, commit or stash the student changes and switch back to your original branch.</p>'
                '                    </div>'
                '                    <div class="workflow-actions"><button id="student-create" type="submit">Create Student Version</button><button id="student-open" type="button" hidden disabled>Open Student Version</button></div>'
                '                </form>'
                '                <p id="student-result" role="status" aria-live="polite"></p>'
                '                <p>Review custom files and test the copy before sharing.</p>'
                '            </article>'
                '        </main>'
                '        <div id="right-divider" class="panel-divider" role="separator" tabindex="0" aria-label="Resize outline panel" aria-orientation="vertical" aria-controls="outline-panel" title="Drag to resize outline; use arrow keys when focused"></div>'
                '        <aside id="outline-panel" class="outline-sidebar" aria-label="Current page outline">'
                '            <h2 class="panel-title">On this page</h2>'
                '            <nav id="outline" aria-label="Page sections"></nav>'
                '        </aside>'
                '    </div>'
                '    <footer id="status" role="status" aria-live="polite"></footer>'
                '</div>'
                '<div id="gifViewer" class="gif-viewer" role="dialog" aria-modal="true" aria-label="Expanded animation" hidden>'
                '    <div class="gif-toolbar">'
                '        <span>Animation</span>'
                '        <button id="closeGif" type="button" aria-label="Close expanded animation" title="Close (Escape)">&times;</button>'
                '    </div>'
                '    <div class="gif-stage"><img id="expandedGif" alt=""></div>'
                '</div>'
                '<dialog id="student-branch-dialog" class="branch-dialog" aria-labelledby="student-branch-dialog-title">'
                '    <h2 id="student-branch-dialog-title">Create student branch</h2>'
                '    <p id="student-branch-dialog-message"></p>'
                '    <p id="student-branch-dialog-warning"><strong>All uncommitted changes will be lost on the original branch.</strong> They are not saved there. Current learner-file edits will carry into the student branch, while uncommitted instructor-only content will be removed.</p>'
                '    <p>You can open the student project when creation finishes. Review and commit the student-file changes before sharing.</p>'
                '    <div class="workflow-actions"><button id="student-branch-open" type="button">Create and Open Student Version</button><button id="student-branch-confirm" type="button">Create Branch</button><button id="student-branch-cancel" type="button">Cancel</button></div>'
                '</dialog>'
                '<script>'
                '"use strict";'
                'let bridge;'
                'let statusMessage = "";'
                'let hoveredLink = null;'
                'let focusedLink = null;'
                'let catalog = { Pages: [], Home: "InstructorResources/Documentation/README.md" };'
                'let currentPath = "";'
                'let pending = null;'
                'let gifReturnFocus = null;'
                'let studentInitialized = false;'
                'let studentOutput = "";'
                'let studentMode = "export";'
                'let studentBranchAvailable = false;'
                'let studentLocalBranchCreated = false;'
                'let studentBusy = false;'
                'let studentDetectionTimer;'
                'let pendingStudentRequest = null;'
                'const panelSizes = { left: null, right: null, outline: 150 };'
                'const imageAssets = new Map();'
                ''
                'window.setup = function setup(htmlComponent) {'
                '    bridge = htmlComponent;'
                '    setupPanelDividers();'
                '    document.addEventListener("mouseover", event => { hoveredLink = event.target.closest("a[href]"); updateLinkStatus(); });'
                '    document.addEventListener("mouseout", event => { hoveredLink = event.relatedTarget instanceof Element ? event.relatedTarget.closest("a[href]") : null; updateLinkStatus(); });'
                '    document.addEventListener("focusin", event => { focusedLink = event.target.closest("a[href]"); updateLinkStatus(); });'
                '    document.addEventListener("focusout", event => { focusedLink = event.relatedTarget instanceof Element ? event.relatedTarget.closest("a[href]") : null; updateLinkStatus(); });'
                '    window.addEventListener("error", event => {'
                '        const message = event.message || "The documentation reader encountered an error.";'
                '        setStatus(message);'
                '        bridge.sendEventToMATLAB("ReaderError", { Message: message });'
                '    });'
                '    bridge.addEventListener("Catalog", event => {'
                '        catalog = event.Data;'
                '        catalog.Pages = Array.isArray(catalog.Pages) ? catalog.Pages : (catalog.Pages ? [catalog.Pages] : []);'
                '        catalog.Pages.sort((a, b) => (a.Path === catalog.Home ? -1 : b.Path === catalog.Home ? 1 : a.Title.localeCompare(b.Title)));'
                '        renderPageList();'
                '        navigate(catalog.Home);'
                '    });'
                '    bridge.addEventListener("Page", event => {'
                '        const page = event.Data;'
                '        const assets = Array.isArray(page.Assets) ? page.Assets : (page.Assets ? [page.Assets] : []);'
                '        assets.forEach(asset => imageAssets.set(asset.ID, asset.DataURI));'
                '        if (!pending || page.Path !== pending.Path) return;'
                '        const request = pending;'
                '        pending = null;'
                '        currentPath = page.Path;'
                '        document.querySelector(".main").classList.remove("student-mode");'
                '        document.querySelector(".outline-sidebar").hidden = false;'
                '        document.getElementById("right-divider").hidden = false;'
                '        fitPanels();'
                '        document.getElementById("student-workflow").hidden = true;'
                '        document.getElementById("content").hidden = false;'
                '        document.getElementById("path").hidden = false;'
                '        const content = document.getElementById("content");'
                '        closeGif();'
                '        content.innerHTML = "";'
                '        content.appendChild(renderMarkdown(page.Markdown));'
                '        content.querySelectorAll("img[data-asset]").forEach(image => {'
                '            image.src = imageAssets.get(image.getAttribute("data-asset")) || "";'
                '        });'
                '        prepareGifImages();'
                '        content.setAttribute("aria-busy", "false");'
                '        renderOutline();'
                '        document.getElementById("path").textContent = page.Path;'
                '        const reader = document.getElementById("reader");'
                '        reader.scrollTop = 0;'
                '        if (request.Anchor) scrollToAnchor(request.Anchor);'
                '        renderPageList();'
                '        updateOutline();'
                '        setStatus("");'
                '        bridge.sendEventToMATLAB("Rendered", { Path: currentPath });'
                '    });'
                '    bridge.addEventListener("Status", event => setStatus(event.Data.Message));'
                '    bridge.addEventListener("StudentDefaults", event => {'
                '        if (!studentInitialized) {'
                '            document.getElementById("student-parent").value = event.Data.Parent;'
                '            document.getElementById("student-name").value = event.Data.FolderName;'
                '            document.getElementById("student-source").textContent = event.Data.Source;'
                '            document.getElementById("student-worktree-destination").value = event.Data.WorktreeDestination;'
                '            studentOutput = "";'
                '            studentInitialized = true;'
                '        }'
                '        studentBranchAvailable = event.Data.BranchAvailable === true;'
                '        document.getElementById("student-branch-unavailable").hidden = studentBranchAvailable;'
                '        document.getElementById("student-branch-tab").title = studentBranchAvailable ? "" : "Requires a current project tracked by Git and Git installed";'
                '        if (!studentBranchAvailable && studentMode === "branch") selectStudentMode("export");'
                '        updateStudentDestination();'
                '        setStudentBusy(false);'
                '    });'
                '    bridge.addEventListener("StudentFolder", event => {'
                '        document.getElementById("student-parent").value = event.Data.Parent;'
                '        updateStudentDestination();'
                '    });'
                '    bridge.addEventListener("StudentWorktreeFolder", event => {'
                '        document.getElementById("student-worktree-destination").value = event.Data.Destination;'
                '    });'
                '    bridge.addEventListener("StudentDetected", event => {'
                '        if (studentMode !== "export" || event.Data.Parent !== document.getElementById("student-parent").value.trim() || event.Data.FolderName !== document.getElementById("student-name").value.trim()) return;'
                '        studentOutput = event.Data.Output || "";'
                '        setStudentBusy(studentBusy);'
                '    });'
                '    bridge.addEventListener("StudentCreated", event => {'
                '        studentOutput = event.Data.Output;'
                '        studentLocalBranchCreated = event.Data.LocalBranch === true;'
                '        setStudentBusy(false);'
                '        document.getElementById("student-result").textContent = event.Data.Mode === "branch" ? "Created branch " + event.Data.BranchName + " at: " + studentOutput + ". Review and commit the student-file changes before sharing the branch." : "Created: " + studentOutput;'
                '        setStatus("Student version created.");'
                '    });'
                '    bridge.addEventListener("Error", event => {'
                '        pending = null;'
                '        document.getElementById("content").setAttribute("aria-busy", "false");'
                '        setStatus(event.Data.Message);'
                '        setStudentBusy(false);'
                '        if (currentPath === "student-version") document.getElementById("student-result").textContent = event.Data.Message;'
                '    });'
                '    document.getElementById("student").addEventListener("click", showStudentWorkflow);'
                '    const studentTabs = [document.getElementById("student-export-tab"), document.getElementById("student-branch-tab")];'
                '    studentTabs.forEach((tab, index) => {'
                '        tab.addEventListener("click", () => selectStudentMode(index === 0 ? "export" : "branch"));'
                '        tab.addEventListener("keydown", event => {'
                '            if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;'
                '            event.preventDefault();'
                '            const next = event.key === "Home" ? 0 : event.key === "End" ? 1 : 1 - index;'
                '            if (studentTabs[next].disabled) return;'
                '            selectStudentMode(next === 0 ? "export" : "branch");'
                '            studentTabs[next].focus();'
                '        });'
                '    });'
                '    document.getElementById("student-browse").addEventListener("click", () => bridge.sendEventToMATLAB("BrowseStudentFolder", {}));'
                '    document.getElementById("student-worktree-browse").addEventListener("click", () => bridge.sendEventToMATLAB("BrowseStudentWorktree", {}));'
                '    document.getElementById("student-use-worktree").addEventListener("change", updateStudentWorktree);'
                '    document.getElementById("student-branch-open").addEventListener("click", () => confirmStudentBranch(true));'
                '    document.getElementById("student-branch-confirm").addEventListener("click", () => confirmStudentBranch(false));'
                '    document.getElementById("student-branch-cancel").addEventListener("click", () => { document.getElementById("student-branch-dialog").close(); pendingStudentRequest = null; });'
                '    document.getElementById("student-branch-dialog").addEventListener("cancel", () => { pendingStudentRequest = null; });'
                '    document.getElementById("student-parent").addEventListener("input", updateStudentDestination);'
                '    document.getElementById("student-name").addEventListener("input", updateStudentDestination);'
                '    document.getElementById("student-form").addEventListener("submit", event => {'
                '        event.preventDefault();'
                '        const data = studentMode === "branch" ? { Mode: studentMode, BranchName: document.getElementById("student-branch-name").value, UseWorktree: document.getElementById("student-use-worktree").checked } : { Mode: studentMode, Parent: document.getElementById("student-parent").value, FolderName: document.getElementById("student-name").value };'
                '        if (studentMode === "branch" && data.UseWorktree) data.Destination = document.getElementById("student-worktree-destination").value;'
                '        if (studentMode === "branch") {'
                '            pendingStudentRequest = data;'
                '            document.getElementById("student-branch-dialog-message").textContent = data.UseWorktree ? "Create branch " + data.BranchName + " in a separate worktree. Opening the student project will switch MATLAB to that worktree; the original checkout stays unchanged." : "Create the student version in the current folder. When creation finishes, branch " + data.BranchName + " will be active and the source project will be closed.";'
                '            document.getElementById("student-branch-dialog-warning").hidden = data.UseWorktree;'
                '            document.getElementById("student-branch-dialog").showModal();'
                '        } else sendStudentCreation(data);'
                '    });'
                '    document.getElementById("student-open").addEventListener("click", () => bridge.sendEventToMATLAB("OpenStudentVersion", {}));'
                '    document.getElementById("home").addEventListener("click", () => navigate(catalog.Home));'
                '    document.getElementById("startup").addEventListener("click", () => bridge.sendEventToMATLAB("StartUp", {}));'
                '    document.getElementById("feedback").addEventListener("click", event => {'
                '        event.preventDefault();'
                '        bridge.sendEventToMATLAB("Feedback", {});'
                '    });'
                '    document.getElementById("content").addEventListener("click", event => {'
                '        const gif = event.target.closest("img.expandable-gif");'
                '        if (gif) { event.preventDefault(); openGif(gif); return; }'
                '        const link = event.target.closest("a");'
                '        if (!link) return;'
                '        event.preventDefault();'
                '        followLink(link.getAttribute("href"));'
                '    });'
                '    document.getElementById("content").addEventListener("keydown", event => {'
                '        if ((event.key === "Enter" || event.key === " ") && event.target.matches("img.expandable-gif")) {'
                '            event.preventDefault();'
                '            openGif(event.target);'
                '        }'
                '    });'
                '    document.getElementById("closeGif").addEventListener("click", closeGif);'
                '    document.addEventListener("keydown", event => {'
                '        if (document.getElementById("gifViewer").hidden) return;'
                '        if (event.key === "Escape") { event.preventDefault(); closeGif(); }'
                '        if (event.key === "Tab") { event.preventDefault(); document.getElementById("closeGif").focus(); }'
                '    });'
                '    document.getElementById("outline").addEventListener("click", event => {'
                '        const link = event.target.closest("a");'
                '        if (!link) return;'
                '        event.preventDefault();'
                '        scrollToAnchor(link.getAttribute("href").slice(1));'
                '        updateOutline();'
                '    });'
                '    let outlineFrame = 0;'
                '    document.getElementById("reader").addEventListener("scroll", () => {'
                '        if (outlineFrame) return;'
                '        outlineFrame = requestAnimationFrame(() => { outlineFrame = 0; updateOutline(); });'
                '    });'
                '    bridge.sendEventToMATLAB("Ready", {});'
                '};'
                ''
                'function setStatus(message) {'
                '    statusMessage = message || "";'
                '    hoveredLink = null;'
                '    focusedLink = null;'
                '    updateLinkStatus();'
                '}'
                ''
                'function updateLinkStatus() {'
                '    const link = [hoveredLink, focusedLink].find(item => item && item.isConnected && item.getAttribute("href") !== "#");'
                '    const target = link ? link.getAttribute("href") : "";'
                '    const footer = document.getElementById("status");'
                '    footer.textContent = target || statusMessage;'
                '    footer.title = target || statusMessage;'
                '}'
                ''
                'function fitPanels() {'
                '    const main = document.querySelector(".main");'
                '    const compact = window.matchMedia("(max-width: 640px)").matches;'
                '    const student = main.classList.contains("student-mode");'
                '    const available = Math.max(0, main.clientWidth - (student || compact ? 6 : 12));'
                '    const minimumSide = Math.min(120, available * 0.22);'
                '    const minimumReader = Math.min(360, available * 0.45);'
                '    const clamp = (value, min, max) => Math.max(min, Math.min(value, max));'
                '    const defaultSide = Math.min(270, (available - minimumReader) / 2);'
                '    const defaultLeft = compact ? 150 : student ? 270 : defaultSide;'
                '    const defaultRight = defaultSide;'
                '    const rightMax = available - minimumReader - minimumSide;'
                '    const right = compact || student ? 0 : clamp(panelSizes.right ?? defaultRight, minimumSide, rightMax);'
                '    const leftMax = available - minimumReader - right;'
                '    const left = clamp(panelSizes.left ?? defaultLeft, minimumSide, leftMax);'
                '    const outlineMin = Math.min(80, main.clientHeight * 0.3);'
                '    const outlineMax = Math.max(outlineMin, main.clientHeight - 166);'
                '    const outline = clamp(panelSizes.outline, outlineMin, outlineMax);'
                '    main.style.setProperty("--left-width", left + "px");'
                '    main.style.setProperty("--right-width", right + "px");'
                '    main.style.setProperty("--outline-height", outline + "px");'
                '    const update = (id, value, min, max) => {'
                '        const divider = document.getElementById(id);'
                '        divider.setAttribute("aria-valuenow", String(Math.round(value)));'
                '        divider.setAttribute("aria-valuemin", String(Math.round(min)));'
                '        divider.setAttribute("aria-valuemax", String(Math.round(max)));'
                '    };'
                '    update("left-divider", left, minimumSide, leftMax);'
                '    update("right-divider", compact ? outline : right, compact ? outlineMin : minimumSide, compact ? outlineMax : rightMax);'
                '    document.getElementById("right-divider").setAttribute("aria-orientation", compact ? "horizontal" : "vertical");'
                '}'
                ''
                'function setupPanelDividers() {'
                '    const main = document.querySelector(".main");'
                '    ["left", "right"].forEach(side => {'
                '        const divider = document.getElementById(side + "-divider");'
                '        let drag = null;'
                '        divider.addEventListener("pointerdown", event => {'
                '            if (event.button !== 0) return;'
                '            const horizontal = divider.getAttribute("aria-orientation") === "horizontal";'
                '            drag = { id: event.pointerId, horizontal, start: horizontal ? event.clientY : event.clientX, size: Number(divider.getAttribute("aria-valuenow")) };'
                '            divider.setPointerCapture(event.pointerId);'
                '            divider.classList.add("dragging");'
                '            document.body.classList.add("resizing-panels");'
                '            if (horizontal) document.body.classList.add("resizing-rows");'
                '            event.preventDefault();'
                '        });'
                '        divider.addEventListener("pointermove", event => {'
                '            if (!drag || event.pointerId !== drag.id) return;'
                '            const delta = (drag.horizontal ? event.clientY : event.clientX) - drag.start;'
                '            panelSizes[drag.horizontal ? "outline" : side] = drag.size + (side === "left" ? delta : -delta);'
                '            fitPanels();'
                '        });'
                '        const finish = () => {'
                '            drag = null;'
                '            divider.classList.remove("dragging");'
                '            document.body.classList.remove("resizing-panels", "resizing-rows");'
                '        };'
                '        ["pointerup", "pointercancel", "lostpointercapture"].forEach(name => divider.addEventListener(name, finish));'
                '        divider.addEventListener("keydown", event => {'
                '            const horizontal = divider.getAttribute("aria-orientation") === "horizontal";'
                '            const decrease = horizontal ? "ArrowDown" : side === "left" ? "ArrowLeft" : "ArrowRight";'
                '            const increase = horizontal ? "ArrowUp" : side === "left" ? "ArrowRight" : "ArrowLeft";'
                '            if (event.key !== decrease && event.key !== increase) return;'
                '            panelSizes[horizontal ? "outline" : side] = Number(divider.getAttribute("aria-valuenow")) + (event.key === increase ? 20 : -20);'
                '            fitPanels();'
                '            event.preventDefault();'
                '        });'
                '    });'
                '    new ResizeObserver(fitPanels).observe(main);'
                '    fitPanels();'
                '}'
                ''
                'function setStudentBusy(busy) {'
                '    studentBusy = busy;'
                '    const locked = busy || studentLocalBranchCreated;'
                '    const worktree = studentMode === "branch" && document.getElementById("student-use-worktree").checked;'
                '    ["student-parent", "student-name", "student-browse"].forEach(id => { document.getElementById(id).disabled = locked || studentMode !== "export"; });'
                '    ["student-create", "student-export-tab"].forEach(id => { document.getElementById(id).disabled = locked; });'
                '    document.getElementById("student-branch-tab").disabled = locked || !studentBranchAvailable;'
                '    ["student-branch-name", "student-use-worktree"].forEach(id => { document.getElementById(id).disabled = locked || studentMode !== "branch"; });'
                '    ["student-worktree-destination", "student-worktree-browse"].forEach(id => { document.getElementById(id).disabled = locked || !worktree; });'
                '    if (studentLocalBranchCreated) document.querySelectorAll(".page-sidebar button").forEach(button => { button.disabled = true; });'
                '    document.getElementById("student-open").disabled = busy || !studentOutput;'
                '    document.getElementById("student-open").hidden = studentMode !== "export" || !studentOutput;'
                '    document.getElementById("student-form").setAttribute("aria-busy", String(busy));'
                '}'
                ''
                'function selectStudentMode(mode) {'
                '    if (studentLocalBranchCreated) return;'
                '    if (mode === "branch" && !studentBranchAvailable) return;'
                '    studentMode = mode;'
                '    ["export", "branch"].forEach(value => {'
                '        const selected = value === mode;'
                '        const tab = document.getElementById("student-" + value + "-tab");'
                '        tab.setAttribute("aria-selected", String(selected));'
                '        tab.tabIndex = selected ? 0 : -1;'
                '        document.getElementById("student-" + value + "-panel").hidden = !selected;'
                '    });'
                '    document.getElementById("student-branch-name").required = mode === "branch";'
                '    updateStudentWorktree();'
                '    if (mode === "export") updateStudentDestination();'
                '}'
                ''
                'function confirmStudentBranch(openAfterCreate) {'
                '    if (!pendingStudentRequest) return;'
                '    const data = { ...pendingStudentRequest, OpenAfterCreate: openAfterCreate };'
                '    pendingStudentRequest = null;'
                '    document.getElementById("student-branch-dialog").close();'
                '    sendStudentCreation(data);'
                '}'
                ''
                'function sendStudentCreation(data) {'
                '    clearTimeout(studentDetectionTimer);'
                '    setStudentBusy(true);'
                '    document.getElementById("student-result").textContent = "Creating student version...";'
                '    bridge.sendEventToMATLAB("CreateStudentVersion", data);'
                '}'
                ''
                'function updateStudentWorktree() {'
                '    const worktree = studentMode === "branch" && document.getElementById("student-use-worktree").checked;'
                '    document.getElementById("student-worktree-fields").hidden = !worktree;'
                '    document.getElementById("student-worktree-destination").required = worktree;'
                '    document.getElementById("student-local-note").hidden = worktree;'
                '    document.getElementById("student-worktree-note").hidden = !worktree;'
                '    setStudentBusy(false);'
                '}'
                ''
                'function updateStudentDestination() {'
                '    const parent = document.getElementById("student-parent").value.trim();'
                '    const name = document.getElementById("student-name").value.trim();'
                '    const separator = parent.includes("\\") ? "\\" : "/";'
                '    document.getElementById("student-destination").textContent = parent.replace(/[\\/]+$/, "") + separator + name;'
                '    clearTimeout(studentDetectionTimer);'
                '    if (studentMode !== "export") return;'
                '    studentOutput = "";'
                '    setStudentBusy(studentBusy);'
                '    if (parent && name) studentDetectionTimer = setTimeout(() => bridge.sendEventToMATLAB("DetectStudentVersion", { Parent: parent, FolderName: name }), 250);'
                '}'
                ''
                'function showStudentWorkflow() {'
                '    closeGif();'
                '    pending = null;'
                '    currentPath = "student-version";'
                '    document.querySelector(".main").classList.add("student-mode");'
                '    document.querySelector(".outline-sidebar").hidden = true;'
                '    document.getElementById("right-divider").hidden = true;'
                '    fitPanels();'
                '    document.getElementById("content").hidden = true;'
                '    document.getElementById("path").hidden = true;'
                '    document.getElementById("student-workflow").hidden = false;'
                '    document.getElementById("reader").scrollTop = 0;'
                '    renderPageList();'
                '    renderOutline();'
                '    updateOutline();'
                '    setStatus("");'
                '    bridge.sendEventToMATLAB("Rendered", { Path: currentPath });'
                '    bridge.sendEventToMATLAB("StudentVersion", {});'
                '}'
                ''
                'function prepareGifImages() {'
                '    document.querySelectorAll("#content img").forEach(image => {'
                '        if (!/\.gif(?:[?#]|$)|^data:image\/gif;/i.test(image.getAttribute("src") || "")) return;'
                '        image.classList.add("expandable-gif");'
                '        image.tabIndex = 0;'
                '        image.setAttribute("role", "button");'
                '        image.setAttribute("aria-label", "Expand animation");'
                '        image.title = "Click to expand animation";'
                '    });'
                '}'
                ''
                'function openGif(image) {'
                '    gifReturnFocus = image;'
                '    const expanded = document.getElementById("expandedGif");'
                '    expanded.src = image.src;'
                '    expanded.alt = image.alt;'
                '    document.getElementById("gifViewer").hidden = false;'
                '    document.body.classList.add("viewing-gif");'
                '    document.querySelector(".app").setAttribute("aria-hidden", "true");'
                '    document.getElementById("closeGif").focus();'
                '}'
                ''
                'function closeGif() {'
                '    if (document.getElementById("gifViewer").hidden) return;'
                '    document.getElementById("gifViewer").hidden = true;'
                '    document.getElementById("expandedGif").removeAttribute("src");'
                '    document.body.classList.remove("viewing-gif");'
                '    document.querySelector(".app").removeAttribute("aria-hidden");'
                '    if (gifReturnFocus && document.body.contains(gifReturnFocus)) gifReturnFocus.focus();'
                '    gifReturnFocus = null;'
                '}'
                ''
                'function renderPageList() {'
                '    const list = document.getElementById("pages");'
                '    list.innerHTML = "";'
                '    catalog.Pages.forEach(page => {'
                '        const button = document.createElement("button");'
                '        button.type = "button";'
                '        button.textContent = page.Title;'
                '        button.title = page.Path;'
                '        if (page.Path === currentPath) button.setAttribute("aria-current", "page");'
                '        button.addEventListener("click", () => navigate(page.Path));'
                '        list.appendChild(button);'
                '    });'
                '    const student = document.getElementById("student");'
                '    if (currentPath === "student-version") student.setAttribute("aria-current", "page"); else student.removeAttribute("aria-current");'
                '    if (!list.childElementCount) list.textContent = "No documentation pages.";'
                '    fitPanels();'
                '}'
                ''
                'function renderOutline() {'
                '    const outline = document.getElementById("outline");'
                '    outline.innerHTML = "";'
                '    const article = document.getElementById(currentPath === "student-version" ? "student-workflow" : "content");'
                '    const headings = Array.from(article.querySelectorAll("h2, h3, h4, h5, h6"));'
                '    if (!headings.length) headings.push(...article.querySelectorAll("h1"));'
                '    headings.forEach((heading, index) => {'
                '        if (!heading.id) heading.id = "student-section-" + index;'
                '        const link = document.createElement("a");'
                '        link.href = "#" + heading.id;'
                '        link.className = "depth-" + heading.tagName.slice(1);'
                '        link.textContent = heading.textContent;'
                '        outline.appendChild(link);'
                '    });'
                '    if (!headings.length) outline.textContent = "No sections on this page.";'
                '    fitPanels();'
                '}'
                ''
                'function updateOutline() {'
                '    const links = Array.from(document.querySelectorAll("#outline a"));'
                '    if (!links.length) return;'
                '    const reader = document.getElementById("reader");'
                '    const top = reader.getBoundingClientRect().top + 32;'
                '    let active = links[0];'
                '    links.forEach(link => {'
                '        const heading = document.getElementById(link.getAttribute("href").slice(1));'
                '        if (heading && heading.getBoundingClientRect().top <= top) active = link;'
                '        link.removeAttribute("aria-current");'
                '    });'
                '    active.setAttribute("aria-current", "location");'
                '}'
                ''
                'function navigate(path, anchor = "") {'
                '    pending = { Path: path, Anchor: anchor };'
                '    document.getElementById("content").setAttribute("aria-busy", "true");'
                '    setStatus("Loading…");'
                '    bridge.sendEventToMATLAB("Open", { Path: path });'
                '}'
                ''
                'function scrollToAnchor(anchor) {'
                '    const target = document.getElementById(anchor);'
                '    const article = document.getElementById(currentPath === "student-version" ? "student-workflow" : "content");'
                '    if (target && article.contains(target)) target.scrollIntoView();'
                '}'
                ''
                'function followLink(href) {'
                '    if (href === "#student-version") { showStudentWorkflow(); return; }'
                '    if (/^https?:\/\//i.test(href)) {'
                '        bridge.sendEventToMATLAB("Web", { URL: href });'
                '        return;'
                '    }'
                '    try {'
                '        const target = new URL(href.replace(/\\/g, "/"), "https://courseware.local/" + currentPath);'
                '        if (target.origin !== "https://courseware.local") throw new Error("This link is unavailable in the documentation reader.");'
                '        const path = decodeURIComponent(target.pathname.slice(1));'
                '        const anchor = decodeURIComponent(target.hash.slice(1));'
                '        if (/\.m$/i.test(path)) openScript(path);'
                '        else if (/\.md$/i.test(path)) navigate(path, anchor);'
                '        else setStatus("This link does not point to a Markdown page or MATLAB script.");'
                '    } catch (error) { setStatus(error.message); }'
                '}'
                ''
                'function openScript(path) { bridge.sendEventToMATLAB("Open", { Path: path }); }'
                ''
                'function escapeHTML(text) {'
                '    return String(text).replace(/[&<>"'']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", ''"'': "&quot;", "''": "&#39;" })[char]);'
                '}'
                ''
                'function safeImage(src, alt, width) {'
                '    if (/^asset-\d+$/.test(src)) return ''<img data-asset="'' + escapeHTML(src) + ''" alt="'' + escapeHTML(alt) + ''"'' + (/^\d+$/.test(width || '''') ? '' width="'' + width + ''"'' : '''') + ''>'';'
                '    if (/^(?!data:image\/)[a-z][a-z0-9+.-]*:/i.test(src) && !/^https?:/i.test(src)) return escapeHTML(alt);'
                '    if (/^data:/i.test(src) && !/^data:image\/(png|gif|jpeg|svg\+xml);base64,/i.test(src)) return escapeHTML(alt);'
                '    return ''<img src="'' + escapeHTML(src) + ''" alt="'' + escapeHTML(alt) + ''"'' + (/^\d+$/.test(width || "") ? '' width="'' + width + ''"'' : "") + ''>'';'
                '}'
                ''
                'function inlineMarkdown(text, tokens = []) {'
                '    const save = html => { tokens.push(html); return "\uE000" + (tokens.length - 1) + "\uE001"; };'
                '    const restore = html => {'
                '        for (let count = 0; count <= tokens.length; count++) {'
                '            const next = html.replace(/\uE000(\d+)\uE001/g, (_, index) => tokens[Number(index)]);'
                '            if (next === html) break;'
                '            html = next;'
                '        }'
                '        return html;'
                '    };'
                '    let value = String(text);'
                '    value = value.replace(/`([^`]+)`/g, (_, code) => save("<code>" + escapeHTML(code) + "</code>"));'
                '    value = value.replace(/\\([\\`*{}\[\]()#+\-.!_>])/g, (_, char) => save(escapeHTML(char)));'
                '    value = value.replace(/<img\b[^>]*>/gi, tag => {'
                '        const attribute = name => { const found = tag.match(new RegExp("\\b" + name + "=[\"'']([^\"'']*)[\"'']", "i")); return found ? found[1] : ""; };'
                '        return save(safeImage(attribute("src"), attribute("alt"), attribute("width")));'
                '    });'
                '    value = value.replace(/<br\s*\/?\s*>/gi, () => save("<br>"));'
                '    value = value.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (_, alt, src) => save(safeImage(src.trim().replace(/^<|>$/g, ""), alt, "")));'
                '    value = value.replace(/\[([^\]]*)\]\(([^)]+)\)/g, (_, label, href) => save(''<a href="'' + escapeHTML(href.trim().replace(/^<|>$/g, "")) + ''">'' + inlineMarkdown(label, tokens) + ''</a>''));'
                '    value = value.replace(/<(https?:\/\/[^>]+)>/g, (_, href) => save(''<a href="'' + escapeHTML(href) + ''">'' + escapeHTML(href) + ''</a>''));'
                '    value = escapeHTML(value);'
                '    value = value.replace(/\*\*([^*]+)\*\*/g, ''<strong>$1</strong>'').replace(/__([^_]+)__/g, ''<strong>$1</strong>'');'
                '    value = value.replace(/\*([^*]+)\*/g, ''<em>$1</em>'').replace(/(^|\s)_([^_]+)_(?=\s|$|[.,])/g, ''$1<em>$2</em>'');'
                '    value = value.replace(/~~([^~]+)~~/g, ''<del>$1</del>'');'
                '    return restore(value);'
                '}'
                ''
                'function tableCells(line) {'
                '    if (!line || !line.includes("|")) return null;'
                '    const content = line.trim().replace(/^\|/, "").replace(/\|$/, "");'
                '    const cells = [];'
                '    let cell = "";'
                '    for (let index = 0; index < content.length; index++) {'
                '        if (content[index] === "|" && content[index - 1] !== "\\") {'
                '            cells.push(cell.trim()); cell = "";'
                '        } else cell += content[index];'
                '    }'
                '    cells.push(cell.trim());'
                '    return cells;'
                '}'
                ''
                'function renderMarkdown(markdown) {'
                '    const lines = String(markdown || "").replace(/\r\n?/g, "\n").split("\n");'
                '    const fragment = document.createDocumentFragment();'
                '    const slugs = new Map();'
                '    let index = 0;'
                '    const append = (tag, text, parent = fragment) => {'
                '        const node = document.createElement(tag);'
                '        node.innerHTML = inlineMarkdown(text);'
                '        parent.appendChild(node);'
                '        return node;'
                '    };'
                '    const isList = line => /^(\s*)([-+*]|\d+[.)])\s+(.+)$/.exec(line);'
                '    while (index < lines.length) {'
                '        const line = lines[index];'
                '        const trimmed = line.trim();'
                '        if (!trimmed || /^<!--/.test(trimmed)) { index++; continue; }'
                '        const fence = /^(?:```|~~~)(.*)$/.exec(trimmed);'
                '        if (fence || /^<pre>$/i.test(trimmed)) {'
                '            const closing = fence ? trimmed.slice(0, 3) : "</pre>";'
                '            const codeLines = [];'
                '            index++;'
                '            while (index < lines.length && !lines[index].trim().startsWith(closing)) codeLines.push(lines[index++]);'
                '            index++;'
                '            const pre = document.createElement("pre");'
                '            const code = document.createElement("code");'
                '            code.textContent = codeLines.join("\n");'
                '            if (fence) code.className = "language-" + fence[1].trim();'
                '            pre.appendChild(code);'
                '            fragment.appendChild(pre);'
                '            continue;'
                '        }'
                '        const heading = /^(#{1,6})\s+(.+?)\s*#*\s*$/.exec(trimmed);'
                '        if (heading) {'
                '            const node = append("h" + heading[1].length, heading[2]);'
                '            const base = node.textContent.toLowerCase().replace(/[^a-z0-9_\- \u0080-\uFFFF]/g, "").replace(/ /g, "-");'
                '            const count = slugs.get(base) || 0;'
                '            slugs.set(base, count + 1);'
                '            node.id = base + (count ? "-" + count : "");'
                '            index++;'
                '            continue;'
                '        }'
                '        const headers = tableCells(line);'
                '        const delimiters = tableCells(lines[index + 1]);'
                '        if (headers && delimiters && headers.length === delimiters.length && delimiters.every(cell => /^:?-{2,}:?$/.test(cell))) {'
                '            const wrap = document.createElement("div");'
                '            wrap.className = "table-wrap";'
                '            const table = document.createElement("table");'
                '            const head = document.createElement("thead");'
                '            const headRow = document.createElement("tr");'
                '            headers.forEach(text => { const cell = append("th", text, headRow); cell.scope = "col"; });'
                '            head.appendChild(headRow);'
                '            table.appendChild(head);'
                '            const body = document.createElement("tbody");'
                '            index += 2;'
                '            while (index < lines.length) {'
                '                const cells = tableCells(lines[index]);'
                '                if (!cells || cells.length !== headers.length) break;'
                '                const row = document.createElement("tr");'
                '                cells.forEach((text, column) => {'
                '                    const cell = append("td", text, row);'
                '                    const delimiter = delimiters[column];'
                '                    if (delimiter.endsWith(":")) cell.style.textAlign = delimiter.startsWith(":") ? "center" : "right";'
                '                });'
                '                body.appendChild(row);'
                '                index++;'
                '            }'
                '            table.appendChild(body);'
                '            wrap.appendChild(table);'
                '            fragment.appendChild(wrap);'
                '            continue;'
                '        }'
                '        if (isList(line)) {'
                '            const stack = [];'
                '            while (index < lines.length) {'
                '                const item = isList(lines[index]);'
                '                if (!item) {'
                '                    if (!lines[index].trim() && isList(lines[index + 1] || "")) { index++; continue; }'
                '                    break;'
                '                }'
                '                const indent = item[1].length;'
                '                const type = /^\d/.test(item[2]) ? "ol" : "ul";'
                '                while (stack.length && stack[stack.length - 1].Indent > indent) stack.pop();'
                '                if (stack.length && stack[stack.length - 1].Indent === indent && stack[stack.length - 1].Type !== type) stack.pop();'
                '                if (!stack.length || stack[stack.length - 1].Indent < indent) {'
                '                    const list = document.createElement(type);'
                '                    if (type === "ol") list.start = parseInt(item[2], 10);'
                '                    const parent = stack.length ? stack[stack.length - 1].List.lastElementChild : fragment;'
                '                    parent.appendChild(list);'
                '                    stack.push({ Indent: indent, Type: type, List: list });'
                '                }'
                '                append("li", item[3], stack[stack.length - 1].List);'
                '                index++;'
                '            }'
                '            continue;'
                '        }'
                '        if (/^>\s?/.test(trimmed)) {'
                '            const quote = [];'
                '            while (index < lines.length && /^>\s?/.test(lines[index].trim())) quote.push(lines[index++].trim().replace(/^>\s?/, ""));'
                '            const block = document.createElement("blockquote");'
                '            block.appendChild(renderMarkdown(quote.join("\n")));'
                '            fragment.appendChild(block);'
                '            continue;'
                '        }'
                '        if (/^(\*\s*){3,}$|^(-\s*){3,}$|^(_\s*){3,}$/.test(trimmed)) {'
                '            fragment.appendChild(document.createElement("hr")); index++; continue;'
                '        }'
                '        const paragraph = [trimmed];'
                '        index++;'
                '        while (index < lines.length && lines[index].trim() && !/^(#{1,6}\s|```|~~~|<pre>|>)/.test(lines[index].trim()) && !isList(lines[index])) {'
                '            if (tableCells(lines[index]) && tableCells(lines[index + 1])) break;'
                '            paragraph.push(lines[index++].trim());'
                '        }'
                '        append("p", paragraph.join(" "));'
                '    }'
                '    return fragment;'
                '}'
                '</script>'
                '</body>'
                '</html>'
            };
            source = strjoin(lines,newline);
        end

        function excluded = isExcluded(relative)
            %isExcluded - Hide solution, helper, and image directories
            parts = split(replace(string(relative),'\','/'),'/');
            excluded = any(ismember(lower(parts), ...
                ["solutions","helperfunctions","images"]));
        end

        function value = textField(data,name)
            %textField - Validate strings received from the HTML bridge
            if ~isstruct(data) || ~isscalar(data) || ~isfield(data,name)
                error('InstructorResources:InvalidRequest','Invalid navigation request.');
            end
            raw = data.(name);
            if ~((ischar(raw) && isrow(raw)) || (isstring(raw) && isscalar(raw)))
                error('InstructorResources:InvalidRequest','Invalid navigation request.');
            end
            value = string(raw);
            if ismissing(value) || strlength(value) == 0 || strlength(value) > 4096
                error('InstructorResources:InvalidRequest','Invalid navigation request.');
            end
        end
    end
end
