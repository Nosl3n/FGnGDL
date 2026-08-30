function simplified = SimplifyPath(pathXY, GX, GY, occ)
%SIMPLIFYPATH Reduce un camino de waypoints mediante "string pulling".
%   simplified = SimplifyPath(pathXY, GX, GY, occ)
%   Elimina puntos intermedios del camino cuando existe línea de vista
%   libre de zonas bloqueadas entre dos puntos no consecutivos, dejando
%   un camino con menos segmentos y más directo.
%   Entradas:
%       pathXY - Nx2 puntos [x y] del camino original (p.ej. de A*)
%       GX, GY - mallas de la grilla de ocupación (meshgrid)
%       occ    - matriz lógica de ocupación asociada a GX, GY
%   Salida:
%       simplified - Mx2 puntos [x y] simplificados (M <= N)

    n = size(pathXY, 1);
    if n <= 2
        simplified = pathXY;
        return;
    end

    cellSize = GX(1, 2) - GX(1, 1);
    gxVec = GX(1, :);
    gyVec = GY(:, 1);

    simplified = pathXY(1, :);
    i = 1;
    while i < n
        j = n;
        while j > i + 1 && ~lineOfSightFree(pathXY(i, :), pathXY(j, :), gxVec, gyVec, occ, cellSize)
            j = j - 1;
        end
        simplified(end+1, :) = pathXY(j, :); %#ok<AGROW>
        i = j;
    end
end

function free = lineOfSightFree(p1, p2, gxVec, gyVec, occ, cellSize)
    dist = hypot(p2(1) - p1(1), p2(2) - p1(2));
    nSamples = max(2, ceil(dist / (cellSize * 0.5)));
    tvals = linspace(0, 1, nSamples);
    xs = p1(1) + tvals * (p2(1) - p1(1));
    ys = p1(2) + tvals * (p2(2) - p1(2));

    free = true;
    for k = 1:numel(xs)
        [~, c] = min(abs(gxVec - xs(k)));
        [~, r] = min(abs(gyVec - ys(k)));
        if occ(r, c)
            free = false;
            return;
        end
    end
end
