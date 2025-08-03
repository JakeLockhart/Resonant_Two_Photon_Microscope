clear; clc; format short; format compact;

addpath('C:\Workspace\LabScripts\Functions')
Lookup = FileLookup('csv');
[LowerBound, UpperBound, Canceled] = UserDefinedPeaks(Lookup, 1, 'all', 'UseAligned');
Oscope = ReadOscope(Lookup);

%% Cross Correlation to Sync Waveforms
for i = 1:Lookup.FileCount
    [xc, lags] = xcorr(Oscope.Voltage(end,:), Oscope.Voltage(i,:));
    [~, Index] = max(xc);
    Shift = lags(Index);
    Oscope.AlignedVoltage(i,:) = circshift(Oscope.Voltage(i,:), Shift);
end

%% Histogram & High/Low Signal Data Analysis
WF_T.TotalBins = linspace(0, max(max(1.25*Oscope.Voltage)), Lookup.FileCount*10);
for i = 1:Lookup.FileCount
    [Count, BinEdge] = histcounts(Oscope.AlignedVoltage(i,:), WF_T.TotalBins);
    WF_T.Count(i,:) = Count;
    WF_T.BinEdge(i,:) = BinEdge;
    WF_T.BinCenter(i,:) = (WF_T.BinEdge(i, 1:end-1) + WF_T.BinEdge(i, 2:end))/ 2;

    WF_S.TotalBins = sqrt(size(Oscope.AlignedVoltage(i,:),2));
    [Count, BinEdge] = histcounts(Oscope.AlignedVoltage(i,:), WF_S.TotalBins);
    WF_S.Count(i,:) = Count;
    WF_S.BinEdge(i,:) = BinEdge;
    WF_S.BinCenter(i,:) = (WF_S.BinEdge(i, 1:end-1) + WF_S.BinEdge(i, 2:end))/ 2;

    LowSignal.Count(i,:) = WF_S.Count(i, 1:round(end/2));
    LowSignal.BinEdge(i,:) = WF_S.BinEdge(i, 1:round(end/2));
    LowSignal.BinCenter(i,:) = WF_S.BinCenter(i, 1:round(end/2));
    [LowPeak, LowLocation] = findpeaks(LowSignal.Count(i,:));
    [~, Index] = max(LowPeak);
    LowSignal.Voltage(i,:) = LowSignal.BinCenter(i, LowLocation(Index));

    HighSignal.Count(i,:) = WF_S.Count(i, round(end/2):end);
    HighSignal.BinEdge(i,:) = WF_S.BinEdge(i, round(end/2):end);
    HighSignal.BinCenter(i,:) = WF_S.BinCenter(i, round(end/2):end);
    [HighPeak, HighLocation] = findpeaks(HighSignal.Count(i,:));
    [~, Index] = max(HighPeak);
    HighSignal.Voltage(i,:) = HighSignal.BinCenter(i, HighLocation(Index));
end

%% Waveform Characteristics
for i = 1:Lookup.FileCount
    Oscope.BinarySignal(i,:) = Oscope.AlignedVoltage(i,:) > (LowSignal.Voltage(i) + HighSignal.Voltage(i))/2;
    [xc, lags] = xcorr(Oscope.BinarySignal(end,:), Oscope.BinarySignal(i,:));
    [~, Index] = max(xc);
    Shift = lags(Index);
    Oscope.BinarySignal(i,:) = circshift(Oscope.BinarySignal(i,:), -Shift);

    pw = pulsewidth(double(Oscope.BinarySignal(i,:)), Oscope.Time(i,:));
    pp = pulseperiod(double(Oscope.BinarySignal(i,:)), Oscope.Time(i,:));
    rt = risetime(double(Oscope.BinarySignal(i,:)), Oscope.Time(i,:));
    ft = falltime(double(Oscope.BinarySignal(i,:)), Oscope.Time(i,:));
    Waveform.Local.PulseWidth(i) = mean(pw);
    Waveform.Local.PulsePeriod(i) = mean(pp);
    Waveform.Local.RiseTime(i) = mean(rt);
    Waveform.Local.FallTime(i) = mean(ft);
end
Waveform.Global.PulseWidth = mean(pw([4,end]));
Waveform.Global.PulsePeriod = mean(pp([4,end]));
Waveform.Global.PulseGap = Waveform.Global.PulsePeriod - Waveform.Global.PulseWidth;
Waveform.Global.RiseTime = mean(rt([4,end]));
Waveform.Global.FallTime = mean(ft([4,end]));

%% Plot Initial Signal Processing
figure(1)
t = tiledlayout(6,6);
title(t, "MScan Signal Processing", 'Color', 'white')
ColorMap = hsv(Lookup.FileCount);
Gap = Oscope.Time(1,UpperBound) - Oscope.Time(1,LowerBound);
set(gcf,"Color", [0 0 0])
nexttile(1, [2,2])
title("Raw Signal Data", 'Color', 'white')
xlabel("Time [ms]", 'Color', 'white'); ylabel("Voltage [mV]");
hold on;
nexttile(3, [2,2])
title("Aligned Signal Data", 'Color', 'white')
xlabel("Time [ms]", 'Color', 'white'); ylabel("Voltage [mV]");
hold on;
nexttile(5, [2,2])
title("Aligned Single Step Waveforms", 'Color', 'white')
xlabel("Time [ms]", 'Color', 'white'); ylabel("Voltage [mV]");
hold on;

