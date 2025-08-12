function PowerMeter = PowerMeasurement(SaveResults, ReferencePower)
    % <Documentation>
        % PowerMeasurement()
        %   Import, process, and (optionally) save data from ThorLabs Power Meter
        %   Created by: jsl5865
        %   
        % Syntax:
        %   PowerMeter = PowerMeasurement(SaveResults, ReferencePower)
        %
        % Description:
        %   
        % Input:
        %   SaveResults     - Character specifying whether to save processed results:
        %                     'Save'  : Write output data to files
        %                     'xSave' : Do not save output files.
        %   ReferencePower  - Numeric vector specifying reference power values used for output matching.
        %   
        % Output:
        %   PowerMeter    - Cell array of structs, each containing:
        %                   Name        : Filename 
        %                   Header      : Raw header lines from the file.
        %                   Wavelength  : Laser wavelength extracted from the header (nm).
        %                   RawData     : Table of imported raw power data.
        %                   Data        : Struct with processed fields:
        %                                   TimeStamp       - Time relative to start (seconds).
        %                                   Power           - Power values in mW.
        %                                   PeakPower       - Detected peak power values.
        %                                   PeakTimeStamp   - Timestamps corresponding to peaks.
        %                                   Fit             - Struct with polynomial fit results (Power, Time).
        %                   Output      : (If saved) Matrix combining ReferencePower and processed power values.
    % <End Documentation>

    arguments
        SaveResults char {mustBeMember(SaveResults, {'Save', 'xSave'})} = 'xSave'
        ReferencePower (1,:) double = [0:5:70, 80:10:100]
    end

    %% Initialization
        addpath("C:\Workspace\LabScripts\General_Functions");
        zap
        DirectoryInfo = FileLookup("txt", "AllSubFolders");

    %% Validate file headers to confirm .txt file originates from ThorLabs power meter 
        ResonantHeader = 'PM100D  SN:P0008073  Firmware: 2.4.0 -- Sensor: S425C  SN:1800583';
        GalvoHeader = 'PM100D  SN:P0019315  Firmware: 2.5.0 -- Sensor: S310C  SN:1004145';
        ValidHeader = {ResonantHeader, GalvoHeader};
        PowerMeter = cell(1, DirectoryInfo.FileCount);

    %% Collect power meter data
        for i = 1:DirectoryInfo.FileCount
            FileIdentifier = fopen(DirectoryInfo.Path(i), 'rt');
            Header1 = fgetl(FileIdentifier);
            Header2 = fgetl(FileIdentifier);
            fclose(FileIdentifier);

            if ~ismember(Header1, ValidHeader)
                continue
            else
                Wavelength_Token = regexp(Header2, 'Wave (\d+)nm', 'tokens');
                Wavelength = str2double(Wavelength_Token{1}{1});

                ImportOptions = detectImportOptions(DirectoryInfo.Path(i), "FileType", "text", "NumHeaderLines", 2, "Delimiter", '\t');
                ImportOptions.VariableNames = {'TimeStamp', 'Power', 'Unit'};
                ImportOptions = setvaropts(ImportOptions, 'TimeStamp', 'InputFormat', 'MM/dd/yyyy hh:mm:ss.SSS a');
                TempFile = readtable(DirectoryInfo.Path(i), ImportOptions);

                [~, PowerMeter{i}.Name, ~] = fileparts(DirectoryInfo.Path(i));
                PowerMeter{i}.Header = sprintf('%s\n%s', Header1, Header2);
                PowerMeter{i}.Wavelength = Wavelength;
                PowerMeter{i}.RawData = TempFile;
            end
        end
        PowerMeter = PowerMeter(~cellfun(@isempty, PowerMeter));

    %% Process power meter data
        for i = 1:length(PowerMeter)
            %% Create time stamp from 0s->end and convert power data to mW
                StartTime = PowerMeter{i}.RawData(1,'TimeStamp');
                PowerMeter{i}.Data.TimeStamp = table2array(PowerMeter{i}.RawData(:, 'TimeStamp') - StartTime);
                PowerMeter{i}.Data.Power = table2array(PowerMeter{i}.RawData(:, 'Power') .* 1000);

            %% Define parameters for findpeaks
                MinPeakProminence = 0.01 * range(PowerMeter{i}.Data.Power);

                SamplingInverval = seconds(median(diff(PowerMeter{i}.RawData.TimeStamp)));
                ExpectedPulseWidth = 3;
                MinPeakDistance = round(ExpectedPulseWidth / SamplingInverval);

            %% Identify peaks
                [Peak, Index] = findpeaks(PowerMeter{i}.Data.Power, "MinPeakProminence", MinPeakProminence, "MinPeakDistance", MinPeakDistance);
                PowerMeter{i}.Data.PeakPower = Peak;
                PowerMeter{i}.Data.PeakTimeStamp = PowerMeter{i}.Data.TimeStamp(Index);
            
            %% Polynomial fit peak values
                Time = seconds(PowerMeter{i}.Data.PeakTimeStamp - PowerMeter{i}.Data.PeakTimeStamp(1));
                Power = PowerMeter{i}.Data.PeakPower;
                Degree = 5;

                [PolyCoeff, FitInfo, Mu] = polyfit(Time, Power, Degree);

                SmoothTime = linspace(min(Time), max(Time), 101);
                PowerMeter{i}.Data.Fit.Power = polyval(PolyCoeff, SmoothTime, FitInfo, Mu);
                PowerMeter{i}.Data.Fit.Time = PowerMeter{i}.Data.PeakTimeStamp(1) + seconds(SmoothTime);

            %% Identify power at reference inputs
            figure
            hold on
            plot(PowerMeter{i}.Data.TimeStamp, PowerMeter{i}.Data.Power, 'b-', ...
                'DisplayName', 'Power');
            plot(PowerMeter{i}.Data.Fit.Time, PowerMeter{i}.Data.Fit.Power, 'k-', 'LineWidth', 2, ...
                'DisplayName', sprintf('Polyfit Peaks (deg %d)', Degree));
            plot(PowerMeter{i}.Data.Fit.Time, PowerMeter{i}.Data.Fit.Power, 'r.');
            axis tight
            xlabel('Time [hh:mm:ss]')
            ylabel('Power [mW]')
            title(sprintf('Laser Power Measurement\n%s\nWavelength: %d', PowerMeter{i}.Name, PowerMeter{i}.Wavelength), "Interpreter", "none")

        end

    %% Output power meter results
        switch SaveResults
            case 'Save'
                for i = 1:length(PowerMeter)
                    PowerMeter{i}.Output = [ReferencePower', PowerMeter{i}.Data.MScan_Power'];
                    writematrix(PowerMeter{i}.Output, sprintf('Power Measurement (%dnm)', PowerMeter{i}.Wavelength))
                end
            case 'xSave'
                return
        end
end