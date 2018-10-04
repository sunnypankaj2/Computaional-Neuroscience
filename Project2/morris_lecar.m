clc;
clear;
warning off;

morris_lecar;

hodgkin_huxley;

function morris_lecar

%declare model parameters
global C;
global gCa;
global VCa;
global gK;
global VK;
global gL;
global VL;
global v1;
global v2;
global v3;
global v4;
global phi;
global Iext;

%parameter values
C = 20 ; %microfarad/cm^2 
gCa=4.4; % millisiemens/ cm^2 
VCa=120; %millivolts
gK=8;% millisiemens/ cm^2 
VK=-84; %millivolts
gL=2;% millisiemens/ cm^2 
VL=-60;%millivolts
v1=-1.2; %millivolts
v2= 18 ; %millivolts
v3= 2 ; %millivolts
v4= 30; %millivolts
phi = 0.02; % per millisecond

Iext=0;

%% Generating nullclines, equilibrium points and trajectories (Question 2)
% generate nullclines
figure;
hold on
Vnc = @(V) (Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gL*(V-VL))/(gK*(V-VK));
wnc = @(V) (0.5*(1+tanh((V-v3)/v4)));
fplot(@(V) Vnc(V)*100, [-80 100]);
fplot(@(V) wnc(V)*100, [-80 100]);
xlabel('V(in mV)');
ylabel('w');
title('Phase Plane Plot(MLE)');

% Finding equilibrium points using MATLAB
syms V w
Vnc_eqn = (1/C)*(Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gK*w*(V-VK) - gL*(V-VL)) == 0;
wnc_eqn = (0.5*(1+tanh((V-v3)/v4)) - w) == 0;
eq_pt_0 = solve([Vnc_eqn, wnc_eqn], [V, w]);

V_eq = double(eq_pt_0.V);
w_eq = double(eq_pt_0.w);

plot(V_eq, 100*w_eq, 'k+', 'linewidth', 2);
text(V_eq, 100*w_eq, ['(' num2str(round(V_eq,5)) ',' num2str(round(w_eq,5)) ')']);
grid on;

fprintf('\n ------------------------- Part 2 ------------------------------\n ');
fprintf('The equilibrium point is located at (%d,%d) \n', V_eq, w_eq);
% Simulate Trajectories
x = linspace(-80,100,100);
y = linspace(0,1,100);

[V_quiv,w_quiv] = meshgrid(x, y);

dV_dt = (1/C)*(gCa*(0.5*(1+tanh((V_quiv-v1)/v2))).*(VCa-V_quiv) + gK*w_quiv .*(VK-V_quiv) + gL*(VL-V_quiv) + Iext);
dw_dt = phi*((0.5*(1+tanh((V_quiv-v3)/v4)))-w_quiv).*cosh((V_quiv-v3)/(2*v4));
quiver(x,y*100,dV_dt,dw_dt*100);
legend('V nullcline', 'w nullcline','Equilibrium Point','Trajectories');


%% Stability of the Jacobian matrix (Question 3)
syms V w
dV_dt = (1/C)*(gCa*(0.5*(1+tanh((V-v1)/v2)))*(VCa-V) + gK*w*(VK-V) + gL*(VL-V) + Iext);
dw_dt = phi*((0.5*(1+tanh((V-v3)/v4)))-w)*cosh((V-v3)/(2*v4));

JSymbolic = jacobian([dV_dt, dw_dt],[V,w]);
V = V_eq;
w = w_eq;
Jmatrix = zeros(2,2);
Jmatrix(1,1) = subs(JSymbolic(1,1));
Jmatrix(1,2) = subs(JSymbolic(1,2));
Jmatrix(2,1) = subs(JSymbolic(2,1));
Jmatrix(2,2) = subs(JSymbolic(2,2));

eigenValues = eig(Jmatrix);
fprintf('\n------------------------- Part 3 ------------------------------\n ');
fprintf('The eigen values are %d and %d \n', eigenValues(1), eigenValues(2));

%% Generating an action potential using MLE (Question 5)
options = odeset('RelTol',1e-3,'AbsTol',1e-6, 'refine',5, 'MaxStep', 1);

Iext = 0;
tSpan = [0, 300];
initial = [0,w_eq];

