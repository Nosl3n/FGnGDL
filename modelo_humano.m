raizProyecto = fileparts(mfilename('fullpath'));
addpath(fullfile(raizProyecto,'FUNCTIONS'));
addpath(fullfile(raizProyecto,'MODELOS'));
% SE PRUEVA CADA MODELO POR SEPARADO
% Defina las coordenadas como vectores fila o columna:
x = [5, 4];  % <-- editar
y = [4, 3]; % <-- editar
theta = [200 45];
n= length(x);

% Parámetros visuales de la silueta
circle_radius = 0.0763;   % radio del círculo centrado en el cuerpo (m)
rect_length = 0.435;      % lado más largo del rectángulo (m)
rect_width  = 0.12;       % ancho del rectángulo (m)
half_len = rect_length / 2;
half_wid = rect_width / 2;
% Radio del círculo amarillo adicional por persona (solicitado):
yellow_zone_radius = 0.45 + circle_radius/4; % 0.45 + 0.1525/4
% Radio del círculo rojo adicional por persona (solicitado):
red_zone_radius = 0.45 + half_len; % 0.45 + half_len (m)
%..................................................................
li = 10;        % límites [0 li]
limvec = 20;   % máximo número de personas
mo = 2;         % 1-Paco_Model, 2-De_Sousa_Model, 3-Individual_Group_Model

%.................................................................

r_small = 0.5;             % radio de cada punto (m)
r_large = r_small + 0.45;  % radio del círculo rojo mayor (m)

MCo = Group_Detector_Distan(x, y); %detector de grupos por distancia
disp(MCo);


%% ----------------------- GRAFICO

figure; hold on; axis equal; grid on;
xlabel('X (m)'); ylabel('Y (m)');
title('Generacion de zonas proxemicas cuando las personas estan en movimiento');

% Orientaciones de cada persona.
% Preferencia: si existe la variable 'theta' se interpreta como grados
% theta = [theta1, theta2, ...] (igual tamaño que x,y). Si no existe,
% se acepta 'orient' ya en radianes. Si ninguna existe, por defecto 0.
if exist('theta','var') && numel(theta) == n
    ang_orient = deg2rad(theta(:)'); % theta en grados -> radianes
elseif exist('orient', 'var') && numel(orient) == n
    ang_orient = orient(:)'; % usar variable externa ya en radianes
else
    % orientaciones por defecto (mirando hacia +x)
    ang_orient = zeros(1,n);
end

% Muestreo angular para dibujar círculos y semicírculos
angSamples = linspace(0,2*pi,360);

% Dibujar cada persona como una silueta (cabeza y torso) con orientación fija.
% Inicializar manejadores y zonas
hBody = gobjects(1, length(x));
hHead = gobjects(1, length(x));
hZone = gobjects(1, length(x));
hRedZone = gobjects(1, length(x));
personColor = [0 0.4470 0.7410];

for k = 1:length(x)
    xk = x(k);
    yk = y(k);
    phi = ang_orient(k); % orientación en radianes (dirección a la que mira la persona)
    % Rotar de modo que el lado largo del rectángulo (rect_length) quede
    % perpendicular a la orientación (representa la anchura de hombros)
    R = [cos(phi + pi/2), -sin(phi + pi/2); sin(phi + pi/2), cos(phi + pi/2)];

    % Crear una forma "capsule" (rectángulo con extremos semicirculares) centrada en 0,0
    r = half_wid; % radio de los extremos semicirculares (igual a la mitad del ancho)
    core_half = half_len - r; % mitad de la parte rectangular central
    if core_half < 0
        % Si la longitud es menor que el ancho, degradar a un elipse completa
        t_ell = linspace(0,2*pi,64);
        localCaps = [ (half_len)*cos(t_ell); (half_wid)*sin(t_ell) ];
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
    % Dibujar primero la zona roja (más grande) detrás de la amarilla
    redX = xk + red_zone_radius * cos(angSamples);
    redY = yk + red_zone_radius * sin(angSamples);
    hRedZone(k) = fill(redX, redY, [1 0 0], 'EdgeColor', 'none', 'FaceAlpha', 0.15);

    % Dibujar luego la zona amarilla (por debajo del cuerpo)
    zoneX = xk + yellow_zone_radius * cos(angSamples);
    zoneY = yk + yellow_zone_radius * sin(angSamples);
    hZone(k) = fill(zoneX, zoneY, [1 1 0], 'EdgeColor', 'none', 'FaceAlpha', 0.25);

    % Rotar la cápsula para que el lado largo quede perpendicular a phi
    worldCaps = (R * localCaps)'; % M x 2
    worldCaps = worldCaps + [xk, yk];
    hBody(k) = fill(worldCaps(:,1), worldCaps(:,2), personColor, 'EdgeColor', 'k', 'LineWidth', 0.6);

    % Círculo centrado en el centro del rectángulo (misma posición xk, yk)
    circX = xk + circle_radius * cos(angSamples);
    circY = yk + circle_radius * sin(angSamples);
    hHead(k) = fill(circX, circY, [1.0 0.80 0.62], 'EdgeColor', 'k', 'LineWidth', 0.6);

    % Línea o flecha de orientación desde el centro (apunta hacia phi)
    quiver(xk, yk, half_len*0.9*cos(phi), half_len*0.9*sin(phi), 0, 'k', 'LineWidth', 0.8, 'MaxHeadSize',0.5);
end

% grafica gaussianas
hContours = gobjects(0);
for i=1:size(MCo,1)
    row = MCo(i,:);            % primera fila
    vals = row(~isnan(row));   % quitar NaN
    xin = vals(1:2:end);       % x = posiciones 1,3,5,...
    yin = vals(2:2:end);       % y = posiciones 2,4,6,...

    [xrot, yrot, zrot] = Modelo(xin, yin, mo);
    [~, h1] = contour(xrot, yrot, zrot, [0.6, 0.6], 'LineColor', [1 0 0]); %55
   % [~, h2] = contour(xrot, yrot, zrot, [0.4, 0.4], 'LineColor', [1 0.5 0]);
    hContours(end+1) = h1; %#ok<SAGROW>
   % hContours(end+1) = h2; %#ok<SAGROW>
end

% Grafica del centro geometrico
%plot(XC, YC, 'kp', 'MarkerFaceColor','y', 'MarkerSize',12);
%text(XC, YC, '  CG', 'FontWeight','bold', 'Color','k');

% Ajustar límites para buena visualización
xlim([0, li]);
ylim([0, li]);

% El modelo es estático en este script: no hay animación.
% Si se desea actualizar las zonas proxémicas con nuevas posiciones,
% ejecutar de nuevo este script o llamar a las funciones correspondientes.

% Mantener la figura abierta hasta que el usuario la cierre
hold off;

% [xrot, yrot, zrot] = Paco_Model(xin, yin);

%contour(xrot, yrot, zrot, [0.96, 0.96], 'LineColor', [1 0 0]);
%hold on;
%contour(xrot, yrot, zrot, [0.9, 0.9], 'LineColor', [1 0.5 0]);
%hold on;
