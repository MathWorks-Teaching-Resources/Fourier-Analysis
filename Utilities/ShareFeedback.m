function varargout = ShareFeedback(options)
    %ShareFeedback Open a courseware feedback form in the system browser.
    %   ShareFeedback prompts for a student, faculty, or other role and
    %   prefills the form with the current project's name.
    %
    %   ShareFeedback(Role="student") opens the student form directly.
    %   Role can be "student", "faculty", "other", or "choose" (default).
    %
    %   ShareFeedback(ProjectName="My module",Parent=fig) uses an explicit
    %   project name and parents the role dialog to a UI figure. Without
    %   Parent, a compact dialog offers role buttons and a Cancel action.
    %
    %   OPENED = ShareFeedback(...) returns true if the browser opens and
    %   false if the user cancels. It does not confirm form submission.
    %   Browser failures raise an error for the caller to handle.
    %
    %   See also WEB, UICONFIRM, CURRENTPROJECT

    arguments
        options.Role (1,1) string {mustBeMember(options.Role, ...
            ["choose","student","faculty","other"])} = "choose"
        options.ProjectName (1,1) string = ""
        options.Parent = []
    end

    varargout = cell(1,nargout);
    if nargout > 0
        varargout{1} = false;
    end
    projectName = options.ProjectName;
    if strlength(projectName) == 0
        project = currentProject();
        projectName = string(project.Name);
    end
    parent = options.Parent;
    if ~isempty(parent) && ~(isa(parent,'matlab.ui.Figure') && isscalar(parent) && isvalid(parent))
        error('ShareFeedback:InvalidParent','Parent must be a valid scalar UI figure.')
    end
    role = options.Role;
    if role == "choose"
        if isempty(parent)
            role = chooseFeedbackRole();
            if role == ""
                return
            end
        else
            choice = uiconfirm(parent, ...
                'Choose what describes you best.', ...
                'Share feedback','Options',{'Student','Faculty','Other','Cancel'}, ...
                'DefaultOption',1,'CancelOption',4);
            if strcmp(choice,'Cancel')
                return
            end
            role = lower(string(choice));
        end
    end

    formId = 'ETrdmUhDaESb3eUHKx3B5mlcO9AKxC5AgMAKBg6OKuBUNlNBOVRZSDZHT1VTMzA4MjdHSUdVR0o3Vy4u';
    question = 'r362e367caa234debbf4f65a58a0338e6';
    if role == "faculty"
        formId = 'ETrdmUhDaESb3eUHKx3B5mlcO9AKxC5AgMAKBg6OKuBUNTVXVlBTS0lOU0hPRExYMldGWldVQUhIRC4u';
        question = 'r2017080ed20546d1a2db18fe36421929';
    end
    uri = matlab.net.URI('https://forms.office.com/Pages/ResponsePage.aspx','literal');
    uri.Query = [matlab.net.QueryParameter('id',formId); ...
        matlab.net.QueryParameter(question,projectName)];
    status = web(strrep(uri.EncodedURI,'+','%20'),'-browser');
    if status ~= 0
        error('ShareFeedback:Browser','The browser could not open. Please try again.')
    end
    if nargout > 0
        varargout{1} = true;
    end
end

function role = chooseFeedbackRole()
    role = "";
    dialog = uifigure('Name','Share feedback','Position',[100 100 460 160], ...
        'Resize','off','Visible','off','Color',[1 1 1]);
    dialogCleanup = onCleanup(@() deleteFeedbackDialog(dialog));
    dialog.CloseRequestFcn = @(~,~) cancelDialog();
    dialog.WindowKeyPressFcn = @handleKey;
    grid = uigridlayout(dialog,[3 1]);
    grid.RowHeight = {'fit','fit',34};
    grid.Padding = [20 16 20 16];
    grid.RowSpacing = 10;
    grid.BackgroundColor = dialog.Color;
    message = uilabel(grid,'Text', ...
        'Thanks for being willing to share your feedback. Your experience helps us improve these resources.', ...
        'WordWrap','on','FontName','Segoe UI','FontSize',14, ...
        'FontColor',[23 43 61]/255);
    message.Layout.Row = 1;
    prompt = uilabel(grid,'Text','Choose what describes you best.', ...
        'FontName','Segoe UI','FontSize',14,'FontWeight','bold', ...
        'FontColor',[23 43 61]/255,'WordWrap','on');
    prompt.Layout.Row = 2;
    actions = uigridlayout(grid,[1 4]);
    actions.Layout.Row = 3;
    actions.ColumnWidth = {'1x','1x','1x','1x'};
    actions.Padding = [0 0 0 0];
    actions.ColumnSpacing = 8;
    actions.BackgroundColor = dialog.Color;
    roles = ["student","faculty","other"];
    captions = {'Student','Faculty','Other'};
    for index = 1:3
        button = uibutton(actions,'Text',captions{index}, ...
            'FontName','Segoe UI','FontSize',14,'FontWeight','bold', ...
            'FontColor',[23 43 61]/255, ...
            'ButtonPushedFcn',@(~,~) selectRole(roles(index)));
        button.Layout.Column = index;
        if index == 1
            button.BackgroundColor = [0 0.447 0.741];
            button.FontColor = [1 1 1];
        end
    end
    cancel = uibutton(actions,'Text','Cancel','FontName','Segoe UI','FontSize',14, ...
        'FontColor',[23 43 61]/255, ...
        'ButtonPushedFcn',@(~,~) cancelDialog());
    cancel.Layout.Column = 4;
    movegui(dialog,'center')
    dialog.Visible = 'on';
    uiwait(dialog)
    deleteFeedbackDialog(dialog)

    function selectRole(selectedRole)
        role = selectedRole;
        deleteFeedbackDialog(dialog)
    end

    function cancelDialog()
        role = "";
        deleteFeedbackDialog(dialog)
    end

    function handleKey(~,event)
        if strcmp(event.Key,'escape')
            cancelDialog()
        end
    end
end

function deleteFeedbackDialog(dialog)
    if isvalid(dialog)
        delete(dialog)
    end
end
