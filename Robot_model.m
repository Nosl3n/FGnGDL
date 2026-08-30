function Robot_model(x, y, theta)
%ROBOT_MODEL Dibuja la silueta de un robot en la posición y orientación dadas.
%   Robot_model(x, y, theta)
%   Entradas:
%       x, y  - posición del robot (m), escalares
%       theta - orientación del robot en grados
%   Efecto secundario: dibuja sobre los ejes actuales la silueta del
%   robot (chasis, ruedas, torreta y flecha de orientación).
%   El robot no tiene zona proxémica (no genera ninguna gaussiana).

    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(theta)
        error('x, y y theta deben ser numéricos.');
    end
    if ~isscalar(x) || ~isscalar(y) || ~isscalar(theta)
        error('x, y y theta deben ser escalares.');
    end

    %% ----------------------- SILUETA DEL ROBOT
    % Parámetros visuales del chasis (vista superior)
    L_R = 0.50;    % largo del chasis, eje frontal (m)
    W_R = 0.40;    % ancho del chasis (m)
    half_len = L_R / 2;
    half_wid = W_R / 2;

    wheel_len = 0.16;  % largo de cada rueda (m)
    wheel_wid = 0.06;  % ancho de cada rueda (m)
    turret_radius = 0.09; % radio de la torreta/sensor central (m)

    bodyColor   = [0.75 0.76 0.80];
    wheelColor  = [0.15 0.15 0.15];
    turretColor = [0.25 0.65 0.90];
    frontColor  = [0.85 0.10 0.10];

    angSamples = linspace(0, 2*pi, 60);
    phi = deg2rad(theta); % orientación en radianes (dirección de avance del robot)
    R = [cos(phi), -sin(phi); sin(phi), cos(phi)];

    ax = gca;
    hold(ax, 'on');
    axis(ax, 'equal');
    grid(ax, 'on');
    xlabel(ax, 'X (m)'); ylabel(ax, 'Y (m)');

    toWorld = @(local) (R * local)' + [x, y]; % local: 2 x M -> world: M x 2

    % Chasis: rectángulo con esquinas ligeramente achaflanadas
    chamfer = 0.05;
    localBody = [ ...
         half_len,              half_wid-chamfer; ...
         half_len-chamfer,      half_wid; ...
        -half_len+chamfer,      half_wid; ...
        -half_len,              half_wid-chamfer; ...
        -half_len,             -half_wid+chamfer; ...
        -half_len+chamfer,     -half_wid; ...
         half_len-chamfer,     -half_wid; ...
         half_len,             -half_wid+chamfer]';
    worldBody = toWorld(localBody);
    fill(worldBody(:,1), worldBody(:,2), bodyColor, 'EdgeColor', 'k', 'LineWidth', 0.8);

    % Ruedas: dos rectángulos a cada lado, centrados a la mitad del largo
    localWheelRight = [ wheel_len/2, -half_wid-wheel_wid/2; ...
                         wheel_len/2, -half_wid+wheel_wid/2; ...
                        -wheel_len/2, -half_wid+wheel_wid/2; ...
                        -wheel_len/2, -half_wid-wheel_wid/2]';
    localWheelLeft = [ wheel_len/2,  half_wid-wheel_wid/2; ...
                        wheel_len/2,  half_wid+wheel_wid/2; ...
                       -wheel_len/2,  half_wid+wheel_wid/2; ...
                       -wheel_len/2,  half_wid-wheel_wid/2]';
    worldWheelRight = toWorld(localWheelRight);
    worldWheelLeft  = toWorld(localWheelLeft);
    fill(worldWheelRight(:,1), worldWheelRight(:,2), wheelColor, 'EdgeColor', 'k', 'LineWidth', 0.5);
    fill(worldWheelLeft(:,1),  worldWheelLeft(:,2),  wheelColor, 'EdgeColor', 'k', 'LineWidth', 0.5);

    % Indicador de frente: triángulo saliendo del borde delantero
    localFront = [ half_len,          0.10; ...
                   half_len+0.12,     0; ...
                   half_len,         -0.10]';
    worldFront = toWorld(localFront);
    fill(worldFront(:,1), worldFront(:,2), frontColor, 'EdgeColor', 'k', 'LineWidth', 0.5);

    % Torreta/sensor central
    localTurret = [turret_radius*cos(angSamples); turret_radius*sin(angSamples)];
    worldTurret = toWorld(localTurret);
    fill(worldTurret(:,1), worldTurret(:,2), turretColor, 'EdgeColor', 'k', 'LineWidth', 0.6);

    % Flecha de orientación desde el centro (apunta hacia phi)
    quiver(x, y, half_len*1.3*cos(phi), half_len*1.3*sin(phi), 0, 'k', ...
        'LineWidth', 0.8, 'MaxHeadSize', 0.5);
end
