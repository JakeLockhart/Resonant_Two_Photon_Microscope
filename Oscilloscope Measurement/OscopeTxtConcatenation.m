clear; clc; format short; format compact;

addpath('C:\Workspace\LabScripts\Functions')
Lookup = FileLookup('txt');

%% Read .TXT file
for i = 1:Lookup.FileCount
    Name = erase(Lookup.FolderInfo(i).name, ".txt");
    if strcmpi(Name, "Notes"); continue; end
    TempFile = readtable(fullfile(Lookup.FolderAddress, Name));
    Oscope.LowVoltage(:,i) = TempFile{:,2};
    Oscope.HighVoltage(:,i) = TempFile{:,3};
end
Oscope.Intensity(:,1) = TempFile{:,1};

figure(1); clf(1)
for i = 1:4
    plot(Oscope.Intensity(:,1), Oscope.LowVoltage(:,i), "Color", 'black'); hold on
    plot(Oscope.Intensity(:,1), Oscope.HighVoltage(:,i), "Color", 'blue'); hold on;
    plot(Oscope.Intensity(:,1), Oscope.HighVoltage(:,i), "Color", 'red'); hold on;
    grid on; axis tight;
    pause(0.5)
end
legend('a', 'b', 'c', 'd', 'A', 'B', 'C', 'D', 'Location', 'best');

figure(2); clf(2)
for i = 1:4
    plot(Oscope.Intensity(:,1), Oscope.LowVoltage(:,i), "Color", 'black', 'HandleVisibility', 'off'); hold on;
    plot(Oscope.Intensity(:,1), Oscope.HighVoltage(:,i), "Color", 'blue'); hold on;
    grid on; axis tight;
end
legend('a', 'b', 'c', 'd', 'Location', 'best');

figure(3); clf(3)
for i = 5:Lookup.FileCount
    plot(Oscope.Intensity(:,1), Oscope.LowVoltage(:,i), "Color", 'black', 'HandleVisibility', 'off'); hold on;
    plot(Oscope.Intensity(:,1), Oscope.HighVoltage(:,i), "Color", 'red'); hold on;
    grid on; axis tight;
end
legend('A', 'B', 'C', 'D', 'Location', 'best');
