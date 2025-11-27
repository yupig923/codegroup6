function workResults = CalculateWorkAndPower(Ca, p, Cyl)
% CalculateWorkAndPower
% Computes net cycle work for each cycle and engine power.
%
% Inputs:
%   Ca   : Crank angle matrix [deg]        (Npoints × Ncycles)
%   p    : Pressure matrix [Pa]            (Npoints × Ncycles)
%   Cyl  : Engine geometry struct
%
% Output:
%   workResults : struct containing:
%       .W_net_all   : Net work for each cycle [J]
%       .W_net_avg   : Average net work [J]
%       .W_net_std   : Standard deviation [J]
%       .W_net_cov   : Coefficient of variation [%]
%       .W_net_min   : Minimum work [J]
%       .W_net_max   : Maximum work [J]
%       .cycle_min   : Cycle with minimum work
%       .cycle_max   : Cycle with maximum work
%       .power       : Engine power [W]
%       .RPM         : Fixed engine speed (1500 RPM)

%% Engine RPM is fixed
RPM = 1500;

%% Number of cycles
Ncycles = size(Ca, 2);

%% Preallocate
W_net_all = zeros(1, Ncycles);

%% Compute work for each cycle
for i = 1:Ncycles
    V_cycle = CylinderVolume(Ca(:,i), Cyl);
    W_net_all(i) = trapz(V_cycle, p(:,i));
end

%% Statistics
W_net_avg = mean(W_net_all);
W_net_std = std(W_net_all);
W_net_cov = (W_net_std / W_net_avg) * 100;

%% Min/max
[W_net_min, cycle_min] = min(W_net_all);
[W_net_max, cycle_max] = max(W_net_all);

%% Power calculation (4-stroke → 1 power stroke every 2 revolutions)
cycles_per_second = RPM / (2 * 60);
power = W_net_avg * cycles_per_second;

%% Output struct
workResults = struct();
workResults.W_net_all = W_net_all;
workResults.W_net_avg = W_net_avg;
workResults.W_net_std = W_net_std;
workResults.W_net_cov = W_net_cov;
workResults.W_net_min = W_net_min;
workResults.W_net_max = W_net_max;
workResults.cycle_min = cycle_min;
workResults.cycle_max = cycle_max;
workResults.power = power;
workResults.RPM = RPM;

end
