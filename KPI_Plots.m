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
% Defining which Files to use
fdaq_data_name  = ["Data\Diesel\20251124_0000002_Measurement 30% 14CA_fdaq.txt","Data\Diesel\20251124_0000003_Measurement 50% 14CA_fdaq.txt","Data\Diesel\20251124_0000004_Measurement 70% 14CA_fdaq.txt"];
sdaq_data_name  = ["Data\Diesel\20251124_0000002_Measurement 30% 14CA_sdaq.txt","Data\Diesel\20251124_0000003_Measurement 50% 14CA_sdaq.txt","Data\Diesel\20251124_0000004_Measurement 70% 14CA_sdaq.txt"];

% Giving measurements a name
name = ["Diesel_30L_14Ca","Diesel_50L_14Ca","Diesel_70L_14Ca"];
Load = [30               ,50               ,70];
Ca_exp=[14               ,14               ,14];

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
diesel_AFR_sto = 14.5;

% Actual Calculation

BSem = [];

for i=1:length(name)

    Current_Raw_data = Data_Extraction(fdaq_data_name(i),sdaq_data_name(i));
    Current_Power_data = CalculateWorkAndPower(Current_Raw_data.Ca,Current_Raw_data.p,Cyl);
    Current_BSem = KPICalculation(emissions_diesel(i),diesel_AFR_sto,Current_Raw_data.AVG_fuel_m_flow,Current_Power_data.W_net_avg);
    
    BSem = [BSem, Current_BSem];
end    

%% Plotting Example

figure;
plot(Load,[BSem.BSCO],"Marker","o","LineStyle","-")
grid on
xlabel("Load [%]")
ylabel("Brake Specific CO [g/kwh]")
title("Brake Specific CO emission over the Load")
xlim([0,100])
ylim([0,max([BSem.BSCO])*1.2])


