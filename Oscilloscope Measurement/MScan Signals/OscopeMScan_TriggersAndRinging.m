clear; clc; format short g; format compact;
addpath('C:\Workspace\LabScripts\Functions')
Lookup = FileLookup('csv', 'AllSubFolders');
Oscope = ReadOscope(Lookup);

PlotTitles = ["Frame (TTL) and Line (Analog) Trigger", "Analog Signal Ringing", "Analog Rising Ringing Signal", "Analog Falling Ringing Signal", "TTL Rising Signal", "TTL Falling Signal"];
TimeScales = ["[2.5ms]", "[50\mus]", "[2.5\mus]", "[500ns]", "[25ns]"];

%% Plot 512x128 FOV Oscope Data
figure(1)
t1 = tiledlayout(5,2);
title(t1, "512x128 Pixel FOV", "Color", "White")
set(gcf, "Color", [0, 0, 0]);
ylabel(t1, "Voltage [V]", "Color", "White");
xlabel(t1, "Time", "Color", "White");

Tile = 1;
for i = 1:Lookup.FolderCount/2
    if i < 3
        nexttile(Tile, [1,2]);
        Tile = Tile + 2;
        hold on;
        plot(Oscope.Time((i-1)*2+1,:), Oscope.Voltage((i-1)*2+1,:), "Color", "Cyan");
        plot(Oscope.Time((i-1)*2+2,:), Oscope.Voltage((i-1)*2+2,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(i))
        title(PlotTitles(1), "Color", "White"); 
    elseif i == 3
        nexttile(Tile, [1,2]);
        Tile = Tile +2;
        hold on;
        plot(Oscope.Time(i+2,:), Oscope.Voltage(i+2,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(i))
        title(PlotTitles(2), "Color", "White");
    elseif i > 3 && i < 6
        nexttile(Tile);
        Tile = Tile + 1;
        hold on;
        plot(Oscope.Time(i+2,:), Oscope.Voltage(i+2,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(4))
        title(PlotTitles(i-1), "Color", "White");
    elseif i >= 6
        nexttile(Tile);
        Tile = Tile + 1;
        hold on;
        plot(Oscope.Time(i+2,:), Oscope.Voltage(i+2,:), "Color", "Cyan");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(5))
        title(PlotTitles(i-1), "Color", "White");
    end
end

%% Plot 512x512 FOV Oscope Data
figure(2)
t2 = tiledlayout(5,2);
title(t2, "512x512 Pixel FOV", "Color", "White")
set(gcf, "Color", [0, 0, 0]);
ylabel(t2, "Voltage [V]", "Color", "White");
xlabel(t2, "Time", "Color", "White");

Tile = 1;
for i = Lookup.FolderCount/2+1:Lookup.FolderCount
    if i < 10
        nexttile(Tile, [1,2]);
        Tile = Tile + 2;
        hold on;
        plot(Oscope.Time(2*(i - 8) + 10,:), Oscope.Voltage(2*(i - 8) + 10,:), "Color", "Cyan");
        plot(Oscope.Time(2*(i - 8) + 11,:), Oscope.Voltage(2*(i - 8) + 11,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(i-Lookup.FolderCount/2))
        title(PlotTitles(1), "Color", "White"); 
    elseif i == 10
        nexttile(Tile, [1,2]);
        Tile = Tile +2;
        hold on;
        plot(Oscope.Time(i+4,:), Oscope.Voltage(i+4,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(i-Lookup.FolderCount/2))
        title(PlotTitles(2), "Color", "White");
    elseif i > 10 && i < 13
        nexttile(Tile);
        Tile = Tile + 1;
        hold on;
        plot(Oscope.Time(i+4,:), Oscope.Voltage(i+4,:), "Color", "Red");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(4))
        title(PlotTitles(i-8), "Color", "White");
    elseif i >= 13
        nexttile(Tile);
        Tile = Tile + 1;
        hold on;
        plot(Oscope.Time(i+4,:), Oscope.Voltage(i+4,:), "Color", "Cyan");
        set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
        axis tight; 
        xlabel(TimeScales(5))
        title(PlotTitles(i-8), "Color", "White");
    end
end

%% Ringing Analysis
% Power Spectrum
figure(3)
t3 = tiledlayout('flow');
title(t3, "Power Spectrum Analysis");
for i = 1:Lookup.FileCount
    nexttile();
    pspectrum(Oscope.Voltage(i,:), Oscope.SampleFrequency(i));
end

% Fast Fourier Transformation
figure(4)
t4 = tiledlayout('flow');
title(t4, "Fast Fourier Transformation")
for i = 1:Lookup.FileCount
    nexttile();
    Y = fft(Oscope.Voltage(i,:));
    P2 = abs(Y/Oscope.RecordLength(i));
    P1 = P2(1:floor(Oscope.RecordLength(i)/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    FrequencyVector = Oscope.SampleFrequency(i)*(0:floor(Oscope.RecordLength(i)/2))/Oscope.RecordLength(i);
    plot(FrequencyVector, P1);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    title("FFT of Signal " + i)
end

