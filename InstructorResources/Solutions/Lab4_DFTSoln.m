%[text] %[text:anchor:T_3AA44D56] # Lab 4: DFT
%[text] [⇦ Return to the main menu](file:../../MainMenu.m)
%[text] In this lab, you will write code to analyze audio signals using the discrete Fourier transform.
%%
%[text] **1.** Read the test audio signal into MATLAB using the [`audioread`](https://www.mathworks.com/help/matlab/ref/audioread.html) function with the syntax
%[text] ```matlabCodeExample
%[text] [y2Ch,Fs] = audioread("filename")
%[text] ```
%[text] The test signal is stored in `ENote.mp3`. Store the signal in `y2Ch` and the sampling frequency in `Fs`.
% [y2Ch,Fs] = audioread("Enote.mp3")
[y2Ch,Fs] = audioread("note5.mp3")
%%
%[text] **2.** The audio signal has two channels. Each is stored in a column of `y2Ch`. Select the first channel and store it in `y`. You can select the `k`$^{th}${"altText":"^{th}"} column of a matrix `Y` using
%[text] ```matlabCodeExample
%[text] y = Y(:,k)
%[text] ```
y = y2Ch(:,1);
%%
%[text] **3.** Play the audio signal using [`sound`](https://www.mathworks.com/help/matlab/ref/sound.html).
sound(y,Fs)
%%
%[text] **4.** Compute the magnitude of the shifted DFT of `y`.
%[text] 1. Compute the FFT.
%[text] 2. Rescale/shift it to match the form of the Fourier transform. 
%[text] 3. Compute the magnitude. Store the result in `mag`. \
% Write your code here
yhat = fft(y);
yhatShift = fftshift(yhat);
mag = abs(1/Fs*yhatShift);
%[text] If you're not sure how to perform these computations, review the examples in [`DiscreteFourierTransform.m`](file:../../Scripts/DiscreteFourierTransform.m)`.`
%%
%[text] **5.** Plot the magnitude of the spectrum against the frequencies in Hz. 
%[text] 1. Create a vector (called `freq`) of frequencies (in Hz) that correspond to the values stored in `mag`. 
%[text] 2. Plot `mag` against `freq`. 
%[text] 3. Set the frequency axis limits to `[-1000,1000]` Hz. \
% Write your code here
N = numel(mag);
freq = Fs/N*(-N/2:N/2-1);
plot(freq,mag)
xlim([-1000 1000])
xlabel("frequency (Hz)")
ylabel("Magnitude")
%[text] If you're not sure how to create the frequency vector, review the examples in [`DiscreteFourierTransform.m`](file:../../Scripts/DiscreteFourierTransform.m)`.`
%%
%[text] **6.** Examine the frequency plot. If correct, you should see three significant peaks located at 82.1, 164.4, and 246.5 Hz. 
%%
%[text] **7.** For each of the listed audio recordings, determine the guitar note that generated the sound. To analyze each recording, replace the `filename` in question **1** and rerun the entire script.
%[text] - `note1.mp3`
%[text] - `note2.mp3`
%[text] - `note3.mp3`
%[text] - `note4.mp3`
%[text] - `note5.mp3` \
%[text] **Hint:** The note is determined by the fundamental frequency (the lowest frequency peak). The relevant notes are shown in the table below.
%[text]  $\\text{\\textbf{Octave 2}}\n\\\\\n\\begin{array}{lr} \n\\text{Note} & \\text{ Hz} \\\\\nC & 65.4 \\\\ \nC\\\# & 69.3 \\\\\nD & 73.4 \\\\\nD\\\# & 77.8\\\\\nE & 82.4\\\\\nF & 87.3 \\\\\nF\\\# & 92.5 \\\\\nG & 98.0\\\\\nG\\\# & 103.8\\\\\nA & 110.0\\\\\nA\\\# & 116.5\\\\\nB & 123.5\\\\\n\\end{array}${"altText":"\text{\textbf{Octave 2}} \\ \begin{array}{lr}  \text{Note} & \text{ Hz} \\ C & 65.4 \\  C\\# & 69.3 \\ D & 73.4 \\ D\\# & 77.8\\ E & 82.4\\ F & 87.3 \\ F\\# & 92.5 \\ G & 98.0\\ G\\# & 103.8\\ A & 110.0\\ A\\# & 116.5\\ B & 123.5\\ \end{array}"} $\\text{\\textbf{Octave 3}}\n\\\\\n\\begin{array}{lr} \n\\text{Note} & \\text{ Hz} \\\\\nC & 130.8 \\\\ \nC\\\# & 138.6 \\\\\nD & 146.8\\\\\nD\\\# & 155.6\\\\\nE & 164.8\\\\\nF & 174.6 \\\\\nF\\\# & 185.0 \\\\\nG & 196.0\\\\\nG\\\# & 207.7\\\\\nA & 220.0\\\\\nA\\\# & 233.1\\\\\nB & 246.9\\\\\n\\end{array}${"altText":"\text{\textbf{Octave 3}} \\ \begin{array}{lr}  \text{Note} & \text{ Hz} \\ C & 130.8 \\  C\\# & 138.6 \\ D & 146.8\\ D\\# & 155.6\\ E & 164.8\\ F & 174.6 \\ F\\# & 185.0 \\ G & 196.0\\ G\\# & 207.7\\ A & 220.0\\ A\\# & 233.1\\ B & 246.9\\ \end{array}"} $\\text{\\textbf{Octave 4}}\n\\\\\n\\begin{array}{lr} \n\\text{Note} & \\text{ Hz} \\\\\nC & 261.6 \\\\ \nC\\\# & 277.2 \\\\\nD & 293.7\\\\\nD\\\# & 311.1\\\\\nE & 329.6\\\\\nF & 349.2\\\\\nF\\\# & 370.0\\\\\nG & 392.0\\\\\nG\\\# & 415.3\\\\\nA & 440.0\\\\\nA\\\# & 466.2\\\\\nB & 493.9\\\\\n\\end{array}${"altText":"\text{\textbf{Octave 4}} \\ \begin{array}{lr}  \text{Note} & \text{ Hz} \\ C & 261.6 \\  C\\# & 277.2 \\ D & 293.7\\ D\\# & 311.1\\ E & 329.6\\ F & 349.2\\ F\\# & 370.0\\ G & 392.0\\ G\\# & 415.3\\ A & 440.0\\ A\\# & 466.2\\ B & 493.9\\ \end{array}"}
% Record your answers below using the name of the  
% note and the octave.
% For example, the test note was "E2"
note1 = "B2"
note2 = "B3"
note3 = "G4"
note4 = "A2"
note5 = "E3"
%[text] [⇦ Return to the main menu](file:../../MainMenu.m)
%[text] 
%%
%[text] ## Help us Improve
%[text] [Share your feedback](<matlab: ShareFeedback>) to help us improve this module.


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":40}
%---
