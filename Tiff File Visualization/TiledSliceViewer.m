
function [ImageInfo, FigureWindow] = TiledSliceViewer(ImageStacks, Rows)
    % TiledSliceViewer()
    %   Displays multiple 3d image stacks a tiled 2d slice viewers with sliders. 
    %   Created by: jsl5865
    %
    % Syntax:
    %   [ImageInfo, FigureWindow] = TiledSliceViewer(ImageStacks, Rows)
    % Description:
    %   This function creates a UI figure window that displays each 3d stack as a 3d slice in a grid layout
    %       each slice has an associated slider below it to scroll through ths slices of that stack.
    %   The user can interact with each image stack independently.
    %   Three UI buttons are created in the UI figure:
    %       "Get Indices" - Confrims and returns the current slice indices for each stack
    %       "Reset" - Resets all stacks to the first slice
    %       "Cancel" - Closes the UI figure without returning indices
    % Input: 
    %   ImageStacks - Cell array of 3d numeric arrays (.tiff file image stacks). Each stack should be of the
    %                 form ImageStacks = [Pixel Height, Pixel Width, Total Slices]
    %   Rows        - Positive integer to specify the number of rows in the layout. This function does not 
    %                 create a true tiledlayout() so this is a work-around.
    % Output:
    %   ImageInfo   - Struct with metadata about each stack, including:
    %                   StackName       - Cell array of stack names ("Stack 1", "Stack 2", etc.)
    %                   StackSize       - Cell array of [height, width] for each stack
    %                   TotalFrames     - Cell array with number of slices in each stack
    %                   ReferencePlane  - Cell array with the selected slice index for each stack (updated after user selection)
    %   FigureWindow - Handle to the created UIFigure containing the tiled slice viewers and sliders.

    arguments
        ImageStacks
        Rows {mustBeNumeric, mustBePositive} = 1
    end

    TotalStacks = length(ImageStacks);
    for i = 1:TotalStacks
        ImageInfo.StackName{i} = "Stack "+num2str(i);
        ImageInfo.StackSize{i} = size(ImageStacks{i}, [1,2]);
        ImageInfo.TotalFrames{i} = size(ImageStacks{i}, 3);
        ImageInfo.ReferencePlane{i} = nan;
    end
    ReferencePlanes = nan(1, TotalStacks);
    
    FigureWindow = uifigure('Name', "Tiled SliceViewer");

    Columns = ceil(TotalStacks / Rows);
    Layout = uigridlayout(FigureWindow, [Rows*2+1, Columns]);
    Layout.RowHeight = [repmat({'1x', 'fit'}, 1, Rows), {'fit'}];
    Layout.ColumnWidth = repmat({'1x'}, 1, Columns);

    ax = gobjects(TotalStacks, 1);
    Image = gobjects(TotalStacks, 1);
    Slider = gobjects(TotalStacks, 1);

    for i = 1:TotalStacks
        Row = 2 * floor((i-1) / Columns) + 1;
        Column = mod(i-1, Columns) + 1;

        ax(i) = uiaxes(Layout);
        ax(i).Layout.Row = Row;
        ax(i).Layout.Column = Column;
        title(ax(i), ImageInfo.StackName{i});

        Image(i) = imshow(ImageStacks{i}(:,:,1), ...
                       "Parent", ax(i), ...
                       "DisplayRange", []);

        Slider(i) = uislider(Layout, ...
                            "Limits", [1, ImageInfo.TotalFrames{i}], ...
                            "Value", 1, ...
                            "MinorTicks", [], ...
                            'ValueChangedFcn', @(sld, ~) updateSlice(i), ...
                            'ValueChangingFcn', @(sld, event) updateSlice(i, event.Value));
        Slider(i).Layout.Row = Row+1;
        Slider(i).Layout.Column = Column;
    end

    

    GetButton = uibutton(Layout, ...
        'Text', 'Get Indices', ...
        'ButtonPushedFcn', @(btn,~) getIndices());
    GetButton.Layout.Row = Rows*2 + 1;
    GetButton.Layout.Column = 1;

    ResetButton = uibutton(Layout, ...
        'Text', 'Reset', ...
        'ButtonPushedFcn', @(btn,~) resetSliders());
    ResetButton.Layout.Row = Rows*2 + 1;
    ResetButton.Layout.Column = 2;

    CancelButton = uibutton(Layout, ...
        'Text', 'Cancel', ...
        'ButtonPushedFcn', @(btn,~) cancelWindow());
    CancelButton.Layout.Row = Rows*2 + 1;
    CancelButton.Layout.Column = 3;

    uiwait(FigureWindow);

    if isvalid(FigureWindow) && isprop(FigureWindow, 'UserData')
        temp = FigureWindow.UserData;
        if isnumeric(temp) && numel(temp) == TotalStacks
            ReferencePlanes = temp;
        end
    end

    for i = 1:TotalStacks
        ImageInfo.ReferencePlane{i} = ReferencePlanes(i);
    end

    if isvalid(FigureWindow)
        close(FigureWindow);
    end

    function updateSlice(idx, val)
        if nargin < 2
            val = Slider(idx).Value;
        end
        sliceIdx = round(val);
        Image(idx).CData = ImageStacks{idx}(:,:,sliceIdx);
    end

    function getIndices()
        for j = 1:TotalStacks
            ReferencePlanes(j) = round(Slider(j).Value);
        end
        FigureWindow.UserData = ReferencePlanes;
        uiresume(FigureWindow);
    end

    function resetSliders()
        for j = 1:TotalStacks
            Slider(j).Value = 1;
            updateSlice(j, 1);
        end
    end

    function cancelWindow()
        FigureWindow.UserData = [];
        uiresume(FigureWindow);
    end

end

