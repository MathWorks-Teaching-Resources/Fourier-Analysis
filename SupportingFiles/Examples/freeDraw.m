 function [x,y,pHandle] = freeDraw(UIFigure,UIAxesHandle,closed)
    % Allows the user to draw freely
    % Wait until this is done
    
    % Start by removing the original motion/click callbacks(replace
    % them later)
    set(UIFigure,"Pointer","crosshair")
    origMotionFcn = UIFigure.WindowButtonMotionFcn;
    origButtonFcn = UIFigure.WindowButtonDownFcn;
    
    x = NaN;
    y = NaN;
    areaPlot = [];
    hold(UIAxesHandle,"on")
        pHandle = plot(UIAxesHandle,x,y,'linewidth',2,"color",[0.8,0.4,0.4]);
    hold(UIAxesHandle,"off")
    
    drawing = false;
    
    UIFigure.WindowButtonMotionFcn = @addPoint;
    UIFigure.WindowButtonDownFcn = @clickCallback;
     
    uiwait(UIFigure)
    function clickCallback(object,event)
        % Stop drawing
        if(drawing)
            % Replace the functions
            UIFigure.WindowButtonMotionFcn = origMotionFcn;
            UIFigure.WindowButtonDownFcn = origButtonFcn;      
            set(UIFigure,"Pointer","Arrow")
            uiresume(UIFigure)
            
            return
        end
        
        % Start drawing
        location = SharedFunctions.checkIfInFieldAxis(event,...
             UIAxesHandle,xmin,xmax,ymin,ymax);
        if(numel(location) == 2 && ~any(isnan(location)) )
            x = location(1);
            y = location(2);
            pHandle.XData(1) = x;
            pHandle.YData(1) = y;
            drawing = true;
            set(UIFigure,"Pointer","Cross")
        end
    end

    function addPoint(object,event)
        if(drawing)
            location = SharedFunctions.checkIfInFieldAxis(event,UIAxesHandle);
         
             if(numel(location) == 2 && ~any(isnan(location)) )
                x = [x;location(1)];
                y = [y;location(2)];
                pHandle.XData = x;
                pHandle.YData = y;
                
                if(closed)
                    pHandle.XData = [x;x(1)];
                    pHandle.YData = [y;y(1)];
                end

                pause(0);
             end
        end
    end
end