function ang = orientacion_vec(x,y,cmx,cmy,graf) %graf = 1 (dirección) | 0 (sin dirección)
    % Dirección resultante: suma de los vectores (x_i,y_i) centrados en
    % (cmx,cmy). Si esa suma es (numéricamente) cero -no hay dirección
    % definida por vectores-, se usa como respaldo la dirección de la
    % persona más alejada de (cmx,cmy) (ver bloque "Caso en el que la
    % resultante sea cero" más abajo, incluye por qué se usa una
    % tolerancia y no una igualdad exacta a 0). Esto es relevante en
    % particular cuando (cmx,cmy) es el centroide/media aritmética del
    % grupo: en ese caso la suma de vectores centrados es SIEMPRE cero
    % (salvo ruido de redondeo), para cualquier configuración de puntos,
    % así que el respaldo por persona más alejada se activa en el 100% de
    % las llamadas con centroide.
    %
    % Se determina el desplazamiento necesario para mover el centro de masa al origen
    xmove = -cmx;
    ymove = -cmy;
    % se mueve todo al origen.
    x = x + xmove;
    y = y + ymove;

    x_ord = x;
    y_ord = y;

    if length(x) == 2
       %Cuando hay dos individuos, la dirección es el primer individuo.
        resultan = [x(1), y(1)];
    else 
        % Ordenar los puntos alrededor del origen
        [x_ord, y_ord] = ordenar_puntos(0, 0, x, y);
        % Se halla la dirección resultante sumando los vectores
        resultan = [0, 0];
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
    % Caso en el que la resultante sea (numéricamente) cero: la suma de
    % vectores no define una dirección (esto ocurre, por ejemplo, SIEMPRE
    % que (cmx,cmy) es el centroide/media aritmética del grupo, ya que la
    % suma de posiciones centradas en su propia media es idénticamente
    % cero para cualquier configuración de puntos, no solo para las
    % simétricas; con el centro geométrico -bounding box- es un caso más
    % raro, pero también puede pasar).
    % Se compara con una TOLERANCIA en vez de "== 0" exacto: en punto
    % flotante, esa suma casi nunca da 0.0 bit a bit (el redondeo al
    % calcular cmx,cmy como media dejaría un residuo del orden de
    % eps*escala), así que una comparación exacta dejaría pasar un vector
    % de puro ruido numérico como si fuera una dirección real. La
    % tolerancia se escala con la distancia máxima del grupo al centro
    % para que sea consistente sin importar las unidades/escala de x,y.
    % Dirección de respaldo: se usa la de la persona MÁS ALEJADA del
    % centro (cmx,cmy) -la más "expuesta" del grupo-, que sí está
    % garantizada a ser no nula salvo que todas las personas coincidan
    % exactamente con el centro (caso extremo cubierto abajo con +X por
    % defecto).
    dist_ord = hypot(x_ord, y_ord);
    tol = max(1e-9, 1e-9 * max(dist_ord));
    if hypot(resultan(1), resultan(2)) < tol
        if length(x_ord) >= 1
            [maxDist, idxFar] = max(dist_ord);
            if maxDist > 0
                resultan = [x_ord(idxFar), y_ord(idxFar)];
            else
                % Todas las personas coinciden con el centro: no hay
                % dirección definida, se usa +X por defecto.
                resultan = [1, 0];
            end
        else
            resultan = [0, 0];
        end
    end
    %Determinar el angulo
    an = atan2(resultan(2) - 0, resultan(1) - 0); 
    ang = mod(rad2deg(an), 360);
    % Graficar si se solicita
    if graf == 1
        % La flecha nace en el centro del grupo y su punta coincide con
        % la dirección resultante calculada arriba.
        quiver(cmx, cmy, resultan(1), resultan(2), 0, ...
            'Color', 'k', 'LineWidth', 2, 'MaxHeadSize', 0.5);
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
%
% Respaldo cuando la resultante es cero: se toma como dirección la de la
% persona más alejada del centro (cmx,cmy) en vez del primer punto
% ordenado (comportamiento anterior). Motivo: cuando (cmx,cmy) es el
% centroide del grupo, la suma de vectores centrados es idénticamente
% cero por definición de la media aritmética (no solo en casos
% simétricos), así que el respaldo deja de ser un caso raro y pasa a
% determinar la dirección en el 100% de las llamadas con centro =
% centroide. Usar el punto más alejado ("más expuesto") da una dirección
% con significado proxémico y estable ante pequeños desplazamientos,
% en vez de una elección arbitraria basada en el orden angular.
