function [xrot, yrot, zrot, h] = Paco_Model(x, y, theta, op)
    % Paco_Model: genera una sección gaussiana rotada y devuelve solo
    % los puntos cuya altura z es >= h. Los puntos por debajo del umbral se
    % eliminan (filtro). No se grafica nada.
    %   op controla cómo se obtiene "h" (nivel de contorno de la zona
    %   grupal):
    %     op == 1  -> h se calcula analíticamente evaluando la gaussiana
    %                 de este modelo en (xh,yh), el punto ubicado al borde
    %                 de la zona íntima de Hall de la persona MÁS ALEJADA
    %                 del centro geométrico del grupo (la más "expuesta"),
    %                 proyectado hacia AFUERA del grupo. Mismo principio
    %                 que usa Individual_Group_Model.m.
    %     op ~= 1  -> h usa un valor fijo por defecto (ver PARÁMETROS DEL
    %                 MODELO más abajo).
    %   theta (orientación de cada persona) se recibe por consistencia de
    %   firma con Modelo.m; este modelo no la usa: su orientación de grupo
    %   sale de orientacion_vec, no de la orientación individual de nadie.
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y)
        error('x e y deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';

    if numel(x) < 2
        xrot = [];
        yrot = [];
        zrot = [];
        h = [];
        return;
    end

    % ===================== PARÁMETROS DEL MODELO =====================
    % Distancia a la que se proyecta (xh,yh) desde la persona más expuesta
    % del grupo, hacia afuera: Dh = R_HB + D_iz (mismo principio que
    % Individual_Group_Model.m).
    %   R_HB = radio corporal
    %   D_iz = distancia de la zona proxémica íntima (Hall)
    R_HB = 0.0763;
    D_iz = 0.5;
    Dh = R_HB + D_iz;

    % Valor por defecto de h cuando op ~= 1 (no se calcula por distancias).
    h_default = 0.5;
    % ===================================================================

    % Centro del grupo
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;

    %xcm = mean(x);
    %ycm = mean(y);

    % Ordenar puntos alrededor del centro
    [x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);

    % Determinar orientación del grupo
    ang_vec = orientacion_vec(x_ord, y_ord, xcm, ycm, 1);

    % Filtrar personas muy cercanas entre sí
    for i = 1:length(x)
        [dis, ang] = dis_ang(x_ord, y_ord, xcm, ycm);
        [x_mod, y_mod] = entre_personas(13, ang, dis, x_ord, y_ord); %angulo minimo de reduccion de personas
        if length(x_mod) == length(x_ord)
            break;
        else
            x_ord = x_mod;
            y_ord = y_mod;
        end
    end

    % Completar distribución si hay huecos grandes
    [x_aum, y_aum] = aumentar_02(40, x_mod, y_mod, xcm, ycm);  %%% separacion maximopara aumentar 70

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
    paso = 0.1;
    xneg = min(x) - lado;
    xpos = max(x) + lado;
    yneg = min(y) - lado;
    ypos = max(y) + lado;
    [xx, yy] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));
  
    % Ángulo de cada punto de la malla respecto al centro del grupo (no
    % confundir con el parámetro theta de orientación de las personas).
    angGrid = mod(rad2deg(atan2(yy - ycm, xx - xcm)), 360);
    alpha = max(1, min(360, round(angGrid)));

    varianzax = sigma_xx(alpha);
    varianzay = sigma_yy(alpha);
  
    zz = exp(-(xx - xcm).^2 ./ (2 .* varianzax.^2) - (yy - ycm).^2 ./ (2 .* varianzay.^2));

    % Rotar la gaussiana
    [xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, rotacion, xcm, ycm);

    % h = densidad grupal evaluada en (xh,yh): el punto ubicado al borde
    % de la zona proxémica íntima de Hall de la persona MÁS ALEJADA del
    % centro geométrico del grupo (la más "expuesta" del grupo), sobre el
    % eje que la une con ese centro, proyectado hacia AFUERA del grupo: se
    % extiende la posición de esa persona alejándola del centro, nunca
    % acercándola. Mismo principio que Individual_Group_Model.m.
    % Persona más alejada del centro del grupo. NOTA: este argmax es
    % discreto y puede hacer saltar (xh,yh) -y por tanto h- de un cuadro a
    % otro si dos personas están casi empatadas en distancia (ver la misma
    % nota en Individual_Group_Model.m).
    distAlCentro = hypot(x - xcm, y - ycm);
    [~, idxFar] = max(distAlCentro);
    xf = x(idxFar);
    yf = y(idxFar);

    dirx = xf - xcm; % del centro hacia esa persona (sentido "hacia afuera")
    diry = yf - ycm;
    distFromCentroid = distAlCentro(idxFar);

    if distFromCentroid < eps
        % Todas las personas coinciden con el centro del grupo (p.ej. un
        % único integrante): no hay una dirección definida hacia afuera,
        % se usa +X por defecto.
        ux = 1; uy = 0;
    else
        ux = dirx / distFromCentroid;
        uy = diry / distFromCentroid;
    end

    xh = xf + Dh * ux;
    yh = yf + Dh * uy;

    if op == 1
        % La gaussiana final está rotada por "rotacion" alrededor de
        % (xcm,ycm) respecto a la que realmente define sigma_xx/sigma_yy
        % (ver rotar_gaussiana.m: aplica, en efecto, una rotación de
        % -rotacion). Para evaluar el modelo en (xh,yh) hay que deshacer
        % esa rotación (aplicar +rotacion) antes de mirar el ángulo y las
        % sigmas.
        angInv = deg2rad(rotacion);
        xhq = cos(angInv)*(xh - xcm) - sin(angInv)*(yh - ycm) + xcm;
        yhq = sin(angInv)*(xh - xcm) + cos(angInv)*(yh - ycm) + ycm;

        angH = mod(rad2deg(atan2(yhq - ycm, xhq - xcm)), 360);
        alphaH = max(1, min(360, round(angH)));
        varianzaxH = sigma_xx(alphaH);
        varianzayH = sigma_yy(alphaH);

        h = exp(-(xhq - xcm)^2 / (2 * varianzaxH^2) - (yhq - ycm)^2 / (2 * varianzayH^2));
    else
        h = h_default;
    end
end
