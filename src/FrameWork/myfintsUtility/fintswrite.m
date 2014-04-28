function fintswrite(fts,filename)

fts2ascii(filename,fts);
end

% separator=',';
% fp=fopen(filename,'w');
% 
% vecFields=fieldnames(fts);
% matData=fts2mat(fts,1);
% 
% nrows=size(matData,1);
% ncols=size(matData,2);
% 
% % write title
% strPrint='';
% for j=1:ncols
%     strPrint=[strPrint vecFields{j+2}];
%     
%     if j<ncols
%         strPrint=[strPrint separator];
%     end
% end
% fprintf(fp,'%s\n', strPrint);
% 
% for i=1:nrows
%     strPrint=datestr(matData(i,1));
%     for j=2:ncols
%         strPrint=[strPrint separator num2str(matData(i,j))];
%     end
%     fprintf(fp,'%s\n', strPrint);
% end
% 
% fclose(fp);
    