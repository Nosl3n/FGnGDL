function [xrot, yrot, zrot] = Aracelly_model(x, y)
%ARACELLY_MODEL Densidad grupal como mezcla de gaussianas asimétricas.
%   Implementa el modelo de Vega et al. (2017): cada persona se representa
%   con una gaussiana 2D orientada (varianza frontal sigma_h, lateral
%   sigma_s) y la densidad grupal G_d(x,y) es la suma de las gaussianas
%   individuales. Como esta función solo recibe posiciones (sin
%   orientación por persona), se asume que cada persona mira hacia el
%   centro del grupo (formación conversacional tipo O-space de Kendon).

    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y)
        error('x e y deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';

    if isempty(x)
        xrot = [];
        yrot = [];
        zrot = [];
        return;
    end

    % Varianzas proxémicas típicas (Vega et al., 2017)
    sigma_h = 1.2;   % frontal
    sigma_s = 0.6;   % lateral

    % Orientación de cada persona: hacia el centro del grupo
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;
    theta = atan2(ycm - y, xcm - x);

    % Coeficientes k1, k2, k3 por persona (gaussiana asimétrica orientada)
    k1 = cos(theta).^2 ./ (2*sigma_s^2) + sin(theta).^2 ./ (2*sigma_h^2);
    k2 = sin(2*theta)  ./ (4*sigma_s^2) - sin(2*theta)  ./ (4*sigma_h^2);
    k3 = sin(theta).^2 ./ (2*sigma_s^2) + cos(theta).^2 ./ (2*sigma_h^2);

    % Malla de evaluación
    lado = 5;
    paso = 0.1;
    xneg = min(x) - lado;
    xpos = max(x) + lado;
    yneg = min(y) - lado;
    ypos = max(y) + lado;
    [xx, yy] = meshgrid(xneg:paso:xpos, yneg:paso:ypos);

    % Densidad global: suma de gaussianas individuales (mezcla gaussiana)
    zz = zeros(size(xx));
    for i = 1:numel(x)
        dx = xx - x(i);
        dy = yy - y(i);
        zz = zz + exp(-(k1(i).*dx.^2 + k2(i).*dx.*dy + k3(i).*dy.^2));
    end

    xrot = xx;
    yrot = yy;
    zrot = zz;
end
