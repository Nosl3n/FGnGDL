function [xrot, yrot, zrot] = gaussian2_a2_focussed(x,y,mean_x, mean_y, rotation, variance_front, variance_right, variance_left, variance_rear)
    lado = 2.5; %maximo valor de cada lado de la grafica
    paso = 0.1; %Paso de la malla, entre punto a punto
    xpos = abs(max(x))+lado;
    xneg = abs(min(x))-lado;
    ypos = abs(max(y))+lado;
    yneg = abs(min(y))-lado;
    %Se genera la malla en la que se determianra cada punto de la gaussiana.
    [xrot, yrot] = meshgrid((xneg):paso:(xpos), (yneg):paso:(ypos));
    %[x,y] = meshgrid(mean_x-limit:0.01:mean_x+limit,mean_y-limit:0.01:mean_y+limit);
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
    a = (cos(rotation)^2)./(2*variance) + (sin(rotation)^2)./(2*variance_sides);
    b = sin(2*rotation)./(4*variance) - sin(2*rotation)./(4*variance_sides);
    c = (sin(rotation)^2)./(2*variance)+ (cos(rotation)^2)./(2*variance_sides);
    zrot = exp(-(a.*(xrot - mean_x).^2 + 2*b.*(xrot - mean_x).*(yrot - mean_y) + c.*(yrot - mean_y).^2));
end
