%% Process all .txt files in Data/HVO
fuel = 'HVO';
folder = fullfile('Data',fuel);
files = dir(fullfile(folder, '*fdaq.txt'));

% Initialize result arrays
numFiles = length(files);
WnetAvg   = zeros(numFiles,1);
WnetStd   = zeros(numFiles,1);
WnetCov   = zeros(numFiles,1);
TminWork  = zeros(numFiles,1);
TmaxWork  = zeros(numFiles,1);
PowerOut  = zeros(numFiles,1);
CA_vals   = zeros(numFiles,1);
P_vals    = zeros(numFiles,1);

for k = 1:numFiles
    FullName = fullfile(files(k).folder, files(k).name);

    fprintf('\n======================================================\n');
    fprintf('Processing file: %s\n', files(k).name);
    fprintf('======================================================\n');

    % Run the work & power calculation on this file
    [avgWork, stdWork, covWork, minWork, maxWork, power] = CalculateWorkAndPower(FullName);

    % Store numeric results
    WnetAvg(k)   = avgWork;
    WnetStd(k)   = stdWork;
    WnetCov(k)   = covWork;
    TminWork(k)  = minWork;
    TmaxWork(k)  = maxWork;
    PowerOut(k)  = power;

    % Extract Crank Angle (CA) from filename
    tokensCA = regexp(files(k).name, 'CA(\d+)-', 'tokens');
    if ~isempty(tokensCA)
        CA_vals(k) = str2double(tokensCA{1}{1});
    else
        CA_vals(k) = NaN;
    end

    % Extract Percentage from filename
    tokensP = regexp(files(k).name, '-(\d+)P', 'tokens');
    if ~isempty(tokensP)
        P_vals(k) = str2double(tokensP{1}{1});
    else
        P_vals(k) = NaN;
    end
end

% Sort first by CA, then by Percentage
[~, sortIdx] = sortrows([CA_vals, P_vals]);

CA_vals    = CA_vals(sortIdx);
P_vals     = P_vals(sortIdx);
WnetAvg    = WnetAvg(sortIdx);
WnetStd    = WnetStd(sortIdx);
WnetCov    = WnetCov(sortIdx);
TminWork   = TminWork(sortIdx);
TmaxWork   = TmaxWork(sortIdx);
PowerOut   = PowerOut(sortIdx);

% Create final table
Results = table(CA_vals, P_vals, WnetAvg, WnetStd, WnetCov, TminWork, TmaxWork, PowerOut);
Results.Properties.VariableNames = {'CrankAngle','Percentage','WnetAvg','WnetStd','WnetCov','MinWork','MaxWork','PowerOut'};

% Display
disp(' ');
disp(['====================== FINAL RESULTS TABLE (' fuel ') ======================']);
disp(Results);

%% --- Function: CalculateWorkAndPower ---
function [W_net_avg, W_net_std, W_net_cov, minWork, maxWork, power] = CalculateWorkAndPower(FullName)

%% Units
mm      = 1e-3; 
bara    = 1e5;

%% Engine geometry
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;

%% Load data from file
dataIn = table2array(readtable(FullName));
[Nrows,~] = size(dataIn);

NdatapointsperCycle = 720/0.2;
Ncycles = Nrows / NdatapointsperCycle;

Ca = reshape(dataIn(:,1),[],Ncycles);
p  = reshape(dataIn(:,2),[],Ncycles) * bara;

%% Calculate Work for ALL cycles
W_net_all = zeros(1, Ncycles);

for i = 1:Ncycles
    V_cycle = CylinderVolume(Ca(:,i), Cyl);
    W_net_all(i) = trapz(V_cycle, p(:,i));
end

%% Stats
W_net_avg = mean(W_net_all);
W_net_std = std(W_net_all);
W_net_cov = (W_net_std / W_net_avg) * 100;

RPM = 1500;
cycles_per_second = RPM / (2 * 60);
power = W_net_avg * cycles_per_second;

minWork = min(W_net_all);
maxWork = max(W_net_all);

%% Print results
fprintf('Average net work per cycle: %.2f J\n', W_net_avg);
fprintf('Standard deviation: %.2f J\n', W_net_std);
fprintf('Coefficient of variation: %.1f%%\n', W_net_cov);
fprintf('Minimum work: %.2f J\n', minWork);
fprintf('Maximum work: %.2f J\n', maxWork);
fprintf('Power: %.2f W\n', power);

end


%% --- Plotting results ---

uniqueP = unique(Results.Percentage); % all unique percentages
figure('Color','w');

% --- Plot Net Work ---
subplot(2,2,1);
hold on;
for i = 1:length(uniqueP)
    idx = Results.Percentage == uniqueP(i);
    plot(Results.CrankAngle(idx), Results.WnetAvg(idx), '-o', 'LineWidth',1.5);
end
xlabel('Crank Angle [°]');
ylabel('Net Work [J]');
title('Net Work vs Crank Angle');
legend(arrayfun(@(x) sprintf('%d%%',x), uniqueP,'UniformOutput',false),'Location','best');
grid on; hold off;

% --- Plot Min Work ---
subplot(2,2,2);
hold on;
for i = 1:length(uniqueP)
    idx = Results.Percentage == uniqueP(i);
    plot(Results.CrankAngle(idx), Results.MinWork(idx), '-o', 'LineWidth',1.5);
end
xlabel('Crank Angle [°]');
ylabel('Min Work [J]');
title('Min Work vs Crank Angle');
legend(arrayfun(@(x) sprintf('%d%%',x), uniqueP,'UniformOutput',false),'Location','best');
grid on; hold off;

% --- Plot Max Work ---
subplot(2,2,3);
hold on;
for i = 1:length(uniqueP)
    idx = Results.Percentage == uniqueP(i);
    plot(Results.CrankAngle(idx), Results.MaxWork(idx), '-o', 'LineWidth',1.5);
end
xlabel('Crank Angle [°]');
ylabel('Max Work [J]');
title('Max Work vs Crank Angle');
legend(arrayfun(@(x) sprintf('%d%%',x), uniqueP,'UniformOutput',false),'Location','best');
grid on; hold off;

% --- Plot Power ---
subplot(2,2,4);
hold on;
for i = 1:length(uniqueP)
    idx = Results.Percentage == uniqueP(i);
    plot(Results.CrankAngle(idx), Results.PowerOut(idx), '-o', 'LineWidth',1.5);
end
xlabel('Crank Angle [°]');
ylabel('Power [W]');
title('Power vs Crank Angle');
legend(arrayfun(@(x) sprintf('%d%%',x), uniqueP,'UniformOutput',false),'Location','best');
grid on; hold off;

sgtitle(['Results for Fuel: ' fuel],'FontSize',14); % super-title for all 4 plots
