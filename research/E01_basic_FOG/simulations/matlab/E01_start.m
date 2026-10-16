%% FOG-E01-MIS: WYBIERZ ZRODLO SWIATLA I URUCHOM
% Edytuj TYLKO te linie (nie zmieniasz cewki ani sprzegacza):
SOURCE = "LASER";     % "LASER", "ASE" lub "BOTH"
%
% W E01_config.m (ustawienia zaawansowane):
%  cfg.noise_enabled = true;       % domyslnie: losowe szumy LASER/ASE
%  cfg.noise_enabled = false;      % tylko sredni sygnal, prawie jednakowy
%  cfg.parasitic_enabled = false;  % domyslnie: bez odbic optycznych
%  cfg.parasitic_enabled = true;   % dodatkowa DEMO droga odbicia
%
% Obserwuj 03_photodiode.png (prad fotodiody) oraz 07_source_noise.png
% (fluktuacje w uA). Szersze ASE NIE MUSI oznaczac innego sredniego pradu.
%
% To DEMONSTRACJA fizyki interferometru i spojnosci, NIE pomiar.
% MATLAB R2023b, bez wymagania Simulinka.

clc;
close all;
thisFolder = fileparts(mfilename('fullpath'));
addpath(thisFolder);

fprintf('FOG-E01-MIS: wybrane zrodlo = %s\n', char(SOURCE));
fprintf('UWAGA: E01_start.m uruchamia wykresy MATLAB, a NIE schemat Simulink.\n');
fprintf('Kod wykresow z pliku: %s\n',which('run_E01'));
fprintf('Schemat Simulink: uruchom osobno build_E01_simulink().\n');
out = run_E01(SOURCE);
