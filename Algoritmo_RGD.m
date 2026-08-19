
% Algoritmo_RGD.m
% Defina las coordenadas como vectores fila o columna:
%x = [0, 1, -1.5, -3, 1.8];  % <-- editar
%y = [0, 1.2, 1.8, 2, 2.0]; % <-- editar

%..................................................................
li = 10;        % límites [0 li]
limvec = 20;   % máximo número de personas

% Generar datos inic.
n = randi([2, limvec]);
x = li * rand(1, n);
y = li * rand(1, n);
%.................................................................

r_small = 0.5;             % radio de cada punto (m)
r_large = r_small + 0.45;  % radio del círculo rojo mayor (m)

MCo = Grupo_detector(x, y); %detector de grupos por distancia
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

    %[xrot, yrot, zrot] = Section_Gaussian(xin, yin); %Modelo del trabajo
    [xrot, yrot, zrot] = raphael_model(xin, yin); %Modelo de De Sousa
    contour(xrot, yrot, zrot, [0.55, 0.55], 'LineColor', [1 0 0]);
    hold on;
    contour(xrot, yrot, zrot, [0.4, 0.4], 'LineColor', [1 0.5 0]);
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

% [xrot, yrot, zrot] = Section_Gaussian(xin, yin);

%contour(xrot, yrot, zrot, [0.96, 0.96], 'LineColor', [1 0 0]);
%hold on;
%contour(xrot, yrot, zrot, [0.9, 0.9], 'LineColor', [1 0.5 0]);
%hold on;