function resultante = result(x, y)
%% Posibles errores al depurar
    % Verificar que x e y tienen dos elementos
    if length(x) ~= 2 && length(y) ~= 2
        error('Los vectores x e y deben tener dos elementos.');
    end
%% CODIGO
    % Crear los vectores
    v1 = [x(1) y(1)];
    v2 = [x(2) y(2)];
    % Calcular la resultante sumando los vectores
    resultante = v1 + v2;
end
% La función result calcula la suma vectorial (resultante) de dos vectores 2D, 
% cada uno representado por dos componentes en los vectores x e y. Primero 
% verifica que los vectores de entrada x e y contengan exactamente dos elementos. 
% Luego, construye los vectores a partir de estos elementos y calcula la resultante 
% sumando los dos vectores.