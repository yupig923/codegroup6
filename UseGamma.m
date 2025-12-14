clc; clear all; close all;
% Plotting gamma and show how to work with i

fuel = 'HVO';
emissions = ReadEmissionsData(fuel);

%Nasa Poly
global Runiv
Runiv = 8.314;
[SpS,El]        = myload('Nasa\NasaThermalDatabase.mat',{'CO','CO2','CH','O2','NO','N2','NO2'});
Mi = [SpS.Mass];
mm      = 1e-3;dm=0.1;
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
CaIVO = -355;
CaIVC = -135;
CaEVO = 149;
CaEVC = -344;
CaSOI = -3.2;
filename = AutoReadFilesFromFuels(fuel);

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

data = Data_Extraction(filename.fastfiles(1).relpath,filename.slowfiles(1).relpath);
tic
gammalist = gammafunc(emissions(1),fuel_specfic_AFR_sto,data.AVG_fuel_m_flow,data.p_filt,data.Ca);
toc

figure
%plot(data.Ca,Temperature)
xlabel('Crank angle [deg]')
ylabel('Temperature')
xlim([-90,180])
title("Temperature over the Crank Angle")
grid on
figure
hold on
plot(data.Ca,data.p,Color="r")
plot(data.Ca,data.p_filt,Color="g")
hold off
xlabel('Crank angle [deg]')
ylabel('Pressure')
grid on
figure
%plot(data.Ca,Volume)
xlabel('Crank angle [deg]')
ylabel('Volume of the cylinder')
grid on
figure;
hold on
for y = 1:1
    plot(data.Ca,gammalist)
end
hold off
xlabel('Crank angle [deg]')
ylabel('Gamma [\gamma]')
xlim([-90,180])
grid on
title("Gamma over the Crank Angle")

figure
%scatter(Temperature,gammalist)