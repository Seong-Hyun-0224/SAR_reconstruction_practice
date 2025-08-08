% % KSH_practice_rangeMigrationLFM.m
% % Range Migration (rangeMigrationLFM) 기반 Stripmap SAR 영상화
% 
% clear; close all; clc;
% 
% %% 기본 설정
% c = physconst('LightSpeed');
% fc = 4e9;                      % 중심 주파수
% rangeResolution = 3;          % 거리 해상도
% crossRangeResolution = 3;     % 방위 해상도
% bw = c/(2*rangeResolution);   % 대역폭
% prf = 1000;                   % 펄스 반복 주기
% aperture = 4;                 % 안테나 개구
% tpd = 3e-6;                   % 펄스 길이
% fs = 120e6;                   % 샘플링 주파수
% 
% waveform = phased.LinearFMWaveform('SampleRate',fs, ...
%     'PulseWidth', tpd, 'PRF', prf, 'SweepBandwidth', bw);
% 
% speed = 100;                      % 플랫폼 속도
% flightDuration = 4;              % 비행 시간
% radarPlatform = phased.Platform('InitialPosition', [0;-200;500], ...
%     'Velocity', [0; speed; 0]);
% 
% slowTime = 1/prf;
% numpulses = round(flightDuration/slowTime) + 1;
% 
% maxRange = 2500;
% truncrangesamples = ceil((2*maxRange/c)*fs);
% fastTime = (0:1/fs:(truncrangesamples-1)/fs).';
% 
% Rc = 1000;  % 기준 거리
% 
% %% 시스템 객체 정의
% antenna = phased.CosineAntennaElement('FrequencyRange', [1e9 6e9]);
% antennaGain = aperture2gain(aperture,c/fc); 
% transmitter = phased.Transmitter('PeakPower', 50e3, 'Gain', antennaGain);
% radiator = phased.Radiator('Sensor', antenna, 'OperatingFrequency', fc, 'PropagationSpeed', c);
% collector = phased.Collector('Sensor', antenna, 'PropagationSpeed', c, 'OperatingFrequency', fc);
% receiver = phased.ReceiverPreamp('SampleRate', fs, 'NoiseFigure', 30);
% 
% channel = phased.FreeSpace('PropagationSpeed', c, 'OperatingFrequency', fc, ...
%     'SampleRate', fs, 'TwoWayPropagation', true);
% 
% %% 타겟 정의
% targetpos = [800, 0, 0; 1000, 0, 0; 1300, 0, 0]';
% targetvel = zeros(3, 3);
% target = phased.RadarTarget('OperatingFrequency', fc, 'MeanRCS', [1,1,1]);
% pointTargets = phased.Platform('InitialPosition', targetpos, 'Velocity', targetvel);
% 
% % Ground Truth Plot
% figure(1);
% plot(targetpos(2,:), targetpos(1,:), '*');
% set(gca, 'Ydir', 'reverse');
% xlim([-10 10]); ylim([700 1500]);
% title('Ground Truth'); xlabel('Cross-Range (m)'); ylabel('Range (m)');
% 
% %% SAR 수신 신호 시뮬레이션
% refangle = zeros(1, size(targetpos,2));
% rxsig = zeros(truncrangesamples, numpulses);
% 
% for ii = 1:numpulses
%     [radarpos, radarvel] = radarPlatform(slowTime);
%     [targetpos, targetvel] = pointTargets(slowTime);
%     [~, targetAngle] = rangeangle(targetpos, radarpos);
% 
%     sig = waveform(); % 송신 파형
%     sig = sig(1:truncrangesamples); % 필요한 길이만 사용
% 
%     sig = transmitter(sig);    
%     targetAngle(1,:) = refangle; % 방위각 고정
%     sig = radiator(sig, targetAngle);
%     sig = channel(sig, radarpos, targetpos, radarvel, targetvel);
%     sig = target(sig);
%     sig = collector(sig, targetAngle);
% 
%     rxsig(:,ii) = receiver(sig);
% end
% 
% figure(2);
% imagesc(abs(rxsig));
% title('SAR Raw Data'); xlabel('Azimuth (pulses)'); ylabel('Range Samples');
% 
% %% Pulse Compression (Matched Filter)
% pulseCompression = phased.RangeResponse( ...
%     'RangeMethod', 'Matched filter', ...
%     'PropagationSpeed', c, ...
%     'SampleRate', fs);
% 
% matchingCoeff = getMatchedFilter(waveform);
% [cdata, rnggrid] = pulseCompression(rxsig, matchingCoeff);
% 
% figure(3);
% imagesc(abs(cdata));
% title('Range Compressed SAR Data'); xlabel('Azimuth (pulses)'); ylabel('Range Samples');
% 
% %% Range Migration Algorithm (공식 함수 사용)
% rma_image = rangeMigrationLFM( ...
%     cdata, waveform, fc, speed, Rc, ...
%     'SampleRate', fs, ...
%     'PRF', prf, ...
%     'PropagationSpeed', c);
% 
% figure(4);
% imagesc(abs(rma_image));
% title('SAR Image by Range Migration (rangeMigrationLFM)');
% xlabel('Cross-Range (Azimuth)'); ylabel('Range');
% 



