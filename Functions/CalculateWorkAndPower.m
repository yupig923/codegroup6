function workResults = CalculateWorkAndPower(Ca, p, Cyl, RPM, p_intake)
% CalculateWorkAndPower - Calculate work and power for all engine cycles
%
%   workResults = CalculateWorkAndPower(Ca, p, Cyl, RPM, p_intake)
%
%   Inputs:
%       Ca       : Crank angle matrix [deg], size (NpointsPerCycle, Ncycles)
%       p        : Pressure matrix [Pa], size (NpointsPerCycle, Ncycles)
%       Cyl      : Engine geometry struct (see CylinderVolume.m)
%       RPM      : Engine speed [rev/min]
%       p_intake : Intake pressure [Pa] for pegging
%
%   Output struct 'workResults' contains:
%       .W_net_all   : Work for each cycle [J], array of size (1, Ncycles)
%       .W_net_avg   : Average net work per cycle [J]
%       .W_net_std   : Standard deviation of work [J]
%       .W_net_cov   : Coefficient of variation [%]
%       .W_net_min   : Minimum work value [J]
%       .W_net_max   : Maximum work value [J]
%       .cycle_min   : Cycle number with minimum work
%       .cycle_max   : Cycle number with maximum work
%       .power       : Engine power [W]
%       .RPM         : Engine speed [rev/min]
%       .p_pegged    : Pegged pressure matrix [Pa]
%       .p_avg       : Average pressure across cycles (pegged) [Pa]
%       .p_filt      : Filtered average pressure [Pa]
%       .Ca_avg      : Average crank angle vector [deg]

% Get number of cycles
Ncycles = size(Ca, 2);

%% Pegging pressure to intake pressure at BDC
BDC_angle = Cyl.TDCangle + 180;
[~, BDC_idx] = min(abs(Ca(:,1) - BDC_angle));

p_pegged = p;
for k = 1:Ncycles
    offset = p_intake - p(BDC_idx, k);
    p_pegged(:, k) = p(:, k) + offset;
end

%% Calculate average pressure across all cycles
p_avg = mean(p_pegged, 2);       % [Pa]
Ca_avg = Ca(:, 1);                % [deg]

%% Apply Savitzky-Golay filtering
% This is filtering, similar to that used in the handbook
try
    p_filt = sgolayfilt(p_avg, 3, 21);
catch
    % fallback to moving average filter
    w = ones(21, 1) / 21;
    p_filt = filtfilt(w, 1, p_avg);
end

%% Preallocate array for work values
W_net_all = zeros(1, Ncycles);

%% Calculate work for each cycle using pegged and filtered data
for i = 1:Ncycles
    [V_cycle] = CylinderVolume(Ca(:, i), Cyl);
    W_net_all(i) = trapz(V_cycle, p_pegged(:, i));
end

%% Calculate statistics
W_net_avg = mean(W_net_all);
W_net_std = std(W_net_all);
W_net_cov = (W_net_std / W_net_avg) * 100; % Coefficient of variation in %

% Find min and max
[W_net_min, cycle_min] = min(W_net_all);
[W_net_max, cycle_max] = max(W_net_all);

%% Calculate power (for 4-stroke engine, 1 cycle per 2 revolutions)
cycles_per_second = RPM / (2 * 60);
power = W_net_avg * cycles_per_second; % Power in Watts

%% Store results in output structure
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
workResults.p_pegged = p_pegged;
workResults.p_avg = p_avg;
workResults.p_filt = p_filt;
workResults.Ca_avg = Ca_avg;

end