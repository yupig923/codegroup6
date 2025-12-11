clc; clear all; close all;

mm      = 1e-3; 
bara    = 1e5;
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;

fuel = 'HVO'; % Select the fuel you want to analyse
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

CA_list = zeros(nFiles,1);

for k = 1:nFiles
    fname = files_fdaq(k).name;

    CA_pos = strfind(fname, 'CA');
    CA_power_str = fname(CA_pos:end);

    CA_num = str2double(extractBetween(CA_power_str, 'CA', '-'));
    CA_list(k) = CA_num;
end

% Sort files based on CA
[~, sortIdx] = sort(CA_list);

% Reorder both fdaq and sdaq files in the same order
files_fdaq = files_fdaq(sortIdx);
files_sdaq = files_sdaq(sortIdx);

figure(1); clf; hold on
title('apparent Rate Of Heat Release vs Crank Angle'); xlabel('CA [deg]'); ylabel('aROHR [J/deg]');
xlim([-15 40]); grid on

figure(2); clf; hold on
title('apparent Heat Release vs Crank Angle'); xlabel('CA [deg]'); ylabel('aHR [J]');
xlim([-15 40]); grid on

figure(3); clf; hold on
title('apparent Rate Of Heat Release vs Crank Angle'); xlabel('CA [deg]'); ylabel('aROHR [J/deg]');
xlim([-15 40]); grid on

figure(4); clf; hold on
title('apparent Heat Release vs Crank Angle'); xlabel('CA [deg]'); ylabel('aHR [J]');
xlim([-15 40]); grid on

% CA colormap
CA_colors = lines(50);  

for k = 1:nFiles
    fdaq_file = fullfile(folder, files_fdaq(k).name);
    sdaq_file = fullfile(folder, files_sdaq(k).name);

    %% Extract CA and Power info from filename
    [~, fname, ~] = fileparts(fdaq_file);

    CA_pos = strfind(fname, 'CA');
    fuel_name = fname(1:CA_pos-2);
    CA_power_str = fname(CA_pos:end);

    CA_num = str2double(extractBetween(CA_power_str, 'CA', '-'));
    Power  = str2double(extractBetween(CA_power_str, '-', 'P'));

    data = Data_Extraction(fdaq_file, sdaq_file);
    [aROHR, aHR, CA10, CA50, CA90] = comb_cara(Cyl, iselect, fuel, data);

    CAx = data.Ca(:,iselect);

    % Power colors
    if Power == 30
        pcolor = [1 0 0];
    elseif Power == 50
        pcolor = [0 0 1];
    elseif Power == 70
        pcolor = [0 1 0];
    else
        pcolor = [0 0 0];
    end

    figure(1); 
    plot(CAx, aROHR, 'Color', pcolor, 'LineWidth', 1.5);

    figure(2);
    plot(CAx, aHR, 'Color', pcolor, 'LineWidth', 1.5);

    % Ca colors
    CAcolor = CA_colors(mod(CA_num, size(CA_colors,1))+1, :);

    figure(3);
    plot(CAx, aROHR, 'Color', CAcolor, 'DisplayName', ['CA' num2str(CA_num)], 'LineWidth', 1.5);

    figure(4);
    plot(CAx, aHR, 'Color', CAcolor, 'DisplayName', ['CA' num2str(CA_num)], 'LineWidth', 1.5);

end
figure(1)
hold on
legend({'30% Power','50% Power','70% Power'}, 'Location', 'best');

figure(2)
hold on
legend({'30% Power','50% Power','70% Power'}, 'Location', 'best');

figure(3);
legend show

figure(4);
legend show



for k = 1:nFiles

    fdaq_file = fullfile(folder, files_fdaq(k).name);
    sdaq_file = fullfile(folder, files_sdaq(k).name);

    fname = files_fdaq(k).name;
    
    CA_num = extractBetween(fname, "CA", "-");
    Power  = extractBetween(fname, "-", "P");
    fuel_name = erase(fname, extractAfter(fname, "_"));

    title_str = sprintf('%s - CA%s - %s%% power', fuel_name, CA_num{1}, Power{1});

    data = Data_Extraction(fdaq_file, sdaq_file);
    [aROHR, aHR, CA10, CA50, CA90] = comb_cara(Cyl, iselect, fuel, data);

    CAx = data.Ca(:,iselect);

    %% aROHR figure
    figure('Name', ['aROHR - File ' num2str(k)]);
    plot(CAx, aROHR, 'LineWidth', 1.5);
    grid on; xlim([-45 125])
    xlabel('Crank Angle [deg]'); ylabel('Rate of Heat Release [J/deg]');
    title(['aROHR vs CA: ' title_str]);

    %% aHR figure
    figure('Name', ['aHR - File ' num2str(k)]);
    plot(CAx, aHR, 'LineWidth', 1.5); hold on; grid on
    xlim([-45 125])
    xlabel('CA [deg]'); ylabel('aHR [J]');
    title(['Apparent Heat Release vs CA: ' title_str]);

    % Mark CA10, CA50, CA90
    aHR10 = interp1(CAx, aHR, CA10);
    aHR50 = interp1(CAx, aHR, CA50);
    aHR90 = interp1(CAx, aHR, CA90);

    plot(CA10, aHR10, 'r.', 'MarkerSize', 20)
    plot(CA50, aHR50, 'g.', 'MarkerSize', 20)
    plot(CA90, aHR90, 'b.', 'MarkerSize', 20)

    legend('aHR', 'CA10', 'CA50', 'CA90', 'Location', 'northwest');




    % Smooth the aHR curve using Savitzky–Golay filter
    frame  = 21;      % must be odd; increase for stronger smoothing
    order  = 3;       % polynomial order
    aHR_sm = sgolayfilt(aHR, order, frame);

    figure; hold on;
    plot(CAx, aHR_sm, 'LineWidth', 1.8)
    aHR10 = interp1(CAx, aHR_sm, CA10);
    aHR50 = interp1(CAx, aHR_sm, CA50);
    aHR90 = interp1(CAx, aHR_sm, CA90);
    plot(CA10, aHR10, 'r.', 'MarkerSize', 20)
    plot(CA50, aHR50, 'g.', 'MarkerSize', 20)
    plot(CA90, aHR90, 'b.', 'MarkerSize', 20)
    legend('aHR', 'CA10', 'CA50', 'CA90', 'Location', 'northwest');
    title('Apparent Heat Release vs CA (Smoothed)')
    xlabel('CA [deg]')
    ylabel('aHR [J]')
    grid on
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