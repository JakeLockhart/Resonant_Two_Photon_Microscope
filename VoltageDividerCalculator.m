clear; clc;
format short g; format compact;

AllVoltages = [];
R = [1000, 2000, 10000, 100, 10e6, 100000, 10, 5000, 330, 220. 20000, ...
     27000, 33000, 47000, 56000, 68000, 3000, 4700, 5600, 8200, 10000, ...
     15000, 20, 1200, 1500, 1800, 2000, 47, 10, 49.9, 75, 100, 150, 500, ...
     100000, 499000, 250000, 1000, 195, 75000, 200000, 500];
Vin = [3.3, 5];

for i = 1:length(Vin)
    for j = 1:length(R)
        for k = 1:length(R)

            Vout = Vin(i)*((R(j))/(R(j)+R(k)));
            AllVoltages = [AllVoltages; Vout, Vin(i), R(k), R(j)];

        end
    end
end

MinVoltage = 2.5;
MaxVoltage = 3.5;

MinFiltered = AllVoltages(AllVoltages(:,1) > MinVoltage, :);
MaxFiltered = MinFiltered(MinFiltered(:,1) < MaxVoltage, :);
SortedVoltages = sortrows(MaxFiltered, 1);

Data_3_3V = SortedVoltages(SortedVoltages(:,2) == 3.3, :);
Data_5V = SortedVoltages(SortedVoltages(:,2) == 5, :);