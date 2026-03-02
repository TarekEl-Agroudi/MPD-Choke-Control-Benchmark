classdef KPI
    methods(Static)
        %% Error-based KPIs
        function rmse = RMSE(signal, reference)
            e = reference(:) - signal(:);
            rmse = sqrt(mean(e.^2));
        end
        
        function maxErr = MaxSignedError(signal, reference)
            e = reference(:) - signal(:);
            [~, idx] = max(abs(e));
            maxErr = e(idx);
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

        %% Pressure trapping and Recovery KPIs
        function err = Trapped(signal, reference, tsim, t)
            dtSim = mean(diff(tsim));
            e = reference(:) - signal(:);
            err = max(e(round(t/dtSim)), 0);
        end

        function recov_os = RecoveryOvershoot(signal, reference, t, t_start)
            idx = find(t >= t_start, 1);
            if isempty(idx)
                recov_os = NaN;
                return;
            end
            sig_recovery = signal(idx:end);
            ref_recovery = reference(idx:end);
            e = sig_recovery(:) - ref_recovery(:);
            recov_os = max(max(e), 0);
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

        %% Stability Margin KPIs
        function [GMdB, PM, wcg, wcp, TDM, S_max, resp, faxis] = StabilityMargins(signal, reference, t, t_start, t_end)
            idx = t >= t_start & t <= t_end;
            u = signal(idx) - reference(idx);
            y = signal(idx);
            t_segment = t(idx);
        
            dtSim = mean(diff(t_segment));
            N = numel(t_segment);
        
            % Frequency axis in Hz
            faxis = (0:(N-1)) / N / dtSim;
            half = floor(N/2);
            faxis = faxis(1:half);
        
            u = detrend(u);
            y = detrend(y);
            u = u(:)';
            y = y(:)';
        
            resp = calculate_response(u, y, N);
            resp = resp .* exp(-1i * pi); 
            
            % Frequency range
            f_min = 0.01;
            f_max = 1;
            idx_range = (faxis >= f_min) & (faxis <= f_max);
            
            % GM, PM
            [GM, PM, wcg, wcp] = plot_bode_with_stability_margins(resp, faxis, f_min, f_max, 0);
        
            % Peak Sensitivity (S_max)
            if ~any(idx_range)
                S_max = NaN;
            else
                resp_in_range = resp(idx_range);
                return_diff = 1 + resp_in_range;
                
                min_dist_critical = min(abs(return_diff));
                
                if min_dist_critical == 0
                    S_max = Inf;
                else
                    S_max = 1 / min_dist_critical;
                end
            end
        
            % Robust Time Delay Margin (TDM)
            mag_L = abs(resp);
            valid_indices = find((mag_L >= 1) & idx_range); 
            
            if isempty(valid_indices)
                TDM = Inf;
            else
                f_valid = faxis(valid_indices);
                phi_valid = angle(resp(valid_indices)) * (180/pi);
                pm_valid = 180 + phi_valid;
                delay_candidates = (pm_valid .* (pi/180)) ./ (2 * pi * f_valid);
                delay_candidates(delay_candidates < 0) = Inf;
                
                TDM = min(delay_candidates);
                if isempty(TDM)
                     TDM = 0;
                end
            end
        
            wcg = wcg / (2*pi); % Hz
            wcp = wcp / (2*pi); % Hz
            GMdB = 20*log10(GM); % dB
        end
    end
end
