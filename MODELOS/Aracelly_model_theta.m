function [xrot, yrot, zrot, h] = Aracelly_model_theta(x, y, theta, op)
%   ARACELLY_MODEL Densidad grupal como mezcla de gaussianas asimétricas.
%   Implementa el modelo de Vega et al. (2017): cada persona se representa
%   con una gaussiana 2D orientada (varianza frontal sigma_h, lateral
%   sigma_s) y la densidad grupal G_d(x,y) es la suma de las gaussianas
%   individuales. En esta versión, la orientación de cada persona se
%   recibe explícitamente mediante theta (en grados).
%   op controla cómo se obtiene "h" (nivel de contorno de la zona grupal):
%     op == 1  -> h se calcula analíticamente evaluando el modelo de
%                 gaussianas asimétricas en (xh,yh), el punto ubicado al
%                 borde de la zona íntima de Hall de la persona MÁS
%                 ALEJADA del centro geométrico del grupo (la más
%                 "expuesta"), proyectado hacia AFUERA del grupo. Mismo
%                 principio que usa Individual_Group_Model.m.
%     op ~= 1  -> h usa un valor fijo por defecto (ver PARÁMETROS DEL
%                 MODELO más abajo).

    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y) || ~isnumeric(theta)
        error('x, y y theta deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';
    theta = theta(:).';

    if isempty(x)
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
    % Varianzas proxémicas típicas (Vega et al., 2017)
    % Variables por defecto de individual model
    sigma_h = 0.9;   % frontal 
    sigma_s = 0.6;   % lateral
    % Valores por defecto (Vega et al., 2017)
    %sigma_h = 1.2;   % frontal
    %sigma_s = 0.6;   % lateral

    % Malla de evaluación: margen extra alrededor del bounding box de las
    % personas (lado) y resolución de la grilla (paso).
    lado = 5;
    paso = 0.1;

    % Distancia a la que se proyecta (xh,yh) desde la persona más expuesta
    % del grupo, hacia afuera: Dh = R_HB + D_iz (mismo principio que
    % Individual_Group_Model.m).
    %   R_HB = radio corporal
    %   D_iz = distancia de la zona proxémica íntima (Hall)
    R_HB = 0.0763;
    L_BB = 0.435; %Longitud de los hombros "Anchura bideltoidea" 
    D_iz = 0.5;
    Dh = (L_BB/2) + D_iz;

    % Valor por defecto de h cuando op ~= 1 (no se calcula por distancias).
    h_default = 0.85;
    % ===================================================================

    % Orientación de cada persona dada por theta (grados -> radianes)
    theta_rad = theta * pi / 180;

    % Coeficientes k1, k2, k3 por persona (gaussiana asimétrica orientada)
    k1 = cos(theta_rad).^2 ./ (2*sigma_s^2) + sin(theta_rad).^2 ./ (2*sigma_h^2);
    k2 = sin(2*theta_rad)  ./ (4*sigma_s^2) - sin(2*theta_rad)  ./ (4*sigma_h^2);
    k3 = sin(theta_rad).^2 ./ (2*sigma_s^2) + cos(theta_rad).^2 ./ (2*sigma_h^2);

    xneg = min(x) - lado;
    xpos = max(x) + lado;
    yneg = min(y) - lado;
    ypos = max(y) + lado;
    [xx, yy] = meshgrid(xneg:paso:xpos, yneg:paso:ypos);

    % Densidad global: suma de gaussianas individuales (mezcla gaussiana)
    zz = zeros(size(xx));
    for i = 1:numel(x)
        dx = xx - x(i);
        dy = yy - y(i);
        zz = zz + exp(-(k1(i).*dx.^2 + k2(i).*dx.*dy + k3(i).*dy.^2));
    end

    xrot = xx;
    yrot = yy;
    zrot = zz;

    % h = densidad grupal evaluada en (xh,yh): el punto ubicado al borde
    % de la zona proxémica íntima de Hall de la persona MÁS ALEJADA del
    % centro geométrico del grupo (la más "expuesta" del grupo), sobre el
    % eje que la une con ese centro, proyectado hacia AFUERA del grupo: se
    % extiende la posición de esa persona alejándola del centro, nunca
    % acercándola. Mismo principio que Individual_Group_Model.m, aplicado
    % aquí con la fórmula de gaussiana asimétrica orientada de este modelo.
    xcm = (max(x) + min(x)) / 2;
    ycm = (max(y) + min(y)) / 2;

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
        % Misma fórmula de la gaussiana asimétrica (k1,k2,k3 por persona),
        % evaluada en (xh,yh) en vez de en la malla (xx,yy).
        dxh = xh - x;
        dyh = yh - y;
        h = sum(exp(-(k1.*dxh.^2 + k2.*dxh.*dyh + k3.*dyh.^2)));
    else
        h = h_default;
    end
end
