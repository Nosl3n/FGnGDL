function [xrot, yrot, zrot] = Individual_Group_Model(x, y)
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
        return;
    end

    addpath(fullfile(fileparts(mfilename('fullpath')), 'FUNCTIONS'));

    % Malla de evaluación
    lado = 5;
    paso = 0.1;
    xpos = abs(max(x)) + lado;
    xneg = -abs(min(x)) - lado;
    ypos = abs(max(y)) + lado;
    yneg = -abs(min(y)) - lado;
    [xx, yy] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));

    % Gaussiana circular por persona y suma total (sigma constante)
    sigma = 0.75;

    zz = zeros(size(xx));
    for i = 1:numel(x)
        zz = zz + exp(-((xx - x(i)).^2 + (yy - y(i)).^2) / (2 * sigma^2));
    end

    xrot = xx;
    yrot = yy;
    zrot = zz;
end