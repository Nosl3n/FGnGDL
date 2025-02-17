function ang = orientacion_vec(x,y,cmx,cmy,graf) %graf = 1 (dirección) | 0 (sin dirección)
    % Se determina el desplazamiento necesario para mover el centro de masa al origen
    xmove = -cmx;
    ymove = -cmy;
    % se mueve todo al origen.
    x=x + xmove;
    y=y + ymove;
    if length(x) == 2
       %Cuando hay dos inidividuos, la direccion es el primer individuo.
        resultan = [x(1), y(1)];
    else 
        % Ordenar los puntos alrededor del origen
        [x_ord, y_ord] = ordenar_puntos(0, 0, x, y);
        % Se halla la dirección resultante sumando los vectores

        for i = 1:length(x)-1
            if i==1
                % Inicializar resultan con los primeros dos puntos ordenados
                resultan = result([x_ord(i) x_ord(i+1)],[y_ord(i) y_ord(i+1)]);
            else
                % Sumar el siguiente punto ordenado al vector resultante
                resultan = result([resultan(1) x_ord(i+1)],[resultan(2) y_ord(i+1)]);
            end
        end
    end
    %Caso en el que la resultante sea cero
    if resultan(1) == 0 && resultan(2)== 0
        resultan = [x_ord(1), y_ord(1)];
    end
    %Determinar el angulo
    an = atan2(resultan(2) - 0, resultan(1) - 0); 
    ang = mod(rad2deg(an), 360);
    % Graficar si se solicita
    if graf == 1
        x_dir = resultan(1) - xmove;
        y_dir = resultan(2) - ymove;
        plot([cmx x_dir], [cmy y_dir], 'g', 'LineWidth', 2);
        hold on;
    end
end
% La función orientacion_vec calcula la dirección angular de un grupo de 
% puntos (x, y) respecto a un centro de masa (cmx, cmy) y opcionalmente 
% grafica esta dirección. Primero, mueve todos los puntos al origen, 
% luego calcula la dirección resultante del grupo. Si hay dos puntos, 
% utiliza la dirección del primer punto. Si hay más, ordena los puntos por 
% ángulo y suma sus vectores. Finalmente, convierte la dirección resultante 
% a un ángulo en grados y la grafica si se solicita.