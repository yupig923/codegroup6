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

% Defining which Fuel to use
fuels=['Dieselgroup22','HVO',"HVO+Diesel_Blend"];


fuelfields=[];
unique_CAs=[];
for i=1:length(fuels)
fuel=fuels(i);
Readfile_results=AutoReadFilesFromFuels(fuel);
Load=Readfile_results.P_vals;
Ca_exp=Readfile_results.CA_vals;

fdaq_data_name  =[Readfile_results.fastfiles.relpath];
sdaq_data_name  = [Readfile_results.slowfiles.relpath];

emissions_fuel=ReadEmissionsData(fuel);

% Instead of the file AF_sto
if strcmp(fuel, 'Diesel')
    fuel_specfic_AFR_sto = 14.5;
elseif strcmp(fuel, 'GTL_new')
    fuel_specfic_AFR_sto = 14.7;
elseif strcmp(fuel, 'GTL+Diesel_Blend')
    fuel_specfic_AFR_sto = 14.6;
elseif strcmp(fuel, 'HVO')
    fuel_specfic_AFR_sto = 14.55;
elseif strcmp(fuel, 'HVO+Diesel_Blend')
    fuel_specfic_AFR_sto = 14.525;
elseif strcmp(fuel, 'Dieselgroup22')
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


%% Calculate averaged values and error bars

% Get unique CA values
unique_CA = unique(Ca_exp);

fuelField = matlab.lang.makeValidName(fuel);
fuelfields=[fuelfields,fuelField];
unique_CAs.(fuelField)=unique_CA;
% Initialize arrays for averaged values and error bars
avg_BSNOx.(fuelField) = zeros(size(unique_CA));
avg_BSCO2.(fuelField) = zeros(size(unique_CA));
avg_BSCO.(fuelField) = zeros(size(unique_CA));
avg_BSFC.(fuelField) = zeros(size(unique_CA));
avg_eff.(fuelField) = zeros(size(unique_CA));

err_BSNOx.(fuelField) = zeros(size(unique_CA));
err_BSCO2.(fuelField) = zeros(size(unique_CA));
err_BSCO.(fuelField)  = zeros(size(unique_CA));
err_BSFC.(fuelField ) = zeros(size(unique_CA));
err_eff.(fuelField)   = zeros(size(unique_CA));

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
        avg_BSNOx.(fuelField)(i) = mean([BSem(idx_combined).BSNOx]);
        avg_BSCO2.(fuelField)(i) = mean([BSem(idx_combined).BSCO2]);
        avg_BSCO.(fuelField)(i) = mean([BSem(idx_combined).BSCO]);
        avg_BSFC.(fuelField)(i) = mean([BSem(idx_combined).BSFC]);
        avg_eff.(fuelField)(i) = mean([BSem(idx_combined).eff]);
        
        % Calculate error bars as (max - min)/2
        if ~isempty(idx_30) && ~isempty(idx_70)
            err_BSNOx.(fuelField)(i) = abs([BSem(idx_70).BSNOx] - [BSem(idx_30).BSNOx])/2;
            err_BSCO2.(fuelField)(i) = abs([BSem(idx_70).BSCO2] - [BSem(idx_30).BSCO2])/2;
            err_BSCO.(fuelField)(i) = abs([BSem(idx_70).BSCO] - [BSem(idx_30).BSCO])/2;
            err_BSFC.(fuelField)(i) = abs([BSem(idx_70).BSFC] - [BSem(idx_30).BSFC])/2;
            err_eff.(fuelField)(i) = abs([BSem(idx_70).eff] - [BSem(idx_30).eff])/2;
        end
    end
end




end

%% Plot all 4 BS KPIs with error bars all fuels included
figure;
hold on;

% Plot BSNOx
for i = 1:length(fuelfields)
plot(-unique_CAs.(fuelfields(i)), avg_BSNOx.(fuelfields(i)), "-o")
%errorbar(unique_CAs.(fuelfields(i)), avg_BSNOx.(fuelfields(i)), err_BSNOx.(fuelfields(i)), "-o", ...
%    "LineWidth", 2.5, ...
 %   "MarkerSize", 8, ...
  %  "DisplayName", fuels(i));

end
hold off;

xlabel("Injection Timing - CA [°]");
ylabel("Brake Specific Values [g/kWh]");
title("All BSNOx vs Injection Timing (Averaged over 30-70% Load)");
grid on;
legend(['Diesel','HVO',"HVO+Diesel Blend"],"Location","northwest");
xlim([-19 -3])



figure;
hold on;
for i = 1:length(fuelfields)
% Plot BSCO2
plot(-unique_CAs.(fuelfields(i)), avg_BSCO2.(fuelfields(i)), "-s")
%errorbar(unique_CAs.(fuelfields(i)), avg_BSCO2.(fuelfields(i)), err_BSCO2.(fuelfields(i)), "-s", ...
%    "LineWidth", 2.5, ...
%    "MarkerSize", 8, ...
%    "DisplayName", fuels(i));
end
hold off;

xlabel("Injection Timing - CA [°]");
ylabel("Brake Specific Values [g/kWh]");
title("All BSCO2 vs Injection Timing (Averaged over 30-70% Load)");
grid on;
legend(['Diesel','HVO',"HVO+Diesel Blend"],"Location","northwest");
xlim([-19 -3])



figure;
hold on;
for i = 1:length(fuelfields)
% Plot BSCO
plot(-unique_CAs.(fuelfields(i)), avg_BSCO.(fuelfields(i)), "-^")
%errorbar(unique_CAs.(fuelfields(i)), avg_BSCO.(fuelfields(i)), err_BSCO.(fuelfields(i)), "-^", ...
%    "LineWidth", 2.5, ...
%    "MarkerSize", 8, ...
%    "DisplayName", fuels(i));

end
hold off;

xlabel("Injection Timing - CA [°]");
ylabel("Brake Specific Values [g/kWh]");
title("All BSCO vs Injection Timing (Averaged over 30-70% Load)");
grid on;
legend(['Diesel','HVO',"HVO+Diesel Blend"],"Location","northwest");
xlim([-19 -3])


figure;
hold on;
for i = 1:length(fuelfields)
% Plot BSFC
plot(-unique_CAs.(fuelfields(i)), avg_BSFC.(fuelfields(i)), "-d")
%errorbar(unique_CAs.(fuelfields(i)), avg_BSFC.(fuelfields(i)), err_BSFC.(fuelfields(i)), "-d", ...
%    "LineWidth", 2.5, ...
%    "MarkerSize", 8, ...
%    "DisplayName", fuels(i));


end
hold off;


xlabel("Injection Timing - CA [°]");
ylabel("Brake Specific Values [g/kWh]");
title("All BSFC vs Injection Timing (Averaged over 30-70% Load)");
grid on;
legend(['Diesel','HVO',"HVO+Diesel Blend"],"Location","northwest");
xlim([-19 -3])



