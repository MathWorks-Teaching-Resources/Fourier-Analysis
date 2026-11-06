%  Pre-run script for ComplexFourierSeries.m
% ---- Known Issues     -----
KnownIssuesID = "";
% ---- Pre-run commands -----
sound = @(x,y) disp("Using soundsc");
audioread = @(x) NewAudioRead(x);
% <matlab:ShareFeedback Share your feedback>
function varargout=NewAudioRead(varargin)
load(fullfile(currentProject().RootFolder,"SoftwareTests","PreFiles","Lab4_DFTSoln.mat"));
varargout={y2Ch,Fs};
end