% KSH_ractice_3_rangeMigrationLFM.m
% MATLAB 공식함수 rangeMigrationLFM 기반 SAR 영상화 예제
% 참고: https://kr.mathworks.com/help/phased/ref/rangemigrationlfm.html

clear; close all; clc;

%% 설정
c = physconst('LightSpeed');
fc = 4e9;
rangeResolution = 3;
crossRangeResolution = 3;
bw = c/(2*rangeResolution);
prf = 1000;
aperture = 4;
tpd = 3e-6;
fs = 120e6;

waveform = phased.LinearFMWaveform('SampleRate',fs, ...
    'PulseWidth', tpd, 'PRF', prf, 'SweepBandwidth', bw);

antenna = phased.CosineAntennaElement('FrequencyRange',[1e9 6e9]);
antennaGain = aperture2gain(aperture, c/fc);
transmitter = phased.Transmitter('PeakPower',50e3,'Gain',antennaGain);
radiator = phased.Radiator('Sensor',antenna,'OperatingFrequency',fc, ...
    'PropagationSpeed',c);
collector = phased.Collector('Sensor',antenna,'OperatingFrequency',fc, ...
    'PropagationSpeed',c);
receiver = phased.ReceiverPreamp('SampleRate',fs,'NoiseFigure',30);
channel = phased.FreeSpace('PropagationSpeed',c,'OperatingFrequency',fc, ...
    'SampleRate',fs,'TwoWayPropagation',true);

%% 플랫폼 설정
speed = 100;
flightDuration = 4;
radarPlatform = phased.Platform('InitialPosition',[0;-200;500], ...
    'Velocity',[0; speed; 0]);

slowTime = 1/prf;
numpulses = round(flightDuration/slowTime);
maxRange = 2500;
truncrangesamples = ceil((2*maxRange/c)*fs);
fastTime = (0:truncrangesamples-1)/fs;

% 타겟 설정
targetpos = [800,0,0; 1000,0,0; 1300,0,0]';
targetvel = zeros(3,3);
target = phased.RadarTarget('OperatingFrequency',fc,'MeanRCS',[1,1,1]);
pointTargets = phased.Platform('InitialPosition',targetpos,'Velocity',targetvel);

figure(1);
plot(targetpos(2,:),targetpos(1,:),'*');
set(gca,'Ydir','reverse');
xlim([-10 10]);
ylim([700 1500]);
title('Ground Truth');
xlabel('Cross-Range (m)');
ylabel('Range (m)');

%% SAR 수신 시뮬레이션
rxsig = zeros(truncrangesamples,numpulses);
refangle = zeros(1,3);

for ii = 1:numpulses
    [radarpos, radarvel] = radarPlatform(slowTime);
    [tgtpos, tgtvel] = pointTargets(slowTime);
    [~, tgtang] = rangeangle(tgtpos, radarpos);
    sig = waveform();
    sig = sig(1:truncrangesamples);
    sig = transmitter(sig);
    tgtang(1,:) = refangle;
    sig = radiator(sig, tgtang);
    sig = channel(sig, radarpos, tgtpos, radarvel, tgtvel);
    sig = target(sig);
    sig = collector(sig, tgtang);
    rxsig(:,ii) = receiver(sig);
end

figure(2);
imagesc(abs(rxsig));
title('SAR Raw Data');
xlabel('Azimuth (pulses)');
ylabel('Range Samples');

%% Pulse Compression
pulseCompression = phased.RangeResponse('RangeMethod','Matched filter', ...
    'PropagationSpeed',c,'SampleRate',fs);
matchingCoeff = getMatchedFilter(waveform);
[cdata, rnggrid] = pulseCompression(rxsig, matchingCoeff);

figure(3);
imagesc(abs(cdata));
title('Range Compressed SAR Data');
xlabel('Azimuth (pulses)');
ylabel('Range Samples');

%% Range Migration Algorithm (공식함수)
Rc = 1000;  % 중심 range
% SAR 영상 생성 using rangeMigrationLFM (공식 R2024a 기본 사용 방식)
rma_image = rangeMigrationLFM(cdata, waveform, fc, speed, Rc);

figure(4);
imagesc(abs(rma_image));
title('SAR Image using Range Migration Algorithm (RMA)');
xlabel('Cross-Range Bins');
ylabel('Range Bins');
