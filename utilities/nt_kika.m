function [] = nt_kika(ev, predictions)

ndevices = ev.cfg.speller.functions.nkikadevices;
devicestate = false(ndevices, 1);
for devicei = 1:ndevices
    devicestate(devicei) = boolean(mod(sum(predictions == devicei), 2));
end

value = bin2dec(sprintf('%d', devicestate));
sndSerialButtonBoxMarker(ev, struct('name', 'kiki', 'value', value));