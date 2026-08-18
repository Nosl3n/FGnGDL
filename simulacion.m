% simulacion.m
% Simula N personas moviéndose; cada persona es un círculo (radio=0.5) y una flecha que indica orientación (grados).
rng('shuffle');

% Parámetros de simulación
N = 10;              % número de personas

% Inicialización aleatoria de cada ejecución
% Las posiciones y direcciones de inicio se generan aleatoriamente cada vez que se corre el script.
dt = 0.05;          % paso temporal (s)
T = 60;             % duración total (s)
radius = 0.5;       % radio de la persona (m)
arrowLen = 0.5;     % longitud de la flecha indicadora
xlim_vals = [-4 4];
ylim_vals = [-4 4];

% Parámetros de detección y encierro
maxRange = 500;             % largo de la proyección de la dirección (m)
encircleDistance = 2.5;   % distancia máxima entre personas para considerar encierro (m)
sameDirectionTol = 10;    % diferencia angular para considerar misma dirección (grados)
parallelTol = 18;         % tolerancia para trayectorias casi paralelas (grados)
sectionH = 0.5;           % umbral de altura para la sección gaussiana (valor de z)
Contorno = 1;             % 1: dibujar contorno del grupo, 0: dibujar puntos 3D
encl_margin = 0.2;       % margen extra alrededor del grupo

% Inicializar estados: [x, y, orient_deg, speed, trajType, param1, param2]
% trajType: 1=lineal, 2=circular, 3=sinusoidal
states = zeros(N,7);
for i=1:N
    x0 = (xlim_vals(2)-xlim_vals(1))*rand + xlim_vals(1);
    y0 = (ylim_vals(2)-ylim_vals(1))*rand + ylim_vals(1);
    orient = 360*rand;               % grados
    speed = 0.3 + 1.0*rand;          % m/s
    traj = randi(3);
    switch traj
        case 1 % lineal: param1 = vx, param2 = vy
            vx = speed * cosd(orient);
            vy = speed * sind(orient);
            p1 = vx; p2 = vy;
        case 2 % circular: param1 = center_x, param2 = center_y (radio se elige segun distancia)
            cx = x0 + (1 + 2*rand) * (cosd(orient+90));
            cy = y0 + (1 + 2*rand) * (sind(orient+90));
            p1 = cx; p2 = cy;
        case 3 % sinusoidal: param1 = amplitude, param2 = frequency
            p1 = 0.5 + 1.0*rand;
            p2 = 0.2 + 0.8*rand;
    end
    states(i,:) = [x0, y0, orient, speed, traj, p1, p2];
end

% Preparar figura
figure('Color','w');
axis equal;
axis([xlim_vals ylim_vals]);
hold on;
grid off;
title('Simulación de personas');

% Crear objetos gráficos iniciales
hCircs = gobjects(N,1);
hArrows = gobjects(N,1);
theta = linspace(0,2*pi,36);
for i=1:N
    x = states(i,1); y = states(i,2);
    xc = x + radius*cos(theta);
    yc = y + radius*sin(theta);
    hCircs(i) = fill(xc, yc, [0.6 0.8 1], 'EdgeColor','b', 'FaceAlpha',0.8);
    % Flecha con quiver (usar handle quiver)
    or = states(i,3);
    ux = arrowLen * cosd(or);
    uy = arrowLen * sind(or);
    hArrows(i) = quiver(x, y, ux, uy, 0, 'MaxHeadSize',0.8, 'Color', [0 0 0], 'LineWidth',1.2);
end
drawnow;

