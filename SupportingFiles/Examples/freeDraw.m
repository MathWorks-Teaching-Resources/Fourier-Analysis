function [x,y,pHandle,markerHandle] = freeDraw(src,event,UIFigure,...
                                UIAxesHandle,color,closed,xmin,xmax,ymin,ymax)
    % Allows the user to draw freely
    % Wait until this is done

    N = 10;
    
    % Clear the axes
    cla(UIAxesHandle)

    % Start by removing the original motion/click callbacks(replace
    % them later)
    set(UIFigure,"Pointer","hand")
    origMotionFcn = UIFigure.WindowButtonMotionFcn;
    origButtonFcn = UIFigure.WindowButtonDownFcn;
    
    location = checkIfInFieldAxis(event,UIAxesHandle,xmin,xmax,ymin,ymax);
    x = location(1);
    y = location(2);
    drawing = true;

    hold(UIAxesHandle,"on")
        markerHandle = plot(UIAxesHandle,x,y,'o',"color",color,'markerfacecolor',color);
        pHandle = plot(UIAxesHandle,x,y,'linewidth',2,"color",color);
    hold(UIAxesHandle,"off")

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
    end

    function addPoint(object,event)
        if(drawing)
            location = checkIfInFieldAxis(event,UIAxesHandle,xmin,xmax,ymin,ymax);
  
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

    function location = checkIfInFieldAxis(event,UIAxesHandle,xmin,xmax,ymin,ymax)
        % Identify if inside the field and return location (this axis
        % is inside a panel)
        cp = event.Source.CurrentPoint;
        axPos =UIAxesHandle.Position;
        location = NaN; % Return NaN if outside
        if( cp(1) > axPos(1) && cp(1) < axPos(1) + axPos(3) &&...
            cp(2) > axPos(2) && cp(2) < axPos(2) + axPos(4) )
            % If so, update the current position
            loc = get(UIAxesHandle,'CurrentPoint');
            loc = loc(1,1:2);
            if(loc(1)>xmin && loc(1)<xmax && loc(2)>ymin && loc(2)<ymax)
                
                location = loc;

            end               
        end
    end
end