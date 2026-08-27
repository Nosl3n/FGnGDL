function [xrot, yrot, zrot] = Individual_model(x, y, theta)
%INDIVIDUAL_MODEL Superficie gaussiana asimétrica para una sola persona.
%   La entrada es la posición (x, y) y la orientación theta en grados.
%   La salida conserva el formato [xrot, yrot, zrot] de la malla y
%   densidad gaussiana orientada.

    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(theta)
        error('x, y y theta deben ser numéricos.');
    end
    if ~isscalar(x) || ~isscalar(y) || ~isscalar(theta)
        error('x, y y theta deben ser escalares.');
    end

    % Varianzas proxémicas típicas (Vega et al., 2017)
    sigma_h = 0.9;   % frontal
    sigma_s = 0.6;   % lateral

    % Malla de evaluación
    lado = 5;
    paso = 0.1;
    xneg = x - lado;
    xpos = x + lado;
    yneg = y - lado;
    ypos = y + lado;
    [xx, yy] = meshgrid(xneg:paso:xpos, yneg:paso:ypos);

    % Densidad gaussiana base (siempre con orientación 0)
    dx = xx - x;
    dy = yy - y;
    zz = exp(-(dx.^2 ./ (2*sigma_s^2) + dy.^2 ./ (2*sigma_h^2)));

    % Rotar la malla base según theta (grados)
    [xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, -theta, x, y);
end
