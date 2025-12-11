clc; clear all; close all;
% Plotting gamma and show how to work with i

Fuel = 'HVO';
emissions = ReadEmissionsData(Fuel);

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
filename = AutoReadFilesFromFuels(Fuel);

index = 10; %choose to only look at this cycle


gammalist = [];
for i = 1:length(emissions)
    data = Data_Extraction(filename.fastfiles(i).relpath,filename.slowfiles(i).relpath);
    volumefrac_N2 = 1-(emissions(i).CO+emissions(i).CO2+emissions(i).HC+emissions(i).O2+emissions(i).NOx);
   
    Xair = [emissions(i).CO,emissions(i).CO2,emissions(i).HC,emissions(i).O2,0.85*emissions(i).NOx,0.15*emissions(i).NOx,volumefrac_N2];
    Yair = Xair .* Mi;
    Yair = Yair/sum(Yair);
    
    Volume = CylinderVolume(data.Ca(:,index),Cyl);
    
    AFR_sto = 14.5;
    Actual_AFR = emissions(i).lambda*AFR_sto;
    Exhaust_mass_flow = (Actual_AFR+1)*data.AVG_fuel_m_flow/1000; %in kg/s
    Exhaust_mass_per_cycle = Exhaust_mass_flow/(1500/(60*2));

    Temperature = (data.p(:,index) .* Volume*(Xair*Mi'))/(Runiv * Exhaust_mass_per_cycle);


    for t = 1:length(Temperature)
        [Cp,Cv,~,~] = ThermoMix(Yair,Temperature(t),SpS);

        gammalist(t,i) = Cp/Cv;
    end

end
figure
plot(data.Ca,Temperature)
xlabel('Crank angle [deg]')
ylabel('Temperature')
grid on
figure
plot(data.Ca,data.p(:,index))
xlabel('Crank angle [deg]')
ylabel('Pressure')
grid on
figure
plot(data.Ca,Volume)
xlabel('Crank angle [deg]')
ylabel('Volume of the cylinder')
grid on
figure;
hold on
for y = 1:15
    plot(data.Ca(:,index),gammalist(:,y))
end
hold off
xlabel('Crank angle [deg]')
ylabel('Gamma [\gamma]')
grid on