function Area = GANGL_V05(x,y,graf,VISTA,per)
    % Añadir rutas para funciones adicionales
    addpath("FUNCTIONS");
%% Mensajes de depuracion "errores"
    % Verificar que los vectores x e y tienen el mismo tamaño
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    % Verificar que GRAF y per son números y que solo pueden ser 0 o 1
    if ~isnumeric(VISTA) || ~ismember(VISTA, [2, 3])
        error('VISTA debe ser un valor numérico, 2 o 3.');
    end
    if ~isnumeric(graf) || ~ismember(graf, [0, 1])
        error('graf debe ser un valor numérico, 2 o 3.');
    end
    if ~isnumeric(per) || ~ismember(per, [0, 1])
        error('per debe ser un valor numérico, 0 o 1.');
        
    end
    %% Determinacion del centro del grupo:
    xcm = (max(x) + min(x)) / 2; 
    ycm = (max(y) + min(y)) / 2;
    % if length (x) == 2 %Si son dos personas CM
    %     xcm = sum(x) / length(x)
    %     ycm = sum(y) / length(y)
    % else %Mas de 2 personas CH
    %     k = convhull(x, y);
    %     xcm = mean(x(k))
    %     ycm = mean(y(k))
    % end
    %% Ordenamiento de los puntos en sentido horario.
    [x_ord, y_ord] = ordenar_puntos(xcm,ycm,x,y);
    %% Determinacion de las distancias y sus angulos con respecto al eje x con respecto a cxm y cym
    [dis, ang] = dis_ang (x_ord,y_ord,xcm,ycm);
    %% DETERMINACION DE LA ORIENTACION
    ang_vec = orientacion_vec(x_ord,y_ord,xcm,ycm,graf);
    % Determinar el valor mas cercano a la orientacion
    %% SE APLICA EL FILTRO DE ELIMINAR PERSONAS xmod y ymod.
    for i=1:length(x)
        % Distancias del origen a cada persona, ademas sus angulos con respecto al eje x:
        [dis, ang] = dis_ang (x_ord,y_ord,xcm,ycm);
        % Se añade un valor al final para la determinacion de la distancia.
        [x_mod y_mod] = entre_personas(15, ang, dis, x_ord, y_ord);
        if length(x_mod) == length(x_ord)
            break;
        else
            x_ord = x_mod;
            y_ord = y_mod;
        end
    end
    %% SE APLICA EL FILTRO DE AUMENTAR PERSONAS xaum y yaum
    [x_aum y_aum] = aumentar_02 (70,x_mod,y_mod,xcm,ycm);
    %% Se halla la primera persona cercana a la orientacion
    orientacion = 1000;
    for i=1:length(ang)
        if ang_vec < ang(i)
            orientacion = ang(i); %Primer angulo, para rotar todo
            break;
        end
        %En el caso de que no hay angulos mayores a la direccion vectorial
        %escogera el primer angulo desde 0°
        if orientacion == 1000
            orientacion = ang(1);
        end
    end
    %% EL ANGULO QUE SE TIENE QUE ROTAR SERA "ORIENTACION"
    rotacion = -orientacion;
    %% Determinacion de las distancias y sus angulos con respecto al eje x con respecto a cxm y cym
    [dis, ang] = dis_ang (x_aum,y_aum,xcm,ycm);
    %% DETERMINANOS LA NUEVA DISTRIBUCION DE VECTORES
    [ang_new ang x_new y_new] = ordenamiento(ang, orientacion, x_aum, y_aum); %la nueva entrada sera: 
    %% Determinacion de las distancias y sus angulos con respecto al eje x, de cada punto al centro del grupo
    [dis, ang_sum] = dis_ang (x_new,y_new,xcm,ycm);
    %% Determinacion de las varianzas Madre
    min_sig = 0.5; % mínimo valor de las varianzas
    sigma_x = abs(dis) + min_sig;
    sigma_y = abs(dis) + min_sig;
    % Se añade el sigma inicial, al final de todos los sigmas.
    sigma_x(end + 1) = sigma_x(1);
    sigma_y(end + 1) = sigma_y(1);
    %% Se determinan las distancias para hallar los sigmas intermedios.
        for i=1:length(ang)
            if i==length(ang)
                distan(i)=360-ang(i)+ang(1);
            else
                distan(i)=ang(i+1)-ang(i);
            end
        end
    %se genera un valor de cero al comienzo del arreglo para manerar mejor los
    %indices:
    distancias = [0, distan];
    %% Determinar los sigma hijos, con un recorrido de 0 a 360°, con saltos de delta_ang
        delta_ang=1;
        j=2;
        k=1;
        cont=0;
        angulo=0;
        sigma_xx = zeros(1, 360);
        sigma_yy = zeros(1, 360);
        for i=1:360
            if i>distancias(j)+angulo
                angulo=distancias(j)+angulo;
                j=j+1;
                k=k+1;
                cont=0;
            end
            t1=distancias(j)-cont;
            t2=cont;
            cont=cont+delta_ang;
            sigma_xx(i) = ((t1/distancias(j))*sigma_x(k)) + ((t2/distancias(j))*sigma_x(k+1));
            sigma_yy(i) = ((t1/distancias(j))*sigma_y(k)) + ((t2/distancias(j))*sigma_y(k+1));
        end
    %% GENERACION DE LA MALLA PARA LA GAUSSIANA
        lado = 2.5; %maximo valor de cada lado de la grafica
        paso = 0.1; %Paso de la malla, entre punto a punto
        xpos = abs(max(x))+lado;
        xneg = abs(min(x))-lado;
        ypos = abs(max(y))+lado;
        yneg = abs(min(y))-lado;
        %Se genera la malla en la que se determianra cada punto de la gaussiana.
        [xx, yy] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));
    %% Creacion de las matrices de varianzas
        tam=size(yy);
        for i=1:1:tam(1)
            for j=1:1:tam(2)
                theta = atan2(yy(i,j) - ycm, xx(i,j) - xcm); 
                theta = mod(rad2deg (theta), 360);
                alpha = round( theta ); %redondeando se asigna un valor al angulo OJO
                if alpha >= 360
                    alpha = 360;
                elseif alpha <= 1
                    alpha = 1;
                end
                varianzax(i,j) = sigma_xx(alpha);
                varianzay(i,j) = sigma_yy(alpha);
            end
        end
    %% Se crea cada punto zz de la funcion gaussiana
        zz = exp(-(xx - xcm).^2 ./ (2 .* varianzax.^2) - (yy - ycm).^2 ./ (2 .* varianzay.^2));
    %% Se rota el desfase de la gaussiana
        [xrot,yrot,zrot] = rotar_gaussiana (xx,yy,zz,rotacion,xcm,ycm);     
    %% Se grafica el contorno
    if graf == 1
        if VISTA==3 && per == 1
            mesh(xrot, yrot,zrot);
            hold on;
            graficar_personas3d(x,y);
        elseif VISTA==3 && per == 0
            mesh(xrot, yrot,zrot);
        elseif VISTA == 2 && per == 1
            graficar_personas(x,y);
            hold on;
            graficar_lineas_nivel(xrot,yrot,zrot,xcm,ycm);
        else
            graficar_lineas_nivel(xrot,yrot,zrot,xcm,ycm);
        end
        grid on;
    end
%% Obtener el área bajo el contorno de nivel 0.3
    if graf ~= 1
        % Crear la figura pero hacer que no sea visible
        fig = figure('Visible', 'off');
    end
    hold on;
    [C, h] = contour(xrot, yrot, zrot, [0.58, 0.58],'LineColor', [0 0 0.5]);
    Area = 0;
    for k = 1:length(h.LevelList)
        contour_level = h.LevelList(k);
        if contour_level == 0.58
            for i = 1:length(h.ContourMatrix)
                x_contour = h.ContourMatrix(1, 2:end);
                y_contour = h.ContourMatrix(2, 2:end);
                % Calcular el área usando el método de integración numérica
                Area = polyarea(x_contour, y_contour);
            end
        end
    end
    hold off;
    if graf ~= 1
        close(fig);
    end
end
% La función GANGL_V05 procesa un conjunto de puntos (x, y) para determinar 
% su distribución, orientación y generar una malla gaussiana 3D. La función 
% incluye varias etapas: determinación del centro del grupo, ordenamiento 
% de puntos, cálculo de distancias y ángulos, eliminación y adición de puntos, 
% rotación y graficación de la malla gaussiana.