% Bucle de simulación
nSteps = ceil(T/dt);
t = 0;
for k = 1:nSteps
    t = t + dt;
    for i=1:N
        x = states(i,1); y = states(i,2);
        or = states(i,3);
        spd = states(i,4);
        traj = states(i,5);
        p1 = states(i,6); p2 = states(i,7);
        switch traj
            case 1 % lineal: mover según vx,vy
                vx = p1; vy = p2;
                x = x + vx*dt;
                y = y + vy*dt;
                % orientar según velocidad si es significativa
                if hypot(vx,vy) > 1e-3
                    or = atan2d(vy,vx);
                end
            case 2 % circular: girar alrededor del centro (p1,p2)
                cx = p1; cy = p2;
                R = hypot(x-cx, y-cy);
                if R < 0.5, R = 0.5; end
                omega = spd / R; % rad/s
                ang = atan2(y-cy, x-cx) + omega*dt;
                x = cx + R*cos(ang);
                y = cy + R*sin(ang);
                or = rad2deg(ang) + 90; % orientación tangencial
            case 3 % sinusoidal: avance en x según orientación base, y = base + A*sin(w*t)
                A = p1; w = p2;
                vx = spd * cosd(or);
                vy = spd * sind(or) + A * w * cos(w*t); % componente oscilatoria
                x = x + vx*dt;
                y = y + vy*dt;
                or = atan2d(vy,vx);
        end
        % Limitar dentro de la ventana (rebote simple)
        if x < xlim_vals(1) || x > xlim_vals(2)
            or = mod(or + 180, 360); % girar 180°
            x = min(max(x, xlim_vals(1)), xlim_vals(2));
        end
        if y < ylim_vals(1) || y > ylim_vals(2)
            or = mod(or + 180, 360);
            y = min(max(y, ylim_vals(1)), ylim_vals(2));
        end
        states(i,1) = x;
        states(i,2) = y;
        states(i,3) = or;
    end

    % --- detectar intersecciones entre proyecciones de direcciones ---
    P = states(:,1:2);                    % Nx2 posiciones (origen de los rayos)
    angs = states(:,3);                   % grados
    Apts = P;
    Bpts = P + maxRange*[cosd(angs), sind(angs)]; % extremos de los rayos
    Nloc = size(P,1);
    adj = false(Nloc); % matriz de adyacencia por intersección

    for i=1:Nloc-1
        for j=i+1:Nloc
            dist_ij = hypot(P(i,1)-P(j,1), P(i,2)-P(j,2));
            if dist_ij > encircleDistance
                continue;
            end

            % Diferencia angular entre orientaciones
            dirDiff = min(abs(angs(i)-angs(j)), 360-abs(angs(i)-angs(j)));
            sameDirection = dirDiff <= sameDirectionTol;
            nearParallel = abs(180 - dirDiff) <= parallelTol || dirDiff <= parallelTol;

            % Intersección de trayectorias: OR con casi paralelas
            P1 = Apts(i,:); P2 = Bpts(i,:);
            Q1 = Apts(j,:); Q2 = Bpts(j,:);
            r = P2 - P1;
            s = Q2 - Q1;
            denom = r(1)*s(2) - r(2)*s(1);

            if abs(denom) < 1e-8
                trajectoriesCross = false;
            else
                tparam = ((Q1(1)-P1(1))*s(2) - (Q1(2)-P1(2))*s(1)) / denom;
                uparam = ((Q1(1)-P1(1))*r(2) - (Q1(2)-P1(2))*r(1)) / denom;
                trajectoriesCross = (tparam>=0 && tparam<=1 && uparam>=0 && uparam<=1);
            end

            % Condición final: distancia Y (intersección O casi paralela)
            if trajectoriesCross || sameDirection || nearParallel
                adj(i,j) = true;
                adj(j,i) = true;
            end
        end
    end

    % Si hay intersecciones, obtener componentes conectados y graficar los puntos
    delete(findobj(gca,'Tag','enclosure')); % borrar encierres previos
    if any(adj(:))
        G = graph(adj);
        comps = conncomp(G); % vector componente por nodo
        ncomp = max(comps);
        for c = 1:ncomp
            idx = find(comps==c);
            if numel(idx) < 2
                continue; % opcional: solo encerrar grupos de >=2
            end
            x_group = P(idx,1);
            y_group = P(idx,2);
            [x_sec, y_sec, z_sec] = Section_Gaussian(x_group, y_group, sectionH);
            if ~isempty(x_sec)
                if Contorno == 1
                    % Solo dibujar el contorno exterior del conjunto filtrado,
                    % sin renderizar todos los puntos internos.
                    if numel(x_sec) >= 3
                        k = convhull(x_sec, y_sec);
                        fill(x_sec(k), y_sec(k), [0 0.5 1], 'FaceAlpha', 0.2, ...
                            'EdgeColor', [0 0.4 0.8], 'LineWidth', 1.2, 'Tag', 'enclosure');
                    elseif numel(x_sec) == 2
                        plot([x_sec(1), x_sec(2)], [y_sec(1), y_sec(2)], ...
                            'Color', [0 0.4 0.8], 'LineWidth', 1.2, 'Tag', 'enclosure');
                    else
                        plot(x_sec, y_sec, 'o', 'Color', [0 0.4 0.8], 'MarkerSize', 5, 'Tag', 'enclosure');
                    end
                else
                    scatter3(x_sec, y_sec, z_sec, 6, 'b', 'filled', 'Tag', 'enclosure');
                end
            end
        end
    end

    % Rebotar personas cuando se solapan entre ellas para evitar atravesamientos
    for i = 1:N-1
        for j = i+1:N
            dx = states(j,1) - states(i,1);
            dy = states(j,2) - states(i,2);
            d = hypot(dx, dy);
            if d < 2*radius && d > 0
                nx = dx / d;
                ny = dy / d;
                overlap = 2*radius - d;
                states(i,1) = states(i,1) - nx * overlap / 2;
                states(i,2) = states(i,2) - ny * overlap / 2;
                states(j,1) = states(j,1) + nx * overlap / 2;
                states(j,2) = states(j,2) + ny * overlap / 2;
                states(i,3) = mod(states(i,3) + 180, 360);
                states(j,3) = mod(states(j,3) + 180, 360);
            end
        end
    end

    % Actualizar gráficos
    delete(hCircs); delete(hArrows);
    for i=1:N
        x = states(i,1); y = states(i,2);
        xc = x + radius*cos(theta);
        yc = y + radius*sin(theta);
        hCircs(i) = fill(xc, yc, [0.6 0.8 1], 'EdgeColor','b', 'FaceAlpha',0.8);
        or = states(i,3);
        ux = arrowLen * cosd(or);
        uy = arrowLen * sind(or);
        hArrows(i) = quiver(x, y, ux, uy, 0, 'MaxHeadSize',0.8, 'Color', [0 0 0], 'LineWidth',1.2);
    end
    drawnow;
end
