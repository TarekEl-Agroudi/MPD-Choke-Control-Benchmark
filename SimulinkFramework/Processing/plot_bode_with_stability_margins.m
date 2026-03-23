function [GM, PM, Wcg, Wcp] = plot_bode_with_stability_margins(resp, faxis, f_min, f_max, display_plot)
    % Function to plot the Bode diagram with stability margins and return GM and PM.
    %
    % Inputs:
    %   resp              - The frequency response data (complex values).
    %   faxis             - Frequency axis corresponding to the response.(Hz)
    %   f_min             - Minimum frequency for the valid range (Hz).
    %   f_max             - Maximum frequency for the valid range (Hz).
    %
    % Outputs:
    %   GM    - Gain Margin in dB.
    %   PM    - Phase Margin in degrees.
    %   Wcg   - Gain crossover frequency (where the phase margin is measured).
    %   Wcp   - Phase crossover frequency (where the gain margin is measured).
    %
    % Plots:
    %   A figure showing the Bode plot with stability margins.

    % Check if f_min and f_max are provided, if not, set defaults
    if nargin < 3
        f_min = 0.005; % default minimum frequency
    end
    if nargin < 4
        f_max = 0.8;   % default maximum frequency
    end
    if nargin < 5
        display_plot=0;
    end

    % Select the frequency range for the response
    freq_range_indices = (faxis >= f_min) & (faxis <= f_max);
    
    % Create the frequency response data (FRD) object
    % Note that frequenciesm are converted to rad/s
    response_frd = frd(resp(freq_range_indices), faxis(freq_range_indices)*2*pi);

    % Compute gain margin, phase margin, and associated crossover frequencies
    [GM, PM, Wcg, Wcp] = margin(response_frd);

    
    % Plot the Bode plot with stability margins
    if display_plot
        figure;
        margin(response_frd);
        grid on;
    
        % Display Gain Margin (GM) and Phase Margin (PM)
        fprintf('Bode Plot Gain Margin (GM): %.4f dB at frequency %.4f Hz\n', 20*log10(GM), Wcg);
        fprintf('Bode Plot Phase Margin (PM): %.4f deg at frequency %.4f Hz\n', PM, Wcp);
    end
end