phi = 0.01;
[t1, S1] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);

phi = 0.02;
[t2, S2] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);

phi = 0.04;
[t3, S3] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);

phi = 0.02;

figure;
hold on;
plot(t1,S1(:,1));
plot(t2, S2(:,1));
plot(t3, S3(:,1));
xlabel('Time(in ms)');
ylabel('Volatage(in mV)');
title('Action potentials with different \phi');
legend('\phi = 0.01','\phi = 0.02','\phi = 0.04');
grid on;

figure;
hold on
Vnc = @(V) (Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gL*(V-VL))/(gK*(V-VK));
wnc = @(V) (0.5*(1+tanh((V-v3)/v4)));
fplot(@(V) Vnc(V), [-80 100],'k');
fplot(@(V) wnc(V), [-80 100],'k');

plot(S1(:,1),S1(:,2));
plot(S2(:,1),S2(:,2));
plot(S3(:,1),S3(:,2));
xlabel('V(in mV)');
ylabel('w');
ylim([0,1]);
title('Phase Plane Plot(MLE)');
legend('V-nullcline','w_nullcline','\phi = 0.01','\phi = 0.02','\phi = 0.04');
grid on;

%% Depolarisation Threshold (Question 6)
Iext = 0;
tSpan = [0, 300];
phi=0.02;
initialV=linspace(-15.2,-14.8,400); 
max_V = zeros(1,400);


fprintf(' \n ------------------------- Part 6 ------------------------------ \n');
flag=1;
for n = 1:400 
    [t,S] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, [initialV(n),w_eq], options);
    max_V(n) = max(S(:,1));
    if max_V(n) >= 0 && flag==1
        fprintf("Threshold is (%f)",initialV(n));
        threshold = initialV(n);
        flag=0;
    end
end

figure;
hold on
plot(initialV,max_V);
grid on;
xlabel('Initial Voltage(in mV)');
ylabel('Maximum Voltage(in mV)');
title('Threshold behavior with change in initial voltage');

figure;
hold on
Vnc = @(V) (Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gL*(V-VL))/(gK*(V-VK));
wnc = @(V) (0.5*(1+tanh((V-v3)/v4)));
fplot(@(V) Vnc(V), [-80 100],'k');
fplot(@(V) wnc(V), [-80 100],'k');

V_plot = linspace(threshold-0.1,threshold + 0.1,5);
for i = 1:5
    [t,S] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, [V_plot(i),w_eq], options);
    plot(S(:,1),S(:,2));
end
xlabel('V(in mV)');
ylabel('w');
ylim([0,1]);
title('Phase Plane Plot(MLE) for different initial voltages around threshold');
grid on;

%% Response to higher Iext (Question 7)
Iext = 86;

figure;
hold on
Vnc1 = @(V) (Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gL*(V-VL))/(gK*(V-VK));
wnc1 = @(V) (0.5*(1+tanh((V-v3)/v4)));
fplot(@(V) Vnc1(V), [-80 100]);
fplot(@(V) wnc1(V), [-80 100]);
xlabel('V(in mV)');
ylabel('w');
title('Phase Plane Plot(MLE)');

% Finding equilibrium points using MATLAB
syms V w
Vnc1_eqn = (1/C)*(Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gK*w*(V-VK) - gL*(V-VL)) == 0;
wnc1_eqn = (0.5*(1+tanh((V-v3)/v4)) - w) == 0;
eq_pt_1 = solve([Vnc1_eqn, wnc1_eqn], [V, w]);

V_eq1 = double(eq_pt_1.V);
w_eq1 = double(eq_pt_1.w);

plot(V_eq1, w_eq1, 'k+', 'linewidth', 2);
text(V_eq1, w_eq1, ['(' num2str(round(V_eq1,5)) ',' num2str(round(w_eq1,5)) ')']);
grid on;

fprintf('\n------------------------- Part 7 ------------------------------ \n');
fprintf('The equilibrium point is located at (%d,%d) \n', V_eq1, w_eq1);

dV_dt = (1/C)*(gCa*(0.5*(1+tanh((V-v1)/v2)))*(VCa-V) + gK*w*(VK-V) + gL*(VL-V) + Iext);
dw_dt = phi*((0.5*(1+tanh((V-v3)/v4)))-w)*cosh((V-v3)/(2*v4));

