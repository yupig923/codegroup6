clc; clear all; close all;

mm      = 1e-3; 
bara    = 1e5;
Cyl.Bore             = 104*mm;
Cyl.Stroke           = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod           = 136.5*mm;
Cyl.TDCangle         = 180;
global Runiv
Runiv = 8.314;

fuel = 'HVO'; % Select the fuel you want to analyse

% Find the AFR_sto of the fuel
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
elseif strcmp(fuel, 'Dieselgroup22')
    fuel_specfic_AFR_sto = 14.5; 
end

% Add paths
addpath('Nasa\')
addpath('Data\')
addpath('Functions\')

% Extract emission data
emissions = ReadEmissionsData(fuel);

filename = AutoReadFilesFromFuels(fuel);
nFiles = length(filename.fastfiles);

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


comb_data = struct;
comb_data.aROHR= [];
comb_data.aHR  = [];
comb_data.CA10 = [];
comb_data.CA50 = [];
comb_data.CA90 = [];
comb_data.Delay= [];
comb_data.SOIgnition=[];
comb_data.CA_num=[];


for k = 1:nFiles

    data = Data_Extraction(filename.fastfiles(k).relpath,filename.slowfiles(k).relpath);
    [aROHR, aHR, CA10, CA50, CA90, SOIgnition] = comb_func(data,emissions(k),fuel_specfic_AFR_sto);

    comb_data.aROHR(:,k) = aROHR;
    comb_data.aHR(:,k) = aHR;
    comb_data.CA10(k) =CA10;
    comb_data.CA50(k) =CA50;
    comb_data.CA90(k) =CA90;
    comb_data.SOIgnition(k)=SOIgnition;
    CA_num = filename.CA_vals(k);
    Power  = filename.P_vals(k);
    comb_data.CA_num(k)=CA_num;
    comb_data.Delay(:,k) = SOIgnition + CA_num;

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
    
    CAx = data.Ca_avg;
    
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

    title_str = sprintf('%s - CA%s - %s%% power', fuel, num2str(CA_num), num2str(Power));





    %% aROHR figure
    figure('Name', ['aROHR - File ' num2str(k)]);
    plot(CAx, aROHR, 'LineWidth', 1.5);
    grid on; 
    xlim([-15 40])
    xlabel('Crank Angle [deg]'); ylabel('Rate of Heat Release [J/deg]');
    title(['aROHR vs CA: ' title_str]);

    %% aHR figure
    figure('Name', ['aHR - File ' num2str(k)]);
    plot(CAx, aHR, 'LineWidth', 1.5); hold on; grid on
    xlim([-15 40])
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


end

figure(1)
hold on
legend({'30% Power','50% Power','70% Power'}, 'Location', 'northwest');

figure(2)
hold on
legend({'30% Power','50% Power','70% Power'}, 'Location', 'best');

figure(3);
legend show

figure(4);
legend show

%% Print Results

% Create final table
Results = table(round(filename.P_vals,1),-round(filename.CA_vals,1), round(comb_data.CA10',1), round(comb_data.CA50',1), round(comb_data.CA90',1),round(comb_data.SOIgnition',1),round(comb_data.Delay',1));
Results.Properties.VariableNames = {'Percentage','Injection','CA10','CA50','CA90','Ignition','Delay'};

% Display
disp(' ');
disp(['====================== FINAL RESULTS TABLE (' fuel ') ======================']);
disp( '====================== All the angles are in ATDC ========================' );
disp(Results);

% Extract data from Results table
InjectionTiming = Results.Injection;
Load = Results.Percentage;
CA50_vals = Results.CA50;

% Get unique loads for colors
loads = unique(Load);
colors = lines(length(loads));

%% 3D Plot - CA50 vs Injection Timing vs Load
figure;
hold on;

% Plot each load as a separate line in 3D space
for i = 1:length(loads)
    idx = (Load == loads(i));
    plot3(InjectionTiming(idx), Load(idx), CA50_vals(idx), '-o', ...
        'LineWidth', 3, ...
        'MarkerSize', 10, ...
        'MarkerFaceColor', colors(i,:), ...
        'Color', colors(i,:), ...
        'DisplayName', sprintf('%d%% Load', loads(i)));
end

grid on;
xlabel('Injection Timing [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Load [%]', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('CA50 [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
title('CA50 Response to Injection Timing and Load', 'FontSize', 14);
legend('Location', 'best');
set(gca, 'FontSize', 11);
view(45, 20);
box on;

% Get unique values
loads = unique(Load);
InjTimings = unique(InjectionTiming);

%% Heatmap
figure;
% Create matrix for heatmap
CA50_matrix = zeros(length(loads), length(InjTimings));
for i = 1:length(loads)
    for j = 1:length(InjTimings)
        idx = (Load == loads(i)) & (InjectionTiming == InjTimings(j));
        CA50_matrix(i,j) = CA50_vals(idx);
    end
end

h = heatmap(InjTimings, loads, CA50_matrix);
h.Title = 'CA50 Heatmap';
h.XLabel = 'Injection Timing [°ATDC]';
h.YLabel = 'Load [%]';
h.Colormap = hot;
h.ColorbarVisible = 'on';
h.FontSize = 11;

%% Surface Plot
figure;
% Create a finer grid for smooth surface
[IT_grid, Load_grid] = meshgrid(linspace(min(InjectionTiming), max(InjectionTiming), 50), ...
                                 linspace(min(Load), max(Load), 50));
CA50_grid = griddata(InjectionTiming, Load, CA50_vals, IT_grid, Load_grid, 'cubic');

% Plot surface
surf(IT_grid, Load_grid, CA50_grid, 'EdgeAlpha', 0.3, 'FaceAlpha', 0.8);
hold on;

% Overlay actual data points
scatter3(InjectionTiming, Load, CA50_vals, 100, 'r', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

xlabel('Injection Timing [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Load [%]', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('CA50 [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
title('CA50 Response Surface', 'FontSize', 14);
colorbar;
colormap('jet');
view(45, 20);
grid on;
box on;
set(gca, 'FontSize', 11);

%Delay Surface Plot
figure;
% Create a finer grid for smooth surface
[IT_grid, Load_grid] = meshgrid(linspace(min(InjectionTiming), max(InjectionTiming), 50), ...
                                 linspace(min(Load), max(Load), 50));
Delay_grid = griddata(InjectionTiming, Load, comb_data.Delay, IT_grid, Load_grid, 'cubic');

% Plot surface
surf(IT_grid, Load_grid, Delay_grid, 'EdgeAlpha', 0.3, 'FaceAlpha', 0.8);
hold on;

% Overlay actual data points
scatter3(InjectionTiming, Load, comb_data.Delay, 100, 'r', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

xlabel('Injection Timing [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Load [%]', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('Delay [°ATDC]', 'FontSize', 12, 'FontWeight', 'bold');
title('Injection Delay Surface', 'FontSize', 14);
colorbar;
colormap('jet');
view(45, 20);
grid on;
box on;
set(gca, 'FontSize', 11);


clear all;

% Units
mm      = 1e-3;dm=0.1;
bara    = 1e5;
MJ      = 1e6;
kWhr    = 1000*3600;
volperc = 0.01; % Emissions are in volume percentages
ppm     = 1e-6; % Some are in ppm (also a volume- not a mass-fraction)
g       = 1e-3;
s       = 1;
% Engine geom data (check if these are correct)
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
addpath('Nasa\')
addpath('Data\')
addpath('Functions\')
global Runiv
Runiv = 8.314;

% Defining which Fuel to use
fuels=['Dieselgroup22','HVO',"HVO+Diesel_Blend","GTL"];

% Defining which Injection Timing to use:
Injection_Timing = 11;
Load_wanted = 50;


comb_data = struct;
comb_data.aROHR= [];
comb_data.aHR  = [];
comb_data.CA10 = [];
comb_data.CA50 = [];
comb_data.CA90 = [];
comb_data.Delay= [];
comb_data.SOIgnition=[];
comb_data.CA_num=[];
comb_data.CA_avg = [];

fuelfields=[];
unique_CAs=[];
for i=1:length(fuels)
fuel=fuels(i);
Readfile_results=AutoReadFilesFromFuels(fuel);
Load=Readfile_results. P_vals;
Ca_exp=Readfile_results.CA_vals;
index_data = [];
for g = 1:length(Ca_exp)
    if fuel == "HVO+Diesel_Blend"
        index_data = [index_data,6];
        break
    end
    if Ca_exp(g) == Injection_Timing
        if Load(g) == Load_wanted
            index_data = [index_data,g];
        end
    end
end

fdaq_data_name  =[Readfile_results.fastfiles(index_data).relpath];
sdaq_data_name  = [Readfile_results.slowfiles(index_data).relpath];
emissions_fuel=ReadEmissionsData(fuel);



% Instead of the file AF_sto
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
elseif strcmp(fuel, 'Dieselgroup22')
    fuel_specfic_AFR_sto = 14.5;
end

data = Data_Extraction(fdaq_data_name,sdaq_data_name);
[aROHR, aHR, CA10, CA50, CA90, SOIgnition] = comb_func(data,emissions_fuel(index_data),fuel_specfic_AFR_sto);


    comb_data.aROHR(:,i) = aROHR;
    comb_data.aHR(:,i) = aHR;
    comb_data.CA10(i) =CA10;
    comb_data.CA50(i) =CA50;
    comb_data.CA90(i) =CA90;
    comb_data.SOIgnition(i)=SOIgnition;
    CA_num = Readfile_results.CA_vals(i);
    Power  = Readfile_results.P_vals(i);
    comb_data.CA_num(i)=CA_num;
    comb_data.Delay(:,i) = SOIgnition + CA_num;
    comb_data.CA_avg(:,i) = data.Ca_avg;


end

figure;

plot(comb_data.CA_avg,comb_data.aROHR, 'LineWidth', 1.5)
    xlim([-15 40])
    xlabel('CA [°]'); ylabel('aROHR [J]');
    title('apparent Rate of Heat Release vs CA');
    legend(['Diesel','HVO',"HVO+Diesel Blend","GTL"],"Location","northwest");
figure;
plot(comb_data.CA_avg,comb_data.aHR)
xlim([-15 40])