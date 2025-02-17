function personas3d(posicion_x, posicion_y)  
%% Mensajes de depuracion "errores" e inicialización de variables
    % Verificar que posicion_x y posicion_y son valores numéricos
    if ~isnumeric(posicion_x) || ~isnumeric(posicion_y)
        error('Las posiciones x e y deben ser numéricas.');
    end    
    % Definir las dimensiones de la persona
    altura_maxima = 0.8; % Altura máxima en el eje z
    radio_cuerpo = 0.2; % Radio del cuerpo
    radio_cabeza = 0.25; % Radio de la cabeza    
    % Número de puntos para dibujar el cilindro
    num_puntos = 50;    
    % Verificar que num_puntos es mayor que 1
    if num_puntos <= 1
        error('El número de puntos debe ser mayor que 1.');
    end
%% CODIGO
    % Calcular los ángulos para los puntos del cilindro
    theta = linspace(0, 2*pi, num_puntos);
    z = linspace(0, altura_maxima, num_puntos);
    % Coordenadas x e y del cilindro
    x_cilindro = radio_cuerpo * cos(theta);
    y_cilindro = radio_cuerpo * sin(theta);    
    % Coordenadas para las caras laterales del cilindro
    [Theta, Z] = meshgrid(theta, z);
    X = radio_cuerpo * cos(Theta) + posicion_x;
    Y = radio_cuerpo * sin(Theta) + posicion_y;    
    % Coordenadas para la esfera de la cabeza
    [X_cabeza, Y_cabeza, Z_cabeza] = sphere(num_puntos);
    X_cabeza = X_cabeza * radio_cabeza + posicion_x;
    Y_cabeza = Y_cabeza * radio_cabeza + posicion_y;
    Z_cabeza = Z_cabeza * radio_cabeza + altura_maxima;    
    % Dibujar el cilindro y la cabeza
    hold on;
    surf(X, Y, Z, 'FaceColor', 'blue', 'EdgeColor', 'none');
    surf(X_cabeza, Y_cabeza, Z_cabeza, 'FaceColor', 'red', 'EdgeColor', 'none');
    axis equal;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    grid on;
    view(3);
    hold off;
end
% La función personas3d dibuja una representación en 3D de una persona en 
% las coordenadas especificadas por posicion_x y posicion_y. La representación 
% consiste en un cilindro azul para el cuerpo y una esfera roja para la cabeza. 
% La altura del cuerpo y los radios del cuerpo y la cabeza son personalizables.