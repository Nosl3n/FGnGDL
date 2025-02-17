function [distancias, angulos_grados] = dis_ang(x, y, xc, yc)
%% Mensajes de depuracion "errores"
    % Verificar que xc e yc son escalares
    if ~isscalar(xc) || ~isscalar(yc)
        error('xc e yc deben ser valores escalares.');
    end
    % Verificar que los vectores x e y tienen el mismo tamaño
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
%% CODIGO
    % Calcular las distancias euclidianas entre cada punto (x, y) y el punto central (xc, yc)
    distancias = sqrt((x - xc).^2 + (y - yc).^2);
    % Calcular los ángulos en radianes entre cada punto (x, y) y el punto central (xc, yc)
    angulos = atan2(y - yc, x - xc);
    % Convertir los ángulos de radianes a grados y ajustarlos para que estén en el rango [0, 360)
    angulos_grados = mod(rad2deg(angulos), 360);
end
% La función dis_ang calcula las distancias euclidianas y los ángulos en 
% grados de cada punto (x, y) respecto a un punto central (xc, yc). 
% Primero verifica que los puntos centrales sean escalares y que los 
% vectores x e y tengan el mismo tamaño. Luego, calcula las distancias 
% entre cada punto y el punto central, así como los ángulos en grados, 
% ajustándolos para que estén en el rango [0, 360) grados. La función 
% devuelve las distancias y los ángulos en grados.