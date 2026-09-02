function [xrot, yrot, zrot] = Individual_Human_Model(x, y, theta, activar)
%INDIVIDUAL_MODEL Gaussiana proxémica de una persona y dibujo de su silueta.
%   [xrot, yrot, zrot] = Individual_Model(x, y, theta, activar)
%   Entradas:
%       x, y    - posición de la persona (m), escalares
%       theta   - orientación de la persona en grados
%       activar - 1 para dibujar la silueta y la gaussiana, 0 para no
%                 graficar la gaussiana (opcional, por defecto 1)
%   Salidas:
%       xrot, yrot, zrot - malla y densidad gaussiana orientada según theta;
%                         vacías si activar == 0
%   Efecto secundario: si activar == 1, dibuja sobre los ejes actuales la
%   silueta de la persona (cuerpo, cabeza y flecha de orientación) junto
%   con el contorno de su gaussiana proxémica.
    if nargin < 4
        activar = 1;
    end

    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(theta)
        error('x, y y theta deben ser numéricos.');
    end
    if ~isscalar(x) || ~isscalar(y) || ~isscalar(theta)
        error('x, y y theta deben ser escalares.');
    end

    %% ----------------------- MODELO GAUSSIANO
    % Con activar == 0 no se calcula ni se devuelve la zona proxémica.
    if activar == 0
        xrot = [];
        yrot = [];
        zrot = [];
    else
        % Varianzas proxémicas típicas (Vega et al., 2017)
        sigma_h = 0.9;   % frontal
        sigma_s = 0.6;   % lateral

        % Malla de evaluación
        lado = 5;
        paso = 0.1;
        [xx, yy] = meshgrid(x-lado:paso:x+lado, y-lado:paso:y+lado);

        % Densidad gaussiana base (orientación 0) rotada según theta (grados)
        dx = xx - x;
        dy = yy - y;
        zz = exp(-(dx.^2 ./ (2*sigma_s^2) + dy.^2 ./ (2*sigma_h^2)));
        [xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, -theta, x, y);
    end

    %% ----------------------- SILUETA DE LA PERSONA
    % Parámetros visuales de la silueta
    R_HB = 0.0763;   % radio del círculo centrado en el cuerpo (m)
    L_BB = 0.435;    % lado más largo del rectángulo (m)
    rect_width    = 0.12;     % ancho del rectángulo (m)
    half_len = L_BB / 2;
    half_wid = rect_width / 2;
    personColor = [0 0.4470 0.7410];
    angSamples = linspace(0, 2*pi, 360);

    phi = deg2rad(theta); % orientación en radianes (dirección a la que mira la persona)

    ax = gca;
    hold(ax, 'on');
    axis(ax, 'equal');
    grid(ax, 'on');
    xlabel(ax, 'X (m)'); ylabel(ax, 'Y (m)');

    % Cápsula (rectángulo con extremos semicirculares) centrada en (0,0)
    r = half_wid; % radio de los extremos semicirculares (igual a la mitad del ancho)
    core_half = half_len - r; % mitad de la parte rectangular central
    if core_half < 0
        % Si la longitud es menor que el ancho, degradar a una elipse completa
        t_ell = linspace(0, 2*pi, 64);
        localCaps = [ half_len*cos(t_ell); half_wid*sin(t_ell) ];
    else
        nseg = 24; % resolución de cada semicircunferencia
        t1 = linspace(-pi/2, pi/2, nseg); % semicirculo derecho (inferior->superior)
        rightSemi = [ core_half + r*cos(t1); r*sin(t1) ];
        t2 = linspace(pi/2, 3*pi/2, nseg); % semicirculo izquierdo (superior->inferior)
        leftSemi = [ -core_half + r*cos(t2); r*sin(t2) ];
        topEdge = [ linspace(core_half, -core_half, 2); ones(1,2)*r ];
        bottomEdge = [ linspace(-core_half, core_half, 2); ones(1,2)*(-r) ];
        localCaps = [ rightSemi, topEdge, leftSemi, bottomEdge ]; % 2 x M
    end

    % Contorno de la gaussiana proxémica (solo si activar == 1), detrás del cuerpo
    if activar == 1
        contour(ax, xrot, yrot, zrot, [0.75 0.75], 'LineColor', [1 0 1], 'LineWidth', 1.0);
    end

    % Cuerpo: rotar la cápsula para que el lado largo quede perpendicular a phi
    R = [cos(phi + pi/2), -sin(phi + pi/2); sin(phi + pi/2), cos(phi + pi/2)];
    worldCaps = (R * localCaps)'; % M x 2
    worldCaps = worldCaps + [x, y];
    fill(worldCaps(:,1), worldCaps(:,2), personColor, 'EdgeColor', 'k', 'LineWidth', 0.6);

    % Cabeza: círculo centrado en el centro del rectángulo
    circX = x + R_HB * cos(angSamples);
    circY = y + R_HB * sin(angSamples);
    fill(circX, circY, [1.0 0.80 0.62], 'EdgeColor', 'k', 'LineWidth', 0.6);

    % Flecha de orientación desde el centro (apunta hacia phi)
    quiver(x, y, half_len*0.9*cos(phi), half_len*0.9*sin(phi), 0, 'k', ...
        'LineWidth', 0.8, 'MaxHeadSize', 0.5);
end
