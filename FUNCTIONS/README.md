# FGnGDL

# Funciones de Procesamiento y Visualización en MATLAB

Este repositorio contiene una colección de funciones en MATLAB para el procesamiento, ordenamiento y visualización de datos relacionados con puntos y su distribución en el espacio. 

## Contenido

Las siguientes funciones están incluidas en este proyecto:

### 1. `aumentar_02(maximo, x_ord, y_ord, xcm, ycm)`
**Descripción:**  
Ajusta la distribución de puntos `(x_ord, y_ord)` respecto a un centro de masa `(xcm, ycm)`, añadiendo nuevos puntos si las distancias angulares entre puntos consecutivos superan un valor máximo `(maximo)`.  

**Uso:**
```matlab
[x_aaum, y_aaum] = aumentar_02(maximo, x_ord, y_ord, xcm, ycm); 
```

### 2.  `dis_ang(x, y, xc, yc)`
**Descripción:**
Calcula las distancias euclidianas y los ángulos en grados de cada punto `(x, y)` respecto a un punto central `(xc, yc)`.

**Uso:**
```matlab
[distancias, angulos_grados] = dis_ang(x, y, xc, yc);
```

### 3.  `graficar_lineas_nivel(xrot, yrot, zrot, xcm, ycm)`
**Descripción:**
Dibuja contornos de nivel en una gráfica para una malla 3D rotada `(xrot, yrot, zrot)`, y marca el centro de masa `(xcm, ycm)`.

**Uso:**
```matlab
graficar_lineas_nivel(xrot, yrot, zrot, xcm, ycm);
```

### 4.  `graficar_personas(x, y)`
**Descripción:**
Dibuja círculos en una gráfica para representar a cada persona en las coordenadas `(x, y)`.

**Uso:**
```matlab
graficar_personas(x, y);
```

### 5.  `graficar_personas3d(posicion_x, posicion_y)`
**Descripción:**
Dibuja representaciones 3D de múltiples personas en las coordenadas especificadas por `(posicion_x, posicion_y)`.

**Uso:**
```matlab
graficar_personas3d(posicion_x, posicion_y);
```

### 6.  `ordenar_puntos(xcm, ycm, x, y)`
**Descripción:**
Organiza los puntos `(x, y)` en función de sus ángulos respecto a un punto central `(xcm, ycm)`.

**Uso:**
```matlab
[x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);
```

### 7.  `orientacion_vec(x, y, cmx, cmy, graf)`
**Descripción:**
Calcula la dirección angular de un grupo de puntos `(x, y)` respecto a un centro de masa `(cmx, cmy)`, y opcionalmente la grafica.

**Uso:**
```matlab
ang = orientacion_vec(x, y, cmx, cmy, graf);
```

### 8.  `personas3d(posicion_x, posicion_y)`
**Descripción:**
Dibuja una representación en 3D de una persona en `(posicion_x, posicion_y)`.

**Uso:**
```matlab
personas3d(posicion_x, posicion_y);
```

### 9.  `result(x, y)`
**Descripción:**
Calcula la suma vectorial (resultante) de dos vectores 2D, cada uno representado por dos componentes en los vectores `x` e `y`.

**Uso:**
```matlab
resultante = result(x, y);
```

### 10.  `ordenar_puntos(xcm, ycm, x, y)`
**Descripción:**
Rota una malla gaussiana `(x, y, z)` alrededor de un punto central `(cmx, cmy)` por un ángulo especificado.

**Uso:**
```matlab
[xrot, yrot, zrot] = rotar_gaussiana(x, y, z, angulo, cmx, cmy);
```

### 11.  `separacion(ang)`
**Descripción:**
Devuelve un vector con las distancias angulares entre personas en grados `(°)`, respecto al centro del grupo.

**Uso:**
```matlab
distancias = separacion(ang);
```

## Requisitos

- MATLAB (versión recomendada: R2021a o superior).
- Las funciones deben estar en el **path de MATLAB** para su correcta ejecución.

---


## Autor

**Autor:** Nelson Paco 
**Última actualización:** Febrero 2025  
**Licencia:** MIT  

