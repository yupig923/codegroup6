function x = modified_cosine(Ca,Cyl)
% This function has the modified cosine for the volume calculation
%
% Input:
%       Ca  : Crankangle [degrees]
%       Cyl : a struct containing
%           Cyl.Stroke              : Stroke
%           Cyl.B                   : Bore
%           Cyl.ConRod              : Connecting Rod length
%           Cyl.CompressionRatio    : Compession Ratio
%           Cyl.TDCangle            : Angle associated with the Top Dead Center
% Ouput: 
%       x   : Cosine looking equation when seeing the angle as the variable
%             the max value is 1 and min value is 0

l = Cyl.ConRod;
r = Cyl.Stroke/2;

x = (cosd(Ca) - (sqrt(l^2 - (r*sind(Ca)).^2) - l)/r +1)/2;