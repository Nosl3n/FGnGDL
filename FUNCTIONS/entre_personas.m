function [xmod ymod] = entre_personas(minima, ang, dis, x_ord, y_ord)
%% Errores que pueden suceder al compilar  
    % Verificar que los vectores de entrada tienen el mismo tamaño
    if length(ang) ~= length(dis) || length(dis) ~= length(x_ord) || length(x_ord) ~= length(y_ord)
        error('Todos los vectores de entrada deben tener el mismo tamaño.');
    end
%% CODIGO
    % Determinar las distancias angulares entre personas
    distancias = separacion(ang);
    eliminar = 0;
    % Encontrar la persona a eliminar basada en la distancia mínima
    for i = 1:length(distancias)
        if distancias(i) <= minima % Filtro de distancia
            if i == length(x_ord) % caso en el que se trabaja con la ultima persona.
                if dis(i) < dis(1)
                    eliminar = i;
                else
                    eliminar = 1;
                end
            else %los demas casos
                if dis(i) < dis(i+1)
                    eliminar = i;
                else
                    eliminar = i+1;
                end
            end
        end
    end
    % Modificar los vectores x e y, eliminando la persona seleccionada
    if eliminar == 0
        % Si no se elimina ninguna persona, devolver los vectores originales
        xmod = x_ord;
        ymod = y_ord;
    else
        % Inicializar vectores modificados
        xmod = zeros(1, length(x_ord) - 1);
        ymod = zeros(1, length(y_ord) - 1);
        j = 1;
        for i = 1:length(x_ord) %Se forma el nuevo conjunto de puntos sin una persona
            if i ~= eliminar
                xmod(j) = x_ord(i);
                ymod(j) = y_ord(i);
                j = j + 1;
            end
        end
    end
end
% La función entre_personas toma como entrada una distancia angular mínima (minima), 
% un vector de ángulos (ang), un vector de distancias (dis), y dos vectores 
% de coordenadas (x_ord y y_ord). La función calcula las distancias angulares 
% entre puntos y elimina el punto que tiene la distancia más pequeña a otro 
% punto en el grupo, siempre que esa distancia sea menor o igual a la distancia 
% mínima especificada. Devuelve los vectores de coordenadas modificados 
% (xmod y ymod), con el punto eliminado si se cumple la condición.