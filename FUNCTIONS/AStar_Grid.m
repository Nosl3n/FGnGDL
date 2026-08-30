function pathRC = AStar_Grid(occ, startRC, goalRC)
%ASTAR_GRID Búsqueda de camino A* sobre una grilla 2D con 8-conectividad.
%   pathRC = AStar_Grid(occ, startRC, goalRC)
%   Entradas:
%       occ     - matriz lógica [ny x nx]; true = celda bloqueada
%       startRC - [fila, columna] de la celda de inicio
%       goalRC  - [fila, columna] de la celda de meta
%   Salida:
%       pathRC  - Nx2 con las celdas [fila, columna] del camino, desde
%                 inicio hasta meta (ambos incluidos). Vacío si no hay
%                 camino posible.

    [ny, nx] = size(occ);

    if occ(startRC(1), startRC(2))
        error('La celda de inicio está dentro de una zona bloqueada.');
    end
    if occ(goalRC(1), goalRC(2))
        error('La celda de meta está dentro de una zona bloqueada.');
    end

    numNodes = ny * nx;
    startLin = sub2ind([ny, nx], startRC(1), startRC(2));
    goalLin  = sub2ind([ny, nx], goalRC(1), goalRC(2));

    gScore = inf(numNodes, 1);
    fScore = inf(numNodes, 1);
    cameFrom = zeros(numNodes, 1);
    closed = false(numNodes, 1);
    inOpen = false(numNodes, 1);

    gScore(startLin) = 0;
    fScore(startLin) = heuristic(startRC, goalRC);

    openSet = startLin;
    inOpen(startLin) = true;

    % Desplazamientos a los 8 vecinos y su costo de movimiento
    offsets = [-1 0; 1 0; 0 -1; 0 1; -1 -1; -1 1; 1 -1; 1 1];
    costs = [1 1 1 1 sqrt(2) sqrt(2) sqrt(2) sqrt(2)];

    while ~isempty(openSet)
        [~, pick] = min(fScore(openSet));
        current = openSet(pick);

        if current == goalLin
            pathRC = reconstructPath(cameFrom, current, ny, nx);
            return;
        end

        openSet(pick) = [];
        inOpen(current) = false;
        closed(current) = true;

        [r, c] = ind2sub([ny, nx], current);

        for k = 1:8
            nr = r + offsets(k, 1);
            nc = c + offsets(k, 2);
            if nr < 1 || nr > ny || nc < 1 || nc > nx
                continue;
            end
            if occ(nr, nc)
                continue;
            end
            % Evitar "cortar esquina" entre dos celdas bloqueadas diagonales
            if offsets(k, 1) ~= 0 && offsets(k, 2) ~= 0
                if occ(r, nc) || occ(nr, c)
                    continue;
                end
            end

            nb = sub2ind([ny, nx], nr, nc);
            if closed(nb)
                continue;
            end

            tentativeG = gScore(current) + costs(k);
            if tentativeG < gScore(nb)
                cameFrom(nb) = current;
                gScore(nb) = tentativeG;
                fScore(nb) = tentativeG + heuristic([nr, nc], goalRC);
                if ~inOpen(nb)
                    openSet(end+1) = nb; %#ok<AGROW>
                    inOpen(nb) = true;
                end
            end
        end
    end

    pathRC = []; % no se encontró camino
end

function h = heuristic(a, b)
    h = hypot(a(1) - b(1), a(2) - b(2));
end

function pathRC = reconstructPath(cameFrom, current, ny, nx)
    lin = current;
    while cameFrom(current) ~= 0
        current = cameFrom(current);
        lin(end+1) = current; %#ok<AGROW>
    end
    lin = flip(lin(:));
    [r, c] = ind2sub([ny, nx], lin);
    pathRC = [r, c];
end
