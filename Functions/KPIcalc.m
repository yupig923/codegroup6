syms V_fuelin W m_NOx m_thc m_co2
rho = 836.1; % kg/m^3
Q_LHV = 43 * 10^6; %J/kg

m_fuel = V_fuelin * rho;
%W = closed integral p dV
eta = W/(m_fuel* Q_LHV)
BSFC_unit = 1/(eta * Q_LHV) % kg/J
BSFC = BSFC_unit * 3.6 * 10^9 %[g/kWhr]
M_CO2 = 44; %g/mol
M_fuel = 2673; %g/mol
M_ex=29; %g/mol exhaust like air
M_NOx=46; %g/mol use no2
x = 191;
BSCO2_unit = (x*M_fuel) / M_fuel * BSFC_unit; %kg/J
BSCO2 = BSCO2_unit * 3.6 * 10^9; %[g/kWhr]

EF_NOx=m_NOx/(m_fuel* Q_LHV);
BSNOx_unit = (m_NOx) / m_fuel * BSFC_unit; %kg/J
BSNOx= EF*Q_LHV*m_fuel;

EF_emissions=(m_thc+m_co2+m_NOx)/(m_fuel* Q_LHV);
BSEMx_unit = (m_thc+m_co2+m_NOx)/ m_fuel * BSFC_unit; %kg/J
BSEM= EF*Q_LHV*m_fuel;