JSymbolic = jacobian([dV_dt, dw_dt],[V,w]);
V = V_eq1;
w = w_eq1;
Jmatrix = zeros(2,2);
Jmatrix(1,1) = subs(JSymbolic(1,1));
Jmatrix(1,2) = subs(JSymbolic(1,2));
Jmatrix(2,1) = subs(JSymbolic(2,1));
Jmatrix(2,2) = subs(JSymbolic(2,2));

eigenValues = eig(Jmatrix)

tSpan = [0,300];
initial = [V_eq,w_eq];
[t1, S1] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);
initial = [V_eq1,w_eq1];
[t2, S2] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);
initial = [-27.9,0.17];
[t3, S3] = ode15s(@(t,S)morris_lecar_ddt(t,S),tSpan, initial, options);
% figure;
% hold on

plot(S1(:,1),S1(:,2));
plot(S2(:,1),S2(:,2));
plot(S3(:,1),S3(:,2));
ylim([0 1]);
legend('V - nullcline','w - nullcline','Equilibrium point','Eqlbm pt of Ixt = 0','Eqlbm pt of Ixt = 86','Random intial point');


%% Unstable Periodic Orbital in non-zero Iext (Question 8)
Iext = 86;

% Plotting the Phase Plane with V and w null clines
figure;
hold on
Vnc1 = @(V) (Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gL*(V-VL))/(gK*(V-VK));
wnc1 = @(V) (0.5*(1+tanh((V-v3)/v4)));
fplot(@(V) Vnc1(V), [-80 100]);
fplot(@(V) wnc1(V), [-80 100]);
xlabel('V(in mV)');
ylabel('w');
title('Phase Plane Plot(MLE)');

% Finding and plotting the equilibrium point for this system using MATLAB
syms V w
Vnc1_eqn = (1/C)*(Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gK*w*(V-VK) - gL*(V-VL)) == 0;
wnc1_eqn = (0.5*(1+tanh((V-v3)/v4)) - w) == 0;
eq_pt_1 = solve([Vnc1_eqn, wnc1_eqn], [V, w]);

V_eq1 = double(eq_pt_1.V);
w_eq1 = double(eq_pt_1.w);

plot(V_eq1, w_eq1, 'o');
text(V_eq1, w_eq1, ['(' num2str(round(V_eq1,5)) ',' num2str(round(w_eq1,5)) ')']);
grid on;

% Running the system backwards in time from equilibrium point and plotting
% on the Phase plane plot
tSpan1 = [0,300];
tSpan2 = [0,-1000];

[t1,S1]=ode15s(@(t,S)morris_lecar_ddt(t,S), tSpan1, [V_eq, w_eq]);
[t2,S2]=ode15s(@(t,S)morris_lecar_ddt(t,S), tSpan1, [-27.9, 0.17]);
[t3,S3]=ode15s(@(t,S)morris_lecar_ddt(t,S), tSpan1, [V_eq1, w_eq1]);
[t4,S4]=ode15s(@(t,S)morris_lecar_ddt(t,S), tSpan2, [-27.9, 0.17]);
plot(S1(:,1), S1(:,2),'g');
plot(S2(:,1), S2(:,2),'y');
plot(S3(:,1), S3(:,2),'b');
plot(S4(:,1), S4(:,2),'m');
legend('W nullcline','V nullcline','Equilibrium point', 'Eqlbrm point for Iext=0','Random initial point', ...
       'Eqlbrm point for Iext=86','UPO for negative time for Random initial point');

ylim([0 1]);

% figure;
% hold on

