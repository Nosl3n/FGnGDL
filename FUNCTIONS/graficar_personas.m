function graficar_personas(x, y)
%% Mensajes de depuracion "errores"
   % Verificar que los vectores x e y tienen el mismo tamaño
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
%% CODIGO
    % Detalles estéticos de los círculos
    r = 0.4;
    edgeColor = [0.1, 0.4, 0.2];  % Color de borde personalizado
    lineWidth = 2;                % Grosor de línea personalizado
    faceColor = 'none';           % Sin relleno (transparente)

    % Graficar círculos para representar a cada persona
    for i = 1:length(x)
        rectangle('Position', [x(i) - r, y(i) - r, 2 * r, 2 * r], ...
                  'Curvature', [1, 1], ...
                  'EdgeColor', edgeColor, ...
                  'LineWidth', lineWidth, ...
                  'FaceColor', faceColor);
    end
end
% La función graficar_personas dibuja círculos en una gráfica para 
% representar a cada persona en las coordenadas especificadas por los 
% vectores x e y. Cada círculo tiene un radio fijo, un borde de color y 
% grosor personalizados, y un interior transparente.