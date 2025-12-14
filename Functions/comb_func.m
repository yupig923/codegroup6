function [aROHR, aHR, CA10, CA50, CA90] = comb_func(data,emissions,AFR_sto)
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

% aHR calculation
aHR = cumtrapz(Ca, aROHR); % calculates integral at every measering point

%CAx calculations
offset = find(Ca >= 0); %calculates when the graph goes above 0

aHR = aHR - aHR(offset(1)); 

[max_aHR,idx_max] = max(aHR);
aHR10 = 0.1 * max_aHR;
aHR50 = 0.5 * max_aHR;
aHR90 = 0.9 * max_aHR;

%find the value of the crank angle by looking into the crank angles between
%0 and 150 degrees

idx_min = find(aHR >= 0, 1, 'first');

idx = idx_min:idx_max;
CA10 = interp1(aHR(idx), Ca(idx), aHR10);
CA50 = interp1(aHR(idx), Ca(idx), aHR50);
CA90 = interp1(aHR(idx), Ca(idx), aHR90);
end
