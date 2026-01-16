function [aROHR, aHR, CA10, CA50, CA90, SOIgnition] = comb_func(data,emissions,AFR_sto)
% Computes all the combustion characteristics data
%
% Inputs:
%   data : The data struct made by Data_Extraction.m
%   emissions : The emissions struct made by ReadEmissionsData.m
%   AFR_sto : the stoichiometric Air to Fuel ratio
%
% Output:
%   aROHR : array containing apparent Rate of Heat Release
%   aHR : array containing apparent Heat Release
%   CA10 : array containing the CA10
%   CA50 : array containing the CA50
%   CA90 : array containing the CA90
%   SOIgnition : array containing the Start of Ignition

mm      = 1e-3; 
bara    = 1e5;
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;

Ca = data.Ca_avg;
p = data.p_filt;

%calculate gamma
gammalist = gammafunc(emissions,AFR_sto,data.AVG_fuel_m_flow,p,Ca);

%Volume
Volume = CylinderVolume(Ca,Cyl);

%partial derivatives for aROHR formula
dp_dCA = gradient(p,Ca);
dV_dCA = gradient(Volume, Ca);

% aROHR calculation
aROHR = [];
for i = 1:length(gammalist)
    aROHR_calc = gammalist(i)/(gammalist(i)-1) * (p(i)) * dV_dCA(i) + 1/(gammalist(i)-1) * Volume(i) * dp_dCA(i);   % [J/deg]
    aROHR = [aROHR;aROHR_calc];
end

% Find Start of Ignition
[~,idx_SOI_temp] = max(aROHR);
while true
    idx_SOI_temp = idx_SOI_temp - 1;
    if aROHR(idx_SOI_temp) <= 0
        idx_SOIgnition = idx_SOI_temp;
        SOIgnition = Ca(idx_SOIgnition); %Transfer Index to Crank Angle
        break
    end
end

% aHR calculation
aHR = cumtrapz(Ca, aROHR);

%CA10,CA50 and CA90 calculation
aHR = aHR - aHR(idx_SOIgnition);

[max_aHR,idx_max] = max(aHR);
aHR10 = 0.1 * max_aHR;
aHR50 = 0.5 * max_aHR;
aHR90 = 0.9 * max_aHR;

idx_min = idx_SOIgnition;

idx = idx_min:idx_max;
CA10 = interp1(aHR(idx), Ca(idx), aHR10);
CA50 = interp1(aHR(idx), Ca(idx), aHR50);
CA90 = interp1(aHR(idx), Ca(idx), aHR90);
end
