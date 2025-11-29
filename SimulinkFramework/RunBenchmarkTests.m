% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Purpose:
% Created:
%   06-11-2025, Tarek El-Agroudi
%
% Modified:
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clear all; disp('workspace cleared');
scriptDir = fileparts(mfilename('fullpath'));

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Select Tests, Well, Controller and Reporting
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
scenarioNames = { ...
    'T1 Pressure Steps', ...
    'T2 Downlinking', ...
    'T3 Flow Ramps', ...
    'T4 Connection', ...
    'T5 Shut-off + Ramp-up', ...
    'T6 Stability Margins, Nominal OP', ...
    'T7 Stability Margins, Connection OP'
    };
[selectedScenarios, ok] = listdlg( ...
    'PromptString','Select scenario(s) to run:', ...
    'SelectionMode','multiple', ...
    'ListString',scenarioNames, ...
    'ListSize',[300 200]);
if ~ok
    error('No scenarios selected.');
end
ScenariosToRun = selectedScenarios;
disp(['Selected scenarios: ', strjoin(scenarioNames(ScenariosToRun), ', ')]);

wellNames = { ...
    'BM01 Land', ...
    'BM02 Deepwater MPD', ...
    'BM03 Deepwater CML'};
[selectedWell, ok] = listdlg( ...
    'PromptString','Select test well:', ...
    'SelectionMode','single', ...
    'ListString',wellNames, ...
    'ListSize',[300 100]);
if ~ok
    error('No test well selected.');
end
TestWellMenu = selectedWell;
disp(['Selected well: ', wellNames{TestWellMenu}]);


controllersDir = fullfile(scriptDir, 'controllers');
controllerFiles = dir(fullfile(controllersDir, '*.slx'));
if isempty(controllerFiles)
    error('No controller models found in "%s".', controllersDir);
end
controllerNames = {controllerFiles.name};
[selectedController, ok] = listdlg( ...
    'PromptString','Select controller to use:', ...
    'SelectionMode','single', ...
    'ListString',controllerNames, ...
    'ListSize',[300 150]);
if ~ok
    error('No controller selected.');
end
SelectedControllerFile = fullfile(controllersDir, controllerNames{selectedController});
[~, SelectedControllerName, ~] = fileparts(SelectedControllerFile);
disp(['Selected controller: ', SelectedControllerName]);


generateReport = questdlg( ...
    'Do you want to generate a report after running the scenarios?', ...
    'Generate Report', ...
    'Yes (Dark Theme)', 'Yes (Light Theme)', 'No', 'No');
switch generateReport
    case 'Yes (Dark Theme)'
        GenerateReportFlag = true;
        theme = 'dark';
        disp('Report generation enabled.');
    case 'Yes (Light Theme)'
        GenerateReportFlag = true;
        theme = 'light';
        disp('Report generation enabled.');
    case 'No'
        GenerateReportFlag = false;
        disp('Report generation disabled.');
    otherwise
        error('Operation cancelled by user.');
end


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Operating Point [bar, lps]
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
switch TestWellMenu
    case 1
        OP.q_p0  = 33.33; 
        OP.q_bl_nom = 0;
        OP.q_bl_con = 8.3333; 
        OP.p_c0  = 2.5;
        OP.z_c0  = [0.4356; 0];
        OP.t_ramp = 30;
        OP.p_fric = 45;
    case 2
        OP.q_p0  = 50.4722;
        OP.q_bl_nom = 25.2361;
        OP.q_bl_con = 25.2361;
        OP.p_c0  = 6.8950;
        OP.z_c0  = [0.5871; 0];
        OP.t_ramp = 60;
        OP.p_fric = 50;
    case 3
        OP.q_p0  = 50.4722;
        OP.q_bl_nom = 25.2361;
        OP.q_bl_con = 25.2361;
        OP.p_c0  = 6.8950;
        OP.z_c0  = [0.5871; 0];
        OP.t_ramp = 60;
        OP.p_fric = 60;
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Simulation Model
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dtSim = 0.01;
HarnessModel = 'BenchmarkTestHarness';
switch TestWellMenu
    case 1
        fmuPath = fullfile(scriptDir, 'fmu', 'BM01_Land.fmu');
    case 2
        fmuPath = fullfile(scriptDir, 'fmu', 'BM02_DeepwaterMPD.fmu');
    case 3
        fmuPath = fullfile(scriptDir, 'fmu', 'BM03_DeepwaterCML.fmu');
end
destFMU = fullfile(scriptDir, 'fmu', 'SelectedFMU.fmu');
copyfile(fmuPath, destFMU, 'f');

