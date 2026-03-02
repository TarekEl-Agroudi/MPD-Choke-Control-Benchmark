function response = calculate_response(u, y, N)
    % This function calculates the frequency response of a system given
    % input signal u, output signal y, and the total number of samples N.
    arguments
        u (1,:)
        y (1,:)
        N (1,1) {mustBeInteger}
    end
    
    half = floor(N/2);  % Calculate half of the sample size

    % FFT of input signal
    fu = fft(u) * (1 / N);
    fu = fu(1:half);
    fu(2:end) = 2 * fu(2:end);

    % FFT of output signal
    fy = fft(y) * (1 / N);
    fy = fy(1:half);
    fy(2:end) = 2 * fy(2:end);

    % Calculate the frequency response
    response = fy ./ fu;
end