function [xrot, yrot, zrot] = prueba_dennis(x, y)
    if length(x) ~= length(y)
        error('Los vectores x e y deben tener el mismo tamaño.');
    end
    if ~isnumeric(x) || ~isnumeric(y)
        error('x e y deben ser numéricos.');
    end

    x = x(:).';
    y = y(:).';

    % Centro geométrico de la distribución
    mean_x = (max(x) + min(x)) / 2;
    mean_y = (max(y) + min(y)) / 2;

    dist_max = max(hypot(x - mean_x, y - mean_y));

    rotation = pi/2;
    variance_front  = dist_max + 0.5;
    variance_right  = dist_max / 1.5 + 0.2;
    variance_left   = dist_max / 1.5 + 0.2;
    variance_rear   = dist_max - 0.2;

    variance_front  = max(variance_front, eps);
    variance_right  = max(variance_right, eps);
    variance_left   = max(variance_left, eps);
    variance_rear   = max(variance_rear, eps);

    limit = dist_max + 0.5;
    paso = 0.05;
    [xrot, yrot] = meshgrid(mean_x-limit:paso:mean_x+limit, mean_y-limit:paso:mean_y+limit);
    alpha = atan2(yrot - mean_y, xrot - mean_x) - rotation + pi/2;
    size_alpha = size(alpha);
    for (i=1:size_alpha(1))
        for (j=1:size_alpha(2))
            if (alpha(i,j) > pi)
                alpha(i,j) = alpha(i,j) - 2*pi;
            elseif (alpha(i,j) < -pi)
                alpha(i,j) = alpha(i,j) + 2*pi;
            end
        end
    end
    for (i=1:size_alpha(1))
        for (j=1:size_alpha(2))
            if (alpha(i,j) <= 0)
                variance(i,j) = variance_rear;
            else
                variance(i,j) = variance_front;
            end
        end
    end
    for (i=1:size_alpha(1))
        for (j=1:size_alpha(2))
            if (alpha(i,j) >= pi/2  | alpha(i,j) <= -pi/2 )
                variance_sides(i,j) = variance_left;
            else
                variance_sides(i,j) = variance_right;
            end
        end
    end
    size(variance_sides);
    a = (cos(rotation)^2)./(2*variance) + (sin(rotation)^2)./(2*variance_sides);
    b = sin(2*rotation)./(4*variance) - sin(2*rotation)./(4*variance_sides);
    c = (sin(rotation)^2)./(2*variance)+ (cos(rotation)^2)./(2*variance_sides);
    f = exp(-(a.*(xrot - mean_x).^2 + 2*b.*(xrot - mean_x).*(yrot - mean_y) + c.*(yrot - mean_y).^2));
    
    zrot = f;
end