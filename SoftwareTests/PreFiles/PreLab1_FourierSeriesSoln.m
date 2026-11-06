%  Pre-run script for ComplexFourierSeries.m
% ---- Known Issues     -----
KnownIssuesID = "";
% ---- Pre-run commands -----
sound = @(x,y) disp("Using sound");
audioread = @(x) NewAudioRead(x);
% <matlab:ShareFeedback Share your feedback>
function varargout=NewAudioRead(varargin)
load(fullfile(currentProject().RootFolder,"SoftwareTests","PreFiles","Lab1_FourierSeries.mat"));
varargout={y,Fs};
end