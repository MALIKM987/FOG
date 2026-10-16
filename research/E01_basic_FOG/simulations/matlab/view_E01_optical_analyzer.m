function fig = view_E01_optical_analyzer(kind,model)
%VIEW_E01_OPTICAL_ANALYZER Spectrum from a source's wired spectral outputs.
%
% Double click model's "OSA LASER..." or "OSA ASE..." block.
% This plots the wavelength and S_lambda vector CONSTANTS driving
% the 2nd and 3rd Simulink output ports of that source.
%
% Optical, not RF: this is not a time-signal FFT. Simulink source still
% propagates reduced complex envelopes in its 1st output.
if nargin<1 || isempty(kind)
    kind='LASER';
end
if nargin<2 || isempty(model)
    model='FOG_E01_SIMULINK';
end
kind=upper(char(kind));
assert(ismember(kind,{'LASER','ASE'}), ...
    'Wybierz LASER albo ASE.');
if ~bdIsLoaded(model)
    here=fileparts(mfilename('fullpath'));
    load_system(fullfile(here,[model '.slx']));
end
sourcePath=[model '/' kind ' - zrodlo'];
assert(getSimulinkBlockHandle(sourcePath)~=-1, ...
    'Nie znaleziono wskazanego zrodla.');
S_text=get_param([sourcePath '/Widmo S_lambda [W_nm]'],'Value');
L_text=get_param([sourcePath '/Dlugosc fali [nm]'],'Value');
spectrum=parseVector(S_text);
lambda=parseVector(L_text);
assert(numel(lambda)==numel(spectrum)&&numel(lambda)>=3, ...
    'Niepoprawne rozmiary sygnalow widmowych.');
assert(all(diff(lambda)>0)&&all(spectrum>=0), ...
    'Niepoprawne wartosci danych widmowych.');

totalPower_mW=trapz(lambda,spectrum)*1e3;
[peak,idx]=max(spectrum);
half=peak/2;
left=find(spectrum(1:idx)<=half,1,'last');
right=find(spectrum(idx:end)<=half,1,'first');
if isempty(left)||isempty(right)
    fwhm_nm=NaN;
else
    right=idx+right-1;
    fwhm_nm=lambda(right)-lambda(left);
end

fig=figure('Name',['OSA - Widmo optyczne ' kind], ...
    'Color','w','NumberTitle','off');
plot(lambda,spectrum,'LineWidth',1.7);
grid on;
xlabel('Długość fali [nm]');
ylabel('Gęstość mocy widmowej [W/nm]');
title(sprintf('Widmo źródła %s (wyjście optyczne modelu)',kind));
if isfinite(fwhm_nm)
    subtitle(sprintf('Moc %.3f mW | FWHM ok. %.4f nm', ...
        totalPower_mW,fwhm_nm));
else
    subtitle(sprintf('Moc %.3f mW',totalPower_mW));
end

fprintf('OSA %s: lambda=%g..%g nm, P=%.6f mW, FWHM=%.5f nm.\n', ...
    kind,lambda(1),lambda(end),totalPower_mW,fwhm_nm);
fprintf(['Wyswietlane widmo pochodzi z wyjsc widmowych modelu, ', ...
    'nie z pomiaru ani FFT obwiedni elektrycznej.\n']);
end

function values=parseVector(raw)
% Generator uses a literal MATLAB vector. str2num cannot be trusted for
% arbitrary user expressions, so accept only number/exp/bracket chars.
assert(~isempty(regexp(raw,'^[\[\]\s0-9+\-.eE]+$','once')), ...
    'Dane nie sa literalnym wektorem liczbowym.');
clean=strrep(strrep(raw,'[',''),']','');
values=sscanf(clean,'%f');
assert(~isempty(values), 'Pusty wektor widma.');
end
