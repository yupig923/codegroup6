function [BSem] = KPICalculation(emissions,AFR_sto,FUEL_m_flow,Energy_per_cycle)
% This Function calculates the Brake Specific Emissions
% - Input:
%   - emissions: Struct will the needed data
%   - AFR_sto: The stoichiometric AIR to Fuel Ratio
%   - FUEL_m_flow: Mass Flow of the fuel
%   - Energy_per_cycle: Energy created per cycle.
%
% - Output:
%   - BSem: a struct with all the Brake Specific Emissions

% Molar Masses
CO_molarmass = 28.01;
CO2_molarmass = 44.01;
HC_molarmass = 13.018;
O2_molarmass = 32;
NOx_molarmass = 46; % this is an approximation
AIR_molarmass = 29; % this is an approximation

gperJ_to_gperkWh = 3600*1000;

% Find the Volume 
Actual_AFR = emissions.lambda*AFR_sto;
AIR_mass_flow = Actual_AFR*FUEL_m_flow;

% Convert to Mass Flow
 CO_m_flow = ( CO_molarmass * emissions.CO  * AIR_mass_flow)/AIR_molarmass;
CO2_m_flow = (CO2_molarmass * emissions.CO2 * AIR_mass_flow)/AIR_molarmass;
 HC_m_flow = ( HC_molarmass * emissions.HC  * AIR_mass_flow)/AIR_molarmass;
 O2_m_flow = ( O2_molarmass * emissions.O2  * AIR_mass_flow)/AIR_molarmass;
NOx_m_flow = (NOx_molarmass * emissions.NOx * AIR_mass_flow)/AIR_molarmass;

BSem = struct();
BSem.BSFC  =FUEL_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
BSem.BSCO  =  CO_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
BSem.BSCO2 = CO2_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
BSem.BSHC  =  HC_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
BSem.BSO2  =  O2_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
BSem.BSNOx = NOx_m_flow*gperJ_to_gperkWh/Energy_per_cycle;
end