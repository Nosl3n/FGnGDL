clc; clearvars; close all;
raizProyecto = fileparts(mfilename('fullpath'));
addpath(fullfile(raizProyecto,'FUNCTIONS'));
addpath(fullfile(raizProyecto,'MODELOS'));
% Parámetros
h = 0.5;
li = 8;        % límites de movimiento [0 li]
limvec = 10;   % máximo número de personas
radius = 0.5;  % radio de cada esfera

%Modelo

mo = 1; % Modelo a usar: 1-Paco_Model, 2-De_Sousa_Model, 3-Individual_Group_Model, 4-Aracelly_model

% Generar datos inic.
n = randi([2, limvec]);
x = radius + (li - 2*radius) * rand(1, n);
y = radius + (li - 2*radius) * rand(1, n);

% Velocidades iniciales
vmax0 = 0.3;
vx = vmax0*(2*rand(1,n)-1);
vy = vmax0*(2*rand(1,n)-1);

% Gráficos: figura única en 3D
figure('Color','w');
hold on;
axis([-2 li+5 -2 li+5 0 1.4]);
xlabel('x'); ylabel('y'); zlabel('densidad');
view(10, 45);           % vista más rasante: resalta el relieve de las gaussianas
daspect([1 1 0.22]);     % exagera visualmente el eje z frente a x,y (que son ~10x más grandes)
camproj('perspective');  % perspectiva con profundidad, en vez de proyección plana
grid on;
box on;
camlight('headlight');
lighting gouraud;
colormap(flipud(hot));
colorbar;

% Plantilla de esfera unitaria (para las personas)
[Xs, Ys, Zs] = sphere(16);

% Crear esferas y centros (handles)
hSphere = gobjects(1,n);
hCenter = gobjects(1,n);
for k = 1:n
    hSphere(k) = surf(Xs, Ys, Zs, 'FaceColor',[0.6 0.8 1], 'EdgeColor','none', 'FaceAlpha',0.9);
    hCenter(k) = plot3(0,0,0,'kx','MarkerSize',8,'LineWidth',1.2);
end

% Handle para la superficie gaussiana
hSurfObjs = gobjects(0);

% Primer cálculo de la sección gaussiana
[x_sec, y_sec, z_sec] = Modelo(x, y, mo);

% Preparar y dibujar la superficie inicial
[Xg, Yg, Zg] = prepareGrid(x_sec, y_sec, z_sec);
if ~isempty(Xg)
    delete(hSurfObjs(ishandle(hSurfObjs)));
    hSurf = surf(Xg, Yg, Zg, 'EdgeColor','none', 'FaceAlpha',0.85);
    hSurfObjs = hSurf;
end

% Inicializar esferas con posiciones iniciales
% Separar esferas que hayan nacido superpuestas.
for iter = 1:8
    for i = 1:n-1
        for j = i+1:n
            dx = x(j) - x(i);
            dy = y(j) - y(i);
            d = hypot(dx, dy);
            minDist = 2*radius;
            if d < minDist
                if d < eps
                    ang = 2*pi*rand;
                    dx = cos(ang); dy = sin(ang); d = 1;
                end
                nx = dx/d; ny = dy/d;
                correction = (minDist - d)/2;
                x(i) = x(i) - correction*nx; y(i) = y(i) - correction*ny;
                x(j) = x(j) + correction*nx; y(j) = y(j) + correction*ny;
            end
        end
    end
    x = min(max(x, radius), li - radius);
    y = min(max(y, radius), li - radius);
end

for k = 1:n
    set(hSphere(k), 'XData', radius*Xs + x(k), 'YData', radius*Ys + y(k), 'ZData', radius*Zs + radius);
    set(hCenter(k), 'XData', x(k), 'YData', y(k), 'ZData', 2*radius + 0.02);
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
        if x(k) < radius
            x(k) = radius; vx(k) = -vx(k);
        elseif x(k) > li - radius
            x(k) = li - radius; vx(k) = -vx(k);
        end
        if y(k) < radius
            y(k) = radius; vy(k) = -vy(k);
        elseif y(k) > li - radius
            y(k) = li - radius; vy(k) = -vy(k);
        end
    end

    % Colisiones elásticas entre esferas del mismo radio.
    % Se corrige la posición para eliminar cualquier superposición y se
    % intercambia la componente normal de las velocidades cuando se acercan.
    for iter = 1:4
        for i = 1:n-1
            for j = i+1:n
                dx = x(j) - x(i);
                dy = y(j) - y(i);
                d = hypot(dx, dy);
                minDist = 2*radius;
                if d < minDist
                    if d < eps
                        ang = 2*pi*rand;
                        dx = cos(ang); dy = sin(ang); d = 1;
                    end
                    nx = dx/d; ny = dy/d;

                    correction = (minDist - d)/2;
                    x(i) = x(i) - correction*nx; y(i) = y(i) - correction*ny;
                    x(j) = x(j) + correction*nx; y(j) = y(j) + correction*ny;

                    relativeSpeed = (vx(j) - vx(i))*nx + (vy(j) - vy(i))*ny;
                    if relativeSpeed < 0
                        vx(i) = vx(i) + relativeSpeed*nx;
                        vy(i) = vy(i) + relativeSpeed*ny;
                        vx(j) = vx(j) - relativeSpeed*nx;
                        vy(j) = vy(j) - relativeSpeed*ny;
                    end
                end
            end
        end
        x = min(max(x, radius), li - radius);
        y = min(max(y, radius), li - radius);
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

    % actualizar esferas y centros
    for k = 1:n
        set(hSphere(k), 'XData', radius*Xs + x(k), 'YData', radius*Ys + y(k), 'ZData', radius*Zs + radius);
        set(hCenter(k), 'XData', x(k), 'YData', y(k), 'ZData', 2*radius + 0.02);
    end

    % recalcular sección y actualizar la superficie gaussiana
    [x_sec, y_sec, z_sec] = Modelo(x, y, mo);

    [Xg, Yg, Zg] = prepareGrid(x_sec, y_sec, z_sec);
    % borrar superficie anterior (el tamaño de malla cambia cada cuadro)
    delete(hSurfObjs(ishandle(hSurfObjs)));
    hSurfObjs = gobjects(0);
    if ~isempty(Xg)
        hSurf = surf(Xg, Yg, Zg, 'EdgeColor','none', 'FaceAlpha',0.85);
        hSurfObjs = hSurf;
    end

    drawnow limitrate;
end

% Función auxiliar para obtener malla válida para surf
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
