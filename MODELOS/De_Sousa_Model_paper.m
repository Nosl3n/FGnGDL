function [xrot, yrot, zrot, h] = De_Sousa_Model_paper(x, y, theta, op)
%   Implementación "fiel al paper" del modelo de De Sousa para zonas
%   proxémicas grupales, según se describe en algoritmo_gaussiano_grupo.md
%   (algoritmo gaussiano asimétrico para zonas proxémicas de grupos).
%
%   El paper propone una fórmula FIJA: las varianzas frente/atrás/
%   derecha/izquierda se calculan solo a partir de la dispersión
%   geométrica del grupo ("md"), sin variar. Las variables FV/IV que se
%   agregan en este archivo (Secciones 6-9 del documento) son justamente
%   la parte "variable" que el paper no tenía: sirven para modular esa
%   base fija con el estado emocional/social del grupo, SIN reemplazarla.
%   Con los valores por defecto de FV/IV (ver PARÁMETROS DEL MODELO) la
%   salida es numéricamente idéntica a la fórmula original de
%   De_Sousa_Model.m (iv_x = 1 en las 4 direcciones no cambia nada).
%
%   Correspondencia con algoritmo_gaussiano_grupo.md:
%     Centro del grupo (xcm,ycm)       -> variante bounding-box, igual
%                                          que De_Sousa_Model.m. El
%                                          reconocimiento/geometría de
%                                          grupo (Secciones 1-2:
%                                          Delaunay, media aritmética)
%                                          se deja tal cual está hoy y
%                                          se revisará en otra tarea.
%     Orientación del grupo (rotation) -> Sección 3, media circular de
%                                          las orientaciones individuales
%                                          theta_i. Reemplaza el cálculo
%                                          puramente geométrico de
%                                          orientacion_vec (que ignoraba
%                                          theta).
%     FV, IV_f / IV_r / IV_ri / IV_l   -> Secciones 6 y 7.
%     iv_f/iv_r/iv_ri/iv_l = FV . IV_x -> Sección 8 (producto escalar).
%     variance_* = base_paper x iv_x   -> Sección 9 (sigma_x = sigma_x^0
%                                          x iv_x), usando como sigma_x^0
%                                          la base geométrica fija del
%                                          paper (en función de md).
%     alpha, selección por cuadrante   -> Secciones 5 y 10 (dentro de
%                                          Assimetric_Gaussian.m).
%     g,h,k (aquí a,b,c)               -> Sección 11 (dentro de
%                                          Assimetric_Gaussian.m y en el
%                                          bloque de cálculo de "h").
%     f(x,y) = exp(-Q(x,y))            -> Sección 12.
%     Costo = K - f(x,y) para A*       -> Sección 13. No se calcula en
%                                          este archivo; se usa el mapa
%                                          zrot (o el escalar h) aguas
%                                          abajo, p.ej. en AStar_Grid.m.
%
%   op controla cómo se obtiene "h" (nivel de contorno de la zona grupal):
%     op == 1  -> h se calcula analíticamente evaluando la gaussiana
%                 asimétrica de este modelo (ver Assimetric_Gaussian.m) en
%                 (xh,yh), el punto ubicado al borde de la zona íntima de
%                 Hall de la persona MÁS ALEJADA del centro geométrico del
%                 grupo (la más "expuesta"), proyectado hacia AFUERA del
%                 grupo. Mismo principio que usa Individual_Group_Model.m.
%                 Esta idea de "h" es una extensión propia de este
%                 archivo: no aparece en algoritmo_gaussiano_grupo.md.
%     op ~= 1  -> h usa un valor fijo por defecto (ver PARÁMETROS DEL
%                 MODELO más abajo).
%
%   theta (orientación de cada persona, en GRADOS, igual convención que
%   Aracelly_model_theta.m) ahora SÍ se usa: define la orientación del
%   grupo por media circular (Sección 3). A diferencia de
%   De_Sousa_Model.m, aquí theta deja de ignorarse.
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y)
        error('x e y deben ser numéricos.');
    end
    if ~isnumeric(theta)
        error('theta debe ser numérico.');
    end

    x = x(:).';
    y = y(:).';
    theta = theta(:).';

    if numel(x) < 2
        xrot = [];
        yrot = [];
        zrot = [];
        h = [];
        return;
    end

    if numel(theta) ~= numel(x)
        error('theta debe tener el mismo número de elementos que x e y.');
    end

    % ===================== PARÁMETROS DEL MODELO =====================
    % --- Geometría / contorno (igual que De_Sousa_Model.m) ---
    % Distancia a la que se proyecta (xh,yh) desde la persona más expuesta
    % del grupo, hacia afuera: Dh = R_HB + D_iz (mismo principio que
    % Individual_Group_Model.m).
    %   R_HB = radio corporal
    %   D_iz = distancia de la zona proxémica íntima (Hall)
    R_HB = 0.0763;
    D_iz = 0.5;
    Dh = R_HB + D_iz;

    % Valor por defecto de h cuando op ~= 1 (no se calcula por distancias).
    h_default = 0.4;

    % --- Modulación social/emocional (algoritmo_gaussiano_grupo.md, Secciones 6-9) ---
    % FV: vector de características de socialización del grupo, cada
    % componente en (0, 1] (Sección 6). Ejemplo con una sola
    % característica = estado emocional (0.14 enojado ... 0.98 feliz).
    % Por defecto FV = 1 ("aceptación total"): junto con IV_* = 1 esto
    % reproduce EXACTAMENTE las varianzas fijas del paper original.
    % Para activar la modulación, cambiar FV (y/o los IV_*) por los
    % valores reales del grupo, p.ej. FV = 0.70 (estado neutral).
    FV = 1;

    % IV_f, IV_r, IV_ri, IV_l: vectores de influencia por dirección
    % (frente, trasera, derecha, izquierda), cada componente en [-1, 1]
    % (Sección 7). Deben tener el mismo número de componentes que FV.
    % Al quedar separados, IV_ri e IV_l ya NO están forzados a coincidir
    % como en De_Sousa_Model.m (ahí variance_right y variance_left usaban
    % la misma expresión): esto es lo que rompe la simetría lateral.
    IV_f  = 1;
    IV_r  = 1;
    IV_ri = 1;
    IV_l  = 1;

    % Piso numérico para iv_x = FV . IV_x (Sección 8). El documento
    % permite iv_x <= 0 ("rechazo total"), pero una varianza <= 0 rompe
    % la gaussiana (división por cero / exponente mal definido); ese
    % caso no lo cubre el paper, así que aquí se acota a un mínimo
    % positivo para mantener la función bien definida.
    IV_FLOOR = 0.05;
    % ===================================================================

    %% ordenar detemrinar el centro del grupo
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;
    %% Ordenar puntos
    [x_ord, y_ord] = ordenar_puntos(xcm,ycm,x,y);
    %% determinar las distancias del CG a cada persona.
    [dis, ang] = dis_ang (x_ord,y_ord,xcm,ycm); %#ok<ASGLU>
    %% determinar la maxima distancia.
    md = max(dis);

    %% Determinar la orientación del grupo (Sección 3: media circular)
    % theta_grupo = atan2(sum(sin(theta_i)), sum(cos(theta_i)))
    % Reemplaza el enfoque geométrico de orientacion_vec (que ignoraba
    % theta) por la orientación real de las personas del grupo, tal
    % como lo define el documento.
    theta_rad = deg2rad(theta);
    theta_grupo = atan2(sum(sin(theta_rad)), sum(cos(theta_rad)));
    rotation = theta_grupo;

    %% Influencias dinámicas iv_x = FV . IV_x (Sección 8)
    iv_f  = max(dot(FV, IV_f),  IV_FLOOR);
    iv_r  = max(dot(FV, IV_r),  IV_FLOOR);
    iv_ri = max(dot(FV, IV_ri), IV_FLOOR);
    iv_l  = max(dot(FV, IV_l),  IV_FLOOR);

    %% Parametro de la funcion gaussiana
    % Base geométrica fija del paper (idéntica a De_Sousa_Model.m),
    % modulada por iv_x (Sección 9: sigma_x = sigma_x^0 x iv_x). Con
    % los valores por defecto de FV/IV, iv_x = 1 y esto es exactamente
    % la fórmula original, sin cambio numérico alguno.
    variance_front = (md+1*md)   * iv_f;   % Varianza al frente
    variance_right = (md+0.5*md) * iv_ri;  % Varianza a la derecha
    variance_left  = (md+0.5*md) * iv_l;   % Varianza a la izquierda
    variance_rear  = (md+0.1)    * iv_r;   % Varianza atrás
    %% Llamada a la función
    [xrot, yrot, zrot] = Assimetric_Gaussian(x, y, xcm, ycm, rotation, variance_front, variance_right, variance_left, variance_rear);

    % h = densidad grupal evaluada en (xh,yh): el punto ubicado al borde
    % de la zona proxémica íntima de Hall de la persona MÁS ALEJADA del
    % centro geométrico del grupo (la más "expuesta" del grupo), sobre el
    % eje que la une con ese centro, proyectado hacia AFUERA del grupo: se
    % extiende la posición de esa persona alejándola del centro, nunca
    % acercándola. Mismo principio que Individual_Group_Model.m. Esta
    % idea de "h" es una extensión propia de este archivo, no forma
    % parte de algoritmo_gaussiano_grupo.md.
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
        % Misma fórmula que Assimetric_Gaussian.m (Secciones 5, 10 y 11
        % del documento), evaluada en (xh,yh) en vez de sobre toda la
        % malla (xrot,yrot). variance_front/right/left/rear ya incluyen
        % la modulación FV/IV calculada arriba.
        alpha = atan2(yh - ycm, xh - xcm) - rotation + pi/2;
        alpha = mod(alpha + pi, 2*pi) - pi;

        if alpha <= 0
            varianceH = variance_rear;
        else
            varianceH = variance_front;
        end
        if abs(alpha) >= pi/2
            varianceSidesH = variance_left;
        else
            varianceSidesH = variance_right;
        end

        cr = cos(rotation);
        sr = sin(rotation);
        a = cr^2/(2*varianceH) + sr^2/(2*varianceSidesH);
        b = sin(2*rotation)/(4*varianceH) - sin(2*rotation)/(4*varianceSidesH);
        c = sr^2/(2*varianceH) + cr^2/(2*varianceSidesH);

        dxh = xh - xcm;
        dyh = yh - ycm;
        h = exp(-(a*dxh^2 + 2*b*dxh*dyh + c*dyh^2)); % Sección 12
    else
        h = h_default;
    end
end
