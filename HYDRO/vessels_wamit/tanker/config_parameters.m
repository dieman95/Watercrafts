% wamit FRC input files
g = 9.81;
rho = 1025;
m   =  rho*(92309.5  +    92313.2  +    92314.5)/3

xg = 3.93
yg = 0
zg = 2.5

Lpp = 246
B = 46
R44 = 0.37*B
R55 = 0.26*Lpp
R66 = 0.27*Lpp

% wamit axes
MRB_CO = diag([m m m m*R44^2 m*R55^2 m*R66^2]);
MRB_CO(1,5) = m*zg;
MRB_CO(5,1) = MRB_CO(1,5);
MRB_CO(2,4) = -m*zg;
MRB_CO(4,2) = MRB_CO(2,4);
MRB_CO(3,5) = -m*xg;
MRB_CO(5,3) = MRB_CO(3,5);

% From WAMIT
% C(3,3),C(3,4),C(3,5):   10222.       0.0000       31916.    
%  C(4,4),C(4,5),C(4,6):               0.92149E+06   0.0000       374.61    
%         C(5,5),C(5,6):                            0.43472E+08   0.0000  
C33 = 10222*rho*g
C44 = 0.92149e6*rho*g
C55 = 0.43703e8*rho*g

%     ADDED-MASS COEFFICIENTS
%      I     J         A(I,J)
%      1     1   1.589215E+03
%      1     3   2.138238E+03
%      1     5   5.127263E+05
%      2     2   1.775084E+04
%      2     4  -1.204802E+05
%      2     6   1.918678E+03
%      3     1   2.133744E+03
%      3     3   1.893987E+05
%      3     5  -2.626893E+05
%      4     2  -1.203633E+05
%      4     4   9.348968E+06
%      4     6   2.588576E+06
%      5     1   5.129652E+05
%      5     3  -2.626174E+05
%      5     5   5.659558E+08
%      6     2   1.869625E+03
%      6     4   2.600499E+06
%      6     6   7.759748E+07
     
A33 = 1.893987e5;
A44 = 9.348968e6;
A55 =  5.659558e8;

format long g
MRB = sprintf('%1.2f %1.2f %1.2f %1.2f %1.2f %6.2f\n',MRB_CO)


