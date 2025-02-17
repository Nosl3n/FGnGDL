function [x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y)
%% Mensajes de error durante la depuración
    % Verificar que xc e yc son escalares
    if ~isscalar(xcm) || ~isscalar(ycm)
        error('xc e yc deben ser valores escalares.');
    end
    % Comprobar que los vectores x e y tienen el mismo tamaño
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
%% CODIGO
    % Calcular los ángulos en radianes entre cada punto (x, y) y el punto central (xcm, ycm)
    ang_ordenar = rad2deg(atan2(y - ycm, x - xcm));
    % Ajustar los ángulos para que estén en el rango [0, 360)
    angulos_ajustados = mod(ang_ordenar, 360);
    % Ordenar los ángulos ajustados y obtener los índices de ordenamiento
    [~, indice_orden] = sort(angulos_ajustados);
    % Utilizar los índices de ordenamiento para reordenar los vectores x e y
    x_ord = x(indice_orden);
    y_ord = y(indice_orden);
end

% La función ordenar_puntos organiza los puntos (x, y) en función de sus 
% ángulos respecto a un punto central (xcm, ycm). Primero verifica que los 
% puntos centrales sean escalares y que los vectores x e y tengan el mismo 
% tamaño. Luego, calcula los ángulos de cada punto con respecto al punto 
% central, ajusta estos ángulos para que estén en el rango [0, 360) grados, 
% y finalmente ordena los puntos de acuerdo a estos ángulos. La función 
% devuelve los vectores x e y ordenados (x_ord y y_ord).