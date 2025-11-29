%% Info
% 1500 RPM
% SOA van 4.2º voor TDC
% Resolutie van 0.2º CA
%% init
clear all; clc; close all;
addpath("Functions","Nasa");

%% Units
mm      = 1e-3; dm = 0.1;
bara    = 1e5;
MJ      = 1e6;
kWhr    = 1000*3600;
volperc = 0.01;
ppm     = 1e-6;
g       = 1e-3;
s       = 1;

%% Load NASA 
global Runiv
Runiv = 8.314;
[SpS,El] = myload('Nasa/NasaThermalDatabase.mat',{'Diesel','O2','N2','CO2','H2O'});

%% Engine geometry
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;

% Valve events
CaIVO = -355;
CaIVC = -135;
CaEVO = 149;
CaEVC = -344;
CaSOI = -3.2;

%% Load data using Data_Extraction_pf
Filename_fdaq = fullfile("Data","Example","20251120_0000001_example_fdaq.txt");
Filename_sdaq = fullfile("Data","Example","20251120_0000001_example_sdaq.txt");

data = Data_Extraction(Filename_fdaq, Filename_sdaq);

% Extract all the pressure-related data
Ca      = data.Ca;          % crank angle [deg]
p_raw   = data.p;           % unpegged pressure [Pa]
p_peg   = data.p_pegged;    % pegged pressure [Pa]
p_avg   = data.p_avg;       % averaged pegged pressure [Pa]
p_filt  = data.p_filt;      % filtered avg pressure [Pa]

% Use the pegged pressure for cycle analysis
p = p_peg;

[~, Ncycles_total] = size(Ca);

%% Skip first cycle
Ca = Ca(:,2:end);
p  = p(:,2:end);
Ncycles = Ncycles_total - 1;

fprintf('Skipping first cycle. Using cycles 2 to %d for analysis.\n', Ncycles+1);

%% Plotting all cycles
figure(1);
plot(Ca, p/bara, 'LineWidth', 1);
xlabel('Ca'); ylabel('p [bar]');
xlim([-360 360]); ylim([0 70]);
iselect = min(10, Ncycles);
YLIM = ylim;

line([CaIVC CaIVC], YLIM, 'LineWidth',1,'Color','b');
line([CaEVO CaEVO], YLIM, 'LineWidth',1,'Color','r');
set(gca,'XTick',-360:60:360,'XGrid','on','YGrid','on');
title("All cycles (excluding first)");

%% Work for selected cycle
[V] = CylinderVolume(Ca(:,iselect), Cyl);
W_net = trapz(V, p_peg(:,iselect));

fprintf('\n=== Work Calculation for Cycle %d ===\n', iselect+1);
fprintf('Net work: %.2f J\n', W_net);
fprintf('Net work: %.3f kJ\n', W_net/1000);

%% Visualize work area
figure(4);
fill(V/dm^3, p_peg(:,iselect)/bara, [0 0.7 0.85], ...
     'FaceAlpha',0.3,'EdgeColor',[0 0.7 0.85],'LineWidth',2);
xlabel('V [dm^3]'); ylabel('p [bar]');
xlim([0 0.8]); ylim([0.5 70]);
set(gca,'XTick',0:0.1:0.8,'XGrid','on','YGrid','on');
title(sprintf('Work Area - Net Work = %.2f J', W_net));
legend('Enclosed area = Work','Location','northeast');

%% Work calculation for ALL cycles
RPM = 1500;
workResults = CalculateWorkAndPower(Ca, p, Cyl);

fprintf('\n=== Work Calculation for ALL %d Cycles ===\n', Ncycles);
fprintf('Avg net work: %.2f J\n', workResults.W_net_avg);
fprintf('Std: %.2f J\n', workResults.W_net_std);
fprintf('Cov: %.1f%%\n', workResults.W_net_cov);
fprintf('Min work: %.2f J (cycle %d)\n', workResults.W_net_min, workResults.cycle_min+1);
fprintf('Max work: %.2f J (cycle %d)\n', workResults.W_net_max, workResults.cycle_max+1);


fprintf('Power: %.2f W\n', workResults.power);
fprintf('Power: %.3f kW\n', workResults.power/1000);
fprintf('Power: %.3f HP\n', workResults.power/745.7);

%% Plot Work vs Cycle
figure(5);
cycle_numbers = 2:(Ncycles+1);
plot(cycle_numbers, workResults.W_net_all/1000, 'bo-', ...
     'LineWidth',1.5,'MarkerSize',4,'MarkerFaceColor','b');
hold on;
yline(workResults.W_net_avg/1000,'r--','LineWidth',2,...
      'Label',sprintf('Avg = %.3f kJ', workResults.W_net_avg/1000));
yline((workResults.W_net_avg + workResults.W_net_std)/1000,'g--');
yline((workResults.W_net_avg - workResults.W_net_std)/1000,'g--');
hold off;
xlabel('Cycle Number'); ylabel('Net Work [kJ]');
title(sprintf('Work per Cycle (Avg = %.3f kJ, σ = %.3f kJ)', ...
      workResults.W_net_avg/1000, workResults.W_net_std/1000));
set(gca,'XGrid','on','YGrid','on');
xlim([2 Ncycles+1]);
legend('Cycle Work','Average','±1 Std','Location','best');

%% Histogram of Work
figure(6);
histogram(workResults.W_net_all/1000, 15, ...
          'FaceColor',[0.2 0.6 0.8],'FaceAlpha',0.7);
xlabel('Net Work [kJ]'); ylabel('Frequency');
title(sprintf('Work Distribution (%d cycles, no first cycle)', Ncycles));
hold on;
xline(workResults.W_net_avg/1000,'r--','LineWidth',2);
xline((workResults.W_net_avg + workResults.W_net_std)/1000,'g--');
xline((workResults.W_net_avg - workResults.W_net_std)/1000,'g--');
hold off;
set(gca,'XGrid','on','YGrid','on');
