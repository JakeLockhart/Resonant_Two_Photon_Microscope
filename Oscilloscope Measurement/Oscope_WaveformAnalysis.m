classdef Oscope_WaveformAnalysis
    properties
        % Loaded Data Porpoerties
        Signals (1,:) string 
        Lookup struct = struct()
        Oscope struct = struct()
        Bounds struct = struct( ...
            'LowerBound', 0, ...
            'UpperBound', 0 ...
        )

        % Cross Correlation Properties
        CC struct = struct( ...
            'Xc', struct(), ...
            'Lags', struct(), ...
            'Shift', struct() ...
        )

        % Voltage Steps Properties
        VS struct = struct( ...
            'BinCenters', struct(), ...
            'Peaks', struct(), ...
            'Counts', struct() ...
        )
    end

    methods
        %%  Constructor - Create an object based on oscilloscope data, the types of signals, and the bounds of a single pulse
        function obj = Oscope_WaveformAnalysis(Signals, LoadedData)
            obj.Signals = Signals;
            obj.Lookup = LoadedData.Lookup;
            obj.Oscope = LoadedData.Oscope;
            obj.Bounds.LowerBound = LoadedData.Bounds.LowerBound;
            obj.Bounds.UpperBound = LoadedData.Bounds.UpperBound;

            fprintf("Automated Analysis in constructor function\n\tCrossCorrelation\n\tVoltageSteps\n")
            obj = obj.CrossCorrelation;
            obj = obj.VoltageSteps;
        end

        %%  Determine the cross correlation, lags, and shift between each recorded oscilloscope signal 
        function obj = CrossCorrelation(obj)
            % CrossCorrelation() 
            %   Compute the cross correlation between all signals within the class Oscope_WaveformAnalysis
            % Syntax:
            %   obj = CrossCorrelation(obj)
            % Description:
            %   This function determines the correlation coefficient and lag between signals as well as the shift needed to align the two signals.
            %   Correlation is based on the mean-subtracted voltage signal. Matlab function xcorr() is used to determine the normalized (by standard
            %       deviation - 'coeff') correlation coefficient and lag.
            %   Organizes outputs into three structures: Xc, Lags, Shift. There are sub-structures that contain the name of the two signals being 
            %       compared to one another.
            % Input:
            %   obj - Independent from other functions
            % Output:
            %   obj.{Xc, Lags, Shift}.(Signal(i)_Signal(j))
            Voltage = obj.Oscope.Voltage(:, obj.Bounds.LowerBound:obj.Bounds.UpperBound);
            Voltage = Voltage - mean(Voltage,2);

            TotalSignals = size(obj.Signals, 2);
            
            obj.CC.Xc = struct();
            obj.CC.Lags = struct();
            obj.CC.Shift = struct();

            for i = 1:TotalSignals-1
                for j = i+1:TotalSignals
                    Signal = sprintf('%s_%s', obj.Signals{i}, obj.Signals{j});
                    Signal = matlab.lang.makeValidName(Signal);

                    [obj.CC.Xc.(Signal), obj.CC.Lags.(Signal)] = xcorr(Voltage(i,:), Voltage(j,:), 'coeff');
                    [~, idx] = max(obj.CC.Xc.(Signal));
                    obj.CC.Shift.(Signal) = obj.CC.Lags.(Signal)(idx);
                end
            end
        end

        %%  Determine bin size, obj.Count and obj.Peaks of the recorded oscilloscope data using histograms
        function obj = VoltageSteps(obj, Signal)
            % VoltageSteps()
            % Syntax:
            %   obj = VoltageSteps(obj, Signal)
            % Description:
            %   This function creates histogram data for oscilloscope signals in order to determine LOW/HIGH signals and signal steps based 
            %       on peak counts.
            %   Voltage from oscilloscope is collected for a signal, and bin sizes for the histogram are determined based on the number of 
            %       samples within the voltage signal. Matlab function histcounts() then determines the counts and binedges for the voltage
            %       data. Matlab function findpeaks() is used to determine the LOW/HIGH signals and their steps, however findpeaks() only 
            %       detects local maxima of the counts from histcounts(). idx structure is used to find edge conditions (global LOW and global
            %       HIGH). Only unique voltage peaks are passed through. 
            % Input:
            %   obj - Independent from other functions
            %   Signal - If provided, function computes histogram of solely that signal.
            %          - If not provided, function computes histogram for all signals within parent obj.
            % Output:
            %   obj.{Peaks, Counts}.(Signal)
            if nargin < 2 || isempty(Signal) 
                for i = 1:length(obj.Signals)
                    obj = obj.VoltageSteps(obj.Signals(i));
                end
                return
            end

            if isstring(Signal) && length(Signal) > 1
                for i = 1:length(Signal)
                    obj = obj.VoltageSteps(Signal(i));
                end
                return
            end

            FieldName = matlab.lang.makeValidName(Signal);            
            idx = find(strcmp(obj.Signals, Signal), 1);
            if isempty(idx)
                error('%s is not found within signal list', Signal);
            end

            Voltage = obj.Oscope.Voltage(idx,:);
            TotalBins = round(sqrt(size(Voltage,2)));
            [HistCounts, BinEdge] = histcounts(Voltage,TotalBins);
            obj.VS.BinCenters.(FieldName) = (BinEdge(1:end-1) + BinEdge(2:end))/2;

            HistCounts(HistCounts == 1) = 0;

            idx = struct();
            [~, idx.Leading] = max(HistCounts);
            [~, idx.Standard] = findpeaks(HistCounts);
            [~, idx.Trailing] = max(HistCounts(idx.Standard(end):end));
            idx.Trailing = idx.Standard(end) + idx.Trailing - 1;
            [~, idx.Overall] = max(obj.VS.BinCenters.(FieldName));
            idxList = [idx.Standard, idx.Leading, idx.Trailing, idx.Overall];

            AllPeaks = obj.VS.BinCenters.(FieldName)(idxList);
            AllCounts = HistCounts(idxList);

            [UniquePeaks, idx.Unique] = unique(AllPeaks, 'stable');
            UniqueCounts = AllCounts(idx.Unique);

            obj.VS.Peaks.(FieldName) = UniquePeaks;
            obj.VS.Counts.(FieldName) = UniqueCounts;
        end
    end

    methods (Static)
        function LoadedData = LoadData(FileType, SearchMode, ConstantAddress, DisplayLayout, SignalAlignment, TotalTiles)
            arguments
                FileType char {mustBeMember(FileType, {'csv', 'xlsx', 'txt', 'tiff', 'mdf'})} = 'csv'
                SearchMode char {mustBeMember(SearchMode, {'SingleFolder', 'AllSubFolders', 'TroubleShoot'})} = 'SingleFolder'
                ConstantAddress char = ''
                DisplayLayout (1,:) char {mustBeMember(DisplayLayout, {'Separate', 'Overlay'})} = 'Separate'
                SignalAlignment (1,:) char {mustBeMember(SignalAlignment, {'RawData', 'AlignedData'})} = 'RawData'
                TotalTiles (1,1) {mustBeInteger, mustBePositive} = 1
            end

            LoadedData.Lookup = FileLookup(FileType, SearchMode, ConstantAddress);
            LoadedData.Oscope = ReadOscope(LoadedData.Lookup);

            if nargin < 6 || isempty(TotalTiles)
                TotalTiles = LoadedData.Lookup.FileCount;
            end
            [LowerBound, UpperBound, Canceled] = UserDefinedPeaks(LoadedData.Lookup, TotalTiles, DisplayLayout, SignalAlignment);
            LoadedData.Bounds.LowerBound = LowerBound;
            LoadedData.Bounds.UpperBound = UpperBound;
            LoadedData.Bounds.Canceled = Canceled;
        end
    end
end