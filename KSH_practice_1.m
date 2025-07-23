% demo_satellite_iceye.m
% 위성 SAR 시뮬레이션 (ICEYE 유사 조건)
clear all; close all; clc;

%% Radar parameters
fc = 9.65e9;       % [Hz] 중심 주파수 (X-band)
B = 150e6;         % [Hz] 대역폭
T = 40e-6;         % [s] 펄스 길이

%% Constants
c = 3e8;           % [m/s] 빛의 속도

%% Imaging parameters
start_range = 400e3;   % [m] 시작 거리 (위성-지표 거리)
end_range = 600e3;     % [m] 최대 거리
cell_size = c / (2 * B) / 3;  % [m] 거리 셀 크기 (약 1 m)
sampling_density = cell_size;

%% Scene definition (지표면 근처)
point = [
    0, 0, 0, 0.8, 0;
    500, 500, 0, 1, pi/3;
];

vertex = [
    -500,-500,0;
    -500,-500,50;
    -500,500,50;
    -500,500,0;
    -1000,-250,5;
    -1000,-250,55;
    -1000,250,55;
    -1000,250,5;
];

face(1).v = [1,2,3];  face(2).v = [3,4,1];
[face(1:2).transparency] = deal(0.5);
[face(1:2).roughness] = deal(0.8);
[face(1:2).magnitude] = deal(0.8);
[face(1:2).phase] = deal(0);

face(3).v = [5,6,7];  face(4).v = [7,8,5];
[face(3:4).transparency] = deal(0.1);
[face(3:4).roughness] = deal(0.1);
[face(3:4).magnitude] = deal(0.5);
[face(3:4).phase] = deal(0);

%% Antenna trajectory definition (위성 궤도)
num_lines = 500;
tmp_y = linspace(-25e3, 25e3, num_lines).';  % [m] azimuth line
sat_alt = 500e3;  % [m] 고도
graz_angle = 30;  % [deg] 사선각

tmp_dir_y = 0;
tmp_dir_x = cosd(-graz_angle);
tmp_dir_z = sind(-graz_angle);

tx_pos = [-50 * ones(size(tmp_y)), tmp_y, sat_alt * ones(size(tmp_y)), ...
          tmp_dir_x * ones(size(tmp_y)), tmp_dir_y * ones(size(tmp_y)), tmp_dir_z * ones(size(tmp_y)), ...
          zeros(size(tmp_y))];
rx_pos = tx_pos;

%% Antenna beam pattern definition
ant_pat = @(az,el) abs(sinc(2*az/deg2rad(80)).^0.5 .* sinc(2*el/deg2rad(5)).^0.5);

%% Convert faces to point clouds
for iter_faces = 1:numel(face)
    points{iter_faces} = face2points(vertex(face(iter_faces).v,:), sampling_density, face(iter_faces).magnitude, face(iter_faces).phase);
end

%% Scene plot
figure;
hold on;
for iter_faces = 1:numel(face)
    fill3(vertex(face(iter_faces).v,1),vertex(face(iter_faces).v,2),vertex(face(iter_faces).v,3), face(iter_faces).magnitude, 'FaceAlpha', 1 - face(iter_faces).transparency, 'EdgeColor', 'k', 'EdgeAlpha', 0.2);
end
caxis([0 1]);
clrbr = colorbar;
clrbr.Label.String = 'Magnitude [dB]';
plot3(tx_pos(:,1),tx_pos(:,2),tx_pos(:,3),'r-x');
plot3(rx_pos(:,1),rx_pos(:,2),rx_pos(:,3),'b-o');
scatter3(point(:,1),point(:,2),point(:,3),1+50*point(:,4),point(:,4),'filled','MarkerEdgeColor','k');
hold off;
grid on;
axis equal;
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
view(3);

%% Main Simulation Loop
raw_data = zeros(size(tx_pos,1), ceil((end_range - start_range) / cell_size));

for iter_pos = 1:size(tx_pos,1)
    curr_points = points;
    curr_point = point;

    for iter_faces = 1:numel(face)
        curr_points{iter_faces}(:,4) = curr_points{iter_faces}(:,4) .* reflected(tx_pos(iter_pos,1:3), rx_pos(iter_pos,1:3), vertex(face(iter_faces).v,:), face(iter_faces).roughness);
        for iter_faces2 = 1:numel(face)
            if iter_faces ~= iter_faces2
                curr_points{iter_faces}(:,4) = curr_points{iter_faces}(:,4) .* shadowed(tx_pos(iter_pos,1:3), rx_pos(iter_pos,1:3), vertex(face(iter_faces2).v,:), face(iter_faces2).transparency, curr_points{iter_faces}(:,1:3));
            end
        end
        curr_point(:,4) = curr_point(:,4) .* shadowed(tx_pos(iter_pos,1:3), rx_pos(iter_pos,1:3), vertex(face(iter_faces).v,:), face(iter_faces).transparency, curr_point(:,1:3));
    end

    for iter_faces = 1:numel(face)
        curr_point = [curr_point; curr_points{iter_faces}];
    end

    % 안테나 gain 적용
    ant_gain = ones(size(curr_point,1),1);
    for i = 1:size(curr_point,1)
        [az, el] = ant_orientation(tx_pos(iter_pos,:), curr_point(i,1:3).');
        ant_gain(i) = ant_gain(i) * ant_pat(az, el);
    end
    for i = 1:size(curr_point,1)
        [az, el] = ant_orientation(rx_pos(iter_pos,:), curr_point(i,1:3).');
        ant_gain(i) = ant_gain(i) * ant_pat(az, el);
    end
    curr_point(:,4) = curr_point(:,4) .* ant_gain;

    % 수신 신호 계산
    raw_data(iter_pos,:) = sim_resp(fc, B, T, cell_size, start_range, end_range, curr_point, tx_pos(iter_pos,:), rx_pos(iter_pos,:));
end

%% Raw Data Visualization
range_axis = start_range:cell_size:end_range;
figure;
imagesc(range_axis, tmp_y, db(abs(raw_data)));
xlabel('Range [m]');
ylabel('Azimuth [m]');
title('Raw SAR Data (ICEYE-like)');
clrbr = colorbar;
clrbr.Label.String = 'Magnitude [dB]';
[~,cmax] = caxis;
caxis(cmax+[-100, 0]);
