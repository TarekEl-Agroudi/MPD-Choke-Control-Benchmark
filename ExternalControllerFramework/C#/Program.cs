using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;

namespace ExExtControl
{
    internal class Program
    {

        // user settings
        static ushort nPortOut = 65007;
        static ushort nPortIn = 65000;
        static byte[] ip = [127, 0, 0, 1];
        static double z_cA0;
        static double z_cB0;

        // ## CODE FOR CONTROLLER HERE
        static (double z_uA, double z_uB, double w_uA, double w_uB, double E_ctrl) DoControl(double t, double p_c_r, double p_c, double p_stp, double q_p, double q_bl, double q_c, double z_cA_m, double z_cB_m, double w_cA_m, double w_cB_m)
        {
            double K_p = -0.001;

            double z_uA = z_cA_m;
            double z_uB = z_cB_m;
            double w_uA = K_p * (p_c_r - p_c);
            double w_uB = w_cB_m;
            double E_ctrl = 0;
            return (z_cA_m, z_cB_m, w_uA, w_uB, E_ctrl);
        }

        // arcitecture for communication
        static UdpHandler _udp;
        static double[] controlCmd = new double[6];
        static double[] measurements = new double[12];
        static byte[] bytesOut = new byte[6 * 8];
        static bool bMsgIn = false;

        static void Main(string[] args)
        {
            // --- Select Test Well ---
            Console.WriteLine("\n--- Select Test Well ---");
            Console.WriteLine("[1] BM01 Land");
            Console.WriteLine("[2] BM02 Deepwater MPD");
            Console.WriteLine("[3] BM03 Deepwater CML");
            Console.WriteLine("------------------------");

            int selection = 0;
            while (true)
            {
                Console.Write("Enter number for test well: ");
                if (int.TryParse(Console.ReadLine(), out selection) && selection >= 1 && selection <= 3)
                {
                    break;
                }
                Console.WriteLine("Invalid selection. Please enter 1, 2, or 3.");
            }

            string wellName = "";
            if (selection == 1)
            {
                wellName = "BM01 Land";
                z_cA0 = 0.4356;
                z_cB0 = 0.0;
            }
            else
            {
                // BM02 or BM03
                wellName = selection == 2 ? "BM02 Deepwater MPD" : "BM03 Deepwater CML";
                z_cA0 = 0.5871;
                z_cB0 = 0.0;
            }
            Console.WriteLine($"Selected well: {wellName}");
            // ------------------------

            _udp = new UdpHandler(nPortOut);  // set port 
            _udp.DataReceived += _udp_DataReceived;
            var ksim = new IPEndPoint(new IPAddress(ip), nPortIn);
            int sim_idx = 0;

            double z_uA = z_cA0;
            double z_uB = z_cB0;
            double w_uA = 0;
            double w_uB = 0;
            double E_ctrl = 0;

            var _dtLastSendt = DateTime.Now;

            _udp.Start();
            while (true)
            {
                controlCmd[0] = sim_idx;
                controlCmd[1] = z_uA;
                controlCmd[2] = z_uB;
                controlCmd[3] = w_uA;
                controlCmd[4] = w_uB;
                controlCmd[5] = E_ctrl;

                Buffer.BlockCopy(controlCmd, 0, bytesOut, 0, sizeof(double) * controlCmd.Length);
                _udp.SendTo(bytesOut, ksim);
                _dtLastSendt = DateTime.Now;

                // receive messages
                while (!bMsgIn)
                {
                    if ((DateTime.Now - _dtLastSendt).TotalMilliseconds > 5000)
                    {
                        Console.WriteLine($"Over 5 seconds since last interaction. Initiating new control test (index 0).");

                        sim_idx = 0;
                        z_uA = z_cA0;
                        z_uB = z_cB0;
                        w_uA = 0.0;
                        w_uB = 0.0;
                        E_ctrl = 0;

                        controlCmd[0] = sim_idx;
                        controlCmd[1] = z_uA;
                        controlCmd[2] = z_uB;
                        controlCmd[3] = w_uA;
                        controlCmd[4] = w_uB;
                        controlCmd[5] = E_ctrl;

                        Buffer.BlockCopy(controlCmd, 0, bytesOut, 0, sizeof(double) * controlCmd.Length);
                        _udp.SendTo(bytesOut, ksim);
                        _dtLastSendt = DateTime.Now;
                    }
                }
                bMsgIn = false;

                var t_sim = measurements[0];
                sim_idx = Convert.ToInt32(measurements[1]);
                double p_c_r = measurements[2];
                double p_c = measurements[3];
                double p_stp = measurements[4];
                double q_p = measurements[5];
                double q_bl = measurements[6];
                double q_c = measurements[7];
                double z_cA_m = measurements[8];
                double z_cB_m = measurements[9];
                double w_cA_m = measurements[10];
                double w_cB_m = measurements[11];

                if (sim_idx % 1000 == 0)
                {
                    Console.WriteLine($"######################");
                    Console.WriteLine($"t    : {t_sim}");
                    Console.WriteLine($"p_c  : {p_c}");
                    Console.WriteLine($"p_c_r: {p_c_r}");
                }

                // compute control          
                (z_uA, z_uB, w_uA, w_uB, E_ctrl) = DoControl(t_sim, p_c_r, p_c, p_stp, q_p, q_bl, q_c, z_cA_m, z_cB_m, w_cA_m, w_cB_m);
            }
        }

