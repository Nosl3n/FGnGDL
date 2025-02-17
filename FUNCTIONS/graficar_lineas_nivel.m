function graficar_lineas_nivel(xrot,yrot,zrot,xcm,ycm)
%% Mensajes de depuracion "errores"
    % Verificar que las matrices xrot, yrot, y zrot tienen el mismo tamaño
    if ~isequal(size(xrot), size(yrot), size(zrot))
        error('Las matrices xrot, yrot, y zrot deben tener el mismo tamaño.');
    end
    % Verificar que xcm y ycm son valores numéricos
    if ~isnumeric(xcm) || ~isnumeric(ycm)
        error('Los valores de xcm y ycm deben ser numéricos.');
    end
%% CODIGO
    % Dibujar contornos de nivel
    contour(xrot, yrot, zrot, [0.96, 0.96], 'LineColor', [1 0 0]);
    hold on;
    contour(xrot, yrot, zrot, [0.9, 0.9], 'LineColor', [1 0.5 0]);
    hold on;
    contour(xrot, yrot, zrot, [0.8, 0.8], 'LineColor', [0 1 0]);
    %hold on;
    contour(xrot, yrot, zrot, [0.7, 0.7], 'LineColor', [0 0 1]);
    %hold on;
    contour(xrot, yrot, zrot, [0.58, 0.58], 'LineColor', [0 0 0.5]);
    hold on;
    % Marcar el centro de masa en azul con tamaños decrecientes
    plot(xcm, ycm, 'bo', 'MarkerSize', 15);
    hold on;
    plot(xcm, ycm, 'bo', 'MarkerSize', 10);
    hold on;
    plot(xcm, ycm, 'bo', 'MarkerSize', 5);
end
% La función graficar_lineas_nivel dibuja contornos de nivel en una gráfica 
% para una malla 3D rotada definida por xrot, yrot, y zrot. Los contornos 
% se dibujan en tres niveles diferentes con colores específicos. Además, 
% la función marca el centro de masa (xcm, ycm) con un marcador azul de 
% tamaño decreciente para enfatizar el punto central.