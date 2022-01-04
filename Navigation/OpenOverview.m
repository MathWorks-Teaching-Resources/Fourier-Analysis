function OpenOverview
    % Open the overview file
    open("Overview.html")
    
    % Close the current script
    close(matlab.desktop.editor.getActive)
end