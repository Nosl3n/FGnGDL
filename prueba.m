raizProyecto = fileparts(mfilename('fullpath'));
addpath(fullfile(raizProyecto,'FUNCTIONS'));
addpath(fullfile(raizProyecto,'MODELOS'));
% ================= PARÁMETROS EDITABLES DEL EXPERIMENTO =================
% prueba.m: mismo esqueleto de simulación que Experimento_01.m (personas
% moviéndose, rebotando entre sí y contra los límites), pero adaptado
% SOLO para llamar y graficar Paco_Model_Paper_HO.m (no se usa el
% dispatcher Modelo.m, ni A*/robot, que no son necesarios para ver la
% diferencia entre los dos modos de corte).
%
% Para cada grupo se llama dos veces a Paco_Model_Paper_HO, cambiando
% únicamente "op", para que la diferencia sea directamente comparable:
%   op = 0 -> corte plano paralelo a XY (Z_corte_default), en AZUL.
%   op = 1 -> "h optimizado por sección": una superficie de corte con
%             forma, distinta para cada sección angular, en ROJO.
x = [2.5, 4.5, 3.5, 8, 7, 7, 8];  % <-- editar
y = [3.5, 2, 3.5, 6, 7, 5, 4];   % <-- editar
theta_ini = [30, 25, 45, 90, 150, 180, 200]; % orientación inicial (grados) <-- editar
speed_ini = [0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03]; % velocidad inicial (m/cuadro) <-- editar

li = 10;          % tamaño del área de movimiento: [0, li] m en X e Y
r_small = 0.5;    % radio físico de cada persona (m); el centro queda en [r_small, li-r_small]
min_speed = 0.01; % velocidad mínima permitida (m/cuadro)
max_speed = 0.05; % velocidad máxima permitida (m/cuadro)
home_pull = 0.01; % aceleración de retorno: a = -home_pull*(posicion - posicion_inicial)
                  % unidades: m/cuadro^2; 0 desactiva el retorno a la posición inicial
graf = 1;         % 0: ocultar/excluir zonas individuales; 1: dibujar/incluir zonas individuales
maxFrames = 300;  % cuadros de animación (aquí no hay robot que marque el final)

% Aceptar vectores fila o columna y trabajar internamente con vectores fila.
x = x(:).';
y = y(:).';
theta_ini = theta_ini(:).';
speed_ini = speed_ini(:).';
n = numel(x);
if numel(y) ~= n || numel(theta_ini) ~= n || numel(speed_ini) ~= n
    error('x, y, theta_ini y speed_ini deben tener la misma cantidad de elementos.');
end
if any(speed_ini < min_speed) || any(speed_ini > max_speed)
    error('Cada valor de speed_ini debe estar entre min_speed y max_speed.');
end
homeX = x;  % posición de referencia de cada persona: no cambia durante la
homeY = y;  % simulación; cada persona ronda alrededor de su propio "homeX,homeY"

MCo = Group_Detector_Distan(x, y); %detector de grupos por distancia
disp(MCo);

%% ----------------------- GRAFICO

fig = figure; hold on; axis equal; grid on;
xlabel('X (m)'); ylabel('Y (m)');
title('Paco Model Paper HO: h constante (azul) vs h optimizado por sección (rojo)');

