function [data] = Data_Extraction(Filename_fdaq,Filename_sdaq)
% This function extracts the data from the files
% 
% Input:
%      -Filename_fdaq: Full path name of the "Fast" datafile
%           Example: "Data/Diesel/20251124_0000002_Measurement 30% 14CA_fdaq.txt"
%      -Filename_sdaq: Full path name of the "Slow" datafile
%           Example: "Data/Diesel/20251124_0000002_Measurement 30% 14CA_sdaq.txt"
%
% Output:
%      -data: This is a struct that contains all the data, with on each
%             colomn the data of a certain cycle.
% Added output fields:
%   data.p_pegged  - pegged in cylinder pressure [Pa]
%   data.p_avg     - cycle averaged pegged pressure trace [Pa]
%   data.Ca_avg    - crank angle vector associated with p_avg
%   data.p_filt    - filtered pressure

bara = 1e5;

% Extract the "Fast" Data
dataIn_fdaq     = table2array(readtable(Filename_fdaq));
[Nrows,~]       = size(dataIn_fdaq);                    
NdatapointsperCycle = 720/0.2;                    
Ncycles         = Nrows/NdatapointsperCycle;       

% Extract the "Slow" Data
dataIn_sdaq     = table2array(readtable(Filename_sdaq))';
[~,Ncolomns]    = size(dataIn_sdaq);

% check if the Data belong to eachother
if Ncycles ~= Ncolomns
    fprintf("Error in the Data_Extraction Function. Amount of Measurements do not match for the given Data files")
end

% Putting the data in a single struct
data.Ca              = reshape(dataIn_fdaq(:,1),[],Ncycles); % Crank Angle
data.p               = reshape(dataIn_fdaq(:,2),[],Ncycles)*bara; % In-cylinder Pressure
data.Inject_Current  = reshape(dataIn_fdaq(:,3),[],Ncycles); % Injector Current

data.Fuel_massflow   = dataIn_sdaq(1,:); % Total Mass flow of the fuel in that cycle
data.Intake_Temp     = dataIn_sdaq(2,:); % Intake Temperature
data.Exhaust_Temp    = dataIn_sdaq(3,:); % Exhaust Temperature
data.Intake_p        = dataIn_sdaq(4,:); % Intake Pressure
data.AVG_fuel_m_flow = mean(data.Fuel_massflow); % Average Mass flow of the fuel in that cycle

% =========================== Pegging ===========================
% convert intake pressure to Pa:
p_int = data.Intake_p * 1e5;     % [Pa]

Ca = data.Ca;  
p  = data.p;

% TDC is defined as 0 deg
TDCangle = 180;          
BDC_angle = TDCangle + 180; 

% find BDC index in the crank-angle array
[~, BDC_idx] = min(abs(Ca(:,1) - BDC_angle));

% apply pegging cycle-by-cycle
p_pegged = p;
for k = 1:Ncycles
    offset = p_int(k) - p(BDC_idx,k);
    p_pegged(:,k) = p(:,k) + offset;
end

% store in struct
data.p_pegged = p_pegged;       
data.p_avg    = mean(p_pegged(:, 2:end), 2);
data.Ca_avg   = Ca(:,1);        % first cycle crank-angle vector


% =========================== Filtering ===========================

p_avg = data.p_avg;

% Savitzky-Golay filter - mentioned in the handbook
try
    p_filt = sgolayfilt(p_avg, 3, 21);
catch
    %fallback
    w = ones(21,1) / 21;
    p_filt = filtfilt(w,1,p_avg);
end

data.p_filt = p_filt;   % store filtered pressure

end