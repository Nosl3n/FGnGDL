function [xrot, yrot, zrot] = Aracelly_model_theta(x, y, theta)
%ARACELLY_MODEL Densidad grupal como mezcla de gaussianas asimétricas.
%   Implementa el modelo de Vega et al. (2017): cada persona se representa
%   con una gaussiana 2D orientada (varianza frontal sigma_h, lateral
%   sigma_s) y la densidad grupal G_d(x,y) es la suma de las gaussianas
%   individuales. En esta versión, la orientación de cada persona se
%   recibe explícitamente mediante theta (en grados).

    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(theta)
        error('x, y y theta deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';
    theta = theta(:).';

    if isempty(x)
        xrot = [];
        yrot = [];
        zrot = [];
        return;
    end
    if numel(theta) ~= numel(x)
        error('theta debe tener el mismo número de elementos que x e y.');
    end

    % Varianzas proxémicas típicas (Vega et al., 2017)
    sigma_h = 1.2;   % frontal
    sigma_s = 0.6;   % lateral

    % Orientación de cada persona dada por theta (grados -> radianes)
    theta_rad = theta * pi / 180;

    % Coeficientes k1, k2, k3 por persona (gaussiana asimétrica orientada)
    k1 = cos(theta_rad).^2 ./ (2*sigma_s^2) + sin(theta_rad).^2 ./ (2*sigma_h^2);
    k2 = sin(2*theta_rad)  ./ (4*sigma_s^2) - sin(2*theta_rad)  ./ (4*sigma_h^2);
    k3 = sin(theta_rad).^2 ./ (2*sigma_s^2) + cos(theta_rad).^2 ./ (2*sigma_h^2);

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