%% Equilibrium Points for Iext = 80, 86, 90 (Question 9)
% Analyse the three cases of Iext
Iexts = [80, 86, 90];
for i = 1:3
    Iext = Iexts(i);
    fprintf('\n------------------------- Part 9 -> Iext = %d ------------------------------ \n', Iext);
    % Finding the equilibrium point for this system using MATLAB
    syms V w
    Vnc1_eqn = (1/C)*(Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gK*w*(V-VK) - gL*(V-VL)) == 0;
    wnc1_eqn = (0.5*(1+tanh((V-v3)/v4)) - w) == 0;
    eq_pt_1 = solve([Vnc1_eqn, wnc1_eqn], [V, w]);

    V_eq1 = double(eq_pt_1.V);
    w_eq1 = double(eq_pt_1.w);

    % Stability Analysis for equilibrium point
    fprintf('The equilibrium point is located at (%d,%d)  \n', V_eq1, w_eq1);

    dV_dt = (1/C)*(gCa*(0.5*(1+tanh((V-v1)/v2)))*(VCa-V) + gK*w*(VK-V) + gL*(VL-V) + Iext);
    dw_dt = phi*((0.5*(1+tanh((V-v3)/v4)))-w)*cosh((V-v3)/(2*v4));

    JSymbolic = jacobian([dV_dt, dw_dt],[V,w]);
    V = V_eq1;
    w = w_eq1;
    Jmatrix = zeros(2,2);
    Jmatrix(1,1) = subs(JSymbolic(1,1));
    Jmatrix(1,2) = subs(JSymbolic(1,2));
    Jmatrix(2,1) = subs(JSymbolic(2,1));
    Jmatrix(2,2) = subs(JSymbolic(2,2));

    eigenValues = eig(Jmatrix);
    fprintf('The eigen values are  %f%+fi , %f%+fi \n', real(eigenValues(1)), imag(eigenValues(1)), ...
            real(eigenValues(2)), imag(eigenValues(2)));
end

% Plot the trajectories for different Iext with starting position near
% equilibrium point of the system:
figure;
hold on
ylabel('Firing Rate (in hz or 1/s)');
xlabel('Iext (in uA)');
title('Firing Rate vs External Current');
i = 0;
frequency = zeros(21, 1);
current = zeros(21, 1);
for Iext = 80:1:100
    syms V w
    Vnc1_eqn = (1/C)*(Iext - gCa*(0.5*(1+tanh((V-v1)/v2)))*(V-VCa) - gK*w*(V-VK) - gL*(V-VL)) == 0;
    wnc1_eqn = (0.5*(1+tanh((V-v3)/v4)) - w) == 0;
    eq_pt_1 = solve([Vnc1_eqn, wnc1_eqn], [V, w]);
    V_eq1 = double(eq_pt_1.V);
    w_eq1 = double(eq_pt_1.w);
    
    initpoint = [V_eq1 + 0.1, w_eq1 + 0.001];
    tspan = [0 2000];
    [t1,S1]=ode15s(@(t,S)morris_lecar_ddt(t,S), tspan, initpoint);
    i = i+1;
    frequency(i) = get_frequency(t1, S1);
    current(i) = Iext;
    hold on
end
plot(current, frequency);

hold off    
end




function F = get_frequency(t, S)
    n = size(S);
    n = n(1);
    S = S(:, 1);
    % Check for spike generation:
    has_spikes = 0;
    for i = 1:n
        if S(i) > 0
            has_spikes = 1;
        end
    end
    if has_spikes == 0
        F = 0;
        return
    end
    
    % Move ahead till we get a negative signal: 
    while S(n) > 0 
        n = n - 1;
    end
    % Record first positive signal:
    while S(n) < 0 
        n = n -1 ;
    end
    t2 = t(n);
    % Move ahead till we get negative signal again:
    while S(n) >0
        n = n-1;
    end
    % Record second positive signal:
    while S(n) < 0
        n = n-1;
    end
    t1 = t(n);
    F = 1000 / (t2 - t1);
end

