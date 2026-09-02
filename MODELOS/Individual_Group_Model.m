function [xrot, yrot, zrot, h] = Individual_Group_Model(x, y, theta , op)
%INDIVIDUAL_GROUP_MODEL Densidad proxémica grupal (suma de gaussianas).
%   op controla cómo se obtiene "h" (nivel de contorno de la zona grupal):
%     op == 1  -> h se calcula analíticamente evaluando el modelo
%                 gaussiano en (xh,yh), el borde de la zona íntima de la
%                 persona más expuesta del grupo (ver más abajo).
%     op ~= 1  -> h usa un valor fijo por defecto, sin depender de las
%                 posiciones (ver el bloque if/else al final).
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y)
        error('x e y deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';

    if isempty(x)
        xrot = [];
        yrot = [];
        zrot = [];
        h = [];
        return;
    end

    addpath(fullfile(fileparts(mfilename('fullpath')), 'FUNCTIONS'));

    % ===================== PARÁMETROS DEL MODELO =====================
    % Malla de evaluación: margen extra alrededor del bounding box de las
    % personas (lado) y resolución de la grilla (paso). lado chico puede
    % recortar el contorno si el grupo está muy disperso; paso chico da un
    % contorno más suave pero es más caro de calcular (esta malla se
    % reconstruye por grupo y por cuadro en la animación).
    lado = 5;
    paso = 0.1;

    % Ancho de la gaussiana individual (misma para todas las personas).
    % Subirlo hace que las campanas se solapen más y el grupo se vea como
    % un solo "blob" continuo; bajarlo separa más los picos individuales.
    sigma = 0.75;

    % Distancia a la que se proyecta (xh,yh) desde la persona más expuesta
    % del grupo (ver más abajo), hacia afuera: Dh = R_HB + D_iz.
    %   R_HB = radio corporal
    %   D_iz = distancia de la zona proxémica íntima (Hall)
    % Aumentar Dh aleja (xh,yh) de cualquier pico gaussiano -> h calculado
    % sale más bajo -> el contorno (zz > h) encierra un área más grande.
    % Reducirlo hace lo contrario: h más alto, contorno más ajustado.
    R_HB = 0.0763;
    D_iz = 0.5;
    Dh = R_HB + D_iz;

    % Valor por defecto de h cuando op ~= 1 (no se calcula por distancias).
    % Obtenido empíricamente (pruebas con varios grupos): en promedio es el
    % nivel de densidad que incluye la zona proxémica íntima de los
    % integrantes del grupo.
    h_default = 0.85;
    % ===================================================================

    xpos = abs(max(x)) + lado;
    xneg = -abs(min(x)) - lado;
    ypos = abs(max(y)) + lado;
    yneg = -abs(min(y)) - lado;
    [xx, yy] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));

    % Gaussiana circular por persona y suma total (sigma constante)
    zz = zeros(size(xx));
    for i = 1:numel(x)
        zz = zz + exp(-((xx - x(i)).^2 + (yy - y(i)).^2) / (2 * sigma^2));
    end

    xrot = xx;
    yrot = yy;
    zrot = zz;

    % h = densidad grupal evaluada en (xh,yh): el punto ubicado al borde
    % de la zona proxémica íntima de Hall de la persona MÁS ALEJADA del
    % centro geométrico del grupo (la más "expuesta" del grupo), sobre el
    % eje que la une con ese centro (mismo eje que usa Aracelly_model.m
    % para la orientación), proyectado hacia AFUERA del grupo: se
    % extiende la posición de esa persona alejándola del centro, nunca
    % acercándola. Así (xh,yh) queda siempre más lejos del centro que la
    % propia persona (el borde de su zona íntima "por detrás", visto
    % desde el grupo), nunca más cerca. Dh se define en el bloque de
    % parámetros al comienzo de la función.

    % Centro geométrico del grupo: centro del bounding box, NO el
    % centroide/promedio de las posiciones. Se prefiere así porque el
    % centroide pondera más a los subgrupos de personas ya agrupadas entre
    % sí y puede dejar de lado a quienes están más alejadas del resto; el
    % centro del bounding box no depende de cuántas personas haya cerca
    % del centro y le da el mismo peso a los extremos del grupo. Sujeto a
    % revisión: hay varios enfoques posibles (p.ej. centroide, centro
    % ponderado) aún en evaluación.
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;

    % Persona más alejada del centro del grupo
    % NOTA: este argmax es discreto. Si dos personas están casi empatadas
    % en distAlCentro, un pequeño movimiento puede cambiar idxFar de una
    % persona a otra de un cuadro a otro, lo que hace saltar (xf,yf), la
    % dirección hacia afuera y, por tanto, (xh,yh) y el valor de h. Lo
    % mismo ocurre si cambia la pertenencia al grupo (umbral duro en
    % Group_Detector_Distan): el número de términos que se suman en h
    % cambia de golpe. Estas discontinuidades no se corrigen aquí; se
    % atenúan aguas abajo con un suavizado temporal de h (ver
    % Experimento_01.m, variable hSmooth).
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
        h = sum(exp(-((xh - x).^2 + (yh - y).^2) / (2 * sigma^2)));
    else
        h = h_default;
    end
end