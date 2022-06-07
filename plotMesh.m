function [] = plotMesh(NC,CM)

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

end