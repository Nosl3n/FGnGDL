# GANGL_V05 - Generación de Mallas Gaussianas en MATLAB

La función `GANGL_V05` procesa un conjunto de puntos `(x, y)` para determinar su distribución, orientación y generar una **malla gaussiana 3D**.  
La función incluye varias etapas:  

 **Determinación del centro del grupo**  
 **Ordenamiento de puntos**  
 **Cálculo de distancias y ángulos**  
 **Eliminación y adición de puntos**  
 **Rotación y graficación de la malla gaussiana**  

---

## Uso

```matlab
Area = GANGL_V05(x, y, graf, VISTA, per);
```

## Parámetros de entrada

- `x`: Vector con coordenadas **x** de los puntos.  
- `y`: Vector con coordenadas **y** de los puntos.  
- `graf`: Control de visualización (`1 = Sí`, `0 = No`).  
- `VISTA`: Modo de visualización (`2 = 2D`, `3 = 3D`).  
- `per`: Control de representación de personas (`1 = Con personas`, `0 = Sin personas`).  

---

## Salida

- `Area`: Devuelve el área bajo el contorno de nivel **0.3** de la malla gaussiana generada.  

---

## Explicación del Proceso  

###  1. Determinación del Centro del Grupo
El **centro de masa** `(xcm, ycm)` se calcula a partir de los puntos proporcionados.  

###  2. Ordenamiento de Puntos
Se ordenan los puntos en sentido horario respecto al centro de masa con la función:  

```matlab
[x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);
```

###  3. Cálculo de Distancias y Ángulos  
Se determinan las distancias y los ángulos de cada punto respecto al eje **x** y al centro de masa:  

```matlab
[dis, ang] = dis_ang(x_ord, y_ord, xcm, ycm);
```

###  4. Determinación de la Orientación del Grupo
Se calcula la dirección angular del grupo utilizando la función: 

```matlab
ang_vec = orientacion_vec(x_ord, y_ord, xcm, ycm, graf);
```

###  5. Eliminación y Adición de Puntos
- Se eliminan personas si están demasiado cerca (entre_personas).
- Se añaden personas si hay espacios muy grandes (aumentar_02).

```matlab
[x_mod, y_mod] = entre_personas(15, ang, dis, x_ord, y_ord);
[x_aum, y_aum] = aumentar_02(70, x_mod, y_mod, xcm, ycm);

```

###  6. Rotación de los Puntos
Los puntos se rotan para alinear la orientación con el ángulo calculado:

```matlab
[xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, rotacion, xcm, ycm);
```

###  7. Generación de la Malla Gaussiana
Se genera una malla en 2D/3D para representar la distribución de los puntos:

```matlab
zz = exp(-(xx - xcm).^2 ./ (2 .* varianzax.^2) - (yy - ycm).^2 ./ (2 .* varianzay.^2));
```

###  8. Cálculo del Área Bajo la Curva
El área bajo el contorno de nivel 0.3 se calcula mediante integración numérica:

```matlab
Area = polyarea(x_contour, y_contour);
```

## Ejemplo de Uso

también puede ver el archivo `Principal.m` para ver un ejemplo de funcionamiento.

### Definir coordenadas de los puntos

```matlab
x = [1, 3, 5, 7, 9];
y = [2, 4, 6, 8, 10];
```

### Generar la malla gaussiana en 3D con personas

```matlab
Area = GANGL_V05(x, y, 1, 3, 1);
```

### Ver el área total

```matlab
fprintf("Área: %f", Area);
```

## Cambios recientes
Fecha: 2026-08-27

### 1) `MODELOS/Individual_model.m`
- Se actualizó la firma a:

```matlab
[xrot, yrot, zrot] = Individual_model(x, y, theta)
```

- Ahora recibe una sola persona (`x`, `y` escalares) y su orientación `theta` en grados.
- La gaussiana se genera primero con orientación base `0` y luego se rota con `theta`, para mantener forma consistente entre orientaciones.
- Mantiene la misma salida (`xrot`, `yrot`, `zrot`).

### 2) `MODELOS/Aracelly_model_theta.m`
- Se corrigió para usar explícitamente `theta` de entrada por persona (en grados).
- Ya no calcula la orientación mirando al centro del grupo.
- Se añadió validación de tamaño: `theta` debe tener el mismo número de elementos que `x` e `y`.
- La salida sigue siendo la malla global de la mezcla gaussiana (`xrot`, `yrot`, `zrot`).

### 3) `modelo_humano.m`
- Se integró el uso de orientaciones para los modelos:
  - Curva grupal usando `Aracelly_model_theta(...)`.
  - Curva individual por persona llamando `Individual_model(x(k), y(k), theta(k))`.
- Se añadieron curvas de contorno individuales (corte en nivel `h`) para cada persona.
- Se mantiene la visualización de cuerpo, zonas proxémicas y flecha de orientación.

### Ejemplo rápido
```matlab
x = [4.5, 4, 3, 2];
y = [1, -1, 0, 1];
theta = [200, 45, 30, 15]; % grados
run('modelo_humano.m');
```
