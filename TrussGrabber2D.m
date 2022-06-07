%% Trace a 2D Truss over a background image
%Lawrence Smith | lasm4254@colorado.edu

clear; clc; close all

%adjust snap tolerance here
snapTol = 16;

%get the image file
[file,path] = uigetfile('*.*',...
    'Select a picture to use as a backdrop');

%read and display the image, and make it 50% transparent
backdrop = imread([path '/' file]);
h = imshow(backdrop); hold on
set(h, 'AlphaData', 0.5);

%% Set up the environment
theta = linspace(0,2*pi,20); %theta for plotting snapping circle
c = snapTol*[4 4];           %centerpoint of snapping circle

%draw and label snapping circle
plot(c(1)+snapTol*cos(theta),c(2)+snapTol*sin(theta),'b','linewidth',1.5)
text(c(1)+1.5*snapTol,c(2),'Snapping Tolerance')

%gather 2 points to act as a scale bar
title('Click on Two Points to Create a Reference Distance')
[x1, y1] = ginput(1);
plot(x1,y1,'r.','markersize',30);
[x2, y2] = ginput(1);
plot(x2,y2,'r.','markersize',30);
plot([x1 x2],[y1 y2],'linewidth',2.5,'Color','r')

%gather the distance between these 2 points
Dist = sqrt((x1-x2)^2 + (y1-y2)^2);
Dref = inputdlg('Enter Reference Distance');


%% Start assembling points and connecting them

%initialize empty Nodal Coordinate (NC) and Connectivity Matrix (CM)
%NC is a nx2 matrix of coordinates, where each row is a separate point and
%n is the total number of points in the mesh
%CM is a mx2 matrix of connectivity info, where each row is a separate link
%connecting two nodes and m is the number of links in the mesh
NC = [];
CM = [];
title('Click to Create Nodes and Bars. First Click is Origin. ESC to exit.')

while 1

%gather the first point and mark it
[x1, y1, key] = ginput(1);

if key==27 %check if we pressed the escape key to get here
    break
end

plot(x1,y1,'r.','markersize',30);

%gather the second point
[x2, y2, key] = ginput(1);

if key==27 %check if we pressed the escape key to get here
    break
end

%function that updates NC and CM, merging points into existing ones if
%necessary.
[NC,CM] = appendPts([x1 x2],[y1 y2],CM,NC,snapTol);

%delete and replot everything
delete(findobj('type','line'))
plot(c(1)+snapTol*cos(theta),c(2)+snapTol*sin(theta),'b','linewidth',1.5) %snapping circle
for i = 1:size(CM,1)
    plot(NC(CM(i,:),1),NC(CM(i,:),2),'linewidth',1.5,'Color','b') %links
end
plot(NC(:,1),NC(:,2),'g.','markersize',30); %nodes

end

%% Plot the finished mesh and save the mesh info
close all
%transform the coordinates
NC = [NC(:,1), -NC(:,2)];              %flip the y direction
NC = NC-NC(1,:);                     %translate to origin
scaleFactor = str2double(Dref{1})/Dist; %scale the coords based on reference length
NC = NC*scaleFactor;

figure
set(gcf,'position',[250 50 1300 900])
for i = 1:size(CM,1)
    plot(NC(CM(i,:),1),NC(CM(i,:),2),'linewidth',3,'Color','k'); hold on %links
    plot(mean(NC(CM(i,:),1)),mean(NC(CM(i,:),2)),'ks','markersize',15,'markerfacecolor','k')
    text(mean(NC(CM(i,:),1)),mean(NC(CM(i,:),2)),num2str(i),...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'FontSize',12,'FontWeight','bold','color','w');
end
plot(NC(:,1),NC(:,2),'r.','markersize',50); %nodes
text(NC(:,1),NC(:,2),num2str((1:size(NC,1))'),...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'FontSize',12,'FontWeight','bold','color','w')
grid on; grid minor; axis equal
title('Finished Mesh')

meshName = inputdlg('Enter a name for the Mesh');
save(meshName{1},'NC','CM')

function [NC,CM] = appendPts(x,y,CM,NC,snapTol)

%if we are on the first link, automatically add it!
if isempty(CM)

NC = [x' y'];
CM = [1 2];

else
%compute distance from first point
D = sqrt((x(1)-NC(:,1)).^2 + (y(1)-NC(:,2)).^2);
[m,i] = min(D);

%if the first point is further than snapTol away from all other points,
%then add it to the node list. Store its index as the start of the line. If
%not, merge this new point with the closest point and store that index as
%the start of the line
if m>snapTol
    NC = [NC; x(1) y(1)];
    ID1 = size(NC,1);
else
    NC(i,:) = mean([NC(i,:); x(1) y(1)]);
    ID1 = i;
end

%compute distance from first point
D = sqrt((x(2)-NC(:,1)).^2 + (y(2)-NC(:,2)).^2);
[m,i] = min(D);

%if the first point is further than snapTol away from all other points,
%then add it to the node list. Store its index as the end of the line. If
%not, merge this new point with the closest point and store that index as
%the end of the line
if m>snapTol
    NC = [NC; x(2) y(2)];
    ID2 = size(NC,1);
else
    NC(i,:) = mean([NC(i,:); x(2) y(2)]);
    ID2 = i;
end

% add this new link to the connectivity matrix
CM = [CM; ID1 ID2];

end

end