if exist(HarnessModel) == 4
    close_system(HarnessModel, 0);
end
open_system(HarnessModel)

controllerBlockPath = [HarnessModel '/Controller'];
try
    set_param(controllerBlockPath, 'ModelName', SelectedControllerName);
    disp(['Linked controller "', SelectedControllerName, '" to block "', controllerBlockPath, '".']);
catch ME
    warning('Failed to link controller model: %s\nError: %s', SelectedControllerName, ME.message);
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Run Tests
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Results = struct();

for i = 1:length(ScenariosToRun)
    fprintf('\nRunning Scenario %d...\n', ScenariosToRun(i));
    [U, tEnd] = setupScenario(ScenariosToRun(i), dtSim, OP);

    tic;
    simOut = sim(HarnessModel, 'StopTime', num2str(tEnd));
    time2sim = toc;
    xRT = tEnd/time2sim;
    
    KPI = computeKPI(simOut, ScenariosToRun(i), OP); 
    KPI.xRT = xRT;
    Results(i).Scenario = ScenariosToRun(i);
    Results(i).KPI = KPI;
    Results(i).SimOut = simOut;
end
%% Run from here to only generate report.
displayKPIs(Results, scenarioNames);
folderName = sprintf('Benchmark_%s_%s', wellNames{TestWellMenu}, SelectedControllerName);
reportDir = fullfile(scriptDir, 'reports');
reportFolder = fullfile(reportDir, folderName);
if ~exist(reportFolder, 'dir')
    mkdir(reportFolder);
end

save(fullfile(reportFolder, 'Results.mat'), 'Results');

