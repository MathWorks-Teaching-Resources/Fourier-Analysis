%  Pre-run script for ComplexFourierSeries.mlx
% ---- Known Issues     -----
KnownIssuesID = "";
% ---- Pre-run commands -----
sound = @(x,y) disp("Using soundsc");
audioread = @(x) NewAudioRead(x);
function varargout=NewAudioRead(varargin)
load(fullfile(currentProject().RootFolder,"SoftwareTests","PreFiles","Lab4_DFTSoln.mat"));
varargout={y2Ch,Fs};
end