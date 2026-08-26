function [xrot, yrot, zrot] = Assimetric_Gaussian(x, y, mean_x, mean_y, rotation, variance_front, variance_right, variance_left, variance_rear)
lado = 2.5;
paso = 0.1;
xpos = abs(max(x)) + lado;
xneg = abs(min(x)) - lado;
ypos = abs(max(y)) + lado;
yneg = abs(min(y)) - lado;

[xrot, yrot] = meshgrid(xneg:paso:xpos, yneg:paso:ypos);

% alpha vectorizado y normalización a (-pi, pi]
alpha = atan2(yrot - mean_y, xrot - mean_x) - rotation + pi/2;
alpha = mod(alpha + pi, 2*pi) - pi;

% variance y variance_sides vectorizadas
isRear = (alpha <= 0);
variance = variance_rear .* isRear + variance_front .* (~isRear);

isSideLeft = (abs(alpha) >= pi/2);
variance_sides = variance_left .* isSideLeft + variance_right .* (~isSideLeft);

% Precalcular constantes trigonométricas
cr = cos(rotation);
sr = sin(rotation);
cr2 = cr.^2;
sr2 = sr.^2;
s2r = sin(2*rotation);

a = (cr2) ./ (2 .* variance) + (sr2) ./ (2 .* variance_sides);
b = s2r ./ (4 .* variance) - s2r ./ (4 .* variance_sides);
c = (sr2) ./ (2 .* variance) + (cr2) ./ (2 .* variance_sides);

dx = xrot - mean_x;
dy = yrot - mean_y;

zrot = exp(-(a .* dx.^2 + 2 .* b .* dx .* dy + c .* dy.^2));
end