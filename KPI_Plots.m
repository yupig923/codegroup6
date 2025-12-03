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

%% Actual Code
% Defining which Fuel to use
fuel="Diesel"
Readfile_results=AutoReadFilesFromFuels(fuel);
Load=Readfile_results.P_vals;
Ca_exp=Readfile_results.CA_vals;

fdaq_data_name  =[Readfile_results.fastfiles.relpath];
sdaq_data_name  = [Readfile_results.slowfiles.relpath];

% Emission data
emissions_30L_14Ca_Diesel = struct();
emissions_30L_14Ca_Diesel.CO  = 0.04  *volperc;
emissions_30L_14Ca_Diesel.CO2 = 1.61  *volperc;
emissions_30L_14Ca_Diesel.HC  = 9*10  *ppm;
emissions_30L_14Ca_Diesel.O2  = 18.54 *volperc;
emissions_30L_14Ca_Diesel.NOx = 203   *ppm;
emissions_30L_14Ca_Diesel.lambda = 8.634;

emissions_50L_14Ca = struct();
emissions_50L_14Ca.CO  = 0.04  *volperc;
emissions_50L_14Ca.CO2 = 2.45  *volperc;
emissions_50L_14Ca.HC  = 10*10 *ppm;
emissions_50L_14Ca.O2  = 17.54 *volperc;
emissions_50L_14Ca.NOx = 527   *ppm;
emissions_50L_14Ca.lambda = 5.789;

emissions_70L_14Ca = struct();
emissions_70L_14Ca.CO  = 0.02  *volperc;
emissions_70L_14Ca.CO2 = 3.17  *volperc;
emissions_70L_14Ca.HC  = 5*10  *ppm;
emissions_70L_14Ca.O2  = 16.42 *volperc;
emissions_70L_14Ca.NOx = 1135  *ppm;
emissions_70L_14Ca.lambda = 4.508;

emissions_diesel = [emissions_30L_14Ca_Diesel,emissions_50L_14Ca,emissions_70L_14Ca];

AFR_sto_filename = 'Data/AFR_sto.xlsx';
AFR_sto_data = readtable(AFR_sto_filename);
fuel_specfic_AFR_sto = AFR_sto_data.(fuel);

% Actual Calculation

BSem = [];

for i=1:length(fdaq_data_name)

    Current_Raw_data = Data_Extraction(fdaq_data_name(i),sdaq_data_name(i));
    Current_Power_data = CalculateWorkAndPower(Current_Raw_data.Ca,Current_Raw_data.p,Cyl);
    Current_BSem = KPICalculation(emissions_diesel(i),fuel_specfic_AFR_sto,Current_Raw_data.AVG_fuel_m_flow,Current_Power_data.power);
    
    BSem = [BSem, Current_BSem];
end    

%% Plotting Example

figure;
plot(Load,[BSem.BSCO2],"Marker","o","LineStyle","-")
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
F = scatteredInterpolant(Load, Ca_exp, [BSem.BSCO2], 'natural', 'none');
figure;
% Create meshgrid for surface
xq = linspace(min(Load), max(Load), 50);
yq = linspace(min(Ca_exp), max(Ca_exp), 50);
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