clear all; clc;close all;
% Units
mm      = 1e-3;dm=0.1;
bara    = 1e5;
MJ      = 1e6;
kWhr    = 1000*3600;
volperc = 0.01; % Emissions are in volume percentages
ppm     = 1e-6; % Some are in ppm (also a volume- not a mass-fraction)
g       = 1e-3;
s       = 1;
% Engine geom data (check if these are correct)
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
addpath('Nasa\')
addpath('Data\')
addpath('Functions\')
%% Actual Code
% Defining which Fuel to use
fuel="HVO+Diesel_Blend";
Readfile_results=AutoReadFilesFromFuels(fuel);
Load=Readfile_results.P_vals;
Ca_exp=Readfile_results.CA_vals;

fdaq_data_name  =[Readfile_results.fastfiles.relpath];
sdaq_data_name  = [Readfile_results.slowfiles.relpath];

emissions_fuel=ReadEmissionsData(fuel);

% Instead of the file AF_sto
if strcmp(fuel, 'Diesel')
    fuel_specfic_AFR_sto = 14.5;
elseif strcmp(fuel, 'GTL')
    fuel_specfic_AFR_sto = 14.7;
elseif strcmp(fuel, 'GTL+Diesel_Blend')
    fuel_specfic_AFR_sto = 14.6;
elseif strcmp(fuel, 'HVO')
    fuel_specfic_AFR_sto = 14.55;
elseif strcmp(fuel, 'HVO+Diesel_Blend')
    fuel_specfic_AFR_sto = 14.525;
elseif strcmp(fuel, 'Dieselgroup16')
    fuel_specfic_AFR_sto = 14.5;
end
 



% Actual Calculation

BSem = [];

num_points = length(emissions_fuel); 
for i = 1:num_points

    Current_Raw_data = Data_Extraction(fdaq_data_name(i),sdaq_data_name(i));
    Current_Power_data = CalculateWorkAndPower(Current_Raw_data.Ca,Current_Raw_data.p,Cyl);
    Current_BSem = KPICalculation(emissions_fuel(i),fuel_specfic_AFR_sto,Current_Raw_data.AVG_fuel_m_flow,Current_Power_data.power,fuel);
    
    BSem = [BSem, Current_BSem];
end    

disp("BSem.BSCO2 values:")
disp([BSem.BSCO2]);


targetLoads = [30, 50, 70];  % loads of the engine 
emissionsToPlot = ["BSNOx", "BSCO2"];
colors = lines(length(targetLoads));

%% Plot BSNOx
figure;
hold on;
for l = 1:length(targetLoads)
    loadVal = targetLoads(l);

    idx = find(abs(Load - loadVal) < 1);

    CA_vals = Ca_exp(idx);
    emissionVals = [BSem(idx).BSNOx];

    plot(CA_vals, emissionVals, "-o", ...
        "LineWidth", 2.5, ...
        "Color", colors(l,:), ...
        "DisplayName", sprintf("%d%% Load", loadVal));
end

xlabel("CA [°]");
ylabel("BSNOx [g/kWh]");
title("Brake Specific NOx vs CA");
grid on;
legend("Location","best");
xlim([14 19])


%% Plot BSCO2
figure;
hold on;
for l = 1:length(targetLoads)
    loadVal = targetLoads(l);

    idx = find(abs(Load - loadVal) < 1);

    CA_vals = Ca_exp(idx);
    emissionVals = [BSem(idx).BSCO2];

    plot(CA_vals, emissionVals, "-o", ...
        "LineWidth", 2.5, ...
        "Color", colors(l,:), ...
        "DisplayName", sprintf("%d%% Load", loadVal));
end

xlabel("CA [°]");
ylabel("BSCO2 [g/kWh]");
title("Brake Specific CO2 vs CA");
grid on;
legend("Location","best");
xlim([14 19])

%% Plot BSCO
figure;
hold on;
for l = 1:length(targetLoads)
    loadVal = targetLoads(l);

    idx = find(abs(Load - loadVal) < 1);

    CA_vals = Ca_exp(idx);
    emissionVals = [BSem(idx).BSCO];

    plot(CA_vals, emissionVals, "-o", ...
        "LineWidth", 2.5, ...
        "Color", colors(l,:), ...
        "DisplayName", sprintf("%d%% Load", loadVal));
end

xlabel("CA [°]");
ylabel("BSCO [g/kWh]");
title("Brake Specific CO vs CA");
grid on;
legend("Location","best");
xlim([14 19])

%% Plot BSFC
figure;
hold on;
for l = 1:length(targetLoads)
    loadVal = targetLoads(l);

    idx = find(abs(Load - loadVal) < 1);

    CA_vals = Ca_exp(idx);
    emissionVals = [BSem(idx).BSFC];

    plot(CA_vals, emissionVals, "-o", ...
        "LineWidth", 2.5, ...
        "Color", colors(l,:), ...
        "DisplayName", sprintf("%d%% Load", loadVal));
end

xlabel("CA [°]");
ylabel("BSFC [g/kWh]");
title("Brake Specific Fuel Consumption vs CA");
grid on;
legend("Location","best");
xlim([14 19])


%% Plot BSeff
figure;
hold on;
for l = 1:length(targetLoads)
    loadVal = targetLoads(l);

    idx = find(abs(Load - loadVal) < 1);

    CA_vals = Ca_exp(idx);
    emissionVals = [BSem(idx).eff];

    plot(CA_vals, emissionVals, "-o", ...
        "LineWidth", 2.5, ...
        "Color", colors(l,:), ...
        "DisplayName", sprintf("%d%% Load", loadVal));
end

xlabel("CA [°]");
ylabel("efficiency [-]");
title("Efficiency vs CA");
grid on;
legend("Location","best");
xlim([14 19])


%% Calculate averaged values and error bars
% Get unique CA values
unique_CA = unique(Ca_exp);

% Initialize arrays for averaged values and error bars
avg_BSNOx = zeros(size(unique_CA));
avg_BSCO2 = zeros(size(unique_CA));
avg_BSCO = zeros(size(unique_CA));
avg_BSFC = zeros(size(unique_CA));
avg_eff = zeros(size(unique_CA));

err_BSNOx = zeros(size(unique_CA));
err_BSCO2 = zeros(size(unique_CA));
err_BSCO = zeros(size(unique_CA));
err_BSFC = zeros(size(unique_CA));
err_eff = zeros(size(unique_CA));

for i = 1:length(unique_CA)
    ca_val = unique_CA(i);
    
    % Find indices for this CA value and loads 30-70
    idx_ca = find(abs(Ca_exp - ca_val) < 0.1);
    idx_loads = find(Load(idx_ca) >= 30 & Load(idx_ca) <= 70);
    idx_combined = idx_ca(idx_loads);
    
    % Find indices for 30% and 70% loads specifically for error bars
    idx_30 = find(abs(Ca_exp - ca_val) < 0.1 & abs(Load - 30) < 1);
    idx_70 = find(abs(Ca_exp - ca_val) < 0.1 & abs(Load - 70) < 1);
    
    if ~isempty(idx_combined)
        % Calculate averages
        avg_BSNOx(i) = mean([BSem(idx_combined).BSNOx]);
        avg_BSCO2(i) = mean([BSem(idx_combined).BSCO2]);
        avg_BSCO(i) = mean([BSem(idx_combined).BSCO]);
        avg_BSFC(i) = mean([BSem(idx_combined).BSFC]);
        avg_eff(i) = mean([BSem(idx_combined).eff]);
        
        % Calculate error bars as (max - min)/2
        if ~isempty(idx_30) && ~isempty(idx_70)
            err_BSNOx(i) = abs([BSem(idx_70).BSNOx] - [BSem(idx_30).BSNOx])/2;
            err_BSCO2(i) = abs([BSem(idx_70).BSCO2] - [BSem(idx_30).BSCO2])/2;
            err_BSCO(i) = abs([BSem(idx_70).BSCO] - [BSem(idx_30).BSCO])/2;
            err_BSFC(i) = abs([BSem(idx_70).BSFC] - [BSem(idx_30).BSFC])/2;
            err_eff(i) = abs([BSem(idx_70).eff] - [BSem(idx_30).eff])/2;
        end
    end
end

%% Plot all 4 BS KPIs with error bars
figure;
hold on;

% Plot BSNOx
errorbar(unique_CA, avg_BSNOx, err_BSNOx, "-o", ...
    "LineWidth", 2.5, ...
    "MarkerSize", 8, ...
    "DisplayName", "BSNOx");

% Plot BSCO2
errorbar(unique_CA, avg_BSCO2, err_BSCO2, "-s", ...
    "LineWidth", 2.5, ...
    "MarkerSize", 8, ...
    "DisplayName", "BSCO2");

% Plot BSCO
errorbar(unique_CA, avg_BSCO, err_BSCO, "-^", ...
    "LineWidth", 2.5, ...
    "MarkerSize", 8, ...
    "DisplayName", "BSCO");

% Plot BSFC
errorbar(unique_CA, avg_BSFC, err_BSFC, "-d", ...
    "LineWidth", 2.5, ...
    "MarkerSize", 8, ...
    "DisplayName", "BSFC");

xlabel("CA [°]");
ylabel("Brake Specific Values [g/kWh]");
title("All BS KPIs vs CA (Averaged over 30-70% Load)");
grid on;
legend("Location","best");
xlim([14 19])

% Table 1: BS KPIs (without efficiency)
Averaged_Results = table(unique_CA, ...
    round(avg_BSNOx, 2), round(err_BSNOx, 2), ...
    round(avg_BSCO2, 1), round(err_BSCO2, 1), ...
    round(avg_BSCO, 3), round(err_BSCO, 3), ...
    round(avg_BSFC, 2), round(err_BSFC, 2));

Averaged_Results.Properties.VariableNames = {...
    'CA', ...
    'Avg_BSNOx', 'Err_BSNOx', ...
    'Avg_BSCO2', 'Err_BSCO2', ...
    'Avg_BSCO', 'Err_BSCO', ...
    'Avg_BSFC', 'Err_BSFC'};

% Display the table
disp(' ');
disp('====================== AVERAGED BS KPIs TABLE ======================');
disp('============ Averaged over 30-70% Load, Error = (70%-30%)/2 =========');
disp(Averaged_Results);

% Table 2: Efficiency data from Figure 5 (all three loads)
% Extract efficiency values for each load in separate columns
Eff_30 = [];
Eff_50 = [];
Eff_70 = [];

for i = 1:length(unique_CA)
    ca_val = unique_CA(i);
    
    % Find efficiency for 30% load
    idx_30 = find(abs(Ca_exp - ca_val) < 0.1 & abs(Load - 30) < 1);
    if ~isempty(idx_30)
        Eff_30(i) = [BSem(idx_30).eff];
    else
        Eff_30(i) = NaN;
    end
    
    % Find efficiency for 50% load
    idx_50 = find(abs(Ca_exp - ca_val) < 0.1 & abs(Load - 50) < 1);
    if ~isempty(idx_50)
        Eff_50(i) = [BSem(idx_50).eff];
    else
        Eff_50(i) = NaN;
    end
    
    % Find efficiency for 70% load
    idx_70 = find(abs(Ca_exp - ca_val) < 0.1 & abs(Load - 70) < 1);
    if ~isempty(idx_70)
        Eff_70(i) = [BSem(idx_70).eff];
    else
        Eff_70(i) = NaN;
    end
end

Efficiency_Results = table(unique_CA, round(Eff_30', 4), round(Eff_50', 4), round(Eff_70', 4));
Efficiency_Results.Properties.VariableNames = {'CA', 'Eff_30pct', 'Eff_50pct', 'Eff_70pct'};

% Display the efficiency table
disp(' ');
disp('====================== EFFICIENCY TABLE (Figure 5) ======================');
disp(Efficiency_Results);

%% Plot Efficiency with error bars
figure;
hold on;

errorbar(unique_CA, avg_eff, err_eff, "-o", ...
    "LineWidth", 2.5, ...
    "MarkerSize", 8, ...
    "Color", [0.8500 0.3250 0.0980], ...
    "DisplayName", "Efficiency (avg 30-70% Load)");

xlabel("CA [°]");
ylabel("Efficiency [-]");
title("Efficiency vs CA (Averaged over 30-70% Load)");
grid on;
legend("Location","best");
xlim([14 19])



if fuel == "Diesel"
    WtT = 3.70e-4;      
elseif fuel == "HVO+Diesel_Blend"
    WtT = 1.09315e-4;
elseif fuel == "GTL+Diesel_Blend"
    WtT = -1.12e-3;
elseif fuel == "HVO"
    WtT = -5.8863e-4;
elseif fuel == "GTL"
    WtT = -2.6e-3;
elseif fuel == "Dieselgroup16"
    WtT = 3.70e-4;
end

BSem.eff

WtT_g_kWh = WtT * 1e6 * 3.6 ./ [BSem.eff]

CA_vals   = Ca_exp(:);
Load_vals = Load(:);

% WTW values
WTW_CO2_vals = WtT_g_kWh(:) + [BSem.BSCO2]';
WTW_NOx_vals = [BSem.BSNOx]';
WTW_CO_vals  = [BSem.BSCO]';

% Create table
WTW_table = table(Load_vals, CA_vals, WTW_CO2_vals, WTW_NOx_vals, WTW_CO_vals);
WTW_table.Properties.VariableNames = {'Load', 'CA', 'WTW_CO2', 'WTW_NOx', 'WTW_CO'};

WTW_table_sorted = sortrows(WTW_table, {'Load', 'CA'});

disp(WTW_table_sorted);


% figure;
% plot(Load, [BSem.BSCO2], "Marker","o","LineStyle","-")
% 
% grid on
% xlabel("Load [%]")
% ylabel("Brake Specific CO2 [g/kwh]")
% title("Brake Specific CO2 emission over the Load")
% xlim([0,100])
% ylim([0,max([BSem.BSCO2])*1.2])
% 
% %3D Scatter Plot
% figure;
% scatter3(Load, Ca_exp, [BSem.BSCO2], "filled")
% grid on
% xlabel("Load [%]")
% ylabel("CA [°]")
% zlabel("Brake Specific CO₂ [g/kWh]")
% title("Brake Specific CO₂ Emission over Load and CA")
% xlim([0 100])
% 
% %Add intermediate Values for Mesh Plot
% F = scatteredInterpolant(Load, Ca_exp, [BSem.BSCO2]', 'natural', 'none');
% figure;
% % Create meshgrid for surface
% xq = linspace(0, 75, 5);
% yq = linspace(0, 20, 0.5);
% [Xq, Yq] = meshgrid(xq, yq);
% Zq = F(Xq, Yq);
% 
% % Mesh Plot 
% 
% surf(Xq, Yq, Zq, 'EdgeColor', 'none', 'FaceAlpha', 0.85)
% hold on
% scatter3(Load, Ca_exp, [BSem.BSCO2], 70, 'filled', 'MarkerEdgeColor', 'k')
% hold off
% 
% grid on
% xlabel("Load [%]")
% ylabel("CA [°]")
% zlabel("Brake Specific CO₂ [g/kWh]")
% title("Interpolated Brake Specific CO₂ Surface")
% colorbar
% 
% 
% N = length(BSem);
% 
% Load_col   = Load(:);
% CA_col     = Ca_exp(:);
% 
% fieldNames = fieldnames(BSem);
% 
% tableData = table(Load_col, CA_col, 'VariableNames', {'Load_percent','CA_deg'});
% fieldsToAdd = ["BSFC","BSCO","BSCO2","BSHC","BSO2","BSNOx"];
% 
% for f = fieldsToAdd
%     dataVector = [BSem.(f)]';    
%     tableData.(f) = dataVector;   
% end
% 
% disp(tableData)