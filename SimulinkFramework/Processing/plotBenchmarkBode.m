function plotBenchmarkBode(KPI, th, reportFolder, reportPDF, scenarioNum)
    fig = figure('Visible','on','Units','pixels','Position',[100 100 794 1123], ...
                 'Color', th.fig_bg, 'InvertHardcopy','off');

    left_margin = 0.1; right_margin = 0.9;
    bottom_margin = 0.08; top_margin = 0.82;
    plot_spacing = 0.02; nPlots = 2;
    plot_height = (top_margin - bottom_margin - (nPlots-1)*plot_spacing)/nPlots;

    resp  = KPI.resp;
    faxis = KPI.faxis;
    GM    = KPI.GM; 
    PM    = KPI.PM;
    wcp   = KPI.wcp;
    wcg   = KPI.wcg;

    % --- Magnitude plot ---
    ax1 = axes('Position',[left_margin, bottom_margin + plot_height + plot_spacing, right_margin-left_margin, plot_height], ...
               'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, ...
               'GridColor', th.axes_grid, 'GridAlpha',0.3, 'XScale', 'log');
    set(ax1, 'XTickLabel', []);
    hold(ax1,'on'); grid(ax1,'on');
    plot(ax1, faxis, 20*log10(abs(resp)), 'Color', th.lineColors(1,:), 'LineWidth', 1);
    % xlabel(ax1,'Frequency (Hz)','Color',th.text_col);
    ylabel(ax1,'Magnitude (dB)','Color',th.text_col);
    xlim(ax1, [0.005, 1]);
    ylim(ax1, [-50, 50]);
    plot(ax1, xlim(ax1), [0 0], '--', 'Color', th.lineColors(1,:));

    title(ax1, 'Loop gain with stability margins','FontSize',10,'FontWeight','bold','Color', th.text_col);

    % --- Phase plot ---
    ax2 = axes('Position',[left_margin, bottom_margin, right_margin-left_margin, plot_height], ...
               'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, ...
               'GridColor', th.axes_grid, 'GridAlpha',0.3, 'XScale', 'log');
    hold(ax2,'on'); grid(ax2,'on');
    
    ph = unwrap(angle(resp)) * 180/pi;
    if isfinite(wcg) && wcg > 0 && isfinite(PM)
        [~, wcg_idx] = min(abs(faxis - wcg)); 
        phase_at_wcg = ph(wcg_idx);
        required_phase = -180 + PM;
        shift = round((required_phase - phase_at_wcg) / 180) * 180;
        ph_shifted = ph + shift;
    else
        idx = (faxis >= 0.05 & faxis <= 0.1);
        meanBand = mean(ph(idx));
        n = round((-180-meanBand) / 180);
        ph_shifted = ph - 180 * n;
    end

    plot(ax2, faxis, ph_shifted, 'Color', th.lineColors(2,:), 'LineWidth', 1);
    xlabel(ax2,'Frequency (Hz)','Color',th.text_col);
    ylabel(ax2,'Phase (deg)','Color',th.text_col);
    xlim(ax2, [0.005, 1]);
    ylim(ax2, [-360, 10]);
    plot(ax2, xlim(ax1), [-180 -180], '--', 'Color', th.lineColors(2,:));

    % --- Mark crossovers & margins ---
    GM_color = [0 0.7 0] * (GM >= 6) + [1 0 0] * (GM < 6);
    PM_color = [0 0.7 0] * (PM >= 45) + [1 0 0] * (PM < 45);

    yMag = ylim(ax1); yPh = ylim(ax2);

    % Gain/Phase crossover lines
    plot(ax1, [wcp wcp], yMag, '--', 'Color', PM_color, 'LineWidth', 1.2);
    text(ax1, wcp, yMag(2)*0.82, sprintf('%.3f Hz', wcp), 'Color', PM_color, 'HorizontalAlignment','right');

    plot(ax1, [wcg wcg], [0 -GM], '-', 'Color', GM_color, 'LineWidth', 3);
    plot(ax1, [wcg wcg], yMag, '--', 'Color', GM_color, 'LineWidth', 1.2);
    text(ax1, wcg, yMag(2)*0.92, sprintf('%.3f Hz', wcg), 'Color', GM_color, 'HorizontalAlignment','left');
    text(ax1, wcg, -GM/2, sprintf(' %.1f dB', GM), 'Color', GM_color, 'FontSize', 14, 'HorizontalAlignment','left', 'VerticalAlignment','middle');

    plot(ax2, [wcp wcp], [-180 -180+PM], '-', 'Color', PM_color, 'LineWidth', 3);
    plot(ax2, [wcp wcp], yPh, '--', 'Color', PM_color, 'LineWidth', 1.2);
    text(ax2, wcp, -180 + PM/2, sprintf('%.1f° ', PM), 'Color', PM_color, 'FontSize', 14, 'HorizontalAlignment','right', 'VerticalAlignment','middle');

    plot(ax2, [wcg wcg], yPh, '--', 'Color', GM_color, 'LineWidth', 1.2);

    % --- Export ---
    figName = fullfile(reportFolder, sprintf('Scenario%d_Bode.fig', scenarioNum));
    savefig(fig, figName);
    exportgraphics(fig, reportPDF, 'ContentType','vector', 'Append', true);
    close(fig);
end