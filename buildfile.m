function plan = buildfile
% buildfile - MATLAB Build Automation Configuration
%
% PURPOSE:
%   This file defines an automated build plan that orchestrates testing,
%   validation, and badge generation for the courseware.
%   It is executed by MATLAB's buildtool command and uses the buildplan
%   object to define a series of tasks.
%
% QUICK OVERVIEW:
%   Think of this file as a recipe that describes:
%   1. What tests to run (courseware tests, function tests, multi-release validation)
%   2. Where to save results (organized by MATLAB release in ./public/)
%   3. How to cross-check results across releases
%   4. How to generate a status badge showing which releases passed
%
% LOCAL EXECUTION:
%   Run from MATLAB Command Window:
%     >> openProject(pwd); buildtool test     % Run all tests (default)
%     >> buildtool report                      % Validate and generate badge
%     >> buildtool clean                       % Clean build artifacts
%
% CI INTEGRATION (GitHub Actions - see .github/workflows/ci.yml):
%   GitHub runs this buildfile in a MATRIX across multiple MATLAB releases.
%   See .github/workflows/ci.yml for workflow overview and artifact flow.
%
%   FLOW:
%     1. test-matrix job (parallel): For each release in matrix.Releases [R2024b, R2025a, R2025b]:
%        - Runs: buildtool test
%        - Generates: public/<RELEASE>/CoursewareSmokeTests.mat, FunctionTests.mat
%        - Uploads: test-results-<RELEASE> artifacts
%
%     2. report-and-deploy job (sequential, after test-matrix):
%        - Downloads: All test-results-* artifacts and merges into public/
%        - Runs: buildtool report
%          * report:validate task runs SoftwareTests/CrossReleaseTestResults.m
%          * report:badge task runs createBadge() -> public/TestedWith.json
%          * report:link task runs linkResultArtifactPathsInReportIndex()
%        - Deploys: public/ to GitHub Pages
%
%   KEY PARAMETERS:
%     - matrix.Releases: Tested MATLAB versions (line 29 of ci.yml)
%     - MATLAB_PRODUCTS: Required products (line 28 of ci.yml)
%     - Triggers: push/PR to 'release' branch (lines 3-7 of ci.yml)

import matlab.buildtool.Task
import matlab.buildtool.tasks.TestTask
import matlab.buildtool.tasks.CleanTask

plan = buildplan;
plan.DefaultTasks = "test";

release = "R" + string(version("-release"));
releaseFolder = fullfile("public", release);

% TASK 1: CoursewareSmokeTests
% Tests core courseware scripts (Scripts/ folder)
% Runs in both local and CI environments
% Output: public/<RELEASE>/CoursewareSmokeTests.{xml, html, mat}

plan("test:courseware") = TestTask("SoftwareTests/CoursewareSmokeTests.m",...
    IncludeSubfolders=false,...
    TestResults=fullfile(releaseFolder, ["CoursewareSmokeTests.xml" "CoursewareSmokeTests.html" "CoursewareSmokeTests.mat"]),...
    Description="Run CoursewareSmokeTests", ...
    SourceFiles="Scripts",...
    RunOnlyImpactedTests=true);
plan("test:courseware").Outputs = releaseFolder;

% TASK 2: FunctionTests (Conditional)
% Tests functions in development in FunctionLibrary/
% Only added to the plan if the FunctionTests class has test methods
% This allows incremental development: tests are run when ready
% Output: public/<RELEASE>/FunctionTests.{xml, html, mat}
if ~isempty(matlab.unittest.TestSuite.fromClass(?FunctionTests))
    plan("test:function") = TestTask("SoftwareTests/FunctionTests.m",...
        IncludeSubfolders=false,...
        TestResults=fullfile(releaseFolder, ["FunctionTests.xml" "FunctionTests.html" "FunctionTests.mat"]),...
        Description="Run FunctionTests", ...
        SourceFiles="FunctionLibrary", ...
        RunOnlyImpactedTests=true);
end

% TASK 3: report:validate (CI-only, runs after test-matrix merge)
% Aggregates test results from all MATLAB releases (public/2024b/, public/2025a/, public/2025b/)
% Validates that tests passed consistently across releases
% This task is skipped in local builds; only runs in CI after all matrix jobs complete
% Output: public/index.html and public/CrossReleaseTestResults.mat
plan("report:validate") = TestTask("SoftwareTests/CrossReleaseTestResults.m",...
    IncludeSubfolders=false,...
    TestResults=fullfile("public",["index.html" "CrossReleaseTestResults.mat"]),...
    Description="Run CrossReleaseTestResults");
plan("report:validate").Outputs = fullfile("public",["*.html" "*.mat"]);

