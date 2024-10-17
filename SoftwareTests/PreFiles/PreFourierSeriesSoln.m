%  Pre-run script for ComplexFourierSeries.mlx
% ---- Known Issues     -----
KnownIssuesID = "";
% ---- Pre-run commands -----
soundsc = @(x,y) disp("Using soundsc");
audioread = @(x) NewAudioRead(x);
function varargout=NewAudioRead(varargin)
load(fullfile(currentProject().RootFolder,"SoftwareTests","PreFiles","FourierSeries.mat"));
varargout={yGuitar,FsGuitar};
end