%2D Linear FEA on Truss (Bar Elements)
% Lawrence Smith <Lawrence.Smith-1@Colorado.EDU>
% Jeff Knutsen <jeffrey.knutsen@colorado.edu>

clear; clc; close all

%% Material Properties and Loads for Bar Elements
E = 200e9; %[Pa]
A = 3e-4; %[m^2]
f = 5e4; %[N]

%% Mesh Information

%Define the nodal coordinate (NC) matrix: each row corresponds to one node
%in the mesh. The first entry in each row is the X coord and the second is
%the Y coord.
%NC = [  0	0;  2	0;  2	2;  4	6;  2	6;  0	6;  0	2;];

%Dedine the location matrix (LM): Each row corrresponds to one bar element
%in the mesh. The first entry in each row is the node at the left end of
%the element and the second entry is the node at the right end.
%CM = [1 2; 2 3; 7 3; 1 7; 7 2; 1 3; 3 4; 3 5; 3 6; 7 5; 7 6; 6 5; 5 4;];

%Note: You could also comment the above information out, and load the NC and CM
%matrices in from another source!

%like this:
load("newMesh.mat");
   
%% Assemble the Global Stiffness matrix
%Initialize Matrices for storing Length, Angle, of each element

nEl = size(CM,1);       %Number of elements in the mesh
nNode = size(NC,1);     %Number of nodes in the mesh
L = zeros(nEl,1);       %This will hold the length of each bar element
Thetas = zeros(nEl,1);  %This will hold the angle of each bar element
ID = reshape(1:2*nNode,2,[])'; %this matrix tells us the global DOF that 
% the nodes in each element belong to.

%Initialize Global Stiffness Matrix
K = zeros(2*nNode,2*nNode);

for i = 1:nEl
   
   %Extract the X coords and Y coords of the nodes in this element
   X = NC(CM(i,:),1);
   Y = NC(CM(i,:),2);

   % Compute Length of this element
   L(i) = sqrt((X(1)-X(2))^2+(Y(1)-Y(2))^2);

   % Compute Theta of this element
   Thetas(i) = atan2(Y(1)-Y(2),X(1)-X(2));
   
   % Local Stiffness Matrix for this Element
   k = (E*A/L(i))*barstiffness(Thetas(i));
   
   % Which global DOF does this element contain?
   id = [ID(CM(i,1),:) ID(CM(i,2),:)];
   
   % Store local matrix in global matrix
   K(id,id) = K(id,id) + k;
end   

% Apply Forces. This is mesh dependent! You will have to change which
% indices are loaded depending on your mesh
F = zeros(2*nNode,1);
F(10) = -f;      %in this case, the 10th DOF is the tip of the crane

%% Solve for Unknown Displacements
%Identify which DOF we need to solve for. This is mesh dependent!! You will
%have to change these indices depending on your mesh
fixed = [1 2 5 6];
active = 1:length(F); %these are the DOF's that are not pinned
active(fixed) = [];

%Solve for the unknown degrees of freedom
d = K(active,active)\F(active);

% Add known displacements back in
D = zeros(2*nNode,1);
D(active) = d;

%Add the displacements to the original coords to obtain deformed coords
nc = [NC(:,1)+D(1:2:end) NC(:,2)+D(2:2:end)];

%% Post-Process Displacements to obtain axial (S11) stress

% Compute deformed lengths, strains, and stresses
L2 = zeros(nEl,1);
s = zeros(nEl,1);
S = zeros(nEl,1);

for i = 1:nEl

   %Extract the X coords and Y coords of the nodes in this element
   X = nc(CM(i,:),1);
   Y = nc(CM(i,:),2);

   % Compute Length of this element
   L2(i) = sqrt((X(1)-X(2))^2+(Y(1)-Y(2))^2);
   
   %Compute strain in each element
   s(i) = (L2(i)-L(i))/L(i);
   
   %Compute S11 in each element
   S(i) = s(i)*E;
end


%% Plot undeformed and deformed mesh
SF = 20; %scale factor for visualization of deformed results
% Scaled nodal coordinates of deformed elements
nc = [NC(:,1)+SF*D(1:2:end) NC(:,2)+SF*D(2:2:end)];

% Plot Results
Contours = 8;
Scolor = floor(rescale(S,1,Contours));
C = cool(Contours);
colormap(C);

figure(1),clf
for i = 1:nEl
   %Extract the original X coords and Y coords of the nodes in this element
   X0 = NC(CM(i,:),1);
   Y0 = NC(CM(i,:),2);
   %plot undeformed elements
   plot(X0,Y0,'k','linewidth',1.5); 
   hold on

   %Extract the original X coords and Y coords of the nodes in this element
   X = nc(CM(i,:),1);
   Y = nc(CM(i,:),2);
   %plot deformed elements
   plot(X,Y,'linewidth',2,'color',C(Scolor(i),:)); 
end

axis equal
colorbar
caxis(1e-6*[min(S) max(S)])
title(sprintf('Deformed Results, S11 in MPa, ScaleFactor = %.0f',SF))


%% Support Functions
%this function calculates the local stiffness matrix of an element
function k = barstiffness(theta)
k = [ C2(theta), CS(theta), -C2(theta), -CS(theta);
CS(theta), S2(theta), -CS(theta), -S2(theta);
-C2(theta), -CS(theta), C2(theta), CS(theta);
-CS(theta), -S2(theta), CS(theta), S2(theta); ];
end
function val = S2(theta)
val = sin(theta)^2;
end
function val = C2(theta)
val = cos(theta)^2;
end
function val = CS(theta)
val = cos(theta)*sin(theta);
end  