for i = 1:Lookup.FileCount
    nexttile(1, [2,2])
    plot(Oscope.Time(i,:), Oscope.Voltage(i,:), "Color", ColorMap(i,:)); 
    set(gca, 'Color', [0 0 0]);  set(gca, 'XColor', 'white', 'YColor', 'white');
    axis tight; hold on;
    nexttile(3, [2,2])
    plot(Oscope.Time(i,:), Oscope.AlignedVoltage(i,:), "Color", ColorMap(i,:));
    set(gca, 'Color', [0 0 0]);  set(gca, 'XColor', 'white', 'YColor', 'white');
    xlim([Oscope.Time(1,LowerBound)-2*Gap, Oscope.Time(1,UpperBound)+2*Gap]);
    hold on;
    nexttile(5, [2,2])
    plot(Oscope.Time(i,:),Oscope.AlignedVoltage(i,:), "Color", ColorMap(i,:));
    set(gca, 'Color', [0 0 0]);  set(gca, 'XColor', 'white', 'YColor', 'white');
    xlim([Oscope.Time(1,LowerBound), Oscope.Time(1,UpperBound)]); 
    ylim([1.05*min(min(Oscope.AlignedVoltage)), 1.1*max(max(Oscope.AlignedVoltage))]);
    nexttile()
    bar(WF_S.BinCenter(i,:), WF_S.Count(i,:), 'FaceColor', ColorMap(i,:), "EdgeColor", "none"); 
    xline(LowSignal.Voltage(i,:), 'w--');
    xline(HighSignal.Voltage(i,:), 'w--');
    if i == 1
        Name = "Waveform: Laser off";
    else
        Name = "Waveform: " + num2str((i-2)*5) + "%";
    end
    title(Name, 'Color', 'white');
    set(gca, 'Color', [0 0 0]); 
    set(gca, 'XColor', 'white', 'YColor', 'white');
    pause(0.1)
end
pause(2)

%% Waveform Characteristics Demo
figure(2)
pulsewidth(double(Oscope.BinarySignal(end,:)), Oscope.Time(end,:));
xlim([-5*Waveform.Global.PulsePeriod, 5*Waveform.Global.PulsePeriod]);
pause(0.5)
figure(3)
pulseperiod(double(Oscope.BinarySignal(end,:)), Oscope.Time(end,:));
xlim([-5*Waveform.Global.PulsePeriod, 5*Waveform.Global.PulsePeriod]);
pause(0.5)
figure(4)
risetime(double(Oscope.BinarySignal(end,:)), Oscope.Time(end,:));
xlim([-5*Waveform.Global.PulsePeriod, 5*Waveform.Global.PulsePeriod]);
pause(0.5)
figure(5)
falltime(double(Oscope.BinarySignal(end,:)), Oscope.Time(end,:));
xlim([-5*Waveform.Global.PulsePeriod, 5*Waveform.Global.PulsePeriod]);
pause(0.5)

%% Plot Waveforms
figure(6)
t = tiledlayout(3,1);
title(t, "MScan Oscilloscope Data Processing", 'Color', 'white')
ylabel(t, "Waveform Voltage [mV]", 'Color', 'white');
ColorMap = hsv(Lookup.FileCount);
set(gcf,"Color", [0 0 0])
nexttile(1)
title("Raw Signal Data", 'Color', 'white')
axis tight;
set(gca, 'Color', [0 0 0]); 
set(gca, 'XColor', 'white', 'YColor', 'white');
hold on;
nexttile(2)
title("Aligned Signal Data", 'Color', 'white')
xlim([Oscope.Time(1,LowerBound)-2*Gap, Oscope.Time(1,UpperBound)+2*Gap]);
set(gca, 'Color', [0 0 0]); 
set(gca, 'XColor', 'white', 'YColor', 'white');
hold on;
nexttile(3)    
title("Aligned Single Step Waveforms", 'Color', 'white')
xlim([Oscope.Time(1,LowerBound), Oscope.Time(1,UpperBound)]);
ylim([1.05*min(min(Oscope.AlignedVoltage)), 1.1*max(max(Oscope.AlignedVoltage))]);
xlabel("Time [ms]", 'Color', 'white');
set(gca, 'Color', [0 0 0]); hold on;
set(gca, 'XColor', 'white', 'YColor', 'white');

for i = 1:Lookup.FileCount
    nexttile(1)
    plot(Oscope.Time(i,:), Oscope.Voltage(i,:), "Color", ColorMap(i,:)); hold on;
    nexttile(2)
    plot(Oscope.Time(i,:), Oscope.AlignedVoltage(i,:), "Color", ColorMap(i,:)); hold on;
    nexttile(3)
    plot(Oscope.Time(i,:),Oscope.AlignedVoltage(i,:), "Color", ColorMap(i,:)); hold on;
    pause(0.01)