        private static void _udp_DataReceived(byte[] arg1, EndPoint arg2)
        {
            Buffer.BlockCopy(arg1, 0, measurements, 0, arg1.Length);
            bMsgIn = true;
        }
    }


    #region UDP HANDLER
    public class UdpHandler : IDisposable
    {
        private const int RECEIVE_BUFFER_SIZE = 1024 * 1024; // 1MB
        private const int SHUTDOWN_TIMEOUT_MS = 2000;

        private Socket _socket;
        private Thread _receiveThread;
        private EndPoint _lastSender;
        private readonly object _senderLock = new object();
        private volatile bool _isRunning;
        private readonly ushort _port;
        public event Action<byte[], EndPoint> DataReceived;
        public event Action Started;
        public event Action Stopped;
        public event Action<string> Error;

        public bool IsRunning => _isRunning;
        public ushort Port => _port;
        public EndPoint LastSender
        {
            get
            {
                lock (_senderLock)
                {
                    return _lastSender;
                }
            }
        }

        public UdpHandler(ushort port)
        {
            _port = port;
        }

        public void Start()
        {
            if (_isRunning)
            {
                throw new InvalidOperationException("UDP handler is already running");
            }

            try
            {
                CreateAndBindSocket();
                InitializeLastSender();
                StartReceiveThread();
                Started?.Invoke();
            }
            catch (Exception ex)
            {
                _isRunning = false;
                Error?.Invoke($"Failed to start UDP listener on port {_port}: {ex.Message}");
                throw;
            }
        }

        public void Stop()
        {
            if (!_isRunning)
            {
                return;
            }

            _isRunning = false;
            _socket?.Close();
            _receiveThread?.Join(SHUTDOWN_TIMEOUT_MS);
            Stopped?.Invoke();
        }

        public bool SendToLastSender(byte[] data)
        {
            EndPoint target;
            lock (_senderLock)
            {
                target = _lastSender;
            }

            if (!IsValidSender(target))
            {
                Error?.Invoke("Cannot send UDP: No sender received yet");
                return false;
            }

            return SendTo(data, target);
        }

        public bool SendTo(byte[] data, EndPoint target)
        {
            if (!_isRunning)
            {
                Error?.Invoke("Cannot send: UDP handler is not running");
                return false;
            }

            try
            {
                _socket.SendTo(data, target);
                return true;
            }
            catch (Exception ex)
            {
                Error?.Invoke($"UDP Send error to {target}: {ex.Message}");
                return false;
            }
        }

        public void Dispose()
        {
            Stop();
            _socket?.Dispose();
        }

        private void CreateAndBindSocket()
        {
            var endpoint = new IPEndPoint(IPAddress.Any, _port);
            _socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            _socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
            _socket.ReceiveBufferSize = RECEIVE_BUFFER_SIZE;
            _socket.Bind(endpoint);
        }

        private void InitializeLastSender()
        {
            lock (_senderLock)
            {
                _lastSender = new IPEndPoint(IPAddress.Any, 0);
            }
        }

        private void StartReceiveThread()
        {
            _isRunning = true;
            _receiveThread = new Thread(ReceiveLoop)
            {
                Name = $"UDP-Recv-{_port}",
                IsBackground = true
            };
            _receiveThread.Start();
        }

        private bool IsValidSender(EndPoint sender)
        {
            return sender != null && sender is IPEndPoint ep && ep.Port != 0;
        }

        private void ReceiveLoop()
        {
            byte[] buffer = new byte[RECEIVE_BUFFER_SIZE];

            while (_isRunning)
            {
                try
                {
                    EndPoint sender = new IPEndPoint(IPAddress.Any, 0);
                    int bytesReceived = _socket.ReceiveFrom(buffer, ref sender);

                    UpdateLastSender(sender);
                    byte[] data = CopyReceivedData(buffer, bytesReceived);
                    DataReceived?.Invoke(data, sender);
                }
                catch (SocketException ex) when (IsExpectedShutdownException(ex))
                {
                    break;
                }
                catch (ObjectDisposedException)
                {
                    break;
                }
                catch (Exception ex) when (_isRunning)
                {
                    Console.WriteLine($"UDP Receive error: {ex.Message}");
                }
            }
        }

        private void UpdateLastSender(EndPoint sender)
        {
            lock (_senderLock)
            {
                _lastSender = sender;
            }
        }

        private byte[] CopyReceivedData(byte[] buffer, int length)
        {
            byte[] data = new byte[length];
            Array.Copy(buffer, 0, data, 0, length);
            return data;
        }

        private bool IsExpectedShutdownException(SocketException ex)
        {
            return ex.SocketErrorCode == SocketError.Interrupted ||
                   ex.SocketErrorCode == SocketError.ConnectionReset;
        }
    }
    #endregion
}