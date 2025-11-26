function V = CylinderVolume(Ca,Cyl)
% This function provides the cylinder volume as function of 
% Ca : Crankangle [degrees]
% Cyl :  a struct containing
%   Cyl.Stroke              : Stroke
%   Cyl.B                   : Bore
%   Cyl.ConRod              : Connecting Rod length
%   Cyl.CompressionRatio    : Compession Ratio
%   Cyl.TDCangle            : Angle associated with the Top Dead Center
%----------------------------------------------------------------------

B   = Cyl.Bore;
S   = Cyl.Stroke;
cr  = Cyl.CompressionRatio;
r   = S/2;
l   = Cyl.ConRod;
%-------------------------------------------------------------------------------------------------------
CAl     = Ca-Cyl.TDCangle;
Vd      = pi*(B/2)^2*S;
Vc      = Vd/(cr-1);
% The next line calculates at which position the piston is as a value
% between 0 and 1, with 0 being top position and 1 bottom position.
x = (cosd(CAl) - (sqrt(l^2 - (r*sind(CAl)).^2) - l)/r +1)/2;
V      = Vc + Vd*x;


