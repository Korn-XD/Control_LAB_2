% ==========================================
% 1. ตั้งค่าพารามิเตอร์ก่อนรัน (User Configuration)
% ==========================================
com_port = "COM5";  
baud_rate = 209700; 

% กำหนดค่าให้ตรงกับที่ตั้งไว้ใน C Code 
signal_type = 1;    % 1=Sine, 2=Ramp, 3=Manual
dt = 0.002;         % Sampling time (ถ้า > 0.001 กราฟจะแยกบน-ล่างอัตโนมัติ)

% แปลงตัวเลขประเภทสัญญาณเป็นข้อความ (แยกระหว่างชื่อบนกราฟ และชื่อไฟล์ให้ปลอดภัย)
if signal_type == 1
    title_sig = 'Sin(2Pi)';
    file_sig = 'Sin';
elseif signal_type == 2
    title_sig = 'Ramp';
    file_sig = 'Ramp';
else
    title_sig = 'Manual';
    file_sig = 'Manual';
end

% ==========================================
% 2. ล้างและเริ่มการเชื่อมต่อ Serial
% ==========================================
if exist('s', 'var')
    clear s;
end
old_ports = serialportfind;
if ~isempty(old_ports)
    delete(old_ports);
end

s = serialport(com_port, baud_rate);
configureTerminator(s, "LF");
flush(s);

% ==========================================
% 3. ตั้งค่าหน้าต่างกราฟ (Dynamic Subplot & Lock X-Axis)
% ==========================================
fig = figure('Name', sprintf('Real-time Motor HIL (dt = %g s)', dt), 'NumberTitle', 'off', 'WindowState', 'maximized');

if dt > 0.001
    % กรณี Sampling Time ช้า (dt > 0.001): แยกกราฟ Forward ออก
    
    % กราฟบน: วิธีที่เสถียร และ มอเตอร์จริง
    ax1 = subplot(2, 1, 1);
    title(sprintf('Motor Speed Comparison (Signal: %s, dt: %g s) \n Stable Methods & Real Motor (Signal: %s, dt: %g s)', title_sig, dt));
    line_real = animatedline(ax1, 'Color', '#EDB120', 'LineWidth', 2.0, 'DisplayName', 'Real Motor');
    line_bw = animatedline(ax1, 'Color', '#0072BD', 'LineWidth', 2.0, 'LineStyle', '--', 'DisplayName', 'Backward');
    line_tz = animatedline(ax1, 'Color', '#7E2F8E', 'LineWidth', 2.0, 'LineStyle', ':', 'DisplayName', 'Trapezoidal');
    legend(ax1, 'show', 'Location', 'best');
    grid(ax1, 'on'); 
    ylabel(ax1, 'Angular Velocity (rad/s)');
    xlim(ax1, [0 20]);
    
    % กราฟล่าง: วิธี Forward (ที่ไม่เสถียร)
    ax2 = subplot(2, 1, 2);
    title('Unstable Method (Forward Explicit)');
    line_fw = animatedline(ax2, 'Color', '#D95319', 'LineWidth', 1.5, 'DisplayName', 'Forward');
    legend(ax2, 'show', 'Location', 'best');
    grid(ax2, 'on'); 
    xlabel(ax2, 'Time (s)'); 
    ylabel(ax2, 'Angular Velocity (rad/s)');
    xlim(ax2, [0 20]); 
    
    linkaxes([ax1, ax2], 'x'); 
else
    % กรณี Sampling Time เร็ว (dt <= 0.001): กราฟเสถียรทั้งหมด รวมเป็นกราฟเดียว
    ax1 = axes(fig);
    title(sprintf('Motor Speed Comparison (Signal: %s, dt: %g s)', title_sig, dt));
    line_real = animatedline(ax1, 'Color', '#EDB120', 'LineWidth', 2.0, 'DisplayName', 'Real Motor');
    line_fw = animatedline(ax1, 'Color', '#D95319', 'LineWidth', 2.0, 'DisplayName', 'Forward');
    line_bw = animatedline(ax1, 'Color', '#0072BD', 'LineWidth', 2.0, 'LineStyle', '--', 'DisplayName', 'Backward');
    line_tz = animatedline(ax1, 'Color', '#7E2F8E', 'LineWidth', 2.0, 'LineStyle', ':', 'DisplayName', 'Trapezoidal');
    legend(ax1, 'show', 'Location', 'best');
    grid(ax1, 'on'); 
    xlabel(ax1, 'Time (s)'); 
    ylabel(ax1, 'Angular Velocity (rad/s)');
    xlim(ax1, [0 20]); 
end

disp('Waiting for data... Press User Button (PC13) on Nucleo to start.');

% ==========================================
% 4. ลูปอ่านข้อมูลแบบ Real-time
% ==========================================
data_log = [];

while true
    if s.NumBytesAvailable > 0
        str = readline(s);
        
        if isempty(str) || strlength(str) == 0
            continue;
        end
        
        if contains(str, "STOP")
            disp('Experiment Finished.');
            break;
        end
        
        data = str2double(split(str, ','));
        
        if length(data) == 6 && ~any(isnan(data))
            t_val = data(1);
            data_log = [data_log; data']; 
            
            % วาดกราฟ
            addpoints(line_real, t_val, data(3));
            addpoints(line_fw, t_val, data(4));
            addpoints(line_bw, t_val, data(5));
            addpoints(line_tz, t_val, data(6));
            
            drawnow limitrate;
        end
    end
end

% ==========================================
% 5. สร้างโฟลเดอร์แยกและบันทึกผลลัพธ์
% ==========================================
if ~isempty(data_log)
    % สร้างชื่อโฟลเดอร์จากเวลาปัจจุบัน (เช่น Exp_Sin_dt0.005_20240309_153000)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    folder_name = sprintf('Exp_%s_dt%g_%s', file_sig, dt, timestamp);
    
    % สร้างโฟลเดอร์
    mkdir(folder_name);
    
    % 1. บันทึก CSV เข้าไปในโฟลเดอร์ใหม่
    save_filename_csv = fullfile(folder_name, sprintf('data_%s_dt%g.csv', file_sig, dt));
    writematrix(data_log, save_filename_csv);
    
    % 2. บันทึกรูปภาพกราฟ (PNG ความละเอียด 300 DPI) เข้าไปในโฟลเดอร์ใหม่
    save_filename_img = fullfile(folder_name, sprintf('graph_%s_dt%g.png', file_sig, dt));
    exportgraphics(fig, save_filename_img, 'Resolution', 300);
    
    fprintf('Success! Data and Graph saved in folder: %s\n', folder_name);
else
    disp('Error: No data received.');
end