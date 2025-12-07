clc; clear all; close all;

mm      = 1e-3; 
bara    = 1e5;
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;

fuel = 'GTL'; % Select the fuel you want to analyse
iselect = 10; % Select which cycle you want to analyse

% Add paths
addpath('Nasa\')
addpath('Data\')
addpath('Functions\')

% Automatically find fdaq and sdaq files
folder = fullfile('Data', fuel);
files_fdaq = dir(fullfile(folder, '*fdaq.txt'));
files_sdaq = dir(fullfile(folder, '*sdaq.txt'));

nFiles = min(length(files_fdaq), length(files_sdaq));


%plot all the experiments only for 1 cycle otherwise to messy
for k = 1:nFiles
    fdaq_file = fullfile(folder, files_fdaq(k).name);
    sdaq_file = fullfile(folder, files_sdaq(k).name);

    %% Extract CA and Power info from filename for the titles of the plots
    [~, fname, ~] = fileparts(fdaq_file); % fname = 'FuelName_CA50-30P_fdaq' or 'FuelName+Diesel_Blend_CA50-30P_fdaq'
    
    CA_pos = strfind(fname, 'CA'); 
    if isempty(CA_pos)
        title_str = fname; 
    else
        fuel_name = fname(1:CA_pos-2);
        CA_power_str = fname(CA_pos:end); 
        CA_num = extractBetween(CA_power_str, 'CA', '-'); 
        Power = extractBetween(CA_power_str, '-', 'P');   
        title_str = [fuel_name ' - CA' CA_num ' - ' Power '% power'];
    end

    data = Data_Extraction(fdaq_file, sdaq_file); % load data

    [aROHR, aHR, CA10, CA50, CA90] = comb_cara(Cyl, iselect, fuel, data); %function 

    %% Plots
    %Plot aROHR
    figure('Name', ['aROHR - File ' num2str(k)]);
    plot(data.Ca(:,iselect), aROHR, 'LineWidth', 1.5);
    grid on;
    xlim([-45 125])
    xlabel('Crank Angle [deg]');
    ylabel('Rate of Heat Release [J/deg]');
    title(['aROHR vs Crank Angle: ' title_str]);

    % Plot aHR
    figure('Name', ['aHR - File ' num2str(k)]);
    plot(data.Ca(:,iselect), aHR, 'LineWidth', 1.5)
    xlim([-45 125])
    xlabel('CA [deg]'); 
    ylabel('aHR [J]');
    title(['Apparent Heat Release vs Crank Angle: ' title_str])
    grid on
    hold on

    % Plot CAx
    aHR10 = interp1(data.Ca(:,iselect), aHR, CA10);
    aHR50 = interp1(data.Ca(:,iselect), aHR, CA50);
    aHR90 = interp1(data.Ca(:,iselect), aHR, CA90);

    plot(CA10, aHR10, 'r.', 'MarkerSize', 20)
    plot(CA50, aHR50, 'g.', 'MarkerSize', 20)
    plot(CA90, aHR90, 'b.', 'MarkerSize', 20)
    legend('aHR vs CA', 'CA10', 'CA50', 'CA90', 'Location', 'northwest')
end


%% function for combustion characteristics
function [aROHR, aHR, CA10, CA50, CA90] = comb_cara(Cyl, iselect, fuel, data)
mm      = 1e-3; 
bara    = 1e5;
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;

%fuel gamma's
if strcmp(fuel, 'Diesel')
    gamma = 1.34; 
elseif strcmp(fuel, 'HVO')
    gamma = 1.30;
elseif strcmp(fuel, 'HVO+Diesel_Blend')
    gamma = 1.32;
elseif strcmp(fuel, 'GTL')
    gamma = 1.3;
elseif strcmp(fuel, 'GTL+Diesel_Blend')
    gamma = 1.3;
end

% extract data from the data_extraction file
p = data.p_filt;
Ca = data.Ca;

%partial derivatives for aROHR formula
dp_dCA = gradient(p, Ca(:,iselect));
dV_dCA = gradient(CylinderVolume(Ca(:,iselect), Cyl), Ca(:,iselect));

% aROHR calculation
aROHR = gamma/(gamma-1) * (p) .* dV_dCA + 1/(gamma-1) * CylinderVolume(Ca(:,iselect), Cyl) .* dp_dCA;   % [J/deg]

% aHR calculation
aHR = cumtrapz(Ca(:,iselect), aROHR); % calculates integral at every measering point

%CAx calculations
offset = find(Ca(:,iselect) >= 0); %calculates when the graph goes above 0 

aHR = aHR - aHR(offset(1)); 

aHR10 = 0.1 * max(aHR);
aHR50 = 0.5 * max(aHR);
aHR90 = 0.9 * max(aHR);


%find the value of the crank angle by looking into the crank angles between
%0 and 150 degrees
idx = (Ca(:,iselect) >= 0 & Ca(:,iselect) <= 150);
CA10 = interp1(aHR(idx), Ca(idx, iselect), aHR10);
CA50 = interp1(aHR(idx), Ca(idx, iselect), aHR50);
CA90 = interp1(aHR(idx), Ca(idx, iselect), aHR90);
end