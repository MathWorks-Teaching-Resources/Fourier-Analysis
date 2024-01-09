classdef DraggablePoint2D
    %DRAGGABLEPOINT
    % Constructor syntax:
    %    DraggablePoint(x0,y0)
    %    DraggablePoint(ax,x0,y0)
    %    DraggablePoint(ax,x0,y0,moveFunc)
    %    DraggablePoint(ax,x0,y0,moveFunc,axisRestriction)
    %   
    %    x0,y0: single value coordinate pair
    %    ax: axis handle where the point will be created
    %    func: handle of a function to be executed when a point is moved, 
    %          the function should take two inputs: x,y, the current 
    %          location of the point
    %    axisRestriction: restrict motion to an axis:
    %          0 (no restriction), 1 (only x), 2 (only y)
    %
    % Suggestions:
    %    1. Set the axis mode to manual when using the draggable point
    %
    % Interactions with other objects:
    %    1. This code automatically sets the axes to manual mode during
    %       dragging. Afterwards, it is reset.
    %    2. This code creates a point on the axes, the handle is stored in
    %       the object
    %
    %

    properties
        lineHandle
        funcHandle = [];
        restrictToAxis = 0; %Set to 1 for only x-axis motion and 2 for only y-axis motion
    end
    
    methods

        function obj = DraggablePoint2D(in1,in2,in3,in4,in5)
            %DRAGGABLEPOINT constructor. Use either:
            % DraggablePoint(x0,y0)
            % DraggablePoint(ax,x0,y0)
            % DraggablePoint(ax,x0,y0,moveFunc)

            if nargin == 2
                obj.lineHandle = plot(gca,in1,in2,'o');
            elseif nargin == 3
                obj.lineHandle = plot(in1,in2,in3,'o');
            elseif nargin == 4
                obj.lineHandle = plot(in1,in2,in3,'o');
                obj.funcHandle = in4;
            elseif nargin == 5
                obj.lineHandle = plot(in1,in2,in3,'o');
                obj.funcHandle = in4;
                obj.restrictToAxis = in5;
            else
                error("Incorrect number of inputs. Use on of the default syntaxes.")
            end

            % Set the callback after the line object has been created
            obj.lineHandle.ButtonDownFcn = @obj.plotClick;
        end

        function plotClick(obj,src,event)
            % Turn off all interactions while dragging is under way
            pan(src.Parent,'off')
            zoom(src.Parent,'off')
            rotate3d(src.Parent,'off')
            brush(src.Parent,'off')

            % Temporarily set the mode to manual
            origModes = {obj.lineHandle.Parent.XLimMode, obj.lineHandle.Parent.YLimMode};
            obj.lineHandle.Parent.XLimMode = "manual";
            obj.lineHandle.Parent.YLimMode = "manual";
            
            % Handle clicks on the plot objects
            set(src,"Selected","on")
            set(gcbf,"WindowButtonMotionFcn",{@obj.objMove,src})
            set(gcbf,"WindowButtonUpFcn",{@obj.objStop,src,origModes})            
        end
    
        % Moves an object around the plot (used to move the poles/zeros)
        function objMove(obj,src,event,plotSrc)
            % Get the current point
            currentPoint = plotSrc.Parent.CurrentPoint;
            x = currentPoint(1,1);
            y = currentPoint(1,2);
            
            % Do not allow the object to move outside the window
            if(~(obj.restrictToAxis == 2))
                xlims = plotSrc.Parent.XLim;
                if(x > xlims(2))
                    x = xlims(2);
                elseif (x < xlims(1))
                    x = xlims(1);
                end
                plotSrc.XData = x;
            end
            if(~(obj.restrictToAxis == 1))
                ylims = plotSrc.Parent.YLim;
                if(y > ylims(2))
                    y = ylims(2);
                elseif(y < ylims(1))
                    y = ylims(1);
                end
                plotSrc.YData = y;
            end

            % Execute the function handle
            if(~isempty(obj.funcHandle))
                obj.funcHandle(x,y)
            end

            % This gives time for the graph to update and is faster than
            % drawnow, because it doesn't update the UI, only the plot
            pause(0)
        end
        
        % Stop moving the object around
        function objStop(obj,src,event,plotSrc,origModes)
            obj.objMove(src,event,plotSrc);
            % remove the callbacks and unselect
            set(gcbf,"WindowButtonMotionFcn","")
            set(gcbf,"WindowButtonUpFcn","")
            set(plotSrc,"Selected","off") 

            % Update the mode
            obj.lineHandle.Parent.XLimMode = origModes{1};
            obj.lineHandle.Parent.YLimMode = origModes{2};
            
            % Update the plot/UI
            drawnow
        end

        % Retrieve the position of the object
        function [x,y] = getPos(obj)
            x = obj.lineHandle.XData;
            y = obj.lineHandle.YData;
        end
 
    end
end

