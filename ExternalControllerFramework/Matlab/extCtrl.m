clear; clc;

% Simulation & UDP setup
destIP   = "127.0.0.1";
destPort = 65000;
localPort = 65009;

udpSender = dsp.UDPSender('RemoteIPAddress', destIP, ...
                           'RemoteIPPort', destPort, ...,
                           'LocalIPPortSource', 'Property', ...
                           'LocalIPPort', localPort);

udpReceiver = dsp.UDPReceiver('LocalIPPort', localPort, ...
                              'RemoteIPAddress', destIP, ...
                              'MessageDataType', 'double', ...
                              'MaximumMessageLength', 12);

% Control variables
ctrlTime        = 0.0;
dtCtrl          = 0.05;
sim_idx         = 0;
prev_sim_idx    = 0;
send_ctrl = true;
no_meas_count = 0;

% Initial Control Command
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

switch TestWellMenu
    case 1
        OP.z_c0  = [0.4356; 0];
    case 2
        OP.z_c0  = [0.5871; 0];
    case 3
        OP.z_c0  = [0.5871; 0];
end

z_uA = OP.z_c0(1);
z_uB = OP.z_c0(2);
w_uA = 0; 
w_uB = 0;
E_ctrl = 0;

disp('Controller running... Ctrl+C to stop');
while true
    % 1) SEND CONTROL COMMAND
    if send_ctrl
        controlCmd = [sim_idx; z_uA; z_uB; w_uA; w_uB; E_ctrl];  % 6 doubles
        udpSender(controlCmd);
        send_ctrl = false;
    end
    
    % 2) RECEIVE MEASUREMENTS
    measurements = udpReceiver();
    if isempty(measurements)
        no_meas_count = no_meas_count +1;
        pause(0.001);
        if (no_meas_count >= 5000)
            sim_idx = 0;
            prev_sim_idx = 0;
            z_uA = OP.z_c0(1);
            z_uB = OP.z_c0(2);
            w_uA = 0; 
            w_uB = 0;
            E_ctrl = 0;
            send_ctrl = true;
            no_meas_count = 0;
        end
        continue;
    end
    t_sim    = measurements(1);
    sim_idx   = measurements(2);
    p_c_r     = measurements(3);
    p_c       = measurements(4);
    p_stp     = measurements(5);
    q_p       = measurements(6);
    q_bl      = measurements(7);
    q_c       = measurements(8);
    z_cA      = measurements(9);
    z_cB      = measurements(10);
    w_cA      = measurements(11);
    w_cB      = measurements(12);


    % 3) CONTROL LAW
    if sim_idx > prev_sim_idx
        K_p = -0.001;
        w_uA = K_p * (p_c_r - p_c);

        fprintf("\n[MEASUREMENT] t=%.4f, count=%d, p_c=%.4f, p_c_r=%.4f, p_stp=%.4f, q_p=%.4f, q_bl=%.4f, q_c=%.4f, z_cA=%.4f, z_cB=%.4f, w_cA=%.4f, w_cB=%.4f", ...
                t_sim, sim_idx, p_c, p_c_r, p_stp, q_p, q_bl, q_c, z_cA, z_cB, w_cA, w_cB);

        ctrlTime = ctrlTime + dtCtrl;
        prev_sim_idx = sim_idx;
        send_ctrl = true;
    end


end
