function fig = show_E01_spectra()
%SHOW_E01_SPECTRA Widma LASER i ASE z modelu E01, po polsku.
% MATLAB R2023b, bez Simulinka i bez toolboxow.
%
% W Command Window: show_E01_spectra();
% W Simulinku: kliknij 2x blok WIDMA LASER I ASE.
%
% To widma GAUSSA z E01_config, nie pomiary laboratoryjne.
% W obu przypadkach calkowita moc jest taka sama.

cfg = E01_config();
laser = E01_source(cfg,"LASER");
ase = E01_source(cfg,"ASE");

fig=figure('Name','FOG E01 | Widma optyczne LASER i ASE', ...
    'Color','w','NumberTitle','off');
lay=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

% 1. Wspolna skala dlugosci fali, normowanie kazdego widma osobno.
nexttile(lay,1);hold on;grid on;
plot(laser.lambda_nm,laser.S_W_per_nm/max(laser.S_W_per_nm), ...
    'LineWidth',1.6,'DisplayName','LASER');
plot(ase.lambda_nm,ase.S_W_per_nm/max(ase.S_W_per_nm), ...
    'LineWidth',1.6,'DisplayName','ASE');
xlim([cfg.lambda0_nm-1.8*cfg.ase_fwhm_nm, ...
      cfg.lambda0_nm+1.8*cfg.ase_fwhm_nm]);
xlabel('Długość fali [nm]');
ylabel('Znormalizowana gęstość widmowa [-]');
title('Porównanie szerokości widma');
legend('show','Location','best');

% 2. Zoom, aby uwidocznic waskie widmo LASER.
nexttile(lay,2);hold on;grid on;
plot(laser.lambda_nm,laser.S_W_per_nm/max(laser.S_W_per_nm), ...
    'LineWidth',1.6,'DisplayName','LASER');
plot(ase.lambda_nm,ase.S_W_per_nm/max(ase.S_W_per_nm), ...
    'LineWidth',1.6,'DisplayName','ASE');
xlim(cfg.lambda0_nm+[-0.12 0.12]);
xlabel('Długość fali [nm]');
ylabel('Znormalizowana gęstość widmowa [-]');
title('Zbliżenie na wąskie widmo lasera');
legend('show','Location','best');

% 3. Rzeczywista gestosc mocy widmowej (a nie normowanie piku do 1).
nexttile(lay,3);hold on;grid on;
semilogy(laser.lambda_nm,laser.S_W_per_nm, ...
    'LineWidth',1.6,'DisplayName','LASER');
semilogy(ase.lambda_nm,ase.S_W_per_nm, ...
    'LineWidth',1.6,'DisplayName','ASE');
xlim([cfg.lambda0_nm-1.8*cfg.ase_fwhm_nm, ...
      cfg.lambda0_nm+1.8*cfg.ase_fwhm_nm]);
xlabel('Długość fali [nm]');
ylabel('Gęstość mocy optycznej [W/nm]');
title('Skala bezwzględna (oś pionowa logarytmiczna)');
legend('show','Location','best');

% 4. Calka po widmie pokazuje jednakowa moc calkowita w obu zrodlach.
nexttile(lay,4);hold on;grid on;
plot(laser.lambda_nm,cumtrapz(laser.lambda_nm, ...
    laser.S_W_per_nm)*1e3,'LineWidth',1.6, ...
    'DisplayName','LASER');
plot(ase.lambda_nm,cumtrapz(ase.lambda_nm, ...
    ase.S_W_per_nm)*1e3,'LineWidth',1.6, ...
    'DisplayName','ASE');
xlim([cfg.lambda0_nm-1.8*cfg.ase_fwhm_nm, ...
      cfg.lambda0_nm+1.8*cfg.ase_fwhm_nm]);
xlabel('Długość fali [nm]');
ylabel('Moc skumulowana [mW]');
title('Całka z widma: obie moce końcowe są równe');
legend('show','Location','best');

sgtitle(lay,sprintf(['FOG-E01-MIS: LASER i ASE | ', ...
    'P = %.3f mW | FWHM: LASER %.3f nm, ASE %.1f nm'], ...
    cfg.input_power_W*1e3,laser.fwhm_nm,ase.fwhm_nm));

fprintf('\nPODGLAD WIDM OPTYCZNYCH E01 (modele Gaussa):\n');
fprintf(' LASER: FWHM = %.4f nm, P = %.6f mW\n', ...
    laser.fwhm_nm,trapz(laser.lambda_nm,laser.S_W_per_nm)*1e3);
fprintf(' ASE:   FWHM = %.4f nm, P = %.6f mW\n', ...
    ase.fwhm_nm,trapz(ase.lambda_nm,ase.S_W_per_nm)*1e3);
fprintf(' To widma ilustracyjne, NIE zarejestrowane widma źródeł.\n');
end