% TASK 4: badge (CI-only, depends on report:check)
% Generates ./public/TestedWith.json - A JSON badge showing tested releases and pass/fail status
% Color logic:
%   - green (success):     All releases passed
%   - yellow (warning):    Some releases passed
%   - red (critical):      All releases failed
% This badge is deployed to GitHub Pages and often displayed in README.md
plan("report:badge") = Task(Actions=@createBadge);
plan("report:badge").Dependencies = "report:validate";
plan("report:badge").Outputs = fullfile("public","TestedWith.json");


% TASK 5: report:describe (CI-only)
% Creates a human-readable description for the report tasks and artifacts.
% This task generates a short text file in public/ describing:
%   - purpose of the report tasks (validate, badge, link)
%   - outputs produced (index.html, CrossReleaseTestResults.mat, TestedWith.json)
%   - deployment target (public/ served via GitHub Pages)
% The file is useful for maintainers and displays in CI artifact listings.
plan("report:link") = Task(Actions=@linkResultArtifactPathsInReportIndex);
plan("report:link").Dependencies = "report:validate";

plan("clean") = CleanTask;

end

function createBadge(~)

    load(fullfile("public","CrossReleaseTestResults.mat"),"result");
    result = table(result);
    result.Name = string(result.Name);
    result.Version = extractBetween(result.Name,"Path=",")");
    result = pivot(result, Rows="Version", DataVariable="Passed", ...
        Method=@(x) all(x), RowLabelPlacement="rownames");

    versionLabel = string(result.Properties.RowNames);
    result.Properties.VariableNames = {'Passed'};

    badge = struct;
    badge.schemaVersion = 1;
    badge.label = "Test Status";
    if all(result.Passed)
        badge.color = "success";
        badge.message = join(versionLabel, " | ");
    elseif any(result.Passed)
        badge.color = "yellowgreen";
        badge.message = join(versionLabel(result.Passed), " | ");
    else
        badge.color = "critical";
        badge.message = join(versionLabel, " | ");
    end

    writelines(jsonencode(badge), fullfile("public", "TestedWith.json"));
end

function linkResultArtifactPathsInReportIndex(~)
% linkResultArtifactPathsInReportIndex Add links for ResultArtifactPath tokens.
%
% This function reads a MATLAB-generated test report index HTML file,
% searches for text tokens like:
%   ResultArtifactPath=R2026a
%   ResultArtifactPath=R2025b
% and wraps each unlinked token in an anchor pointing to:
%   ./R2026a/CoursewareSmokeTests.html

indexFile = fullfile("public", "index.html");

indexFile = char(indexFile);
if ~isfile(indexFile)
    error("linkResultArtifactPathsInReportIndex:MissingFile", ...
        "Index HTML file not found: %s", indexFile);
end

html = fileread(indexFile);

% Match ResultArtifactPath tokens in the HTML report.
% Example matches:
%   ResultArtifactPath=R2026a
%   ResultArtifactPath=R2025b
pattern = 'ResultArtifactPath=(R20[0-9][0-9][ab])';
[startIdx, endIdx, tokenGroups, tokenMatches] = regexp(html, pattern, 'start', 'end', 'tokens', 'match');

if isempty(startIdx)
    return;
end

% Replace from the end so earlier indices remain valid.
for k = numel(startIdx):-1:1
    tokenStart = startIdx(k);
    tokenEnd = endIdx(k);

    % Skip if token is already wrapped by an anchor.
    if isAlreadyLinkedAt(html, tokenStart, tokenEnd)
        continue;
    end

    releaseLabel = tokenGroups{k}{end};
    tokenText = tokenMatches{k};
    href = sprintf('./%s/CoursewareSmokeTests.html', releaseLabel);
    replacement = sprintf('<a href="%s" target="_self">%s</a>', href, tokenText);

    html = [html(1:tokenStart-1), replacement, html(tokenEnd+1:end)];
end

fid = fopen(indexFile, "w");
if fid < 0
    error("linkResultArtifactPathsInReportIndex:WriteFailed", ...
        "Unable to open file for writing: %s", indexFile);
end

cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, html, "char");

end

function tf = isAlreadyLinkedAt(html, tokenStart, tokenEnd)
preStart = max(1, tokenStart - 200);
postEnd = min(length(html), tokenEnd + 20);

pre = html(preStart:tokenStart-1);
post = html(tokenEnd+1:postEnd);

hasAnchorOpenRightBefore = ~isempty(regexp(pre, '<a\b[^>]*>$', 'once'));
hasAnchorCloseRightAfter = ~isempty(regexp(post, '^</a>', 'once'));
tf = hasAnchorOpenRightBefore && hasAnchorCloseRightAfter;
end
