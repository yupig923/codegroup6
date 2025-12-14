function [Cp,Cv,H,E] = ThermoMix(Y,T,Sp)
global Runiv

Tsize = size(T);
T = T(:).';                % flatten
nT = numel(T);
nSp = length(Sp);

Hi  = zeros(nSp, nT);
Cpi = zeros(nSp, nT);

Ma_inv = 0;
for i = 1:nSp
    Hi(i,:)  = HNasa(T, Sp(i));
    Cpi(i,:) = CpNasa(T, Sp(i));
    Ma_inv   = Ma_inv + Y(i)/Sp(i).Mass;
end

Ma = 1/Ma_inv;

H  = reshape(Y * Hi,  Tsize);
Cp = reshape(Y * Cpi, Tsize);

E  = H - Runiv/Ma .* reshape(T, Tsize);
Cv = Cp - Runiv/Ma;
end