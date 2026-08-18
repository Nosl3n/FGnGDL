function [nuevo_ang nuevo x_nuv y_nuv] = ordenamiento(ang, referencia, x, y)    
    % Verificar que los vectores de entrada tienen el mismo tamaño
    if length(ang) ~= length(x) || length(x) ~= length(y)
        error('Los vectores ang, x, y deben tener el mismo tamaño.');
    end
    
    % Encontrar el índice de la referencia
    indice = find(ang == referencia);
    if isempty(indice)
        error('La referencia no se encuentra en el vector de ángulos.');
    end
    
    % Reordenar los ángulos y las coordenadas según el índice de referencia
    nuevo_ang = [ang(indice:end), ang(1:indice-1)];
    x_nuv = [x(indice:end), x(1:indice-1)];
    y_nuv = [y(indice:end), y(1:indice-1)];
    
    % Inicializar el vector de ángulos ajustados
    nuevo = zeros(1, length(nuevo_ang));
    
    % Ajustar los ángulos considerando la referencia como cero grados
    for i = 1:length(nuevo_ang)
        nuevo(i) = mod(nuevo_ang(i) - nuevo_ang(1), 360);
    end
end
% La función ordenamiento reordena los ángulos y sus correspondientes 
% coordenadas (x, y) a partir de una referencia específica. Luego ajusta 
% los ángulos reordenados para que se consideren como si la referencia 
% fuera cero grados.