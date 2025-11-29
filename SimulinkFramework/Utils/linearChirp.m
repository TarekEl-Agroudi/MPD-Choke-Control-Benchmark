function [signal_ts, t_sim] = linearChirp(dt, initialValue, amp, t_settle, t_chirp)
% linearChirp Generate a linear chirp timeseries for any signal
%
% Inputs:
%   dt           - simulation time step [s]
%   initialValue - initial value(s) of the signal (scalar or vector)
%   amp          - amplitude of the chirp
%   t_settle     - duration before chirp starts [s]
%   t_chirp      - duration of chirp [s]
%
% Outputs:
%   signal_ts - timeseries object
%   t_sim     - total simulation time [s]

    Fs = 1/dt;
    t_total = t_settle + t_chirp;
    t_sim = t_total;
    t = linspace(0, t_total, round(t_total * Fs))';

    % Frequency sweep
    f_start = 0.05;
    f_end   = 1.5;
    f_t = f_start + (f_end - f_start) * ((t - t_settle) / t_chirp);
    f_t(t < t_settle) = 0;

    phase = 2 * pi * cumtrapz(t, f_t);

    if isscalar(initialValue)
        signal = initialValue + amp * sin(phase);
        signal(t < t_settle) = initialValue;
    else
        signal = repmat(initialValue(:)', length(t), 1);
        signal(:,1) = initialValue(1) + amp * sin(phase);
    end

    signal_ts = timeseries(signal, t);
end
