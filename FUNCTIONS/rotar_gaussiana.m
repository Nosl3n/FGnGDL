function [xrot,yrot,zrot] = rotar_gaussiana (x,y,z,angulo,cmx,cmy)
%% Mensajes de depuracion "errores"
    % Verificar que las matrices de entrada tienen el mismo tamaño
    if ~isequal(size(x), size(y), size(z))
        error('Las matrices x, y, z deben tener el mismo tamaño.');
    end

    % Verificar que el ángulo es un valor numérico
    if ~isnumeric(angulo)
        error('El ángulo debe ser un valor numérico.');
    end

    % Verificar que cmx y cmy son valores numéricos
    if ~isnumeric(cmx) || ~isnumeric(cmy)
        error('Los valores de cmx y cmy deben ser numéricos.');
    end
%% Codigo
    % Determinamos la traslación en los ejes
    xmove = -cmx;
    ymove = -cmy;
    % Ángulo de rotación en radianes
    angulo = deg2rad(angulo);
    % Crear la matriz de transformación homogénea para la rotación alrededor del eje Z
    matriz_rotacion = [cos(angulo), -sin(angulo), 0;
                       sin(angulo),  cos(angulo), 0;
                       0,            0,           1];

    % Convertir las matrices x, y, z en vectores
    xx = x(:);
    yy = y(:);
    zz = z(:);

    % Trasladar la gaussiana al origen de coordenadas
    xx = xx + xmove;
    yy = yy + ymove;

    % Combinar los vectores en una matriz de puntos
    puntos = [xx, yy, zz];

    % Aplicar la matriz de transformación homogénea (Rotación en Z) a los puntos en 3D
    puntos_rot = puntos * matriz_rotacion;

    % Separar los puntos rotados en vectores x, y, z
    Xrot = puntos_rot(:, 1);
    Yrot = puntos_rot(:, 2);
    Zrot = puntos_rot(:, 3);

    % Regresar la gaussiana a su posición original
    Xrot = Xrot - xmove;
    Yrot = Yrot - ymove;

    % Reshape para obtener matrices 2D
    xrot = reshape(Xrot, size(x));
    yrot = reshape(Yrot, size(y));
    zrot = reshape(Zrot, size(z));
end
% La función rotar_gaussiana rota una malla gaussiana (x, y, z) alrededor 
% de un punto central (cmx, cmy) por un ángulo especificado en grados. 
% Primero, traslada la malla al origen, aplica la rotación y luego la 
% devuelve a su posición original. Finalmente, devuelve las matrices 
% rotadas xrot, yrot, y zrot.