function E01_toggle_layer(~,event)
%E01_TOGGLE_LAYER Toggle a current-vs-angular-rate layer via MATLAB legend.
% MATLAB R2023b legend ItemHitFcn callback; no simulations are run here.
line=event.Peer;
if strcmp(get(line,'Visible'),'on')
    set(line,'Visible','off');
else
    set(line,'Visible','on');
end
end
