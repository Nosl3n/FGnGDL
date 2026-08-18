clc; clearvars; close all;

% Parámetros
h = 0.5;
li = 10;        % límites [0 li]
limvec = 10;   % máximo número de personas

% Generar datos inic.
n = randi([2, limvec]);
x = li * rand(1, n);
y = li * rand(1, n);

% Velocidades iniciales
vmax0 = 0.3;
vx = vmax0*(2*rand(1,n)-1);
vy = vmax0*(2*rand(1,n)-1);

% Gráficos: figura única
figure('Color','w');
hold on;
axis([0 li 0 li]);
axis equal;
xlabel('x'); ylabel('y');

% Círculo plantilla
radius = 0.5;
theta = linspace(0,2*pi,80);

% Crear parches y centros (handles)
hPatch = gobjects(1,n);
hCenter = gobjects(1,n);
for k = 1:n
    hPatch(k) = patch(0,0,[0.6 0.8 1], 'EdgeColor','b', 'FaceAlpha', 0.6);
    hCenter(k) = plot(0,0,'kx','MarkerSize',8,'LineWidth',1.2);
end

% Handles para contornos
hContourObjs = gobjects(0);

% Función auxiliar para obtener malla válida para contour
    function [Xg,Yg,Zg] = prepareGrid(xp,yp,zp)
        % Si Z es matriz usable, devuélvela tal cual
        if ismatrix(zp) && all(size(zp) >= [2 2])
            Xg = xp; Yg = yp; Zg = zp;
            return;
        end
        % Si zp es vector, interpola a malla regular dentro del hull
        xp = xp(:); yp = yp(:); zp = zp(:);
        if numel(xp) < 3
            Xg = []; Yg = []; Zg = [];
            return;
        end
        % crear malla de consulta
        nx = 120; ny = 120;
        xmin = min(xp); xmax = max(xp);
        ymin = min(yp); ymax = max(yp);
        % si rango nulo, expandir un poco
        if xmax==xmin, xmax = xmin + 1e-3; end
        if ymax==ymin, ymax = ymin + 1e-3; end
        [Xg, Yg] = meshgrid(linspace(xmin, xmax, nx), linspace(ymin, ymax, ny));
        % interpolar (natural es buena opción)
        Zg = griddata(xp, yp, zp, Xg, Yg, 'natural');
    end

% Primer cálculo de la sección gaussiana (se asume Section_Gaussian acepta x,y)
[x_sec, y_sec, z_sec] = Section_Gaussian(x, y);

% Preparar y dibujar contornos iniciales
[Xg, Yg, Zg] = prepareGrid(x_sec, y_sec, z_sec);
if ~isempty(Xg)
    % borrar previos si existen
    delete(hContourObjs(ishandle(hContourObjs)));
    hold on;
    levels = [h+0.2, h, h-0.2, h-0.35];
    cmap = flipud(hot(numel(levels)));
    colormap(cmap);
    c = [];

    hC = gobjects(0);
    for L = levels
        hobj = contour(Xg, Yg, Zg, [L L], 'LineWidth', 1.2);
        [~, hobj] = contour(Xg, Yg, Zg, [L L], 'LineWidth', 1.2);
        hold on;
    end
    hContourObjs = hC;

end

% Inicializar parches con posiciones iniciales
for k = 1:n
    set(hPatch(k), 'XData', x(k) + radius*cos(theta), 'YData', y(k) + radius*sin(theta));
    set(hCenter(k), 'XData', x(k), 'YData', y(k));
end
drawnow;

% Bucle de animación
dt = 0.05;
T = 30;
nSteps = ceil(T/dt);
for step = 1:nSteps
    % actualizar posiciones
    x = x + vx*dt;
    y = y + vy*dt;
    % rebotes en límites
    for k = 1:n
        if x(k) < 0
            x(k) = 0; vx(k) = -vx(k);
        elseif x(k) > li
            x(k) = li; vx(k) = -vx(k);
        end
        if y(k) < 0
            y(k) = 0; vy(k) = -vy(k);
        elseif y(k) > li
            y(k) = li; vy(k) = -vy(k);
        end
    end
    % ligera variación aleatoria de velocidad
    vx = vx + 0.02*(rand(1,n)-0.5);
    vy = vy + 0.02*(rand(1,n)-0.5);
    % limitar velocidad máxima
    vmax = 0.6;
    sp = hypot(vx,vy);
    idx = sp > vmax;
    vx(idx) = vx(idx).* (vmax./sp(idx));
    vy(idx) = vy(idx).* (vmax./sp(idx));

    % actualizar parches y centros
    for k = 1:n
        set(hPatch(k), 'XData', x(k) + radius*cos(theta), 'YData', y(k) + radius*sin(theta));
        set(hCenter(k), 'XData', x(k), 'YData', y(k));
    end

    % recalcular sección y actualizar contornos
    [x_sec, y_sec, z_sec] = Section_Gaussian(x, y);
    [Xg, Yg, Zg] = prepareGrid(x_sec, y_sec, z_sec);
    % borrar contornos antiguos
    delete(hContourObjs(ishandle(hContourObjs)));
    hContourObjs = gobjects(0);
    if ~isempty(Xg)
        levels = [h+0.2, h, h-0.2];
        for L = levels
            contour(Xg, Yg, Zg, [L L], 'LineWidth', 1.2);
            hold on;
        end
        hContourObjs = findall(gca,'Type','contour');
    end

    drawnow limitrate;
end
