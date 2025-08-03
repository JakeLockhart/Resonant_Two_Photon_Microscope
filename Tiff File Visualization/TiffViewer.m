classdef TiffViewer
    properties
        FilePath
        ZStack
        FigureHandles struct = struct('SliceViewHandle', [], ...
                                      'SliceViewFigure', [], ...
                                      'VolumeViewHandle', [] ...
                                      )
    end

    methods
        function obj = TiffViewer()
            [obj.FilePath, obj.ZStack] = TiffViewer.LoadTiff();
        end

        function obj = SliceView(obj)
            TempHandle = sliceViewer(obj.ZStack);
            TempHandle.Parent.Title = sprintf("File Path: %s", obj.FilePath);

            obj.FigureHandles.SliceViewHandle = TempHandle;
            obj.FigureHandles.SliceViewFigure = ancestor(TempHandle, 'figure');
        end

        function obj = VolumeView(obj)
            Window.Figure = uifigure('Name', '3D Volume Viewer', 'Position', [100 100 800 600]);
            Window.Viewer = viewer3d(Window.Figure, 'Position', [20 150 760 430]);
            
            Window.Handle = volshow(obj.ZStack, "Parent", Window.Viewer, "RenderingStyle", "VolumeRendering");
            Window.Viewer.BackgroundColor = [0, 0, 0];

            obj.FigureHandles.VolumeViewHandle = Window;
        end

        function obj = AdjustBrightnessContrast(obj)
            origStack = obj.ZStack;
            minVal = double(min(origStack(:)));
            maxVal = double(max(origStack(:)));
            defaultMin = minVal;
            defaultMax = maxVal;
            defaultBrightness = 0;
            defaultContrast = 1;
            minWindow = isa(origStack, 'uint8') * 1 + ~isa(origStack, 'uint8') * 10;

            % Detect open viewer
            isSliceOpen = isfield(obj.FigureHandles, 'SliceViewFigure') && ...
                ~isempty(obj.FigureHandles.SliceViewFigure) && ...
                isgraphics(obj.FigureHandles.SliceViewFigure, 'figure') && ...
                strcmp(get(obj.FigureHandles.SliceViewFigure, 'Visible'), 'on');
            isVolumeOpen = ~isempty(obj.FigureHandles.VolumeViewHandle) && ...
                isfield(obj.FigureHandles.VolumeViewHandle, 'Figure') && ...
                isgraphics(obj.FigureHandles.VolumeViewHandle.Figure, 'figure') && ...
                strcmp(get(obj.FigureHandles.VolumeViewHandle.Figure, 'Visible'), 'on');
            if isSliceOpen && ~isVolumeOpen
                viewType = 'slice';
            elseif isVolumeOpen && ~isSliceOpen
                viewType = 'volume';
            elseif isSliceOpen && isVolumeOpen
                viewType = 'volume';
            else
                uialert(uifigure, 'No viewer window is open. Open a SliceView or VolumeView first.', 'No Viewer');
                return;
            end

            UIFig = uifigure('Name', 'Adjust Brightness/Contrast', 'Position', [200 200 350 300]);
            uilabel(UIFig, 'Position', [20 250 60 22], 'Text', 'Min');
            minSlider = uislider(UIFig, 'Position', [80 260 200 3], 'Limits', [minVal maxVal-minWindow], 'Value', defaultMin);
            uilabel(UIFig, 'Position', [20 200 60 22], 'Text', 'Max');
            maxSlider = uislider(UIFig, 'Position', [80 210 200 3], 'Limits', [minVal+minWindow maxVal], 'Value', defaultMax);
            uilabel(UIFig, 'Position', [20 150 60 22], 'Text', 'Brightness');
            brightnessSlider = uislider(UIFig, 'Position', [80 160 200 3], 'Limits', [0 1], 'Value', 0.5);
            uilabel(UIFig, 'Position', [20 100 60 22], 'Text', 'Contrast');
            contrastSlider = uislider(UIFig, 'Position', [80 110 200 3], 'Limits', [0.1 3], 'Value', defaultContrast);

            function updateDisplay(~, ~)
                if isinteger(origStack)
                    minSlider.Value = round(minSlider.Value);
                    maxSlider.Value = round(maxSlider.Value);
                end
                minI = minSlider.Value;
                maxI = maxSlider.Value;
                if maxI - minI < minWindow
                    if minI + minWindow <= maxVal
                        maxI = minI + minWindow;
                        maxSlider.Value = maxI;
                    else
                        minI = maxI - minWindow;
                        minSlider.Value = minI;
                    end
                end
                brightness = brightnessSlider.Value;
                contrast = contrastSlider.Value;
                if minI == defaultMin && maxI == defaultMax && brightness == 0.5 && contrast == 1
                    adjStack = origStack;
                else
                    adjStack = double(origStack);
                    adjStack = min(max(adjStack, minI), maxI);
                    adjStack = (adjStack - minI) * contrast + (brightness-0.5) * (maxI - minI);
                    adjStack = adjStack / (maxI - minI);
                    adjStack = max(min(adjStack, 1), 0);
                    adjStack = cast(adjStack * double(intmax(class(origStack))), class(origStack));
                end
                if strcmpi(viewType, 'slice')
                    % No live update for slice view
                elseif strcmpi(viewType, 'volume')
                    if isempty(obj.FigureHandles.VolumeViewHandle) || ~isvalid(obj.FigureHandles.VolumeViewHandle.Figure)
                        obj = obj.VolumeView();
                    end
                    obj.FigureHandles.VolumeViewHandle.Handle.Data = adjStack;
                end
            end

            % Add listeners for smooth dragging and snapping
            addlistener(minSlider, 'ValueChanging', @(src, evt) updateDisplay());
            addlistener(maxSlider, 'ValueChanging', @(src, evt) updateDisplay());
            addlistener(brightnessSlider, 'ValueChanging', @(src, evt) updateDisplay());
            addlistener(contrastSlider, 'ValueChanging', @(src, evt) updateDisplay());

            addlistener(minSlider, 'ValueChanged', @(src, evt) snapAndUpdate('min'));
            addlistener(maxSlider, 'ValueChanged', @(src, evt) snapAndUpdate('max'));

            function snapAndUpdate(which)
                if isinteger(origStack)
                    minSlider.Value = round(minSlider.Value);
                    maxSlider.Value = round(maxSlider.Value);
                end
                minI = minSlider.Value;
                maxI = maxSlider.Value;
                if maxI - minI < minWindow
                    if strcmp(which, 'min')
                        minSlider.Value = maxI - minWindow;
                    else
                        maxSlider.Value = minI + minWindow;
                    end
                end
                updateDisplay();
            end

            updateDisplay();

            resetBtn = uibutton(UIFig, 'push', 'Text', 'Reset', 'Position', [60 30 80 30]);
            closeBtn = uibutton(UIFig, 'push', 'Text', 'Close', 'Position', [200 30 80 30]);
            resetBtn.ButtonPushedFcn = @(src, event) resetSliders();
            function resetSliders()
                minSlider.Value = defaultMin;
                maxSlider.Value = defaultMax;
                brightnessSlider.Value = defaultBrightness;
                contrastSlider.Value = defaultContrast;
                updateDisplay();
            end
            closeBtn.ButtonPushedFcn = @(src, event) closeAll();
            function closeAll()
                close(UIFig);
                if strcmpi(viewType, 'slice')
                    if ~isempty(obj.FigureHandles.SliceViewHandle) && isvalid(obj.FigureHandles.SliceViewHandle)
                        close(ancestor(obj.FigureHandles.SliceViewHandle, 'figure'));
                        obj.FigureHandles.SliceViewHandle = [];
                    end
                elseif strcmpi(viewType, 'volume')
                    if ~isempty(obj.FigureHandles.VolumeViewHandle) && isvalid(obj.FigureHandles.VolumeViewHandle.Figure)
                        close(obj.FigureHandles.VolumeViewHandle.Figure);
                        obj.FigureHandles.VolumeViewHandle = [];
                    end
                end
            end
        end

    end

    methods(Access = private, Static)
        function [FilePath, ZStack] = LoadTiff()
            [FileName, Directory] = uigetfile('*.tif', "Choose a multi-paged tiff stack...");
            if isequal(FileName, 0)
                error("No .tiff file selected");
            end

            FilePath = fullfile(Directory, FileName);

            TiffInfo = imfinfo(FilePath);
            
            TotalSlices = length(TiffInfo);
            DemoSlice = imread(FilePath, 1);
            ZStack = zeros([size(DemoSlice), TotalSlices], class(DemoSlice));

            for i = 1:TotalSlices
                ZStack(:,:,i) = imread(FilePath, i);
            end
        end

    end
end


