classdef KPI
    methods(Static)
        %% Error-based KPIs
        function rmse = RMSE(signal, reference)
            e = reference(:) - signal(:);
            rmse = sqrt(mean(e.^2));
            rmse = 14.503*rmse; % bar -> psi
        end
        
        function err = Trapped(signal, reference, tsim, t)
            dtSim = mean(diff(tsim));
            e = reference(:) - signal(:);
            err = max(e(round(t/dtSim)), 0);
            err = 14.503*err; % bar -> psi
        end
        
        function maxErr = MaxSignedError(signal, reference)
            e = reference(:) - signal(:);
            [~, idx] = max(abs(e));
            maxErr = e(idx);  
            maxErr = 14.503*maxErr; % bar -> psi
        end
        
        function rise_t = RiseTime(signal, t, t_start, step_value, threshold)
            if nargin < 5, threshold = 0.9; end
            idx = find(t >= t_start,1);
            s = signal(idx:end);
            target_value = step_value * threshold;
            rise_idx = find(s >= target_value, 1);
            if isempty(rise_idx)
                rise_t = NaN;
            else
                rise_t = t(idx-1+rise_idx) - t_start;
            end
        end
        
        function sett_t = SettlingTime(signal, t, t_start, t_endStep, start_value, step_value, tol)
            if nargin < 7, tol = 0.05; end
            idx_start = find(t >= t_start,1);
            idx_end = find(t >= t_endStep,1);
            s = signal(idx_start:idx_end);
            t_segment = t(idx_start:idx_end);
            tol = tol*(step_value-start_value);

            within_tol = find(abs(s - step_value) <= tol);

            if isempty(within_tol)
                sett_t = NaN;
                return
            end

            for i = 1:length(within_tol)
                if all(abs(s(within_tol(i):end)-step_value) <= tol)
                    sett_t = t_segment(within_tol(i)) - t_start;
                    return
                end
            end

            sett_t = NaN;
        end
        
        function os = MaxOvershoot(signal, t, t_start, t_end, start_value, target_value)
            idx1 = find(t >= t_start, 1);
            idx2 = find(t <= t_end, 1, 'last');
            seg = signal(idx1:idx2);
            if target_value > start_value
                os = max(seg - target_value);
            else
                os = max(target_value - seg);
            end
            os = 14.503*os; % bar -> psi
        end
        
        %% Integral error KPIs
        function IAE = IAE(signal, reference, t)
            e = reference(:) - signal(:);
            IAE = trapz(t, abs(e));
        end
        
        function ISE = ISE(signal, reference, t)
            e = reference(:) - signal(:);
            ISE = trapz(t, e.^2);
        end
        
        function ITAE = ITAE(signal, reference, t)
            e = reference(:) - signal(:);
            ITAE = trapz(t, t(:) .* abs(e));
        end
        
        %% Actuator usage KPIs
        function IAW = IAOmega(omega, t)
            IAW = trapz(t, abs(omega(:)));
        end
        
        function ISW = ISOmega(omega, t)
            ISW = trapz(t, omega(:).^2);
        end
        
        function IAA = IAAccel(omega, t)
            omega = omega(:); t = t(:);
            alpha = zeros(size(omega));
            alpha(2:end-1) = (omega(3:end) - omega(1:end-2)) ./ (t(3:end) - t(1:end-2));
            alpha(1)  = (omega(2) - omega(1)) / (t(2) - t(1));
            alpha(end)= (omega(end) - omega(end-1)) / (t(end) - t(end-1));
            IAA = trapz(t, abs(alpha));
        end
        
        function ISA = ISAccel(omega, t)
            omega = omega(:); t = t(:);
            alpha = zeros(size(omega));
            alpha(2:end-1) = (omega(3:end) - omega(1:end-2)) ./ (t(3:end) - t(1:end-2));
            alpha(1)  = (omega(2) - omega(1)) / (t(2) - t(1));
            alpha(end)= (omega(end) - omega(end-1)) / (t(end) - t(end-1));
            ISA = trapz(t, alpha.^2);
        end

        %% Stability Margin KPI
        function [GMdB, PM, wcg, wcp, resp, faxis] = StabilityMargins(signal, reference, t, t_start, t_end)
            idx = t >= t_start & t <= t_end;
            u = signal(idx) - reference(idx);
            y = signal(idx);
            t_segment = t(idx);
        
            dtSim = mean(diff(t_segment));
            N = numel(t_segment);
        
            faxis = (0:(N-1)) / N / dtSim;
            half = floor(N/2);
            faxis = faxis(1:half);
        
            u = detrend(u);
            y = detrend(y);
        
            u = u(:)';
            y = y(:)';
        
            resp = calculate_response(u, y, N);
            resp = resp .* exp(-1i * pi);
            [GM, PM, wcg, wcp] = plot_bode_with_stability_margins(resp, faxis, 0.01, 1, 0);
        
            % Convert to Hz
            wcg = wcg / (2*pi);
            wcp = wcp / (2*pi);
       
            GMdB = 20*log10(GM); % in dB
        end
    end
end
