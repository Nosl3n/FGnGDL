function [xrot, yrot, zrot, h] = Modelo(x, y, theta, m, op)
%MODELO Selecciona el modelo proxémico que se va a calcular.
%   [XROT, YROT, ZROT] = MODELO(X, Y, M) calcula la malla del modelo
%   indicado por M:
%       1 - Paco_Model
%       2 - De_Sousa_Model
%       3 - Individual_Group_Model
%       4 - Aracelly_model

    if nargin ~= 5
        error('Modelo requiere cinco entradas: x, y, theta, m y op.');
    end

    if ~isnumeric(m) || ~isscalar(m) || ~isfinite(m) || m ~= fix(m)
        error('m debe ser un número entero: 1, 2, 3 o 4.');
    end

    if ~isnumeric(op) || ~isscalar(op) || ~isfinite(op)
        error('op debe ser un número finito.');
    end

    switch m
        case 1
            [xrot, yrot, zrot, h] = Paco_Model(x, y, theta, op);
        case 2
            [xrot, yrot, zrot, h] = De_Sousa_Model(x, y, theta, op);
        case 3
            [xrot, yrot, zrot, h] = Individual_Group_Model(x, y, theta, op);
        case 4
            [xrot, yrot, zrot, h] = Aracelly_model_theta(x, y, theta, op);
        case 5
            [xrot, yrot, zrot, h] = De_Sousa_Model_paper(x, y, theta, op);
        otherwise
            error('Modelo no válido. Use 1 (Paco_Model), 2 (De_Sousa_Model), 3 (Individual_Group_Model) o 4 (Aracelly_model).');
    end
end
