function [gammalist] = gammafunc(Fuel,AFR_sto)
%% Still work in Progress
emissions = ReadEmissionsData(Fuel);
[SpS,~]        = myload('Nasa\NasaThermalDatabase.mat',{'CO','CO2','CH','O2','NO','N2','NO2'});
Mi = [SpS.Mass];
mm      = 1e-3;
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
filename = AutoReadFilesFromFuels(Fuel);
gammalist = [];
for i = 1:length(emissions)
    data = Data_Extraction(filename.fastfiles(i).relpath,filename.slowfiles(i).relpath);
    volumefrac_N2 = 1-(emissions(i).CO+emissions(i).CO2+emissions(i).HC+emissions(i).O2+emissions(i).NOx);
   
    Xair = [emissions(i).CO,emissions(i).CO2,emissions(i).HC,emissions(i).O2,0.85*emissions(i).NOx,0.15*emissions(i).NOx,volumefrac_N2];
    Yair = Xair .* Mi;
    Yair = Yair/sum(Yair);
    
    Volume = CylinderVolume(data.Ca(:,1),Cyl);
    
    Actual_AFR = emissions(i).lambda*AFR_sto;
    Exhaust_mass_flow = (Actual_AFR+1)*data.AVG_fuel_m_flow/1000; %in kg/s
    Exhaust_mass_per_cycle = Exhaust_mass_flow/(1500/(60*2));

    Temperature = (data.p(:,index) .* Volume*(Xair*Mi'))/(Runiv * Exhaust_mass_per_cycle);


    for t = 1:length(Temperature)
        [Cp,Cv,~,~] = ThermoMix(Yair,Temperature(t),SpS);

        gammalist(t,i) = Cp/Cv;
    end
end
fprintf('Still Work in Progress. The calculation is there, but it does not process the data nicely. And it takes ages to run')
end