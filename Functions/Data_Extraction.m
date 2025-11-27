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

bara = 1e5;

% Extraction the "Fast" Data
dataIn_fdaq     = table2array(readtable(Filename_fdaq));
[Nrows,~]       = size(dataIn_fdaq);                    
NdatapointsperCycle = 720/0.2;                    
Ncycles         = Nrows/NdatapointsperCycle;       

% Extraction the "Slow" Data
dataIn_sdaq     = table2array(readtable(Filename_sdaq))';
[~,Ncolomns]    = size(dataIn_sdaq);

% Small check if the Data belong to eachother
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