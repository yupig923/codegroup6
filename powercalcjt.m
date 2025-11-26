%% Info
% 1500 RPM
% SOA van 4.2º voor TDC
% Resolutie van 0.2º CA
% Data voor 69 cycles (maximale van de Smetec, de OGO gensets kunnen in principe "onbeperkt" aan)
% 
%% init
clear all; clc;close all;
addpath( "Functions","Nasa");
%% Units
mm      = 1e-3;dm=0.1;
bara    = 1e5;
MJ      = 1e6;
kWhr    = 1000*3600;
volperc = 0.01; % Emissions are in volume percentages
ppm     = 1e-6; % Some are in ppm (also a volume- not a mass-fraction)
g       = 1e-3;
s       = 1;
%% Load NASA 
% Global (for the Nasa database in case you wish to use it).
global Runiv
Runiv = 8.314;
[SpS,El]        = myload('Nasa\NasaThermalDatabase.mat',{'Diesel','O2','N2','CO2','H2O'});
%% Engine geom data (check if these are correct)
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
% -- Valve closing events can sometimes be seen in fast oscillations in the pressure signal (due
% to the impact when the Valve hits its seat).
CaIVO = -355;
CaIVC = -135;
CaEVO = 149;
CaEVC = -344;
CaSOI = -3.2;
% Write a function [V] = CylinderVolume(Ca,Cyl) that will give you Volume
% for the given Cyl geometry. If you can do that you can create pV-diagrams
%% Load data (if txt file)
FullName        = fullfile('Data','ExampleDataSet.txt');
dataIn          = table2array(readtable(FullName));
[Nrows,Ncols]   = size(dataIn);                    % Determine size of array
NdatapointsperCycle = 720/0.2;                     % Nrows is a multitude of NdatapointsperCycle
Ncycles         = Nrows/NdatapointsperCycle;       % This must be an integer. If not checkwhat is going on
Ca              = reshape(dataIn(:,1),[],Ncycles); % Both p and Ca are now matrices of size (NCa,Ncycles)
p               = reshape(dataIn(:,2),[],Ncycles)*bara; % type 'help reshape' in the command window if you want to know what it does (reshape is a Matlab buit-in command
%% Plotting 
f1=figure(1);           
pp = plot(Ca,p/bara,'LineWidth',1);                 % Plots the whole matrix
xlabel('Ca');ylabel('p [bar]');                     % Always add axis labels
xlim([-360 360]);ylim([0 50]);                      % Matter of taste
iselect = 10;                                    % Plot cycle 10 again in the same plot to emphasize it. Just to show how to access individual cycles.
line(Ca(:,iselect),p(:,iselect)/bara,'LineWidth',2,'Color','r');
YLIM = ylim;
% Add some extras to the plot
line([CaIVC CaIVC],YLIM,'LineWidth',1,'Color','b'); % Plot a vertical line at IVC. Just for reference not a particular reason.
line([CaEVO CaEVO],YLIM,'LineWidth',1,'Color','r'); % Plot a vertical line at EVO. Just for reference not a particular reason.
set(gca,'XTick',[-360:60:360],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title('All cycles in one plot.')

%% pV-diagram using Modified Cosine (Linear Scale)
[~,V] = CylinderVolume(Ca(:,iselect),Cyl);  % Only use modified cosine (second output)

f2 = figure(2);
plot(V/dm^3,p(:,iselect)/bara,"Color","#00B4D8");
xlabel('V [dm^3]');ylabel('p [bar]');               % Always add axis labels
xlim([0 0.8]);ylim([0.5 50]);                      % Matter of taste
set(gca,'XTick',[0:0.1:0.8],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title({'pV-diagram (Modified Cosine) - Linear Scale'})

%% pV-diagram using Modified Cosine (Logarithmic Scale)
f3 = figure(3);
loglog(V/dm^3,p(:,iselect)/bara,"Color","#00B4D8");
xlabel('V [dm^3] (logarithmic scale)');ylabel('p [bar] (logarithmic scale)');               % Always add axis labels
xlim([0.02 0.8]);ylim([0.5 50]);                      % Matter of taste
set(gca,'XTick',[0.02 0.05 0.1 0.2 0.5 0.8],...
    'YTick',[0.5 1 2 5 10 20 50],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title({'pV-diagram (Modified Cosine) - Logarithmic Scale'})

%% Calculate Work from pV-diagram
% Work is the integral of p dV over the complete cycle
% W = ∮ p dV (closed loop integral)

% Calculate net work by integrating p dV over the entire cycle
W_net = trapz(V, p(:,iselect));

% Display results
fprintf('\n=== Work Calculation for Cycle %d ===\n', iselect);
fprintf('Net work per cycle: %.2f J\n', W_net);
fprintf('Net work per cycle: %.3f kJ\n', W_net/1000);

%% Visualize the work calculation area
f4 = figure(4);
% Fill the area enclosed by the pV loop
fill(V/dm^3, p(:,iselect)/bara, [0 0.7 0.85], 'FaceAlpha', 0.3, 'EdgeColor', [0 0.7 0.85], 'LineWidth', 2);
hold on;
% Mark the start/end point (red dot removed)
% plot(V(1)/dm^3, p(1,iselect)/bara, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
% text(V(1)/dm^3 + 0.02, p(1,iselect)/bara, 'Start/End', 'FontSize', 10);
hold off;
xlabel('V [dm^3]');
ylabel('p [bar]');
xlim([0 0.8]);
ylim([0.5 50]);
set(gca,'XTick',[0:0.1:0.8],'XGrid','on','YGrid','on');
title(sprintf('Work Area Visualization - Net Work = %.2f J', W_net));
legend('Enclosed area = Work', 'Location', 'northeast');

%% Calculate Work for ALL 69 cycles and perform power analysis
fprintf('\n=== Work Calculation for ALL %d Cycles ===\n', Ncycles);

% Preallocate array for work values
W_net_all = zeros(1, Ncycles);

% Calculate work for each cycle
for i = 1:Ncycles
    [~, V_cycle] = CylinderVolume(Ca(:,i), Cyl);
    W_net_all(i) = trapz(V_cycle, p(:,i));
end

% Calculate statistics
W_net_avg = mean(W_net_all);
W_net_std = std(W_net_all);
W_net_cov = (W_net_std / W_net_avg) * 100; % Coefficient of variation in %

% Calculate power (assuming 1500 RPM from the info section)
RPM = 1500;
cycles_per_second = RPM / (2 * 60); % For 4-stroke engine, 1 cycle per 2 revolutions
power = W_net_avg * cycles_per_second; % Power in Watts

% Display results
fprintf('Average net work per cycle: %.2f J\n', W_net_avg);
fprintf('Standard deviation: %.2f J\n', W_net_std);
fprintf('Coefficient of variation: %.1f%%\n', W_net_cov);
fprintf('Minimum work: %.2f J (cycle %d)\n', min(W_net_all), find(W_net_all == min(W_net_all), 1));
fprintf('Maximum work: %.2f J (cycle %d)\n', max(W_net_all), find(W_net_all == max(W_net_all), 1));
fprintf('\nPower Calculation (%.0f RPM):\n', RPM);
fprintf('Power: %.2f W\n', power);
fprintf('Power: %.3f kW\n', power/1000);
fprintf('Power: %.3f HP\n', power/745.7);

%% Plot Work vs Cycle Number
f5 = figure(5);
cycle_numbers = 1:Ncycles;
plot(cycle_numbers, W_net_all/1000, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', 'b');
hold on;
yline(W_net_avg/1000, 'r--', 'LineWidth', 2, 'Label', sprintf('Average = %.3f kJ', W_net_avg/1000));
yline((W_net_avg + W_net_std)/1000, 'g--', 'LineWidth', 1, 'Label', '+1σ');
yline((W_net_avg - W_net_std)/1000, 'g--', 'LineWidth', 1, 'Label', '-1σ');
hold off;
xlabel('Cycle Number');
ylabel('Net Work [kJ]');
title(sprintf('Work per Cycle (Average = %.3f kJ, σ = %.3f kJ)', W_net_avg/1000, W_net_std/1000));
set(gca, 'XGrid', 'on', 'YGrid', 'on');
xlim([1 Ncycles]);
legend('Cycle Work', 'Average', '±1 Standard Deviation', 'Location', 'best');

%% Plot Histogram of Work Distribution
f6 = figure(6);
histogram(W_net_all/1000, 15, 'FaceColor', [0.2 0.6 0.8], 'FaceAlpha', 0.7);
xlabel('Net Work [kJ]');
ylabel('Frequency');
title(sprintf('Distribution of Work per Cycle (n = %d cycles)', Ncycles));
hold on;
xline(W_net_avg/1000, 'r--', 'LineWidth', 2, 'Label', sprintf('Mean = %.3f kJ', W_net_avg/1000));
xline((W_net_avg + W_net_std)/1000, 'g--', 'LineWidth', 1, 'Label', sprintf('+1σ = %.3f kJ', W_net_std/1000));
xline((W_net_avg - W_net_std)/1000, 'g--', 'LineWidth', 1, 'Label', sprintf('-1σ = %.3f kJ', W_net_std/1000));
hold off;
set(gca, 'XGrid', 'on', 'YGrid', 'on');