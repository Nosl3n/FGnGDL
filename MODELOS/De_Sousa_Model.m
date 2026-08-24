function [xrot, yrot, zrot] = De_Sousa_Model(x, y)
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
        return;
    end

    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'FUNCTIONS'));

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
    variance_rear = md+0.1;     % Varianza atrás
    %% Llamada a la función
    [xrot, yrot, zrot] = Assimetric_Gaussian(x, y, xcm, ycm, rotation, variance_front, variance_right, variance_left, variance_rear);
end