end
pause(1)

%% Plot Single Steps, Global Histogram, and Results 
figure(7)
t = tiledlayout(1,3);
title(t, "Voltage Step & Histogram", 'Color', 'white');
ColorMap = hsv(Lookup.FileCount);
set(gcf,"Color", [0 0 0])
nexttile(1)    
title("Single Step Waveforms", 'Color', 'white')
xlabel("Time [ms]", 'Color', 'white'); ylabel("Voltage [mV]", 'Color', 'white');
xlim([Oscope.Time(1,LowerBound), Oscope.Time(1,UpperBound)]);
ylim([1.05*min(min(Oscope.AlignedVoltage)), 1.1*max(max(Oscope.AlignedVoltage))]);
set(gca, 'Color', [0 0 0]); hold on;
set(gca, 'XColor', 'white', 'YColor', 'white');
nexttile(2)
title("Low & High Signal Histogram for Each Waveform", 'Color', 'white')
xlabel("Waveform Voltage [mV]", 'Color', 'white'); ylabel("Frequency [Counts]", 'Color', 'white');
ylim([0,750]);
xlim([1.05*min(min(Oscope.AlignedVoltage)), 1.1*max(max(Oscope.AlignedVoltage))]);
set(gca, 'Color', [0 0 0]); 
set(gca, 'XColor', 'white', 'YColor', 'white');
hold on;
nexttile(3)
title("High & Low Signal Voltages", 'Color', 'white')
xlabel("Laser Input Intensity", 'Color', 'white'); ylabel("Voltage [mV]", 'Color', 'white');
xlim([1.05*min(min(Oscope.AlignedVoltage)), 1.1*max(max(Oscope.AlignedVoltage))]);
set(gca, 'Color', [0 0 0]); hold on;
set(gca, 'XColor', 'white', 'YColor', 'white');
Interval = [-1,0:5:100];
grid on; axis tight;

for i = 1:Lookup.FileCount
    nexttile(1)
    plot(Oscope.Time(i,:), Oscope.AlignedVoltage(i,:), "Color", ColorMap(i,:)); hold on;
    nexttile(2)
    bar(WF_T.BinCenter(i,:), WF_T.Count(i,:), "FaceAlpha", 0.75, "FaceColor", ColorMap(i,:), "EdgeColor", "none"); hold on;
    nexttile(3)
    plot(Interval(i), LowSignal.Voltage(i), '.', 'MarkerSize', 30, 'Color', ColorMap(i,:), 'HandleVisibility', 'off'); hold on;
    plot(Interval(i), HighSignal.Voltage(i), '.', 'MarkerSize', 30, 'Color', ColorMap(i,:), 'HandleVisibility', 'off'); hold on;
    pause(0.1);
end
    pause(0.5)
    plot(Interval, HighSignal.Voltage, 'w--', 'HandleVisibility', 'off'); hold on;
    plot(Interval, LowSignal.Voltage, 'w--', 'HandleVisibility', 'off'); hold on;
    pause(0.5)
    plot(Interval, HighSignal.Voltage, '.', 'MarkerSize', 30, 'Color', 'red'); hold on;
    plot(Interval, LowSignal.Voltage, '.', 'MarkerSize', 30, 'Color', 'blue'); hold on;
    legend("High Signal Voltage", "Low Signal Voltage", 'Color', 'white', 'Location', 'northwest')

%% File Output
Results.Data = [Interval', LowSignal.Voltage, HighSignal.Voltage];
Results.NewFile = 'MScan HighLow Voltage - ' + Lookup.CurrentFolder + '.txt';
Results.fid = fopen(Results.NewFile, 'w');
for i = 1:Lookup.FileCount
    fprintf(Results.fid, '%d\t%.6f\t%.6f\n', Results.Data(i,1), Results.Data(i,2), Results.Data(i,3));
end
fclose(Results.fid);

disp('Data written to ' + Results.NewFile)
fprintf('\n\tInput Intensity\tLow Signal Voltage\tHigh Signal Voltage\n');
for i = 1:Lookup.FileCount
    fprintf('\t%d%%\t\t%.6f mV\t\t%.6f mV\n', Results.Data(i,1), Results.Data(i,2), Results.Data(i,3))
end

fprintf('\nWaveform Characteristics:\n');
fprintf('\tPulse Period:\t%.2f μs\n', Waveform.Global.PulsePeriod);
fprintf('\tPulse Width:\t%.2f μs\n', Waveform.Global.PulseWidth);
fprintf('\tPulse Gap:\t%.2f μs\n', Waveform.Global.PulseGap);
fprintf('\tRise Time:\t%.4f μs\n', Waveform.Global.RiseTime);
fprintf('\tFall Time:\t%.4f μs\n', Waveform.Global.FallTime);