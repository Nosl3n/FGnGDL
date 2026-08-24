# Funciones auxiliares de FGnGDL

Esta carpeta reúne las funciones de apoyo geométrico usadas por los modelos
proxémicos del proyecto. En particular, `MODELOS/Paco_Model.m` y
`MODELOS/De_Sousa_Model.m` añaden esta carpeta al *path* de MATLAB automáticamente.

Si se invoca una función de esta carpeta de forma directa, añádela primero al
*path*:

```matlab
addpath('FUNCTIONS')
```

## Funciones incluidas

| Función | Descripción |
| --- | --- |
| `aumentar_02(maximo, x_ord, y_ord, xcm, ycm)` | Añade puntos intermedios cuando la separación angular entre puntos ordenados supera `maximo` grados. |
| `dis_ang(x, y, xc, yc)` | Calcula la distancia al centro `(xc, yc)` y el ángulo de cada punto en el intervalo `[0, 360)`. |
| `entre_personas(minima, ang, dis, x_ord, y_ord)` | Elimina un punto cuando dos puntos consecutivos tienen una separación angular menor o igual que `minima`. |
| `ordenamiento(ang, referencia, x, y)` | Reordena ángulos y coordenadas desde el ángulo de referencia; también devuelve los ángulos normalizados respecto a esa referencia. |
| `ordenar_puntos(xcm, ycm, x, y)` | Ordena las coordenadas de un grupo por su ángulo alrededor del centro `(xcm, ycm)`. |
| `orientacion_vec(x, y, cmx, cmy, graf)` | Calcula el ángulo de orientación resultante de un grupo; si `graf` vale `1`, dibuja el vector resultante. |
| `result(x, y)` | Suma dos vectores 2D representados por las parejas `x` e `y`. |
| `rotar_gaussiana(x, y, z, angulo, cmx, cmy)` | Rota una malla gaussiana alrededor de `(cmx, cmy)` el número de grados indicado. |
| `separacion(ang)` | Obtiene las separaciones angulares consecutivas, incluida la separación entre el último y el primer ángulo. |

## Ejemplos de uso

```matlab
% Distancias y ángulos de un grupo respecto a su centro
[distancias, angulos] = dis_ang(x, y, xcm, ycm);

% Ordenar puntos alrededor del centro geométrico
[x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);

% Separación angular entre puntos ya ordenados
separaciones = separacion(angulos);

% Rotar una malla gaussiana
[xrot, yrot, zrot] = rotar_gaussiana(X, Y, Z, 30, xcm, ycm);
```

## Dependencias internas

La cadena principal utilizada por `Paco_Model` es:

```text
ordenar_puntos -> orientacion_vec -> result
dis_ang -> entre_personas -> separacion
dis_ang + separacion + ordenar_puntos -> aumentar_02
rotar_gaussiana
```

Las funciones trabajan con coordenadas `x` e `y` de igual longitud. Los
ángulos se expresan en grados y se normalizan al intervalo `[0, 360)` cuando
corresponde.

## Requisitos

- MATLAB R2021a o posterior recomendado.
- Las funciones de esta carpeta deben estar disponibles en el *path* cuando
  se utilicen directamente.

**Autor:** Nelson Paco
**Última actualización:** agosto de 2026