function stability_check(Iext)
    global C;
    %global Iext;
    global gK;
    global gNa;
    global gL;
    global VK;
    global VNa;
    global VL;
    global eps;
    
    syms V n m h 
    alphan =  -0.01 * (V + eps + 50)/(exp(-(V + eps + 50)/10)-1);
    alpham =  -0.1 * (V + eps + 35)/(exp(-(V + eps + 35)/10)-1);
    alphah = 0.07 * exp(-(V + 60)/20);
    betan = 0.125 * exp(-(V + 60)/80);
    betam = 4 * exp(-(V + 60)/18);
    betah = 1/(exp(-(V + 30)/10) + 1);
    mInf = alpham/(alpham + betam);
    nInf = alphan/(alphan + betan);
    hInf = alphah/(alphah + betah);
    
    V_nc = (1/C) * (Iext - gK * n^4 * (V - VK) - gNa * m^3 * h* (V - VNa) - gL * (V - VL)) == 0;
    n_nc = alphan *(1-n) - betan*n == 0 ;
    m_nc = alpham * (1 - m) - betam * m ==0 ;
    h_nc = alphah * (1 - h) - betah * h ==0 ;
    
    eq_pt = solve([V_nc, n_nc, m_nc, h_nc], [V, n, m ,h]);
    V_eq1 = double(eq_pt.V);
    n_eq1 = double(eq_pt.n);
    m_eq1 = double(eq_pt.m);
    h_eq1 = double(eq_pt.h);
    
    for p=1:length(eq_pt)
        fprintf('Equilibrium Point V=%f n=%f m=%f h=%f\n',eq_pt(p).V,eq_pt(p).n,eq_pt(p).m,eq_pt(p).h);
    end
    % Stability Analysis for equilibrium point
    % fprintf('The equilibrium point is located at (%d,%d)  \n', V_eq1, n_eq1);

    dV_dt = (1/C) * (Iext - gK * n^4 * (V - VK) - gNa * m^3 * h* (V - VNa) - gL * (V - VL));
    dn_dt = alphan *(1-n) - betan*n;
    dm_dt = alpham * (1 - m) - betam * m ;
    dh_dt = alphah * (1 - h) - betah * h ;
    
    JSymbolic = jacobian([dV_dt, dn_dt, dm_dt, dh_dt],[V,n,m,h]);
    V = V_eq1;
    n = n_eq1;
    m = m_eq1;
    h = h_eq1;
    Jmatrix = zeros(4,4);
    Jmatrix(1,1) = subs(JSymbolic(1,1));
    Jmatrix(1,2) = subs(JSymbolic(1,2));
    Jmatrix(1,3) = subs(JSymbolic(1,3));
    Jmatrix(1,4) = subs(JSymbolic(1,4));
    Jmatrix(2,1) = subs(JSymbolic(2,1));
    Jmatrix(2,2) = subs(JSymbolic(2,2));
    Jmatrix(2,3) = subs(JSymbolic(2,3));
    Jmatrix(2,4) = subs(JSymbolic(2,4));
    Jmatrix(3,1) = subs(JSymbolic(3,1));
    Jmatrix(3,2) = subs(JSymbolic(3,2));
    Jmatrix(3,3) = subs(JSymbolic(3,3));
    Jmatrix(3,4) = subs(JSymbolic(3,4));
    Jmatrix(4,1) = subs(JSymbolic(4,1));
    Jmatrix(4,2) = subs(JSymbolic(4,2));
    Jmatrix(4,3) = subs(JSymbolic(4,3));
    Jmatrix(4,4) = subs(JSymbolic(4,4));
    
    eigenValues = eig(Jmatrix);
    fprintf('The eigen values are %f%+fi , %f%+fi , %f%+fi , %f%+fi \n', real(eigenValues(1)), imag(eigenValues(1)), ...
            real(eigenValues(2)), imag(eigenValues(2)), real(eigenValues(3)), imag(eigenValues(3)), ...
            real(eigenValues(4)), imag(eigenValues(4)));
    k=0;
    for x=1:4
        if real(eigenValues(x)) < 0 
            k = k+1;
        else
            k = k-1;
        end
    end
    if k == 4 
        fprintf("Stable\n");
    elseif k == -4
        fprintf("Unstable\n");
    else
        fprintf("Cannot say (Need to plot in 4 dimensions)\n");
    end
    
end

function dS = HH_f_na(t,S)
    global C;
    global Iext;
    global gK;
    global gNa;
    global gL;
    global VK;
    global VNa;
    global VL;
    global eps;
    global f;
    
    V = S(1);
    n = S(2);
    m = S(3);
    h = S(4);
    
    alphan =  -0.01 * (V + eps + 50)/(exp(-(V + eps + 50)/10)-1);
    alpham =  -0.1 * (V + eps + 35)/(exp(-(V + eps + 35)/10)-1);
    alphah = 0.07 * exp(-(V + 60)/20);
    betan = 0.125 * exp(-(V + 60)/80);
    betam = 4 * exp(-(V + 60)/18);
    betah = 1/(exp(-(V + 30)/10) + 1);
    
    ddt_V = (1/C) * (Iext - gK * n^4 * (V - VK) - gNa * (1-f) * m^3 * h * (V-VNa) - gNa * f * m^3 * (V-VNa)  - gL * (V - VL));
    ddt_n = alphan * (1 - n) - betan * n;
    ddt_m = alpham * (1 - m) - betam * m;
    ddt_h = alphah * (1 - h) - betah * h;
    
    dS = [ddt_V; ddt_n; ddt_m; ddt_h];
