function graficar_personas3d(posicion_x, posicion_y)    % Verificar que los vectores posicion_x y posicion_y tienen el mismo tamaño
%% Mensajes de depuracion "errores"
    if length(posicion_x) ~= length(posicion_y)
        error('Los vectores posicion_x y posicion_y deben tener el mismo tamaño.');
    end
%% CODIGO
    % Dibujar personas en 3D en las posiciones especificadas
    for i = 1:length(posicion_x)
        personas3d(posicion_x(i), posicion_y(i));
        hold on;
    end
end
% La función graficar_personas3d dibuja representaciones 3D de múltiples 
% personas en las coordenadas especificadas por los vectores posicion_x y 
% posicion_y. Para cada posición, llama a la función personas3d que dibuja 
% una persona en esa ubicación.