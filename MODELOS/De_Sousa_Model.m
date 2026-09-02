function [xrot, yrot, zrot, h] = De_Sousa_Model(x, y, theta, op)
%   op controla cómo se obtiene "h" (nivel de contorno de la zona grupal):
%     op == 1  -> h se calcula analíticamente evaluando la gaussiana
%                 asimétrica de este modelo (ver Assimetric_Gaussian.m) en
%                 (xh,yh), el punto ubicado al borde de la zona íntima de
%                 Hall de la persona MÁS ALEJADA del centro geométrico del
%                 grupo (la más "expuesta"), proyectado hacia AFUERA del
%                 grupo. Mismo principio que usa Individual_Group_Model.m.
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

    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'FUNCTIONS'));

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
    h_default = 0.4;
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
    %% Determinar la direccion del grupo
    ang_vec = orientacion_vec(x_ord,y_ord,xcm,ycm,0);
    rotation = deg2rad(ang_vec);
    %% Parametro de la funcion gaussiana
    variance_front = md+1*md;      % Varianza al frente
    variance_right = md+0.5*md;    % Varianza a la derecha
    variance_left = md+0.5*md;     % Varianza a la izquierda
    variance_rear = md+0.1;        % Varianza atrás
    %% Llamada a la función
    [xrot, yrot, zrot] = Assimetric_Gaussian(x, y, xcm, ycm, rotation, variance_front, variance_right, variance_left, variance_rear);

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
        % Misma fórmula que Assimetric_Gaussian.m, evaluada en (xh,yh) en
        % vez de sobre toda la malla (xrot,yrot).
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
        h = exp(-(a*dxh^2 + 2*b*dxh*dyh + c*dyh^2));
    else
        h = h_default;
    end
end
