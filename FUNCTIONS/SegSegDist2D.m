function [dist, c1, c2] = SegSegDist2D(p1, q1, p2, q2)
%SEGSEGDIST2D Distancia mínima entre dos segmentos 2D.
%   [dist, c1, c2] = SegSegDist2D(p1, q1, p2, q2)
%   Calcula la distancia mínima entre el segmento [p1,q1] y el segmento
%   [p2,q2] (cada punto es un vector fila [x y]), junto con el punto más
%   cercano de cada segmento (c1 en el primero, c2 en el segundo).
%   Se usa para la colisión entre las "columnas" de las cápsulas que
%   representan el cuerpo de cada persona (ver Individual_Human_Model),
%   en vez de aproximar a cada persona como un simple círculo.
%   Implementación estándar (Ericson, "Real-Time Collision Detection").

    d1 = q1 - p1;
    d2 = q2 - p2;
    r  = p1 - p2;
    a = dot(d1, d1);
    e = dot(d2, d2);
    f = dot(d2, r);

    tol = 1e-12;
    if a <= tol && e <= tol
        c1 = p1;
        c2 = p2;
        dist = norm(c1 - c2);
        return;
    end

    if a <= tol
        s = 0;
        t = clampUnit(f / e);
    else
        c = dot(d1, r);
        if e <= tol
            t = 0;
            s = clampUnit(-c / a);
        else
            b = dot(d1, d2);
            denom = a*e - b*b;
            if denom ~= 0
                s = clampUnit((b*f - c*e) / denom);
            else
                s = 0;
            end
            t = (b*s + f) / e;
            if t < 0
                t = 0;
                s = clampUnit(-c / a);
            elseif t > 1
                t = 1;
                s = clampUnit((b - c) / a);
            end
        end
    end

    c1 = p1 + s * d1;
    c2 = p2 + t * d2;
    dist = norm(c1 - c2);
end

function v = clampUnit(v)
    v = min(max(v, 0), 1);
end
