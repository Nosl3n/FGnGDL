clc; clear all; close all;
GRAF = 1; vista = 3; per = 1;

li=5;%limite de coordenadas, maximo 5.
limvec=10; %limite del numero de personas.
%% caso con dos personas
n = randi([2, limvec]);% Generar un número aleatorio de elementos para el vector (n)
x = li * rand(1, n); % Valores aleatorios
y = li * rand(1, n); % Valores aleatorios 
figure
Area_GAN = GANGL_V05(x,y,GRAF, vista,per);
legend('Direction','level curves','level curves','level curves','level curves','level curves','Center','','','People');
axis equal;
fprintf("El area interna es: %f",Area_GAN);

