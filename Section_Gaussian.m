function [xrot, yrot, zrot] = Section_Gaussian(x, y)
    % Section_Gaussian: genera una sección gaussiana rotada y devuelve solo
    % los puntos cuya altura z es >= h. Los puntos por debajo del umbral se
    % eliminan (filtro). No se grafica nada.

    if nargin < 3 || isempty(h)
        h = 0.58;
    end

    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(h)
        error('x, y y h deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';

    if numel(x) < 2
        x_sec = [];
        y_sec = [];
        z_sec = [];
        return;
    end

    addpath(fullfile(fileparts(mfilename('fullpath')),'FUNCTIONS'));

    % Centro del grupo
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;

    % Ordenar puntos alrededor del centro
    [x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);

    % Determinar orientación del grupo
    ang_vec = orientacion_vec(x_ord, y_ord, xcm, ycm, 0);

    % Filtrar personas muy cercanas entre sí
    for i = 1:length(x)
        [dis, ang] = dis_ang(x_ord, y_ord, xcm, ycm);
        [x_mod, y_mod] = entre_personas(15, ang, dis, x_ord, y_ord);
        if length(x_mod) == length(x_ord)
            break;
        else
            x_ord = x_mod;
            y_ord = y_mod;
        end
    end

    % Completar distribución si hay huecos grandes
    [x_aum, y_aum] = aumentar_02(70, x_mod, y_mod, xcm, ycm);

    % Hallar la primera orientación de referencia
    orientacion = 1000;
    [dis, ang] = dis_ang(x_aum, y_aum, xcm, ycm);
    for i = 1:length(ang)
        if ang_vec < ang(i)
            orientacion = ang(i);
            break;
        end
    end
    if orientacion == 1000
        orientacion = ang(1);
    end
    rotacion = -orientacion;

    % Reordenar según la orientación y calcular sigmas
    [ang_new, ang, x_new, y_new] = ordenamiento(ang, orientacion, x_aum, y_aum);
    [dis, ang_sum] = dis_ang(x_new, y_new, xcm, ycm);

    min_sig = 0.5;
    sigma_x = abs(dis) + min_sig;
    sigma_y = abs(dis) + min_sig;
    sigma_x(end + 1) = sigma_x(1);
    sigma_y(end + 1) = sigma_y(1);

    for i = 1:length(ang)
        if i == length(ang)
            distan(i) = 360 - ang(i) + ang(1);
        else
            distan(i) = ang(i + 1) - ang(i);
        end
    end
    distancias = [0, distan];

    delta_ang = 1;
    j = 2;
    k = 1;
    cont = 0;
    angulo = 0;
    sigma_xx = zeros(1, 360);
    sigma_yy = zeros(1, 360);

    for i = 1:360
        if i > distancias(j) + angulo
            angulo = distancias(j) + angulo;
            j = j + 1;
            k = k + 1;
            cont = 0;
        end
        %este if es un cambio reciente
        if j > numel(distancias)
            continue;
        end
        t1 = distancias(j) - cont;
        t2 = cont;
        cont = cont + delta_ang;
        sigma_xx(i) = ((t1 / distancias(j)) * sigma_x(k)) + ((t2 / distancias(j)) * sigma_x(k + 1));
        sigma_yy(i) = ((t1 / distancias(j)) * sigma_y(k)) + ((t2 / distancias(j)) * sigma_y(k + 1));
    end

    % Malla de evaluación
    lado = 5;
    paso = 0.05;
    xpos = abs(max(x)) + lado;
    xneg = abs(min(x)) - lado;
    ypos = abs(max(y)) + lado;
    yneg = abs(min(y)) - lado;
    [xx, yy] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));

    tam = size(yy);
    varianzax = zeros(tam(1), tam(2));
    varianzay = zeros(tam(1), tam(2));
    for i = 1:tam(1)
        for j = 1:tam(2)
            theta = atan2(yy(i, j) - ycm, xx(i, j) - xcm);
            theta = mod(rad2deg(theta), 360);
            alpha = round(theta);
            if alpha >= 360
                alpha = 360;
            elseif alpha <= 1
                alpha = 1;
            end
            varianzax(i, j) = sigma_xx(alpha);
            varianzay(i, j) = sigma_yy(alpha);
        end
    end

    zz = exp(-(xx - xcm).^2 ./ (2 .* varianzax.^2) - (yy - ycm).^2 ./ (2 .* varianzay.^2));

    % Rotar la gaussiana
    [xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, rotacion, xcm, ycm);

    % Filtro por altura: solo guardar puntos por encima del umbral h
    %mask = zrot >= h;
    %x_sec = xrot(mask);
    %y_sec = yrot(mask);
    %z_sec = zrot(mask);
end
