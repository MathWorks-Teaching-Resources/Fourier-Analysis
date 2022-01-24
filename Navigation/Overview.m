%% Fourier Analysis
%
% <html>
% <span style="font-family:Arial">
% <span style="font-size:12pt">
% <h2> Information </h2>
% This curriculum module teaches Fourier analysis using interactive 
% <a href="https://www.mathworks.com/products/matlab/live-editor.html">live scripts</a>
% and <a href="https://www.mathworks.com/products/matlab/app-designer.html">MATLAB&reg; apps</a>. 
% The module is taught from a signal processing perspective at a level 
% suitable for an introductory signals and systems course. 
% In the first lesson, students use apps to visualize Fourier series and
% build intuition about the frequency domain. In subsequent lessons, 
% students study complex Fourier series, Fourier transforms, and discrete 
% Fourier transforms. As students progress, they transition from utilizing 
% apps to writing their own code to analyze signals. Throughout the module, 
% students apply Fourier techniques to analyze recorded audio signals.
% <br>
% <br>
% Each topic includes a lab that applies the concepts taught in the lesson. 
% The solutions are available upon instructor request. If you
% would like to request solutions, find an issue,
% or have a suggestion, email the MathWorks online teaching team at 
% onlineteaching@mathworks.com
% <br>
% <br>
% <h2> Getting Started </h2>
% <ol>
% <li>
% Make sure that you have all the required products (listed below)
% installed. If you are missing a product, add it using the 
% <a href="https://www.mathworks.com/products/matlab/add-on-explorer.html">
% Add-On Explorer.</a> To install an add-on, go to the <b>Home</b>
% tab and select <img src="../Images/add-ons.png" style="margin:0px;" height=12> <b> Add-Ons > Get Add-Ons</b>.
% </li>
% <li>
% Get started with each topic by clicking the link in the first column of the table below to access the
% introductory example. The instructions inside each live script will walk
% you through the lesson.
% </li>
% <li> 
% Complete the lab assignment located in the last column of the table to apply the concepts.
% </li>
% </ol>
% <h2> Products </h2>
% MATLAB, Symbolic Math Toolbox
% <br>
% <br>
% <h2> Modules </h2>
% <table border=1 style="margin-left:20px; cellpadding:15px;">
% <tr>
%   <th>Interactive Examples</th>
%   <th>Learning Goals</th>
%   <th>Lab Assignments</th>
% </tr>
% <tr>
%   <td>
%       <b>Fourier Series</b><br>
%           &nbsp;&nbsp;<a href="matlab:edit FourierSeries.mlx;"><code>FourierSeries.mlx</code><br>
%       <img src = "../Images/FourierSeriesCover.png" height=100 style="margin-top:5px; margin-bottom:0px"></a>
%   </td>
%   <td>
%   	<ul style="margin-top:5px; margin-bottom:10px">
%           <li>Compare signals in the time and frequency domains.</li>
%           <li>Analyze audio signals in the frequency domain.</li>
%           <li>Visualize Fourier series modes.</li>
%           <li>Describe how phase shift is represented in a Fourier series.</li>
%           <li>Compute the Fourier series of a periodic function.</li>
%           <li>Discuss magnitude and phase.</li>
%       </ul>
%   </td>
%   <td>
%       <a href="matlab:edit Lab1_FourierSeries.mlx;">Lab1_FourierSeries.mlx</a>
%   </td>
% </tr>
% <tr>
%   <td>
%       <b>Complex Fourier Series</b><br>
%           &nbsp;&nbsp;<a href="matlab:edit ComplexFourierSeries.mlx;"><code>ComplexFourierSeries.mlx</code><br>
%       <img src = "../Images/ComplexSeriesCover.png" height=100 style="margin-top:5px; margin-bottom:0px"></a>
%   </td>
%   <td>
%   	<ul style="margin-top:5px; margin-bottom:10px">
%           <li>Recall Euler's formula.</li>
%           <li>Compare complex and real Fourier series.</li>
%           <li>Visualize complex Fourier series.</li>
%           <li>Construct functions using complex Fourier series.</li>
%       </ul>
%   </td>
%   <td>
%       <a href="matlab:edit Lab2_ComplexFourierSeries.mlx;">Lab2_ComplexFourierSeries.mlx</a>
%   </td>
% </tr>
% <tr>
%   <td>
%       <b>Fourier Transform</b><br>
%           &nbsp;&nbsp;<a href="matlab:edit FourierTransform.mlx;"><code>FourierTransform.mlx</code><br>
%       <img src = "../Images/FourierTransformCover.png" height=100 style="margin-top:5px; margin-bottom:0px"></a>
%   </td>
%   <td>
%   	<ul style="margin-top:5px; margin-bottom:10px">
%           <li>Compare Fourier series to the Fourier transform.</li>
%           <li>Evaluate the Fourier transform of a function.</li>
%           <li>Represent signals using continuous functions.</li>
%           <li>Discuss carrier waves and modulation.</li>
%           <li>Compare functions in the time and frequency domains using the Fourier transform.</li>
%       </ul>
%   </td>
%   <td>
%       <a href="matlab:edit Lab3_FourierTransform.mlx;">Lab3_FourierTransform.mlx</a>
%   </td>
% </tr>
% <tr>
%   <td>
%       <b>Discrete Fourier Transform</b><br>
%           &nbsp;&nbsp;<a href="matlab:edit DiscreteFourierTransform.mlx;"><code>DiscreteFourierTransform.mlx</code><br>
%       <img src = "../Images/DFTCover.png" height=100 style="margin-top:5px; margin-bottom:0px"></a>
%   </td>
%   <td>
%   	<ul style="margin-top:5px; margin-bottom:10px">
%           <li>Define the discrete Fourier transform (DFT).</li>
%           <li>Use the fft function to compute the DFT.</li>
%           <li>Relate the DFT to the Fourier transform.</li>
%           <li>Apply the DFT to analyze an audio signal.</li>
%       </ul>
%   </td>
%   <td>
%       <a href="matlab:edit Lab4_DFT.mlx;">Lab4_DFT.mlx</a>
%   </td>
% </tr>
% </table>
% <br>
% <h2> Apps </h2>
% <table border=1 style="margin-left:20px; cellpadding:15px;">
% <tr>
%   <td style="Horizontal-alignment:center;">
%       <a href="matlab:run SinCosSeries.mlapp;">
%       Sine and Cosine Series app
%       <br>
%       <img src = "../Images/SinCosSeriesApp.png" height=150 style="margin-top:5px; margin-bottom:0px">
%       </a>
%   </td>
%   <td style="Horizontal-alignment:center;">
%       <a href="matlab:run InteractiveFourierSeries.mlapp;">
%       Fourier Series app
%       <br>
%       <img src = "../Images/FourierSeriesApp.png" height=150 style="margin-top:5px; margin-bottom:0px">
%       </a>
%   </td>
%   <td style="Horizontal-alignment:center;">
%       <a href="matlab:run MagnitudePhase.mlapp;">
%       Magnitude and Phase app
%       <br>
%       <img src = "../Images/MagPhaseApp.png" height=150 style="margin-top:5px; margin-bottom:0px">
%       </a>
%   </td>
%   <td style="Horizontal-alignment:center;">
%       <a href="matlab:run ComplexFourierSeries.mlapp;">
%       Complex Fourier Series app
%       <br>
%       <img src = "../Images/ComplexSeriesApp.png" height=150 style="margin-top:5px; margin-bottom:0px">
%       </a>
%   </td>
% </tr>
% </table>
% <br>
% </span>
% </span>
% </html>
% 
% Copyright 2022 The MathWorks(TM), Inc.