end

function dS = HH_reduced(t,S)
    global C;
    global Iext;
    global gK;
    global gNa;
    global gL;
    global VK;
    global VNa;
    global VL;
    global eps;
    global f;
    global hconst;
    V = S(1);
    n = S(2);
    
    alphan =  -0.01 * (V + eps + 50)/(exp(-(V + eps + 50)/10)-1);
    alpham =  -0.1 * (V + eps + 35)/(exp(-(V + eps + 35)/10)-1);
    alphah = 0.07 * exp(-(V + 60)/20);
    betan = 0.125 * exp(-(V + 60)/80);
    betam = 4 * exp(-(V + 60)/18);
    betah = 1/(exp(-(V + 30)/10) + 1);
    
    mInf = alpham/(alpham + betam);
    
    ddt_V = (1/C) * (Iext - gK * n^4 * (V - VK) - gNa * (1-f) * mInf^3 * hconst * (V-VNa) - gNa * f * mInf^3 * (V-VNa)  - gL * (V - VL));
    ddt_n = alphan * (1 - n) - betan * n;
    
    dS = [ddt_V; ddt_n];
end

function dS = HH_reduced_m(t,S,nInf,hInf)
    global C;
    global Iext;
    global gK;
    global gNa;
    global gL;
    global VK;
    global VNa;
    global VL;
    global eps;
    
    V = S(1);
    m = S(2);
    
    alpham =  -0.1 * (V + eps + 35)/(exp(-(V + eps + 35)/10)-1);
    betam = 4 * exp(-(V + 60)/18);
    
    ddt_V = (1/C) * (Iext - gK * nInf^4 * (V - VK) - gNa * m^3 * hInf * (V - VNa) - gL * (V - VL));
    ddt_m = alpham * (1 - m) - betam * m;
    
    dS = [ddt_V; ddt_m];
end


function dS = hodgkin_huxley_ddt(t,S)
    global C;
    global Iext;
    global gK;
    global gNa;
    global gL;
    global VK;
    global VNa;
    global VL;
    global eps;
    
    V = S(1);
    n = S(2);
    m = S(3);
    h = S(4);
    
    alphan =  -0.01 * (V + eps + 50)/(exp(-(V + eps + 50)/10)-1);
    alpham =  -0.1 * (V + eps + 35)/(exp(-(V + eps + 35)/10)-1);
    alphah = 0.07 * exp(-(V + 60)/20);
    betan = 0.125 * exp(-(V + 60)/80);
    betam = 4 * exp(-(V + 60)/18);
    betah = 1/(exp(-(V + 30)/10) + 1);
    
    ddt_V = (1/C) * (Iext - gK * n^4 * (V - VK) - gNa * m^3 * h * (V - VNa) - gL * (V - VL));
    ddt_n = alphan * (1 - n) - betan * n;
    ddt_m = alpham * (1 - m) - betam * m;
    ddt_h = alphah * (1 - h) - betah * h;
    
    dS = [ddt_V; ddt_n; ddt_m; ddt_h];
end

%% Morris Lecar dynamics equation solver
function dS = morris_lecar_ddt(t,S)

global C;
global gCa;
global VCa;
global gK;
global VK;
global gL;
global VL;
global v1;
global v2;
global v3;
global v4;
global phi;
global Iext;

%locally define state variables:
V=S(1);
w=S(2);

%local functions:
m_inf = (0.5*(1+tanh((V-v1)/v2)));
w_inf = (0.5*(1+tanh((V-v3)/v4)));

ddt_V = (1/C)*(gCa*m_inf*(VCa-V) + gK*w*(VK-V) + gL*(VL-V)+Iext);
ddt_w = phi*(w_inf-w)*cosh((V-v3)/(2*v4));

dS=[ddt_V; ddt_w];

end