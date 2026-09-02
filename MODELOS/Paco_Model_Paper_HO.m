function [xrot, yrot, zrot, h, Dcorte] = Paco_Model_Paper_HO(x, y, theta_xy, op)
    % Paco_Model_Paper_HO: variante de Paco_Model_paper con "h
    % optimizado por sección" (ver papers/
    % Modelo_Gaussiano_Sectional_Angular.md). Genera la misma gaussiana
    % 2D seccional (Ec. 1), pero en vez de un único Z_corte plano
    % (op ~= 1) o un único punto dinámico (versión original de op == 1),
    % calcula un umbral h distinto POR SECCIÓN angular: una superficie de
    % corte con forma (no un plano paralelo a XY), que sigue la anchura
    % real (sigma_xj/sigma_yj) de cada sección. No se grafica nada; los
    % puntos no se filtran dentro de la función (igual que
    % Paco_Model_paper.m), pero se devuelve "Dcorte" = Zg - h_por_sección
    % ya lista para trazar el borde de corte con contour(...,[0,0]),
    % conservando el mismo costo de cómputo que un contour de nivel fijo
    % (ver discusión de costo contour vs. dibujar la nube de puntos).
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
    %   op controla cómo se obtiene "h" (== Z_corte, nivel de corte de la
    %   zona grupal):
    %     op == 1  -> H OPTIMIZADO POR SECCIÓN (aporte de esta variante,
    %                 no está en el paper ni en la versión original de
    %                 Paco_Model_paper.m): para cada sección angular j se
    %                 evalúa la gaussiana de esa MISMA sección
    %                 (sigma_xj(j), sigma_yj(j)) en el punto ubicado al
    %                 borde de su propia zona íntima de Hall (radio
    %                 d_interpolado(j) + Dh, en la dirección angular de
    %                 la sección), proyectado hacia AFUERA del grupo.
    %                 Mismo principio que el (xh,yh) de la persona más
    %                 expuesta que usa Paco_Model_paper.m/
    %                 Individual_Group_Model.m, pero generalizado a las
    %                 n_secciones en vez de a una sola persona. El
    %                 resultado, "h", es un VECTOR (1 x n_secciones): la
    %                 superficie de corte ya no es un plano paralelo a
    %                 XY, sino que sigue la forma de la gaussiana
    %                 seccionada.
    %     op ~= 1  -> h usa un valor fijo por defecto (ver PARÁMETROS DEL
    %                 MODELO más abajo), equivalente al Z_corte constante
    %                 del paper (plano paralelo a XY, igual que en
    %                 Paco_Model_paper.m).
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
        Dcorte = [];
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
    % Define la resolución de la malla angular: 360/Delta_gamma secciones
    % en total (con Delta_gamma = 1 -> 360 secciones de 1°). Debe dividir
    % exactamente a 360.
    Delta_gamma = 0.5;
    if mod(360, Delta_gamma) ~= 0
        error('Delta_gamma debe dividir exactamente a 360.');
    end
    n_secciones = 360 / Delta_gamma; % número de secciones angulares (antes hardcodeado en 360)

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
    sigma_xj = zeros(1, n_secciones);
    sigma_yj = zeros(1, n_secciones);

    for i = 1:n_secciones
        angulo_actual = i * Delta_gamma; % ángulo (en grados) que representa la sección i
        if angulo_actual > omega_ext(j) + phi_acc
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
    % (1-n_secciones) usado para asignar varianzas (Ec. 13). Cada sección
    % i cubre el rango angular ((i-1)*Delta_gamma, i*Delta_gamma], igual
    % que en el bucle que llena sigma_xj/sigma_yj.
    alpha_gk = mod(rad2deg(atan2(Yg - Ycg, Xg - Xcg)), 360);
    idx_gk = max(1, min(n_secciones, ceil(alpha_gk / Delta_gamma)));

    sigma_xk = sigma_xj(idx_gk);
    sigma_yk = sigma_yj(idx_gk);

    % Ec. 1: función gaussiana base
    Zg = exp(-(Xg - Xcg).^2 ./ (2 .* sigma_xk.^2) - (Yg - Ycg).^2 ./ (2 .* sigma_yk.^2));

    % Rotar la gaussiana de vuelta al sistema original (Ec. 22, Sección
    % 11.7: rotación inversa)
    [xrot, yrot, zrot] = rotar_gaussiana(Xg, Yg, Zg, rot, Xcg, Ycg);

    % ================== APORTE DE ESTA VARIANTE (H OPTIMIZADO) ==================
    % Generaliza el "punto al borde de la zona íntima de la persona más
    % expuesta" (usado en Paco_Model_paper.m) a CADA sección angular: en
    % vez de una sola persona, cada sección j tiene su propio punto de
    % referencia, en la misma dirección angular que la sección
    % (angulo_actual(j) = j*Delta_gamma, el mismo ángulo interno -antes de
    % la rotación inversa- que usa el bucle que llena sigma_xj/sigma_yj),
    % a un radio d_interpolado(j) + Dh.
    %
    % d_interpolado(j) se recupera de sigma_xj sin necesidad de
    % interpolar d_i aparte: como sigma_xj es la interpolación lineal de
    % sigma_Mx = d_i + sigma_min (Ec. 4), y sigma_min es constante, restar
    % sigma_min a la interpolación ya interpolada de sigma_Mx da
    % exactamente la interpolación de d_i (la interpolación lineal
    % conmuta con un corrimiento constante).
    d_interp = sigma_xj - sigma_min; % d_i interpolado por sección (Ec. 4 invertida)
    r_ref = d_interp + Dh;           % radio de referencia por sección (borde zona íntima + margen, hacia afuera)
    angulo_secciones = (1:n_secciones) * Delta_gamma; % mismo ángulo interno usado al llenar sigma_xj/sigma_yj

    % Punto de referencia de cada sección, ya en el sistema interno
    % (relativo a Xcg,Ycg, antes de la rotación inversa) -no requiere
    % deshacer ninguna rotación, a diferencia del cálculo de una sola
    % persona en Paco_Model_paper.m, porque ya se está iterando
    % directamente en el mismo sistema angular que indexa sigma_xj/sigma_yj.
    dx_ref = r_ref .* cosd(angulo_secciones);
    dy_ref = r_ref .* sind(angulo_secciones);

    % Ec. 1 evaluada en el punto de referencia de cada sección, con las
    % varianzas de esa misma sección: h_section(j) es el "Z_corte" propio
    % de la sección j. Vector 1 x n_secciones: superficie de corte con
    % forma, no un plano paralelo a XY.
    h_section = exp(-(dx_ref.^2) ./ (2 .* sigma_xj.^2) - (dy_ref.^2) ./ (2 .* sigma_yj.^2));

    if op == 1
        h = h_section; % h optimizado por sección (vector)
        h_grid = reshape(h_section(idx_gk), size(Zg));
    else
        h = Z_corte_default; % plano paralelo a XY, igual que Paco_Model_paper.m
        h_grid = h; % escalar: se expande por broadcasting al restar de Zg
    end

    % Dcorte = Zg - h_por_sección: su curva de nivel 0 es exactamente el
    % borde de corte (plano si h es escalar, con forma si h es un vector
    % por sección). Como rotar_gaussiana solo mueve las coordenadas (Xg,Yg)
    % y no altera el valor Z de cada punto (ver rotar_gaussiana.m: Zrot =
    % zz sin cambios), Dcorte ya corresponde índice a índice con
    % (xrot,yrot) sin necesidad de una segunda rotación.
    Dcorte = Zg - h_grid;
end
