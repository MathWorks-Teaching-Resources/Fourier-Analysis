classdef ProjectStartupApp < matlab.apps.AppBase
    % ProjectStartupApp Native courseware landing page with inline HTML.

    properties (Access = public)
        StartUpAppUIFigure matlab.ui.Figure
        Panel matlab.ui.container.Panel
        GridLayout matlab.ui.container.GridLayout
        Header matlab.ui.container.GridLayout
        Upper matlab.ui.container.GridLayout
        Lower matlab.ui.container.GridLayout
        HTML matlab.ui.control.HTML
        HTML2 matlab.ui.control.HTML
        HTML3 matlab.ui.control.HTML
        HTML4 matlab.ui.control.HTML
        HTML5 matlab.ui.control.HTML
        TeamLogo matlab.ui.control.Image
        ContactLink matlab.ui.control.Button
        Image2 matlab.ui.control.Image
        ImageFallback matlab.ui.control.Label
        MainMenuButton matlab.ui.control.Button
        READMEButton matlab.ui.control.Button
        InstructorButton matlab.ui.control.Button
        ReviewUsButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label
    end

    % Properties to be modified
    properties (Access = private)
        GitHubOrganization = "MathWorks-Teaching-Resources";
        GitHubRepository = "Fourier-Analysis";
        ImagePath = fullfile("Images","image_7.png");
        HideInstructorResources = false;
    end

    properties (Access = private)
        RootFolder string
        ProjectName string
        ProjectSummary string = ""
    end

    methods (Access = private, Static)
        function html = snippet(content,reportHeight)
            % Inline documents resize their content without supporting files.
            if nargin < 2
                reportHeight = false;
            end
            fitGuard = "";
            if reportHeight
                fitGuard = "return;";
            end
            padding = "8px";
            if contains(content,'class="brand"')
                padding = "0";
            end
            html = string('<!doctype html><html lang="en"><head><meta charset="utf-8">') + ...
                string('<meta name="viewport" content="width=device-width,initial-scale=1">') + ...
                string('<style>:root{--text:#172b3d;--muted:#526577;--accent:#0076a8;}') + ...
                string('*{box-sizing:border-box}html,body{width:100%;height:100%;overflow:hidden}body{margin:0;padding:0;') + ...
                string('font-family:"Segoe UI",Arial,sans-serif;font-size:14px;color:var(--text);line-height:1.5}') + ...
                string('h1{font-size:clamp(24px,5vw,32px);font-weight:700;line-height:1.2;') + ...
                string('margin:10px 0 16px;overflow-wrap:anywhere}h2{font-size:20px;margin:8px 0}') + ...
                string('h3{font-size:18px;font-weight:700;line-height:1.3;margin:8px 0}p{margin:8px 0;color:var(--muted);font-size:14px}') + ...
                string('.eyebrow{font-size:18px;font-weight:700;line-height:1.3;letter-spacing:0;color:var(--accent)}') + ...
                string('.caption{font-size:12px}.brand{font-size:20px;font-weight:700;line-height:1.3;white-space:nowrap}') + ...
                string('</style></head><body><div id="content" style="padding:') + ...
                padding + string(';transform-origin:top left">') + ...
                content + string('</div><script>const content=document.getElementById("content");') + ...
                string('function fit(){') + fitGuard + ...
                string('const w=document.documentElement.clientWidth,h=document.documentElement.clientHeight;') + ...
                string('if(!w||!h)return;let scale=1;content.style.transform="none";') + ...
                string('for(let i=0;i<20;i++){content.style.width=(w/scale)+"px";') + ...
                string('const next=Math.min(1,h/content.scrollHeight,w/content.scrollWidth);') + ...
                string('if(next>=scale-0.001)break;scale=next;}') + ...
                string('content.style.transform="scale("+scale+")";}') + ...
                string('new ResizeObserver(()=>requestAnimationFrame(fit)).observe(document.documentElement);') + ...
                'window.addEventListener("load",fit);fit();</script></body></html>';
            if reportHeight
                html = replace(html,'</body>', ...
                    string('<script>function setup(component){function report(){') + ...
                    'component.Data=Math.ceil(document.getElementById("content").scrollHeight);}' + ...
                    'new ResizeObserver(report).observe(document.getElementById("content"));' + ...
                    'report();}</script></body>');
            end
        end

        function text = escapeHTML(text)
            text = replace(string(text),'&','&amp;');
            text = replace(text,'<','&lt;');
            text = replace(text,'>','&gt;');
            text = replace(text,'"','&quot;');
        end
    end

    methods (Access = private)
        function alignNativeTypography(app)
            % Match native controls to the inline HTML typography.
            controls = findall(app.StartUpAppUIFigure,'-property','FontName');
            for index = 1:numel(controls)
                controls(index).FontName = 'Segoe UI';
                if isprop(controls(index),'FontColor')
                    if ~isequal(controls(index).FontColor,[1 1 1])
                        controls(index).FontColor = [23 43 61]/255;
                    end
                end
                if isa(controls(index),'matlab.ui.control.Hyperlink')
                    controls(index).FontColor = [0 118 168]/255;
                end
            end
            app.StatusLabel.FontColor = [82 101 119]/255;
        end

        function createCompatibilityComponents(app,preview)
            app.RootFolder = string(fileparts(fileparts(mfilename('fullpath'))));
            app.StartUpAppUIFigure = uifigure('Name','Courseware compatibility', ...
                'Position',[100 100 800 540],'Color',[0.97 0.98 0.99]);
            app.StartUpAppUIFigure.CloseRequestFcn = @(~,~) delete(app);
            root = uigridlayout(app.StartUpAppUIFigure,[2 1]);
            root.RowHeight = {62,'1x'};
            root.Padding = [0 0 0 0];
            root.RowSpacing = 0;
            root.BackgroundColor = [0.97 0.98 0.99];
            app.Header = uigridlayout(root,[1 2]);
            app.Header.Layout.Row = 1;
            app.Header.ColumnWidth = {64,'1x'};
            app.Header.Padding = [12 0 12 0];
            app.Header.BackgroundColor = [1 1 1];
            app.TeamLogo = uiimage(app.Header,'ScaleMethod','fit', ...
                'ImageSource',fullfile(app.RootFolder,'Images','TeachingResourcesLogo.png'), ...
                'BackgroundColor',app.Header.BackgroundColor);
            app.TeamLogo.Layout.Column = 1;
            brandGrid = uigridlayout(app.Header,[2 1]);
            brandGrid.Layout.Column = 2;
            brandGrid.RowHeight = {26,18};
            brandGrid.Padding = [0 9 0 9];
            brandGrid.RowSpacing = 0;
            brandGrid.BackgroundColor = app.Header.BackgroundColor;
            brand = uilabel(brandGrid,'Text','MathWorks Teaching Resources', ...
                'FontSize',20,'FontWeight','bold','FontColor',[0.09 0.17 0.24]);
            brand.Layout.Row = 1;
            aboutLink = uihyperlink(brandGrid,'Text','About Us','FontSize',12, ...
                'HorizontalAlignment','left', ...
                'URL','https://www.mathworks.com/matlabcentral/profile/authors/37969341');
            aboutLink.Layout.Row = 2;
            repositoryConfigured = strlength(strtrim(app.GitHubOrganization)) > 0 && ...
                strlength(strtrim(app.GitHubRepository)) > 0 && ...
                ~strcmpi(strtrim(app.GitHubOrganization),"XXXX") && ...
                ~strcmpi(strtrim(app.GitHubRepository),"XXXX");
            grid = uigridlayout(root,[4 + repositoryConfigured 1]);
            grid.Layout.Row = 2;
            grid.RowHeight = [{'fit','1x'},repmat({64},1,1 + repositoryConfigured),{'fit'}];
            grid.Padding = [24 16 24 16];
            grid.RowSpacing = 10;
            grid.BackgroundColor = root.BackgroundColor;
            heading = uilabel(grid,'Text','Choose how to open this courseware', ...
                'FontSize',24,'FontWeight','bold','WordWrap','on', ...
                'FontColor',[0.09 0.17 0.24]);
            heading.Layout.Row = 1;
            release = version('-release');
            if preview
                release = '2024b';
            end
            message = uilabel(grid,'Text', ...
                ['You are using MATLAB R' release '. This courseware uses ' ...
                'plain-text Live Scripts, which require R2025a or newer for the best viewing experience. ' ...
                'We have some great options to help you explore this content:'], ...
                'WordWrap','on','FontSize',14,'FontColor',[0.32 0.40 0.47]);
            message.Layout.Row = 2;
            nextRow = 3;
            if repositoryConfigured
                online = uibutton(grid,'Text', ...
                    {'MATLAB Online','Open this courseware in MATLAB Online with just one click!'}, ...
                    'FontSize',14,'FontWeight','bold', ...
                    'BackgroundColor',[0 0.46 0.66],'FontColor',[1 1 1], ...
                    'ButtonPushedFcn',@(~,~) app.openCompatibilityResource("online"));
                online.Layout.Row = nextRow;
                nextRow = nextRow + 1;
            end
            latest = uibutton(grid,'Text', ...
                {'Upgrade MATLAB','Download the latest version for the full courseware experience.'}, ...
                'FontSize',14,'FontWeight','bold','BackgroundColor',[1 1 1],'FontColor',[0.09 0.17 0.24], ...
                'ButtonPushedFcn',@(~,~) app.openCompatibilityResource("latest"));
            latest.Layout.Row = nextRow;
            app.StatusLabel = uilabel(grid,'Text','','WordWrap','on', ...
                'FontSize',12,'FontColor',[0.32 0.40 0.47]);
            app.StatusLabel.Layout.Row = nextRow + 1;
            app.alignNativeTypography()
            message.FontColor = [82 101 119]/255;
            drawnow
            if ~isvalid(app) || ~isvalid(grid)
                return
            end
            if repositoryConfigured
                if ~preview
                    app.openCompatibilityResource("online")
                end
                repository = app.GitHubOrganization + "/" + app.GitHubRepository;
                try
                    options = weboptions('Timeout',3,'ContentType','json');
                    releaseInfo = webread(char("https://api.github.com/repos/" + ...
                        repository + "/releases/tags/mlx"),options);
                    hasLegacyRelease = isstruct(releaseInfo) && isscalar(releaseInfo) && ...
                        isfield(releaseInfo,'tag_name') && strcmp(releaseInfo.tag_name,'mlx') && ...
                        isfield(releaseInfo,'draft') && isequal(releaseInfo.draft,false);
                catch
                    % Unconfirmed releases do not offer a download option.
                    hasLegacyRelease = false;
                end
                if hasLegacyRelease && isvalid(app) && isvalid(grid)
                    grid.RowHeight = {'fit','1x',64,64,64,'fit'};
                    latest.Layout.Row = 5;
                    app.StatusLabel.Layout.Row = 6;
                    legacy = uibutton(grid,'Text', ...
                        {'Download legacy version','We saved a version with MLX Live Scripts on GitHub for your current MATLAB.'}, ...
                        'FontName','Segoe UI','FontSize',14,'FontWeight','bold', ...
                        'BackgroundColor',[1 1 1],'FontColor',[23 43 61]/255, ...
                        'ButtonPushedFcn',@(~,~) app.openCompatibilityResource("legacy"));
                    legacy.Layout.Row = 4;
                end
            end
        end

        function openCompatibilityResource(app,action)
            repository = app.GitHubOrganization + "/" + app.GitHubRepository;
            switch action
                case "online"
                    url = "https://matlab.mathworks.com/open/github/v1?repo=" + repository;
                    projects = dir(fullfile(app.RootFolder,'*.prj'));
                    if isscalar(projects)
                        url = url + "&project=" + string(matlab.net.URI.encode(projects.name));
                    end
                case "legacy"
                    url = "https://github.com/" + repository + "/releases/tag/mlx";
                case "latest"
                    url = "https://www.mathworks.com/downloads/";
            end
            try
                status = web(char(url),'-browser');
                if status ~= 0
                    error('ProjectStartupApp:Browser','The browser could not open. Please try again.')
                end
                app.StatusLabel.Text = 'Opened in your browser.';
            catch exception
                app.StatusLabel.Text = exception.message;
            end
        end

        function startupFcn(app)
            app.RootFolder = string(fileparts(fileparts(mfilename('fullpath'))));
            app.ProjectName = "Courseware Module";
            try
                project = currentProject();
                if string(project.RootFolder) == app.RootFolder
                    app.ProjectName = string(project.Name);
                    app.ProjectSummary = string(project.Description);
                end
            catch
                % Direct launch also works before opening the project.
            end
            title = app.escapeHTML(app.ProjectName);
            summary = app.escapeHTML(app.ProjectSummary);
            app.HTML4.HTMLSource = app.snippet('<div class="brand">MathWorks Teaching Resources</div>');
            app.HTML5.HTMLSource = app.snippet(string('<h1>') + title + ...
                '</h1><p style="white-space:pre-wrap">' + summary + '</p>',true);
            app.HTML.HTMLSource = app.snippet(string('<p class="eyebrow">LEARN</p>') + ...
                '<h3>For students</h3><p>Read the overview, prerequisites, and tips for getting started.</p>');
            if ~app.HideInstructorResources
                app.HTML2.HTMLSource = app.snippet(string('<p class="eyebrow">TEACH</p>') + ...
                    '<h3>For instructors</h3><p>Find guidance and resources for adapting and teaching with this module.</p>');
            end
            app.HTML3.HTMLSource = app.snippet(string('<p class="eyebrow">IMPROVE</p>') + ...
                '<h3>Help shape what&#8217;s next</h3><p>Tell us what worked and what could make your experience better.</p>');
            imageFile = fullfile(app.RootFolder,app.ImagePath);
            if isfile(imageFile)
                try
                    app.Image2.ImageSource = imageFile;
                    app.ImageFallback.Visible = 'off';
                    app.Image2.Visible = 'on';
                catch
                    app.showStatus('The cover image could not be loaded. Course materials are still available.')
                end
            end
            app.StartUpAppUIFigure.Visible = 'on';
        end

        function showStatus(app,message)
            app.StatusLabel.Text = message;
            if strlength(string(message)) > 0
                app.StatusLabel.Parent.RowHeight{3} = 'fit';
            else
                app.StatusLabel.Parent.RowHeight{3} = 0;
            end
        end

        function navigate(app,action)
            try
                switch action
                    case "resources"
                        status = web('https://github.com/MathWorks-Teaching-Resources','-browser');
                        if status ~= 0
                            error('ProjectStartupApp:Browser','The browser could not open. Please try again.')
                        end
                    case "contact"
                        status = web('https://www.mathworks.com/matlabcentral/profile/authors/37969341','-browser');
                        if status ~= 0
                            error('ProjectStartupApp:Browser','The browser could not open. Please try again.')
                        end
                    case "feedback"
                        app.openFeedback()
                    case "instructor"
                        if app.HideInstructorResources
                            error('ProjectStartupApp:UnavailableAction','Instructor resources are unavailable in this app.')
                        end
                        folder = fullfile(app.RootFolder,'InstructorResources');
                        if ~isfolder(folder)
                            error('ProjectStartupApp:MissingInstructors','Instructor resources are unavailable in this copy.')
                        end
                        addpath(genpath(folder))
                        InstructorResources;
                        delete(app)
                    case "readme"
                        app.openCourseFile(fullfile(app.RootFolder,'README'))
                        delete(app)
                    case "main"
                        app.openCourseFile(fullfile(app.RootFolder,'MainMenu'))
                        delete(app)
                    otherwise
                        error('ProjectStartupApp:UnknownAction','This action is unavailable.')
                end
            catch exception
                app.showStatus(exception.message)
                uialert(app.StartUpAppUIFigure,exception.message,'Unable to open resource')
            end
        end

        function openCourseFile(~,base)
            if isfile(base + '.m')
                open(base + '.m')
            else
                error('ProjectStartupApp:MissingFile','The requested course file is missing: %s',base)
            end
        end

        function openFeedback(app)
            try
                if isempty(which('ShareFeedback'))
                    % Support direct app launch before the project adds Utilities.
                    previousPath = path;
                    pathCleanup = onCleanup(@() path(previousPath));
                    addpath(fullfile(app.RootFolder,'Utilities'))
                end
                role = "choose";
                if app.HideInstructorResources
                    role = "student";
                end
                opened = ShareFeedback(Role=role,ProjectName=app.ProjectName,Parent=app.StartUpAppUIFigure);
                if ~opened
                    return
                end
                app.showStatus('Feedback opened in your browser. Thank you for sharing your experience.')
            catch exception
                app.showStatus(exception.message)
                uialert(app.StartUpAppUIFigure,exception.message,'Unable to open feedback')
            end
        end

        function [html,button] = resourceCard(app,column,buttonText,action)
            panel = uipanel(app.Lower,'BorderType','line','BackgroundColor',[1 1 1]);
            panel.Layout.Column = column;
            grid = uigridlayout(panel,[2 1]);
            grid.RowHeight = {'1x',34};
            grid.Padding = [10 10 10 10];
            grid.RowSpacing = 6;
            grid.BackgroundColor = [1 1 1];
            html = uihtml(grid);
            html.Layout.Row = 1;
            button = uibutton(grid,'Text',buttonText,'FontSize',14, ...
                'FontWeight','bold','ButtonPushedFcn',@(~,~) app.navigate(action));
            button.Layout.Row = 2;
        end

        function updateSummaryHeight(app)
            height = app.HTML5.Data;
            if isnumeric(height) && isscalar(height) && isfinite(height) && height > 0
                grid = app.HTML5.Parent;
                available = max(1,grid.Position(4) - 36 - 2*grid.RowSpacing);
                grid.RowHeight = {min(height,available),36,'1x'};
            end
        end

        function createComponents(app)
            % Leave room for the taskbar and window decorations on small displays.
            previousUnits = get(groot,'Units');
            unitsCleanup = onCleanup(@() set(groot,'Units',previousUnits));
            set(groot,'Units','pixels')
            screen = get(groot,'ScreenSize');
            windowWidth = min(800,screen(3)-64);
            windowHeight = min(540,screen(4)-100);
            windowPosition = [screen(1)+(screen(3)-windowWidth)/2, ...
                screen(2)+(screen(4)-windowHeight)/2,windowWidth,windowHeight];
            clear unitsCleanup
            app.StartUpAppUIFigure = uifigure('Visible','off','Name','StartUp App', ...
                'Position',windowPosition,'Tag','ProjectStartupNative', ...
                'Color',[0.97 0.98 0.99]);
            app.StartUpAppUIFigure.CloseRequestFcn = @(~,~) delete(app);
            root = uigridlayout(app.StartUpAppUIFigure,[3 1]);
            root.RowHeight = {62,'1x',0};
            root.Padding = [0 0 0 0];
            root.BackgroundColor = [0.97 0.98 0.99];
            app.Header = uigridlayout(root,[1 4]);
            app.Header.Layout.Row = 1;
            app.Header.ColumnWidth = {64,'1x',36,36};
            app.Header.Padding = [12 0 12 0];
            app.Header.BackgroundColor = [1 1 1];
            app.TeamLogo = uiimage(app.Header,'ScaleMethod','fit', ...
                'ImageSource',fullfile(fileparts(fileparts(mfilename('fullpath'))),'Images','TeachingResourcesLogo.png'), ...
                'BackgroundColor',app.Header.BackgroundColor);
            app.TeamLogo.Layout.Column = 1;
            brandGrid = uigridlayout(app.Header,[2 1]);
            brandGrid.Layout.Column = 2;
            brandGrid.RowHeight = {26,18};
            brandGrid.Padding = [0 9 0 9];
            brandGrid.RowSpacing = 0;
            brandGrid.BackgroundColor = app.Header.BackgroundColor;
            app.HTML4 = uihtml(brandGrid);
            app.HTML4.Layout.Row = 1;
            aboutLink = uihyperlink(brandGrid,'Text','About us','FontSize',12, ...
                'HorizontalAlignment','left', ...
                'URL','https://www.mathworks.com/matlabcentral/profile/authors/37969341');
            aboutLink.Layout.Row = 2;
            contactGrid = uigridlayout(app.Header,[3 1]);
            contactGrid.Layout.Column = 3;
            contactGrid.RowHeight = {'1x',36,'1x'};
            contactGrid.Padding = [0 0 0 0];
            contactGrid.RowSpacing = 0;
            contactGrid.BackgroundColor = app.Header.BackgroundColor;
            app.ContactLink = uibutton(contactGrid,'Text','', ...
                'Icon',fullfile(fileparts(fileparts(mfilename('fullpath'))),'Images','MailIcon.png'), ...
                'IconAlignment','center', ...
                'BackgroundColor',[0.97 0.98 0.99],'FontColor',[0.38 0.46 0.52], ...
                'Tooltip','About Us / Contact Us', ...
                'ButtonPushedFcn',@(~,~) app.navigate("contact"));
            app.ContactLink.Layout.Row = 2;
            resourcesGrid = uigridlayout(app.Header,[3 1]);
            resourcesGrid.Layout.Column = 4;
            resourcesGrid.RowHeight = {'1x',36,'1x'};
            resourcesGrid.Padding = [0 0 0 0];
            resourcesGrid.RowSpacing = 0;
            resourcesGrid.BackgroundColor = app.Header.BackgroundColor;
            resourcesButton = uibutton(resourcesGrid,'Text','', ...
                'Icon',fullfile(matlabroot,'toolbox','matlab','project','sharing','github','images','github_24.png'), ...
                'BackgroundColor',[0.97 0.98 0.99],'FontColor',[0.38 0.46 0.52], ...
                'Tooltip','Follow us on GitHub', ...
                'ButtonPushedFcn',@(~,~) app.navigate("resources"));
            resourcesButton.Layout.Row = 2;
            app.Panel = uipanel(root,'BorderType','none');
            app.Panel.Layout.Row = 2;
            app.GridLayout = uigridlayout(app.Panel,[2 1]);
            app.GridLayout.RowHeight = {'1.1x','1x'};
            app.GridLayout.Padding = [16 12 16 12];
            app.GridLayout.RowSpacing = 10;
            app.GridLayout.Scrollable = 'off';
            app.GridLayout.BackgroundColor = [0.97 0.98 0.99];
            app.Upper = uigridlayout(app.GridLayout,[1 2]);
            app.Upper.Layout.Row = 1;
            app.Upper.ColumnWidth = {'1x','1x'};
            app.Upper.Padding = [0 0 0 0];
            app.Upper.BackgroundColor = app.GridLayout.BackgroundColor;
            copy = uigridlayout(app.Upper,[3 1]);
            copy.Layout.Column = 1;
            copy.RowHeight = {120,36,'1x'};
            copy.RowSpacing = 6;
            copy.Padding = [0 0 10 0];
            copy.BackgroundColor = app.GridLayout.BackgroundColor;
            app.HTML5 = uihtml(copy);
            app.HTML5.Layout.Row = 1;
            app.HTML5.DataChangedFcn = @(~,~) app.updateSummaryHeight();
            app.StartUpAppUIFigure.AutoResizeChildren = 'off';
            app.StartUpAppUIFigure.SizeChangedFcn = @(~,~) app.updateSummaryHeight();
            app.MainMenuButton = uibutton(copy,'Text','Open Main Menu', ...
                'FontSize',14,'FontWeight','bold','BackgroundColor',[0 0.46 0.66], ...
                'FontColor',[1 1 1],'ButtonPushedFcn',@(~,~) app.navigate("main"));
            app.MainMenuButton.Layout.Row = 2;
            artwork = uigridlayout(app.Upper,[1 1]);
            artwork.Layout.Column = 2;
            artwork.Padding = [4 4 4 4];
            artwork.BackgroundColor = app.GridLayout.BackgroundColor;
            app.Image2 = uiimage(artwork,'ScaleMethod','fit','Visible','off', ...
                'BackgroundColor',app.GridLayout.BackgroundColor);
            app.Image2.Layout.Row = 1;
            app.Image2.Layout.Column = 1;
            app.ImageFallback = uilabel(artwork,'Text','Explore. Experiment. Understand.', ...
                'WordWrap','on','HorizontalAlignment','center','FontSize',20,'FontWeight','bold');
            app.ImageFallback.Layout.Row = 1;
            app.ImageFallback.Layout.Column = 1;
            cardCount = 3 - app.HideInstructorResources;
            app.Lower = uigridlayout(app.GridLayout,[1 cardCount]);
            app.Lower.Layout.Row = 2;
            app.Lower.ColumnWidth = repmat({'1x'},1,cardCount);
            app.Lower.ColumnSpacing = 10;
            app.Lower.Padding = [0 0 0 0];
            app.Lower.BackgroundColor = app.GridLayout.BackgroundColor;
            [app.HTML,app.READMEButton] = app.resourceCard(1,'Open README',"readme");
            if ~app.HideInstructorResources
                [app.HTML2,app.InstructorButton] = app.resourceCard(2,'Instructor resources',"instructor");
            end
            [app.HTML3,app.ReviewUsButton] = app.resourceCard(cardCount,'Share Feedback',"feedback");
            app.StatusLabel = uilabel(root,'Text','','WordWrap','on','FontSize',12);
            app.StatusLabel.Layout.Row = 3;
            app.alignNativeTypography()
            app.ContactLink.FontColor = [82 101 119]/255;
        end

    end

    methods (Access = public)
        function app = ProjectStartupApp(mode)
            if nargin == 0
                mode = "default";
            end
            preview = strcmp(mode,"previewLegacy");
            try
                if preview || isMATLABReleaseOlderThan("R2025a")
                    createCompatibilityComponents(app,preview)
                    registerApp(app,app.StartUpAppUIFigure)
                    return
                end
                createComponents(app)
                registerApp(app,app.StartUpAppUIFigure)
                runStartupFcn(app,@startupFcn)
            catch exception
                delete(app)
                rethrow(exception)
            end
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.StartUpAppUIFigure) && isvalid(app.StartUpAppUIFigure)
                delete(app.StartUpAppUIFigure)
            end
        end
    end
end
