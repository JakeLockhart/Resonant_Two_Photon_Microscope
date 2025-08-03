clear; clc; format short; format compact;
addpath('C:\Workspace\LabScripts\Functions')
Lookup = FileLookup('csv', 'AllSubFolders');
Oscope = ReadOscope(Lookup);

%%% All Figures
%for i = 1:Lookup.FolderCount
%    if i < 5
%        figure(i)
%        hold on;
%        axis tight;
%        plot(Oscope.Time(4*(i-1)+1,:), Oscope.Voltage(4*(i-1)+1,:));
%        plot(Oscope.Time(4*(i-1)+2,:), Oscope.Voltage(4*(i-1)+2,:));
%        plot(Oscope.Time(4*(i-1)+3,:), Oscope.Voltage(4*(i-1)+3,:));
%        plot(Oscope.Time(4*(i-1)+4,:), Oscope.Voltage(4*(i-1)+4,:));
%    elseif i < 11
%        figure(i)
%        hold on;
%        axis tight;
%        plot(Oscope.Time(2*i+7,:), Oscope.Voltage(2*i+7,:));
%        plot(Oscope.Time(2*i+8,:), Oscope.Voltage(2*i+8,:));
%    elseif i < 14
%        figure(i)
%        hold on;
%        axis tight;
%        plot(Oscope.Time(i+18,:), Oscope.Voltage(i+18,:));
%    end
%end

%% Cross Correlation

%% Frame Trigger, H-Sync from Amplifer, Line Trigger, Pockels Cell Output from AO0 (4CH)
figure(1)
t1.Layout = tiledlayout(3,1);
title(t1.Layout, "Frame and Line Signal Timing, 512x512 FOV", "Color", "White")
set(gcf, "Color", [0, 0, 0]);
ylabel(t1.Layout, "Voltage [V]", "Color", "White");
xlabel(t1.Layout, "Time", "Color", "White");
ColorMap = hsv(4);
t1.LegendLabels = ["Frame Trigger (PCI6110 - PFI12/P2.4)";
                   "H-Sync (MDR-R)";
                   "Line Trigger (PCI6353(2) - PFI12/P2.4)";
                   "Pockels Cell Voltage (PCI6353(1) - AO0)"];
t1.AxesLabels = ["50\mus", "2.5\mus", "500ns"];
for i = 1:3
    nexttile
    hold on;
    plot(Oscope.Time(4*(i-1)+1,:), Oscope.Voltage(4*(i-1)+1,:), "Color", ColorMap(1,:));
    plot(Oscope.Time(4*(i-1)+2,:), Oscope.Voltage(4*(i-1)+2,:), "Color", ColorMap(2,:));
    plot(Oscope.Time(4*(i-1)+3,:), Oscope.Voltage(4*(i-1)+3,:), "Color", ColorMap(3,:));
    plot(Oscope.Time(4*(i-1)+4,:), Oscope.Voltage(4*(i-1)+4,:), "Color", ColorMap(4,:));
    set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
    axis tight;
    xlabel(t1.AxesLabels(i), "Color", "White")
end
nexttile(1)
t1.Legend = legend(t1.LegendLabels, "Location", "best");
t1.Legend.TextColor = "White";

%% H-Sync and Line Trigger
figure(2)
t2.Layout = tiledlayout(4,1);
t2.NestedLayout1 = tiledlayout(t2.Layout,1,3);
t2.NestedLayout1.Layout.Tile = 3;
title(t2.Layout, "Line Trigger & H-Sync", "Color", "White");
set(gcf, "Color", [0, 0, 0]);
ylabel(t2.Layout, "Voltage [V]", "Color", "White");
xlabel(t2.Layout, "Time", "Color", "White");
ColorMap = hsv(4);
t2.LegendLabels = ["Line Trigger (PCI6353(2) - PFI12/P2.4)";
                   "H-Sync (MDR-R)"];
t2.AxesLabels = ["25\mus", "10\mus", "250ns", "250ns", "250ns", "500ns", "100ns", "100ns"];
for i = 6:11
    if i == 6
        ax = nexttile(t2.Layout, 1);
        Flag = true;
    elseif i == 7
        ax = nexttile(t2.Layout, 2);
        Flag = true;
    elseif i > 7 && i < 11
        ax = nexttile(t2.NestedLayout1, i-7);
        Flag = true;
    else
        ax = nexttile(t2.Layout, 4);
        Flag = false;
    end
    hold on;
    if Flag == true;
        plot(ax, Oscope.Time(2*i+8,:), Oscope.Voltage(2*i+8,:), "Color", ColorMap(3,:));
        plot(ax, Oscope.Time(2*i+7,:), Oscope.Voltage(2*i+7,:), "Color", ColorMap(2,:));
        axis tight;
        ylim([-0.52, 5.4]);
    else
        plot(ax, Oscope.Time(30,:), Oscope.Voltage(30,:), "Color", ColorMap(3,:));
        axis tight;
    end
    set(gca, "Color", [0, 0, 0], "XColor", "White", "YColor", "White");
    xlabel(ax, t2.AxesLabels(i-5));
end
nexttile(1)
t2.Legend = legend(t2.LegendLabels, "Location", "best");
t2.Legend.TextColor = "White";



