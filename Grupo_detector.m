
function MCo = Grupo_detector(x, y)
%   Grupo_detector Detecta grupos por proximidad y devuelve coordenadas por grupo.
%   La entrada es un vector de coordendas x=[x1,x2,x3...xn], lo mismo para
%   y.
%   MCo = Grupo_detector(x,y) devuelve una matriz donde cada fila corresponde
%   a un grupo y contiene las coordenadas intercaladas [x1 y1 x2 y2 ...]
%   rellenadas con NaN cuando los grupos tienen distinto tamaño.
%
%   Entradas:
%     x, y : vectores con las coordenadas de los puntos (misma longitud)
%
%   Salida:
%     MCo : nGroups x (2*maxGroupSize) matriz con padding NaN

    if numel(x) ~= numel(y)
        error('Los vectores x e y deben tener la misma longitud.');
    end

    r_small = 0.5;
    r_large = r_small + 0.45;

    % PASO 01: centro geométrico y orden angular
    XC = (max(x) + min(x)) / 2;
    YC = (max(y) + min(y)) / 2;

    dx = x - XC;
    dy = y - YC;
    angles = atan2(dy, dx);
    angles(angles < 0) = angles(angles < 0) + 2*pi;
    [angles_sorted, idx] = sort(angles);

    xord = x(idx);
    yord = y(idx);

    % PASO 03: matriz de distancias
    n = numel(xord);
    X1 = repmat(xord(:), 1, n);
    X2 = X1.';
    Y1 = repmat(yord(:), 1, n);
    Y2 = Y1.';
    MD = sqrt( (X1 - X2).^2 + (Y1 - Y2).^2 );

    % PASO 04: matriz binaria MG (umbral)
    umbral = 2 * r_large;
    MG = double(MD <= umbral);
    MG(1:n+1:end) = 0; % diagonal a cero

    % PASO 05: pares (no usado directamente más adelante, pero se conserva)
    [idx_i, idx_j] = find(MG == 1);
    pares = [idx_i, idx_j];

    % PASO 06: construir grupos como matriz (cada fila = índices, NaN padding)
    nNodes = n;
    if isempty(pares)
        gruposMat = zeros(0,0);
    else
        adj = MG > 0;
        visited = false(nNodes,1);
        groupsList = {};
        for seed = 1:nNodes
            if visited(seed)
                continue;
            end
            if ~any(adj(seed,:)) && ~any(adj(:,seed))
                visited(seed) = true;
                continue;
            end
            queue = seed;
            comp = false(nNodes,1);
            comp(seed) = true;
            visited(seed) = true;
            while ~isempty(queue)
                v = queue(1); queue(1) = [];
                nbrs = find(adj(v,:) | adj(:,v)');
                for nb = nbrs
                    if ~comp(nb)
                        comp(nb) = true;
                        visited(nb) = true;
                        queue(end+1) = nb; %#ok<SAGROW>
                    end
                end
            end
            members = find(comp);
            if numel(members) >= 2
                groupsList{end+1} = members; %#ok<SAGROW>
            end
        end
        if isempty(groupsList)
            gruposMat = zeros(0,0);
        else
            maxLen = max(cellfun(@numel, groupsList));
            nGroups = numel(groupsList);
            gruposMat = NaN(nGroups, maxLen);
            for g = 1:nGroups
                idxs = groupsList{g}(:).';
                gruposMat(g,1:numel(idxs)) = idxs;
            end
        end
    end

    % PASO 07: convertir gruposMat a MCo (cada fila = [x1 y1 x2 y2 ...], NaN)
    if isempty(gruposMat) || all(size(gruposMat)==[0 0])
        MCo = NaN(0,0);
    else
        [nGroups, maxLen] = size(gruposMat);
        MCo = NaN(nGroups, 2*maxLen);
        for g = 1:nGroups
            idxs = gruposMat(g, :);
            valid = ~isnan(idxs);
            if any(valid)
                idxv = idxs(valid);
                if any(idxv<1) || any(idxv>numel(xord)) || any(idxv~=floor(idxv))
                    error('PASO 07: índices inválidos en gruposMat fila %d: %s', g, mat2str(idxv));
                end
                xs = xord(idxv);
                ys = yord(idxv);
                row = NaN(1, 2*maxLen);
                row(1:2*numel(xs)) = reshape([xs(:) ys(:)].', 1, []);
                MCo(g, :) = row;
            else
                MCo(g, :) = NaN(1, 2*maxLen);
            end
        end
    end
end