% Leyenda fija (líneas ficticias, ya que contour() no se etiqueta bien
% dentro de un bucle con contornos que cambian de cuadro a cuadro).
legConst = plot(nan, nan, '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.3);
legSec   = plot(nan, nan, '-', 'Color', [1 0 0], 'LineWidth', 1.3);
legend([legConst, legSec], {'h constante (op=0)', 'h optimizado por sección (op=1)'}, ...
    'Location', 'bestoutside');

% Geometría de la "columna" del cuerpo para la colisión entre personas:
% deben coincidir con los parámetros de la cápsula usada en
% Individual_Human_Model.m (L_BB, rect_width) para que el rebote entre
% personas respete la forma real del cuerpo y no un círculo genérico.
L_BB = 0.435;
rect_width = 0.12;
cap_r = rect_width / 2;        % radio de los extremos semicirculares
core_half = L_BB/2 - cap_r;    % mitad de la columna recta de la cápsula

% Estado dinámico inicial completamente definido por el usuario.
% theta_ini está expresado en grados: 0° apunta a +X y 90° a +Y.
ang0 = deg2rad(theta_ini);
spd0 = speed_ini;
vx = spd0 .* cos(ang0);
vy = spd0 .* sin(ang0);

% Dibujar cada persona (silueta + gaussiana individual) con Individual_Human_Model.
theta_deg = theta_ini;
for k = 1:n
    Individual_Human_Model(x(k), y(k), theta_deg(k), graf);
end

% grafica gaussianas de grupo (corte constante vs. corte por sección)
for i = 1:size(MCo,1)
    row = MCo(i,:);            % primera fila
    vals = row(~isnan(row));   % quitar NaN
    xin = vals(1:2:end);       % x = posiciones 1,3,5,...
    yin = vals(2:2:end);       % y = posiciones 2,4,6,...
    if numel(xin) < 2
        continue;
    end
    thetaIn = zeros(size(xin)); % Paco_Model_Paper_HO no usa la orientación individual

    [xrotC, yrotC, ~, ~, DcorteC] = Paco_Model_Paper_HO(xin, yin, thetaIn, 0);
    contour(xrotC, yrotC, DcorteC, [0, 0], 'LineColor', [0 0.4470 0.7410], 'LineWidth', 1.3);

    [xrotS, yrotS, ~, ~, DcorteS] = Paco_Model_Paper_HO(xin, yin, thetaIn, 1);
    contour(xrotS, yrotS, DcorteS, [0, 0], 'LineColor', [1 0 0], 'LineWidth', 1.3);
end

% Ajustar límites para buena visualización
xlim([0, li]);
ylim([0, li]);

%% ----------------------- ANIMACIÓN
% Mismo movimiento determinista que Experimento_01.m (retorno suave a la
% posición inicial + rebote contra límites y entre personas), sin
% planificación de robot ni A*, ya que no aportan nada a la comparación
% de los dos modos de corte de Paco_Model_Paper_HO.
t = 0;
while ishandle(fig)
    t = t + 1;
    if t > maxFrames
        break;
    end

    vx = vx - home_pull * (x - homeX);
    vy = vy - home_pull * (y - homeY);

    speed = sqrt(vx.^2 + vy.^2);
    idxLow = speed < min_speed;
    if any(idxLow)
        scale = min_speed ./ max(speed(idxLow), eps);
        vx(idxLow) = vx(idxLow) .* scale;
        vy(idxLow) = vy(idxLow) .* scale;
    end
    idxHigh = speed > max_speed;
    if any(idxHigh)
        scale = max_speed ./ speed(idxHigh);
        vx(idxHigh) = vx(idxHigh) .* scale;
        vy(idxHigh) = vy(idxHigh) .* scale;
    end

    theta_deg = atan2d(vy, vx);

    x = x + vx;
    y = y + vy;

    % Rebote con límites [0, li] considerando el radio personal
    idx = x < r_small;
    x(idx) = r_small;
    vx(idx) = abs(vx(idx));
    idx = x > (li - r_small);
    x(idx) = li - r_small;
    vx(idx) = -abs(vx(idx));

    idx = y < r_small;
    y(idx) = r_small;
    vy(idx) = abs(vy(idx));
    idx = y > (li - r_small);
    y(idx) = li - r_small;
    vy(idx) = -abs(vy(idx));

    % Rebote entre personas (colisión elástica aproximada), usando la
    % cápsula real del cuerpo de cada una.
    minDist = 2 * cap_r;
    for i = 1:n-1
        for j = i+1:n
            dirI = deg2rad(theta_deg(i)) + pi/2;
            P1i = [x(i), y(i)] + core_half * [cos(dirI), sin(dirI)];
            P2i = [x(i), y(i)] - core_half * [cos(dirI), sin(dirI)];
            dirJ = deg2rad(theta_deg(j)) + pi/2;
            P1j = [x(j), y(j)] + core_half * [cos(dirJ), sin(dirJ)];
            P2j = [x(j), y(j)] - core_half * [cos(dirJ), sin(dirJ)];

            [dist, cI, cJ] = SegSegDist2D(P1i, P2i, P1j, P2j);
            if dist < minDist
                if dist < 1e-9
                    ang = deg2rad(mod(137*i + 53*j, 360));
                    nx = cos(ang);
                    ny = sin(ang);
                    dist = 1e-9;
                else
                    nx = (cJ(1) - cI(1)) / dist;
                    ny = (cJ(2) - cI(2)) / dist;
                end

                overlap = minDist - dist;
                x(i) = x(i) - 0.5 * overlap * nx;
                y(i) = y(i) - 0.5 * overlap * ny;
                x(j) = x(j) + 0.5 * overlap * nx;
                y(j) = y(j) + 0.5 * overlap * ny;

                relV = (vx(j) - vx(i)) * nx + (vy(j) - vy(i)) * ny;
                if relV < 0
                    vx(i) = vx(i) + relV * nx;
                    vy(i) = vy(i) + relV * ny;
                    vx(j) = vx(j) - relV * nx;
                    vy(j) = vy(j) - relV * ny;
                end
            end
        end
    end

    x = min(max(x, r_small), li - r_small);
    y = min(max(y, r_small), li - r_small);

    % Redibujar la escena completa: siluetas individuales y ambos cortes
    % (constante y optimizado por sección) de cada grupo.
    cla;
    theta_deg = atan2d(vy, vx);
    for k = 1:n
        Individual_Human_Model(x(k), y(k), theta_deg(k), graf);
    end

    MCo = Group_Detector_Distan(x, y);
    for i = 1:size(MCo, 1)
        row = MCo(i,:);
        vals = row(~isnan(row));
        xin = vals(1:2:end);
        yin = vals(2:2:end);
        if numel(xin) >= 2
            thetaIn = zeros(size(xin));

            [xrotC, yrotC, ~, ~, DcorteC] = Paco_Model_Paper_HO(xin, yin, thetaIn, 0);
            contour(xrotC, yrotC, DcorteC, [0, 0], 'LineColor', [0 0.4470 0.7410], 'LineWidth', 1.3);

            [xrotS, yrotS, ~, ~, DcorteS] = Paco_Model_Paper_HO(xin, yin, thetaIn, 1);
            contour(xrotS, yrotS, DcorteS, [0, 0], 'LineColor', [1 0 0], 'LineWidth', 1.3);
        end
    end

    % cla borró también las líneas ficticias de la leyenda: se recrean
    % cada cuadro (baratas, no llevan datos reales).
    legConst = plot(nan, nan, '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.3);
    legSec   = plot(nan, nan, '-', 'Color', [1 0 0], 'LineWidth', 1.3);
    legend([legConst, legSec], {'h constante (op=0)', 'h optimizado por sección (op=1)'}, ...
        'Location', 'bestoutside');

    xlim([0, li]);
    ylim([0, li]);
    drawnow limitrate;
end

disp('Simulación finalizada.');
hold off;
