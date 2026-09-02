function [xrot, yrot, zrot, h] = Paco_Model_paper(x, y, theta_xy, op)
    % Paco_Model_paper: implementación del "Modelo Gaussiano Sectional
    % Angular con Parametrización Adaptable" (ver papers/
    % Modelo_Gaussiano_Sectional_Angular.md). Genera una única gaussiana
    % 2D cuya varianza varía por sección angular (no es una elipse fija),
    % y devuelve solo los puntos cuya altura Zg es >= h (filtro por
    % Z_corte). Los puntos por debajo del umbral se eliminan. No se
    % grafica nada.
    %
    % Correspondencia de nombres con el paper (mismo símbolo, distinto
    % nombre de variable MATLAB porque el código se escribió antes que la
    % notación final del paper):
    %   Xcg, Ycg           <-> X_cg, Y_cg           (centro del grupo, Ec. 9-10)
    %   theta_i, d_i       <-> theta_i, d_i         (ángulo/distancia de cada persona, Ec. 8, 11)
    %   alpha_ref          <-> alpha                (ángulo de referencia del grupo, Ec. 14-15)
    %   theta_ref, rot     <-> theta_(n-1), rotación (referencia de alineación y su inverso, Ec. 16)
    %   sigma_min          <-> sigma_min            (varianza mínima, Sección 4.1.1)
    %   sigma_Mx, sigma_My <-> sigma_Mxi, sigma_Myi (varianzas madre por persona, Ec. 4)
    %   omega / omega_ext  <-> omega_i              (intervalo angular entre personas, Ec. 5)
    %   Delta_gamma        <-> Delta_gamma          (incremento angular de discretización, Sección 4.1.2)
    %   sigma_xj, sigma_yj <-> sigma_xj, sigma_yj   (varianzas interpoladas por sección, Ec. 2-3)
    %   alpha_gk, idx_gk   <-> alpha_gk             (ángulo/sección de cada punto de malla, Ec. 12-13)
    %   Xg, Yg, Zg         <-> X_g, Y_g, Z_g        (malla y valor gaussiano, Ec. 1)
    %   beta_min, beta_max <-> beta_min, beta_max   (umbrales de fusión/inserción, Sección 4.2)
    %   Z_corte_default    <-> Z_corte              (umbral de corte, Sección 4.4.1)
    %
    %   op controla cómo se obtiene "h" (== Z_corte, nivel de contorno de
    %   la zona grupal):
    %     op == 1  -> h se calcula analíticamente evaluando la gaussiana
    %                 de este modelo en (xh,yh), el punto ubicado al borde
    %                 de la zona íntima de Hall de la persona MÁS ALEJADA
    %                 del centro geométrico del grupo (la más "expuesta"),
    %                 proyectado hacia AFUERA del grupo. Mismo principio
    %                 que usa Individual_Group_Model.m. NOTA: este cálculo
    %                 dinámico de h NO está en el paper (que define
    %                 Z_corte como una constante fija, Sección 4.4.1); es
    %                 un aporte posterior de este trabajo.
    %     op ~= 1  -> h usa un valor fijo por defecto (ver PARÁMETROS DEL
    %                 MODELO más abajo), equivalente al Z_corte constante
    %                 del paper.
    %   theta_xy (orientación de cada persona) se recibe por consistencia
    %   de firma con Modelo.m; este modelo no la usa: su orientación de
    %   grupo sale de orientacion_vec (alpha_ref, Ec. 14-15), no de la
    %   orientación individual de nadie.
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
    % beta_min, beta_max: umbrales angulares de optimización (Sección 4.2
    % del paper). El paper sugiere beta_min = 15°, beta_max = 70° como
    % valores de referencia; aquí se dejan en 13°/40°, que son los
    % valores que se fueron ajustando empíricamente en este trabajo
    % (no se modifican al hacer este rename).
    beta_min = 13; % angulo minimo de reduccion de personas (criterio Sección 4.2.1)
    beta_max = 40; % separacion maxima para aumentar (criterio Sección 4.2.2)

    % sigma_min: varianza mínima añadida a la distancia radial de cada
    % persona (Sección 4.1.1). Paper y código coinciden en 0.5.
    sigma_min = 0.5;

    % Delta_gamma: incremento angular de discretización (Sección 4.1.2).
    % Aquí se usa resolución de 1° (360 secciones en total).
    Delta_gamma = 1;

    % Distancia a la que se proyecta (xh,yh) desde la persona más expuesta
    % del grupo, hacia afuera: Dh = R_HB + D_iz (mismo principio que
    % Individual_Group_Model.m). Este bloque (R_HB, D_iz, Dh y el cálculo
    % de xh,yh más abajo) es un APORTE DE ESTE TRABAJO, no forma parte del
    % modelo descrito en el paper.
    %   R_HB = radio corporal
    %   D_iz = distancia de la zona proxémica íntima (Hall)
    R_HB = 0.0763;
    D_iz = 0.5;
    Dh = R_HB + D_iz;

    % Z_corte_default: valor por defecto de h (Z_corte, Sección 4.4.1)
    % cuando op ~= 1, es decir, cuando no se calcula por distancias. El
    % paper documenta Z_corte = 0.55; aquí se usa 0.5, valor ajustado
    % empíricamente en este trabajo (no se modifica al hacer este rename).
    Z_corte_default = 0.5;
    % ===================================================================

    % Centro del grupo (Ec. 9-10)
    Xcg = (max(x) + min(x)) / 2;
    Ycg = (max(y) + min(y)) / 2;

    % Ordenar puntos alrededor del centro (Sección 11.1, paso 3:
    % SortCounterclockwise)
    [x_ord, y_ord] = ordenar_puntos(Xcg, Ycg, x, y);

    % Determinar orientación del grupo: vector resultante y ángulo de
    % referencia alpha (Ec. 14-15)
    alpha_ref = orientacion_vec(x_ord, y_ord, Xcg, Ycg, 0);

    % Filtrar personas muy cercanas entre sí (Sección 11.2, Paso 1:
    % Eliminación de puntos cercanos, criterio beta <= beta_min)
    for i = 1:length(x)
        [d_i, theta_i] = dis_ang(x_ord, y_ord, Xcg, Ycg);
        [x_mod, y_mod] = entre_personas(beta_min, theta_i, d_i, x_ord, y_ord);
        if length(x_mod) == length(x_ord)
            break;
        else
            x_ord = x_mod;
            y_ord = y_mod;
        end
    end

    % Completar distribución si hay huecos grandes (Sección 11.2, Paso 2:
    % Inserción de puntos distantes, criterio beta > beta_max; Ec. 18-21)
    [x_aum, y_aum] = aumentar_02(beta_max, x_mod, y_mod, Xcg, Ycg);

    % Hallar la primera orientación de referencia: el theta_i del primer
    % individuo, el más cercano a alpha_ref en sentido counterclockwise
    % (Sección 11.1, paso 5)
    theta_ref = 1000;
    [d_i, theta_i] = dis_ang(x_aum, y_aum, Xcg, Ycg);
    for i = 1:length(theta_i)
        if alpha_ref < theta_i(i)
            theta_ref = theta_i(i);
            break;
        end
    end
    if theta_ref == 1000
        theta_ref = theta_i(1);
    end
    rot = -theta_ref; % ángulo de rotación inicial (Sección 11.3: rot = -theta_(n-1))

    % Reordenar según la orientación (Ec. 16: alinea el primer individuo
    % con el eje X') y calcular sigmas madre (Ec. 4)
    [theta_i_reordered, theta_i, x_new, y_new] = ordenamiento(theta_i, theta_ref, x_aum, y_aum);
    [d_i, ang_sum] = dis_ang(x_new, y_new, Xcg, Ycg);

    sigma_Mx = abs(d_i) + sigma_min; % Ec. 4: sigma_Mxi = di + sigma_min
    sigma_My = abs(d_i) + sigma_min; % Ec. 4: sigma_Myi = di + sigma_min
    sigma_Mx(end + 1) = sigma_Mx(1);
    sigma_My(end + 1) = sigma_My(1);

    % omega: intervalo angular entre personas consecutivas (Ec. 5)
    for i = 1:length(theta_i)
        if i == length(theta_i)
            omega(i) = 360 - theta_i(i) + theta_i(1);
        else
            omega(i) = theta_i(i + 1) - theta_i(i);
        end
    end
    omega_ext = [0, omega];

    j = 2;
    k = 1;
    cont = 0;
    phi_acc = 0; % acumulador del límite angular de la sección actual (phi_j, Ec. 6-7)
    sigma_xj = zeros(1, 360);
    sigma_yj = zeros(1, 360);

    for i = 1:360
        if i > omega_ext(j) + phi_acc
            phi_acc = omega_ext(j) + phi_acc;
            j = j + 1;
            k = k + 1;
            cont = 0;
        end
        %este if es un cambio reciente
        if j > numel(omega_ext)
            continue;
        end
        t1 = omega_ext(j) - cont;
        t2 = cont;
        cont = cont + Delta_gamma;
        % Interpolación lineal de varianzas por sección (Ec. 2-3)
        sigma_xj(i) = ((t1 / omega_ext(j)) * sigma_Mx(k)) + ((t2 / omega_ext(j)) * sigma_Mx(k + 1));
        sigma_yj(i) = ((t1 / omega_ext(j)) * sigma_My(k)) + ((t2 / omega_ext(j)) * sigma_My(k + 1));
    end

    % Malla de evaluación (Sección 11.5, Etapa 5)
    lado = 5;
    paso = 0.1;
    xneg = min(x) - lado;
    xpos = max(x) + lado;
    yneg = min(y) - lado;
    ypos = max(y) + lado;
    [Xg, Yg] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));

    % alpha_gk: ángulo de cada punto de la malla respecto al centro del
    % grupo (Ec. 12; no confundir con el parámetro theta_xy de
    % orientación de las personas). idx_gk: índice de sección angular
    % (1-360°) usado para asignar varianzas (Ec. 13).
    alpha_gk = mod(rad2deg(atan2(Yg - Ycg, Xg - Xcg)), 360);
    idx_gk = max(1, min(360, round(alpha_gk)));

    sigma_xk = sigma_xj(idx_gk);
    sigma_yk = sigma_yj(idx_gk);

    % Ec. 1: función gaussiana base
    Zg = exp(-(Xg - Xcg).^2 ./ (2 .* sigma_xk.^2) - (Yg - Ycg).^2 ./ (2 .* sigma_yk.^2));

    % Rotar la gaussiana de vuelta al sistema original (Ec. 22, Sección
    % 11.7: rotación inversa)
    [xrot, yrot, zrot] = rotar_gaussiana(Xg, Yg, Zg, rot, Xcg, Ycg);

    % ================== APORTE DE ESTE TRABAJO (no en el paper) ==================
    % h = densidad grupal evaluada en (xh,yh): el punto ubicado al borde
    % de la zona proxémica íntima de Hall de la persona MÁS ALEJADA del
    % centro geométrico del grupo (la más "expuesta" del grupo), sobre el
    % eje que la une con ese centro, proyectado hacia AFUERA del grupo: se
    % extiende la posición de esa persona alejándola del centro, nunca
    % acercándola. Mismo principio que Individual_Group_Model.m. El paper
    % (Sección 4.4.1) solo define Z_corte como una constante fija; este
    % cálculo dinámico de h es una extensión posterior de este trabajo.
    % Persona más alejada del centro del grupo. NOTA: este argmax es
    % discreto y puede hacer saltar (xh,yh) -y por tanto h- de un cuadro a
    % otro si dos personas están casi empatadas en distancia (ver la misma
    % nota en Individual_Group_Model.m).
    distAlCentro = hypot(x - Xcg, y - Ycg);
    [~, idxFar] = max(distAlCentro);
    xf = x(idxFar);
    yf = y(idxFar);

    dirx = xf - Xcg; % del centro hacia esa persona (sentido "hacia afuera")
    diry = yf - Ycg;
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
        % La gaussiana final está rotada por "rot" alrededor de
        % (Xcg,Ycg) respecto a la que realmente define sigma_xj/sigma_yj
        % (ver rotar_gaussiana.m: aplica, en efecto, una rotación de
        % -rot). Para evaluar el modelo en (xh,yh) hay que deshacer
        % esa rotación (aplicar +rot) antes de mirar el ángulo y las
        % sigmas.
        angInv = deg2rad(rot);
        xhq = cos(angInv)*(xh - Xcg) - sin(angInv)*(yh - Ycg) + Xcg;
        yhq = sin(angInv)*(xh - Xcg) + cos(angInv)*(yh - Ycg) + Ycg;

        alpha_h = mod(rad2deg(atan2(yhq - Ycg, xhq - Xcg)), 360);
        idx_h = max(1, min(360, round(alpha_h)));
        sigma_xk_h = sigma_xj(idx_h);
        sigma_yk_h = sigma_yj(idx_h);

        h = exp(-(xhq - Xcg)^2 / (2 * sigma_xk_h^2) - (yhq - Ycg)^2 / (2 * sigma_yk_h^2));
    else
        h = Z_corte_default;
    end
end