if GenerateReportFlag
    generateBenchmarkReport(Results, scenarioNames, OP, wellNames{TestWellMenu}, SelectedControllerName, reportFolder, theme);
    reportPDF = fullfile(reportFolder, sprintf('BenchmarkReport_%s_%s.pdf', wellNames{TestWellMenu}, SelectedControllerName));
    if ispc
        winopen(reportPDF);
    elseif ismac
        system(['open ', reportPDF]);
    elseif isunix
        system(['xdg-open ', reportPDF]);
    end
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Benchmark test scenarios
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function [U, tEnd] = setupScenario(ScenarioMenu, dtSim, OP)
    waitTime = 100;
    switch ScenarioMenu
        case 1 % Pressure Steps
            stepDur = 100;
            mults = [1.5, 1, 3, 1, 5, 1];
            times = waitTime;
            values = OP.p_c0;
            for k = 1:numel(mults)
                tStart = waitTime + (k-1)*stepDur;
                tEnd   = waitTime + k*stepDur;
                times  = [times, tStart, tEnd];
                values = [values, mults(k)*OP.p_c0, mults(k)*OP.p_c0];
            end
            U.q_p = timeseries(OP.q_p0*ones(size(times)), times);
            U.q_bl = timeseries(OP.q_bl_nom*ones(size(times)), times);
            U.p_c_r = timeseries(values, times);
            tEnd = times(end);
    
        case 2 %  Downlinking
            stepDur = [20, 15, 20, 5, 10, 15, 20, 5, 10, 5, 10, 5, 10, 20, 20, 5, 10, 10, 5, 20, 45];
            rampDur = 5;
            mults = [0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 0.7500, 1, 1];
            times = waitTime;
            qVals = OP.q_p0;

            for k = 1:numel(mults)
                tStart = times(end);
                tEnd   = tStart + rampDur + stepDur(k);
                times  = [times, tStart, tStart + rampDur, tEnd];
                if k == 1
                    qVals  = [qVals, OP.q_p0, mults(k)*OP.q_p0, mults(k)*OP.q_p0];
                else
                    qVals  = [qVals, mults(k-1)*OP.q_p0, mults(k)*OP.q_p0, mults(k)*OP.q_p0];
                end
            end
            U.q_p = timeseries(qVals, times);
            U.q_bl = timeseries(OP.q_bl_nom*ones(size(times)), times);
            U.p_c_r = timeseries(OP.p_c0*ones(size(times)), times);
            tEnd = times(end);
    
        case 3 % Flow Ramps
            q_bl_times = [0, waitTime/2];
            q_bl_vals = [OP.q_bl_nom, OP.q_bl_con];

            t_ramp = OP.t_ramp;
            q_p_times = [0, waitTime];
            rampTimes = waitTime + [0, t_ramp, 2*t_ramp, 2.1*t_ramp, 2.5*t_ramp, 3.4*t_ramp, 4.4*t_ramp];
            q_p_times = [q_p_times, rampTimes];
            q_p_vals = [OP.q_p0, OP.q_p0, OP.q_p0, 0, 0, OP.q_p0/10, OP.q_p0/10, OP.q_p0, OP.q_p0];

            U.q_p = timeseries(q_p_vals, q_p_times);
            U.q_bl = timeseries(q_bl_vals, q_bl_times);
            U.p_c_r = timeseries(OP.p_c0);

            tEnd = max([U.q_p.Time(end), U.q_bl.Time(end), U.p_c_r.Time(end)]);

    
        case 4 % Connection
            t_ramp = OP.t_ramp;
            p_fric = OP.p_fric;

            q_bl_times = [0, waitTime/2];
            q_bl_vals = [OP.q_bl_nom, OP.q_bl_con];

            q_p_times = [0, waitTime];
            rampTimes = waitTime + [0, t_ramp, 2*t_ramp, 2.1*t_ramp, 2.5*t_ramp, 3.4*t_ramp, 4.4*t_ramp];
            q_p_times = [q_p_times, rampTimes];
            q_p_vals = [OP.q_p0, OP.q_p0, OP.q_p0, 0, 0, OP.q_p0/10, OP.q_p0/10, OP.q_p0, OP.q_p0];
            
            p_c_times = q_p_times;
            p_c_vals = OP.p_c0 + [0, 0, 0, p_fric, p_fric, p_fric, p_fric, 0, 0];

            U.q_p = timeseries(q_p_vals, q_p_times);
            U.q_bl = timeseries(q_bl_vals, q_bl_times);
            U.p_c_r = timeseries(p_c_vals, p_c_times);
            
            tEnd = max([U.q_p.Time(end), U.q_bl.Time(end), U.p_c_r.Time(end)]);

        case 5 % Pressure Trapping
            t_ramp = OP.t_ramp;
            p_fric = OP.p_fric;

            q_bl_times = [0, waitTime, waitTime + 15];
            q_bl_vals = [OP.q_bl_nom, OP.q_bl_nom, 0];

            q_p_times = waitTime + [-waitTime, 0, 15, 4*t_ramp, 5*t_ramp, 6*t_ramp];
            q_p_vals = [OP.q_p0, OP.q_p0, 0, 0,  OP.q_p0, OP.q_p0];
            
            p_c_times = q_p_times;
            p_c_vals = OP.p_c0 + [0, 0, p_fric, p_fric, 0, 0];

            U.q_p = timeseries(q_p_vals, q_p_times);
            U.q_bl = timeseries(q_bl_vals, q_bl_times);
            U.p_c_r = timeseries(p_c_vals, p_c_times);
            
            tEnd = max([U.q_p.Time(end), U.q_bl.Time(end), U.p_c_r.Time(end)]);
    
        case 6 % Pressure Reference Chirp Nominal OP
            times_wait = [0, waitTime];
            q_wait = OP.q_p0*ones(size(times_wait));
            qb_wait = OP.q_bl_nom*ones(size(times_wait));
    
            [p_c_r, t_sim] = linearChirp(dtSim, OP.p_c0, 0.1, 100, 1000);
            t_sim = t_sim + waitTime;
    
            times = [times_wait, t_sim];
            qVals = [q_wait, OP.q_p0*ones(size(t_sim))];
            qblVals = [qb_wait, OP.q_bl_nom*ones(size(t_sim))];
    
            U.q_p   = timeseries(qVals, times);
            U.q_bl  = timeseries(qblVals, times);
            U.p_c_r = p_c_r;
    
            tEnd = times(end);

        case 7 %Pressure Reference Chirp Connection OP
            t_ramp = OP.t_ramp;
            p_fric = OP.p_fric;

            q_bl_times = [0, waitTime/2];
            q_bl_vals = [OP.q_bl_nom, OP.q_bl_con];

            q_p_times = [0, waitTime, waitTime+t_ramp, waitTime+2*t_ramp];
            q_p_vals = [OP.q_p0, OP.q_p0, 0, 0];
            
            p_c_times = q_p_times;
            p_c_vals = OP.p_c0 + [0, 0, p_fric, p_fric];
            chirp = linearChirp(dtSim, OP.p_c0+p_fric, 0.1, 500, 1000);
            p_c_vals = [p_c_vals(:); chirp.Data(:)];
            p_c_times = [p_c_times(:); p_c_times(end) + chirp.Time];
            
            U.q_p   = timeseries(q_p_vals, q_p_times);
            U.q_bl = timeseries(q_bl_vals, q_bl_times);
            U.p_c_r = timeseries(p_c_vals, p_c_times);

            tEnd = max([U.q_p.Time(end), U.q_bl.Time(end), U.p_c_r.Time(end)]);   
    end
    assignAllVariables()
end
