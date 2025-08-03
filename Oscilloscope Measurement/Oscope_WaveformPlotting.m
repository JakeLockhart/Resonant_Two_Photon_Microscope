classdef Oscope_WaveformPlotting < Oscope_WaveformAnalysis
    properties
        ColorMap (:,3) double = [0 0 0]
    end

    methods
        %% SuperConstructor - Inherit the objecs from WaveformAnalysis
        function obj = Oscope_WaveformPlotting(Signals, LoadedData)
            obj@Oscope_WaveformAnalysis(Signals, LoadedData);
            obj.ColorMap = hsv(obj.Lookup.FileCount);
        end

        function PlotRawSignal(obj)
            figure()

            t = tiledlayout(obj.Lookup.FileCount, 1);
            title(t, "Raw Voltage Signal", 'Color', 'White')
            xlabel(t, "Time [ms]", 'Color', 'White')
            ylabel(t, "Voltage [V]", 'Color', 'White')

            set(gcf, 'Color', [0, 0, 0]);

            for i = 1:obj.Lookup.FileCount
                nexttile(t, i); hold on;
                title(obj.Signals(i), 'Color', 'White')
                plot(obj.Oscope.Time(i,:), obj.Oscope.Voltage(i,:), "Color", obj.ColorMap(i,:))
                set(gca, 'Color', [0 0 0]);  set(gca, 'XColor', 'white', 'YColor', 'white')
                axis tight
            end
        end

        function PlotCrossCorrelation(obj)
            Time = obj.Oscope.Time;
            Voltage = obj.Oscope.Voltage;
            LB = obj.Bounds.LowerBound;
            UB = obj.Bounds.UpperBound;

            TotalSignals = length(obj.Signals);
            DisplayGroups = 3;

            [~, ~, Children] = NestedTiles(3, {2, 2, 2}, "VerticalLayout", "HorizontalLayout", [0 0 0]);

            for i = 1:DisplayGroups
                ax = nexttile(Children(i));
                hold(ax, 'on');
                set(ax, "Color", [0, 0, 0], 'XColor', 'White', 'YColor', 'White');

                switch i
                    case 1
                        for j = 1:TotalSignals
                            plot(ax, Time(j,:), Voltage(j,:), "Color", obj.ColorMap(j,:));
                        end
                        xline(ax, [Time(1,LB), Time(1,UB)], "--w");
                    case 2
                        for j = 1:TotalSignals
                            plot(ax, Time(j,LB:UB), Voltage(j,LB:UB), "Color", obj.ColorMap(j,:));
                        end
                    case 3
                        for j = 1:TotalSignals
                            Fields = fieldnames(obj.CC.Xc);
                            Xc = obj.CC.Xc.(Fields{j});
                            Lags = obj.CC.Lags.(Fields{j});
                            Shift = obj.CC.Shift.(Fields{j});

                            plot(ax, Lags, Xc)
                            xline(ax, Shift)
                        end
                end
                axis(ax, 'tight')
            end
        end



    end
    
end

%        function PlotCrossCorrelation(obj)
%            LB = obj.Bounds.LowerBound
%            UB = obj.Bounds.UpperBound
%            DisplayGroups = 3
%            SignalsCount = length(obj.Signals)
%            PairSignalsCount = (SignalsCount * (SignalsCount - 1)) / 2
%            PairSignalsCount = num2cell(PairSignalsCount * ones(1,DisplayGroups))
%
%            [Figure_CrossCorrelation, Parent, Children] = NestedTiles(DisplayGroups, PairSignalsCount)
% 
%            for i = 1:DisplayGroups%
%                ChildPlot = PairSignalsCount{i};
%                for j = 1:ChildPlot
%                    ax = nexttile(Children(i));
%                    plot(ax, rand(10,1));
%                    title(ax, sprintf("Tile %d - subplot %d", i, j));
%                end
%            end
%
%        end