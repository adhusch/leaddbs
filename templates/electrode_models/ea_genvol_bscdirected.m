function ea_genvol_bscdirected(meshel,elspec,vizz)

load bsci_data.mat;
%h=figure;
%plotmesh(allnode,allface,'linestyle','-','facealpha',0.1);
[newnode,newelem]=removedupnodes(allnode,allface,1e-6); % <- this compresses the node list

[node,~,face]=s2m(newnode,{newelem{:}},electrodetrisize,100,'tetgen',[],[]); % generate a tetrahedral mesh of the cylinders

%plotmesh([node(:,1:2) node(:,3)/10],face,'x>0','edgealpha',0.1)
save([ea_getearoot,'templates',filesep,'electrode_models',filesep,elspec.matfname,'_vol.mat'],'node','face');

return


% old code that will generate data.






electrodetrisize=0.1;  % the maximum triangle size of the electrode mesh

%



%% concat meshel to one 
allface={};
allnode=[];
% nms=figure;
% hold on
for c=1:8
    for cel=1:length(meshel(c).faces)
        allface=[allface;{meshel(c).faces{cel}+length(allnode)}];
        
        if any(meshel(c).faces{cel}(:)>length(meshel(c).vertices))
            keyboard
        end
         
    end
    
    allnode=[allnode;meshel(c).vertices];
    
  
  end  
    
% 
% 
%             %axis equal
%             %zlim([0,10])
% 
            %% check for dups in verts:


[uniquenode,ac,cc]=unique(allnode,'rows');
for facec=1:length(allface)
   uniqueface{facec}=cc(allface{facec})';
end
uniqueface=uniqueface';

allface=uniqueface;
allnode=uniquenode;
      

% 
% %% check for dups in cell:
% alllengths=cellfun(@length,allface);
% nuallface={};
% for lens=unique(alllengths)'
%     ids=alllengths==lens;
%     thisface=allface(ids);
%     
%     thisfmat=cell2mat(thisface);
%     
%     [~,c]=unique(sort(thisfmat,2),'rows');
%     ufmat=thisfmat(c,:);
%     
%     rcnt=1; todel=[];
%     rem={};
%     for row=1:size(ufmat,1)
%         if ~isequal(sum(ufmat(row,:)),sum(unique(ufmat(row,:))))
%             if lens>10
%                 %keyboard
%             end
%             % rm dups but retain order:
%             [~, I]=unique(ufmat(row,:),'first');
%             rem{rcnt}=ufmat(row,sort(I));
%             rcnt=rcnt+1;
%             todel=[todel,row];
%         end
%     end
%     ufmat(todel,:)=[];
%     
%     nuallface=[nuallface;num2cell(ufmat,2);rem'];
% end
% allface=nuallface; clear nuallface





%% convert to obtain the electrode surface mesh model

 
%h=figure;
      %plotmesh(uniquenode,uniqueface,'linestyle','-','facealpha',0.1);
%      plotmesh(allnode,allface,'linestyle','-','facealpha',0.1);

      % zlim([0,10])
      [allnode,allface]=removedupnodes(allnode,allface,1e-6); % <- this compresses the node list

      keyboard
[node,~,face]=s2m(allnode,{allface{:}},electrodetrisize,100,'tetgen',[],[]); % generate a tetrahedral mesh of the cylinders






save([ea_getearoot,'templates',filesep,'electrode_models',filesep,elspec.matfname,'_vol.mat'],'node','face');
