function [xrot, yrot, zrot] = Modelo(x, y, m)
%MODELO Selecciona el modelo proxémico que se va a calcular.
%   [XROT, YROT, ZROT] = MODELO(X, Y, M) calcula la malla del modelo
%   indicado por M:
%       1 - Paco_Model
%       2 - De_Sousa_Model
%       3 - Individual_Group_Model

    % Dejar disponibles los modelos y sus utilidades sin depender de la
    % carpeta de trabajo desde la que se ejecute el script.
    persistent rutasConfiguradas
    if isempty(rutasConfiguradas)
        raizProyecto = fileparts(mfilename('fullpath'));
        addpath(fullfile(raizProyecto, 'MODELOS'));
        addpath(fullfile(raizProyecto, 'FUNCTIONS'));
        rutasConfiguradas = true;
    end

    if nargin ~= 3
        error('Modelo requiere tres entradas: x, y y m.');
    end

    if ~isnumeric(m) || ~isscalar(m) || ~isfinite(m) || m ~= fix(m)
        error('m debe ser un número entero: 1, 2 o 3.');
    end

    switch m
        case 1
            [xrot, yrot, zrot] = Paco_Model(x, y);
        case 2
            [xrot, yrot, zrot] = De_Sousa_Model(x, y);
        case 3
            [xrot, yrot, zrot] = Individual_Group_Model(x, y);
        otherwise
            error('Modelo no válido. Use 1 (Paco_Model), 2 (De_Sousa_Model) o 3 (Individual_Group_Model).');
    end
end
