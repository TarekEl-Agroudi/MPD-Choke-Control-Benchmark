
function generateBenchmarkReport(Results, scenarioNames, OP, selectedWell, selectedCtrl, reportFolder, theme)
    plotForArticle = 0;

     % --- Define themes ---
    themes.dark.fig_bg     = [0.1 0.1 0.1];
    themes.dark.axes_bg    = [0.15 0.15 0.15];
    themes.dark.axes_grid  = [0.5 0.5 0.5];
    themes.dark.text_col   = [1 1 1];
    themes.dark.legend_bg  = [0.2 0.2 0.2];
    themes.dark.lineColors = [0.2 0.7 0.9; 0.9 0.8 0.2; 0.9 0.3 0.2; 0.6 0.4 0.8];

    themes.light.fig_bg     = [1 1 1];
    themes.light.axes_bg    = [1 1 1];
    themes.light.axes_grid  = [0.8 0.8 0.8];
    themes.light.text_col   = [0 0 0];
    if ~plotForArticle
        themes.light.legend_bg  = [0.9 0.9 0.9];
    else
        themes.light.legend_bg  = [1 1 1];
    end
    themes.light.lineColors = [0 0.4470 0.7410;  0.9290 0.6940 0.1250; 0.8500 0.3250 0.0980; 0.4940 0.1840 0.5560];

    if strcmp(theme,'dark')
        th = themes.dark;
    else
        th = themes.light;
    end

    set(0,'DefaultFigureWindowStyle','normal');
   
    if ~plotForArticle
        linew_main = 1.5;
        linew_secondary = 0.8;
    else
        linew_main = 1;
        linew_secondary = 1;
    end

    % --- KPI mapping ---
    kpi_map = containers.Map( ...
        {'AvgRiseTime','AvgSettlingTime','MaxOvershoot','RMSE', ...
        'MaxError', 'Trapped', 'GM','PM','wcg', ...
        'wcp', 'IAW', 'IAA', 'xRT'}, ...
        {'Avg. Rise Time [s]', 'Avg. Settling Time [s]', 'Max Overshoot [psi]', 'RMSE [psi]', ...
         'Max Error [psi]', 'Pressure lost [psi]', 'Gain Margin [dB]', 'Phase Margin [deg]', 'Phase crossover [Hz]', ...
         'Gain crossover [Hz]', 'Choke Vel. (IAW)', 'Choke Acc. (IAA)', 'xRT [-]'} ...
    );

    % --- Export KPIs first page ---
    reportPDF = fullfile(reportFolder, sprintf('BenchmarkReport_%s_%s.pdf', selectedWell, selectedCtrl));
    exportKPIsAsFirstPage(Results, [], kpi_map, scenarioNames, selectedWell, selectedCtrl, reportPDF, th)

    % --- Loop through scenarios ---
    for i = 1:numel(Results)
        simOut = Results(i).SimOut;
        scenarioNum = Results(i).Scenario;
        scenarioName = scenarioNames{scenarioNum};

        % --- KPI text ---
        KPI = Results(i).KPI;
        kpiFields = fieldnames(KPI);
        kpiText = '';
        for k = 1:numel(kpiFields)
            kName = kpiFields{k};
            if isKey(kpi_map, kName), kDisp = kpi_map(kName); else kDisp = kName; end
            val = KPI.(kName);
            if isnumeric(val) && isscalar(val)
                kpiText = [kpiText sprintf('%s: %.4g  |  ', kDisp, val)];
            end
        end
        if ~isempty(kpiText), kpiText = kpiText(1:end-5); end

        % --- Create figure ---
        fig = figure('Visible','on','Units','pixels','Position',[100 100 794 1123], ...
                     'Color', th.fig_bg, 'InvertHardcopy','off');
        
        if ~plotForArticle
            sgtitle(sprintf('Scenario %d: %s', scenarioNum, scenarioName), ...
                    'FontSize',14,'FontWeight','bold','Color', th.text_col);
    
            % --- Annotations ---
        
            annotation(fig,'textbox',[0.1 0.9 0.8 0.02], ...
                'String',sprintf('Test Well: %s    |    Controller: %s', strrep(selectedWell, '_', '\_'), strrep(selectedCtrl, '_', '\_')), ...
                'HorizontalAlignment','center','FontSize',10,'LineStyle','none', ...
                'Color', th.text_col, 'BackgroundColor', th.legend_bg);
    
            if ~isempty(kpiText)
                annotation(fig,'textbox',[0.1 0.85 0.8 0.04], ...
                    'String',kpiText,'HorizontalAlignment','center','VerticalAlignment','middle', ...
                    'FontSize',10,'LineStyle','none','Color', th.text_col,'BackgroundColor', th.legend_bg);
            end
        end
        % --- Plot layout ---
        left_margin = 0.1; right_margin = 0.9;
        bottom_margin = 0.08; top_margin = 0.82;
        plot_spacing = 0.02; nPlots = 4;
        plot_height = (top_margin - bottom_margin - (nPlots-1)*plot_spacing)/nPlots;
        switch scenarioNum
            case {1}
                p_c_min = 0;
                p_c_max = 6*OP.p_c0;
                q_max = 2*(OP.q_p0 + OP.q_bl_nom);
                q_min = -5;
            case {2,6}
                p_c_min = 0.8*OP.p_c0;
                p_c_max = 1.2*OP.p_c0;
                q_max = 1.5*(OP.q_p0 + OP.q_bl_nom);
                q_min = -5;
            case 3
                p_c_min = 0.7*OP.p_c0;
                p_c_max = 1.3*OP.p_c0;
                q_max = 1.5*(OP.q_p0 + OP.q_bl_nom);
                q_min = -5;
            case {4, 5}
                p_c_min = 0;
                p_c_max = OP.p_c0 + OP.p_fric + 10;
                q_max = 1.5*(OP.q_p0 + OP.q_bl_nom);
                q_min = -5;
            case 7
                p_c_min = OP.p_c0 + OP.p_fric - 2;
                p_c_max = OP.p_c0 + OP.p_fric + 2;
                q_max = 1.5*(OP.q_p0 + OP.q_bl_nom);
                q_min = -5;
        end

        % Pressure
        ax1 = axes('Position',[left_margin, bottom_margin + 3*(plot_height+plot_spacing), right_margin-left_margin, plot_height], ...
                   'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, 'GridColor', th.axes_grid, 'GridAlpha',0.3);
        hold(ax1,'on'); grid(ax1,'on');
        if scenarioNum == 6 || scenarioNum == 7
            plotTimeseries(ax1, simOut.tout, simOut.p_c_r.Data(:), linew_secondary, '--', th.lineColors(2,:));
            plotTimeseries(ax1, simOut.tout(), simOut.p_c.Data(:), linew_main, '-', th.lineColors(1,:));
        else
            plotTimeseries(ax1, simOut.tout(), simOut.p_c.Data(:), linew_main, '-', th.lineColors(1,:));
            plotTimeseries(ax1, simOut.tout, simOut.p_c_r.Data(:), linew_secondary, '--', th.lineColors(2,:));
        end
        ylabel(ax1,'p_c [bar]'); legend(ax1,{'p_c','p_c^r'}, 'TextColor', th.text_col, 'Color', th.legend_bg); set(ax1,'FontSize',9);
        ylim(ax1, [p_c_min p_c_max]);

        % Flow
        ax2 = axes('Position',[left_margin, bottom_margin + 2*(plot_height+plot_spacing), right_margin-left_margin, plot_height], ...
                   'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, 'GridColor', th.axes_grid, 'GridAlpha',0.3);
        hold(ax2,'on'); grid(ax2,'on');
        plotTimeseries(ax2, simOut.tout, simOut.q_p.Data(:), linew_main, '-', th.lineColors(1,:));
        plotTimeseries(ax2, simOut.tout, simOut.q_bl.Data(:), linew_secondary, '-', th.lineColors(2,:));
        plotTimeseries(ax2, simOut.tout, simOut.q_c.Data(:), linew_secondary, '-', th.lineColors(3,:));
        ylabel(ax2,'Flow [lps]'); legend(ax2,{'q_p','q_{bl}','q_{c}'}, 'TextColor', th.text_col, 'Color', th.legend_bg); set(ax2,'FontSize',9);
        ylim(ax2, [q_min q_max]);

        % Actuator Pos
        ax3 = axes('Position',[left_margin, bottom_margin + 1*(plot_height+plot_spacing), right_margin-left_margin, plot_height], ...
                   'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, 'GridColor', th.axes_grid, 'GridAlpha',0.3);
        hold(ax3,'on'); grid(ax3,'on');
        plotTimeseries(ax3, simOut.tout, simOut.z_cA.Data(:), linew_main, '-', th.lineColors(1,:));
        plotTimeseries(ax3, simOut.tout, simOut.z_cB.Data(:), linew_main, '-', th.lineColors(2,:));
        ylabel(ax3,'z_c [%]');  legend(ax3,{'z_{cA}','z_{cB}'}, 'TextColor', th.text_col, 'Color', th.legend_bg); set(ax3,'FontSize',9);
        ylim(ax3, [-0.1 1.1]);

        % Actuator Vel
        ax4 = axes('Position',[left_margin, bottom_margin, right_margin-left_margin, plot_height], ...
                   'Color', th.axes_bg, 'XColor', th.text_col, 'YColor', th.text_col, 'GridColor', th.axes_grid, 'GridAlpha',0.3);
        hold(ax4,'on'); grid(ax4,'on');
        plotTimeseries(ax4, simOut.tout, simOut.w_cA.Data(:), linew_main, '-', th.lineColors(1,:));
        plotTimeseries(ax4, simOut.tout, simOut.w_cB.Data(:), linew_main, '-', th.lineColors(2,:));
        ylabel(ax4,'w_c [%/s]');  legend(ax4,{'w_{cA}','w_{cB}'}, 'TextColor', th.text_col, 'Color', th.legend_bg); set(ax4,'FontSize',9);
        xlabel(ax4,'Time [s]');
        ylim(ax4, [-0.21 0.21]);

        figName = fullfile(reportFolder, sprintf('Scenario%d_Page.fig', scenarioNum));
        savefig(fig, figName);
        exportgraphics(fig,reportPDF,'ContentType','vector','Append',true);
        close(fig);

        % --- Bode plots for scenario 6 & 7 ---
        if scenarioNum == 6 || scenarioNum == 7
            plotBenchmarkBode(Results(i).KPI, th,  reportFolder, reportPDF, scenarioNum);
        end
    end

    fprintf('PDF report generated: %s\n', reportPDF);
end
