function plotTimeseries(ax, t, data, linew, style, col)
    if nargin < 6, col = [1 1 1]; end
    if nargin < 5, style = '-'; end
    if size(data,2) > 1
        for k = 1:size(data,2)
            plot(ax, t, data(:,k), style, 'LineWidth', linew, 'Color', col);
        end
    else
        plot(ax, t, data, style, 'LineWidth', linew, 'Color', col);
    end
end
