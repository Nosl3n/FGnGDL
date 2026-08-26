raizProyecto = fileparts(mfilename('fullpath'));
addpath(fullfile(raizProyecto,'FUNCTIONS'));
addpath(fullfile(raizProyecto,'MODELOS'));
% SE PRUEVA CADA MODELO POR SEPARADO
% Defina las coordenadas como vectores fila o columna:
%x = [0, 1, -1.5, -3, 1.8];  % <-- editar
%y = [0, 1.2, 1.8, 2, 2.0]; % <-- editar

%..................................................................
li = 10;        % límites [0 li]
limvec = 20;   % máximo número de personas
mo = 3;         % 1-Paco_Model, 2-De_Sousa_Model, 3-Individual_Group_Model

% Generar datos inic.
n = randi([2, limvec]);
x = li * rand(1, n);
y = li * rand(1, n);
%.................................................................

r_small = 0.5;             % radio de cada punto (m)
r_large = r_small + 0.45;  % radio del círculo rojo mayor (m)

MCo = Group_Detector_Distan(x, y); %detector de grupos por distancia
disp(MCo);


%% ----------------------- GRAFICO

theta = linspace(0,2*pi,360);

figure; hold on; axis equal; grid on;
xlabel('X (m)'); ylabel('Y (m)');
title('Generacion de zonas proxemicas cuando las personas estan en movimiento');

% Parámetros de movimiento (personas)
n_frames = 300;   % cantidad de cuadros de animación
min_speed = 0.02; % velocidad mínima (m/cuadro)
max_speed = 0.10; % velocidad máxima (m/cuadro)
noise_gain = 0.01; % variación suave de dirección/velocidad (m/cuadro)

% Estado dinámico inicial: velocidades con dirección aleatoria
ang0 = 2*pi*rand(1, n);
spd0 = min_speed + (max_speed - min_speed) * rand(1, n);
vx = spd0 .* cos(ang0);
vy = spd0 .* sin(ang0);

% Dibujar cada punto, su círculo pequeño y el círculo rojo mayor centrado en el mismo punto
hFill = gobjects(1, length(x));
hMarker = gobjects(1, length(x));
for k = 1:length(x)
    xk = x(k);
    yk = y(k);
    % círculo relleno semitransparente (pequeño)
    xc = xk + r_small*cos(theta);
    yc = yk + r_small*sin(theta);
    hFill(k) = fill(xc, yc, [0 0.4470 0.7410], 'FaceAlpha',0.2, 'EdgeColor',[0 0.4470 0.7410]);
    % marcador en el centro
    hMarker(k) = plot(xk, yk, 'o', 'MarkerFaceColor',[0 0.4470 0.7410], 'MarkerEdgeColor','k', 'MarkerSize',6);
    % círculo rojo mayor centrado en el mismo punto (sin relleno)
    xR = xk + r_large*cos(theta);
    yR = yk + r_large*sin(theta);
    %plot(xR, yR, 'r-', 'LineWidth',0.5);
end

% grafica gaussianas
hContours = gobjects(0);
for i=1:size(MCo,1)
    row = MCo(i,:);            % primera fila
    vals = row(~isnan(row));   % quitar NaN
    xin = vals(1:2:end);       % x = posiciones 1,3,5,...
    yin = vals(2:2:end);       % y = posiciones 2,4,6,...

    [xrot, yrot, zrot] = Modelo(xin, yin, mo);
    [~, h1] = contour(xrot, yrot, zrot, [0.4, 0.4], 'LineColor', [1 0 0]); %55
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

% Animación del movimiento de personas (círculos en x,y)
for t = 1:n_frames
    % Movimiento natural: mantener inercia y variar suavemente el rumbo
    vx = vx + noise_gain * randn(1, n);
    vy = vy + noise_gain * randn(1, n);

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

    % Rebote entre personas (colisión elástica aproximada)
    minDist = 2 * r_small;
    for i = 1:n-1
        for j = i+1:n
            dx = x(j) - x(i);
            dy = y(j) - y(i);
            dist = hypot(dx, dy);
            if dist < minDist
                if dist < 1e-9
                    ang = 2*pi*rand;
                    nx = cos(ang);
                    ny = sin(ang);
                    dist = 1e-9;
                else
                    nx = dx / dist;
                    ny = dy / dist;
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

    % Reajuste final tras colisiones para no salir de límites
    x = min(max(x, r_small), li - r_small);
    y = min(max(y, r_small), li - r_small);

    for k = 1:n
        xk = x(k);
        yk = y(k);
        xc = xk + r_small*cos(theta);
        yc = yk + r_small*sin(theta);

        set(hFill(k), 'XData', xc, 'YData', yc);
        set(hMarker(k), 'XData', xk, 'YData', yk);
    end

    % Actualizar detector de grupos + gaussianas y curvas de nivel
    if ~isempty(hContours)
        delete(hContours(ishghandle(hContours)));
    end
    hContours = gobjects(0);
    MCo = Group_Detector_Distan(x, y);
    for i = 1:size(MCo, 1)
        row = MCo(i,:);
        vals = row(~isnan(row));
        xin = vals(1:2:end);
        yin = vals(2:2:end);
        if numel(xin) >= 2
            [xrot, yrot, zrot] = Modelo(xin, yin, mo);
            [~, h1] = contour(xrot, yrot, zrot, [0.4, 0.4], 'LineColor', [1 0 0]);
            %[~, h2] = contour(xrot, yrot, zrot, [0.4, 0.4], 'LineColor', [1 0.5 0]);
            hContours(end+1) = h1; %#ok<SAGROW>
            %hContours(end+1) = h2; %#ok<SAGROW>
        end
    end

    drawnow limitrate;
end

hold off;

% [xrot, yrot, zrot] = Paco_Model(xin, yin);

%contour(xrot, yrot, zrot, [0.96, 0.96], 'LineColor', [1 0 0]);
%hold on;
%contour(xrot, yrot, zrot, [0.9, 0.9], 'LineColor', [1 0.5 0]);
%hold on;
