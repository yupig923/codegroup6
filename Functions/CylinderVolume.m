function [V1,V2] = CylinderVolume(Ca,Cyl)
% This function provides the cylinder volume as function of 
% Ca : Crankangle [degrees]
% Cyl :  a struct containing
%   Cyl.Stroke              : Stroke
%   Cyl.B                   : Bore
%   Cyl.ConRod              : Connecting Rod length
%   Cyl.CompressionRatio    : Compession Ratio
%   Cyl.TDCangle            : Angle associated with the Top Dead Center
%----------------------------------------------------------------------
fprintf('WARNING------------------------------------------------------------------\n');
fprintf(' Function have been modified\n');
fprintf(' This function is %s\n',mfilename('fullpath'));
fprintf('END OF WARNING ----------------------------------------------------------\n');
B   = Cyl.Bore;
S   = Cyl.Stroke;
cr  = Cyl.CompressionRatio;
r   = S/2;
l   = Cyl.ConRod;
%-------------------------------------------------------------------------------------------------------
CAl     = Ca-Cyl.TDCangle;
Vd      = pi*(B/2)^2*S;
Vc      = Vd/(cr-1);
V1      = Vc + Vd*(sind(CAl+90)+1)/2; % 'sind' is the sine function taking arguments in degrees instead of radians
V2      = Vc + Vd*( modified_cosine(CAl,Cyl) );


