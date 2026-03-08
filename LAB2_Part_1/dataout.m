clc; close all;

% =========================================================================
% 1. รับค่าโหมดและความถี่จากผู้ใช้
% =========================================================================
fprintf('--- Motor Control Analysis ---\n');
mode_names = {'Step', 'Ramp', 'Sine', 'Stair', 'Chirp'};
mode_idx = input('กรุณาเลือกโหมดที่รัน (1-5): ');

if isempty(mode_idx) || mode_idx < 1 || mode_idx > 5
    my_mode_name = 'Unknown'; 
else
    my_mode_name = mode_names{mode_idx};
end

freq_val = input('กรุณาใส่ความถี่ที่ใช้ (Hz): ');
if isempty(freq_val), freq_val = 1000; end 

% =========================================================================
% 2. ดึงข้อมูลจาก Object 'out'
% =========================================================================
try
    if ~exist('out', 'var')
        error('ไม่พบตัวแปร "out" ใน Workspace');
    end

    data_fwd   = out.get('forward');
    data_bwd   = out.get('backward');
    data_trz   = out.get('trapizoid');
    data_real  = out.get('sim_speed');
    % ไม่ดึง data_volt ตามความต้องการใหม่

    fprintf('✅ ดึงข้อมูล Speed สำเร็จ! (Freq: %d Hz)\n', freq_val);
catch ME
    fprintf('\n❌ [ERROR]: %s\n', ME.message);
    return;
end

% =========================================================================
% 3. สร้าง Folder เก็บผลลัพธ์
% =========================================================================
if ~exist('Lab_Results', 'dir'), mkdir('Lab_Results'); end
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
save_path = fullfile('Lab_Results', sprintf('%s_%s_%dHz', timestamp, my_mode_name, freq_val));
mkdir(save_path);

% =========================================================================
% 4. พลอตกราฟเปรียบเทียบความเร็ว (Single Plot)
% =========================================================================
fig = figure('Name', ['Results: ' my_mode_name], 'Color', 'k', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
hold on;

% --- เงื่อนไขการพล็อต Forward Euler ---
if freq_val == 1000
    plot(data_fwd.Time, squeeze(data_fwd.Data), 'c-', 'LineWidth', 1.5, 'DisplayName', 'Forward Euler');
else
    % พล็อตเส้นว่าง (NaN) เพื่อให้ Legend ยังมีชื่อปรากฏตามรูปที่ 4
    plot(NaN, NaN, 'c-', 'LineWidth', 1.5, 'DisplayName', 'Forward Euler (Disabled)');
    fprintf('⚠️ ความถี่ %dHz: ไม่พล็อต Forward Euler เพื่อป้องกันกราฟหลอน\n', freq_val);
end

% --- พล็อตสัญญาณที่เหลือ ---
plot(data_bwd.Time, squeeze(data_bwd.Data), 'm-', 'LineWidth', 1.5, 'DisplayName', 'Backward Euler');
plot(data_trz.Time, squeeze(data_trz.Data), 'g-', 'LineWidth', 1.5, 'DisplayName', 'Trapezoid (Tustin)');
plot(data_real.Time, squeeze(data_real.Data), 'r--', 'LineWidth', 1.2, 'DisplayName', 'Real Speed (Hardware)');

% --- ปรับแต่งกราฟ (Dark Mode) ---
title(sprintf('Motor Speed Comparison: %s at %d Hz', my_mode_name, freq_val), 'Color', 'w', 'FontSize', 14);
xlabel('Time (s)', 'Color', 'w');
ylabel('Speed (rad/s)', 'Color', 'w');

legend('TextColor', 'w', 'Location', 'northeast', 'FontSize', 11);
grid on;
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.2);
hold off;

% =========================================================================
% 5. บันทึกไฟล์
% =========================================================================
saveas(fig, fullfile(save_path, 'Speed_Comparison.png'));
save(fullfile(save_path, 'Workspace_Data.mat'), 'out', 'my_mode_name', 'freq_val');

fprintf('--------------------------------------------------\n');
fprintf('✅ เสร็จสิ้น! บันทึกกราฟความเร็วที่: %s\n', save_path);