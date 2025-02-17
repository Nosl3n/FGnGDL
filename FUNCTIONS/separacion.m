function distancias = separacion(ang)
    % Verificar que el vector ang no esté vacío
    if isempty(ang)
        error('El vector de ángulos no puede estar vacío.');
    end
    % Verificar que el vector ang tenga al menos dos elementos
    if length(ang) < 2
        error('El vector de ángulos debe contener al menos dos elementos.');
    end
    %% 
    % Agregar el primer ángulo más 360 al final del vector
    ang = [ang, 360 + ang(1)];
    % Prealocar el vector de distancias
    distancias = zeros(1, length(ang) - 1);
    % Calcular las distancias angulares entre personas, comenzando de la primera
    for i = 1:length(ang) - 1
        distancias(i) = ang(i+1) - ang(i);
    end
end
% Función que devuelve un vector con las distancias angulares entre dos personas
% La distancia está en grados (°) y es con respecto al centro del grupo.