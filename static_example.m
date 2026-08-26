raizProyecto = fileparts(mfilename('fullpath'));
addpath(fullfile(raizProyecto,'FUNCTIONS'));
addpath(fullfile(raizProyecto,'MODELOS'));
% SE PRUEBA CADA MODELO POR SEPARADO
% Defina las coordenadas como vectores fila o columna:
%x = [0, 1, -1.5, -3, 1.8];  % <-- editar
%y = [0, 1.2, 1.8, 2, 2.0]; % <-- editar

%..................................................................
li = 10;        % límites [0 li]
limvec = 20;   % máximo número de personas
mo = 1;         % 1-Paco_Model, 2-De_Sousa_Model, 3-Individual_Group_Model
r_small = 0.5;  % radio de cada punto (m)
nivel = 0.4;    % único nivel de contorno que se dibuja

% Generar posiciones iniciales sin superposición entre círculos.
n = randi([2, limvec]);
x = zeros(1, n);
y = zeros(1, n);
for k = 1:n
    colocado = false;
    for intento = 1:10000
        xk = r_small + (li - 2*r_small) * rand;
        yk = r_small + (li - 2*r_small) * rand;
        if k == 1 || all(hypot(x(1:k-1) - xk, y(1:k-1) - yk) >= 2*r_small)
            x(k) = xk;
            y(k) = yk;
            colocado = true;
            break;
        end
    end
    if ~colocado
        error('No fue posible generar %d círculos sin superposición.', n);
    end
end
%.................................................................

r_large = r_small + 0.45;  % radio del círculo rojo mayor (m)

MCo = Group_Detector_Distan(x, y); %detector de grupos por distancia
disp(MCo);


%% ----------------------- GRAFICO

theta = linspace(0,2*pi,360);

figure; hold on; axis equal; grid on;
xlabel('X (m)'); ylabel('Y (m)');
title('Puntos con círculos de radio 0.5 m y círculos rojos mayores (0.95 m)');

% Dibujar cada punto, su círculo pequeño y el círculo rojo mayor centrado en el mismo punto
for k = 1:length(x)
    xk = x(k);
    yk = y(k);
    % círculo relleno semitransparente (pequeño)
    xc = xk + r_small*cos(theta);
    yc = yk + r_small*sin(theta);
    fill(xc, yc, [0 0.4470 0.7410], 'FaceAlpha',0.2, 'EdgeColor',[0 0.4470 0.7410]);
    % marcador en el centro
    plot(xk, yk, 'o', 'MarkerFaceColor',[0 0.4470 0.7410], 'MarkerEdgeColor','k', 'MarkerSize',6);
    % círculo rojo mayor centrado en el mismo punto (sin relleno)
    xR = xk + r_large*cos(theta);
    yR = yk + r_large*sin(theta);
    %plot(xR, yR, 'r-', 'LineWidth',0.5);
end

% grafica gaussianas
for i=1:size(MCo,1)
    row = MCo(i,:);            % primera fila
    vals = row(~isnan(row));   % quitar NaN
    xin = vals(1:2:end);       % x = posiciones 1,3,5,...
    yin = vals(2:2:end);       % y = posiciones 2,4,6,...

    [xrot, yrot, zrot] = Modelo(xin, yin, mo);
    contour(xrot, yrot, zrot, [nivel, nivel], 'LineColor', [1 0 0]);
    hold on;
end

% Grafica del centro geometrico
%plot(XC, YC, 'kp', 'MarkerFaceColor','y', 'MarkerSize',12);
%text(XC, YC, '  CG', 'FontWeight','bold', 'Color','k');

% Ajustar límites para buena visualización
pad = r_large + 0.2;
xlim([min(x)-pad, max(x)+pad]);
ylim([min(y)-pad, max(y)+pad]);

hold off;
