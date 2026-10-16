function report=sweep_E01_simulink(nPoints)
%SWEEP_E01_SIMULINK Zgodnosc ze stara komenda, tylko JEDEN wykres.
%
% Od tego etapu pokazujemy wylacznie interaktywny wykres sredniego
% pradu fotodiody od predkosci katowej. Brak dodatkowych wykresow I1
% i bledu. NIE wykonujemy kilkudziesieciu kolejnych symulacji .slx:
% charakterystyka liczona jest z optycznego modelu widmowego E01,
% tymi samymi parametrami z E01_config i E01_source.
%
% Manualne wywolanie w MATLAB:
%     wyniki=sweep_E01_simulink(101);
% Zalecana jawna nazwa:
%     wyniki=E01_current_layers(101);
%
% Schemat .slx pozostaje niezalezny przy zwyklym nacisnieciu Run.
if nargin<1
    nPoints=[];
end
fprintf(['Charakterystyka warstwowa E01: obliczenia analityczno-', ...
    'widmowe, bez serii 84 uruchomien Simulinka.\n']);
report=E01_current_layers(nPoints);
end
