% =========================================================================
% Discretization Methods Visualization (Improved Version)
% =========================================================================
clear; close all; clc;

%% 1. กำหนดระบบ Continuous (Original System)
wn = 5;         % Natural Frequency
zeta = 0.3;     % Damping Ratio (ค่าน้อยเพื่อให้กราฟพุ่งเกิน จะได้เห็นชัด)
G_s = tf([wn^2], [1, 2*zeta*wn, wn^2]); % Transfer Function

%% 2. กำหนด Sampling Time
% เลือก Ts ให้เห็นผลต่างชัดเจน (Forward Euler จะเริ่มไม่เสถียรที่ Ts > 2*zeta/wn = 0.12s)
Ts = 0.08; 
fprintf('Sampling Time (Ts) = %.3f s (Stability Limit for Euler approx 0.12s)\n', Ts);

%% 3. สร้างระบบ Discrete (Discretization)
z = tf('z', Ts); % ตัวแปร z

% 3.1 Forward Euler: s = (z-1)/Ts
% *ข้อควรระวัง: วิธีนี้มักจะไม่เสถียร (Unstable) ถ้า Ts ใหญ่เกินไป*
s_fwd = (z-1)/Ts;
G_fwd = minreal((wn^2)/(s_fwd^2 + 2*zeta*wn*s_fwd + wn^2));



% 3.2 Backward Euler: s = (z-1)/(z*Ts)
% *ข้อสังเกต: วิธีนี้เสถียรมาก แต่กราฟจะดูอืดกว่าความเป็นจริง (Overdamped)*

s_bwd = (z-1)/(z*Ts);
G_bwd = minreal((wn^2)/(s_bwd^2 + 2*zeta*wn*s_bwd + wn^2));

% 3.3 Tustin (Bilinear): s = (2/Ts)*(z-1)/(z+1)
% *ข้อดี: แม่นยำที่สุดและรักษาความเสถียรได้ดี (กราฟเกาะเส้นจริงสุด)*

s_tus = (2/Ts)*(z-1)/(z+1);
G_tustin = minreal((wn^2)/(s_tus^2 + 2*zeta*wn*s_tus + wn^2));

%% 4. คำนวณผลตอบสนอง (Get Data)
% ใช้วิธีดึงค่า y, t ออกมาใส่ตัวแปรก่อน เพื่อความชัวร์ในการ Plot
t_final = 3;
[y_c, t_c] = step(G_s, t_final);         % Continuous Data
[y_fwd, t_fwd] = step(G_fwd, t_final);   % Forward Euler Data
[y_bwd, t_bwd] = step(G_bwd, t_final);   % Backward Euler Data
[y_tus, t_tus] = step(G_tustin, t_final);% Tustin Data

%% 5. สั่งวาดกราฟ (Manual Plotting)
figure('Name', 'Discretization Comparison', 'Color', 'w');
hold on; box on; grid on;

% 5.1 วาดเส้น Continuous (สีดำ ทึบ)
plot(t_c, y_c, 'w', 'LineWidth', 2, 'DisplayName', 'Continuous (Exact)');

% 5.2 วาดเส้น Discrete แบบขั้นบันได (Stairs)
stairs(t_fwd, y_fwd, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Forward Euler');
stairs(t_bwd, y_bwd, 'b-.', 'LineWidth', 1.5, 'DisplayName', 'Backward Euler');
stairs(t_tus, y_tus, 'g-',  'LineWidth', 1.5, 'DisplayName', 'Tustin (Best)');

% ตกแต่ง
xlabel('Time (s)'); 
ylabel('Amplitude');
title(['Step Response Comparison (Ts = ', num2str(Ts), ' s)']);
legend('Location', 'Best');

% เพิ่มเส้นอ้างอิงที่ 1 (Target)
yline(1, 'k:', 'HandleVisibility', 'off'); 

hold off;