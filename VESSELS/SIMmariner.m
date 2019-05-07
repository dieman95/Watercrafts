clc;clear
echo on
% SIMmariner  User editable script for simulation of the 
%             mariner class vessel under feedback control
%
% Calls:      mariner.m and euler2.m
%
% Author:     Thor I. Fossen
% Date:       2018-07-21
% Revisions: 

echo off 
disp('Simulating mariner.m under PD-control with psi_ref=5 (deg) ...')

t_f = 600;   % final simulation time (sec)
h   = 0.1;   % sample time (sec)

Kp = 1;      % controller P-gain
Td = 10;     % controller derivative time

  

% --- MAIN LOOP ---
n = round(t_f/h);               % number of samples
xout = zeros(n+1,7+2+3);  % memory allocation
xin = zeros(n+1,7);  % memory allocation
pref = zeros(n+1,1); % memory allocation
err = zeros(n+1,1); % memory allocation
cont_out = zeros(n+1,1); % memory allocation

sims = 100;
for j=1:sims
    % initial states:  x = [ u v r x y psi delta ]' 
    x = zeros(7,1); 
    % psi_ref = 5*(pi/180);              % desired heading
    psi_ref = 0.18*rand - 0.09;          % desired heading
    for i=1:n+1
        time = (i-1)*h;                   % simulation time in seconds
        xin(i,:) = x;
        r   = x(3);
        psi = x(6);

        % control system
        delta = -Kp*((psi-psi_ref)+Td*r);  % PD-controller

        % ship model
        [xdot,U,X,Y,N] = mariner(x,delta);       % ship model, see .../gnc/VesselModels/

        % store data for presentation
        xout(i,:) = [time,x',U,X,Y,N]; 

        % numerical integration
        x = euler2(xdot,x,h);             % Euler integration
        
        %store psi reference angle
        pref(i,:) = psi_ref;
        err(i,:) = psi - psi_ref;% error for PID controller
        cont_out(i,:) = delta; % PID output
    end
    % time-series
    t(:,:,j)      = xout(:,1);
    u(:,:,j)      = xout(:,2);%(xout(:,2) - min(xout(:,2)))/(max(xout(:,2))-min(xout(:,2))); %Normalize data between 0 and 1
    v(:,:,j)      = xout(:,3);%(xout(:,3) - min(xout(:,3)))/(max(xout(:,3))-min(xout(:,3)));
    ro(:,:,j)     = xout(:,4);%(xout(:,4) - min(xout(:,4)))/(max(xout(:,4))-min(xout(:,4)));   
    xo(:,:,j)     = xout(:,5);%(xout(:,5) - min(xout(:,5)))/(max(xout(:,5))-min(xout(:,5)));
    y(:,:,j)      = xout(:,6);%(xout(:,6) - min(xout(:,6)))/(max(xout(:,6))-min(xout(:,6)));
    psio(:,:,j)   = xout(:,7);%(xout(:,7) - min(xout(:,7)))/(max(xout(:,7))-min(xout(:,7)));
    deltao(:,:,j) = xout(:,8);%(xout(:,8) - min(xout(:,8)))/(max(xout(:,8))-min(xout(:,8)));
    Uo(:,:,j)     = xout(:,9);%(xout(:,9) - min(xout(:,9)))/(max(xout(:,9))-min(xout(:,9)));
    Xo(:,:,j)     = xout(:,10);%(xout(:,10) - min(xout(:,10)))/(max(xout(:,10))-min(xout(:,10)));
    Yo(:,:,j)     = xout(:,11);%(xout(:,11) - min(xout(:,11)))/(max(xout(:,11))-min(xout(:,11)));
    No(:,:,j)     = xout(:,12);%(xout(:,12) - min(xout(:,12)))/(max(xout(:,12))-min(xout(:,12)));
    xino(:,j,:)   = xin;%(xin'-min(xin)')./(max(xin)'-min(xin)');
    prefo(:,:,j)  = pref;
    erro(:,:,j)   = err;
    conto(:,:,j)  = cont_out;
end

%Reshape data
t     = reshape(t,1,(n+1)*sims); % time
u     = reshape(u,1,(n+1)*sims); % pertubed surge velocity about Uo (m/s)
v     = reshape(v,1,(n+1)*sims); % pertubed sway velocity about zero (m/s)         
r     = reshape(ro,1,(n+1)*sims); % pertubed yaw velocity about zero (rad/s)   
x     = reshape(xo,1,(n+1)*sims); % position in x-direction (m)
y     = reshape(y,1,(n+1)*sims); % position in y-direction (m)
psi   = reshape(psio,1,(n+1)*sims); % pertubed yaw angle about zero (rad)
delta = reshape(deltao,1,(n+1)*sims); % actual rudder angle (rad)
U     = reshape(Uo,1,(n+1)*sims); % speed transform
X     = reshape(Xo,1,(n+1)*sims); % X force
Y     = reshape(Yo,1,(n+1)*sims); % Y force
N     = reshape(No,1,(n+1)*sims); % N force
xin   = reshape(xino,7,(n+1)*sims); % states inputs to calculate speed and forces
psi_ref = reshape(prefo,1,(n+1)*sims); % Reference psi
error = reshape(erro,1,(n+1)*sims);
cont_out = reshape(conto,1,(n+1)*sims);


% % plots
% figure(1)
% plot(y,x),grid,axis('equal'),xlabel('East'),ylabel('North'),title('Ship position')
% 
% figure(2)
% subplot(221),plot(t,r),xlabel('time (s)'),title('yaw rate r (deg/s)'),grid
% subplot(222),plot(t,U),xlabel('time (s)'),title('speed U (m/s)'),grid
% subplot(223),plot(t,psi),xlabel('time (s)'),title('yaw angle \psi (deg)'),grid
% subplot(224),plot(t,delta),xlabel('time (s)'),title('rudder angle \delta (deg)'),grid

%% Train NN to predict X, Y, and N from inputs and states
layers = [24 48 24];
net = feedforwardnet(layers,'trainlm');
net.inputs{1}.processFcns = {};
% net.outputs{length(layers)+1}.processFcns = {};
net.inputs{1}.size = 7;
net.layers{length(layers)+1}.size = 4;

net.layers{1}.transferFcn = 'poslin'; %poslin = relu
net.layers{2}.transferFcn = 'poslin'; %poslin = relu
net.layers{3}.transferFcn = 'poslin'; %poslin = relu
net.layers{4}.transferFcn = 'purelin'; %poslin = relu
%net.layers{5}.transferFcn = 'purelin'; % purelin = linear
net.trainParam.epochs = 10000;
net.trainParam.max_fail = 10;
net.trainParam.mu_max = 10e20;
net.trainParam.goal = 0.0000000001;
net.performFcn = 'mse';%help nnperformance to see list of options

%Cannot train with non two-dimensional data, either create iddata objects,
%or simply place one simulation after another and randomly sample them (all
%together), and then use that for training
datatr = [xin; U; X; Y; N; u; v; r; x; y; psi; delta; psi_ref; error; cont_out];
[m,n] = size(datatr);
idx = randperm(n);
data = datatr;
for i = 1:(size(datatr,1))
    data(i,idx) = data(i,:);
end
in_train = {data(1:7,1:300000)};
out_train = {data(8:11,1:300000)};
in_test = {data(1:7,500000:505000)};
out_test = {data(8:11,500000:505000)};

net = train(net,in_train,out_train,'useGPU','no','useParallel','yes','showResources','yes');
outnet = net(in_test);
perf = perform(net,out_test,outnet)

% view(net);
% gensim(net);

%% Train NN controller to substitute PID
layers = [10 10];
netc = feedforwardnet(layers,'trainlm');
netc.inputs{1}.processFcns = {};
% net.outputs{length(layers)+1}.processFcns = {};
netc.inputs{1}.size = 3;
netc.layers{length(layers)+1}.size = 1;

netc.layers{1}.transferFcn = 'poslin'; %poslin = relu
netc.layers{2}.transferFcn = 'poslin'; %poslin = relu
netc.layers{3}.transferFcn = 'purelin'; %poslin = relu
%net.layers{4}.transferFcn = 'purelin'; %poslin = relu
%net.layers{5}.transferFcn = 'purelin'; % purelin = linear
netc.trainParam.epochs = 10000;
netc.trainParam.max_fail = 10;
netc.trainParam.mu_max = 10e20;
netc.trainParam.goal = 0.0000000001;
netc.performFcn = 'mse';%help nnperformance to see list of options
netc.trainParam.min_grad = 1e-11;
% datatr = [xin(7-dim); U; X; Y; N; u, v, r, x, y, psi, delta, psi_ref; error; cont_out];
in3 = {[data(14,1:200000); data(17,1:200000) ;data(19,1:200000)]};
out3 = {data(21,1:200000)};
in_test3 = {[data(14,end-10000:end); data(17,end-10000:end); data(19,end-10000:end)]};
out_test3 = {data(21,end-10000:end)};
in2 = {[data(14,1:200000); data(17,1:200000) - data(19,1:200000)]};
out2 = {data(21,1:200000)};
in_test2 = {[data(14,end-10000:end); data(17,end-10000:end) - data(19,end-10000:end)]};
out_test2 = {data(21,end-10000:end)};

% netc = train(netc,in3,out3,'useGPU','no','useParallel','yes','showResources','yes');
% outnet3 = netc(in_test3);
% perf = perform(netc,out_test3,outnet3)

