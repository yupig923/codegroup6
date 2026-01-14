function gammalist = gammafunc(emissions,AFR_sto,fuel_m_flow,pressure,Ca)
% This function calculated the gamma for the pressure and Ca you give it.
% It can only do one data file at the time, so only one measurement with
% 200 cycles.
%
% Input:
%   - emissions: the emissions of that measurement. The function
%                "ReadEmissionsData" puts it in the correct form.
%                (struct)
%   - AFR_sto:   the stoichiometric air to fuel ratio of the fuel
%                (scalar)
%   - fuel_m_flow: the average fuel mass flow of the measurement
%                (scalar)
%   - pressure:  the filtered pressure of that measurement.
%                (double)(3600x1)
%   - Ca:        the crankangle of that measuremt.
%                (double)(3600x1)
%
% Output:
%   - gammalist: the gamma of that measurement.
%                (double)(3600x1)

[SpS,~]        = myload('Nasa\NasaThermalDatabase.mat',{'CO','CO2','CH','O2','NO','N2','NO2'}); % set which substances are in the air
Mi = [SpS.Mass];
mm      = 1e-3;
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
Runiv = 8.314;

% Find how much N2 there is in the air
volumefrac_N2 = 1-(emissions.CO+emissions.CO2+emissions.HC+emissions.O2+emissions.NOx);
   
% Go from Xair to Yair
Xair = [emissions.CO,emissions.CO2,emissions.HC,emissions.O2,0.85*emissions.NOx,0.15*emissions.NOx,volumefrac_N2];
Yair = Xair .* Mi;
Yair = Yair/sum(Yair);

Volume = CylinderVolume(Ca,Cyl);

% Find the Amount of air mass per cycle    
Actual_AFR = emissions.lambda*AFR_sto;
Exhaust_mass_flow = (Actual_AFR+1)*fuel_m_flow/1000; %in kg/s
Exhaust_mass_per_cycle = Exhaust_mass_flow/(1500/(60*2)); % in kg

% Find the Temperature
Temperature = (pressure .* Volume*(Xair*Mi'))/(Runiv * Exhaust_mass_per_cycle);

% Find the Gamma
[Cp,Cv,~,~] = ThermoMix(Yair, Temperature, SpS);
gammalist = Cp./Cv;
end