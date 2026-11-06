%[text] %[text:anchor:T_3AA44D56] # Lab 3: Fourier Transform
%[text] [⇦ Return to the main menu](file:../MainMenu.m)
%%
%[text] **1.** Consider the rectangular pulse function with parameter `a`:
%[text]{"align":"center"} $\\text{rect}(at) = \\left\\{ \n\\begin{array}{rl} \n1, & |t| \< a/2  \n\\\\\n0.5, & |t| = a/2  \n\\\\\n0, & |t| \> a/2  \n\\end{array} \\right.${"altText":"\text{rect}(at) = \left\{  \begin{array}{rl}  1, & |t| \< a\/2   \\ 0.5, & |t| = a\/2   \\ 0, & |t| \> a\/2   \end{array} \right."}
%[text] Define the symbolic rectangular pulse function in terms of the symbolic variable `t` and numeric value `a` defined in the space below. Name the result `r`.
%[text] **Hint**: use the [`rectangularPulse`](https://www.mathworks.com/help/symbolic/sym.rectangularpulse.html) function.
% Use these
a = 2; % Default: a = 2
syms t

% Define r here


%%
%[text] **2.** Plot the rectangular pulse `r` using [`fplot`](https://www.mathworks.com/help/matlab/ref/fplot.html).
% Write your code here


%%
%[text] **3.** (optional) Compute the Fourier transform of $\\text{rect}(at)${"altText":"\text{rect}(at)"} by hand.
%%
%[text] **4.** Use the Symbolic Math Toolbox to compute the Fourier transform of `r` defined in Q1 using [`fourier`](https://www.mathworks.com/help/symbolic/sym.fourier.html). Store the result in `rhat`.
% Compute the Fourier transform here


%%
%[text] **5.** Simplify `rhat` using the [`simplify`](https://www.mathworks.com/help/symbolic/sym.simplify.html) function. Save the result in `rhat`.


%%
%[text] **6.** Plot the Fourier transform using [`fplot`](https://www.mathworks.com/help/matlab/ref/fplot.html) on the interval `[-100,100]`. 


%%
%[text] **7.** Define and plot a function $y${"altText":"y"} that has a carrier cosine wave modulated by a rectangular pulse:
%[text]{"align":"center"} $y(t) = \\text{rect}(at)\\cos(2 \\pi f  t)${"altText":"y(t) = \text{rect}(at)\cos(2 \pi f  t)"}
%[text] Use the symbolic variable `t` and the values `a` and `f`. Plot y using [`fplot`](https://www.mathworks.com/help/matlab/ref/fplot.html).
% Use these
a = 2;
f = 5;
syms t

% Define f here


% Plot f here


%%
%[text] **8.** (optional) Compute the Fourier transform of $y(t)${"altText":"y(t)"} by hand.
%[text] **Hint**: rewrite the cosine function in terms of complex exponentials.
%%
%[text] **9.** Use the Symbolic Math Toolbox to compute, simplify, and plot the Fourier transform of `y` defined in question **7**. Store the result in `yhat`. Plot on the interval  `[-100,100]`. 
% Write your code here


%%
%[text] **10.** Change the carrier frequency to 10 Hz in question **7** and then rerun your code from questions **7** and **9**. How does the Fourier transform $\\hat{y}${"altText":"\hat{y}"} change? 
% Write your answer here in quotes
Q10ans = " "
%%
%[text] **11.** Increase the width of the rectangular pulse (by increasing the value of `a`). How does the frequency content change?
Q11ans = " "
%%
%[text] The Fourier **series** can be computed for a periodic extension of any real function. The partial complex Fourier series for the rectangular pulse train (assuming a period of $4a${"altText":"4a"}) is
%[text]{"align":"center"} $f\_N(t) = \\sum\_{-N}^N c\_n e^{ \\frac{i n \\pi}{2a} t}${"altText":"f\_N(t) = \sum\_{-N}^N c\_n e^{ \frac{i n \pi}{2a} t}"} 
%[text] with $c\_n = \\frac{\\sin (\\pi n /2)}{\\pi n}${"altText":"c\_n = \frac{\sin (\pi n \/2)}{\pi n}"} for $n \\neq 0${"altText":"n \neq 0"} and $c\_0 = 1/2${"altText":"c\_0 = 1\/2"}.
%[text] **Task.** Run this section to compute the Fourier coefficients and the partial series $f\_{N}${"altText":"f\_{N}"}.
% Compute the coefficients
a = 2;
n = -100:100;
cn = sin(pi*n/2)./(pi*n);
cn(round(end/2)) = 1/2;

% Compute the series f
t = linspace(-10,10,1e3);
fN = zeros(size(t));
for k = 1:numel(n)
    fN = fN + cn(k).*exp(1i*n(k)*pi/(2*a).*t);
end
%%
%[text] **12.** Create a stem plot of the Fourier coefficients $c\_n${"altText":"c\_n"} against the index $n${"altText":"n"}.
% Create your stem plot here


%%
%[text] **13.** Plot the partial Fourier series $f${"altText":"f"} against $t${"altText":"t"}. The series has already been computed and is stored in `fN`.
% Create your plot here


%%
%[text] **14.** What similarities and differences do you see between the partial Fourier series $f\_N${"altText":"f\_N"} and the original rectangular pulse $y${"altText":"y"} plotted in questions **2** and **6**?
Q14ans = " " + ...
         " "
%[text] [⇦ Return to the main menu](file:../MainMenu.m)
%[text] 
%%
%[text] ## Help us Improve
%[text] [Share your feedback](<matlab: ShareFeedback>) to help us improve this module.


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":39.3}
%---
