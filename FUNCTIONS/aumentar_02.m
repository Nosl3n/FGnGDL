function [x_aaum, y_aaum] = aumentar_02(maximo, x_ord, y_ord, xcm, ycm)
%% Mensaje de error  
    % Verificar que x_ord y y_ord tienen el mismo tamaño
    if length(x_ord) ~= length(y_ord)
        error('Los vectores x_ord e y_ord deben tener el mismo tamaño.');
    end
%% CODIGO    
    % Calcular las distancias y ángulos respecto al centro de masa
    [dis1, ang1] = dis_ang(x_ord, y_ord, xcm, ycm);
    nuevas_distancias = separacion(ang1);
    % Inicializar vector de cambios
    cambios = [];
    j = 1;
    % Determinar las distancias que exceden el máximo permitido
    for i = 1:length(nuevas_distancias)
        if nuevas_distancias(i) > maximo
            cambios(j) = i;
            j = j + 1;
        end
    end
    % Inicializar los nuevos puntos
    x_mas = [];
    y_mas = [];
    j = 1;
    % Añadir nuevos puntos en las posiciones que exceden la distancia máxima
    if length(cambios) ~= 0
        for i = 1:length(cambios)
            if cambios(i) == length(nuevas_distancias)
                angulo = ang1(cambios(i)) + (nuevas_distancias(cambios(i)) / 2);
                Lnew = dis1(cambios(i)) / 4 + dis1(1) / 4;
            else
                angulo = ang1(cambios(i)) + (nuevas_distancias(cambios(i)) / 2);
                Lnew = dis1(cambios(i)) / 4 + dis1(cambios(i) + 1) / 4;
            end
            xnew = cos(deg2rad(angulo)) * Lnew + xcm;
            ynew = sin(deg2rad(angulo)) * Lnew + ycm;
            x_mas(j) = xnew;
            y_mas(j) = ynew;
            j = j + 1;
        end
        % Combinar los puntos originales con los nuevos puntos
        x_aum = [x_ord, x_mas];
        y_aum = [y_ord, y_mas];
        % Ordenar los puntos combinados
        [x_aaum, y_aaum] = ordenar_puntos(xcm, ycm, x_aum, y_aum);
   else
        x_aaum = x_ord;
        y_aaum = y_ord;
   end
end
% La función aumentar_02 ajusta la distribución de puntos (x_ord, y_ord) 
% respecto a un centro de masa (xcm, ycm) añadiendo nuevos puntos si las 
% distancias angulares entre puntos consecutivos superan un valor máximo 
% (maximo). Primero, calcula las distancias y ángulos actuales, determina 
% las distancias angulares entre puntos, y luego añade nuevos puntos para 
% acortar cualquier distancia que exceda el máximo especificado. Finalmente, 
% devuelve los puntos ajustados y ordenados.