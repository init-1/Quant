function r=fts2csv(ftsobj,filepath,filename);

[r2 r1 r3]=fts2vec(ftsobj,1);

cZero=(r3==0);

r3(cZero)=[];
r2(cZero)=[];
r1(cZero)=[];


fullpath=strcat(filepath,'\',filename,'.csv');
    
fid = fopen(fullpath,'wt');     
for j=1:length(r1);
fprintf(fid,'%s,%s,%1.18f\n',[r1{j}],r2{j},r3(j,1));
end        
fclose(fid);

r=1;