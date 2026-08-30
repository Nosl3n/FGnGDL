function smoothPath = SmoothPathCorners(pathXY, GX, GY, occ, cutFraction, samplesPerCorner)
%SMOOTHPATHCORNERS Redondea las esquinas de un camino poligonal.
%   smoothPath = SmoothPathCorners(pathXY, GX, GY, occ, cutFraction, samplesPerCorner)
%   Reemplaza cada vértice interior de pathXY por un arco de Bézier
%   cuadrática que "recorta" la esquina, usando como puntos de control
%   los dos puntos adyacentes sobre los segmentos entrante y saliente.
%   El arco queda siempre dentro del triángulo formado por esos dos
%   puntos y el vértice, por lo que nunca se aleja del camino original
%   hacia el lado contrario a la zona que se está rodeando. Aun así, se
%   valida cada arco contra la grilla de ocupación: si algún punto cae en
%   una celda bloqueada, esa esquina en particular se deja sin suavizar.
%   Entradas:
%       pathXY         - Nx2 puntos [x y] del camino (p.ej. de SimplifyPath)
%       GX, GY, occ    - grilla de ocupación usada para validar los arcos
%       cutFraction    - fracción (0-0.5) del segmento más corto adyacente
%                        que se recorta en cada esquina (típico 0.2-0.4)
%       samplesPerCorner - cantidad de puntos con que se muestrea cada arco
%   Salida:
%       smoothPath - Mx2 puntos [x y] con las esquinas redondeadas

    n = size(pathXY, 1);
    if n <= 2
        smoothPath = pathXY;
        return;
    end

    gxVec = GX(1, :);
    gyVec = GY(:, 1);

    smoothPath = pathXY(1, :);
    for i = 2:n-1
        p0 = pathXY(i-1, :);
        p1 = pathXY(i, :);   % vértice de la esquina
        p2 = pathXY(i+1, :);

        d1 = norm(p1 - p0);
        d2 = norm(p2 - p1);
        cut = cutFraction * min(d1, d2);

        A = p1 + (p0 - p1) * (cut / max(d1, eps)); % corte en el segmento entrante
        B = p1 + (p2 - p1) * (cut / max(d2, eps)); % corte en el segmento saliente

        tt = linspace(0, 1, samplesPerCorner)';
        arc = (1-tt).^2 .* A + 2*(1-tt).*tt .* p1 + tt.^2 .* B; % Bézier cuadrática

        arcFree = true;
        for k = 1:size(arc, 1)
            [~, c] = min(abs(gxVec - arc(k,1)));
            [~, r] = min(abs(gyVec - arc(k,2)));
            if occ(r, c)
                arcFree = false;
                break;
            end
        end

        if arcFree
            smoothPath = [smoothPath; arc]; %#ok<AGROW>
        else
            smoothPath(end+1, :) = p1; %#ok<AGROW>
        end
    end
    smoothPath(end+1, :) = pathXY(end, :);
end
