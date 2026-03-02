function KPI_results = computeKPI(simOut, scenario, OP)
    KPI_results = struct();
    waitTime = 100;
    switch scenario
        case 1
            stepDur  = 100;
            mults = [1.5, 1, 3, 1, 5, 1];
            stepTimes  = waitTime + (0:numel(mults)-1) * stepDur;
            stepValues = mults * OP.p_c0;
            riseTimes = nan(1, numel(stepTimes));
            settlingTimes = nan(1, numel(stepTimes));
            overshoots     = nan(1, numel(stepTimes));
            for iStep = 1:numel(stepTimes)
                tStart = stepTimes(iStep);
                stepVal = stepValues(iStep);
                if iStep == 1
                    startVal = OP.p_c0;
                else
                    startVal = stepValues(iStep-1);
                end
            
                riseTimes(iStep) = KPI.RiseTime(simOut.p_c.Data, simOut.tout, tStart, stepVal);
                settlingTimes(iStep) = KPI.SettlingTime(simOut.p_c.Data, simOut.tout, tStart, tStart+stepDur, startVal, stepVal);
                overshoots(iStep) = KPI.MaxOvershoot(simOut.p_c.Data, simOut.tout, tStart, tStart+stepDur, startVal, stepVal);
            end
            KPI_results.AvgRiseTime     = mean(riseTimes, 'omitnan');
            KPI_results.AvgSettlingTime = mean(settlingTimes, 'omitnan');
            KPI_results.MaxOvershoot    = max(overshoots);

            KPI_results.IAW = KPI.IAOmega(simOut.w_cA.Data,simOut.tout) + KPI.IAOmega(simOut.w_cB.Data,simOut.tout);
            KPI_results.IAA = KPI.IAAccel(simOut.w_cA.Data,simOut.tout) + KPI.IAAccel(simOut.w_cB.Data,simOut.tout);

        case {2,3,4}
            KPI_results.RMSE = KPI.RMSE(simOut.p_c.Data,simOut.p_c_r.Data);
            KPI_results.MaxError = KPI.MaxSignedError(simOut.p_c.Data,simOut.p_c_r.Data);
            KPI_results.IAE = KPI.IAE(simOut.p_c.Data,simOut.p_c_r.Data,simOut.tout);
            KPI_results.ISE = KPI.ISE(simOut.p_c.Data,simOut.p_c_r.Data,simOut.tout);            
            KPI_results.IAW = KPI.IAOmega(simOut.w_cA.Data,simOut.tout) + KPI.IAOmega(simOut.w_cB.Data,simOut.tout);
            KPI_results.IAA = KPI.IAAccel(simOut.w_cA.Data,simOut.tout) + KPI.IAAccel(simOut.w_cB.Data,simOut.tout);
        case 5
            KPI_results.RMSE = KPI.RMSE(simOut.p_c.Data,simOut.p_c_r.Data);
            KPI_results.IAE = KPI.IAE(simOut.p_c.Data,simOut.p_c_r.Data,simOut.tout);
            KPI_results.ISE = KPI.ISE(simOut.p_c.Data,simOut.p_c_r.Data,simOut.tout);            
            KPI_results.IAW = KPI.IAOmega(simOut.w_cA.Data,simOut.tout) + KPI.IAOmega(simOut.w_cB.Data,simOut.tout);
            KPI_results.IAA = KPI.IAAccel(simOut.w_cA.Data,simOut.tout) + KPI.IAAccel(simOut.w_cB.Data,simOut.tout);
            
            T_trapped = waitTime+4*OP.t_ramp;
            KPI_results.Trapped = KPI.Trapped(simOut.p_c.Data,simOut.p_c_r.Data, simOut.tout, T_trapped);
            KPI_results.RecovOS = KPI.RecoveryOvershoot(simOut.p_c.Data, simOut.p_c_r.Data, simOut.tout, T_trapped);
        case 6
            t_start = 100;
            t_end   = 1100;
            [KPI_results.GM, KPI_results.PM, KPI_results.wcg, KPI_results.wcp, ...
             KPI_results.TDM, KPI_results.S_max, ...
             KPI_results.resp, KPI_results.faxis] = KPI.StabilityMargins(simOut.p_c.Data(:), simOut.p_c_r.Data(:), simOut.tout, t_start, t_end);
             
        case 7
            t_start = 500 + waitTime + 2*OP.t_ramp;
            t_end   = 1500 + waitTime + 2*OP.t_ramp;
            [KPI_results.GM, KPI_results.PM, KPI_results.wcg, KPI_results.wcp, ...
             KPI_results.TDM, KPI_results.S_max, ...
             KPI_results.resp, KPI_results.faxis] = KPI.StabilityMargins(simOut.p_c.Data(:), simOut.p_c_r.Data(:), simOut.tout, t_start, t_end);
    end
end
