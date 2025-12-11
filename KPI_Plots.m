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
fuel="HVO";
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
figure; hold on;
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


%% Plot BSCO2
figure; hold on;
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

figure;


plot(Load, [BSem.BSCO2], "Marker","o","LineStyle","-")

grid on
xlabel("Load [%]")
ylabel("Brake Specific CO2 [g/kwh]")
title("Brake Specific CO2 emission over the Load")
xlim([0,100])
ylim([0,max([BSem.BSCO2])*1.2])

%3D Scatter Plot
figure;
scatter3(Load, Ca_exp, [BSem.BSCO2], "filled")
grid on
xlabel("Load [%]")
ylabel("CA [°]")
zlabel("Brake Specific CO₂ [g/kWh]")
title("Brake Specific CO₂ Emission over Load and CA")
xlim([0 100])

%Add intermediate Values for Mesh Plot
F = scatteredInterpolant(Load, Ca_exp, [BSem.BSCO2]', 'natural', 'none');
figure;
% Create meshgrid for surface
xq = linspace(0, 75, 5);
yq = linspace(0, 20, 0.5);
[Xq, Yq] = meshgrid(xq, yq);
Zq = F(Xq, Yq);

% Mesh Plot 

surf(Xq, Yq, Zq, 'EdgeColor', 'none', 'FaceAlpha', 0.85)
hold on
scatter3(Load, Ca_exp, [BSem.BSCO2], 70, 'filled', 'MarkerEdgeColor', 'k')
hold off

grid on
xlabel("Load [%]")
ylabel("CA [°]")
zlabel("Brake Specific CO₂ [g/kWh]")
title("Interpolated Brake Specific CO₂ Surface")
colorbar


N = length(BSem);

Load_col   = Load(:);
CA_col     = Ca_exp(:);

fieldNames = fieldnames(BSem);

tableData = table(Load_col, CA_col, 'VariableNames', {'Load_percent','CA_deg'});
fieldsToAdd = ["BSFC","BSCO","BSCO2","BSHC","BSO2","BSNOx"];

for f = fieldsToAdd
    dataVector = [BSem.(f)]';    
    tableData.(f) = dataVector;   
end

disp(tableData)