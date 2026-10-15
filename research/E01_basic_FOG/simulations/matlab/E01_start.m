%% FOG-E01-MIS: WYBIERZ ZRODLO SWIATLA I URUCHOM
% Edytuj TYLKO te linie (nie zmieniasz cewki ani sprzegacza):
SOURCE = "LASER";     % "LASER", "ASE" lub "BOTH"
%
% W E01_config.m:
%  cfg.parasitic_enabled = true;   % wyrazna roznica na fotodiodzie
%  cfg.parasitic_enabled = false;  % idealny FOG, prawie te same sygnaly
%
% To DEMONSTRACJA fizyki interferometru i spojnosci, NIE pomiar.
% MATLAB R2023b, bez wymagania Simulinka.

clc;
close all;
thisFolder = fileparts(mfilename('fullpath'));
addpath(thisFolder);

fprintf('FOG-E01-MIS: wybrane zrodlo = %s\n', char(SOURCE));
out = run_E01(SOURCE);
